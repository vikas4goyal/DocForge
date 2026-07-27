/// Widget tests for the search screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';
import 'package:doc_forge/features/document_search/infrastructure/repositories/indexed_search_repository.dart';
import 'package:doc_forge/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:doc_forge/features/document_search/presentation/screens/search_screen.dart';
import 'package:doc_forge/features/document_search/presentation/search_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Document doc(String id, {String title = 'Untitled'}) => Document(
  id: DocumentId(id),
  title: title,
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 2,
  sizeInBytes: 20480,
  filePath: '/documents/$id.pdf',
);

Folder folder(String id, String name) =>
    Folder(id: FolderId(id), name: name, createdAt: DateTime.utc(2026));

void main() {
  late IndexedSearchRepository repository;
  late List<DocumentId> opened;

  setUp(() {
    opened = [];
    final documents = [
      doc('a', title: 'Invoice 2026'),
      doc('b', title: 'Receipt'),
    ];
    repository = IndexedSearchRepository(
      InMemoryTitleIndex(documents: documents),
      InMemoryOcrIndex(
        textByDocumentId: {
          const DocumentId('b'): 'Acme Limited invoice total 240.00',
        },
      ),
      InMemoryDocumentLookup(documents: documents),
    );
  });

  Future<SearchBloc> pump(
    WidgetTester tester, {
    IndexedSearchRepository? source,
    Brightness brightness = Brightness.light,
    Size viewport = const Size(600, 1000),
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bloc = SearchBloc(source ?? repository);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<SearchBloc>.value(
          value: bloc,
          child: SearchScreen(
            onOpenDocument: opened.add,
            folders: [folder('f1', 'Receipts'), folder('f2', 'Invoices')],
          ),
        ),
      ),
    );
    await tester.pump();

    return bloc;
  }

  /// Types [term] and waits for the debounce to elapse.
  Future<void> type(WidgetTester tester, String term) async {
    await tester.enterText(find.byKey(SearchKeys.inputField), term);
    await tester.pump(searchDebounce * 2);
    await tester.pump();
    await tester.pump();
  }

  group('composition', () {
    testWidgets('shows the input, filters and initial state', (tester) async {
      await pump(tester);

      expect(find.byKey(SearchKeys.screen), findsOneWidget);
      expect(find.byKey(SearchKeys.inputField), findsOneWidget);
      expect(find.byKey(SearchKeys.filterFolder), findsOneWidget);
      expect(find.byKey(SearchKeys.filterDate), findsOneWidget);
      expect(find.byKey(SearchKeys.initialState), findsOneWidget);
    });

    testWidgets('offers no clear control before anything is typed', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(SearchKeys.clearButton), findsNothing);
    });
  });

  group('searching', () {
    testWidgets('typing produces results', (tester) async {
      await pump(tester);

      await type(tester, 'invoice');

      expect(find.byKey(SearchKeys.resultsList), findsOneWidget);
      expect(find.byKey(SearchKeys.resultRow('a')), findsOneWidget);
      expect(find.byKey(SearchKeys.resultRow('b')), findsOneWidget);
    });

    testWidgets('a text match shows its snippet', (tester) async {
      // Without one, a document whose title does not contain the term looks
      // like a mistake.
      await pump(tester);

      await type(tester, 'acme');

      expect(find.textContaining('Acme'), findsAtLeastNWidgets(1));
    });

    testWidgets('opening a result reports the document', (tester) async {
      await pump(tester);
      await type(tester, 'invoice');

      await tester.tap(find.byKey(SearchKeys.resultRow('a')));
      await tester.pump();

      expect(opened, [const DocumentId('a')]);
    });

    testWidgets('a term matching nothing shows the empty state', (
      tester,
    ) async {
      await pump(tester);

      await type(tester, 'aardvark');

      expect(find.byKey(SearchKeys.emptyState), findsOneWidget);
      expect(find.textContaining('remove a filter'), findsOneWidget);
    });

    testWidgets('a failure shows an error view with a retry', (tester) async {
      await pump(
        tester,
        source: IndexedSearchRepository(
          InMemoryTitleIndex(failure: const Failure.storage()),
          InMemoryOcrIndex(),
          InMemoryDocumentLookup(),
        ),
      );

      await type(tester, 'invoice');

      expect(find.byKey(SearchKeys.errorView), findsOneWidget);
      expect(find.byKey(SearchKeys.errorRetryButton), findsOneWidget);
    });
  });

  group('clearing', () {
    testWidgets('the control appears once there is something to clear', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, 'invoice');

      expect(find.byKey(SearchKeys.clearButton), findsOneWidget);
    });

    testWidgets('clearing returns to the initial state', (tester) async {
      await pump(tester);
      await type(tester, 'invoice');

      await tester.tap(find.byKey(SearchKeys.clearButton));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(SearchKeys.initialState), findsOneWidget);
      expect(find.byKey(SearchKeys.resultsList), findsNothing);
    });
  });

  group('filters', () {
    testWidgets('the folder filter offers every folder', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(SearchKeys.filterFolder));
      await tester.pumpAndSettle();

      expect(find.text('All folders'), findsOneWidget);
      expect(find.text('Receipts'), findsOneWidget);
      expect(find.text('Invoices'), findsOneWidget);
    });

    testWidgets('choosing a folder narrows the query', (tester) async {
      final bloc = await pump(tester);

      await tester.tap(find.byKey(SearchKeys.filterFolder));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receipts'));
      await tester.pumpAndSettle();

      expect(bloc.state.query.folderId, const FolderId('f1'));
    });

    testWidgets('the date filter toggles', (tester) async {
      final bloc = await pump(tester);

      await tester.tap(find.byKey(SearchKeys.filterDate));
      await tester.pumpAndSettle();

      expect(bloc.state.query.modifiedWithin, isNotNull);

      await tester.tap(find.byKey(SearchKeys.filterDate));
      await tester.pumpAndSettle();

      expect(bloc.state.query.modifiedWithin, isNull);
    });
  });

  group('accessibility', () {
    testWidgets('the result count is announced when results change', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      await type(tester, 'invoice');

      expect(find.bySemanticsLabel('2 results'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a text match announces where it matched', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      await type(tester, 'acme');

      expect(
        find.bySemanticsLabel(RegExp('matched in the document text')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await type(tester, 'invoice');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, brightness: Brightness.dark);
      await type(tester, 'invoice');

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives a tablet viewport at double text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final bloc = SearchBloc(repository);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<SearchBloc>.value(
            value: bloc,
            child: SearchScreen(onOpenDocument: (_) {}, folders: const []),
          ),
        ),
      );
      await type(tester, 'invoice');

      expect(tester.takeException(), isNull);
    });
  });

  group('SearchResultRow', () {
    testWidgets('a title match shows the document subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultRow(
              result: SearchResult(
                document: doc('a', title: 'Invoice 2026'),
                source: MatchSource.title,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Invoice 2026'), findsOneWidget);
      expect(find.textContaining('pages'), findsOneWidget);
    });

    testWidgets('a long snippet is truncated rather than overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultRow(
              result: SearchResult(
                document: doc('a', title: 'A very long document title ' * 4),
                source: MatchSource.recognisedText,
                snippet: '…the quick brown fox jumps over the lazy dog… ' * 6,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
