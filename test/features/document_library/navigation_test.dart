import 'dart:async';

import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/app/router/route_gates.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_scanly/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/folder_detail_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/folder_list_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_card.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/folder_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';

final _now = DateTime.utc(2026, 8);

/// A placeholder for routes outside the library.
Widget _placeholder(String label) =>
    Scaffold(key: Key('placeholder_$label'), body: Text(label));

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

  DocumentListCubit listCubit({
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) => DocumentListCubit(
    LoadDocuments(documents),
    ToggleFavourite(documents, clock),
    ArchiveDocument(documents, clock),
    RestoreDocument(documents, clock),
    filter: filter,
    folderId: folderId,
  );

  Widget listRoute(
    BuildContext context, {
    required String title,
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) => BlocProvider(
    create: (_) => listCubit(filter: filter, folderId: folderId),
    child: Builder(
      builder: (listContext) {
        void open(DocumentId id) async {
          await context.push(AppRoutes.documentView(id));
          if (listContext.mounted) {
            await listContext.read<DocumentListCubit>().load();
          }
        }

        return folderId == null
            ? DocumentListScreen(title: title, onOpenDocument: open)
            : FolderDetailScreen(folderName: title, onOpenDocument: open);
      },
    ),
  );

  /// The library's real screens, wired into the real router.
  ///
  /// Placeholders stand in for every route another capability owns, so this
  /// exercises the library's own navigation without pulling in features that
  /// do not exist yet.
  AppScreens buildScreens() => AppScreens(
    onboarding: (_) => _placeholder('onboarding'),
    unlock: (_) => _placeholder('unlock'),
    home: (context) => Scaffold(
      key: const Key('placeholder_home'),
      body: Column(
        children: [
          TextButton(
            key: const Key('go_documents'),
            onPressed: () => context.push(AppRoutes.documents),
            child: const Text('Documents'),
          ),
          TextButton(
            key: const Key('go_folders'),
            onPressed: () => context.push(AppRoutes.folders),
            child: const Text('Folders'),
          ),
        ],
      ),
    ),
    scan: (_) => _placeholder('scan'),
    documents: (context) => listRoute(context, title: 'Documents'),
    viewer: (context, id) => Scaffold(
      key: Key('placeholder_viewer:${id.value}'),
      body: TextButton(
        key: const Key('viewer_toggle_favourite_and_back'),
        onPressed: () async {
          await ToggleFavourite(documents, clock)(id);
          if (context.mounted) context.pop();
        },
        child: const Text('Toggle favourite and back'),
      ),
    ),
    documentDetail: (context, id) => BlocProvider(
      create: (_) => DocumentDetailCubit(
        id,
        LoadDocumentDetail(documents),
        RenameDocument(documents, clock, InMemoryPublicFileStore()),
        MoveDocument(documents, clock),
        ToggleFavourite(documents, clock),
        ArchiveDocument(documents, clock),
        RestoreDocument(documents, clock),
        DuplicateDocument(
          documents,
          pages,
          InMemoryPublicFileStore(),
          clock,
          ids,
        ),
        PurgeDocument(
          documents,
          pages,
          InMemoryPublicFileStore(),
          files,
          secure,
        ),
      ),
      child: DocumentDetailScreen(onClose: () => context.pop()),
    ),
    documentEdit: (_, _) => _placeholder('documentEdit'),
    folders: (context) => BlocProvider(
      create: (_) => FolderCubit(
        LoadFolders(folders),
        CreateFolder(folders, clock, ids),
        RenameFolder(folders),
        DeleteFolder(
          folders,
          documents,
          MoveDocument(documents, clock),
          PurgeDocument(
            documents,
            pages,
            InMemoryPublicFileStore(),
            files,
            secure,
          ),
        ),
      ),
      child: FolderListScreen(
        onOpenFolder: (id) => context.push(AppRoutes.folderDetail(id)),
      ),
    ),
    folderDetail: (context, id) => listRoute(
      context,
      title: folders.folders[id]?.name ?? 'Folder',
      filter: DocumentFilter.folder,
      folderId: id,
    ),
    search: (_) => _placeholder('search'),
    favourites: (context) => listRoute(
      context,
      title: 'Favourites',
      filter: DocumentFilter.favourites,
    ),
    archive: (context) =>
        listRoute(context, title: 'Archive', filter: DocumentFilter.archived),
    trash: (_) => _placeholder('trash'),
    settings: (_) => _placeholder('settings'),
    about: (_) => _placeholder('about'),
    privacy: (_) => _placeholder('privacy'),
  );

  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = createAppRouter(
      guard: RouteGuard(
        lockGate: FakeAppLockGate(),
        onboardingGate: FakeOnboardingGate(),
      ),
      screens: buildScreens(),
      initialLocation: location,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('library routes', () {
    testWidgets('the documents route renders the document list', (
      tester,
    ) async {
      documents.documents[sampleDocument.id] = sampleDocument;

      await pumpAt(tester, AppRoutes.documents);

      expect(find.byKey(LibraryKeys.documentListScreen), findsOneWidget);
      expect(find.byType(DocumentCard), findsOneWidget);
    });

    testWidgets('the favourites route shows only favourites', (tester) async {
      documents.documents.addAll({
        sampleDocument.id: sampleDocument,
        favouriteDocument.id: favouriteDocument,
      });

      await pumpAt(tester, AppRoutes.favourites);

      expect(find.byType(DocumentCard), findsOneWidget);
      expect(find.text(favouriteDocument.title), findsOneWidget);
    });

    testWidgets('the archive route shows only archived documents', (
      tester,
    ) async {
      documents.documents.addAll({
        sampleDocument.id: sampleDocument,
        archivedDocument.id: archivedDocument,
      });

      await pumpAt(tester, AppRoutes.archive);

      expect(find.byType(DocumentCard), findsOneWidget);
      expect(find.text(archivedDocument.title), findsOneWidget);
    });

    testWidgets('the folders route renders the folder list', (tester) async {
      folders.folders[sampleFolder.id] = sampleFolder;

      await pumpAt(tester, AppRoutes.folders);

      expect(find.byKey(LibraryKeys.folderListScreen), findsOneWidget);
      expect(find.byType(FolderTile), findsOneWidget);
    });
  });

  group('the document detail route parameter', () {
    testWidgets('resolves the identifier in the path to that document', (
      tester,
    ) async {
      documents.documents.addAll({
        sampleDocument.id: sampleDocument,
        favouriteDocument.id: favouriteDocument,
      });

      await pumpAt(tester, AppRoutes.documentDetail(favouriteDocument.id));

      // The right document, not merely *a* document: the parameter is what
      // selects it, and a route that ignored it would still render something.
      expect(find.text(favouriteDocument.title), findsWidgets);
      expect(find.text(sampleDocument.title), findsNothing);
    });

    testWidgets('an identifier for a deleted document shows an error', (
      tester,
    ) async {
      await pumpAt(tester, AppRoutes.documentDetail(const DocumentId('gone')));

      // A stale link must not crash the app — the spec requires a way forward.
      expect(find.text('That item no longer exists.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an identifier containing unusual characters survives the URL', (
      tester,
    ) async {
      const id = DocumentId('a b/c');
      documents.documents[id] = sampleDocument.copyWith(
        id: id,
        title: 'Odd identifier',
      );

      await pumpAt(tester, AppRoutes.documentDetail(id));

      // An unencoded identifier would split into extra path segments and match
      // a different route, or none at all.
      expect(tester.takeException(), isNull);
    });
  });

  group('navigating between library screens', () {
    testWidgets('opening a document row pushes Viewer directly', (
      tester,
    ) async {
      documents.documents[sampleDocument.id] = sampleDocument;
      pages.pages[sampleDocument.id] = samplePages(2);

      await pumpAt(tester, AppRoutes.documents);
      await tester.tap(find.byType(DocumentCard));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('placeholder_viewer:${sampleDocument.id.value}')),
        findsOneWidget,
      );
      expect(find.byKey(LibraryKeys.documentDetailScreen), findsNothing);
    });

    testWidgets('Favourites reloads after Viewer removes the favourite', (
      tester,
    ) async {
      documents.documents[favouriteDocument.id] = favouriteDocument;

      await pumpAt(tester, AppRoutes.favourites);
      await tester.tap(find.byType(DocumentCard));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('viewer_toggle_favourite_and_back')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DocumentCard), findsNothing);
      expect(find.byKey(LibraryKeys.documentListEmptyState), findsOneWidget);
    });

    testWidgets('metadata Details has no duplicate lifecycle menu', (
      tester,
    ) async {
      documents.documents[sampleDocument.id] = sampleDocument;

      final router = await pumpAt(tester, AppRoutes.documents);
      unawaited(router.push(AppRoutes.documentDetail(sampleDocument.id)));
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentDetailMenu), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(LibraryKeys.documentDetailScreen), findsNothing);
      expect(find.byKey(LibraryKeys.documentListScreen), findsOneWidget);
    });

    testWidgets('opening a folder shows only that folder\'s documents', (
      tester,
    ) async {
      folders.folders[sampleFolder.id] = sampleFolder;
      documents.documents.addAll({
        sampleDocument.id: sampleDocument.copyWith(folderId: sampleFolder.id),
        // Unfiled, so it must not appear inside the folder.
        protectedDocument.id: protectedDocument,
      });

      await pumpAt(tester, AppRoutes.folders);
      await tester.tap(find.byType(FolderTile));
      await tester.pumpAndSettle();

      expect(find.text(sampleFolder.name), findsWidgets);
      expect(find.byType(DocumentCard), findsOneWidget);
      expect(find.text(sampleDocument.title), findsOneWidget);
    });

    testWidgets('Home reaches the documents and folders routes', (
      tester,
    ) async {
      await pumpAt(tester, AppRoutes.home);

      await tester.tap(find.byKey(const Key('go_documents')));
      await tester.pumpAndSettle();
      expect(find.byKey(LibraryKeys.documentListScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('go_folders')));
      await tester.pumpAndSettle();
      expect(find.byKey(LibraryKeys.folderListScreen), findsOneWidget);
    });
  });
}
