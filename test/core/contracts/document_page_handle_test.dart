import 'package:doc_scanly/core/contracts/models/document_page_handle.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const documentId = DocumentId('document-a');

  test('virtual PDF page identities are stable and source namespaced', () {
    final first = DocumentPageHandle.virtualPdfPageId(documentId, 1);
    final again = DocumentPageHandle.virtualPdfPageId(documentId, 1);
    final next = DocumentPageHandle.virtualPdfPageId(documentId, 2);

    expect(first, again);
    expect(first, isNot(next));
    expect(first.value, startsWith('pdf-page:'));
  });

  test('Freezed page handles compare every identity and source field', () {
    const handle = DocumentPageHandle(
      id: PageId('stored-page'),
      documentId: documentId,
      pageNumber: 1,
      source: DocumentPageSource.storedImage(
        imagePath: '/pages/one.jpg',
        thumbnailPath: '/thumbs/one.jpg',
      ),
    );

    expect(handle, handle.copyWith());
    expect(handle, isNot(handle.copyWith(pageNumber: 2)));
    expect(
      handle,
      isNot(handle.copyWith(source: const DocumentPageSource.pdfPage())),
    );
  });

  test('render purposes keep all pixel bounds finite and explicit', () {
    expect(
      DocumentPageRenderPurpose.values.map((purpose) => purpose.maxWidth),
      everyElement(greaterThan(0)),
    );
    expect(DocumentPageRenderPurpose.thumbnail.retainsCache, isTrue);
    expect(DocumentPageRenderPurpose.sharing.retainsCache, isFalse);
  });
}
