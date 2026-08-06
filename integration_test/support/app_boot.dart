/// Booting the real application for one flow.
///
/// A flow calls [bootDocScanly] and gets the application `main.dart` runs, with
/// only the platform edge substituted. It is deliberately *not* a second wiring
/// of the app: it calls [buildDocScanly], the same function `main` calls, so the
/// harness cannot drift from what a user actually launches. That drift is the
/// standard way an end-to-end suite rots into proving something nobody runs.
///
/// Each flow gets its own Isar database, its own library folder and its own
/// capture directory, all under a temporary directory that is deleted
/// afterwards. That is what lets flows run in any order and lets an agent run
/// one flow to check one fix (`design.md` D6).
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/app/app_dependencies.dart';
import 'package:doc_scanly/app/doc_scanly.dart';
import 'package:doc_scanly/app/fake_dependencies.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_scanly/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'fake_platform.dart';
import 'fixtures.dart';

/// One booted application, and everything a flow needs to reach around it.
///
/// A flow drives the application through the robots and asserts on what the
/// user can see. [platform] is the one exception: the share sheet, the print
/// dialogue and the biometric prompt are outside anything the framework can
/// drive, so they are asserted at the fake's boundary instead.
class FlowApp {
  /// Creates the handle.
  const FlowApp({
    required this.platform,
    required this.fixtures,
    required this.dependencies,
    required this.publicStore,
    required this.libraryFolder,
    required this.isar,
    this.iCloudPlatform,
    this.cloudLibraryFolder,
  });

  /// The substituted platform edges, for boundary assertions.
  final FakePlatform platform;

  /// The files this flow can feed the application.
  final Fixtures fixtures;

  /// The deterministic clock, ids and worker the application was built over.
  final AppDependencies dependencies;

  /// The user-visible library folder, for asserting a file genuinely landed.
  final PublicFileStore publicStore;

  /// Where [publicStore] writes, so a flow can look at real bytes on disk.
  final Directory libraryFolder;

  /// The flow's own database.
  final Isar isar;

  /// Deterministic iCloud edge used by an iOS cloud flow, when supplied.
  final ICloudPlatformApi? iCloudPlatform;

  /// App-owned iCloud Documents root used by the flow, when supplied.
  final Directory? cloudLibraryFolder;
}

/// Whether Isar's native library has been resolved for this process.
///
/// Isar resolves once per process and throws if asked twice, so the flag is
/// process-level rather than per-flow.
var _isarReady = false;

var _instanceCount = 0;

/// Boots the application for one flow and returns the running handle.
///
/// Pumps the application before returning, so a flow's first line acts on a
/// mounted tree rather than having to remember to pump first.
///
/// [onboardingComplete] defaults to true, which is what every flow except the
/// first-launch one wants: the guard redirects home → onboarding until the flag
/// is set, so a flow about the library would otherwise spend its first three
/// steps dismissing an introduction (`route_gates.dart`).
///
/// [appLockEnabled] seeds the lock the same way, for the flow that proves a
/// relaunch requires unlocking.
///
/// [galleryImages], [pickedFiles], [pendingSharedContent] and
/// [exportDestination] configure what the substituted pickers answer with; see
/// [buildFakePlatform]. [unlocksSuccessfully] decides what the biometric prompt
/// would have answered.
///
/// Registers its own teardown: the database is closed and the temporary
/// directory removed when the test ends, however it ends.
Future<FlowApp> bootDocScanly(
  WidgetTester tester, {
  bool onboardingComplete = true,
  bool appLockEnabled = false,
  bool unlocksSuccessfully = true,
  List<String> galleryImages = const [],
  List<String> pickedFiles = const [],
  List<String> pendingSharedContent = const [],
  String? exportDestination,
  Failure? shareFailure,
  Failure? exportFailure,
  ICloudPlatformApi? iCloudPlatform,
  bool? isIOS,
  StorageLocation? storageLocation,
  Directory? cloudRootDirectory,
  String? saveLocationDirectory,
}) async {
  if (!_isarReady) {
    await Isar.initializeIsarCore(download: true);
    _isarReady = true;
  }

  // One root per flow, deleted in teardown. Everything the flow writes — the
  // database, the library folder, captures, the working directory — lives under
  // it, so "clean up after yourself" is one deletion rather than six.
  final root = await Directory.systemTemp.createTemp('docscanly_flow_');
  final cacheDirectory = await Directory('${root.path}/cache').create();
  final libraryFolder = await Directory('${root.path}/library').create();
  final derivedDirectory = await Directory('${root.path}/derived').create();
  final databaseDirectory = await Directory('${root.path}/db').create();
  final fixtureDirectory = await Directory('${root.path}/fixtures').create();
  Directory? cloudLibraryFolder;
  if (iCloudPlatform != null) {
    cloudLibraryFolder =
        cloudRootDirectory ??
        await Directory(
          '${root.path}/icloud/Documents',
        ).create(recursive: true);
    await cloudLibraryFolder.create(recursive: true);
    if (iCloudPlatform is ScriptedICloudPlatform) {
      iCloudPlatform.rootPath = cloudLibraryFolder.path;
    }
  }

  // A distinct instance name per flow: a previous flow's database may still be
  // closing when this one opens, and Isar will not reuse a name until it has.
  _instanceCount++;
  final isar = await Isar.open(
    [
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      TrashEntitySchema,
      OcrTextEntitySchema,
    ],
    directory: databaseDirectory.path,
    name: 'docscanly_flow_$_instanceCount',
  );

  // Deterministic by construction: a fixed clock, sequential ids and an inline
  // worker, so no flow depends on wall-clock time or on isolate scheduling
  // order (`design.md` D2).
  final dependencies = buildFakeAppDependencies();

  // Seeded before the application is built, because both gates are read once
  // before the first frame and the router's redirect is synchronous.
  await dependencies.preferences.writeBool(
    PreferenceKeys.onboardingComplete,
    onboardingComplete,
  );
  if (appLockEnabled) {
    await dependencies.secureStorage.write(
      SecureStorageKeys.appLockEnabled,
      'true',
    );
  }
  if (storageLocation != null) {
    await dependencies.preferences.writeString(
      PreferenceKeys.libraryStorageLocation,
      storageLocation.id,
    );
  }

  final fixtures = Fixtures(fixtureDirectory);

  // Materialised before the platform is built, because the substituted camera
  // writes these bytes on every capture and the composer downstream has to be
  // able to decode them.
  final captureImage = await File(await fixtures.pageOne()).readAsBytes();

  final platform = buildFakePlatform(
    captureDirectory: cacheDirectory,
    captureImageBytes: captureImage,
    galleryImages: galleryImages,
    pickedFiles: pickedFiles,
    pendingSharedContent: pendingSharedContent,
    exportDestination: exportDestination,
    shareFailure: shareFailure,
    exportFailure: exportFailure,
    unlocksSuccessfully: unlocksSuccessfully,
  );

  // A real filesystem store over a directory the flow owns, rather than the
  // device's actual library folder: the flow gets genuine file behaviour
  // without writing into somewhere a user would see.
  final startsInICloud =
      storageLocation == StorageLocation.iCloud ||
      (storageLocation == null &&
          iCloudPlatform is ScriptedICloudPlatform &&
          iCloudPlatform.marker != null);
  final activeLibraryFolder = startsInICloud
      ? cloudLibraryFolder!
      : libraryFolder;
  final publicStore = FilesystemPublicFileStore.atRoot(activeLibraryFolder);

  final app = await buildDocScanly(
    dependencies: dependencies,
    cacheDirectory: cacheDirectory,
    documentsDirectory: libraryFolder,
    publicStore: startsInICloud ? null : publicStore,
    libraryOverride: LibraryOverride(
      isar: isar,
      documentsDirectory: derivedDirectory,
    ),
    scanner: platform.scanner,
    detector: platform.detector,
    authenticator: platform.authenticator,
    recogniser: platform.recogniser,
    share: platform.share,
    printer: platform.printer,
    exportPicker: platform.exportPicker,
    gallery: platform.gallery,
    files: platform.files,
    sharedContent: platform.sharedContent,
    iCloudPlatform: iCloudPlatform,
    isIOS: isIOS,
    pickSaveLocation: () async => saveLocationDirectory,
  );

  addTearDown(() async {
    // Not awaited: a screen the flow left mounted can have a library query in
    // flight, and `close` waits for it. Each flow owns its own instance and
    // directory, so one closing a moment late affects nothing.
    unawaited(isar.close());
    if (root.existsSync()) {
      try {
        root.deleteSync(recursive: true);
      } on FileSystemException {
        // The database file may still be held while the instance closes. The
        // directory is under the system temp root, which the operating system
        // sweeps; failing teardown over it would turn a passing flow red.
      }
    }
  });

  await tester.pumpWidget(app);
  await tester.pump();

  return FlowApp(
    platform: platform,
    fixtures: fixtures,
    dependencies: dependencies,
    publicStore: publicStore,
    libraryFolder: activeLibraryFolder,
    isar: isar,
    iCloudPlatform: iCloudPlatform,
    cloudLibraryFolder: cloudLibraryFolder,
  );
}
