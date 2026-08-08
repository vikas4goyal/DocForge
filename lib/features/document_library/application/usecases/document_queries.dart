/// Read-side use cases for the document library.
///
/// Kept separate from `document_lifecycle.dart` because these never write: a
/// screen that only lists documents depends on this file alone, and cannot
/// accidentally be handed the ability to delete one.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// One page of documents from the library, plus whether more remain.
class DocumentPageResult {
  /// Creates a page of results.
  const DocumentPageResult({required this.documents, required this.hasMore});

  /// The documents in this page, already ordered.
  final List<Document> documents;

  /// Whether at least one further document exists beyond this page.
  ///
  /// Computed by asking for one more row than requested rather than by counting
  /// the whole library, so paging through several thousand documents never
  /// costs a full-table scan per page.
  final bool hasMore;
}

/// Loads a page of documents matching a filter.
class LoadDocuments {
  /// Creates the use case.
  const LoadDocuments(this._documents);

  final DocumentRepository _documents;

  /// The number of documents fetched per page.
  ///
  /// Large enough to fill a tablet viewport without a visible second load,
  /// small enough that the first page renders promptly on a low-end device.
  static const pageSize = 30;

  /// Returns the documents at [offset] for [filter].
  Future<Result<DocumentPageResult>> call({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int offset = 0,
    int limit = pageSize,
  }) async {
    // One extra row is requested purely to answer "is there more?" — it is
    // discarded before the result is returned.
    final result = await _documents.query(
      filter: filter,
      sort: sort,
      folderId: folderId,
      limit: limit + 1,
      offset: offset,
    );

    return result.map((documents) {
      final hasMore = documents.length > limit;
      return DocumentPageResult(
        documents: hasMore ? documents.sublist(0, limit) : documents,
        hasMore: hasMore,
      );
    });
  }
}

/// Metadata displayed by the document Detail screen.
class DocumentDetail {
  /// Creates a detail record.
  const DocumentDetail({required this.document});

  /// The document's metadata.
  final Document document;
}

/// Loads only the metadata needed by the document Detail screen.
class LoadDocumentDetail {
  /// Creates the use case.
  const LoadDocumentDetail(this._documents);

  final DocumentRepository _documents;

  /// Returns [id] without enumerating, materialising, or caching its pages.
  Future<Result<DocumentDetail>> call(DocumentId id) async {
    final found = await _documents.findById(id);
    return found.map((document) => DocumentDetail(document: document));
  }
}

/// Loads folders with their current document counts.
///
/// Distinct from `LoadFolders` in that it exists for the folder *picker*: it
/// returns the same data, and is named for the read it serves so a future
/// change to picker ordering cannot alter the folder list screen.
class LoadFolderOptions {
  /// Creates the use case.
  const LoadFolderOptions(this._folders);

  final FolderRepository _folders;

  /// Returns every folder, ordered by name.
  Future<Result<List<Folder>>> call() async {
    final result = await _folders.all();

    return result.map(
      (folders) => [...folders]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }
}
