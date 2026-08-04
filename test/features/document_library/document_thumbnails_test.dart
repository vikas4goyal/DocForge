import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_thumbnails.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ThumbnailCache cache;
  late _DocumentFiles files;
  late InMemorySecureStore secrets;
  late LoadDocumentPageThumbnail load;

  setUp(() {
    cache = _ThumbnailCache();
    files = _DocumentFiles();
    secrets = InMemorySecureStore();
    load = LoadDocumentPageThumbnail(cache, files, secrets);
  });

  test('forwards resolved path, page and protected password', () async {
    final protected = sampleDocument.copyWith(isProtected: true);
    await secrets.write(
      SecureStorageKeys.pdfPassword(protected.id.value),
      'secret',
    );

    final result = await load(protected, 3);

    expect(result.valueOrNull, '/cache/page.png');
    expect(cache.document, protected);
    expect(cache.filePath, '/materialised/document.pdf');
    expect(cache.pageNumber, 3);
    expect(cache.password, 'secret');
    expect(files.released, [protected.id]);
  });

  test('does not pass a secret for an unprotected document', () async {
    await secrets.write(
      SecureStorageKeys.pdfPassword(sampleDocument.id.value),
      'stale',
    );

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
