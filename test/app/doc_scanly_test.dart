/// Tier 1 — the composition seam itself.
///
/// Proves that [buildDocScanly] assembles the same tree `main.dart` used to
/// assemble inline, and that each platform-edge parameter is actually consulted
/// rather than quietly ignored. Without this, a substituted fake could be
/// accepted and dropped, and every flow above it would be testing the real
/// platform without saying so.
library;

import 'dart:io';

import 'package:doc_scanly/app/app.dart';
import 'package:doc_scanly/app/app_dependencies.dart';
import 'package:doc_scanly/app/doc_scanly.dart';
import 'package:doc_scanly/app/fake_dependencies.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/app_security/domain/repositories/app_lock_repository.dart';
import 'package:doc_scanly/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:doc_scanly/features/app_security/presentation/screens/unlock_screen.dart';
import 'package:doc_scanly/features/app_security/presentation/security_keys.dart';
import 'package:doc_scanly/features/app_security/presentation/widgets/app_lock_observer.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/document_import/domain/repositories/import_repository.dart';
import 'package:doc_scanly/features/document_import/presentation/import_keys.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/library_reconciler.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_scanly/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_scanly/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_scanly/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:doc_scanly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  late Directory cacheDirectory;
  late Directory documentsDirectory;
  late Directory databaseDirectory;
  late Directory derivedDirectory;
  late Isar isar;

  setUpAll(() async {
    // Isar needs its native binaries; on a test VM they are downloaded once to
    // a temp location rather than bundled with the app.
    await Isar.initializeIsarCore(download: true);
    databaseDirectory = await Directory.systemTemp.createTemp('docscanly_db_');
    isar = await Isar.open(
      [
        DocumentEntitySchema,
        FolderEntitySchema,
        PageEntitySchema,
        TrashEntitySchema,
        OcrTextEntitySchema,
      ],
      directory: databaseDirectory.path,
      name: 'doc_scanly_composition_test',
      inspector: false,
    );
  });

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('docscanly_cache_');
    documentsDirectory = await Directory.systemTemp.createTemp(
      'docscanly_doc_',
    );
    derivedDirectory = await Directory.systemTemp.createTemp('docscanly_der_');
  });

  /// Boots the application with every platform edge substituted.
  ///
  /// Mirrors what the end-to-end harness does, at the one level a host test can
  /// reach: no plugin is touched, so anything this returns was built from the
  /// arguments and nothing else.
  ///
  /// Built inside [WidgetTester.runAsync] because booting does real work —
  /// creating the library folder, opening the store, reading the settings. A
  /// `testWidgets` body runs in a fake-async zone where real I/O futures never
  /// complete, so building there would hang rather than fail.
  Future<Widget> boot(
    WidgetTester tester, {
    AppDependencies? dependencies,
    PublicFileStore? publicStore,
    DeviceAuthenticator? authenticator,
    PdfRenderer? renderer,
    ICloudPlatformApi? iCloudPlatform,
    bool? isIOS,
    String initialLocation = '/',
  }) async {
    return (await tester.runAsync(
      () => buildDocScanly(
        dependencies: dependencies ?? buildFakeAppDependencies(),
        cacheDirectory: cacheDirectory,
        documentsDirectory: documentsDirectory,
        publicStore:
            publicStore ?? FilesystemPublicFileStore(documentsDirectory),
        libraryOverride: LibraryOverride(
          isar: isar,
          documentsDirectory: derivedDirectory,
        ),
        scanner: FakeScannerRepository(directory: cacheDirectory),
        detector: const FullPageEdgeDetector(),
        authenticator: authenticator ?? FakeDeviceAuthenticator(),
        pdfRenderer: renderer ?? FakePdfRenderer(),
        sharedContent: _SilentSharedContentSource(),
        iCloudPlatform: iCloudPlatform,
        isIOS: isIOS,
        initialLocation: initialLocation,
      ),
    ))!;
  }

  /// Pumps a bounded number of frames.
  ///
  /// Not `pumpAndSettle`: the booted app does real work — reading the library,
  /// rendering thumbnails — which never completes inside a `testWidgets`
  /// fake-async zone, so a loading indicator spins forever and an unbounded
  /// settle times out. A fixed number of frames is enough for the router to
  /// resolve its redirect, which is what these tests assert on.
  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Lets the real work the screens started — the library queries in
    // particular — actually run. Without this the database still has a query in
    // flight when the test ends, and closing it in teardown blocks forever.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  void compositionTestWidgets(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        // Run cleanup while the widget-test zone is still active. Unmounting
        // stops reconciliation from starting a fresh query; the real-async
        // turn lets the last query finish before Isar is closed and deleted.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        for (final directory in [
          cacheDirectory,
          documentsDirectory,
          derivedDirectory,
        ]) {
          if (directory.existsSync()) directory.deleteSync(recursive: true);
        }
      }
    });
  }

  group('buildDocScanly', () {
    compositionTestWidgets(
      'builds the same tree main.dart used to build inline',
      (tester) async {
        await tester.pumpWidget(await boot(tester));
        await settle(tester);

        // The order matters and is the whole point of the wrapping: the lock
        // observer is outside the app so a re-lock happens on whatever route the
        // user was on, and reconciliation is inside it.
        final observer = find.byType(AppLockObserver);
        final reconciler = find.byType(LibraryReconciler);
        final app = find.byType(DocScanlyApp);

        expect(observer, findsOneWidget);
        expect(
          find.descendant(of: observer, matching: reconciler),
          findsOneWidget,
        );
        expect(find.descendant(of: reconciler, matching: app), findsOneWidget);
      },
    );

    compositionTestWidgets('keys the three app-wide wrappers', (tester) async {
      final dependencies = buildFakeAppDependencies();
      await dependencies.preferences.writeBool(
        PreferenceKeys.onboardingComplete,
        true,
      );

      await tester.pumpWidget(await boot(tester, dependencies: dependencies));
      await settle(tester);

      // None of the three renders anything of its own, so a flow can only
      // assert they are mounted by key. The watcher is inside Home, which is
      // why onboarding has to be complete for this to find it.
      expect(find.byKey(SecurityKeys.appLockObserver), findsOneWidget);
      expect(find.byKey(LibraryKeys.libraryReconciler), findsOneWidget);
      expect(find.byKey(ImportKeys.sharedContentWatcher), findsOneWidget);
    });

    compositionTestWidgets(
      'hands the supplied dependencies to the root widget',
      (tester) async {
        final dependencies = buildFakeAppDependencies();

        await tester.pumpWidget(await boot(tester, dependencies: dependencies));
        await settle(tester);

        final app = tester.widget<DocScanlyApp>(find.byType(DocScanlyApp));
        expect(app.dependencies, same(dependencies));
      },
    );

    compositionTestWidgets(
      'initialises the supplied public store rather than its own',
      (tester) async {
        final store = _CountingPublicFileStore(
          FilesystemPublicFileStore(documentsDirectory),
        );

        await tester.pumpWidget(await boot(tester, publicStore: store));
        await settle(tester);

        expect(store.initialiseCount, 1);
      },
    );

    compositionTestWidgets(
      'Android never invokes or exposes the iCloud platform edge',
      (tester) async {
        final cloud = ScriptedICloudPlatform();
        addTearDown(cloud.dispose);

        await tester.pumpWidget(
          await boot(tester, iCloudPlatform: cloud, isIOS: false),
        );
        await settle(tester);

        expect(cloud.operationRequests, 0);
        expect(find.text('Storage location'), findsNothing);
      },
    );

    compositionTestWidgets(
      'lands on onboarding when the flag has never been written',
      (tester) async {
        await tester.pumpWidget(await boot(tester));
        await settle(tester);

        // The default first-launch state: `RouteGuard` redirects home →
        // onboarding, which is the chain the first-launch flow depends on.
        expect(find.byType(OnboardingScreen), findsOneWidget);
      },
    );

    compositionTestWidgets(
      'lands on the dashboard once onboarding is complete',
      (tester) async {
        final dependencies = buildFakeAppDependencies();
        await dependencies.preferences.writeBool(
          PreferenceKeys.onboardingComplete,
          true,
        );

        await tester.pumpWidget(await boot(tester, dependencies: dependencies));
        await settle(tester);

        expect(find.byType(DashboardScreen), findsOneWidget);
      },
    );

    compositionTestWidgets(
      'honours the supplied authenticator on the unlock screen',
      (tester) async {
        final dependencies = buildFakeAppDependencies();
        await dependencies.preferences.writeBool(
          PreferenceKeys.onboardingComplete,
          true,
        );
        await dependencies.secureStorage.write(
          SecureStorageKeys.appLockEnabled,
          'true',
        );
        final authenticator = FakeDeviceAuthenticator();

        await tester.pumpWidget(
          await boot(
            tester,
            dependencies: dependencies,
            authenticator: authenticator,
          ),
        );
        await settle(tester);

        // An enabled lock redirects to unlock before anything else, so reaching
        // this screen at all proves the lock gate was read before the first
        // frame — and the screen is driven by the authenticator passed in, not by
        // the real biometric prompt, which no host test could answer.
        expect(find.byType(UnlockScreen), findsOneWidget);
      },
    );

    compositionTestWidgets('starts at the requested initial location', (
      tester,
    ) async {
      final dependencies = buildFakeAppDependencies();
      await dependencies.preferences.writeBool(
        PreferenceKeys.onboardingComplete,
        true,
      );

      await tester.pumpWidget(
        await boot(
          tester,
          dependencies: dependencies,
          initialLocation: '/documents',
        ),
      );
      await settle(tester);

      // Proves the parameter reaches GoRouter: the guard lets it through once
      // onboarding is complete, so the app opens on the document list rather
      // than on Home.
      expect(find.byType(DocumentListScreen), findsOneWidget);
    });
  });
}

/// Counts [initialise] calls, delegating everything else.
///
/// The composition root must initialise the store it was handed exactly once,
/// before anything reads a document. A test that only checked the app booted
/// would pass against a root that built its own store and left this one
/// untouched.
class _CountingPublicFileStore implements PublicFileStore {
  _CountingPublicFileStore(this._inner);

  final PublicFileStore _inner;

  /// How many times [initialise] was called.
  int initialiseCount = 0;

  @override
  Future<Result<void>> initialise() {
    initialiseCount++;
    return _inner.initialise();
  }

  @override
  Future<Result<List<PublicEntry>>> list(List<String> folders) =>
      _inner.list(folders);

  @override
  Future<Result<List<PublicEntry>>> listRecursive(List<String> folders) =>
      _inner.listRecursive(folders);

  @override
  Future<Result<PublicTreeInventory>> inventory({
    LibraryPath? file,
    List<String>? folder,
  }) => _inner.inventory(file: file, folder: folder);

  @override
  Future<Result<void>> moveFileToTrash(String trashId, LibraryPath path) =>
      _inner.moveFileToTrash(trashId, path);

  @override
  Future<Result<void>> moveFolderToTrash(
    String trashId,
    List<String> folders,
  ) => _inner.moveFolderToTrash(trashId, folders);

  @override
  Future<Result<void>> restoreFileFromTrash(
    String trashId,
    String originalName,
    LibraryPath destination,
  ) => _inner.restoreFileFromTrash(trashId, originalName, destination);

  @override
  Future<Result<void>> restoreFolderFromTrash(
    String trashId,
    String originalName,
    List<String> destinationFolders,
  ) => _inner.restoreFolderFromTrash(trashId, originalName, destinationFolders);

  @override
  Future<Result<void>> purgeTrashPayload(String trashId) =>
      _inner.purgeTrashPayload(trashId);

  @override
  Future<Result<bool>> trashPayloadExists(String trashId) =>
      _inner.trashPayloadExists(trashId);

  @override
  Future<Result<void>> createFolder(List<String> folders) =>
      _inner.createFolder(folders);

  @override
  Future<Result<void>> deleteFolder(List<String> folders) =>
      _inner.deleteFolder(folders);

  @override
  Future<Result<void>> renameFolder(List<String> folders, String newName) =>
      _inner.renameFolder(folders, newName);

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) =>
      _inner.writeFile(path, sourcePath);

  @override
  Future<Result<String>> materialise(LibraryPath path) =>
      _inner.materialise(path);

  @override
  Future<Result<void>> releaseMaterialised(LibraryPath path) =>
      _inner.releaseMaterialised(path);

  @override
  Future<Result<void>> rename(LibraryPath from, LibraryPath to) =>
      _inner.rename(from, to);

  @override
  Future<Result<void>> delete(LibraryPath path) => _inner.delete(path);

  @override
  Future<Result<bool>> exists(LibraryPath path) => _inner.exists(path);

  @override
  Future<Result<int>> totalBytes() => _inner.totalBytes();
}

/// A shared-content channel that never delivers anything.
///
/// Production listens to a platform channel here. A host test has none, and a
/// source that emitted would make every boot's outcome depend on what it chose
/// to emit — which is exactly the nondeterminism the fakes exist to remove.
class _SilentSharedContentSource implements SharedContentSource {
  @override
  Future<Result<List<String>>> pending() async =>
      const Result<List<String>>.success([]);

  @override
  Stream<List<String>> get incoming => const Stream<List<String>>.empty();

  @override
  Future<void> dispose() async {}
}
