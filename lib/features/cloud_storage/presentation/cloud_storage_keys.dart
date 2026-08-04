/// Stable keys and semantics for iOS cloud-storage interfaces.
library;

import 'package:flutter/widgets.dart';

/// Widget keys used by storage selection and document cloud status.
abstract final class CloudStorageKeys {
  /// Storage-location screen root.
  static const screen = Key('cloud_storage_screen');

  /// Device-local option.
  static const localOption = Key('cloud_storage_local_option');

  /// App-owned iCloud option.
  static const iCloudOption = Key('cloud_storage_icloud_option');

  /// Confirmation action.
  static const migrationConfirm = Key('cloud_storage_migration_confirm');

  /// Migration progress region.
  static const migrationProgress = Key('cloud_storage_migration_progress');

  /// Unavailable state.
  static const unavailable = Key('cloud_storage_unavailable');

  /// Retry action.
  static const retry = Key('cloud_storage_retry');

  /// Safe cancellation action.
  static const cancel = Key('cloud_storage_cancel');

  /// Explicit folder-import action.
  static const importFolder = Key('cloud_storage_import_folder');

  /// Explicit cloud refresh control.
  static const libraryRefresh = Key('library_cloud_refresh');

  /// Every fixed key value, used by registry tests.
  static const fixedValues = <String>{
    'cloud_storage_screen',
    'cloud_storage_local_option',
    'cloud_storage_icloud_option',
    'cloud_storage_migration_confirm',
    'cloud_storage_migration_progress',
    'cloud_storage_unavailable',
    'cloud_storage_retry',
    'cloud_storage_cancel',
    'cloud_storage_import_folder',
    'library_cloud_refresh',
  };
}

/// Normative screen-reader labels for cloud-storage actions and states.
abstract final class CloudStorageSemantics {
  /// Select the local library.
  static const useLocal = 'Use this device for DocScanly documents';

  /// Select the app-owned iCloud library.
  static const useICloud = 'Use iCloud Drive for DocScanly documents';

  /// Current selected cloud library is unavailable.
  static const unavailable = 'DocScanly iCloud library unavailable';

  /// Retry container availability.
  static const retryConnection = 'Retry iCloud connection';

  /// Retry an interrupted migration.
  static const retryMigration = 'Retry iCloud migration';

  /// Cancel a migration before authority switching.
  static const cancelMigration = 'Cancel iCloud migration';

  /// Explicitly import an external selected folder.
  static const importFolder = 'Import an existing iCloud Drive folder';

  /// Refresh app-owned cloud metadata.
  static const refresh = 'Refresh DocScanly iCloud library';

  /// Announces a remote-only document.
  static const storedInICloud = 'Stored in iCloud';

  /// Announces download progress for [title].
  static String downloading(String title) => 'Downloading $title from iCloud';
}
