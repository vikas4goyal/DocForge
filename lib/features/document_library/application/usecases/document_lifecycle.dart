/// Use cases for the document lifecycle.
///
/// Every rule the library enforces lives here or in `domain/library_rules.dart`
/// — never in a Cubit. A Cubit calls one of these and emits the result.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/domain/document_duplicate.dart';
import 'package:doc_scanly/features/document_library/domain/library_rules.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/document_file_store.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// Renames a document.
class RenameDocument {
  /// Creates the use case.
  const RenameDocument(this._documents, this._clock, this._store);

  final DocumentRepository _documents;
  final Clock _clock;
  final PublicFileStore _store;

  /// Renames [id] to [title].
  ///
  /// Rejects an empty or whitespace-only name, and one the filesystem would
  /// refuse: the title is also the file's name in a folder the user can reach
  /// from their file browser, so "not empty" is no longer enough.
  ///
  /// The file is renamed as well as the record. Renaming only the record would
  /// leave the two disagreeing, and the folder is the truth.
  Future<Result<Document>> call(DocumentId id, String title) async {
    final normalised = NameRules.normalise(title);
    if (normalised == null) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }
    if (!LibraryPath.isValidName(LibraryPath.pdfFileName(normalised))) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.illegalName),
      );
    }

    final found = await _documents.findById(id);

    return found.flatMapAsync((document) async {
      final destination = document.libraryPath.withFileName(
        LibraryPath.pdfFileName(normalised),
      );

      // A name already taken in the same folder is refused rather than
      // silently suffixed: the user asked for that name, and quietly giving
      // them a different one is worse than saying no.
      if (destination != document.libraryPath) {
        final taken = await _store.exists(destination);
        if (taken.valueOrNull ?? false) {
          return const Result<Document>.failure(
            Failure.validation(issue: ValidationIssue.duplicateDocumentName),
          );
        }

        final renamed = await _store.rename(document.libraryPath, destination);
        if (renamed case Failed(:final failure)) {
          return Result<Document>.failure(failure);
        }
      }

      // The record second: a record renamed before the file would describe a
      // document at a path that does not hold one.
      return _documents.save(
        document.copyWith(
          title: normalised,
          libraryPath: destination,
          updatedAt: _clock.now(),
        ),
      );
    });
  }
}

/// Moves a document into a folder, or out of one.
class MoveDocument {
  /// Creates the use case.
  const MoveDocument(
    this._documents,
    this._clock, [
    this._store,
    this._folders,
  ]);

  final DocumentRepository _documents;
  final Clock _clock;
  final PublicFileStore? _store;
  final FolderRepository? _folders;

  /// Moves [id] into [folderId], or unfiles it when [folderId] is null.
  Future<Result<Document>> call(DocumentId id, FolderId? folderId) async {
    final found = await _documents.findById(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;
    var destinationPath = document.libraryPath;
    final store = _store;
    final folderRepository = _folders;
    if (store != null && folderRepository != null) {
      var destinationFolders = const <String>[];
      if (folderId != null) {
        final folder = await folderRepository.findById(folderId);
        if (folder case Failed(:final failure)) {
          return Result<Document>.failure(failure);
        }
        final relative = folder.valueOrNull!.relativePath.trim();
        destinationFolders = relative.isEmpty ? const [] : relative.split('/');
      }
      destinationPath = LibraryPath.inFolder(
        destinationFolders,
        document.fileName,
      );
      if (destinationPath != document.libraryPath) {
        final occupied = await store.exists(destinationPath);
        if (occupied case Failed(:final failure)) {
          return Result<Document>.failure(failure);
        }
        if (occupied.valueOrNull ?? false) {
          return const Result<Document>.failure(
            Failure.validation(issue: ValidationIssue.duplicateDocumentName),
          );
        }
        final moved = await store.rename(document.libraryPath, destinationPath);
        if (moved case Failed(:final failure)) {
          return Result<Document>.failure(failure);
        }
      }
    }

    // Rebuild to allow a null folder assignment when moving to Root.
    final saved = await _documents.save(
      Document(
        id: document.id,
        title: document.title,
        createdAt: document.createdAt,
        updatedAt: _clock.now(),
        pageCount: document.pageCount,
        sizeInBytes: document.sizeInBytes,
        libraryPath: destinationPath,
        folderId: folderId,
        isFavourite: document.isFavourite,
        isArchived: document.isArchived,
        isProtected: document.isProtected,
        hasRecognisedText: document.hasRecognisedText,
        cloudResourceIdentifier: document.cloudResourceIdentifier,
        cloudRelativePath: document.cloudRelativePath,
        contentAvailability: document.contentAvailability,
        trashId: document.trashId,
        trashedAt: document.trashedAt,
      ),
    );
    if (saved.isFailure &&
        store != null &&
        destinationPath != document.libraryPath) {
      await store.rename(destinationPath, document.libraryPath);
    }
    return saved;
  }
}

/// Toggles a document's favourite status.
class ToggleFavourite {
  /// Creates the use case.
  const ToggleFavourite(this._documents, this._clock);

  final DocumentRepository _documents;
  final Clock _clock;

  /// Toggles whether [id] is a favourite.
  Future<Result<Document>> call(DocumentId id) async {
    final found = await _documents.findById(id);

    return found.flatMapAsync(
      (document) => _documents.save(
        document.copyWith(
          isFavourite: !document.isFavourite,
          updatedAt: _clock.now(),
        ),
      ),
    );
  }
}

/// Archives a document, removing it from lists and recents.
class ArchiveDocument {
  /// Creates the use case.
  const ArchiveDocument(this._documents, this._clock);

  final DocumentRepository _documents;
  final Clock _clock;

  /// Archives [id].
  Future<Result<Document>> call(DocumentId id) async {
    final found = await _documents.findById(id);

    return found.flatMapAsync(
      (document) => _documents.save(
        document.copyWith(isArchived: true, updatedAt: _clock.now()),
      ),
    );
  }
}

/// Restores an archived document.
class RestoreDocument {
  /// Creates the use case.
  const RestoreDocument(this._documents, this._clock);

  final DocumentRepository _documents;
  final Clock _clock;

  /// Restores [id] to its previous folder.
  ///
  /// The folder assignment was never cleared by archiving, so restoring simply
  /// clears the flag and the document reappears where it was.
  Future<Result<Document>> call(DocumentId id) async {
    final found = await _documents.findById(id);

    return found.flatMapAsync(
      (document) => _documents.save(
        document.copyWith(isArchived: false, updatedAt: _clock.now()),
      ),
    );
  }
}

/// Creates an independent copy of a document.
class DuplicateDocument {
  /// Creates the use case.
  const DuplicateDocument(
    this._documents,
    this._pages,
    this._store,
    this._clock,
    this._ids,
  );

  final DocumentRepository _documents;
  final PageRepository _pages;
  final PublicFileStore _store;
  final Clock _clock;
  final IdGenerator _ids;

  /// Duplicates [id], returning the new document.
  ///
  /// The copy is fully independent: its own identifier, its own files and its
  /// own page records, so editing or deleting one cannot affect the other.
  Future<Result<Document>> call(DocumentId id) async {
    final proposal = await propose(id);
    if (proposal case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    return execute(proposal.valueOrNull!);
  }

  /// Proposes a collision-safe copy name beside the source document.
  Future<Result<DuplicateDocumentRequest>> propose(
    DocumentId id, {
    Folder? destination,
  }) async {
    final found = await _documents.findById(id);
    if (found case Failed<Document>(:final failure)) {
      return Result<DuplicateDocumentRequest>.failure(failure);
    }

    final original = found.valueOrNull!;
    final folders =
        _folderSegments(destination?.relativePath) ??
        original.libraryPath.folders;
    final proposed = DocumentRules.duplicateTitle(original.title);
    final destinationPath = await _availablePathFor(proposed, folders);
    if (destinationPath case Failed(:final failure)) {
      return Result<DuplicateDocumentRequest>.failure(failure);
    }
    return Result<DuplicateDocumentRequest>.success(
      DuplicateDocumentRequest(
        sourceDocumentId: id,
        title: destinationPath.valueOrNull!.baseName,
        destinationFolders: folders,
        destinationFolderId: destination?.id ?? original.folderId,
      ),
    );
  }

  /// Creates exactly one independent copy from the reviewed [request].
  Future<Result<Document>> execute(DuplicateDocumentRequest request) async {
    final normalised = NameRules.normalise(request.title);
    if (normalised == null) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }
    final fileName = LibraryPath.pdfFileName(normalised);
    if (!LibraryPath.isValidName(fileName)) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.illegalName),
      );
    }
    final found = await _documents.findById(request.sourceDocumentId);
    if (found case Failed<Document>(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final original = found.valueOrNull!;
    final destination = LibraryPath.inFolder(
      request.destinationFolders,
      fileName,
    );
    if (destination == original.libraryPath) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.duplicateDocumentName),
      );
    }
    final exists = await _store.exists(destination);
    if (exists case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    if (exists.valueOrNull ?? false) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.duplicateDocumentName),
      );
    }
    final newId = DocumentId(_ids.generate());

    // A second file beside the first in the user's own folder, under a name
    // de-duplicated the way the file browser would do it — the copy has to be
    // something they can tell apart from the original at a glance.
    final source = await _store.materialise(original.libraryPath);
    if (source case Failed<String>(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final copied = await _store.writeFile(destination, source.valueOrNull!);
    await _store.releaseMaterialised(original.libraryPath);
    if (copied case Failed<String>(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final now = _clock.now();
    final duplicate = original.copyWith(
      id: newId,
      title: normalised,
      createdAt: now,
      updatedAt: now,
      libraryPath: destination,
      folderId: request.destinationFolderId,
    );

    final saved = await _documents.save(duplicate);
    if (saved case Failed<Document>(:final failure)) {
      return Result<Document>.failure(failure);
    }

    // Page records are copied with fresh identifiers so the two documents never
    // share a page row.
    final originalPages = await _pages.forDocument(request.sourceDocumentId);
    if (originalPages case Success(:final value)) {
      final copiedPages = value
          .map(
            (page) =>
                page.copyWith(id: PageId(_ids.generate()), documentId: newId),
          )
          .toList();
      await _pages.replaceAll(newId, copiedPages);
    }

    return Result<Document>.success(duplicate);
  }

  /// A collision-safe library path for [title] inside [folders].
  Future<Result<LibraryPath>> _availablePathFor(
    String title,
    List<String> folders,
  ) async {
    final existing = await _store.list(folders);
    // Propagated, not defaulted to empty: without the listing there is no way
    // to know whether the name is free, and writing anyway would silently
    // overwrite a document the user still has.
    if (existing case Failed(:final failure)) {
      return Result<LibraryPath>.failure(failure);
    }

    final taken = <String>{
      for (final entry in existing.valueOrNull!)
        if (!entry.isFolder) entry.name,
    };

    final desired = LibraryPath.pdfFileName(LibraryPath.sanitiseName(title));

    try {
      return Result<LibraryPath>.success(
        LibraryPath.inFolder(folders, LibraryPath.deduplicate(desired, taken)),
      );
    } on InvalidLibraryPath catch (error) {
      return Result<LibraryPath>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: '$error',
        ),
      );
    }
  }

  static List<String>? _folderSegments(String? relativePath) {
    final value = relativePath?.trim();
    return value == null || value.isEmpty ? null : value.split('/');
  }
}

/// Permanently removes a document and everything belonging to it.
class PurgeDocument {
  /// Creates the use case.
  const PurgeDocument(
    this._documents,
    this._pages,
    this._store,
    this._thumbnails,
    this._secureStorage,
  );

  final DocumentRepository _documents;
  final PageRepository _pages;
  final PublicFileStore _store;
  final DocumentFileStore _thumbnails;
  final SecureStore _secureStorage;

  /// Permanently removes [id].
  ///
  /// Removes the record, the page rows, every file on disk and any stored PDF
  /// password. Ordered record-last on purpose: if a step fails part-way, an
  /// orphaned file is recoverable, whereas a record pointing at deleted files
  /// renders as a broken document the user cannot fix.
  Future<Result<void>> call(DocumentId id) async {
    final passwordRemoved = await _secureStorage.delete(
      SecureStorageKeys.pdfPassword(id.value),
    );
    if (passwordRemoved case Failed<void>(:final failure)) {
      return Result<void>.failure(failure);
    }
    final consentRemoved = await _secureStorage.delete(
      SecureStorageKeys.pdfPasswordRemembered(id.value),
    );
    if (consentRemoved case Failed<void>(:final failure)) {
      return Result<void>.failure(failure);
    }

    final found = await _documents.findById(id);
    if (found case Success<Document>(:final value)) {
      final fileRemoved = await _store.delete(value.libraryPath);
      if (fileRemoved case Failed<void>(:final failure)) {
        return Result<void>.failure(failure);
      }
    }

    // Cached thumbnails are derived from the file that has just gone, so they
    // go with it rather than being left to be re-rendered from nothing.
    final thumbnailsRemoved = await _thumbnails.deleteDocument(id);
    if (thumbnailsRemoved case Failed<void>(:final failure)) {
      return Result<void>.failure(failure);
    }

    final pagesRemoved = await _pages.deleteForDocument(id);
    if (pagesRemoved case Failed<void>(:final failure)) {
      return Result<void>.failure(failure);
    }

    return _documents.delete(id);
  }
}

/// Computes how much storage the library consumes.
class ComputeStorageSummary {
  /// Creates the use case.
  const ComputeStorageSummary(this._documents, this._store);

  final DocumentRepository _documents;
  final PublicFileStore _store;

  /// Returns the current storage summary.
  ///
  /// Bytes come from the library folder rather than the sum of recorded
  /// document sizes: a file changed outside the application would make the two
  /// disagree, and the folder is the truth about what is occupying space.
  Future<Result<StorageSummary>> call() async {
    final bytes = await _store.totalBytes();
    if (bytes case Failed<int>(:final failure)) {
      return Result<StorageSummary>.failure(failure);
    }

    // Archived documents still occupy storage, so the count includes them.
    final visible = await _documents.count();
    final archived = await _documents.count(filter: DocumentFilter.archived);

    return Result<StorageSummary>.success(
      StorageSummary(
        totalBytes: bytes.valueOrNull!,
        documentCount: visible.getOrElse(0) + archived.getOrElse(0),
      ),
    );
  }
}
