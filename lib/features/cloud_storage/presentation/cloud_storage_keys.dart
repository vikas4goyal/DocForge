/// Stable keys and semantics for iOS cloud-storage interfaces.
library;

import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:flutter/widgets.dart';

/// Widget keys used by storage status, the migration gate, and document cloud
/// status.
abstract final class CloudStorageKeys {
  /// Storage-location screen root.
  static const screen = Key('cloud_storage_screen');

  /// Card describing where documents are stored and why.
  static const status = Key('cloud_storage_status');

  /// Starts the move to iCloud during a device fallback.
  static const moveNow = Key('cloud_storage_move_now');

  /// Startup migration gate root.
  static const migrationGate = Key('cloud_storage_migration_gate');

  /// Migration progress region.
  static const migrationProgress = Key('cloud_storage_migration_progress');

  /// Completion message shown once the library is in iCloud.
  static const migrationDone = Key('cloud_storage_migration_done');

  /// Opens the library after a completed migration.
  static const migrationContinue = Key('cloud_storage_migration_continue');

  /// Leaves the gate and keeps the device library for this session.
  static const continueLocal = Key('cloud_storage_continue_local');

  /// Unavailable state.
  static const unavailable = Key('cloud_storage_unavailable');

  /// Retry action for a connection or a migration.
  static const retry = Key('cloud_storage_retry');

  /// Replaces an unavailable iCloud library with a device library.
  static const useDevice = Key('cloud_storage_use_device');

  /// Confirms [useDevice].
  static const useDeviceConfirm = Key('cloud_storage_use_device_confirm');

  /// Explicit folder-import action.
  static const importFolder = Key('cloud_storage_import_folder');

  /// Explicit cloud refresh control.
  static const libraryRefresh = Key('library_cloud_refresh');

  /// Every fixed key value, used by registry tests.
  static const fixedValues = <String>{
    'cloud_storage_screen',
    'cloud_storage_status',
    'cloud_storage_move_now',
    'cloud_storage_migration_gate',
    'cloud_storage_migration_progress',
    'cloud_storage_migration_done',
    'cloud_storage_migration_continue',
    'cloud_storage_continue_local',
    'cloud_storage_unavailable',
    'cloud_storage_retry',
    'cloud_storage_use_device',
    'cloud_storage_use_device_confirm',
    'cloud_storage_import_folder',
    'library_cloud_refresh',
  };
}

/// Normative screen-reader labels for cloud-storage actions and states.
abstract final class CloudStorageSemantics {
  /// Documents are stored in the app-owned iCloud library.
  static const storedInICloudDrive =
      'DocScanly documents are stored in iCloud Drive';

  /// Documents are stored on this device.
  static const storedOnDevice = 'DocScanly documents are stored on this device';

  /// Starts the move to iCloud now.
  static const moveNow = 'Move documents to iCloud now';

  /// The startup migration gate.
  static const migrationGate = 'Moving DocScanly documents to iCloud';

  /// Announces migration progress as a whole [percent].
  static String migrationProgress(int percent) =>
      'Library migration $percent percent';

  /// The completed migration.
  static const migrationDone =
      'Your DocScanly documents are now in iCloud Drive';

  /// Opens the library after migration.
  static const migrationContinue = 'Continue to DocScanly';

  /// Keeps the device library for this session.
  static const continueLocal = 'Continue on this device for now';

  /// Current selected cloud library is unavailable.
  static const unavailable = 'DocScanly iCloud library unavailable';

  /// Retry container availability.
  static const retryConnection = 'Retry iCloud connection';

  /// Retry an interrupted migration.
  static const retryMigration = 'Retry iCloud migration';

  /// Replaces an unavailable iCloud library with a device library.
  static const useDevice = 'Use this device without iCloud';

  /// Confirms [useDevice].
  static const useDeviceConfirm = 'Confirm using this device without iCloud';

  /// Explicitly import an external selected folder.
  static const importFolder = 'Import an existing iCloud Drive folder';

  /// Refresh app-owned cloud metadata.
  static const refresh = 'Refresh DocScanly iCloud library';

  /// Announces a remote-only document.
  static const storedInICloud = 'Stored in iCloud';

  /// Announces download progress for [title].
  static String downloading(String title) => 'Downloading $title from iCloud';

  /// Explains why iCloud is not used while [status] applies.
  ///
  /// [CloudAvailabilityStatus.available] means iCloud became usable during
  /// this session, so the library can be moved now.
  static String fallbackReason(
    CloudAvailabilityStatus status,
  ) => switch (status) {
    CloudAvailabilityStatus.available =>
      'iCloud is available. Move your documents to keep them in iCloud '
          'Drive',
    CloudAvailabilityStatus.signedOut => 'Sign in to iCloud in iOS Settings',
    CloudAvailabilityStatus.disabled =>
      'Turn on iCloud Drive for DocScanly in iOS Settings',
    CloudAvailabilityStatus.restricted => 'iCloud is restricted on this device',
    CloudAvailabilityStatus.unavailable => 'iCloud is temporarily unavailable',
  };
}
