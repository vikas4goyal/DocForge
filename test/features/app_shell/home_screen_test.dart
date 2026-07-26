import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_cubit.dart';
import 'package:doc_forge/features/app_shell/presentation/home_keys.dart';
import 'package:doc_forge/features/app_shell/presentation/screens/home_screen.dart';
import 'package:doc_forge/features/app_shell/presentation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Records which action was invoked, so a test asserts on behaviour rather
/// than merely on a widget existing.
class _Recorder {
  int scans = 0;
  int searches = 0;
  int allDocuments = 0;
  int favourites = 0;
  int archive = 0;
  int folders = 0;
  DocumentId? openedDocument;
  FolderId? openedFolder;
}

void main() {
  late FakeDocumentReader documents;
  late FakeFolderReader folders;
  late FakeStorageSummaryReader storage;
  late _Recorder recorder;

  setUp(() {
    documents = FakeDocumentReader();
    folders = FakeFolderReader();
    storage = FakeStorageSummaryReader();
    recorder = _Recorder();
  });

  HomeActions actions() => HomeActions(
    onScan: () => recorder.scans++,
    onSearch: () => recorder.searches++,
    onOpenDocument: (id) => recorder.openedDocument = id,
    onOpenFolder: (id) => recorder.openedFolder = id,
    onAllDocuments: () => recorder.allDocuments++,
    onFolders: () => recorder.folders++,
    onFavourites: () => recorder.favourites++,
    onArchive: () => recorder.archive++,
  );

  Widget build({Brightness brightness = Brightness.light}) => MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: BlocProvider(
      create: (_) => HomeCubit(LoadHomeData(documents, folders, storage)),
      child: HomeScreen(actions: actions()),
    ),
  );

  /// Gives the test a viewport tall enough to hold the whole Home screen.
  ///
  /// Home is a lazy scroll view, so a section below the fold is never built and
  /// `find.byKey` cannot see it. Asserting on composition means making the
  /// whole screen visible rather than scrolling to each section in turn.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Seeds a library that produces the populated Home layout.
  void seedPopulatedLibrary() {
    documents.documents.addAll([
      ...sampleDocuments(3),
      favouriteDocument,
      archivedDocument,
    ]);
    folders.folders.addAll(sampleFolders(2));
    storage.value = const StorageSummary(
      totalBytes: 3 * 1024 * 1024,
      documentCount: 5,
    );
  }

  group('Home composition', () {
    testWidgets('displays every section the spec requires', (tester) async {
      useTallViewport(tester);
      seedPopulatedLibrary();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byKey(HomeKeys.screen), findsOneWidget);
      expect(find.byKey(HomeKeys.searchBar), findsOneWidget);
      expect(find.byKey(HomeKeys.scanButton), findsOneWidget);
      expect(find.byKey(HomeKeys.recentDocuments), findsOneWidget);
      expect(find.byKey(HomeKeys.allDocumentsShortcut), findsOneWidget);
      expect(find.byKey(HomeKeys.foldersSection), findsOneWidget);
      expect(find.byKey(HomeKeys.favouritesShortcut), findsOneWidget);
      expect(find.byKey(HomeKeys.archiveShortcut), findsOneWidget);
      expect(find.byKey(HomeKeys.storageSummary), findsOneWidget);
    });

    testWidgets('lists recent documents newest first', (tester) async {
      useTallViewport(tester);
      seedPopulatedLibrary();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      final rows = tester
          .widgetList<ListTile>(
            find.descendant(
              of: find.byKey(HomeKeys.recentDocuments),
              matching: find.byType(ListTile),
            ),
          )
          .toList();

      expect(rows, isNotEmpty);
      expect(
        (rows.first.title! as Text).data,
        // sampleDocuments steps updatedAt backwards, so index 0 is newest.
        sampleDocuments(3).first.title,
      );
    });

    testWidgets('shows the storage summary in a human-readable unit', (
      tester,
    ) async {
      seedPopulatedLibrary();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(DisplayFormatting.fileSize(3 * 1024 * 1024)),
        findsOneWidget,
      );
    });
  });

  group('Home empty state', () {
    testWidgets('is shown when no document exists', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byKey(HomeKeys.emptyState), findsOneWidget);
      // The spec requires the recents list not to render at all.
      expect(find.byKey(HomeKeys.recentDocuments), findsNothing);
    });

    testWidgets('its call to action starts scanning, same as the button', (
      tester,
    ) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan a document'));
      expect(recorder.scans, 1);

      await tester.tap(find.byKey(HomeKeys.scanButton));
      expect(recorder.scans, 2);
    });
  });

  group('Home loading and error states', () {
    testWidgets('shows an error view with a retry that reloads', (
      tester,
    ) async {
      documents.failure = const Failure.storage();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byKey(HomeKeys.errorView), findsOneWidget);
      expect(find.byKey(HomeKeys.errorRetryButton), findsOneWidget);

      seedPopulatedLibrary();
      documents.failure = null;
      await tester.tap(find.byKey(HomeKeys.errorRetryButton));
      await tester.pumpAndSettle();

      expect(find.byKey(HomeKeys.errorView), findsNothing);
      expect(find.byKey(HomeKeys.recentDocuments), findsOneWidget);
    });

    testWidgets('the error message is human-readable, not technical', (
      tester,
    ) async {
      documents.failure = const Failure.storage(debugDetail: 'errno 5');

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.textContaining('errno'), findsNothing);
      expect(
        find.text(
          'Something went wrong reading your documents. Please try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('Home navigation', () {
    testWidgets('each shortcut invokes its own action', (tester) async {
      useTallViewport(tester);
      seedPopulatedLibrary();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeKeys.allDocumentsShortcut));
      await tester.tap(find.byKey(HomeKeys.favouritesShortcut));
      await tester.tap(find.byKey(HomeKeys.archiveShortcut));
      await tester.tap(find.byKey(HomeKeys.searchBar));

      // Each exactly once: a copy-paste slip that wired two shortcuts to the
      // same callback would show up here and nowhere else.
      expect(recorder.allDocuments, 1);
      expect(recorder.favourites, 1);
      expect(recorder.archive, 1);
      expect(recorder.searches, 1);
    });

    testWidgets('opening a recent document reports its identifier', (
      tester,
    ) async {
      useTallViewport(tester);
      seedPopulatedLibrary();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      final newest = sampleDocuments(3).first;
      await tester.tap(find.byKey(HomeKeys.recentDocument(newest.id.value)));

      expect(recorder.openedDocument, newest.id);
    });

    testWidgets('opening a folder reports its identifier', (tester) async {
      useTallViewport(tester);
      seedPopulatedLibrary();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      final folder = sampleFolders(2).first;
      await tester.tap(find.byKey(HomeKeys.folderChip(folder.id.value)));

      expect(recorder.openedFolder, folder.id);
    });
  });

  group('Home responsive layout', () {
    testWidgets('uses the extra width on a tablet viewport', (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      seedPopulatedLibrary();
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      // The tablet layout puts the shortcut column beside the content column;
      // the phone layout stacks them, so there is no Row wrapping both.
      expect(
        find.ancestor(
          of: find.byKey(HomeKeys.recentDocuments),
          matching: find.byType(Row),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a rotation without losing its content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      seedPopulatedLibrary();
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.recentDocuments), findsOneWidget);

      // Rotate: same viewport, swapped axes.
      tester.view.physicalSize = const Size(1800, 1200);
      await tester.pumpAndSettle();

      // The Cubit outlives the layout change, so the data is still there and no
      // reload was needed.
      expect(find.byKey(HomeKeys.recentDocuments), findsOneWidget);
      expect(find.byKey(HomeKeys.storageSummary), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode without overflowing', (tester) async {
      seedPopulatedLibrary();

      await tester.pumpWidget(build(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Home accessibility baseline', () {
    testWidgets('every interactive control has a semantics label', (
      tester,
    ) async {
      seedPopulatedLibrary();
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Search documents'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^All documents')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Favourites')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Archive')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Storage used')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the storage summary states its value, not just its name', (
      tester,
    ) async {
      seedPopulatedLibrary();
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Storage used: ${DisplayFormatting.fileSize(3 * 1024 * 1024)} '
          'across ${DisplayFormatting.documentCount(5)}',
        ),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('every touch target measures at least 48dp', (tester) async {
      seedPopulatedLibrary();

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      for (final key in [
        HomeKeys.scanButton,
        HomeKeys.searchBar,
        HomeKeys.allDocumentsShortcut,
        HomeKeys.favouritesShortcut,
        HomeKeys.archiveShortcut,
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(
          size.height,
          greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
          reason: '$key is only ${size.height}dp tall',
        );
        expect(
          size.width,
          greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
          reason: '$key is only ${size.width}dp wide',
        );
      }
    });

    testWidgets('stays readable and scrollable at the maximum text scale', (
      tester,
    ) async {
      seedPopulatedLibrary();

      await tester.pumpWidget(
        MediaQuery(
          // The largest scale the accessibility settings offer.
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: build(),
        ),
      );
      await tester.pumpAndSettle();

      // No overflow: every section is inside a scroll view rather than being
      // clipped off the bottom of a fixed column.
      expect(tester.takeException(), isNull);
      expect(find.byKey(HomeKeys.storageSummary), findsOneWidget);
    });

    testWidgets('the empty state remains reachable at a large text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: build(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(HomeKeys.emptyState), findsOneWidget);
    });
  });

  group('Home widgets in isolation', () {
    testWidgets('the shortcut announces its count', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeShortcut(
              label: 'Favourites',
              icon: Icons.star_outline,
              count: 3,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Favourites, 3 documents'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the folders section explains its own emptiness', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeFoldersSection(folders: const [], onOpenFolder: (_) {}),
          ),
        ),
      );

      expect(find.text('No folders yet.'), findsOneWidget);
    });

    testWidgets('a long document title truncates rather than overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RecentDocumentsSection(
              documents: [longTitleDocument],
              onOpenDocument: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
