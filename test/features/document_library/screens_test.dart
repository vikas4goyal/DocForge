import 'dart:async';

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/document_card.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/folder_tile.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/page_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _now = DateTime.utc(2026, 8);

void main() {
  late FakeDocumentRepository documents;
  late FakeFolderRepository folders;
  late FakePageRepository pages;
  late FakeDocumentFileStore files;
  late InMemorySecureStore secure;
  late Clock clock;
  late IdGenerator ids;

  setUp(() {
    documents = FakeDocumentRepository();
    folders = FakeFolderRepository();
    pages = FakePageRepository();
    files = FakeDocumentFileStore();
    secure = InMemorySecureStore();
    clock = FixedClock(_now);
    ids = SequentialIdGenerator(prefix: 'new');
  });

  DocumentListCubit listCubit({DocumentFilter filter = DocumentFilter.all}) =>
      DocumentListCubit(
        LoadDocuments(documents),
        ToggleFavourite(documents, clock),
        ArchiveDocument(documents, clock),
        RestoreDocument(documents, clock),
        filter: filter,
      );

  DocumentDetailCubit detailCubit(DocumentId id) => DocumentDetailCubit(
    id,
    LoadDocumentDetail(documents, pages),
    RenameDocument(documents, clock),
    MoveDocument(documents, clock),
    ToggleFavourite(documents, clock),
    ArchiveDocument(documents, clock),
    RestoreDocument(documents, clock),
    DuplicateDocument(documents, pages, InMemoryPublicFileStore(), clock, ids),
    PurgeDocument(documents, pages, InMemoryPublicFileStore(), files, secure),
  );

  FolderCubit folderCubit() => FolderCubit(
    LoadFolders(folders),
    CreateFolder(folders, clock, ids),
    RenameFolder(folders),
    DeleteFolder(
      folders,
      documents,
      MoveDocument(documents, clock),
      PurgeDocument(documents, pages, InMemoryPublicFileStore(), files, secure),
    ),
  );

  Widget host(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: child,
      );

  group('DocumentListScreen', () {
    Widget build({
      DocumentFilter filter = DocumentFilter.all,
      VoidCallback? onScan,
      void Function(DocumentId id)? onOpen,
    }) => host(
      BlocProvider.value(
        value: listCubit(filter: filter),
        child: DocumentListScreen(
          title: 'Documents',
          onOpenDocument: onOpen ?? (_) {},
          onScan: onScan,
        ),
      ),
    );

    testWidgets('shows the loading indicator before documents arrive', (
      tester,
    ) async {
      // The query is held open, because an in-memory fake otherwise completes
      // within the same frame and the loading state is never observable.
      final gate = Completer<void>();
      documents.gate = gate;

      await tester.pumpWidget(build());
      await tester.pump();

      expect(find.byKey(LibraryKeys.documentListLoading), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentListLoading), findsNothing);
    });

    testWidgets('shows an empty state with a call to action', (tester) async {
      var scanned = false;
      await tester.pumpWidget(build(onScan: () => scanned = true));
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentListEmptyState), findsOneWidget);

      await tester.tap(find.text('Scan a document'));
      expect(scanned, isTrue);
    });

    testWidgets('shows an error view whose retry reloads the list', (
      tester,
    ) async {
      documents.failure = const Failure.storage();
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentListErrorView), findsOneWidget);

      documents.documents[sampleDocument.id] = sampleDocument;
      documents.failure = null;
      await tester.tap(find.byKey(const Key('document_list_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentCard), findsOneWidget);
    });

    testWidgets('renders a row per document, keyed by identifier', (
      tester,
    ) async {
      documents.documents.addAll({for (final d in sampleDocuments(3)) d.id: d});
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(DocumentCard), findsNWidgets(3));
      for (final document in documents.documents.values) {
        expect(
          find.byKey(LibraryKeys.documentListItem(document.id.value)),
          findsOneWidget,
        );
      }
    });

    testWidgets('opening a row reports the document that was tapped', (
      tester,
    ) async {
      documents.documents[sampleDocument.id] = sampleDocument;
      DocumentId? opened;
      await tester.pumpWidget(build(onOpen: (id) => opened = id));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DocumentCard));
      expect(opened, sampleDocument.id);
    });

    testWidgets('the favourite control toggles and persists', (tester) async {
      documents.documents[sampleDocument.id] = sampleDocument;
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(LibraryKeys.documentFavouriteToggle));
      await tester.pumpAndSettle();

      expect(documents.documents[sampleDocument.id]?.isFavourite, isTrue);
    });

    testWidgets('a document row announces its metadata to a screen reader', (
      tester,
    ) async {
      documents.documents[sampleDocument.id] = sampleDocument;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      final label = DisplayFormatting.documentSemanticsLabel(sampleDocument);
      expect(find.bySemanticsLabel(label), findsOneWidget);

      handle.dispose();
    });

    testWidgets('lays out multiple columns on a tablet-width viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      documents.documents.addAll({for (final d in sampleDocuments(6)) d.id: d});
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, greaterThan(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode without overflowing', (tester) async {
      documents.documents.addAll({for (final d in sampleDocuments(4)) d.id: d});
      await tester.pumpWidget(
        host(
          BlocProvider.value(
            value: listCubit(),
            child: DocumentListScreen(
              title: 'Documents',
              onOpenDocument: (_) {},
            ),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('DocumentDetailScreen', () {
    Widget build({VoidCallback? onClose}) => host(
      BlocProvider.value(
        value: detailCubit(sampleDocument.id),
        child: DocumentDetailScreen(onClose: onClose ?? () {}),
      ),
    );

    setUp(() {
      documents.documents[sampleDocument.id] = sampleDocument;
      pages.pages[sampleDocument.id] = samplePages(2);
    });

    testWidgets('shows every piece of metadata the spec requires', (
      tester,
    ) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentDetailScreen), findsOneWidget);
      expect(find.text(sampleDocument.title), findsWidgets);
      expect(
        find.text(DisplayFormatting.pageCount(sampleDocument.pageCount)),
        findsOneWidget,
      );
      expect(
        find.text(DisplayFormatting.fileSize(sampleDocument.sizeInBytes)),
        findsOneWidget,
      );
      expect(
        find.text(DisplayFormatting.dateTime(sampleDocument.createdAt)),
        findsOneWidget,
      );
      expect(
        find.text(DisplayFormatting.dateTime(sampleDocument.updatedAt)),
        findsOneWidget,
      );
    });

    testWidgets('shows a thumbnail per page', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(PageThumbnail), findsNWidgets(2));
    });

    testWidgets('renaming updates the title', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('document_detail_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LibraryKeys.documentRenameButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(LibraryKeys.documentRenameField),
        'Renamed',
      );
      await tester.tap(find.byKey(LibraryKeys.documentRenameConfirm));
      await tester.pumpAndSettle();

      expect(documents.documents[sampleDocument.id]?.title, 'Renamed');
    });

    testWidgets('an empty rename is refused and the dialog stays open', (
      tester,
    ) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('document_detail_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LibraryKeys.documentRenameButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(LibraryKeys.documentRenameField),
        '   ',
      );
      await tester.tap(find.byKey(LibraryKeys.documentRenameConfirm));
      await tester.pumpAndSettle();

      // The dialog is still up with its complaint, and nothing was renamed.
      expect(find.byKey(LibraryKeys.documentRenameField), findsOneWidget);
      expect(find.text('Enter a name.'), findsOneWidget);
      expect(
        documents.documents[sampleDocument.id]?.title,
        sampleDocument.title,
      );
    });

    testWidgets('permanent removal requires confirmation', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('document_detail_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LibraryKeys.documentDeleteButton));
      await tester.pumpAndSettle();

      expect(
        find.byKey(LibraryKeys.documentDeleteConfirmDialog),
        findsOneWidget,
      );

      await tester.tap(find.byKey(LibraryKeys.documentDeleteCancelButton));
      await tester.pumpAndSettle();

      // Cancelling must leave the document entirely untouched.
      expect(documents.documents, hasLength(1));
    });

    testWidgets('confirming removal deletes and closes the screen', (
      tester,
    ) async {
      var closed = false;
      await tester.pumpWidget(build(onClose: () => closed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('document_detail_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LibraryKeys.documentDeleteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LibraryKeys.documentDeleteConfirmButton));
      await tester.pumpAndSettle();

      expect(documents.documents, isEmpty);
      expect(closed, isTrue);
    });

    testWidgets('archiving is offered for an active document', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('document_detail_menu')));
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentArchiveButton), findsOneWidget);
      expect(find.byKey(LibraryKeys.documentRestoreButton), findsNothing);
    });

    testWidgets('restoring is offered instead once archived', (tester) async {
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        isArchived: true,
      );
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('document_detail_menu')));
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentRestoreButton), findsOneWidget);
      expect(find.byKey(LibraryKeys.documentArchiveButton), findsNothing);
    });

    testWidgets(
      'a missing document shows an error rather than blank metadata',
      (tester) async {
        documents.documents.clear();
        await tester.pumpWidget(build());
        await tester.pumpAndSettle();

        expect(find.text('That item no longer exists.'), findsOneWidget);
      },
    );
  });

  group('FolderListScreen', () {
    Widget build({void Function(FolderId id)? onOpen}) => host(
      BlocProvider.value(
        value: folderCubit(),
        child: FolderListScreen(onOpenFolder: onOpen ?? (_) {}),
      ),
    );

    testWidgets('shows an empty state when no folder exists', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.folderListEmptyState), findsOneWidget);
    });

    testWidgets('creating a folder adds it with a zero count', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(LibraryKeys.folderCreateButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(LibraryKeys.folderNameField),
        'Receipts',
      );
      await tester.tap(find.byKey(LibraryKeys.folderNameConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(FolderTile), findsOneWidget);
      expect(find.text('0 documents'), findsOneWidget);
    });

    testWidgets('a duplicate name is refused', (tester) async {
      folders.folders[sampleFolder.id] = sampleFolder;
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(LibraryKeys.folderCreateButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(LibraryKeys.folderNameField),
        sampleFolder.name,
      );
      await tester.tap(find.byKey(LibraryKeys.folderNameConfirm));
      await tester.pumpAndSettle();

      // Still exactly one folder: the duplicate was not created.
      expect(folders.folders, hasLength(1));
    });

    testWidgets('deleting a folder asks what happens to its documents', (
      tester,
    ) async {
      folders.folders[sampleFolder.id] = sampleFolder.copyWith(
        documentCount: 2,
      );
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(LibraryKeys.folderDeleteStrategyDialog),
        findsOneWidget,
      );
      expect(find.byKey(LibraryKeys.folderDeleteMoveOut), findsOneWidget);
      expect(find.byKey(LibraryKeys.folderDeleteWithDocuments), findsOneWidget);
    });

    testWidgets('cancelling the deletion dialog keeps the folder', (
      tester,
    ) async {
      folders.folders[sampleFolder.id] = sampleFolder;
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(folders.folders, hasLength(1));
    });

    testWidgets('keeping the documents deletes only the folder', (
      tester,
    ) async {
      folders.folders[sampleFolder.id] = sampleFolder;
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        folderId: sampleFolder.id,
      );
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LibraryKeys.folderDeleteMoveOut));
      await tester.pumpAndSettle();

      expect(folders.folders, isEmpty);
      expect(documents.documents[sampleDocument.id]?.folderId, isNull);
    });

    testWidgets('a folder row announces its name and count', (tester) async {
      folders.folders[sampleFolder.id] = sampleFolder.copyWith(
        documentCount: 3,
      );
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('${sampleFolder.name}, 3 documents'),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('opening a folder reports which one', (tester) async {
      folders.folders[sampleFolder.id] = sampleFolder;
      FolderId? opened;
      await tester.pumpWidget(build(onOpen: (id) => opened = id));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FolderTile));
      expect(opened, sampleFolder.id);
    });
  });

  group('DisplayFormatting', () {
    test('formats sizes with one decimal below ten units', () {
      expect(DisplayFormatting.fileSize(512), '512 B');
      expect(DisplayFormatting.fileSize(1536), '1.5 KB');
      expect(DisplayFormatting.fileSize(20 * 1024), '20 KB');
      expect(DisplayFormatting.fileSize(3 * 1024 * 1024), '3.0 MB');
    });

    test('uses the singular for exactly one', () {
      expect(DisplayFormatting.pageCount(1), '1 page');
      expect(DisplayFormatting.pageCount(2), '2 pages');
      expect(DisplayFormatting.documentCount(1), '1 document');
      expect(DisplayFormatting.documentCount(0), '0 documents');
    });

    test('renders a stored UTC timestamp in local time', () {
      final utc = DateTime.utc(2026, 7, 26, 23, 30);

      // Formatting the UTC value directly would show the wrong day for any
      // user east of UTC — the bug the UTC-everywhere rule exists to surface.
      expect(
        DisplayFormatting.date(utc),
        DisplayFormatting.date(utc.toLocal()),
      );
    });

    test('the semantics label carries everything the spec requires', () {
      final label = DisplayFormatting.documentSemanticsLabel(favouriteDocument);

      expect(label, contains(favouriteDocument.title));
      expect(
        label,
        contains(DisplayFormatting.pageCount(favouriteDocument.pageCount)),
      );
      expect(label, contains('modified'));
      expect(label, contains('favourite'));
    });
  });
}
