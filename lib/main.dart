/// Entry point for the DocForge application.
///
/// Deliberately thin: build the dependency graph once, build the router over
/// it, hand both to the root widget. No feature logic, no service lookup and no
/// mutable global state lives here.
library;

import 'package:doc_forge/app/app.dart';
import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/app/composition_root.dart';
import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/app/scanning_module.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/theme/theme_mode_controller.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_cubit.dart';
import 'package:doc_forge/features/app_shell/presentation/screens/home_screen.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_list_screen.dart';
import 'package:doc_forge/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_forge/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_forge/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_forge/features/document_viewer/presentation/screens/viewer_screen.dart';
import 'package:doc_forge/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_forge/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_forge/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Boots the application.
Future<void> main() async {
  // Required before any plugin is touched — SharedPreferences, secure storage
  // and the Isar directory lookup are all resolved below.
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await buildAppDependencies();

  final scanning = buildScanningModule(
    directory: await getApplicationCacheDirectory(),
    permissions: dependencies.permissions,
    ids: dependencies.idGenerator,
    worker: dependencies.worker,
  );

  final library = await buildLibraryModule(
    clock: dependencies.clock,
    ids: dependencies.idGenerator,
    secureStorage: dependencies.secureStorage,
  );

  final creation = buildDocumentCreationModule(
    isar: library.isar,
    documentsDirectory: library.documentsDirectory,
    clock: dependencies.clock,
    ids: dependencies.idGenerator,
    documentReader: library.documentReader,
    documentWriter: library.documentWriter,
    // Settings land in group 15; until then the default pattern applies.
    namingPattern: () => NamingPattern.defaultPattern,
  );

  // Onboarding owns its own gate. The flag is read once here, before the first
  // frame, so the router's synchronous redirect has an answer immediately —
  // otherwise a first-time user would see Home flash before onboarding.
  final onboardingRepository = OnboardingRepositoryImpl(
    dependencies.preferences,
  );
  final onboardingGate = OnboardingGateImpl(
    IsOnboardingComplete(onboardingRepository).call,
  );
  await onboardingGate.load();

  // The lock gate is still a placeholder: `app-security` supplies the real one.
  final router = createAppRouter(
    guard: RouteGuard(
      lockGate: FakeAppLockGate(),
      onboardingGate: onboardingGate,
    ),
    screens: _screens(
      dependencies,
      library,
      scanning,
      creation,
      onboardingRepository,
      onboardingGate,
    ),
  );

  runApp(
    DocForgeApp(
      dependencies: dependencies,
      router: router,
      themeMode: ThemeModeController(),
    ),
  );
}

/// Builds the screen set, replacing placeholders as features land.
AppScreens _screens(
  AppDependencies dependencies,
  LibraryModule library,
  ScanningModule scanning,
  DocumentCreationModule creation,
  OnboardingRepositoryImpl onboardingRepository,
  OnboardingGateImpl onboardingGate,
) {
  /// Builds a document list scoped to [filter]; four routes differ only here.
  Widget documentList(
    BuildContext context, {
    required String title,
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
    String? emptyTitle,
    String? emptyMessage,
    bool offerScan = true,
  }) => BlocProvider(
    create: (_) => DocumentListCubit(
      library.loadDocuments,
      library.toggleFavourite,
      library.archiveDocument,
      library.restoreDocument,
      filter: filter,
      folderId: folderId,
    ),
    child: DocumentListScreen(
      title: title,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      // The archive and favourites deliberately offer no scan action: "scan
      // your first document" is not what an empty archive should suggest.
      onScan: offerScan ? () => context.push(AppRoutes.scan) : null,
      onOpenDocument: (id) => context.push(AppRoutes.documentDetail(id)),
    ),
  );

  return AppScreens(
    onboarding: (context) => BlocProvider(
      create: (_) => OnboardingCubit(
        CompleteOnboarding(onboardingRepository),
        RequestOnboardingCameraPermission(dependencies.permissions),
      ),
      child: OnboardingScreen(
        onFinished: () {
          // Update the gate first: the router re-evaluates its redirect on
          // navigation, and a stale gate would bounce the user straight back
          // into onboarding.
          onboardingGate.markComplete();
          context.go(AppRoutes.home);
        },
      ),
    ),
    unlock: (_) => const _Placeholder('Unlock'),
    home: (context) => BlocProvider(
      create: (_) => HomeCubit(
        LoadHomeData(
          library.documentReader,
          library.folderReader,
          library.storageSummaryReader,
        ),
      ),
      child: HomeScreen(
        actions: HomeActions(
          onScan: () => context.push(AppRoutes.scan),
          onSearch: () => context.push(AppRoutes.search),
          onOpenDocument: (id) => context.push(AppRoutes.documentDetail(id)),
          onOpenFolder: (id) => context.push(AppRoutes.folderDetail(id)),
          onAllDocuments: () => context.push(AppRoutes.documents),
          onFolders: () => context.push(AppRoutes.folders),
          onFavourites: () => context.push(AppRoutes.favourites),
          onArchive: () => context.push(AppRoutes.archive),
          onStorage: () => context.push(AppRoutes.settings),
        ),
      ),
    ),
    scan: (context) => ScanFlow(
      module: scanning,
      creation: creation,
      onExit: () => context.go(AppRoutes.home),
      // Home reloads on navigation, so the new document appears at the top of
      // Recent without anything having to tell it.
      onSaved: (_) => context.go(AppRoutes.home),
      onImportInstead: () => context.go(AppRoutes.home),
      onOpenSettings: () => dependencies.permissions.openSettings(),
    ),
    scanReview: (_) => const _Placeholder('Review pages'),
    scanEnhance: (_) => const _Placeholder('Enhance'),
    scanPreview: (_) => const _Placeholder('Preview document'),
    documents: (context) => documentList(context, title: 'Documents'),
    viewer: (context, id) => BlocProvider(
      create: (_) => ViewerCubit(
        id,
        OpenDocumentForViewing(
          library.documentReader,
          const PdfrxRenderer(),
          dependencies.secureStorage,
        ),
        RememberDocumentPassword(dependencies.secureStorage),
        LoadViewerText(creation.ocrTextSource),
      )..load(),
      child: ViewerScreen(
        // The rendering surface comes from here rather than from the screen:
        // it is a plugin-backed widget, and a screen that built its own could
        // be neither previewed nor tested.
        surfaceBuilder:
            (
              context, {
              required filePath,
              required password,
              required page,
              required onPageChanged,
            }) => PdfViewer.file(
              filePath,
              passwordProvider: () => password,
              params: PdfViewerParams(
                onPageChanged: (page) => onPageChanged(page ?? 1),
              ),
            ),
        onBack: () => context.pop(),
        // Sharing, printing and editing land in groups 12 and 14.
        onShare: () => _notYet(context, 'Sharing'),
        onPrint: () => _notYet(context, 'Printing'),
        onEdit: () => _notYet(context, 'Editing'),
      ),
    ),
    documentDetail: (context, id) => BlocProvider(
      create: (_) => DocumentDetailCubit(
        id,
        library.loadDocumentDetail,
        library.renameDocument,
        library.moveDocument,
        library.toggleFavourite,
        library.archiveDocument,
        library.restoreDocument,
        library.duplicateDocument,
        library.purgeDocument,
      ),
      child: DocumentDetailScreen(
        onClose: () => context.pop(),
        // Replaces rather than pushes: the user asked for a copy, and leaving
        // the original underneath would make Back feel like an undo it is not.
        onOpenDocument: (document) =>
            context.pushReplacement(AppRoutes.documentDetail(document.id)),
      ),
    ),
    documentEdit: (_, id) => _Placeholder('Edit ${id.value}'),
    folders: (context) => BlocProvider(
      create: (_) => FolderCubit(
        library.loadFolders,
        library.createFolder,
        library.renameFolder,
        library.deleteFolder,
      ),
      child: FolderListScreen(
        onOpenFolder: (id) => context.push(AppRoutes.folderDetail(id)),
      ),
    ),
    folderDetail: (context, id) => BlocProvider(
      create: (_) => DocumentListCubit(
        library.loadDocuments,
        library.toggleFavourite,
        library.archiveDocument,
        library.restoreDocument,
        filter: DocumentFilter.folder,
        folderId: id,
      ),
      child: FolderDetailScreen(
        folderName: 'Folder',
        onOpenDocument: (documentId) =>
            context.push(AppRoutes.documentDetail(documentId)),
      ),
    ),
    search: (_) => const _Placeholder('Search'),
    favourites: (context) => documentList(
      context,
      title: 'Favourites',
      filter: DocumentFilter.favourites,
      emptyTitle: 'No favourites yet',
      emptyMessage: 'Mark a document as a favourite to find it here.',
      offerScan: false,
    ),
    archive: (context) => documentList(
      context,
      title: 'Archive',
      filter: DocumentFilter.archived,
      emptyTitle: 'Nothing archived',
      emptyMessage: 'Archived documents are kept here, out of your main list.',
      offerScan: false,
    ),
    settings: (_) => const _Placeholder('Settings'),
    about: (_) => const _Placeholder('About'),
    privacy: (_) => const _Placeholder('Privacy policy'),
  );
}

/// Tells the user a capability is not in this build yet.
///
/// Preferred to an inert control: a button that does nothing when tapped reads
/// as a bug, where a message reads as a boundary.
void _notYet(BuildContext context, String capability) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text('$capability arrives in a later step.')));

/// A labelled stand-in for a screen that has not been built yet.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyState(
        title: title,
        message: 'This screen has not been built yet.',
        icon: Icons.construction_outlined,
      ),
    );
  }
}
