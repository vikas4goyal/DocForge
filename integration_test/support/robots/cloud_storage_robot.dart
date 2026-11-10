/// Robots for DocScanly's iOS-only iCloud-by-default journey.
library;

import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump.dart';
import 'robot.dart';

/// How long a gate may take to copy and verify a flow's small library.
const _migrationTimeout = Duration(seconds: 60);

/// Drives the storage-location status screen.
class CloudStorageRobot extends Robot {
  /// Creates the robot.
  const CloudStorageRobot(super.tester);

  @override
  Key get screenKey => CloudStorageKeys.screen;

  /// Asserts the status card announces [semanticsLabel].
  Future<void> expectStatus(String semanticsLabel) =>
      step('checking storage status', () async {
        await waitUntilVisible();
        await waitFor(CloudStorageKeys.status);
        expect(
          find.bySemanticsLabel(semanticsLabel),
          findsOneWidget,
          reason: 'expected the storage status "$semanticsLabel"',
        );
      });

  /// Whether "Move documents to iCloud now" can be used.
  bool get canMoveNow {
    final button = find.byKey(CloudStorageKeys.moveNow);
    if (button.evaluate().isEmpty) return false;
    return tester.widget<ButtonStyleButton>(button).onPressed != null;
  }

  /// Starts moving the device library to iCloud now.
  Future<void> moveNow() => step('moving documents to iCloud now', () async {
    await waitUntilVisible();
    await tap(CloudStorageKeys.moveNow);
  });

  /// Retries an unavailable container or a failed status read.
  Future<void> retry() => step('retrying iCloud storage', () async {
    await tap(CloudStorageKeys.retry);
  });

  /// Whether the no-fallback unavailable state is visible.
  bool get isUnavailable => has(CloudStorageKeys.unavailable);
}

/// Drives the startup migration gate.
class CloudMigrationGateRobot extends Robot {
  /// Creates the robot.
  const CloudMigrationGateRobot(super.tester);

  @override
  Key get screenKey => CloudStorageKeys.migrationGate;

  /// Waits for the gate to appear ahead of the library.
  Future<void> waitForGate() =>
      step('waiting for the migration gate', () async {
        await waitUntilVisible();
      });

  /// Waits for completion and continues into the iCloud library.
  Future<void> continueAfterMigration() => step(
    'continuing after the move to iCloud',
    () async {
      await waitUntilVisible();
      await waitFor(CloudStorageKeys.migrationDone, timeout: _migrationTimeout);
      await tap(CloudStorageKeys.migrationContinue);
      await waitUntilGone(CloudStorageKeys.migrationGate);
    },
  );

  /// Waits for the move to stop with a recoverable failure.
  Future<void> waitForFailure() =>
      step('waiting for the move to fail', () async {
        await waitUntilVisible();
        await waitFor(CloudStorageKeys.retry, timeout: _migrationTimeout);
      });

  /// Retries a failed move.
  Future<void> retryMigration() =>
      step('retrying the move to iCloud', () async {
        await tap(CloudStorageKeys.retry);
      });

  /// Keeps the device library for this session.
  Future<void> continueOnDevice() =>
      step('continuing on this device for now', () async {
        await tap(CloudStorageKeys.continueLocal);
        await waitUntilGone(
          CloudStorageKeys.migrationGate,
          timeout: _migrationTimeout,
        );
      });
}

/// Drives the startup state shown when the iCloud library is unreachable.
class CloudUnavailableRobot extends Robot {
  /// Creates the robot.
  const CloudUnavailableRobot(super.tester);

  @override
  Key get screenKey => CloudStorageKeys.unavailable;

  /// Retries the iCloud connection.
  Future<void> retry() => step('retrying the iCloud connection', () async {
    await waitUntilVisible();
    await tap(CloudStorageKeys.retry);
  });

  /// Confirms using a device library without iCloud.
  Future<void> useDeviceWithoutICloud() =>
      step('using this device without iCloud', () async {
        await waitUntilVisible();
        await tap(CloudStorageKeys.useDevice);
        await tap(CloudStorageKeys.useDeviceConfirm);
        await waitUntilGone(CloudStorageKeys.unavailable);
      });
}
