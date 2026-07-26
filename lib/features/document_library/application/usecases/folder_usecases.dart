/// Use cases for folder management.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/domain/library_rules.dart';
import 'package:doc_forge/features/document_library/domain/repositories/library_repositories.dart';

/// Creates a folder.
class CreateFolder {
  /// Creates the use case.
  const CreateFolder(this._folders, this._clock, this._ids);

  final FolderRepository _folders;
  final Clock _clock;
  final IdGenerator _ids;

  /// Creates a folder named [name].
  ///
  /// Rejects an empty name and a name that already exists — two folders with
  /// the same name are indistinguishable in every list that shows them.
  Future<Result<Folder>> call(String name) async {
    final normalised = NameRules.normalise(name);
    if (normalised == null) {
      return const Result<Folder>.failure(
        Failure.unexpected(debugDetail: 'empty folder name'),
      );
    }

    final existing = await _folders.findByName(normalised);
    if (existing case Failed<Folder?>(:final failure)) {
      return Result<Folder>.failure(failure);
    }
    if (existing.valueOrNull != null) {
      return const Result<Folder>.failure(
        Failure.unexpected(debugDetail: 'duplicate folder name'),
      );
    }

    return _folders.save(
      Folder(
        id: FolderId(_ids.generate()),
        name: normalised,
        createdAt: _clock.now(),
      ),
    );
  }
}

/// Renames a folder.
class RenameFolder {
  /// Creates the use case.
  const RenameFolder(this._folders);

  final FolderRepository _folders;

  /// Renames [id] to [name].
  ///
  /// Applies the same empty-name and duplicate-name rules as creation. The
  /// documents the folder contains are unaffected.
  Future<Result<Folder>> call(FolderId id, String name) async {
    final normalised = NameRules.normalise(name);
    if (normalised == null) {
      return const Result<Folder>.failure(
        Failure.unexpected(debugDetail: 'empty folder name'),
      );
    }

    final clash = await _folders.findByName(normalised);
    if (clash case Failed<Folder?>(:final failure)) {
      return Result<Folder>.failure(failure);
    }
    // Renaming a folder to its own current name is not a clash.
    final existing = clash.valueOrNull;
    if (existing != null && existing.id != id) {
      return const Result<Folder>.failure(
        Failure.unexpected(debugDetail: 'duplicate folder name'),
      );
    }

    final found = await _folders.findById(id);

    return found.flatMapAsync(
      (folder) => _folders.save(folder.copyWith(name: normalised)),
    );
  }
}

/// Deletes a folder, deciding what happens to its documents.
class DeleteFolder {
  /// Creates the use case.
  const DeleteFolder(this._folders, this._documents, this._move, this._purge);

  final FolderRepository _folders;
  final DocumentRepository _documents;
  final MoveDocument _move;
  final PurgeDocument _purge;

  /// Deletes [id], applying [strategy] to the documents it contains.
  ///
  /// The caller must choose a strategy explicitly — there is no default. A
  /// folder deletion must never silently take documents with it, and it must
  /// never silently leave them either; the user is asked and the answer is
  /// passed here.
  Future<Result<void>> call(
    FolderId id,
    FolderDeletionStrategy strategy,
  ) async {
    final contained = await _documents.query(
      filter: DocumentFilter.folder,
      folderId: id,
    );
    if (contained case Failed<List<Document>>(:final failure)) {
      return Result<void>.failure(failure);
    }

    for (final document in contained.valueOrNull!) {
      final outcome = switch (strategy) {
        // Unfiled rather than deleted: tidying folders must not destroy work.
        FolderDeletionStrategy.moveDocumentsOut => await _move(
          document.id,
          null,
        ),
        FolderDeletionStrategy.deleteDocuments => await _purge(document.id),
      };

      if (outcome case Failed(:final failure)) {
        // Stop rather than continue: a partial delete leaves the user unable to
        // tell which documents survived.
        return Result<void>.failure(failure);
      }
    }

    return _folders.delete(id);
  }
}

/// Lists folders with their current document counts.
class LoadFolders {
  /// Creates the use case.
  const LoadFolders(this._folders);

  final FolderRepository _folders;

  /// Returns every folder.
  Future<Result<List<Folder>>> call() => _folders.all();
}
