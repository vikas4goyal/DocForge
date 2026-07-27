/// Search over the title and recognised-text indexes.
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_search/domain/repositories/search_repository.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';

/// Searches by querying two indexes and merging their results.
///
/// Depends on [DocumentTitleIndex] and [OcrSearchIndex] rather than on a
/// database. Both live in `core/contracts/` and are implemented by the features
/// that own the collections behind them — this feature may not read another
/// feature's storage, and going through the seam is what keeps that true
/// (`design.md` §2).
///
/// The two are queried separately and merged by document rather than joined:
/// Isar cannot join, and merging in Dart over two bounded result sets is both
/// simpler and fast enough to run on every pause in typing.
class IndexedSearchRepository implements SearchRepository {
  /// Creates the repository over its two indexes and a document lookup.
  ///
  /// The lookup is needed because a text match is a *document identifier*: the
  /// document whose pages matched very often has a title that does not contain
  /// the term at all — a scan called "Scan 2026-03-14" whose text mentions
  /// Acme — which is precisely the case the searchable-text requirement exists
  /// for. Without it, only documents the title index had already returned could
  /// ever appear.
  const IndexedSearchRepository(this._titles, this._text, this._documents);

  final DocumentTitleIndex _titles;
  final OcrSearchIndex _text;
  final DocumentReader _documents;

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

    final hits = await _text.documentsMatchingWord(word, limit: limit);

    // A failing text index degrades to title-only results rather than failing
    // the search: finding fewer documents is recoverable, finding none is not.
    final textHits = hits.valueOrNull ?? const <OcrIndexHit>[];

    final titleMatches = [
      for (final document in titles.valueOrNull ?? const <Document>[])
        if (SearchRules.matchesFilters(document, query))
          SearchResult(document: document, source: MatchSource.title),
    ];

    final byId = {
      for (final document in titles.valueOrNull ?? const <Document>[])
        document.id: document,
    };

    final textMatches = <SearchResult>[];

    for (final hit in textHits) {
      // Already loaded by the title query in the common case; fetched only for
      // the documents the title index did not return, which is what keeps a
      // text-only match findable without a lookup per result.
      final document =
          byId[hit.documentId] ??
          (await _documents.findById(hit.documentId)).valueOrNull;

      if (document == null) continue;
      // An archived document is excluded here as well as in the title index:
      // the OCR index has no archive flag to filter on, so the rule has to be
      // applied where the document is known.
      if (document.isArchived) continue;
      if (!SearchRules.matchesFilters(document, query)) continue;

      textMatches.add(
        SearchResult(
          document: document,
          source: MatchSource.recognisedText,
          snippet: SearchRules.snippet(hit.text, query.normalisedTerm),
        ),
      );
    }

    final merged = SearchRules.merge(titleMatches, textMatches);

    return Result<List<SearchResult>>.success(
      merged.length > limit ? merged.sublist(0, limit) : merged,
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

/// An OCR index backed by an in-memory map.
class InMemoryOcrIndex implements OcrSearchIndex {
  /// Creates an index over [textByDocumentId].
  InMemoryOcrIndex({this.textByDocumentId = const {}, this.failure});

  /// Each document's recognised text.
  final Map<DocumentId, String> textByDocumentId;

  /// When set, every query fails with this.
  final Failure? failure;

  @override
  Future<Result<List<OcrIndexHit>>> documentsMatchingWord(
    String word, {
    int limit = 50,
  }) async {
    final configured = failure;
    if (configured != null) {
      return Result<List<OcrIndexHit>>.failure(configured);
    }

    if (word.isEmpty) return const Result<List<OcrIndexHit>>.success([]);

    final hits = [
      for (final entry in textByDocumentId.entries)
        if (entry.value
            .toLowerCase()
            .split(RegExp('[^a-z0-9]+'))
            .any((token) => token.startsWith(word)))
          OcrIndexHit(documentId: entry.key, text: entry.value),
    ];

    return Result<List<OcrIndexHit>>.success(
      hits.length > limit ? hits.sublist(0, limit) : hits,
    );
  }
}
