/// Flow — the iOS-only app-owned iCloud Documents library.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/cloud_storage_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selection migrates active PDFs and Trash before switching', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform();
    addTearDown(cloud.dispose);
    final app = await bootDocScanly(tester, iCloudPlatform: cloud, isIOS: true);
    final source = await app.fixtures.importable();
    await app.publicStore.writeFile(LibraryPath.parse('Active.pdf'), source);
    await app.publicStore.writeFile(
      LibraryPath.parse('Recoverable.pdf'),
      source,
    );
    await app.publicStore.moveFileToTrash(
      'trash-flow',
      LibraryPath.parse('Recoverable.pdf'),
    );

    await DashboardRobot(tester).waitUntilLoaded();
    final shell = TabShellRobot(tester);
    await shell.openSettings();
    final settings = SettingsRobot(tester);
    await settings.openStorageLocation();
    await CloudStorageRobot(tester).moveLibraryToICloud();

    final selected = await app.dependencies.preferences.readString(
      PreferenceKeys.libraryStorageLocation,
    );
    expect(selected.valueOrNull, StorageLocation.iCloud.id);
    final root = app.cloudLibraryFolder!;
    expect(File('${root.path}/Active.pdf').existsSync(), isTrue);
    expect(
      File(
        '${root.path}/.docscanly-trash/trash-flow/payload/Recoverable.pdf',
      ).existsSync(),
      isTrue,
    );
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
        marker: const {
          'schemaVersion': 1,
          'libraryIdentifier': 'docscanly-library',
        },
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

  testWidgets('unavailable iCloud never replaces the local authority', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform();
    addTearDown(cloud.dispose);
    final app = await bootDocScanly(tester, iCloudPlatform: cloud, isIOS: true);
    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).openSettings();
    await SettingsRobot(tester).openStorageLocation();

    cloud.availabilityValue = 'signedOut';
    final storage = CloudStorageRobot(tester);
    await storage.chooseUnavailableICloud();
    expect(storage.isUnavailable, isTrue);
    final selected = await app.dependencies.preferences.readString(
      PreferenceKeys.libraryStorageLocation,
    );
    expect(selected.valueOrNull, StorageLocation.local.id);

    cloud.availabilityValue = 'available';
    await storage.retry();
    await tester.pump(const Duration(milliseconds: 500));
    expect(storage.isUnavailable, isFalse);
  });
}
