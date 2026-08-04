/// The document and folder vocabulary shared across capabilities.
///
/// Six capabilities read documents (viewer, search, sharing, import, editing,
/// generation) and two more read folders, so these types live in
/// `core/contracts/` rather than inside `document-library`. That feature still
/// owns their persistence and lifecycle rules; it simply does not own the
/// vocabulary, which is what keeps features from importing each other.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// A stored document.
///
/// Holds metadata only. The PDF itself lives in the user-visible library folder
/// at [libraryPath], and is never loaded merely to display a list row.
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

    /// Where the PDF lives, relative to the library folder.
    ///
    /// A library-relative address rather than a device path: the same document
    /// resolves to a real file on iOS and to a MediaStore item on Android, and
    /// a stored absolute path would be wrong on the next launch after a restore
    /// and meaningless to a future sync layer (`design.md` D1).
    required LibraryPath libraryPath,

    /// The folder this document belongs to, or null when unfiled.
    ///
    /// Retained alongside [libraryPath] because a folder carries its own
    /// identity and creation date, and because a device that refused to create
    /// a nested folder stores the file flat while the document still belongs to
    /// the folder the user chose.
    FolderId? folderId,
    @Default(false) bool isFavourite,
    @Default(false) bool isArchived,

    /// Whether the stored PDF is password-protected.
    ///
    /// The password itself is never held here — it lives in secure storage.
    @Default(false) bool isProtected,

    /// Whether text recognition has been run and produced a stored result.
    @Default(false) bool hasRecognisedText,

    /// Stable iCloud resource identity, when Foundation supplied one.
    ///
    /// This is metadata only. Local and Android documents leave it null.
    String? cloudResourceIdentifier,

    /// Original path reported by iCloud for byte operations.
    ///
    /// Usually this equals [libraryPath]. A simultaneous same-name conflict is
    /// indexed under a deterministic non-overwriting display path while this
    /// field retains the actual container path that Foundation must download.
    String? cloudRelativePath,

    /// Whether the authoritative PDF bytes are readable on this device.
    ///
    /// Android documents always retain the default [DocumentContentAvailability.local].
    @Default(DocumentContentAvailability.local)
    DocumentContentAvailability contentAvailability,

    /// Trash entry holding the PDF, or null while the document is active.
    TrashId? trashId,

    /// UTC instant at which this document was moved to Trash.
    DateTime? trashedAt,
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
  bool get isVisibleInLibrary => !isArchived && trashId == null;

  /// Whether this document is unfiled.
  bool get isUnfiled => folderId == null;

  /// The document's file name including its extension.
  String get fileName => libraryPath.fileName;

  /// The document's location relative to the library folder.
  String get relativePath => libraryPath.relative;
}

/// Availability of a document's authoritative PDF bytes on this device.
enum DocumentContentAvailability {
  /// The document belongs to the device-local library.
  local,

  /// iCloud metadata is known but the PDF has not been downloaded.
  remote,

  /// iCloud is currently materialising the PDF.
  downloading,

  /// The cloud-backed PDF is readable locally.
  available,

  /// The latest materialisation attempt failed and can be retried.
  failed,
}

/// A folder grouping documents.
@freezed
abstract class Folder with _$Folder {
  /// Creates a folder record.
  const factory Folder({
    required FolderId id,
    required String name,
    required DateTime createdAt,

    /// The folder's path relative to the library root, e.g. `Invoices/2026`.
    ///
    /// Folders are real directories in the user-visible library folder, so a
    /// folder needs an address as well as a name — two folders called `2026`
    /// under different parents are different folders.
    @Default('') String relativePath,

    /// Number of non-archived documents the folder currently contains.
    ///
    /// Computed at read time rather than stored, so it cannot drift out of
    /// sync with the documents themselves.
    @Default(0) int documentCount,

    /// Trash entry holding this folder tree, or null while active.
    TrashId? trashId,

    /// UTC instant at which this folder moved to Trash.
    DateTime? trashedAt,
  }) = _Folder;

  /// Creates a folder from JSON.
  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  const Folder._();

  /// Whether the folder currently holds no visible documents.
  bool get isEmpty => documentCount == 0;

  /// Whether this folder appears in active folder pickers and lists.
  bool get isVisibleInLibrary => trashId == null;
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
