/// Loads disposable page previews from an authoritative library PDF.
library;

import 'package:doc_scanly/core/contracts/document_page_access.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/document_page_handle.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// Resolves, renders and releases one thumbnail-sized document page.
///
/// Keeping this orchestration in a use case prevents widgets from learning
/// device paths or reading secure storage. A failed release is deliberately
/// non-fatal: the platform cache can reclaim an orphaned materialised copy.
class LoadDocumentPageThumbnail {
  /// Creates the use case from explicit storage boundaries.
  const LoadDocumentPageThumbnail(this._cache, this._files);

  final DocumentThumbnailCache _cache;
  final DocumentFileResolver _files;

  /// Returns a private derived thumbnail path for [pageNumber].
  Future<Result<String>> call(Document document, int pageNumber) async {
    if (document.isProtected) {
      return const Result<String>.failure(Failure.auth());
    }
    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<String>.failure(failure);
    }

    try {
      return await _cache.thumbnailFor(
        document,
        filePath: resolved.valueOrNull!,
        pageNumber: pageNumber,
      );
    } finally {
      // Android materialises MediaStore content into cache for native PDFium.
      // Release on every success/failure path; cleanup failure does not hide a
      // successfully rendered preview or replace the rendering failure.
      await _files.release(document);
    }
  }
}

/// Materialises one unified page as a private thumbnail-sized image.
class LoadDocumentPagePreview {
  /// Creates the use case over shared [pages].
  const LoadDocumentPagePreview(this.pages);

  /// Unified scanned/PDF-backed page access.
  final DocumentPageAccessRepository pages;

  /// Returns a readable preview path for [page] of [document].
  Future<Result<String>> call(
    Document document,
    DocumentPageHandle page,
  ) async {
    final result = await pages.materialize(
      document,
      page,
      DocumentPageRenderPurpose.thumbnail,
    );
    return result.map(
      (materialized) => materialized.when(
        authoritative: (path) => path,
        cached: (path) => path,
        temporary: (path) => path,
      ),
    );
  }
}
