import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_scanly/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shares imported PDF pages without stored DocumentPage rows', () async {
    final document = sampleDocument.copyWith(pageCount: 2);
    final reader = _Reader(document);
    final access = _PageAccess(document);
    final share = FakeShareRepository();
    final useCase = SharePageImages(
      reader,
      share,
      const InlineBackgroundWorker(),
      () => throw StateError('stored-page staging must not be used'),
      (_) => throw StateError('stored-page renderer must not be used'),
      access,
    );

    final events = await useCase(document.id).toList();

    expect(events.whereType<SharePreparationProgress>(), hasLength(2));
    expect(events.whereType<SharePreparationReady>(), hasLength(1));
    expect(share.shared.single.filePaths, [
      '/tmp/imported-1.png',
      '/tmp/imported-2.png',
    ]);
    expect(access.released, 2);
  });
}

class _Reader implements DocumentReader {
  const _Reader(this.document);

  final Document document;

  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      Result<Document>.success(document);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => Result<List<Document>>.success([document]);
}

class _PageAccess implements DocumentPageAccessRepository {
  _PageAccess(Document document)
    : handles = List.generate(
        document.pageCount,
        (index) => DocumentPageHandle(
          id: DocumentPageHandle.virtualPdfPageId(document.id, index + 1),
          documentId: document.id,
          pageNumber: index + 1,
          source: const DocumentPageSource.pdfPage(),
        ),
      );

  final List<DocumentPageHandle> handles;
  int released = 0;

  @override
  Future<Result<String?>> embeddedText(
    Document document,
    DocumentPageHandle page,
  ) async => const Result<String?>.success(null);

  @override
  Future<Result<MaterializedDocumentPage>> materialize(
    Document document,
    DocumentPageHandle page,
    DocumentPageRenderPurpose purpose,
  ) async => Result<MaterializedDocumentPage>.success(
    MaterializedDocumentPage.temporary(
      path: '/tmp/imported-${page.pageNumber}.png',
    ),
  );

  @override
  Future<Result<List<DocumentPageHandle>>> pagesOf(Document document) async =>
      Result<List<DocumentPageHandle>>.success(handles);

  @override
  Future<Result<void>> release(MaterializedDocumentPage page) async {
    released += 1;
    return const Result<void>.success(null);
  }
}
