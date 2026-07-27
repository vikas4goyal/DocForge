/// Entry point for the DocForge application.
///
/// Deliberately thin: build the dependency graph once, build the router over
/// it, hand both to the root widget. No feature logic, no service lookup and no
/// mutable global state lives here.
library;

import 'dart:async';

import 'package:doc_forge/app/app.dart';
import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/app/composition_root.dart';
import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/app/import_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/pdf_editing_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/app/scanning_module.dart';
import 'package:doc_forge/app/sharing_module.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/theme/theme_mode_controller.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_cubit.dart';
import 'package:doc_forge/features/app_shell/presentation/screens/home_screen.dart';
import 'package:doc_forge/features/document_import/presentation/cubit/import_cubit.dart';
import 'package:doc_forge/features/document_import/presentation/screens/import_options_sheet.dart';
import 'package:doc_forge/features/document_import/presentation/widgets/shared_content_watcher.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_list_screen.dart';
import 'package:doc_forge/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:doc_forge/features/document_search/presentation/screens/search_screen.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:doc_forge/features/document_sharing/presentation/screens/share_options_sheet.dart';
import 'package:doc_forge/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_forge/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_forge/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_forge/features/document_viewer/presentation/screens/viewer_screen.dart';
import 'package:doc_forge/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_forge/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_forge/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_forge/features/pdf_editing/presentation/screens/pdf_edit_screen.dart';
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

  final importing = buildImportModule(
    renderer: const PdfrxRenderer(),
    documentWriter: library.documentWriter,
    documentsDirectory: library.documentsDirectory,
    cacheDirectory: await getApplicationCacheDirectory(),
    clock: dependencies.clock,
    ids: dependencies.idGenerator,
    worker: dependencies.worker,
  );

  final editing = buildPdfEditingModule(
    documentReader: library.documentReader,
    documentWriter: library.documentWriter,
    secureStorage: dependencies.secureStorage,
    documentsDirectory: library.documentsDirectory,
    clock: dependencies.clock,
    ids: dependencies.idGenerator,
  );

  final sharing = buildSharingModule(
    documentReader: library.documentReader,
    ocrTextSource: creation.ocrTextSource,
    cacheDirectory: await getApplicationCacheDirectory(),
    worker: dependencies.worker,
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
      sharing,
      importing,
      editing,
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
  SharingModule sharing,
  ImportModule importing,
  PdfEditingModule editing,
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
    home: (context) => SharedContentWatcher(
      takePending: importing.takePending,
      watchShared: importing.watchShared,
      // Wrapped around Home rather than around a route that comes and goes: a
      // share arriving while the user is deep in another flow would otherwise
      // be dropped.
      onContent: (paths) => _importShared(
        context,
        paths,
        importing,
        scanning,
        creation,
        dependencies,
      ),
      child: BlocProvider(
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
    ),
    scan: (context) => ScanFlow(
      module: scanning,
      creation: creation,
      onExit: () => context.go(AppRoutes.home),
      // Home reloads on navigation, so the new document appears at the top of
      // Recent without anything having to tell it.
      onSaved: (_) => context.go(AppRoutes.home),
      // The scanning flow's "import instead" is the import sheet, which is
      // where the gallery and file sources live.
      onImportInstead: () => _openImportSheet(
        context,
        importing,
        scanning,
        creation,
        dependencies,
      ),
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
        onShare: () => _openShareSheet(context, sharing, id),
        // Printing goes straight to the system dialogue rather than through the
        // sheet: the viewer's print control names the action exactly, and an
        // intermediate sheet asking "print?" would be a step with one option.
        onPrint: () => _print(context, sharing, id),
        onEdit: () => _openEditor(context, editing, id),
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
    search: (context) => BlocProvider(
      create: (_) => SearchBloc(library.search),
      child: SearchScreen(
        onOpenDocument: (id) => context.push(AppRoutes.documentDetail(id)),
        // Folders are loaded lazily by the screen's own filter in a later
        // step; an empty list simply means the filter offers "all folders".
        folders: const [],
      ),
    ),
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
/// Opens the PDF editor for [id].
///
/// A nested navigator route, like the imported-page review: the editor carries
/// selection state the router has no place holding, and it returns to the
/// viewer the user opened it from.
Future<void> _openEditor(
  BuildContext context,
  PdfEditingModule editing,
  DocumentId id,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (routeContext) => BlocProvider(
      create: (_) => PdfEditCubit(id, editing.useCases)..load(),
      child: Builder(
        builder: (screenContext) {
          final path = screenContext
              .watch<PdfEditCubit>()
              .state
              .document
              ?.filePath;

          return PdfEditScreen(
            // The real thumbnail is a rendered PDF page. Supplied here rather
            // than by the screen, because rendering is plugin-backed and a
            // screen that built its own could be neither previewed nor tested.
            thumbnailBuilder: (context, index) => path == null
                ? const ColoredBox(color: Color(0xFFE0E0E0))
                : PdfDocumentViewBuilder.file(
                    path,
                    builder: (context, document) => document == null
                        ? const ColoredBox(color: Color(0xFFE0E0E0))
                        : PdfPageView(
                            document: document,
                            pageNumber: index + 1,
                          ),
                  ),
            onClose: () => Navigator.of(routeContext).pop(),
          );
        },
      ),
    ),
  ),
);

/// Imports [paths] handed to DocForge by another application.
///
/// Goes straight to importing rather than showing the sources: the user already
/// chose what to send and where to send it, and asking them again would be a
/// question with one answer.
Future<void> _importShared(
  BuildContext context,
  List<String> paths,
  ImportModule importing,
  ScanningModule scanning,
  DocumentCreationModule creation,
  AppDependencies dependencies,
) async {
  final cubit = ImportCubit(
    importing.gallery,
    importing.files,
    importing.importFiles,
  );

  try {
    await cubit.fromShareSheet(paths);
    if (!context.mounted) return;

    final state = cubit.state;
    final bundle = state.bundle;

    if (bundle != null) {
      await _reviewImportedPages(
        context,
        bundle,
        scanning,
        creation,
        dependencies,
      );
    } else if (state.imported.isNotEmpty) {
      _report(context, state.outcomeMessage);
    } else if (state.message != null) {
      _report(context, state.message!);
    }
  } finally {
    await cubit.close();
  }
}

/// Opens the import sources as a modal bottom sheet.
///
/// Images that come back are handed to the scanning flow's *review* step rather
/// than saved directly, which is what makes cropping and enhancement available
/// to them — the requirement the gallery scenario states explicitly.
Future<void> _openImportSheet(
  BuildContext context,
  ImportModule importing,
  ScanningModule scanning,
  DocumentCreationModule creation,
  AppDependencies dependencies,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => ImportCubit(
        importing.gallery,
        importing.files,
        importing.importFiles,
      ),
      child: ImportOptionsSheet(
        onScan: () => Navigator.of(sheetContext).pop(),
        onOpenSettings: dependencies.permissions.openSettings,
        onReadyForReview: (bundle) {
          Navigator.of(sheetContext).pop();
          unawaited(
            _reviewImportedPages(
              context,
              bundle,
              scanning,
              creation,
              dependencies,
            ),
          );
        },
        onImported: (state) {
          Navigator.of(sheetContext).pop();
          _report(context, state.outcomeMessage);
        },
      ),
    ),
  );
}

/// Opens the scanning flow at its review step, over [bundle].
///
/// A nested navigator route rather than a top-level one: the flow is transient
/// and carries state the router has no place holding, which is the same reason
/// the crop screen is pushed this way.
Future<void> _reviewImportedPages(
  BuildContext context,
  ScannedPageBundle bundle,
  ScanningModule scanning,
  DocumentCreationModule creation,
  AppDependencies dependencies,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (routeContext) => ScanFlow(
      module: scanning,
      creation: creation,
      initialPages: bundle,
      onExit: () => Navigator.of(routeContext).pop(),
      onSaved: (_) => Navigator.of(routeContext).pop(),
      onImportInstead: () => Navigator.of(routeContext).pop(),
      onOpenSettings: dependencies.permissions.openSettings,
    ),
  ),
);

/// Opens the share options for [id] as a modal bottom sheet.
///
/// The document is read first so the sheet can say what it is about to share
/// and disable the text option when there is nothing to share — both of which
/// are decisions the sheet renders rather than makes.
Future<void> _openShareSheet(
  BuildContext context,
  SharingModule sharing,
  DocumentId id,
) async {
  final found = await sharing.documentReader.findById(id);
  if (!context.mounted) return;

  final document = found.valueOrNull;
  if (document == null) {
    _report(context, 'That document could not be opened.');
    return;
  }

  final text = await sharing.ocrTextSource.textForDocument(id);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => ShareCubit(
        id,
        sharing.sharePdf,
        sharing.shareImages,
        sharing.shareText,
        sharing.print,
        sharing.export,
        initial: ShareState.initial(
          title: document.title,
          pageCount: document.pageCount,
          canShareText: ShareRules.canShareText(
            document,
            text.valueOrNull ?? '',
          ),
        ),
      ),
      child: ShareOptionsSheet(
        // Dismissed once the system has the content: leaving the sheet up
        // behind the share sheet would leave the user looking at options for
        // something they have already sent.
        onDone: (state) {
          Navigator.of(sheetContext).pop();
          final confirmation = state.exportConfirmation;
          if (confirmation != null) _report(context, confirmation);
        },
      ),
    ),
  );
}

/// Prints [id], reporting a failure rather than swallowing it.
Future<void> _print(
  BuildContext context,
  SharingModule sharing,
  DocumentId id,
) async {
  final result = await sharing.print(id);
  if (!context.mounted) return;

  if (result case Failed(:final failure)) {
    _report(context, failure.presentation.message);
  }
}

/// Shows [message] in a snackbar.
void _report(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

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
