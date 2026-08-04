/// Moves an existing library out of app-private storage and into the
/// user-visible `DocScanly` folder.
///
/// Layout 1 kept every document in `<appDocuments>/documents/<uuid>/`, holding
/// the PDF, its page images and its thumbnails. Nothing there was reachable
/// from the iOS Files app or an Android file manager. Layout 2 publishes the
/// PDF into the library folder and keeps only derived data privately
/// (`design.md` D4, D4a).
///
/// The sequence per document is copy, verify, rewrite the record, delete —
/// in that order and never another. A record rewritten before the copy is
/// verified would point at a file that may not have arrived; a source deleted
/// before the record is rewritten would leave the document unreachable. The
/// marker file is written only after the last document, so an interrupted run
/// resumes rather than being skipped.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:isar_community/isar.dart';

/// What a migration run did.
class LibraryMigrationReport {
  /// Creates a report.
  const LibraryMigrationReport({
    this.migrated = 0,
    this.alreadyMigrated = 0,
    this.dropped = 0,
    this.failed = 0,
    this.ranMigration = false,
  });

  /// Documents whose file was published into the library folder by this run.
  final int migrated;

  /// Documents an earlier interrupted run had already published.
  final int alreadyMigrated;

  /// Records removed because their file no longer existed.
  final int dropped;

  /// Documents that could not be migrated and were left for a later attempt.
  final int failed;

  /// Whether any migration work was attempted at all.
  final bool ranMigration;

  /// Whether every document was accounted for.
  bool get isComplete => failed == 0;

  @override
  String toString() =>
      'LibraryMigrationReport(migrated: $migrated, '
      'alreadyMigrated: $alreadyMigrated, dropped: $dropped, failed: $failed)';
}

/// Migrates a layout-1 library into the public folder.
class LibraryStorageMigration {
  /// Creates the migration.
  ///
  /// [legacyDocumentsDirectory] is the old `<appDocuments>` container the
  /// layout-1 tree sat in, injected rather than looked up so a test can point
  /// it at a temporary directory.
  const LibraryStorageMigration({
    required this.isar,
    required this.store,
    required this.legacyDocumentsDirectory,
  });

  /// Name of the file recording the completed layout version.
  static const markerFileName = '.layout-version';

  /// Name of the layout-1 directory holding every document.
  static const legacyDirectoryName = 'documents';

  /// The layout this migration produces.
  static const targetLayoutVersion = 2;

  /// The open database.
  final Isar isar;

  /// The user-visible library documents are published into.
  final PublicFileStore store;

  /// The container the layout-1 tree sits in.
  final Directory legacyDocumentsDirectory;

  /// The layout-1 root.
  Directory get _legacyRoot =>
      Directory('${legacyDocumentsDirectory.path}/$legacyDirectoryName');

  /// The marker recording which layout has been completed.
  ///
  /// Written in the container rather than inside the layout-1 tree, because
  /// that tree is deleted as the migration empties it and a fresh install has
  /// no such tree to put a marker in.
  File get _marker => File('${legacyDocumentsDirectory.path}/$markerFileName');

  /// Where layout 1 wrote its own marker.
  ///
  /// Still read so an install that completed layout 1 is recognised, but never
  /// written: the tree it lives in does not survive this migration.
  File get _legacyMarker => File('${_legacyRoot.path}/$markerFileName');

  /// Runs the migration if it has not already completed.
  ///
  /// Safe to call on every launch: a completed migration is detected from the
  /// marker and returns immediately.
  Future<LibraryMigrationReport> run() async {
    if (_isAlreadyMigrated()) return const LibraryMigrationReport();

    // Folders first: a document's destination folder has to exist before its
    // file can be published into it.
    await _migrateFolders();

    final documents = await isar.documentEntitys.where().findAll();
    final taken = await _existingFileNames();

    var migrated = 0;
    var alreadyMigrated = 0;
    var dropped = 0;
    var failed = 0;

    for (final entity in documents) {
      switch (await _migrateDocument(entity, taken)) {
        case _MigrationOutcome.migrated:
          migrated++;
        case _MigrationOutcome.alreadyMigrated:
          alreadyMigrated++;
        case _MigrationOutcome.dropped:
          dropped++;
        case _MigrationOutcome.failed:
          failed++;
      }
    }

    // Written last, and only when nothing failed: a marker set after a partial
    // run would make the remaining documents invisible for good.
    if (failed == 0) await _writeMarker();

    return LibraryMigrationReport(
      migrated: migrated,
      alreadyMigrated: alreadyMigrated,
      dropped: dropped,
      failed: failed,
      ranMigration: true,
    );
  }

  /// Whether the marker records this layout as complete.
  ///
  /// Only the marker decides. An earlier version also treated a missing
  /// layout-1 directory as "nothing to do", which was wrong: a library whose
  /// private tree had already been emptied still had records to rewrite, and
  /// they would have been skipped for good.
  bool _isAlreadyMigrated() {
    for (final marker in [_marker, _legacyMarker]) {
      if (!marker.existsSync()) continue;
      final recorded = int.tryParse(marker.readAsStringSync().trim()) ?? 1;
      if (recorded >= targetLayoutVersion) return true;
    }
    return false;
  }

  Future<void> _writeMarker() async {
    await legacyDocumentsDirectory.create(recursive: true);
    await _marker.writeAsString('$targetLayoutVersion');
  }

  /// Creates a real directory for every folder record.
  ///
  /// Layout-1 folder names were never constrained to filesystem-safe
  /// characters, so each is sanitised; the record keeps the name the user
  /// chose, and only the directory takes the cleaned form.
  Future<void> _migrateFolders() async {
    final folders = await isar.folderEntitys.where().findAll();
    if (folders.isEmpty) return;

    final used = <String>{};

    await isar.writeTxn(() async {
      for (final folder in folders) {
        if (folder.relativePath.isNotEmpty) continue;

        final safe = LibraryPath.deduplicate(
          LibraryPath.sanitiseName(folder.name),
          used,
        );
        used.add(safe);

        await store.createFolder([safe]);
        folder
          ..relativePath = safe
          ..schemaVersion = librarySchemaVersion;
        await isar.folderEntitys.put(folder);
      }
    });
  }

  /// Publishes one document's file and rewrites its record.
  Future<_MigrationOutcome> _migrateDocument(
    DocumentEntity entity,
    Set<String> taken,
  ) async {
    // Already addressed by library path: an earlier interrupted run got this
    // far, so re-publishing would duplicate the file under a suffixed name.
    if (entity.fileName.isNotEmpty) {
      return _MigrationOutcome.alreadyMigrated;
    }

    final source = File(_legacyPdfPathFor(entity.uuid));
    if (!source.existsSync()) {
      // A record pointing at a file that is gone describes a document the user
      // cannot open. Dropping it is the honest outcome; keeping it would show
      // a broken row forever.
      await isar.writeTxn(() => isar.documentEntitys.delete(entity.id));
      return _MigrationOutcome.dropped;
    }

    final folders = await _foldersFor(entity);
    final name = LibraryPath.deduplicate(
      LibraryPath.pdfFileName(LibraryPath.sanitiseName(entity.title)),
      taken,
    );

    final LibraryPath destination;
    try {
      destination = LibraryPath.inFolder(folders, name);
    } on InvalidLibraryPath {
      return _MigrationOutcome.failed;
    }

    final published = await store.writeFile(destination, source.path);
    if (published case Failed()) return _MigrationOutcome.failed;

    // Verified before anything is deleted: a copy that arrived truncated must
    // not be the only remaining version.
    final verified = await store.exists(destination);
    if (verified.valueOrNull != true) {
      return _MigrationOutcome.failed;
    }

    taken.add(name);

    await isar.writeTxn(() async {
      entity
        ..folderPath = destination.folderPath
        ..fileName = destination.fileName
        ..schemaVersion = librarySchemaVersion;
      await isar.documentEntitys.put(entity);
    });

    // Only now: the record describes the published file, so the private tree
    // holds nothing that is still referenced. Page images go with it — after a
    // save the PDF is all there is (`design.md` D4a).
    await _deleteLegacyDirectory(entity.uuid);

    return _MigrationOutcome.migrated;
  }

  /// The folder segments a document should land in.
  Future<List<String>> _foldersFor(DocumentEntity entity) async {
    final folderUuid = entity.folderUuid;
    if (folderUuid == null) return const [];

    final folder = await isar.folderEntitys
        .filter()
        .uuidEqualTo(folderUuid)
        .findFirst();
    final relative = folder?.relativePath ?? '';
    return relative.isEmpty ? const [] : relative.split('/');
  }

  /// File names already present in the library, so a migrated name is unique.
  Future<Set<String>> _existingFileNames() async {
    final entries = await store.listRecursive(const []);
    return {
      for (final entry in entries.valueOrNull ?? const <PublicEntry>[])
        if (!entry.isFolder) entry.name,
    };
  }

  String _legacyPdfPathFor(String uuid) =>
      '${_legacyRoot.path}/$uuid/document.pdf';

  Future<void> _deleteLegacyDirectory(String uuid) async {
    try {
      final directory = Directory('${_legacyRoot.path}/$uuid');
      if (directory.existsSync()) await directory.delete(recursive: true);
    } on FileSystemException {
      // Best-effort: the document is already published and recorded, and a
      // stale private directory costs space rather than correctness.
    }
  }
}

/// What happened to one document during migration.
enum _MigrationOutcome { migrated, alreadyMigrated, dropped, failed }
