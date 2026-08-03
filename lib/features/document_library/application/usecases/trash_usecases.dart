/// Recoverable Trash lifecycle use cases.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/contracts/models/trash.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/domain/repositories/library_repositories.dart';

/// Measures a deletion candidate without changing it.
class InspectTrashCandidate {
  /// Creates the use case.
  const InspectTrashCandidate(this._store);

  final PublicFileStore _store;

  /// Measures [file] or [folder], exactly one of which must be supplied.
  Future<Result<TrashInventory>> call({
    LibraryPath? file,
    List<String>? folder,
  }) async {
    final result = await _store.inventory(file: file, folder: folder);
    return result.map(
      (value) => TrashInventory(
        documentCount: value.documentCount,
        otherFileCount: value.otherFileCount,
        folderCount: value.folderCount,
        sizeInBytes: value.sizeInBytes,
      ),
    );
  }
}

/// Moves one document into recoverable Trash.
class MoveDocumentToTrash {
  /// Creates the use case.
  const MoveDocumentToTrash(
    this._documents,
    this._trash,
    this._store,
    this._clock,
    this._ids,
  );

  final DocumentRepository _documents;
  final TrashRepository _trash;
  final PublicFileStore _store;
  final Clock _clock;
  final IdGenerator _ids;

  /// Moves [id], preserving all metadata for restoration.
  Future<Result<TrashEntry>> call(DocumentId id) async {
    final found = await _documents.findById(id);
    if (found case Failed(:final failure)) {
      return Result<TrashEntry>.failure(failure);
    }
    final document = found.valueOrNull!;
    if (document.trashId != null) {
      return _trash.findById(document.trashId!);
    }

    final measured = await _store.inventory(file: document.libraryPath);
    if (measured case Failed(:final failure)) {
      return Result<TrashEntry>.failure(failure);
    }
    final now = _clock.now().toUtc();
    final trashId = TrashId(_ids.generate());
    final inventory = measured.valueOrNull!;
    final entry = TrashEntry(
      id: trashId,
      kind: TrashEntryKind.document,
      displayName: document.title,
      originalRelativePath: document.relativePath,
      deletedAt: now,
      expiresAt: TrashEntry.expiryFor(now),
      inventory: TrashInventory(
        documentCount: 1,
        otherFileCount: inventory.otherFileCount,
        folderCount: inventory.folderCount,
        sizeInBytes: inventory.sizeInBytes,
      ),
      documentIds: [document.id],
    );

    final moved = await _store.moveFileToTrash(
      trashId.value,
      document.libraryPath,
    );
    if (moved case Failed(:final failure)) {
      return Result<TrashEntry>.failure(failure);
    }
    final marked = await _documents.save(
      document.copyWith(trashId: trashId, trashedAt: now),
    );
    if (marked case Failed(:final failure)) {
      await _store.restoreFileFromTrash(
        trashId.value,
        document.fileName,
        document.libraryPath,
      );
      return Result<TrashEntry>.failure(failure);
    }
    final saved = await _trash.save(entry);
    if (saved case Failed(:final failure)) {
      await _documents.save(document);
      await _store.restoreFileFromTrash(
        trashId.value,
        document.fileName,
        document.libraryPath,
      );
      return Result<TrashEntry>.failure(failure);
    }
    return saved;
  }
}

/// Moves a complete folder tree into recoverable Trash.
class MoveFolderTreeToTrash {
  /// Creates the use case.
  const MoveFolderTreeToTrash(
    this._documents,
    this._folders,
    this._trash,
    this._store,
    this._clock,
    this._ids,
  );

  final DocumentRepository _documents;
  final FolderRepository _folders;
  final TrashRepository _trash;
  final PublicFileStore _store;
  final Clock _clock;
  final IdGenerator _ids;

  /// Moves [path], including indexed documents, unknown files and empty folders.
  Future<Result<TrashEntry>> call(List<String> path) async {
    if (path.isEmpty) {
      return const Result<TrashEntry>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: 'the library root cannot be moved to Trash',
        ),
      );
    }
    final measured = await _store.inventory(folder: path);
    if (measured case Failed(:final failure)) {
      return Result<TrashEntry>.failure(failure);
    }
    final documents = await _activeAndArchivedDocuments(_documents);
    if (documents case Failed(:final failure)) {
      return Result<TrashEntry>.failure(failure);
    }
    final prefix = '${path.join('/')}/';
    final affected = documents.valueOrNull!
        .where((document) => document.relativePath.startsWith(prefix))
        .toList();
    final loadedFolders = await _folders.all();
    if (loadedFolders case Failed(:final failure)) {
      return Result<TrashEntry>.failure(failure);
    }
    final folderPath = path.join('/');
    final affectedFolders = loadedFolders.valueOrNull!
        .where(
          (folder) =>
              folder.relativePath == folderPath ||
              folder.relativePath.startsWith('$folderPath/'),
        )
        .toList();
    final now = _clock.now().toUtc();
    final trashId = TrashId(_ids.generate());
    final measuredValue = measured.valueOrNull!;
    final unindexedFileCount =
        measuredValue.documentCount +
        measuredValue.otherFileCount -
        affected.length;
    final entry = TrashEntry(
      id: trashId,
      kind: TrashEntryKind.folderTree,
      displayName: path.last,
      originalRelativePath: path.join('/'),
      deletedAt: now,
      expiresAt: TrashEntry.expiryFor(now),
      inventory: TrashInventory(
        documentCount: affected.length,
        otherFileCount: unindexedFileCount < 0 ? 0 : unindexedFileCount,
        folderCount: measuredValue.folderCount,
        sizeInBytes: measuredValue.sizeInBytes,
      ),
      documentIds: affected.map((document) => document.id).toList(),
      folderIds: affectedFolders.map((folder) => folder.id).toList(),
    );

    final moved = await _store.moveFolderToTrash(trashId.value, path);
    if (moved case Failed(:final failure)) {
      return Result<TrashEntry>.failure(failure);
    }
    final marked = <Document>[];
    for (final document in affected) {
      final saved = await _documents.save(
        document.copyWith(trashId: trashId, trashedAt: now),
      );
      if (saved case Failed(:final failure)) {
        for (final original in marked) {
          await _documents.save(original);
        }
        await _store.restoreFolderFromTrash(trashId.value, path.last, path);
        return Result<TrashEntry>.failure(failure);
      }
      marked.add(document);
    }
    final markedFolders = <Folder>[];
    for (final folder in affectedFolders) {
      final saved = await _folders.save(
        folder.copyWith(trashId: trashId, trashedAt: now),
      );
      if (saved case Failed(:final failure)) {
        for (final original in marked) {
          await _documents.save(original);
        }
        for (final original in markedFolders) {
          await _folders.save(original);
        }
        await _store.restoreFolderFromTrash(trashId.value, path.last, path);
        return Result<TrashEntry>.failure(failure);
      }
      markedFolders.add(folder);
    }
    final savedEntry = await _trash.save(entry);
    if (savedEntry case Failed(:final failure)) {
      for (final original in marked) {
        await _documents.save(original);
      }
      for (final original in markedFolders) {
        await _folders.save(original);
      }
      await _store.restoreFolderFromTrash(trashId.value, path.last, path);
      return Result<TrashEntry>.failure(failure);
    }
    return savedEntry;
  }
}

/// Loads recoverable entries newest first.
class LoadTrash {
  /// Creates the use case.
  const LoadTrash(this._trash);

  final TrashRepository _trash;

  /// Returns all entries.
  Future<Result<List<TrashEntry>>> call() => _trash.all();
}

/// Restores one entry, de-duplicating a conflicting name deterministically.
class RestoreTrashEntry {
  /// Creates the use case.
  const RestoreTrashEntry(
    this._trash,
    this._documents,
    this._folders,
    this._store,
  );

  final TrashRepository _trash;
  final DocumentRepository _documents;
  final FolderRepository _folders;
  final PublicFileStore _store;

  /// Restores [id] and returns the final recovered relative path.
  Future<Result<String>> call(TrashId id) async {
    final found = await _trash.findById(id);
    if (found case Failed(:final failure)) {
      return Result<String>.failure(failure);
    }
    final entry = found.valueOrNull!;
    final segments = entry.originalRelativePath.split('/');
    final parent = segments.sublist(0, segments.length - 1);
    final originalName = segments.last;
    final listed = await _store.list(parent);
    if (listed case Failed(:final failure)) {
      return Result<String>.failure(failure);
    }
    final taken = listed.valueOrNull!
        .map((item) => item.name.toLowerCase())
        .toSet();
    final finalName = recoveredName(
      originalName,
      (candidate) => taken.contains(candidate.toLowerCase()),
    );
    final finalRelative = [...parent, finalName].join('/');

    final restored = switch (entry.kind) {
      TrashEntryKind.document => _store.restoreFileFromTrash(
        id.value,
        originalName,
        LibraryPath.inFolder(parent, finalName),
      ),
      TrashEntryKind.folderTree => _store.restoreFolderFromTrash(
        id.value,
        originalName,
        [...parent, finalName],
      ),
    };
    if (await restored case Failed(:final failure)) {
      return Result<String>.failure(failure);
    }

    for (final documentId in entry.documentIds) {
      final result = await _documents.findById(documentId);
      if (result case Success(:final value)) {
        final newPath = entry.kind == TrashEntryKind.document
            ? LibraryPath.inFolder(parent, finalName)
            : LibraryPath.parse(
                value.relativePath.replaceFirst(
                  entry.originalRelativePath,
                  finalRelative,
                ),
              );
        await _documents.save(
          value.copyWith(libraryPath: newPath, trashId: null, trashedAt: null),
        );
      }
    }
    for (final folderId in entry.folderIds) {
      final result = await _folders.findById(folderId);
      if (result case Success(:final value)) {
        final newPath = value.relativePath.replaceFirst(
          entry.originalRelativePath,
          finalRelative,
        );
        await _folders.save(
          value.copyWith(
            name: value.relativePath == entry.originalRelativePath
                ? finalName
                : value.name,
            relativePath: newPath,
            trashId: null,
            trashedAt: null,
          ),
        );
      }
    }
    final deleted = await _trash.delete(id);
    return deleted.map((_) => finalRelative);
  }
}

/// Permanently removes a Trash entry and every owned document resource.
class PurgeTrashEntry {
  /// Creates the use case.
  const PurgeTrashEntry(
    this._trash,
    this._folders,
    this._store,
    this._purgeDocument,
  );

  final TrashRepository _trash;
  final FolderRepository _folders;
  final PublicFileStore _store;
  final PurgeDocument _purgeDocument;

  /// Permanently removes [id]. This operation is idempotent.
  Future<Result<void>> call(TrashId id) async {
    final found = await _trash.findById(id);
    if (found case Failed(:final failure)) {
      return failure == const Failure.notFound()
          ? const Result<void>.success(null)
          : Result<void>.failure(failure);
    }
    final entry = found.valueOrNull!;
    final payload = await _store.purgeTrashPayload(id.value);
    if (payload case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    for (final documentId in entry.documentIds) {
      final purged = await _purgeDocument(documentId);
      if (purged case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
    }
    for (final folderId in entry.folderIds) {
      final deleted = await _folders.delete(folderId);
      if (deleted case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
    }
    return _trash.delete(id);
  }
}

/// Permanently removes every recoverable entry.
class EmptyTrash {
  /// Creates the use case.
  const EmptyTrash(this._trash, this._purge);

  final TrashRepository _trash;
  final PurgeTrashEntry _purge;

  /// Empties Trash, stopping on the first failure so retry is safe.
  Future<Result<void>> call() async {
    final loaded = await _trash.all();
    if (loaded case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    for (final entry in loaded.valueOrNull!) {
      final result = await _purge(entry.id);
      if (result case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
    }
    return const Result<void>.success(null);
  }
}

/// Permanently removes entries at or beyond the 30-day boundary.
class ExpireTrash {
  /// Creates the use case.
  const ExpireTrash(this._trash, this._purge, this._clock);

  final TrashRepository _trash;
  final PurgeTrashEntry _purge;
  final Clock _clock;

  /// Purges expired entries, leaving failures recoverable for the next run.
  Future<Result<void>> call() async {
    final expired = await _trash.expiredAt(_clock.now().toUtc());
    if (expired case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    Failure? firstFailure;
    for (final entry in expired.valueOrNull!) {
      final result = await _purge(entry.id);
      firstFailure ??= result.failureOrNull;
    }
    return firstFailure == null
        ? const Result<void>.success(null)
        : Result<void>.failure(firstFailure);
  }
}

Future<Result<List<Document>>> _activeAndArchivedDocuments(
  DocumentRepository repository,
) async {
  final active = await repository.query();
  if (active case Failed(:final failure)) {
    return Result<List<Document>>.failure(failure);
  }
  final archived = await repository.query(filter: DocumentFilter.archived);
  if (archived case Failed(:final failure)) {
    return Result<List<Document>>.failure(failure);
  }
  return Result<List<Document>>.success([
    ...active.valueOrNull!,
    ...archived.valueOrNull!,
  ]);
}
