/// Constructs the iOS-only cloud-storage object graph.
library;

import 'dart:io';

import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/adopt_device_library.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_status.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/cloud_migration_gate_screen.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// iOS cloud-storage dependencies and the startup decision they produced.
class CloudStorageModule {
  /// Creates the already-resolved module.
  const CloudStorageModule({
    required this.locations,
    required this.cloud,
    required this.localStore,
    required this.resolution,
  });

  /// Versioned persisted authority.
  final StorageLocationPreferences locations;

  /// Registered first-party iCloud edge.
  final PlatformCloudContainerRepository cloud;

  /// Device-local candidate store.
  final FilesystemPublicFileStore localStore;

  /// Startup decision and the iCloud snapshot it was based on.
  final LoadedStorageLocation resolution;

  /// What the composition root must do before building the library.
  StorageDecision get decision => resolution.decision;

  /// The root this session is composed on.
  StorageLocation get authority => resolution.location;

  /// Where this session stores PDFs, for the Settings storage row.
  String get summary =>
      authority == StorageLocation.iCloud ? 'iCloud Drive' : 'On this device';

  /// Explicit, confirmed replacement of an unavailable iCloud library.
  AdoptDeviceLibrary get adoptDeviceLibrary => AdoptDeviceLibrary(locations);

  /// Resolves the selected store, failing rather than forking selected iCloud.
  Future<Result<PublicFileStore>> authoritativeStore() async {
    if (authority == StorageLocation.local) {
      return Result<PublicFileStore>.success(localStore);
    }
    return _iCloudStore();
  }

  /// Builds the typed iOS-only status route.
  ///
  /// [onRecompose] rebuilds the whole app, which is how "Move documents to
  /// iCloud now" reaches the migration gate; null disables that action.
  ScreenBuilder screen({
    CloudStorageAction? onImportFolder,
    Future<void> Function()? onRecompose,
  }) =>
      (context) => BlocProvider(
        create: (_) => StorageLocationCubit(
          loadStatus: LoadStorageStatus(authority: authority, cloud: cloud),
          onMoveNow: onRecompose,
        )..load(),
        child: StorageLocationScreen(
          onBack: () => context.pop(),
          onImportFolder: onImportFolder,
        ),
      );

  /// Moves the device library into iCloud with copy–verify–switch–cleanup.
  ///
  /// Fails with `cloud:unavailable` when the container cannot be reached, and
  /// otherwise with whatever [MigrateLibraryLocation] reports.
  Future<Result<void>> migrate({
    required StorageLocation source,
    required StorageLocation destination,
    StorageMigrationProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final availability = await cloud.availability();
    if (availability case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    if (!availability.valueOrNull!.isAvailable) {
      return const Result<void>.failure(
        Failure.storage(debugDetail: 'cloud:unavailable'),
      );
    }
    final iCloud = await _iCloudStore();
    if (iCloud case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final migration = MigrateLibraryLocation(
      locations: locations,
      stores: FixedLibraryStoreResolver(
        local: localStore,
        iCloud: iCloud.valueOrNull!,
      ),
      cloud: cloud,
    );
    return migration(
      source: source,
      destination: destination,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  Future<Result<PublicFileStore>> _iCloudStore() async {
    final root = await cloud.documentRootPath();
    if (root case Failed(:final failure)) {
      return Result<PublicFileStore>.failure(failure);
    }
    final path = root.valueOrNull;
    if (path == null || path.isEmpty) {
      return const Result<PublicFileStore>.failure(
        Failure.storage(debugDetail: 'cloud:unavailable'),
      );
    }
    return Result<PublicFileStore>.success(
      FilesystemPublicFileStore.atRoot(Directory(path)),
    );
  }
}

/// Builds cloud storage only after the caller has established iOS support.
///
/// [continueLocalThisSession] is set only when the user just left a failed
/// migration gate; see [LoadStorageLocation.call].
Future<Result<CloudStorageModule>> buildCloudStorageModule({
  required PreferenceStore preferences,
  required Directory documentsDirectory,
  ICloudPlatformApi platform = const IosICloudChannel(),
  bool continueLocalThisSession = false,
}) async {
  final locations = StorageLocationPreferences(preferences);
  final cloud = PlatformCloudContainerRepository(platform);
  final localStore = FilesystemPublicFileStore(documentsDirectory);
  final resolution = await LoadStorageLocation(
    locations: locations,
    cloud: cloud,
    localStore: localStore,
  )(continueLocalThisSession: continueLocalThisSession);
  if (resolution case Failed(:final failure)) {
    return Result<CloudStorageModule>.failure(failure);
  }
  return Result<CloudStorageModule>.success(
    CloudStorageModule(
      locations: locations,
      cloud: cloud,
      localStore: localStore,
      resolution: resolution.valueOrNull!,
    ),
  );
}

/// Startup screen that moves the device library into iCloud before the
/// library is composed.
///
/// It runs ahead of composition because the migration inventories the device
/// library once: nothing may write a document while it runs. It replaces
/// itself with [onFinished]'s app once iCloud is authoritative, or with
/// [onContinueLocal]'s when the user keeps the device for this session.
class CloudMigrationGateApp extends StatefulWidget {
  /// Creates the gate.
  const CloudMigrationGateApp({
    required this.runMigration,
    required this.onFinished,
    required this.onContinueLocal,
    super.key,
  });

  /// Copy–verify–switch–cleanup migration into iCloud.
  final RunStorageMigration runMigration;

  /// Re-runs composition once the library is in iCloud.
  final Future<Widget> Function() onFinished;

  /// Re-runs composition on the device library for this session only.
  final Future<Widget> Function() onContinueLocal;

  @override
  State<CloudMigrationGateApp> createState() => _CloudMigrationGateAppState();
}

class _CloudMigrationGateAppState extends State<CloudMigrationGateApp> {
  late final CloudMigrationGateCubit _cubit = CloudMigrationGateCubit(
    runMigration: widget.runMigration,
  );
  Widget? _resolved;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _cubit.start();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _swapTo(Future<Widget> Function() compose) async {
    if (_resolving) return;
    _resolving = true;
    final resolved = await compose();
    if (!mounted) return;
    setState(() => _resolved = resolved);
  }

  @override
  Widget build(BuildContext context) =>
      _resolved ??
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: BlocProvider.value(
          value: _cubit,
          child: CloudMigrationGateScreen(
            onFinished: () => _swapTo(widget.onFinished),
            onContinueLocal: () => _swapTo(widget.onContinueLocal),
          ),
        ),
      );
}

/// Honest startup state shown when a selected cloud authority is unavailable.
///
/// Keys: `cloud_storage_unavailable`, `cloud_storage_retry` (“Retry iCloud
/// connection”), `cloud_storage_use_device` (“Use this device without
/// iCloud”) and, in its confirmation, `cloud_storage_use_device_confirm`.
class CloudLibraryUnavailableApp extends StatefulWidget {
  /// Creates the unavailable application state.
  const CloudLibraryUnavailableApp({
    required this.onRetry,
    this.onUseDevice,
    super.key,
  });

  /// Re-runs the complete composition root without selecting local fallback.
  final Future<Widget> Function() onRetry;

  /// Makes the device library authoritative, after the user confirmed it, and
  /// re-runs composition; null where no authority can be changed.
  final Future<Widget> Function()? onUseDevice;

  @override
  State<CloudLibraryUnavailableApp> createState() =>
      _CloudLibraryUnavailableAppState();
}

class _CloudLibraryUnavailableAppState
    extends State<CloudLibraryUnavailableApp> {
  Widget? _resolved;
  bool _busy = false;

  Future<void> _swapTo(Future<Widget> Function() compose) async {
    if (_busy) return;
    setState(() => _busy = true);
    final resolved = await compose();
    if (!mounted) return;
    setState(() {
      _resolved = resolved;
      _busy = false;
    });
  }

  Future<void> _confirmUseDevice(BuildContext context) async {
    final useDevice = widget.onUseDevice;
    if (useDevice == null) return;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Use this device without iCloud?'),
        content: const Text(
          'Your iCloud documents stay in iCloud and are not deleted, but they '
          'will not appear until iCloud is available again. New documents are '
          'saved on this device and move to iCloud automatically when it '
          'returns.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          Semantics(
            label: CloudStorageSemantics.useDeviceConfirm,
            button: true,
            excludeSemantics: true,
            onTap: () => Navigator.of(dialogContext).pop(true),
            child: TextButton(
              key: CloudStorageKeys.useDeviceConfirm,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Use this device'),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _swapTo(useDevice);
  }

  @override
  Widget build(BuildContext context) =>
      _resolved ??
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('DocScanly')),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Semantics(
                      key: CloudStorageKeys.unavailable,
                      label: CloudStorageSemantics.unavailable,
                      container: true,
                      explicitChildNodes: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'Your DocScanly iCloud library is unavailable. '
                            'The app will not switch to local storage or '
                            'create a duplicate on its own.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: CloudStorageSemantics.retryConnection,
                            button: true,
                            excludeSemantics: true,
                            onTap: _busy ? null : () => _swapTo(widget.onRetry),
                            child: FilledButton.tonal(
                              key: CloudStorageKeys.retry,
                              onPressed: _busy
                                  ? null
                                  : () => _swapTo(widget.onRetry),
                              child: Text(
                                _busy
                                    ? 'Checking iCloud…'
                                    : 'Retry iCloud connection',
                              ),
                            ),
                          ),
                          if (widget.onUseDevice != null) ...[
                            const SizedBox(height: 8),
                            Semantics(
                              label: CloudStorageSemantics.useDevice,
                              button: true,
                              excludeSemantics: true,
                              onTap: _busy
                                  ? null
                                  : () => _confirmUseDevice(context),
                              child: TextButton(
                                key: CloudStorageKeys.useDevice,
                                onPressed: _busy
                                    ? null
                                    : () => _confirmUseDevice(context),
                                child: const Text(
                                  'Use this device without iCloud',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
