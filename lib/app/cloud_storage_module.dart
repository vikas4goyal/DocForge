/// Constructs the iOS-only cloud-storage object graph.
library;

import 'dart:io';

import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// iOS storage-selection dependencies and its currently resolved authority.
class CloudStorageModule {
  /// Creates the already-resolved module.
  const CloudStorageModule({
    required this.locations,
    required this.cloud,
    required this.loadLocation,
    required this.chooseLocation,
    required this.localStore,
    required this.resolution,
  });

  /// Versioned persisted authority.
  final StorageLocationPreferences locations;

  /// Registered first-party iCloud edge.
  final PlatformCloudContainerRepository cloud;

  /// Startup and same-account discovery.
  final LoadStorageLocation loadLocation;

  /// Explicit choice validation.
  final ChooseStorageLocation chooseLocation;

  /// Device-local candidate store.
  final FilesystemPublicFileStore localStore;

  /// Startup resolution.
  final LoadedStorageLocation resolution;

  /// Resolves the selected store, failing rather than forking selected iCloud.
  Future<Result<PublicFileStore>> authoritativeStore() async {
    if (resolution.location == StorageLocation.local) {
      return Result<PublicFileStore>.success(localStore);
    }
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

  /// Builds the typed iOS-only route.
  ScreenBuilder screen({CloudStorageAction? onImportFolder}) =>
      (context) => BlocProvider(
        create: (_) => StorageLocationCubit(
          loadLocation: loadLocation,
          chooseLocation: chooseLocation,
          runMigration: _migrate,
        )..load(),
        child: StorageLocationScreen(
          onBack: () => context.pop(),
          onImportFolder: onImportFolder,
        ),
      );

  Future<Result<void>> _migrate({
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
    final root = await cloud.documentRootPath();
    if (root case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final path = root.valueOrNull;
    if (path == null || path.isEmpty) {
      return const Result<void>.failure(
        Failure.storage(debugDetail: 'cloud:unavailable'),
      );
    }
    final migration = MigrateLibraryLocation(
      locations: locations,
      stores: FixedLibraryStoreResolver(
        local: localStore,
        iCloud: FilesystemPublicFileStore.atRoot(Directory(path)),
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
}

/// Builds cloud storage only after the caller has established iOS support.
Future<Result<CloudStorageModule>> buildCloudStorageModule({
  required PreferenceStore preferences,
  required Directory documentsDirectory,
  ICloudPlatformApi platform = const IosICloudChannel(),
}) async {
  final locations = StorageLocationPreferences(preferences);
  final cloud = PlatformCloudContainerRepository(platform);
  final load = LoadStorageLocation(locations: locations, cloud: cloud);
  final resolution = await load();
  if (resolution case Failed(:final failure)) {
    return Result<CloudStorageModule>.failure(failure);
  }
  return Result<CloudStorageModule>.success(
    CloudStorageModule(
      locations: locations,
      cloud: cloud,
      loadLocation: load,
      chooseLocation: ChooseStorageLocation(cloud),
      localStore: FilesystemPublicFileStore(documentsDirectory),
      resolution: resolution.valueOrNull!,
    ),
  );
}

/// Honest startup state shown when a selected cloud authority is unavailable.
class CloudLibraryUnavailableApp extends StatefulWidget {
  /// Creates the unavailable application state.
  const CloudLibraryUnavailableApp({required this.onRetry, super.key});

  /// Re-runs the complete composition root without selecting local fallback.
  final Future<Widget> Function() onRetry;

  @override
  State<CloudLibraryUnavailableApp> createState() =>
      _CloudLibraryUnavailableAppState();
}

class _CloudLibraryUnavailableAppState
    extends State<CloudLibraryUnavailableApp> {
  Widget? _resolved;
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final resolved = await widget.onRetry();
    if (!mounted) return;
    setState(() {
      _resolved = resolved;
      _retrying = false;
    });
  }

  @override
  Widget build(BuildContext context) =>
      _resolved ??
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('DocScanly')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Your DocScanly iCloud library is unavailable. The app '
                        'will not switch to local storage or create a duplicate.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _retrying ? null : _retry,
                        child: Text(
                          _retrying
                              ? 'Checking iCloud…'
                              : 'Retry iCloud connection',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
