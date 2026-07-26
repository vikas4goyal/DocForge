/// The document and folder vocabulary shared across capabilities.
///
/// Six capabilities read documents (viewer, search, sharing, import, editing,
/// generation) and two more read folders, so these types live in
/// `core/contracts/` rather than inside `document-library`. That feature still
/// owns their persistence and lifecycle rules; it simply does not own the
/// vocabulary, which is what keeps features from importing each other.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// A stored document.
///
/// Holds metadata only. The PDF itself lives on disk at [filePath], inside
/// app-private storage, and is never loaded merely to display a list row.
@freezed
abstract class Document with _$Document {
  /// Creates a document record.
  const factory Document({
    required DocumentId id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Number of pages in the document. Always at least one.
    required int pageCount,

    /// Size of the stored PDF in bytes.
    required int sizeInBytes,

    /// Path to the PDF inside app-private storage.
    required String filePath,

    /// The folder this document belongs to, or null when unfiled.
    FolderId? folderId,
    @Default(false) bool isFavourite,
    @Default(false) bool isArchived,

    /// Whether the stored PDF is password-protected.
    ///
    /// The password itself is never held here — it lives in secure storage.
    @Default(false) bool isProtected,

    /// Whether text recognition has been run and produced a stored result.
    @Default(false) bool hasRecognisedText,
  }) = _Document;

  /// Creates a document from JSON.
  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  const Document._();

  /// Whether this document appears in the main document list.
  ///
  /// Archived documents are excluded from recents, lists and search unless
  /// explicitly requested, so this predicate is the single definition of
  /// "visible" that every list shares.
  bool get isVisibleInLibrary => !isArchived;

  /// Whether this document is unfiled.
  bool get isUnfiled => folderId == null;
}

/// A folder grouping documents.
@freezed
abstract class Folder with _$Folder {
  /// Creates a folder record.
  const factory Folder({
    required FolderId id,
    required String name,
    required DateTime createdAt,

    /// Number of non-archived documents the folder currently contains.
    ///
    /// Computed at read time rather than stored, so it cannot drift out of
    /// sync with the documents themselves.
    @Default(0) int documentCount,
  }) = _Folder;

  /// Creates a folder from JSON.
  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  const Folder._();

  /// Whether the folder currently holds no visible documents.
  bool get isEmpty => documentCount == 0;
}

/// A summary of the storage consumed by stored documents.
@freezed
abstract class StorageSummary with _$StorageSummary {
  /// Creates a storage summary.
  const factory StorageSummary({
    /// Total bytes used by stored PDFs, page images and thumbnails.
    required int totalBytes,

    /// Number of stored documents, including archived ones.
    required int documentCount,
  }) = _StorageSummary;

  /// Creates a storage summary from JSON.
  factory StorageSummary.fromJson(Map<String, dynamic> json) =>
      _$StorageSummaryFromJson(json);

  const StorageSummary._();

  /// An empty summary, used before any document exists.
  static const empty = StorageSummary(totalBytes: 0, documentCount: 0);
}

/// How a document list is ordered.
enum DocumentSort {
  /// Most recently modified first. The default for recents and lists.
  modifiedDescending,

  /// Oldest modification first.
  modifiedAscending,

  /// Most recently created first.
  createdDescending,

  /// Alphabetical by title.
  titleAscending,
}

/// Which subset of the library a document query returns.
enum DocumentFilter {
  /// Every non-archived document.
  all,

  /// Non-archived documents marked as favourite.
  favourites,

  /// Archived documents only.
  archived,

  /// Non-archived documents within a specific folder.
  folder,
}
