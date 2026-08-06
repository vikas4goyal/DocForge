/// Folder operations against the user-visible library folder.
///
/// Folders here are real directories the user can also see in their file
/// browser, so every operation touches the filesystem as well as the index —
/// and the two are kept in step in one place rather than at each call site
/// (`design.md` D1).
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// Creates a folder inside the library.
class CreateLibraryFolder {
  /// Creates the use case.
  const CreateLibraryFolder(this._store, this._folders, this._clock, this._ids);

  final PublicFileStore _store;
  final FolderRepository _folders;
  final Clock _clock;
  final IdGenerator _ids;

  /// Creates [name] inside [parent], relative to the library root.
  ///
  /// Refuses an illegal name and a duplicate. Both are validation rather than
  /// failure: the user is on the screen that fixes them.
  Future<Result<Folder>> call(
    String name, {
    List<String> parent = const [],
  }) async {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return const Result<Folder>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }
    if (!LibraryPath.isValidName(trimmed)) {
      return const Result<Folder>.failure(
        Failure.validation(issue: ValidationIssue.illegalName),
      );
    }

    final existing = await _store.list(parent);
    if (existing case Failed(:final failure)) {
      return Result<Folder>.failure(failure);
    }

    final taken = existing.valueOrNull!
        .where((entry) => entry.isFolder)
        .map((entry) => entry.name.toLowerCase());
    if (taken.contains(trimmed.toLowerCase())) {
      return const Result<Folder>.failure(
        Failure.validation(issue: ValidationIssue.duplicateFolderName),
      );
    }

    final segments = [...parent, trimmed];
    final created = await _store.createFolder(segments);
    if (created case Failed(:final failure)) {
      return Result<Folder>.failure(failure);
    }

    // The directory first, the record second: a record for a directory that
    // was never made would show the user a folder they cannot open.
    return _folders.save(
      Folder(
        id: FolderId(_ids.generate()),
        name: trimmed,
        relativePath: segments.join('/'),
        createdAt: _clock.now().toUtc(),
      ),
    );
  }
}

/// Renames a folder, moving the documents inside it with it.
class RenameLibraryFolder {
  /// Creates the use case.
  const RenameLibraryFolder(this._store, this._folders, this._documents);

  final PublicFileStore _store;
  final FolderRepository _folders;
  final DocumentRepository _documents;

  /// Renames the folder at [path] to [newName].
  Future<Result<void>> call(List<String> path, String newName) async {
    final trimmed = newName.trim();

    if (trimmed.isEmpty) {
      return const Result<void>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }
    if (!LibraryPath.isValidName(trimmed)) {
      return const Result<void>.failure(
        Failure.validation(issue: ValidationIssue.illegalName),
      );
    }

    final renamed = await _store.renameFolder(path, trimmed);
    if (renamed case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    // Every document beneath it now lives somewhere else. Re-pathing them in
    // the same operation is what keeps the index and the folder in step.
    final from = path.join('/');
    final to = [...path.sublist(0, path.length - 1), trimmed].join('/');

    final indexed = await _documents.query();
    for (final document in indexed.valueOrNull ?? const <Document>[]) {
      if (!document.relativePath.startsWith('$from/')) continue;

      await _documents.save(
        document.copyWith(
          libraryPath: LibraryPath.parse(
            document.relativePath.replaceFirst(from, to),
          ),
        ),
      );
    }

    final record = await _folders.findByRelativePath(from);
    if (record case Success(:final value?)) {
      await _folders.save(value.copyWith(name: trimmed, relativePath: to));
    }

    return const Result<void>.success(null);
  }
}

/// Deletes a folder and everything in it.
class DeleteLibraryFolder {
  /// Creates the use case.
  const DeleteLibraryFolder(this._store, this._folders, this._documents);

  final PublicFileStore _store;
  final FolderRepository _folders;
  final DocumentRepository _documents;

  /// Deletes the folder at [path].
  ///
  /// [keepDocuments] moves the documents to the library root instead of
  /// deleting them, which is the answer to "move them out or delete them?" that
  /// the specification requires be asked before anything is lost.
  Future<Result<void>> call(
    List<String> path, {
    bool keepDocuments = false,
  }) async {
    final prefix = '${path.join('/')}/';
    final indexed = await _documents.query();
    final affected = [
      for (final document in indexed.valueOrNull ?? const <Document>[])
        if (document.relativePath.startsWith(prefix)) document,
    ];

    if (keepDocuments) {
      for (final document in affected) {
        final destination = LibraryPath.inFolder(const [], document.fileName);
        final moved = await _store.rename(document.libraryPath, destination);
        if (moved case Failed(:final failure)) {
          // Stops rather than continuing: a partial move would leave the user
          // with documents in two places and no way to tell which are which.
          return Result<void>.failure(failure);
        }
        await _documents.save(document.copyWith(libraryPath: destination));
      }
    } else {
      for (final document in affected) {
        await _documents.delete(document.id);
      }
    }

    final removed = await _store.deleteFolder(path);
    if (removed case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    final record = await _folders.findByRelativePath(path.join('/'));
    if (record case Success(:final value?)) {
      await _folders.delete(value.id);
    }

    return const Result<void>.success(null);
  }
}
