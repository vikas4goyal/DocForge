/// Robot for DocScanly's iOS-only storage-location journey.
library;

import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump.dart';
import 'robot.dart';

/// Drives local/iCloud selection, migration, recovery, and refresh controls.
class CloudStorageRobot extends Robot {
  /// Creates the robot.
  const CloudStorageRobot(super.tester);

  @override
  Key get screenKey => CloudStorageKeys.screen;

  /// Selects iCloud, confirms copy–verify migration, and waits for completion.
  Future<void> moveLibraryToICloud() =>
      step('moving the library to iCloud', () async {
        await waitUntilVisible();
        await tap(CloudStorageKeys.iCloudOption);
        await waitFor(CloudStorageKeys.migrationConfirm);
        await tap(CloudStorageKeys.migrationConfirm);
        await waitFor(
          CloudStorageKeys.migrationProgress,
          timeout: const Duration(seconds: 60),
        );
        await tester.pump(const Duration(seconds: 1));
      });

  /// Retries an unavailable container or interrupted migration.
  Future<void> retry() => step('retrying iCloud storage', () async {
    await tap(CloudStorageKeys.retry);
  });

  /// Whether the no-fallback unavailable state is visible.
  bool get isUnavailable => has(CloudStorageKeys.unavailable);

  /// Selects iCloud while unavailable and waits for the no-fallback state.
  Future<void> chooseUnavailableICloud() =>
      step('selecting unavailable iCloud storage', () async {
        await waitUntilVisible();
        await tap(CloudStorageKeys.iCloudOption);
        await waitFor(CloudStorageKeys.unavailable);
      });
}
