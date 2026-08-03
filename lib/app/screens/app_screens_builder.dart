/// Assembles the application's screen set from the per-feature builders.
///
/// [createAppRouter] takes its screens as an argument so the router depends on
/// no feature; this is where those screens are actually built. It is public and
/// callable on its own so a test can construct the real screen set without
/// booting the whole application, and so the end-to-end suite drives exactly
/// the screens `main.dart` does rather than a second set that can drift.
library;

import 'package:doc_forge/app/creation_module.dart';
import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/app/import_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/pdf_editing_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/screens/creation_screens.dart';
import 'package:doc_forge/app/screens/home_refresh.dart';
import 'package:doc_forge/app/screens/library_screens.dart';
import 'package:doc_forge/app/screens/search_screens.dart';
import 'package:doc_forge/app/screens/security_screens.dart';
import 'package:doc_forge/app/screens/settings_screens.dart';
import 'package:doc_forge/app/screens/shell_screens.dart';
import 'package:doc_forge/app/screens/viewer_screens.dart';
import 'package:doc_forge/app/settings_module.dart';
import 'package:doc_forge/app/sharing_module.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_forge/core/theme/theme_mode_controller.dart';
import 'package:doc_forge/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_forge/features/app_security/domain/repositories/app_lock_repository.dart';
import 'package:doc_forge/features/app_settings/domain/app_settings.dart';
import 'package:doc_forge/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:flutter/material.dart';

/// Builds every screen the router renders.
///
/// The modules are passed whole rather than unpacked into their use cases: each
/// feature's builder needs a different subset of the same handful, and listing
/// them individually is what made the private predecessor of this function take
/// seventeen positional parameters that no caller outside `main` could supply.
///
/// Parameters that are not modules:
///
/// - [permissions] backs onboarding's camera request, the unlock screen's and
///   the import sheet's "open settings" escape hatches.
/// - [secureStorage] holds remembered document passwords — secure storage
///   rather than preferences, because an unprotected file can be edited on a
///   rooted device.
/// - [documentFiles] resolves a document to the file its bytes live in.
/// - [currentSettings] is the live copy of the persisted settings; the settings
///   screen writes it so document creation reads what is on screen rather than
///   what was loaded at startup.
/// - [themeMode] is published to so an explicit theme choice applies without a
///   restart.
/// - [appVersion] is shown on About.
/// - [lockGate] and [onboardingGate] are the in-memory answers the router's
///   synchronous redirect reads; the screens mark them satisfied.
/// - [lockConfiguration] stores whether the lock is on, and
///   [onboardingRepository] whether onboarding is done.
/// - [authenticator] confirms who is asking before the lock is toggled or
///   released. A parameter because biometrics are a platform edge with no
///   host-VM implementation.
/// - [pdfRenderer] opens a document in the viewer. A parameter for the same
///   reason: pdfrx binds a native library the host test VM does not have.
/// - [routeObserver] must be the one the router was built with. Home subscribes
///   to it so it reloads when a route pushed over it pops, which is the only
///   thing that makes a saved or imported document appear.
AppScreens buildAppScreens({
  required LibraryModule library,
  required DocumentCreationModule creation,
  required CreationModule creationFlow,
  required ImportModule importing,
  required SharingModule sharing,
  required PdfEditingModule editing,
  required SettingsModule settings,
  required PermissionService permissions,
  required SecureStore secureStorage,
  required DocumentFileResolver documentFiles,
  required ValueNotifier<AppSettings> currentSettings,
  required ThemeModeController themeMode,
  required String appVersion,
  required AppLockGateImpl lockGate,
  required AppLockConfiguration lockConfiguration,
  required OnboardingRepositoryImpl onboardingRepository,
  required OnboardingGateImpl onboardingGate,
  required DeviceAuthenticator authenticator,
  required PdfRenderer pdfRenderer,
  required HomeRefreshObserver routeObserver,
}) {
  final securityScreens = buildSecurityScreens(
    permissions: permissions,
    onboardingRepository: onboardingRepository,
    onboardingGate: onboardingGate,
    lockConfiguration: lockConfiguration,
    lockGate: lockGate,
    authenticator: authenticator,
  );

  final libraryScreens = buildLibraryScreens(library: library);

  final settingsScreens = buildSettingsScreens(
    settings: settings,
    currentSettings: currentSettings,
    themeMode: themeMode,
    appVersion: appVersion,
    lockConfiguration: lockConfiguration,
    authenticator: authenticator,
  );

  final viewerScreens = buildViewerScreens(
    library: library,
    creation: creation,
    sharing: sharing,
    editing: editing,
    documentFiles: documentFiles,
    secureStorage: secureStorage,
    renderer: pdfRenderer,
  );

  return AppScreens(
    onboarding: securityScreens.onboarding,
    unlock: securityScreens.unlock,
    // Home is built last of the groups it depends on: the settings tab is the
    // settings screen itself, not a second copy of it.
    home: buildHomeScreen(
      library: library,
      importing: importing,
      creationFlow: creationFlow,
      permissions: permissions,
      settings: settingsScreens.settings,
      routeObserver: routeObserver,
    ),
    scan: buildCreationScreen(creationFlow: creationFlow),
    documents: libraryScreens.documents,
    documentDetail: libraryScreens.documentDetail,
    viewer: viewerScreens.viewer,
    documentEdit: viewerScreens.documentEdit,
    folders: libraryScreens.folders,
    folderDetail: libraryScreens.folderDetail,
    search: buildSearchScreen(library: library),
    favourites: libraryScreens.favourites,
    archive: libraryScreens.archive,
    trash: libraryScreens.trash,
    settings: settingsScreens.settings,
    about: settingsScreens.about,
    privacy: settingsScreens.privacy,
  );
}
