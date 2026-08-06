/// The contract for a document's on-disk files.
///
/// Declared in the domain layer because use cases depend on it: purging a
/// document deletes its files, duplicating one copies them. The concrete
/// layout — which directory, which extension — is an infrastructure concern
/// and lives in `infrastructure/datasource/document_file_store.dart`.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Resolves and manages paths for a document's files.
abstract interface class DocumentFileStore {
  /// Prepares the storage area and returns the root documents directory.
  ///
  /// Writes the layout-version marker if it is absent. Call once at startup.
  Future<Result<Directory>> initialise();

  /// Returns the directory holding [id]'s files, creating it if needed.
  Future<Result<Directory>> directoryFor(DocumentId id);

  /// Returns the path the PDF for [id] is stored at.
  ///
  /// A path, not a file: the caller writes it. Composing paths in one place
  /// stops the layout being re-derived — and mis-derived — per call site.
  Future<Result<String>> pdfPathFor(DocumentId id);

  /// Returns the path the image for [pageId] of [documentId] is stored at.
  Future<Result<String>> pagePathFor(DocumentId documentId, PageId pageId);

  /// Returns the path the thumbnail for [pageId] of [documentId] is stored at.
  Future<Result<String>> thumbnailPathFor(DocumentId documentId, PageId pageId);

  /// Deletes every file belonging to [id].
  ///
  /// Succeeds when the directory is already absent: permanent removal must be
  /// idempotent, or a retry after a partial failure would itself fail.
  Future<Result<void>> deleteDocument(DocumentId id);

  /// Copies every file of [from] into a new directory for [to].
  ///
  /// Used when duplicating a document, which must produce an independent copy
  /// rather than two records sharing one file.
  Future<Result<void>> copyDocument(DocumentId from, DocumentId to);

  /// Returns the total bytes used by every stored document.
  Future<Result<int>> totalBytes();
}
