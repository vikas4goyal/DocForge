/// Golden tests for the search screen.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_search/domain/search_query.dart';
import 'package:doc_scanly/features/document_search/infrastructure/repositories/indexed_search_repository.dart';
import 'package:doc_scanly/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:doc_scanly/features/document_search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

Document _document(String id, String title) => Document(
  id: DocumentId(id),
  title: title,
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 4,
  sizeInBytes: 184_320,
  libraryPath: LibraryPath.parse('$id.pdf'),
);

List<SearchResult> _results(int count) => [
  for (var index = 0; index < count; index++)
    SearchResult(
      document: _document('golden-$index', 'Invoice $index'),
      source: index.isOdd ? MatchSource.recognisedText : MatchSource.title,
      snippet: index.isOdd
          ? '…Acme Limited issued this invoice on the fourteenth of March…'
          : '',
    ),
];

/// A Bloc frozen at a chosen state.
class _SeededBloc extends SearchBloc {
  _SeededBloc(this._seeded)
    : super(
        IndexedSearchRepository(
          InMemoryTitleIndex(),
          InMemoryOcrIndex(),
          InMemoryDocumentLookup(),
        ),
      );

  final SearchState _seeded;

  @override
  SearchState get state => _seeded;
}

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    SearchState state, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bloc = _SeededBloc(state);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<SearchBloc>.value(
          value: bloc,
          child: SearchScreen(
            onOpenDocument: (_) {},
            folders: [
              Folder(
                id: const FolderId('f1'),
                name: 'Receipts',
                createdAt: DateTime.utc(2026),
              ),
            ],
          ),
        ),
      ),
    );

    // Bounded rather than `pumpAndSettle`: the searching state shows an
    // indefinite progress indicator, which never settles.
    await tester.pump();
    await tester.pump();
  }

  final results = const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice'),
    results: _results(6),
  );

  group('search goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, _phone, results);

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, _phone, results, brightness: Brightness.dark);

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, _tablet, results);

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, _tablet, results, brightness: Brightness.dark);

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_tablet_dark.png'),
      );
    });

    testWidgets('initial, light', (tester) async {
      await pumpAt(tester, _phone, const SearchState.initial());

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_initial_light.png'),
      );
    });

    testWidgets('empty, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        const SearchState.initial().copyWith(
          status: SearchStatus.empty,
          query: const SearchQuery(term: 'aardvark'),
        ),
      );

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_empty_light.png'),
      );
    });

    testWidgets('error, dark', (tester) async {
      await pumpAt(
        tester,
        _phone,
        const SearchState.initial().copyWith(
          status: SearchStatus.failure,
          query: const SearchQuery(term: 'invoice'),
          failure: const Failure.storage(),
        ),
        brightness: Brightness.dark,
      );

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_error_dark.png'),
      );
    });
  });
}
