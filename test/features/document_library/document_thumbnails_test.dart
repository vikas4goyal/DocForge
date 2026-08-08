import 'package:doc_scanly/core/contracts/document_page_access.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/document_page_handle.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_thumbnails.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ThumbnailCache cache;
  late _DocumentFiles files;
  late LoadDocumentPageThumbnail load;

  setUp(() {
    cache = _ThumbnailCache();
    files = _DocumentFiles();
    load = LoadDocumentPageThumbnail(cache, files);
  });

  test('refuses to derive content from a protected document', () async {
    final protected = sampleDocument.copyWith(isProtected: true);

    final result = await load(protected, 3);

    expect(result.failureOrNull, isA<AuthFailure>());
    expect(cache.document, isNull);
    expect(files.released, isEmpty);
  });

  test('does not pass a secret for an unprotected document', () async {
    await load(sampleDocument, 1);

    expect(cache.password, isNull);
  });

  test('releases a materialised file when rendering fails', () async {
    cache.failure = const Failure.pdf(debugDetail: 'bad page');

    final result = await load(sampleDocument, 1);

    expect(result.failureOrNull, cache.failure);
    expect(files.released, [sampleDocument.id]);
  });

  test('returns resolution failure without asking the cache', () async {
    files.failure = const Failure.notFound();

    final result = await load(sampleDocument, 1);

    expect(result.failureOrNull, files.failure);
    expect(cache.document, isNull);
    expect(files.released, isEmpty);
  });

  group('unified page preview', () {
    final handle = DocumentPageHandle(
      id: const PageId('page-1'),
      documentId: sampleDocument.id,
      pageNumber: 1,
      source: const DocumentPageSource.pdfPage(),
    );

    test(
      'maps every materialized page lifetime to its readable path',
      () async {
        for (final value in <MaterializedDocumentPage>[
          const MaterializedDocumentPage.authoritative(path: '/scan.jpg'),
          const MaterializedDocumentPage.cached(path: '/cache/page.png'),
          const MaterializedDocumentPage.temporary(path: '/tmp/page.png'),
        ]) {
          final pages = _PageAccess(value: value);

          final result = await LoadDocumentPagePreview(pages)(
            sampleDocument,
            handle,
          );

          expect(result.valueOrNull, value.path);
          expect(pages.purpose, DocumentPageRenderPurpose.thumbnail);
        }
      },
    );

    test('preserves a typed materialization failure', () async {
      final pages = _PageAccess(failure: const Failure.corruptFile());

      final result = await LoadDocumentPagePreview(pages)(
        sampleDocument,
        handle,
      );

      expect(result.failureOrNull, const Failure.corruptFile());
    });
  });
}

class _PageAccess implements DocumentPageAccessRepository {
  _PageAccess({this.value, this.failure});

  final MaterializedDocumentPage? value;
  final Failure? failure;
  DocumentPageRenderPurpose? purpose;

  @override
  Future<Result<MaterializedDocumentPage>> materialize(
    Document document,
    DocumentPageHandle page,
    DocumentPageRenderPurpose purpose,
  ) async {
    this.purpose = purpose;
    return failure == null
        ? Result<MaterializedDocumentPage>.success(value!)
        : Result<MaterializedDocumentPage>.failure(failure!);
  }

  @override
  Future<Result<List<DocumentPageHandle>>> pagesOf(Document document) async =>
      const Result<List<DocumentPageHandle>>.success([]);

  @override
  Future<Result<String?>> embeddedText(
    Document document,
    DocumentPageHandle page,
  ) async => const Result<String?>.success(null);

  @override
  Future<Result<void>> release(MaterializedDocumentPage page) async =>
      const Result<void>.success(null);
}

class _ThumbnailCache implements DocumentThumbnailCache {
  Document? document;
  String? filePath;
  int? pageNumber;
  String? password;
  Failure? failure;

  @override
  Future<Result<String>> thumbnailFor(
    Document document, {
    required String filePath,
    required int pageNumber,
    String? password,
  }) async {
    this.document = document;
    this.filePath = filePath;
    this.pageNumber = pageNumber;
    this.password = password;
    return failure == null
        ? const Result<String>.success('/cache/page.png')
        : Result<String>.failure(failure!);
  }

  @override
  Future<Result<void>> evict(DocumentId id) async =>
      const Result<void>.success(null);
}

class _DocumentFiles implements DocumentFileResolver {
  Failure? failure;
  final List<DocumentId> released = [];

  @override
  Future<Result<String>> pathFor(Document document) async => failure == null
      ? const Result<String>.success('/materialised/document.pdf')
      : Result<String>.failure(failure!);

  @override
  Future<Result<void>> release(Document document) async {
    released.add(document.id);
    return const Result<void>.success(null);
  }
}
