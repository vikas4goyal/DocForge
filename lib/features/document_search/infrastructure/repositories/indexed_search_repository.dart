/// Search over the document-title index.
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_search/domain/repositories/search_repository.dart';
import 'package:doc_scanly/features/document_search/domain/search_query.dart';

/// Depends on [DocumentTitleIndex] rather than on a database.
class IndexedSearchRepository implements SearchRepository {
  /// Creates the repository over its title index.
  const IndexedSearchRepository(this._titles);

  final DocumentTitleIndex _titles;

  @override
  Future<Result<List<SearchResult>>> search(
    SearchQuery query, {
    int limit = SearchRepository.defaultLimit,
  }) async {
    if (query.isEmpty) {
      return const Result<List<SearchResult>>.success([]);
    }

    // Only the first word is sent to the index. Isar's word index answers a
    // prefix query on one term, and narrowing further is what the filters and
    // the merge below are for — issuing a query per word would multiply the
    // round trips for a gain the result limit would discard anyway.
    final word = query.words.isEmpty ? '' : query.words.first;

    final titles = await _titles.documentsMatchingWord(word, limit: limit);
    if (titles case Failed(:final failure)) {
      return Result<List<SearchResult>>.failure(failure);
    }

    final matches = [
      for (final document in titles.valueOrNull ?? const <Document>[])
        if (SearchRules.matchesFilters(document, query))
          SearchResult(document: document, source: MatchSource.title),
    ];
    return Result<List<SearchResult>>.success(
      matches.length > limit ? matches.sublist(0, limit) : matches,
    );
  }
}

/// A title index backed by an in-memory list.
///
/// Ships in `lib/` rather than in `test/` because previews need it too.
class InMemoryTitleIndex implements DocumentTitleIndex {
  /// Creates an index over [documents].
  InMemoryTitleIndex({this.documents = const [], this.failure});

  /// The documents to search.
  final List<Document> documents;

  /// When set, every query fails with this.
  final Failure? failure;

  @override
  Future<Result<List<Document>>> documentsMatchingWord(
    String word, {
    int limit = 50,
  }) async {
    final configured = failure;
    if (configured != null) {
      return Result<List<Document>>.failure(configured);
    }

    final matches = [
      for (final document in documents)
        if (!document.isArchived &&
            (word.isEmpty ||
                document.title
                    .toLowerCase()
                    .split(RegExp('[^a-z0-9]+'))
                    .any((token) => token.startsWith(word))))
          document,
    ];

    return Result<List<Document>>.success(
      matches.length > limit ? matches.sublist(0, limit) : matches,
    );
  }
}

/// A document reader backed by an in-memory list.
///
/// Ships in `lib/` rather than in `test/` because previews need it too.
class InMemoryDocumentLookup implements DocumentReader {
  /// Creates a reader over [documents].
  InMemoryDocumentLookup({this.documents = const []});

  /// The documents it can find.
  final List<Document> documents;

  @override
  Future<Result<Document>> findById(DocumentId id) async {
    for (final document in documents) {
      if (document.id == id) return Result<Document>.success(document);
    }
    return const Result<Document>.failure(Failure.notFound());
  }

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => Result<List<Document>>.success(documents);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);
}
