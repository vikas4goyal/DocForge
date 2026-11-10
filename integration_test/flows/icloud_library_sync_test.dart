/// Flow — the iOS-only app-owned iCloud Documents library, used by default.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/cloud_storage_robot.dart';

const _establishedMarker = {
  'schemaVersion': 1,
  'libraryIdentifier': 'docscanly-library',
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<String?> storedLocation(FlowApp app) async =>
      (await app.dependencies.preferences.readString(
        PreferenceKeys.libraryStorageLocation,
      )).valueOrNull;

  Future<void> openStorageStatus(WidgetTester tester) async {
    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).openSettings();
    await SettingsRobot(tester).openStorageLocation();
  }

  testWidgets('a fresh install uses iCloud without asking', (tester) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform();
    addTearDown(cloud.dispose);

    final app = await bootDocScanly(tester, iCloudPlatform: cloud, isIOS: true);
    await openStorageStatus(tester);

    await CloudStorageRobot(
      tester,
    ).expectStatus(CloudStorageSemantics.storedInICloudDrive);
    expect(await storedLocation(app), StorageLocation.iCloud.id);
    expect(cloud.marker, isNotNull);
    expect(find.byKey(CloudStorageKeys.migrationGate), findsNothing);
  });

  testWidgets('a device library moves to iCloud through the gate', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform();
    addTearDown(cloud.dispose);

    final app = await bootDocScanly(
      tester,
      iCloudPlatform: cloud,
      isIOS: true,
      beforeCompose: (device, fixtures) async {
        final source = await fixtures.importable();
        await device.writeFile(LibraryPath.parse('Active.pdf'), source);
        await device.writeFile(LibraryPath.parse('Recoverable.pdf'), source);
        await device.moveFileToTrash(
          'trash-flow',
          LibraryPath.parse('Recoverable.pdf'),
        );
      },
    );

    final gate = CloudMigrationGateRobot(tester);
    await gate.waitForGate();
    await gate.continueAfterMigration();
    await DashboardRobot(tester).waitUntilLoaded();

    final root = app.cloudLibraryFolder!;
    expect(await storedLocation(app), StorageLocation.iCloud.id);
    expect(File('${root.path}/Active.pdf').existsSync(), isTrue);
    expect(
      File(
        '${root.path}/.docscanly-trash/trash-flow/payload/Recoverable.pdf',
      ).existsSync(),
      isTrue,
    );
    expect(File('${app.libraryFolder.path}/Active.pdf').existsSync(), isFalse);
    expect(cloud.marker, isNotNull);
  });

  testWidgets('a failed move continues on the device and retries later', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform()..scheduleOutage(afterChecks: 5);
    addTearDown(cloud.dispose);

    final app = await bootDocScanly(
      tester,
      iCloudPlatform: cloud,
      isIOS: true,
      beforeCompose: (device, fixtures) async {
        final source = await fixtures.importable();
        await device.writeFile(LibraryPath.parse('A.pdf'), source);
        await device.writeFile(LibraryPath.parse('B.pdf'), source);
      },
    );

    final gate = CloudMigrationGateRobot(tester);
    await gate.waitForFailure();
    await gate.continueOnDevice();
    await DashboardRobot(tester).waitUntilLoaded();
    expect(await storedLocation(app), StorageLocation.local.id);
    expect(File('${app.libraryFolder.path}/A.pdf').existsSync(), isTrue);

    // iCloud recovers; the next attempt comes from the status screen here,
    // standing in for the next cold launch.
    cloud.availabilityValue = 'available';
    await TabShellRobot(tester).openSettings();
    await SettingsRobot(tester).openStorageLocation();
    final storage = CloudStorageRobot(tester);
    await storage.expectStatus(
      '${CloudStorageSemantics.storedOnDevice}. '
      '${CloudStorageSemantics.fallbackReason(CloudAvailabilityStatus.available)}',
    );
    await storage.moveNow();
    await gate.continueAfterMigration();

    expect(await storedLocation(app), StorageLocation.iCloud.id);
    expect(File('${app.cloudLibraryFolder!.path}/B.pdf').existsSync(), isTrue);
  });

  testWidgets('signed out keeps the device, then moves after sign-in', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform(availabilityValue: 'signedOut');
    addTearDown(cloud.dispose);

    final app = await bootDocScanly(
      tester,
      iCloudPlatform: cloud,
      isIOS: true,
      beforeCompose: (device, fixtures) async {
        await device.writeFile(
          LibraryPath.parse('Local.pdf'),
          await fixtures.importable(),
        );
      },
    );
    expect(find.byKey(CloudStorageKeys.migrationGate), findsNothing);
    await openStorageStatus(tester);

    final storage = CloudStorageRobot(tester);
    await storage.expectStatus(
      '${CloudStorageSemantics.storedOnDevice}. '
      '${CloudStorageSemantics.fallbackReason(CloudAvailabilityStatus.signedOut)}',
    );
    expect(storage.canMoveNow, isFalse);
    expect(await storedLocation(app), StorageLocation.local.id);

    cloud.availabilityValue = 'available';
    // Back to Settings (via the storage detail screen) and in again, so the
    // status is read afresh.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await SettingsRobot(tester).openStorageLocation();
    await storage.expectStatus(
      '${CloudStorageSemantics.storedOnDevice}. '
      '${CloudStorageSemantics.fallbackReason(CloudAvailabilityStatus.available)}',
    );
    expect(storage.canMoveNow, isTrue);
    await storage.moveNow();
    await CloudMigrationGateRobot(tester).continueAfterMigration();

    expect(await storedLocation(app), StorageLocation.iCloud.id);
    expect(
      File('${app.cloudLibraryFolder!.path}/Local.pdf').existsSync(),
      isTrue,
    );
  });

  testWidgets('merging into an established library keeps both versions', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform(marker: _establishedMarker);
    addTearDown(cloud.dispose);
    final sharedRoot = await Directory.systemTemp.createTemp(
      'docscanly_merge_icloud_',
    );
    addTearDown(() async {
      if (sharedRoot.existsSync()) await sharedRoot.delete(recursive: true);
    });
    await File(
      '${sharedRoot.path}/Scan.pdf',
    ).writeAsString('%PDF-1.7 from another iPhone', flush: true);

    final app = await bootDocScanly(
      tester,
      iCloudPlatform: cloud,
      isIOS: true,
      cloudRootDirectory: sharedRoot,
      storageLocation: StorageLocation.local,
      beforeCompose: (device, fixtures) async {
        await device.writeFile(
          LibraryPath.parse('Scan.pdf'),
          await fixtures.importable(),
        );
      },
    );

    await CloudMigrationGateRobot(tester).continueAfterMigration();

    expect(await storedLocation(app), StorageLocation.iCloud.id);
    expect(
      File('${sharedRoot.path}/Scan.pdf').readAsStringSync(),
      '%PDF-1.7 from another iPhone',
    );
    expect(
      File('${sharedRoot.path}/Scan (Conflict device).pdf').existsSync(),
      isTrue,
    );

    // Both versions are listed once iCloud reports them.
    cloud.replaceItems(const [
      ScriptedICloudItem(relativePath: 'Scan.pdf', resourceIdentifier: 'a'),
      ScriptedICloudItem(
        relativePath: 'Scan (Conflict device).pdf',
        resourceIdentifier: 'b',
      ),
    ]);
    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    await dashboard.refreshCloudLibrary();
    await tester.pump(const Duration(milliseconds: 500));
    expect(dashboard.visibleDocumentIds, hasLength(2));
  });

  testWidgets('an unreachable iCloud library can continue on the device', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform(
      availabilityValue: 'disabled',
      marker: _establishedMarker,
    );
    addTearDown(cloud.dispose);

    final app = await bootDocScanly(
      tester,
      iCloudPlatform: cloud,
      isIOS: true,
      storageLocation: StorageLocation.iCloud,
    );

    final unavailable = CloudUnavailableRobot(tester);
    await unavailable.waitUntilVisible();
    expect(await storedLocation(app), StorageLocation.iCloud.id);

    await unavailable.useDeviceWithoutICloud();
    await DashboardRobot(tester).waitUntilLoaded();

    expect(await storedLocation(app), StorageLocation.local.id);
    expect(cloud.marker, isNotNull);
  });

  testWidgets(
    'a new device discovers, refreshes, and downloads the same library',
    (tester) async {
      if (!Platform.isIOS) return;
      final sharedRoot = await Directory.systemTemp.createTemp(
        'docscanly_shared_icloud_',
      );
      addTearDown(() async {
        if (sharedRoot.existsSync()) await sharedRoot.delete(recursive: true);
      });
      final remote = File('${sharedRoot.path}/Remote.pdf');
      await remote.writeAsString('%PDF-1.7 remote fixture', flush: true);
      final cloud = ScriptedICloudPlatform(
        marker: _establishedMarker,
        items: const [
          ScriptedICloudItem(
            relativePath: 'Remote.pdf',
            availability: 'remote',
            resourceIdentifier: 'remote-resource',
            sizeBytes: 23,
          ),
        ],
      );
      addTearDown(cloud.dispose);

      final app = await bootDocScanly(
        tester,
        iCloudPlatform: cloud,
        isIOS: true,
        cloudRootDirectory: sharedRoot,
      );
      final dashboard = DashboardRobot(tester);
      await dashboard.waitUntilLoaded();
      await dashboard.waitForDocuments();
      final documentId = dashboard.visibleDocumentIds.single;

      expect(
        find.byKey(LibraryKeys.documentCloudStatus(documentId)),
        findsOneWidget,
      );
      await dashboard.waitForDocumentThumbnail(documentId);
      expect(cloud.downloadRequests, contains('Remote.pdf'));

      final beforeRefresh = cloud.listRequests;
      await dashboard.refreshCloudLibrary();
      expect(cloud.listRequests, greaterThan(beforeRefresh));
      expect(app.libraryFolder.path, sharedRoot.path);
    },
  );

  testWidgets('an iCloud session that loses iCloud retries without fallback', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform();
    addTearDown(cloud.dispose);
    final app = await bootDocScanly(tester, iCloudPlatform: cloud, isIOS: true);
    cloud.availabilityValue = 'signedOut';
    await openStorageStatus(tester);

    final storage = CloudStorageRobot(tester);
    await storage.waitUntilVisible();
    expect(storage.isUnavailable, isTrue);
    expect(await storedLocation(app), StorageLocation.iCloud.id);

    cloud.availabilityValue = 'available';
    await storage.retry();
    await tester.pump(const Duration(milliseconds: 500));
    expect(storage.isUnavailable, isFalse);
  });
}
