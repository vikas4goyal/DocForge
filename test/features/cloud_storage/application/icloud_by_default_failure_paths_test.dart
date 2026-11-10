/// Tier 1 — failure propagation and value semantics of the iCloud-by-default
/// use cases: every repository failure surfaces as a typed result, and no
/// failure widens what a migration may delete.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/adopt_device_library.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_status.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/resolve_storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Preferences whose reads or removals of chosen keys fail.
class _FaultyPreferences extends InMemoryPreferenceStore {
  _FaultyPreferences(
    super.values, {
    this.failReadsOf = '',
    this.failRemoves = false,
  });

  final String failReadsOf;
  final bool failRemoves;

  @override
  Future<Result<String?>> readString(String key) async =>
      failReadsOf.isNotEmpty && key.contains(failReadsOf)
      ? const Result<String?>.failure(Failure.storage(debugDetail: 'read'))
      : super.readString(key);

  @override
  Future<Result<void>> remove(String key) async => failRemoves
      ? const Result<void>.failure(Failure.storage(debugDetail: 'remove'))
      : super.remove(key);
}

/// A platform whose marker operations throw on demand.
class _MarkerFaults extends ScriptedICloudPlatform {
  _MarkerFaults({super.rootPath});

  bool failRead = false;
  bool failWrite = false;

  @override
  Future<Map<String, Object?>?> readMarker() {
    if (failRead) throw PlatformException(code: 'marker_read');
    return super.readMarker();
  }

  @override
  Future<void> writeMarker(Map<String, Object?> marker) {
    if (failWrite) throw PlatformException(code: 'marker_write');
    return super.writeMarker(marker);
  }
}

const _legacyCheckpoint = StorageMigrationCheckpoint(
  source: StorageLocation.iCloud,
  destination: StorageLocation.local,
  phase: StorageMigrationPhase.copying,
);

void main() {
  late Directory scratch;
  late FilesystemPublicFileStore local;

  setUp(() async {
    scratch = await Directory.systemTemp.createTemp('docscanly_paths_');
    local = FilesystemPublicFileStore.atRoot(
      Directory('${scratch.path}/local'),
    );
  });

  tearDown(() => scratch.delete(recursive: true));

  group('value semantics', () {
    test('policy inputs, status and resolutions compare by value', () {
      // Built at run time: identical const instances would never consult
      // `props`, which is what these assertions are about.
      StorageDecisionInputs inputs({required bool payloads}) =>
          StorageDecisionInputs(
            stored: StorageLocation.local,
            availability: CloudAvailabilityStatus.available,
            marker: CloudMarkerState.absent,
            localHasPayloads: payloads,
          );
      expect(inputs(payloads: true), inputs(payloads: true));
      expect(inputs(payloads: true), isNot(inputs(payloads: false)));

      StorageStatus status(StorageLocation authority) => StorageStatus(
        authority: authority,
        availability: const CloudAvailability(
          CloudAvailabilityStatus.available,
        ),
      );
      expect(status(StorageLocation.iCloud), status(StorageLocation.iCloud));
      expect(
        status(StorageLocation.iCloud),
        isNot(status(StorageLocation.local)),
      );

      LoadedStorageLocation loaded(CloudAvailabilityStatus status) =>
          LoadedStorageLocation(
            decision: const StorageDecision.useICloud(),
            cloudAvailability: CloudAvailability(status),
          );
      expect(
        loaded(CloudAvailabilityStatus.available),
        loaded(CloudAvailabilityStatus.available),
      );
      expect(
        loaded(CloudAvailabilityStatus.available),
        isNot(loaded(CloudAvailabilityStatus.disabled)),
      );
    });

    test('a completed resumed move already names iCloud as the root', () {
      expect(
        const LoadedStorageLocation(
          decision: StorageDecision.migrateToICloud(
            resume: StorageMigrationCheckpoint(
              source: StorageLocation.local,
              destination: StorageLocation.iCloud,
              phase: StorageMigrationPhase.completed,
            ),
          ),
          cloudAvailability: CloudAvailability(
            CloudAvailabilityStatus.available,
          ),
        ).location,
        StorageLocation.iCloud,
      );
    });
  });

  group('LoadStorageLocation propagates', () {
    Future<Result<LoadedStorageLocation>> load(
      InMemoryPreferenceStore preferences,
      ScriptedICloudPlatform platform,
    ) => LoadStorageLocation(
      locations: StorageLocationPreferences(preferences),
      cloud: PlatformCloudContainerRepository(platform),
      localStore: local,
    )();

    test('a checkpoint read failure', () async {
      final platform = ScriptedICloudPlatform();
      final result = await load(
        _FaultyPreferences({}, failReadsOf: 'migration'),
        platform,
      );
      expect(result.failureOrNull, isA<StorageFailure>());
      await platform.dispose();
    });

    test('a failure to discard a legacy checkpoint', () async {
      final preferences = _FaultyPreferences({}, failRemoves: true);
      await StorageLocationPreferences(
        preferences,
      ).writeCheckpoint(_legacyCheckpoint);
      final platform = ScriptedICloudPlatform();

      expect(
        (await load(preferences, platform)).failureOrNull,
        isA<StorageFailure>(),
      );
      await platform.dispose();
    });

    test('a marker transport failure', () async {
      final platform = _MarkerFaults()..failRead = true;
      expect(
        (await load(InMemoryPreferenceStore(), platform)).failureOrNull,
        isA<StorageFailure>(),
      );
      await platform.dispose();
    });

    test('a marker write failure', () async {
      final platform = _MarkerFaults()..failWrite = true;
      final preferences = InMemoryPreferenceStore();
      expect(
        (await load(preferences, platform)).failureOrNull,
        isA<StorageFailure>(),
      );
      // The authority is not switched without its marker.
      expect(preferences.values['settings.storage.location.v1'], isNull);
      await platform.dispose();
    });
  });

  test(
    'AdoptDeviceLibrary propagates a failure to discard the checkpoint',
    () async {
      final preferences = _FaultyPreferences({
        'settings.storage.location.v1': 'icloud',
      }, failRemoves: true);

      final result = await AdoptDeviceLibrary(
        StorageLocationPreferences(preferences),
      )();

      expect(result.failureOrNull, isA<StorageFailure>());
      expect(preferences.values['settings.storage.location.v1'], 'icloud');
    },
  );

  group('MigrateLibraryLocation', () {
    late Directory cloudRoot;
    late FilesystemPublicFileStore cloudStore;
    late InMemoryPreferenceStore preferences;

    setUp(() async {
      cloudRoot = Directory('${scratch.path}/cloud')..createSync();
      cloudStore = FilesystemPublicFileStore.atRoot(cloudRoot);
      await local.initialise();
      preferences = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'local',
      });
    });

    Future<void> seed(String relative, String text) async {
      final source = File('${scratch.path}/seed')..writeAsStringSync(text);
      await local.writeFile(LibraryPath.parse(relative), source.path);
    }

    MigrateLibraryLocation migration(ScriptedICloudPlatform platform) =>
        MigrateLibraryLocation(
          locations: StorageLocationPreferences(preferences),
          stores: FixedLibraryStoreResolver(local: local, iCloud: cloudStore),
          cloud: PlatformCloudContainerRepository(platform),
        );

    test('a fresh destination loses its folders on cancellation', () async {
      await seed('Tax/2026/a.pdf', 'a');
      await seed('Tax/2026/b.pdf', 'b');
      final platform = ScriptedICloudPlatform(rootPath: cloudRoot.path);
      var checks = 0;

      final result = await migration(platform)(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        shouldCancel: () => checks++ > 0,
      );

      expect(result.failureOrNull, isA<CancelledFailure>());
      expect(Directory('${cloudRoot.path}/Tax').existsSync(), isFalse);
      await platform.dispose();
    });

    test('an unreadable marker is treated as an established library', () async {
      await File('${cloudRoot.path}/Kept.pdf').writeAsString('other device');
      Directory('${cloudRoot.path}/Shared').createSync();
      await seed('Shared/a.pdf', 'a');
      await seed('Shared/b.pdf', 'b');
      final platform = _MarkerFaults(rootPath: cloudRoot.path)..failRead = true;
      var checks = 0;

      final result = await migration(platform)(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        shouldCancel: () => checks++ > 0,
      );

      expect(result.failureOrNull, isA<CancelledFailure>());
      // Nothing it did not write is removed, including existing folders.
      expect(File('${cloudRoot.path}/Kept.pdf').existsSync(), isTrue);
      expect(Directory('${cloudRoot.path}/Shared').existsSync(), isTrue);
      await platform.dispose();
    });

    test('a marker read failure before the switch keeps the device', () async {
      await seed('a.pdf', 'a');
      final platform = _MarkerFaults(rootPath: cloudRoot.path);
      final migrate = MigrateLibraryLocation(
        locations: StorageLocationPreferences(preferences),
        stores: FixedLibraryStoreResolver(local: local, iCloud: cloudStore),
        cloud: PlatformCloudContainerRepository(platform),
      );
      var copied = false;

      final result = await migrate(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        onProgress: (progress) {
          // Fail the pre-switch marker check once every file is verified.
          if (progress.phase == StorageMigrationPhase.verifying &&
              progress.completedFiles == progress.totalFiles) {
            copied = true;
            platform.failRead = true;
          }
        },
      );

      expect(copied, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
      expect(preferences.values['settings.storage.location.v1'], 'local');
      await platform.dispose();
    });
  });
}
