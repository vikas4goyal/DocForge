/// Builds the running application.
///
/// This is the composition root proper: it resolves the platform primitives,
/// constructs every module in dependency order, assembles the screens, builds
/// the router over them and returns the configured root widget. `main.dart`
/// does nothing but run what this returns.
///
/// It is public and fully parameterised so the end-to-end suite boots *this*
/// application rather than a second wiring of its own that would drift from it.
/// Every parameter defaults to the production implementation, so a caller that
/// passes nothing gets exactly what a user gets, and a test passes only the
/// platform edges it has to replace.
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_forge/app/app.dart';
import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/app/composition_root.dart';
import 'package:doc_forge/app/creation_module.dart';
import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/app/import_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/page_render_job.dart';
import 'package:doc_forge/app/pdf_editing_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/app/scanning_module.dart';
import 'package:doc_forge/app/screens/home_refresh.dart';
import 'package:doc_forge/app/screens/app_screens_builder.dart';
import 'package:doc_forge/app/settings_module.dart';
import 'package:doc_forge/app/sharing_module.dart';
import 'package:doc_forge/core/storage/capture_staging.dart';
import 'package:doc_forge/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';
import 'package:doc_forge/core/storage/public_storage/public_storage_factory.dart';
import 'package:doc_forge/core/theme/theme_mode_controller.dart';
import 'package:doc_forge/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_forge/features/app_security/domain/repositories/app_lock_repository.dart';
import 'package:doc_forge/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:doc_forge/features/app_security/presentation/security_keys.dart';
import 'package:doc_forge/features/app_security/presentation/widgets/app_lock_observer.dart';
import 'package:doc_forge/features/app_settings/domain/app_settings.dart';
import 'package:doc_forge/features/document_creation/application/usecases/add_page.dart';
import 'package:doc_forge/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_forge/features/document_creation/domain/creation_session.dart';
import 'package:doc_forge/features/document_import/domain/repositories/import_repository.dart';
import 'package:doc_forge/features/document_import/infrastructure/repositories/platform_import_sources.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/library_reconciler.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/opencv_edge_detector.dart';
import 'package:doc_forge/features/document_sharing/domain/repositories/share_repository.dart';
import 'package:doc_forge/features/document_sharing/infrastructure/repositories/platform_share_repositories.dart';
import 'package:doc_forge/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_forge/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_forge/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_forge/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/pdf_manipulator_editor.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

/// An already-open library database and the directory its derived files live in.
///
/// Supplied by an end-to-end flow so the run works against a temporary database
/// it owns and deletes, rather than the device's real library. Production
/// leaves it null, and the library opens Isar itself under Application Support
/// (`design.md` D4).
class LibraryOverride {
  /// Creates an override over an [isar] the caller opened and will close.
  const LibraryOverride({required this.isar, required this.documentsDirectory});

  /// The open database the library reads and writes.
  final Isar isar;

  /// Where derived files — thumbnails, not the PDFs themselves — are written.
  final Directory documentsDirectory;
}

/// The version shown on the About screen.
///
/// A constant rather than a `package_info_plus` lookup: the value is baked into
/// the build, and reading it asynchronously would make About the one screen
/// that has a loading state.
const appVersion = '1.0.0';

/// Builds the application and returns its root widget.
///
/// Awaits everything that must be resolved before the first frame — the
/// dependency graph, the platform directories, the library database, the stored
/// settings and both route gates — so the router's synchronous redirect has an
/// answer immediately and the first frame is already correct.
///
/// The platform edges below are parameters because each one binds something the
/// host test VM does not have. Each defaults to the production implementation,
/// so production behaviour is unchanged by their presence:
///
/// - [dependencies] — the cross-cutting graph. Defaults to
///   [buildAppDependencies]; a flow passes `buildFakeAppDependencies` for its
///   fixed clock, sequential ids and inline worker.
/// - [cacheDirectory] and [documentsDirectory] — resolved through
///   `path_provider` by default.
/// - [publicStore] — the user-visible library folder. Defaults to
///   [buildPublicFileStore], which is the one place that branches on the
///   operating system.
/// - [libraryOverride] — a temporary database, per [LibraryOverride].
/// - [scanner] and [detector] — the camera and OpenCV edge detection.
/// - [authenticator] — biometrics.
/// - [pdfRenderer] — pdfrx, which binds a native library.
/// - [pdfEditor] — one instance shared by generation and editing, so encryption
///   has one implementation rather than two that can drift.
/// - [recogniser] — ML Kit text recognition.
/// - [share], [printer] and [exportPicker] — the system share sheet, print
///   dialogue and destination picker.
/// - [gallery], [files] and [sharedContent] — the system pickers and the
///   channel other applications share into DocForge through.
///
/// [initialLocation] is where the router starts; the guard still redirects from
/// it, so a flow that wants the dashboard asks for [AppRoutes.home] and lets the
/// gates decide.
Future<Widget> buildDocForge({
  AppDependencies? dependencies,
  Directory? cacheDirectory,
  Directory? documentsDirectory,
  PublicFileStore? publicStore,
  LibraryOverride? libraryOverride,
  ScannerRepository? scanner,
  EdgeDetector detector = const OpenCvEdgeDetector(),
  DeviceAuthenticator authenticator = const LocalAuthAuthenticator(),
  PdfRenderer pdfRenderer = const PdfrxRenderer(),
  PdfEditorRepository? pdfEditor,
  OcrRepository? recogniser,
  ShareRepository share = const SystemShareRepository(),
  PrintRepository printer = const SystemPrintRepository(),
  ExportDestinationPicker exportPicker = const SystemExportDestinationPicker(),
  GalleryPicker gallery = const SystemGalleryPicker(),
  FileBrowser files = const SystemFileBrowser(),
  SharedContentSource? sharedContent,
  String initialLocation = AppRoutes.home,
}) async {
  // Awaited together rather than one after another: none needs the other, and
  // everything here happens before the first frame, so each avoidable round
  // trip is time the user spends looking at a blank screen. A supplied value
  // short-circuits its lookup, because a test has no plugin to answer it.
  final (resolvedDependencies, resolvedCache, resolvedDocuments) = await (
    dependencies == null
        ? buildAppDependencies()
        : Future<AppDependencies>.value(dependencies),
    cacheDirectory == null
        ? getApplicationCacheDirectory()
        : Future<Directory>.value(cacheDirectory),
    documentsDirectory == null
        ? getApplicationDocumentsDirectory()
        : Future<Directory>.value(documentsDirectory),
  ).wait;

  // The user-visible library folder, and the only place a finished PDF is
  // written. Built before anything else that touches documents, because every
  // one of them addresses files through it (`design.md` D2).
  final store =
      publicStore ??
      buildPublicFileStore(
        documentsDirectory: resolvedDocuments,
        cacheDirectory: resolvedCache,
      );
  await store.initialise();

  // Private scratch space for half-built PDFs. Never the library folder: a
  // partial file there would be visible in the user's file browser.
  final workingDirectory = Directory('${resolvedCache.path}/working')
    ..createSync(recursive: true);

  final documentFiles = PublicStoreDocumentFileResolver(store);

  // One renderer for the whole application: everything that shows a page goes
  // through it, so the row thumbnail, the crop screen and the generated PDF
  // cannot disagree about what the user's edits amount to.
  final renderPage = RenderPage(
    cacheDirectory: resolvedCache,
    sizeOf: readImageSize,
    render: (plan, {required destinationPath, transform}) => renderPageJob(
      resolvedDependencies.worker,
      plan,
      destinationPath: destinationPath,
      transform: transform,
    ),
  );

  final scanning = buildScanningModule(
    directory: resolvedCache,
    renderPage: renderPage,
    permissions: resolvedDependencies.permissions,
    ids: resolvedDependencies.idGenerator,
    worker: resolvedDependencies.worker,
    detector: detector,
    scanner: scanner,
  );

  // Reconciliation needs to know how many pages a file it has never seen
  // holds. The renderer is the only thing that knows, and handing over the one
  // method keeps the library from depending on the viewer.
  final pageCountOf = RendererPdfInspector(pdfRenderer).pageCountOf;

  final library = libraryOverride == null
      ? await buildLibraryModule(
          store: store,
          preferences: resolvedDependencies.preferences,
          pageCountOf: pageCountOf,
          clock: resolvedDependencies.clock,
          ids: resolvedDependencies.idGenerator,
          secureStorage: resolvedDependencies.secureStorage,
        )
      : buildLibraryModuleOver(
          isar: libraryOverride.isar,
          documentsDirectory: libraryOverride.documentsDirectory,
          store: store,
          preferences: resolvedDependencies.preferences,
          pageCountOf: pageCountOf,
          clock: resolvedDependencies.clock,
          ids: resolvedDependencies.idGenerator,
          secureStorage: resolvedDependencies.secureStorage,
        );

  final settings = buildSettingsModule(
    preferences: resolvedDependencies.preferences,
    storageReader: library.storageSummaryReader,
    clock: resolvedDependencies.clock,
    // Read from secure storage, never preferences: an unprotected file can be
    // edited on a rooted device.
    isAppLockEnabled: () => IsAppLockEnabled(
      SecureAppLockConfiguration(resolvedDependencies.secureStorage),
    )(),
  );

  // Read once at startup and kept current by the settings screen. The features
  // that consume a setting — naming, quality — read it through this holder
  // rather than hitting preferences on every save, which would put a disk read
  // in the middle of document creation.
  final currentSettings = ValueNotifier<AppSettings>(await settings.load());

  // Seeded from the stored choice so the very first frame is already in the
  // right theme; a default-then-correct sequence would flash light before dark.
  final themeMode = ThemeModeController(
    themeModeFor(currentSettings.value.theme),
  );

  // One editor instance, shared: generation protects through it and the editing
  // feature manipulates through it, so encryption has one implementation rather
  // than two that can drift.
  final editor = pdfEditor ?? PdfManipulatorEditor();

  final creation = buildDocumentCreationModule(
    // Protecting a generated PDF reuses the editor that already does it, so
    // there is one implementation of encryption rather than two.
    protectPdf: (sourcePath, password) async {
      final destination = '$sourcePath.protected';
      final result = await editor.protect(
        sourcePath,
        destination,
        password: password,
      );
      return result.map((_) => destination);
    },
    isar: library.isar,
    workingDirectory: workingDirectory,
    publicStore: store,
    clock: resolvedDependencies.clock,
    ids: resolvedDependencies.idGenerator,
    documentReader: library.documentReader,
    documentWriter: library.documentWriter,
    namingPattern: () => currentSettings.value.namingPattern,
    // Shared with the scanning module so a page enhanced on screen and a page
    // enhanced while saving go through exactly the same code.
    applyEnhancement: scanning.applyEnhancement,
    recogniser: recogniser,
  );

  final importing = buildImportModule(
    renderer: pdfRenderer,
    documentWriter: library.documentWriter,
    store: store,
    cacheDirectory: resolvedCache,
    clock: resolvedDependencies.clock,
    ids: resolvedDependencies.idGenerator,
    worker: resolvedDependencies.worker,
    gallery: gallery,
    files: files,
    shared: sharedContent,
  );

  // The creation flow: one page table, and the loop that fills it.
  final staging = CaptureStaging(resolvedCache);
  final creationFlow = CreationModule(
    staging: staging,
    renderPage: renderPage,
    addFromCamera: AddPageFromCamera(() async {
      final captured = await scanning.capturePage();
      return captured.map((page) => page.imagePath);
    }, StagePageImage(staging, resolvedDependencies.idGenerator)),
    addFromGallery: AddPagesFromGallery(
      importing.gallery.pickImages,
      StagePageImage(staging, resolvedDependencies.idGenerator),
    ),
    discardSession: DiscardCreationSession(staging),
    scanning: scanning,
    save: (pages, {required title, required folders, password, folderId}) =>
        creation.saveDocument(
          CreationSession.toBundle(pages),
          title: title,
          folders: folders,
          folderId: folderId,
        ),
    suggestName: () =>
        creation.generateName(currentSettings.value.namingPattern),
    store: store,
  );

  final editing = buildPdfEditingModule(
    editor: editor,
    documentReader: library.documentReader,
    documentWriter: library.documentWriter,
    secureStorage: resolvedDependencies.secureStorage,
    store: store,
    workingDirectory: workingDirectory,
    clock: resolvedDependencies.clock,
    ids: resolvedDependencies.idGenerator,
  );

  final sharing = buildSharingModule(
    documentReader: library.documentReader,
    ocrTextSource: creation.ocrTextSource,
    documentFiles: documentFiles,
    cacheDirectory: resolvedCache,
    worker: resolvedDependencies.worker,
    share: share,
    printer: printer,
    picker: exportPicker,
  );

  // Onboarding owns its own gate. The flag is read once here, before the first
  // frame, so the router's synchronous redirect has an answer immediately —
  // otherwise a first-time user would see Home flash before onboarding.
  final onboardingRepository = OnboardingRepositoryImpl(
    resolvedDependencies.preferences,
  );
  final onboardingGate = OnboardingGateImpl(
    IsOnboardingComplete(onboardingRepository).call,
  );

  // Read before the first frame, exactly like the onboarding gate: the router's
  // redirect is synchronous, and a gate that had to guess would show a document
  // list for a frame behind an enabled lock.
  final lockConfiguration = SecureAppLockConfiguration(
    resolvedDependencies.secureStorage,
  );
  final isLockEnabled = IsAppLockEnabled(lockConfiguration);
  final lockGate = AppLockGateImpl(isLockEnabled);

  // One reads preferences, the other secure storage, and neither needs the
  // other's answer — so they load concurrently. Both are still resolved before
  // the router is built, which is what the redirects depend on.
  await (onboardingGate.load(), lockGate.load()).wait;

  // Owned here rather than declared as a global, because the project bars
  // global mutable state: the router publishes route changes through it and
  // Home subscribes, so both have to be handed the same instance.
  final routeObserver = HomeRefreshObserver();

  final router = createAppRouter(
    guard: RouteGuard(lockGate: lockGate, onboardingGate: onboardingGate),
    // Without this the user would sit on the unlock screen after authenticating,
    // because GoRouter re-evaluates its redirect only when told to.
    refreshListenable: AppLockListenable(lockGate),
    initialLocation: initialLocation,
    observers: [routeObserver],
    screens: buildAppScreens(
      library: library,
      creation: creation,
      creationFlow: creationFlow,
      importing: importing,
      sharing: sharing,
      editing: editing,
      settings: settings,
      permissions: resolvedDependencies.permissions,
      secureStorage: resolvedDependencies.secureStorage,
      documentFiles: documentFiles,
      currentSettings: currentSettings,
      themeMode: themeMode,
      appVersion: appVersion,
      lockGate: lockGate,
      lockConfiguration: lockConfiguration,
      onboardingRepository: onboardingRepository,
      onboardingGate: onboardingGate,
      authenticator: authenticator,
      pdfRenderer: pdfRenderer,
      routeObserver: routeObserver,
    ),
  );

  // Anything left by a run that was killed mid-session. Swept before the first
  // frame so a crash during creation does not leave full-resolution captures
  // occupying space the user cannot account for.
  unawaited(CaptureStaging(resolvedCache).sweepOrphans());

  // Wrapped outside the app, so the re-lock happens whatever route the user was
  // on when the phone went into a pocket.
  return AppLockObserver(
    key: SecurityKeys.appLockObserver,
    gate: lockGate,
    child: LibraryReconciler(
      key: LibraryKeys.libraryReconciler,
      // The library folder is visible in the user's file browser, so it can
      // change while DocForge is in the background. Reconciling on resume is
      // what makes that change appear when they come back.
      reconcile: library.reconcile.call,
      child: DocForgeApp(
        dependencies: resolvedDependencies,
        router: router,
        themeMode: themeMode,
      ),
    ),
  );
}
