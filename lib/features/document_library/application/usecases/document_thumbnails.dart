/// Loads disposable page previews from an authoritative library PDF.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// Resolves, renders and releases one thumbnail-sized document page.
///
/// Keeping this orchestration in a use case prevents widgets from learning
/// device paths or reading secure storage. A failed release is deliberately
/// non-fatal: the platform cache can reclaim an orphaned materialised copy.
class LoadDocumentPageThumbnail {
  /// Creates the use case from explicit storage boundaries.
  const LoadDocumentPageThumbnail(this._cache, this._files, this._secrets);

  final DocumentThumbnailCache _cache;
  final DocumentFileResolver _files;
  final SecureStore _secrets;

  /// Returns a private derived thumbnail path for [pageNumber].
  Future<Result<String>> call(Document document, int pageNumber) async {
    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<String>.failure(failure);
    }

    try {
      final password = document.isProtected
          ? (await _secrets.read(
              SecureStorageKeys.pdfPassword(document.id.value),
            )).valueOrNull
          : null;
      return await _cache.thumbnailFor(
        document,
        filePath: resolved.valueOrNull!,
        pageNumber: pageNumber,
        password: password,
      );
    } finally {
      // Android materialises MediaStore content into cache for native PDFium.
      // Release on every success/failure path; cleanup failure does not hide a
      // successfully rendered preview or replace the rendering failure.
      await _files.release(document);
    }
  }
}
