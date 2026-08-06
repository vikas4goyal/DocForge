/// The library's implementations of the cross-capability contracts.
///
/// Six capabilities read documents and two read folders, but none of them may
/// import this feature. Each therefore depends on an interface from
/// `core/contracts/`, and these adapters are what the composition root injects.
///
/// They are deliberately thin: they translate a contract call into a repository
/// call and nothing else. Any rule that appeared here would be a rule the
/// library's own use cases do not apply, which is how two callers of the same
/// data end up disagreeing about it.
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// Read access to stored documents, for capabilities outside the library.
class LibraryDocumentReader implements DocumentReader {
  /// Creates the reader.
  const LibraryDocumentReader(this._documents, this._pages);

  final DocumentRepository _documents;
  final PageRepository _pages;

  @override
  Future<Result<Document>> findById(DocumentId id) => _documents.findById(id);

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) => _documents.query(
    filter: filter,
    sort: sort,
    folderId: folderId,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) =>
      _pages.forDocument(id);
}

/// Write access to stored documents, for the capabilities that create them.
class LibraryDocumentWriter implements DocumentWriter {
  /// Creates the writer.
  const LibraryDocumentWriter(this._documents, this._pages, this._clock);

  final DocumentRepository _documents;
  final PageRepository _pages;
  final Clock _clock;

  /// Persists [document] and replaces its pages with [pages].
  ///
  /// The record is written first: if the page write then fails, the document
  /// exists with a stale page list, which the next save corrects. The reverse
  /// order would leave pages belonging to a document that does not exist, which
  /// nothing would ever clean up.
  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    // The page count comes from the pages actually written rather than from
    // whatever the caller put in the record, so the two cannot disagree —
    // *except* when there are no page rows at all. An imported or edited PDF
    // has its pages inside the file rather than as records, and overriding its
    // count to zero would leave a document the library reports as empty and
    // the viewer renders in full.
    final saved = await _documents.save(
      document.copyWith(
        pageCount: pages.isEmpty ? document.pageCount : pages.length,
        updatedAt: _clock.now(),
      ),
    );

    return saved.flatMapAsync((stored) async {
      final written = await _pages.replaceAll(stored.id, pages);
      return written.map((_) => stored);
    });
  }

  /// Updates [document]'s metadata, refreshing its modified date.
  @override
  Future<Result<Document>> updateMetadata(Document document) =>
      _documents.save(document.copyWith(updatedAt: _clock.now()));
}

/// Read access to folders, for the home shell and search.
class LibraryFolderReader implements FolderReader {
  /// Creates the reader.
  const LibraryFolderReader(this._folders);

  final FolderRepository _folders;

  @override
  Future<Result<List<Folder>>> all() => _folders.all();

  @override
  Future<Result<Folder>> findById(FolderId id) => _folders.findById(id);
}

/// Reports storage consumption, for the home shell and settings.
class LibraryStorageSummaryReader implements StorageSummaryReader {
  /// Creates the reader over the storage-summary use case.
  ///
  /// Delegates to the use case rather than recomputing, so the figure shown on
  /// Home and the figure shown in settings can never be derived differently.
  const LibraryStorageSummaryReader(this._computeSummary);

  final ComputeStorageSummary _computeSummary;

  @override
  Future<Result<StorageSummary>> summary() => _computeSummary();
}
