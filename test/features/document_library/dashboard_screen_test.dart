/// Widget tests for the dashboard.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/library_folder_usecases.dart';
import 'package:doc_scanly/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Finds [text] inside the content list, ignoring the recents strip above it.
///
/// A recently-saved document appears in both, so an unscoped text finder would
/// match twice and say nothing about which list rendered it.
Finder inList(String text) => find.descendant(
  of: find.byKey(DashboardKeys.contentList),
  matching: find.text(text),
);

void main() {
  late InMemoryPublicFileStore store;
  late FakeDocumentRepository documents;
  late List<Document> opened;
  late List<String> createdFolders;
  late int imports;

  setUp(() {
    store = InMemoryPublicFileStore();
    documents = FakeDocumentRepository();
    opened = [];
    createdFolders = [];
    imports = 0;
  });

  /// Puts a document in both the folder and the index.
  void given(String relative) {
    final path = LibraryPath.parse(relative);
    final document = Document(
      id: DocumentId(relative),
      title: path.baseName,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      pageCount: 1,
      sizeInBytes: 1024,
      libraryPath: path,
    );

    store.files[relative] = 'pdf';
    for (var depth = 1; depth <= path.folders.length; depth++) {
      store.folderPaths.add(path.folders.sublist(0, depth).join('/'));
    }
    documents.documents[document.id] = document;
  }

  Future<DashboardCubit> pumpDashboard(
    WidgetTester tester, {
    Future<void> Function()? onLibraryRefresh,
    Key? libraryRefreshKey,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = DashboardCubit(store: store, index: documents);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<DashboardCubit>.value(
          value: cubit,
          child: DashboardScreen(
            onLibraryRefresh: onLibraryRefresh,
            libraryRefreshKey: libraryRefreshKey,
            actions: DashboardActions(
              onOpenDocument: opened.add,
              onCreateFolder: createdFolders.add,
              onImportPdf: () => imports++,
            ),
          ),
        ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();
    return cubit;
  }

  group('composition', () {
    testWidgets('shows compact root controls without a redundant breadcrumb', (
      tester,
    ) async {
      given('Invoice.pdf');
      await pumpDashboard(tester);

      expect(find.byKey(DashboardKeys.searchField), findsOneWidget);
      expect(find.byKey(DashboardKeys.scrollView), findsOneWidget);
      expect(find.byKey(DashboardKeys.breadcrumb), findsNothing);
      expect(find.byKey(DashboardKeys.storageSummary), findsOneWidget);
      expect(find.byKey(DashboardKeys.createFolderButton), findsOneWidget);
      expect(find.byKey(DashboardKeys.importPdfButton), findsOneWidget);
      expect(find.byKey(DashboardKeys.favouritesCollection), findsOneWidget);
      expect(find.byKey(DashboardKeys.archiveCollection), findsOneWidget);
      expect(find.byKey(DashboardKeys.trashCollection), findsOneWidget);
    });

    testWidgets('lists documents and folders', (tester) async {
      given('Invoices/Receipt.pdf');
      given('Statement.pdf');
      await pumpDashboard(tester);

      expect(inList('Invoices'), findsOneWidget);
      expect(inList('Statement'), findsOneWidget);
    });

    testWidgets('keeps no more than five recents in one horizontal lane', (
      tester,
    ) async {
      for (var index = 0; index < 7; index++) {
        given('Document $index.pdf');
      }
      await pumpDashboard(tester);

      final lane = tester.widget<ListView>(find.byKey(DashboardKeys.recents));
      expect(lane.scrollDirection, Axis.horizontal);
      expect(
        find.descendant(
          of: find.byKey(DashboardKeys.recents),
          matching: find.byType(InkWell),
        ),
        findsNWidgets(DashboardCubit.maxRecents),
      );
    });

    testWidgets('pull refresh reconciles storage before reloading the index', (
      tester,
    ) async {
      final order = <String>[];
      await pumpDashboard(
        tester,
        onLibraryRefresh: () async {
          order.add('reconcile');
          documents.documents[const DocumentId('added')] = Document(
            id: const DocumentId('added'),
            title: 'Added',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            pageCount: 1,
            sizeInBytes: 1,
            libraryPath: LibraryPath.parse('Added.pdf'),
          );
        },
        libraryRefreshKey: const Key('library_cloud_refresh'),
      );

      final indicator = tester.widget<RefreshIndicator>(
        find.byKey(const Key('library_cloud_refresh')),
      );
      await indicator.onRefresh();
      order.add('loaded');
      await tester.pump();

      expect(order, ['reconcile', 'loaded']);
    });
  });

  group('recoverable folder deletion', () {
    testWidgets('confirms recursive contents and supports Undo', (
      tester,
    ) async {
      given('Projects/Scan.pdf');
      store.folderPaths.add('Projects/Empty');
      store.files['Projects/readme.txt'] = 'unknown';
      final trash = FakeTrashRepository();
      final folders = FakeFolderRepository();
      final clock = FixedClock(DateTime.utc(2026, 8, 3));
      final ids = SequentialIdGenerator(prefix: 'trash');
      final cubit = DashboardCubit(
        store: store,
        index: documents,
        inspectTrashCandidate: InspectTrashCandidate(store),
        moveFolderTreeToTrash: MoveFolderTreeToTrash(
          documents,
          folders,
          trash,
          store,
          clock,
          ids,
        ),
        restoreTrashEntry: RestoreTrashEntry(trash, documents, folders, store),
        renameLibraryFolder: RenameLibraryFolder(store, folders, documents),
        loadTrash: LoadTrash(trash),
      );
      addTearDown(cubit.close);
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
            value: cubit,
            child: DashboardScreen(
              actions: DashboardActions(
                onOpenDocument: opened.add,
                onCreateFolder: createdFolders.add,
                onImportPdf: () {},
              ),
            ),
          ),
        ),
      );
      await cubit.load();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(DashboardKeys.folderMenu('Projects')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DashboardKeys.folderTrash));
      await tester.pumpAndSettle();
      expect(find.byKey(DashboardKeys.trashConfirmDialog), findsOneWidget);
      expect(find.textContaining('2 files and 1 subfolders'), findsOneWidget);

      await tester.tap(find.byKey(DashboardKeys.trashConfirm));
      await tester.pumpAndSettle();
      expect(find.text('Moved to Trash'), findsOneWidget);
      expect(find.byKey(DashboardKeys.folderRow('Projects')), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.byKey(DashboardKeys.folderRow('Projects')), findsOneWidget);
    });
  });

  group('navigating', () {
    testWidgets('opening a folder shows its contents', (tester) async {
      given('Invoices/Receipt.pdf');
      await pumpDashboard(tester);

      await tester.tap(find.byKey(DashboardKeys.folderRow('Invoices')));
      await tester.pumpAndSettle();

      expect(find.text('Receipt'), findsOneWidget);
    });

    testWidgets('the breadcrumb names the path', (tester) async {
      given('Invoices/Receipt.pdf');
      final cubit = await pumpDashboard(tester);

      await cubit.openFolder('Invoices');
      await tester.pumpAndSettle();

      expect(find.byKey(DashboardKeys.breadcrumb), findsOneWidget);
      expect(find.text('DocScanly'), findsWidgets);
      expect(find.text('Invoices'), findsWidgets);
    });

    testWidgets('the breadcrumb goes back up', (tester) async {
      given('Invoices/Receipt.pdf');
      given('Root.pdf');
      final cubit = await pumpDashboard(tester);
      await cubit.openFolder('Invoices');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'DocScanly'));
      await tester.pumpAndSettle();

      expect(cubit.state.isAtRoot, isTrue);
    });

    testWidgets('only folders inside the library are reachable', (
      tester,
    ) async {
      given('Invoices/Receipt.pdf');
      final cubit = await pumpDashboard(tester);

      await cubit.openFolder('Invoices');
      await tester.pumpAndSettle();

      // The path is relative to the library root and cannot name anything
      // above it — the line between a document app and a file manager.
      expect(cubit.state.path, ['Invoices']);
      expect(cubit.state.breadcrumb.first, 'DocScanly');
    });
  });

  group('opening a document', () {
    testWidgets('reports which one was tapped', (tester) async {
      given('Invoice.pdf');
      await pumpDashboard(tester);

      await tester.tap(inList('Invoice'));
      await tester.pumpAndSettle();

      expect(opened.single.title, 'Invoice');
    });
  });

  group('searching', () {
    testWidgets('shows matches from anywhere in the library', (tester) async {
      given('Invoices/Receipt.pdf');
      given('Statement.pdf');
      await pumpDashboard(tester);

      await tester.enterText(find.byKey(DashboardKeys.searchField), 'receipt');
      await tester.pumpAndSettle();

      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Statement'), findsNothing);
    });

    testWidgets('hides the breadcrumb while searching', (tester) async {
      given('Invoice.pdf');
      await pumpDashboard(tester);

      await tester.enterText(find.byKey(DashboardKeys.searchField), 'invoice');
      await tester.pumpAndSettle();

      expect(find.byKey(DashboardKeys.breadcrumb), findsNothing);
    });

    testWidgets('says so when nothing matches', (tester) async {
      given('Invoice.pdf');
      await pumpDashboard(tester);

      await tester.enterText(
        find.byKey(DashboardKeys.searchField),
        'nothing at all',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DashboardKeys.emptyState), findsOneWidget);
      expect(find.text('No matches'), findsOneWidget);
    });
  });

  group('creating a folder', () {
    testWidgets('asks for a name', (tester) async {
      await pumpDashboard(tester);

      await tester.tap(find.byKey(DashboardKeys.createFolderButton));
      await tester.pumpAndSettle();

      expect(find.byKey(DashboardKeys.createFolderDialog), findsOneWidget);
    });

    testWidgets('reports the name entered', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.byKey(DashboardKeys.createFolderButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(DashboardKeys.createFolderField),
        'Receipts',
      );
      await tester.tap(find.byKey(DashboardKeys.createFolderConfirm));
      await tester.pumpAndSettle();

      // The screen does not validate: a name the filesystem will refuse has to
      // be refused the same way wherever it is entered.
      expect(createdFolders, ['Receipts']);
    });

    testWidgets('cancelling creates nothing', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.byKey(DashboardKeys.createFolderButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(createdFolders, isEmpty);
    });
  });

  group('importing', () {
    testWidgets('the import action opens the picker', (tester) async {
      await pumpDashboard(tester);

      await tester.tap(find.byKey(DashboardKeys.importPdfButton));
      await tester.pumpAndSettle();

      expect(imports, 1);
    });
  });

  group('states', () {
    testWidgets('an empty library invites the user to start', (tester) async {
      await pumpDashboard(tester);

      expect(find.byKey(DashboardKeys.emptyState), findsOneWidget);
    });

    testWidgets('an unreadable folder shows an error with a retry', (
      tester,
    ) async {
      store.failures['list'] = const Failure.storage();
      await pumpDashboard(tester);

      expect(find.byKey(DashboardKeys.errorView), findsOneWidget);
      expect(find.byKey(DashboardKeys.errorRetryButton), findsOneWidget);
    });

    testWidgets('retrying reloads', (tester) async {
      given('Invoice.pdf');
      store.failures['list'] = const Failure.storage();
      await pumpDashboard(tester);

      store.failures.clear();
      await tester.tap(find.byKey(DashboardKeys.errorRetryButton));
      await tester.pumpAndSettle();

      expect(inList('Invoice'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('the storage summary announces its value', (tester) async {
      final handle = tester.ensureSemantics();
      given('Invoice.pdf');
      await pumpDashboard(tester);

      expect(find.bySemanticsLabel(RegExp('Library uses')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('survives the largest supported text scale', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      given('Invoice.pdf');

      final cubit = DashboardCubit(store: store, index: documents);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<DashboardCubit>.value(
            value: cubit,
            child: DashboardScreen(
              actions: DashboardActions(
                onOpenDocument: (_) {},
                onCreateFolder: (_) {},
                onImportPdf: () {},
              ),
            ),
          ),
        ),
      );
      await cubit.load();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
