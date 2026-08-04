/// Isar collections for the document library, and their domain mappers.
///
/// These are storage shapes, deliberately separate from the domain types: Isar
/// requires mutable annotated classes with an integer primary key, which is the
/// opposite of the immutable, UUID-keyed value objects the rest of the app uses.
/// Mapping at the repository boundary keeps Isar's shape from leaking upward.
///
/// Schema notes that matter for future migrations:
///
/// * Every collection carries a `uuid` (stable across devices) *and* Isar's
///   auto-increment `id`. The UUID is the identity a future sync layer
///   reconciles on; the integer is a local storage detail that must never be
///   exposed or persisted anywhere else.
/// * `schemaVersion` is written on every row so a later release can detect and
///   upgrade older records without guessing.
/// * PDFs live in the user-visible library folder; only their library-relative
///   address lives here. A database holding binary blobs bloats, slows every
///   query and complicates backup — and an *absolute* path stored here would be
///   wrong after a restore and meaningless to a future sync layer.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/trash.dart';
import 'package:isar_community/isar.dart';

part 'isar_entities.g.dart';

/// Current schema version written to every row.
///
/// Bump when a collection's shape changes in a way an older row cannot satisfy,
/// and add the corresponding upgrade step.
/// Version 2 replaced `filePath` — an absolute device path into app-private
/// storage — with `folderPath` and `fileName`, which address the file inside
/// the user-visible library folder. See `LibraryStorageMigration`.
const librarySchemaVersion = 5;

/// Isar row for a document.
@collection
class DocumentEntity {
  /// Isar's local primary key. Never leaves this layer.
  Id id = Isar.autoIncrement;

  /// Stable cross-device identifier.
  @Index(unique: true, replace: true)
  late String uuid;

  /// Document title as entered by the user.
  late String title;

  /// Lower-cased words of [title], indexed for search.
  ///
  /// Isar has no full-text index type: word search is implemented by storing
  /// the tokenised words as a list and indexing its elements, which supports
  /// `anyStartsWith` prefix queries. Derived on write by [titleWordsOf] so it
  /// cannot drift from [title].
  @Index(type: IndexType.value, caseSensitive: false)
  late List<String> titleWords;

  /// When the document was created.
  late DateTime createdAt;

  /// When the document last changed. Indexed: every list sorts on it.
  @Index()
  late DateTime updatedAt;

  /// Number of pages.
  late int pageCount;

  /// Size of the stored PDF in bytes.
  late int sizeInBytes;

  /// The document's folder path relative to the library root.
  ///
  /// Empty for a document sitting directly in the library folder. Stored apart
  /// from [fileName] so a folder rename is one indexed update per document
  /// rather than a string rewrite per row.
  late String folderPath;

  /// The document's file name, including its `.pdf` extension.
  late String fileName;

  /// UUID of the owning folder, or null when unfiled. Indexed for folder views.
  @Index()
  String? folderUuid;

  /// Whether the user marked this document as a favourite.
  late bool isFavourite;

  /// Whether the document is archived. Indexed: every list filters on it.
  @Index()
  late bool isArchived;

  /// Whether the stored PDF is password-protected.
  late bool isProtected;

  /// Whether recognised text has been stored for this document.
  late bool hasRecognisedText;

  /// Stable iCloud resource identity. Null for local and legacy rows.
  @Index()
  String? cloudResourceIdentifier;

  /// Original iCloud-relative path used to materialise conflict copies.
  String? cloudRelativePath;

  /// Stored [DocumentContentAvailability] name.
  ///
  /// Nullable so rows written before schema version 4 read as local without a
  /// destructive database migration.
  String? contentAvailability;

  /// UUID of the Trash entry holding this document, when deleted.
  @Index()
  String? trashUuid;

  /// When this document was moved to Trash.
  DateTime? trashedAt;

  /// Schema version this row was written with.
  late int schemaVersion;

  /// Splits [title] into lower-cased searchable words.
  ///
  /// Punctuation is dropped and empty tokens removed, so "Invoice — Acme Ltd."
  /// indexes as [invoice, acme, ltd].
  static List<String> titleWordsOf(String title) => title
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();

  /// Builds a row from [document].
  static DocumentEntity fromDomain(Document document) => DocumentEntity()
    ..uuid = document.id.value
    ..title = document.title
    ..titleWords = titleWordsOf(document.title)
    ..createdAt = document.createdAt.toUtc()
    ..updatedAt = document.updatedAt.toUtc()
    ..pageCount = document.pageCount
    ..sizeInBytes = document.sizeInBytes
    ..folderPath = document.libraryPath.folderPath
    ..fileName = document.libraryPath.fileName
    ..folderUuid = document.folderId?.value
    ..isFavourite = document.isFavourite
    ..isArchived = document.isArchived
    ..isProtected = document.isProtected
    ..hasRecognisedText = document.hasRecognisedText
    ..cloudResourceIdentifier = document.cloudResourceIdentifier
    ..cloudRelativePath = document.cloudRelativePath
    ..contentAvailability = document.contentAvailability.name
    ..trashUuid = document.trashId?.value
    ..trashedAt = document.trashedAt?.toUtc()
    ..schemaVersion = librarySchemaVersion;

  /// Converts this row to its domain type.
  ///
  /// Timestamps are normalised back to UTC: Isar always returns `DateTime` in
  /// local time, so a UTC value written here reads back with `isUtc == false`.
  /// The instant is unchanged, but the two are not `==`, and a future sync
  /// layer reconciling devices in different timezones needs one canonical
  /// representation. The domain is UTC throughout.
  Document toDomain() => Document(
    id: DocumentId(uuid),
    title: title,
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    pageCount: pageCount,
    sizeInBytes: sizeInBytes,
    libraryPath: LibraryPath.raw(
      folders: folderPath.isEmpty ? const [] : folderPath.split('/'),
      fileName: fileName,
    ),
    folderId: folderUuid == null ? null : FolderId(folderUuid!),
    isFavourite: isFavourite,
    isArchived: isArchived,
    isProtected: isProtected,
    hasRecognisedText: hasRecognisedText,
    cloudResourceIdentifier: cloudResourceIdentifier,
    cloudRelativePath: cloudRelativePath,
    contentAvailability: DocumentContentAvailability.values.firstWhere(
      (value) => value.name == contentAvailability,
      orElse: () => DocumentContentAvailability.local,
    ),
    trashId: trashUuid == null ? null : TrashId(trashUuid!),
    trashedAt: trashedAt?.toUtc(),
  );
}

/// Isar row for a recoverable Trash entry.
@collection
class TrashEntity {
  /// Isar's local primary key.
  Id id = Isar.autoIncrement;

  /// Stable Trash identifier.
  @Index(unique: true, replace: true)
  late String uuid;

  /// Stored [TrashEntryKind] name.
  late String kind;

  /// Human-readable name shown in Trash.
  late String displayName;

  /// Location before deletion, relative to the library root.
  late String originalRelativePath;

  /// Deletion instant, indexed for newest-first presentation.
  @Index()
  late DateTime deletedAt;

  /// Automatic permanent-deletion boundary.
  @Index()
  late DateTime expiresAt;

  /// Recursive inventory values.
  late int documentCount;

  /// Recursive non-document files.
  late int otherFileCount;

  /// Recursive descendant folders.
  late int folderCount;

  /// Recursive file bytes.
  late int sizeInBytes;

  /// Documents whose metadata must be restored or purged with this payload.
  late List<String> documentUuids;

  /// Folder records belonging to this tree.
  late List<String> folderUuids;

  /// Schema version this row was written with.
  late int schemaVersion;

  /// Builds a row from [entry].
  static TrashEntity fromDomain(TrashEntry entry) => TrashEntity()
    ..uuid = entry.id.value
    ..kind = entry.kind.name
    ..displayName = entry.displayName
    ..originalRelativePath = entry.originalRelativePath
    ..deletedAt = entry.deletedAt.toUtc()
    ..expiresAt = entry.expiresAt.toUtc()
    ..documentCount = entry.inventory.documentCount
    ..otherFileCount = entry.inventory.otherFileCount
    ..folderCount = entry.inventory.folderCount
    ..sizeInBytes = entry.inventory.sizeInBytes
    ..documentUuids = entry.documentIds.map((id) => id.value).toList()
    ..folderUuids = entry.folderIds.map((id) => id.value).toList()
    ..schemaVersion = librarySchemaVersion;

  /// Converts this row to its domain type.
  TrashEntry toDomain() => TrashEntry(
    id: TrashId(uuid),
    kind: TrashEntryKind.values.firstWhere(
      (value) => value.name == kind,
      orElse: () => TrashEntryKind.document,
    ),
    displayName: displayName,
    originalRelativePath: originalRelativePath,
    deletedAt: deletedAt.toUtc(),
    expiresAt: expiresAt.toUtc(),
    inventory: TrashInventory(
      documentCount: documentCount,
      otherFileCount: otherFileCount,
      folderCount: folderCount,
      sizeInBytes: sizeInBytes,
    ),
    documentIds: documentUuids.map(DocumentId.new).toList(),
    folderIds: folderUuids.map(FolderId.new).toList(),
  );
}

/// Isar row for a folder.
@collection
class FolderEntity {
  /// Isar's local primary key.
  Id id = Isar.autoIncrement;

  /// Stable cross-device identifier.
  @Index(unique: true, replace: true)
  late String uuid;

  /// Folder name. Indexed so duplicate names can be rejected cheaply.
  @Index(caseSensitive: false)
  late String name;

  /// The folder's path relative to the library root.
  ///
  /// Stored as well as [name] because folders nest: `name` is what the user
  /// reads on a row, `relativePath` is what addresses the directory on disk.
  late String relativePath;

  /// When the folder was created.
  late DateTime createdAt;

  /// UUID of the Trash entry holding this folder tree.
  @Index()
  String? trashUuid;

  /// When the folder tree moved to Trash.
  DateTime? trashedAt;

  /// Schema version this row was written with.
  late int schemaVersion;

  /// Builds a row from [folder].
  ///
  /// The document count is deliberately not stored: it is computed at read time
  /// so it cannot drift out of sync with the documents themselves.
  static FolderEntity fromDomain(Folder folder) => FolderEntity()
    ..uuid = folder.id.value
    ..name = folder.name
    ..relativePath = folder.relativePath
    ..createdAt = folder.createdAt.toUtc()
    ..trashUuid = folder.trashId?.value
    ..trashedAt = folder.trashedAt?.toUtc()
    ..schemaVersion = librarySchemaVersion;

  /// Converts this row to its domain type, reporting [documentCount].
  ///
  /// [createdAt] is normalised to UTC — see [DocumentEntity.toDomain].
  Folder toDomain({int documentCount = 0}) => Folder(
    id: FolderId(uuid),
    name: name,
    relativePath: relativePath,
    createdAt: createdAt.toUtc(),
    documentCount: documentCount,
    trashId: trashUuid == null ? null : TrashId(trashUuid!),
    trashedAt: trashedAt?.toUtc(),
  );
}

/// Isar row for a page.
@collection
class PageEntity {
  /// Isar's local primary key.
  Id id = Isar.autoIncrement;

  /// Stable cross-device identifier.
  @Index(unique: true, replace: true)
  late String uuid;

  /// UUID of the owning document. Indexed: pages are always queried per document.
  @Index()
  late String documentUuid;

  /// Zero-based position within the document.
  late int order;

  /// Path to the page image inside app-private storage.
  late String imagePath;

  /// Cached display-resolution thumbnail path, when one exists.
  String? thumbnailPath;

  /// Clockwise rotation in degrees.
  late int rotationDegrees;

  /// Applied enhancement filter, stored by name.
  late String enhancementFilter;

  /// Brightness offset.
  late double brightness;

  /// Contrast offset.
  late double contrast;

  /// Sharpening amount.
  late double sharpen;

  /// Whether shadow removal was applied.
  late bool shadowRemoval;

  /// Schema version this row was written with.
  late int schemaVersion;

  /// Builds a row from [page].
  static PageEntity fromDomain(DocumentPage page) => PageEntity()
    ..uuid = page.id.value
    ..documentUuid = page.documentId.value
    ..order = page.order
    ..imagePath = page.imagePath
    ..thumbnailPath = page.thumbnailPath
    ..rotationDegrees = page.rotation.degrees
    ..enhancementFilter = page.enhancement.filter.name
    ..brightness = page.enhancement.brightness
    ..contrast = page.enhancement.contrast
    ..sharpen = page.enhancement.sharpen
    ..shadowRemoval = page.enhancement.shadowRemoval
    ..schemaVersion = librarySchemaVersion;

  /// Converts this row to its domain type.
  DocumentPage toDomain() => DocumentPage(
    id: PageId(uuid),
    documentId: DocumentId(documentUuid),
    order: order,
    imagePath: imagePath,
    thumbnailPath: thumbnailPath,
    rotation: _rotationFromDegrees(rotationDegrees),
    enhancement: EnhancementSettings(
      filter: _filterFromName(enhancementFilter),
      brightness: brightness,
      contrast: contrast,
      sharpen: sharpen,
      shadowRemoval: shadowRemoval,
    ),
  );

  /// Maps stored degrees back to a rotation.
  ///
  /// Falls back to no rotation rather than throwing: a row written by a future
  /// version with an unknown value should still render, just unrotated.
  static PageRotation _rotationFromDegrees(int degrees) => PageRotation.values
      .firstWhere((r) => r.degrees == degrees, orElse: () => PageRotation.none);

  /// Maps a stored filter name back to its enum value.
  ///
  /// Falls back to the original image for the same reason.
  static EnhancementFilter _filterFromName(String name) =>
      EnhancementFilter.values.firstWhere(
        (f) => f.name == name,
        orElse: () => EnhancementFilter.original,
      );
}
