/// Tests the search rules, repository and Bloc.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_search/domain/repositories/search_repository.dart';
import 'package:doc_scanly/features/document_search/domain/search_query.dart';
import 'package:doc_scanly/features/document_search/infrastructure/repositories/indexed_search_repository.dart';
import 'package:doc_scanly/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Document doc(
  String id, {
  String title = 'Untitled',
  FolderId? folderId,
  bool archived = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => Document(
  id: DocumentId(id),
  title: title,
  createdAt: createdAt ?? DateTime.utc(2026, 3, 14),
  updatedAt: updatedAt ?? DateTime.utc(2026, 3, 14),
  pageCount: 2,
  sizeInBytes: 20480,
  libraryPath: LibraryPath.parse('$id.pdf'),
  folderId: folderId,
  isArchived: archived,
);

void main() {
  group('SearchQuery', () {
    test('a blank term with no filters is not a search', () {
      // Running it would return the whole library with a spinner in front.
      expect(const SearchQuery().isEmpty, isTrue);
      expect(const SearchQuery(term: '   ').isEmpty, isTrue);
    });

    test('a term makes it a search', () {
      expect(const SearchQuery(term: 'invoice').isEmpty, isFalse);
    });

    test('a filter alone makes it a search', () {
      // "Everything in this folder" is a legitimate thing to ask for.
      expect(const SearchQuery(folderId: FolderId('f1')).isEmpty, isFalse);
    });

    test('an unbounded date range is not a filter', () {
      expect(const SearchQuery(createdWithin: DateRange()).hasFilters, isFalse);
    });

    test('normalises the term for matching', () {
      expect(const SearchQuery(term: '  INVOICE ').normalisedTerm, 'invoice');
    });

    test('tokenises the same way the indexes do', () {
      // A term that indexes one way must not fail to match itself.
      expect(const SearchQuery(term: 'Invoice — Acme Ltd.').words, [
        'invoice',
        'acme',
        'ltd',
      ]);
    });

    test('changing the term leaves the filters in place', () {
      const query = SearchQuery(term: 'a', folderId: FolderId('f1'));

      expect(query.copyWith(term: 'b').folderId, const FolderId('f1'));
    });

    test('a filter is cleared explicitly, not by passing null', () {
      const query = SearchQuery(term: 'a', folderId: FolderId('f1'));

      expect(query.copyWith(clearFolder: true).folderId, isNull);
    });
  });

  group('DateRange', () {
    test('an unbounded range contains everything', () {
      expect(const DateRange().contains(DateTime.utc(1999)), isTrue);
      expect(const DateRange().isUnbounded, isTrue);
    });

    test('a lower bound excludes what came before it', () {
      final range = DateRange(from: DateTime.utc(2026, 3));

      expect(range.contains(DateTime.utc(2026, 2, 28)), isFalse);
      expect(range.contains(DateTime.utc(2026, 3)), isTrue);
      expect(range.contains(DateTime.utc(2026, 4)), isTrue);
    });

    test('an upper bound excludes what came after it', () {
      final range = DateRange(to: DateTime.utc(2026, 3, 31));

      expect(range.contains(DateTime.utc(2026, 4)), isFalse);
      expect(range.contains(DateTime.utc(2026, 3, 31)), isTrue);
    });

    test('both bounds are inclusive', () {
      final range = DateRange(
        from: DateTime.utc(2026, 3),
        to: DateTime.utc(2026, 3, 31),
      );

      expect(range.contains(DateTime.utc(2026, 3)), isTrue);
      expect(range.contains(DateTime.utc(2026, 3, 31)), isTrue);
    });

    test('compares in UTC, so a local bound does not shift the boundary', () {
      final range = DateRange(from: DateTime.utc(2026, 3));

      expect(range.contains(DateTime.utc(2026, 3).toLocal()), isTrue);
    });
  });

  group('snippets', () {
    const text =
        'Acme Limited issued this invoice on the fourteenth of March for '
        'consulting services rendered during the previous quarter.';

    test('shows the term in context', () {
      final snippet = SearchRules.snippet(text, 'invoice');

      expect(snippet, contains('invoice'));
      expect(snippet.length, lessThan(text.length));
    });

    test('marks where it was cut', () {
      // So a user can tell a fragment from a whole line.
      expect(SearchRules.snippet(text, 'consulting'), startsWith('…'));
    });

    test('does not mark a cut that did not happen', () {
      expect(
        SearchRules.snippet('Short invoice', 'invoice'),
        isNot(startsWith('…')),
      );
    });

    test('collapses line breaks so a row stays scannable', () {
      final snippet = SearchRules.snippet('one\ntwo\nthree', 'two');

      expect(snippet, isNot(contains('\n')));
    });

    test('is empty when the term does not appear', () {
      expect(SearchRules.snippet(text, 'aardvark'), isEmpty);
    });

    test('is empty for an empty term or text', () {
      expect(SearchRules.snippet(text, ''), isEmpty);
      expect(SearchRules.snippet('', 'invoice'), isEmpty);
    });

    test('is case-insensitive', () {
      expect(SearchRules.snippet(text, 'INVOICE'), isNotEmpty);
    });
  });

  group('filters', () {
    test('a folder filter excludes documents elsewhere', () {
      expect(
        SearchRules.matchesFilters(
          doc('a', folderId: const FolderId('f1')),
          const SearchQuery(folderId: FolderId('f2')),
        ),
        isFalse,
      );
    });

    test('a folder filter excludes unfiled documents', () {
      expect(
        SearchRules.matchesFilters(
          doc('a'),
          const SearchQuery(folderId: FolderId('f1')),
        ),
        isFalse,
      );
    });

    test('a creation-date filter uses the creation date', () {
      final document = doc(
        'a',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 6),
      );

      expect(
        SearchRules.matchesFilters(
          document,
          SearchQuery(createdWithin: DateRange(from: DateTime.utc(2026, 5))),
        ),
        isFalse,
      );
    });

    test('a modification-date filter uses the modification date', () {
      final document = doc(
        'a',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 6),
      );

      expect(
        SearchRules.matchesFilters(
          document,
          SearchQuery(modifiedWithin: DateRange(from: DateTime.utc(2026, 5))),
        ),
        isTrue,
      );
    });

    test('filters combine', () {
      final document = doc(
        'a',
        folderId: const FolderId('f1'),
        updatedAt: DateTime.utc(2026, 6),
      );

      expect(
        SearchRules.matchesFilters(
          document,
          SearchQuery(
            folderId: const FolderId('f1'),
            modifiedWithin: DateRange(from: DateTime.utc(2026, 5)),
          ),
        ),
        isTrue,
      );
      expect(
        SearchRules.matchesFilters(
          document,
          SearchQuery(
            folderId: const FolderId('f2'),
            modifiedWithin: DateRange(from: DateTime.utc(2026, 5)),
          ),
        ),
        isFalse,
      );
    });
  });

  group('merging matches', () {
    test('a document matching both ways appears once', () {
      final document = doc('a', title: 'Invoice');

      final merged = SearchRules.merge(
        [SearchResult(document: document, source: MatchSource.title)],
        [
          SearchResult(
            document: document,
            source: MatchSource.recognisedText,
            snippet: '…invoice…',
          ),
        ],
      );

      expect(merged, hasLength(1));
    });

    test('and is attributed to its title', () {
      // The title is what the row shows; claiming the match came from the text
      // would send the user looking for something already in front of them.
      final document = doc('a', title: 'Invoice');

      final merged = SearchRules.merge(
        [SearchResult(document: document, source: MatchSource.title)],
        [
          SearchResult(
            document: document,
            source: MatchSource.recognisedText,
            snippet: '…invoice…',
          ),
        ],
      );

      expect(merged.single.source, MatchSource.title);
    });

    test('title matches come before text matches', () {
      final merged = SearchRules.merge(
        [SearchResult(document: doc('a'), source: MatchSource.title)],
        [SearchResult(document: doc('b'), source: MatchSource.recognisedText)],
      );

      expect(merged.map((r) => r.document.id.value), ['a', 'b']);
    });

    test('an empty merge is empty', () {
      expect(SearchRules.merge(const [], const []), isEmpty);
    });
  });

  group('result count announcement', () {
    test('names the count in words a listener can act on', () {
      expect(SearchRules.resultCountLabel(0), 'No results');
      expect(SearchRules.resultCountLabel(1), '1 result');
      expect(SearchRules.resultCountLabel(7), '7 results');
    });
  });

  group('IndexedSearchRepository', () {
    final documents = [
      doc('a', title: 'Invoice 2026', folderId: const FolderId('f1')),
      doc('b', title: 'Receipt'),
      doc('c', title: 'Old invoice', archived: true),
    ];

    final repository = IndexedSearchRepository(
      InMemoryTitleIndex(documents: documents),
      InMemoryOcrIndex(
        textByDocumentId: {
          const DocumentId('b'): 'Acme Limited invoice total 240.00',
          // A document whose *title* does not contain the term: the case the
          // searchable-text requirement exists for.
          const DocumentId('c'): 'Archived acme paperwork',
        },
      ),
      InMemoryDocumentLookup(documents: documents),
    );

    Future<List<SearchResult>> search(SearchQuery query) async =>
        (await repository.search(query) as Success<List<SearchResult>>).value;

    test('matches a title', () async {
      final results = await search(const SearchQuery(term: 'invoice'));

      expect(results.map((r) => r.document.id.value), containsAll(['a', 'b']));
    });

    test('matches recognised text and carries a snippet', () async {
      final results = await search(const SearchQuery(term: 'acme'));

      expect(results.single.document.id.value, 'b');
      expect(results.single.source, MatchSource.recognisedText);
      expect(results.single.hasSnippet, isTrue);
    });

    test('is case-insensitive', () async {
      expect(await search(const SearchQuery(term: 'INVOICE')), isNotEmpty);
    });

    test('excludes archived documents, by title or by text', () async {
      // The archive is where a user puts things they have finished with. The
      // OCR index has no archive flag to filter on, so the rule has to hold on
      // the text path too — document 'c' is archived and its text says "acme".
      expect(
        (await search(
          const SearchQuery(term: 'invoice'),
        )).map((r) => r.document.id.value),
        isNot(contains('c')),
      );
      expect(
        (await search(
          const SearchQuery(term: 'acme'),
        )).map((r) => r.document.id.value),
        isNot(contains('c')),
      );
    });

    test('a folder filter narrows the results', () async {
      final results = await search(
        const SearchQuery(term: 'invoice', folderId: FolderId('f1')),
      );

      expect(results.map((r) => r.document.id.value), ['a']);
    });

    test('an empty query returns nothing', () async {
      expect(await search(const SearchQuery()), isEmpty);
    });

    test('a term matching nothing returns nothing', () async {
      expect(await search(const SearchQuery(term: 'aardvark')), isEmpty);
    });

    test('respects the result limit', () async {
      final many = IndexedSearchRepository(
        InMemoryTitleIndex(
          documents: [
            for (var index = 0; index < 100; index++)
              doc('doc-$index', title: 'Invoice $index'),
          ],
        ),
        InMemoryOcrIndex(),
        InMemoryDocumentLookup(),
      );

      final result = await many.search(
        const SearchQuery(term: 'invoice'),
        limit: 10,
      );

      expect((result as Success<List<SearchResult>>).value, hasLength(10));
    });

    test('reports a failure rather than throwing', () async {
      final broken = IndexedSearchRepository(
        InMemoryTitleIndex(failure: const Failure.storage()),
        InMemoryOcrIndex(),
        InMemoryDocumentLookup(),
      );

      expect(
        await broken.search(const SearchQuery(term: 'x')),
        isA<Failed<List<SearchResult>>>(),
      );
    });
  });

  group('SearchBloc', () {
    late IndexedSearchRepository repository;
    late RecordingTitleIndex titles;

    setUp(() {
      titles = RecordingTitleIndex(
        documents: [
          doc('a', title: 'Invoice 2026'),
          doc('b', title: 'Receipt'),
        ],
      );
      final documents = [
        doc('a', title: 'Invoice 2026'),
        doc('b', title: 'Receipt'),
      ];
      repository = IndexedSearchRepository(
        titles,
        InMemoryOcrIndex(
          textByDocumentId: {const DocumentId('b'): 'Acme Limited invoice'},
        ),
        InMemoryDocumentLookup(documents: documents),
      );
    });

    blocTest<SearchBloc, SearchState>(
      'starts with nothing searched for',
      build: () => SearchBloc(repository),
      verify: (bloc) => expect(bloc.state.status, SearchStatus.initial),
    );

    blocTest<SearchBloc, SearchState>(
      'a term produces results',
      build: () => SearchBloc(repository),
      act: (bloc) => bloc.add(const SearchTermChanged('invoice')),
      wait: searchDebounce * 2,
      verify: (bloc) {
        expect(bloc.state.status, SearchStatus.results);
        expect(bloc.state.results, hasLength(2));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'debouncing collapses rapid typing into one query',
      build: () => SearchBloc(repository),
      act: (bloc) {
        // Five keystrokes for one word: without debouncing this is five
        // database queries per word typed.
        for (final term in ['i', 'in', 'inv', 'invo', 'invoice']) {
          bloc.add(SearchTermChanged(term));
        }
      },
      wait: searchDebounce * 2,
      verify: (_) => expect(titles.queries, hasLength(1)),
    );

    blocTest<SearchBloc, SearchState>(
      'and the query that runs is the last one typed',
      build: () => SearchBloc(repository),
      act: (bloc) {
        bloc.add(const SearchTermChanged('receipt'));
        bloc.add(const SearchTermChanged('invoice'));
      },
      wait: searchDebounce * 2,
      // The index is asked about the first word of the term, so the assertion
      // is on the tokenised word rather than on the raw string.
      verify: (_) => expect(titles.queries.single, 'invoice'),
    );

    blocTest<SearchBloc, SearchState>(
      'a term matching nothing shows the empty state',
      build: () => SearchBloc(repository),
      act: (bloc) => bloc.add(const SearchTermChanged('aardvark')),
      wait: searchDebounce * 2,
      verify: (bloc) => expect(bloc.state.status, SearchStatus.empty),
    );

    blocTest<SearchBloc, SearchState>(
      'clearing the term returns to the initial state',
      build: () => SearchBloc(repository),
      act: (bloc) async {
        bloc.add(const SearchTermChanged('invoice'));
        await Future<void>.delayed(searchDebounce * 2);
        bloc.add(const SearchTermChanged(''));
      },
      wait: searchDebounce * 2,
      verify: (bloc) {
        expect(bloc.state.status, SearchStatus.initial);
        expect(bloc.state.results, isEmpty);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'the clear control resets everything',
      build: () => SearchBloc(repository),
      act: (bloc) async {
        bloc.add(const SearchTermChanged('invoice'));
        await Future<void>.delayed(searchDebounce * 2);
        bloc.add(const SearchCleared());
      },
      verify: (bloc) {
        expect(bloc.state.status, SearchStatus.initial);
        expect(bloc.state.query.isEmpty, isTrue);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'a failure surfaces with a message and can be retried',
      build: () => SearchBloc(
        IndexedSearchRepository(
          InMemoryTitleIndex(failure: const Failure.storage()),
          InMemoryOcrIndex(),
          InMemoryDocumentLookup(),
        ),
      ),
      act: (bloc) => bloc.add(const SearchTermChanged('invoice')),
      wait: searchDebounce * 2,
      verify: (bloc) {
        expect(bloc.state.status, SearchStatus.failure);
        expect(bloc.state.message, isNotNull);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'a folder filter runs immediately, without debouncing',
      build: () => SearchBloc(repository),
      act: (bloc) => bloc.add(const SearchFolderFilterChanged(FolderId('f1'))),
      verify: (_) {
        // A filter change is one deliberate action, not a stream of them.
        expect(titles.queries, hasLength(1));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'clearing the folder filter searches everywhere again',
      build: () => SearchBloc(repository),
      act: (bloc) async {
        bloc.add(const SearchFolderFilterChanged(FolderId('f1')));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchFolderFilterChanged(null));
      },
      verify: (bloc) => expect(bloc.state.query.folderId, isNull),
    );

    blocTest<SearchBloc, SearchState>(
      'a date filter narrows the query',
      build: () => SearchBloc(repository),
      act: (bloc) => bloc.add(
        SearchDateFilterChanged(modified: DateRange(from: DateTime.utc(2026))),
      ),
      verify: (bloc) => expect(bloc.state.query.modifiedWithin, isNotNull),
    );

    blocTest<SearchBloc, SearchState>(
      'an unbounded date filter clears it',
      build: () => SearchBloc(repository),
      act: (bloc) async {
        bloc.add(
          SearchDateFilterChanged(
            modified: DateRange(from: DateTime.utc(2026)),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchDateFilterChanged(modified: DateRange()));
      },
      verify: (bloc) => expect(bloc.state.query.modifiedWithin, isNull),
    );

    blocTest<SearchBloc, SearchState>(
      'the clear control is offered only once there is something to clear',
      build: () => SearchBloc(repository),
      act: (bloc) async {
        expect(bloc.state.canClear, isFalse);
        bloc.add(const SearchTermChanged('invoice'));
        await Future<void>.delayed(searchDebounce * 2);
      },
      verify: (bloc) => expect(bloc.state.canClear, isTrue),
    );

    blocTest<SearchBloc, SearchState>(
      'announces the result count',
      build: () => SearchBloc(repository),
      act: (bloc) => bloc.add(const SearchTermChanged('invoice')),
      wait: searchDebounce * 2,
      verify: (bloc) => expect(bloc.state.resultCountLabel, '2 results'),
    );
  });

  group('performance', () {
    test('a large library searches within a frame budget', () async {
      // Not a benchmark — a guard. Search runs on every pause in typing, and a
      // linear scan that took hundreds of milliseconds would be felt.
      final repository = IndexedSearchRepository(
        InMemoryTitleIndex(
          documents: [
            for (var index = 0; index < 5000; index++)
              doc('doc-$index', title: 'Document $index'),
          ],
        ),
        InMemoryOcrIndex(
          textByDocumentId: {
            for (var index = 0; index < 5000; index++)
              DocumentId('doc-$index'): 'Recognised text for document $index',
          },
        ),
        InMemoryDocumentLookup(),
      );

      final stopwatch = Stopwatch()..start();
      final result = await repository.search(const SearchQuery(term: '4242'));
      stopwatch.stop();

      expect(result, isA<Success<List<SearchResult>>>());
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('the default limit bounds an unfiltered search', () {
      expect(SearchRepository.defaultLimit, lessThanOrEqualTo(100));
    });
  });
}

/// A title index that records the words it was queried with.
///
/// The debounce and restart behaviour is about *how many* queries reach
/// storage, so the assertion needs a collaborator that counts them.
class RecordingTitleIndex extends InMemoryTitleIndex {
  /// Creates a recording index over [documents].
  RecordingTitleIndex({super.documents});

  /// Every word this index was asked about, in order.
  final queries = <String>[];

  @override
  Future<Result<List<Document>>> documentsMatchingWord(
    String word, {
    int limit = 50,
  }) {
    queries.add(word);
    return super.documentsMatchingWord(word, limit: limit);
  }
}
