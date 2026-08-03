/// Persistence contracts for documents, folders and pages.
///
/// Declared in the domain layer and implemented in infrastructure, so use cases
/// depend on the contract rather than on Isar. That is what makes a change of
/// database engine an infrastructure-only edit, and what lets every use case be
/// tested against an in-memory fake.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/trash.dart';
import 'package:doc_forge/core/failures/result.dart';

/// Stores and queries documents.
abstract interface class DocumentRepository {
  /// Returns the document identified by [id].
  Future<Result<Document>> findById(DocumentId id);

  /// Returns documents matching [filter], ordered by [sort].
  ///
  /// [limit] and [offset] drive incremental loading so a library of several
  /// thousand documents never loads at once.
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  });

  /// Creates or replaces [document].
  Future<Result<Document>> save(Document document);

  /// Permanently removes the record for [id].
  ///
  /// Deletes the record only. Removing the files on disk is the caller's
  /// responsibility, ordered so a crash leaves an orphaned file rather than a
  /// record pointing at nothing.
  Future<Result<void>> delete(DocumentId id);

  /// Returns the number of documents matching [filter].
  Future<Result<int>> count({
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  });

  /// Returns the total size of every stored document in bytes.
  Future<Result<int>> totalSizeInBytes();
}

/// Stores and queries folders.
abstract interface class FolderRepository {
  /// Returns every folder, each with its current document count.
  Future<Result<List<Folder>>> all();

  /// Returns the folder identified by [id].
  Future<Result<Folder>> findById(FolderId id);

  /// Returns the folder named [name], or null when none exists.
  ///
  /// Used to reject duplicate names before creating a folder.
  Future<Result<Folder?>> findByName(String name);

  /// Returns the folder at [relativePath], or null when none exists.
  ///
  /// Distinct from [findByName]: folders nest, so two called `2026` under
  /// different parents are different folders and only the path tells them
  /// apart.
  Future<Result<Folder?>> findByRelativePath(String relativePath);

  /// Creates or replaces [folder].
  Future<Result<Folder>> save(Folder folder);

  /// Removes the folder identified by [id].
  Future<Result<void>> delete(FolderId id);
}

/// Stores and queries the pages belonging to documents.
abstract interface class PageRepository {
  /// Returns the pages of [documentId], in page order.
  Future<Result<List<DocumentPage>>> forDocument(DocumentId documentId);

  /// Replaces every page of [documentId] with [pages].
  ///
  /// Replacing wholesale rather than diffing keeps ordering unambiguous: page
  /// order is the list order, so a reorder cannot leave two pages claiming the
  /// same position.
  Future<Result<void>> replaceAll(
    DocumentId documentId,
    List<DocumentPage> pages,
  );

  /// Removes every page of [documentId].
  Future<Result<void>> deleteForDocument(DocumentId documentId);
}

/// Stores recoverable Trash entries independently from active folders.
abstract interface class TrashRepository {
  /// Returns [id], or `Failure.notFound` when absent.
  Future<Result<TrashEntry>> findById(TrashId id);

  /// Returns newest-deleted entries first.
  Future<Result<List<TrashEntry>>> all();

  /// Creates or replaces [entry].
  Future<Result<TrashEntry>> save(TrashEntry entry);

  /// Removes only the Trash metadata row.
  Future<Result<void>> delete(TrashId id);

  /// Returns entries whose expiry is at or before [now].
  Future<Result<List<TrashEntry>>> expiredAt(DateTime now);

  /// Number of recoverable entries.
  Future<Result<int>> count();
}
