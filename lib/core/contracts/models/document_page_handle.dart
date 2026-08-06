/// Unified page identities and materialisation values for stored documents.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_page_handle.freezed.dart';

/// Describes where a document page's authoritative pixels come from.
@freezed
sealed class DocumentPageSource with _$DocumentPageSource {
  /// Creates a source backed by an app-private captured or imported image.
  const factory DocumentPageSource.storedImage({
    required String imagePath,
    String? thumbnailPath,
  }) = StoredImageDocumentPageSource;

  /// Creates a source backed by a page inside the authoritative PDF.
  const factory DocumentPageSource.pdfPage() = PdfDocumentPageSource;
}

/// Identifies one ordered page independently of how its pixels are stored.
@freezed
abstract class DocumentPageHandle with _$DocumentPageHandle {
  /// Creates a page handle.
  const factory DocumentPageHandle({
    required PageId id,
    required DocumentId documentId,
    required int pageNumber,
    required DocumentPageSource source,
  }) = _DocumentPageHandle;

  const DocumentPageHandle._();

  /// Creates the deterministic identity for page [pageNumber] of an imported PDF.
  ///
  /// The `pdf-page` namespace prevents a virtual page from colliding with a
  /// stored scan page even when external document identifiers are unusual.
  static PageId virtualPdfPageId(DocumentId documentId, int pageNumber) =>
      PageId('pdf-page:${documentId.value}:$pageNumber');
}

/// Why a consumer needs a page image.
enum DocumentPageRenderPurpose {
  /// A small list or Detail preview.
  thumbnail(maxWidth: 320, retainsCache: true),

  /// A bounded image suitable for on-device recognition.
  recognition(maxWidth: 1600, retainsCache: false),

  /// A bounded image handed to the system share sheet.
  sharing(maxWidth: 2048, retainsCache: false);

  const DocumentPageRenderPurpose({
    required this.maxWidth,
    required this.retainsCache,
  });

  /// Maximum rendered width in physical pixels.
  final int maxWidth;

  /// Whether the materialised file is a reusable cache entry.
  final bool retainsCache;
}

/// A readable image produced for a document-page consumer.
@freezed
sealed class MaterializedDocumentPage with _$MaterializedDocumentPage {
  /// Creates a value that points at authoritative retained image content.
  const factory MaterializedDocumentPage.authoritative({required String path}) =
      AuthoritativeDocumentPage;

  /// Creates a value backed by a reusable private cache entry.
  const factory MaterializedDocumentPage.cached({required String path}) =
      CachedDocumentPage;

  /// Creates a value that must be released after the current operation.
  const factory MaterializedDocumentPage.temporary({required String path}) =
      TemporaryDocumentPage;
}
