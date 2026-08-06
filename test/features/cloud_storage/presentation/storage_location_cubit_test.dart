import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ScriptedICloudPlatform platform;
  late InMemoryPreferenceStore preferenceStore;
  late StorageLocationPreferences locations;
  late PlatformCloudContainerRepository cloud;

  setUp(() {
    platform = ScriptedICloudPlatform();
    preferenceStore = InMemoryPreferenceStore({
      'settings.storage.location.v1': 'local',
    });
    locations = StorageLocationPreferences(preferenceStore);
    cloud = PlatformCloudContainerRepository(platform);
  });

  tearDown(() => platform.dispose());

  StorageLocationCubit buildCubit({RunStorageMigration? migration}) =>
      StorageLocationCubit(
        loadLocation: LoadStorageLocation(locations: locations, cloud: cloud),
        chooseLocation: ChooseStorageLocation(cloud),
        runMigration:
            migration ??
            ({
              required source,
              required destination,
              onProgress,
              shouldCancel,
            }) async => const Result<void>.success(null),
      );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'loads local authority',
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const StorageLocationState(),
      const StorageLocationState(
        status: StorageLocationStatus.readyLocal,
        location: StorageLocation.local,
        cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
      ),
    ],
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'selection requires confirmation before migration',
    build: buildCubit,
    seed: () => const StorageLocationState(
      status: StorageLocationStatus.readyLocal,
      location: StorageLocation.local,
      cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
    ),
    act: (cubit) => cubit.choose(StorageLocation.iCloud),
    expect: () => [
      const StorageLocationState(
        status: StorageLocationStatus.confirmationRequired,
        location: StorageLocation.local,
        cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
        pendingChoice: StorageLocationChoice(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        ),
      ),
    ],
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'reports migrating, verifying, and completed phases',
    build: () => buildCubit(
      migration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async {
            onProgress?.call(
              const StorageMigrationProgress(
                phase: StorageMigrationPhase.copying,
                completedFiles: 0,
                totalFiles: 2,
              ),
            );
            onProgress?.call(
              const StorageMigrationProgress(
                phase: StorageMigrationPhase.verifying,
                completedFiles: 1,
                totalFiles: 2,
              ),
            );
            onProgress?.call(
              const StorageMigrationProgress(
                phase: StorageMigrationPhase.completed,
                completedFiles: 2,
                totalFiles: 2,
              ),
            );
            return const Result<void>.success(null);
          },
    ),
    seed: () => const StorageLocationState(
      status: StorageLocationStatus.confirmationRequired,
      location: StorageLocation.local,
      cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
      pendingChoice: StorageLocationChoice(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
      ),
    ),
    act: (cubit) => cubit.confirm(),
    verify: (cubit) {
      expect(cubit.state.status, StorageLocationStatus.completed);
      expect(cubit.state.location, StorageLocation.iCloud);
      expect(cubit.state.progress, 1);
    },
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'keeps pending choice for retry after migration failure',
    build: () => buildCubit(
      migration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async => const Result<void>.failure(
            Failure.storage(debugDetail: 'offline'),
          ),
    ),
    seed: () => const StorageLocationState(
      status: StorageLocationStatus.confirmationRequired,
      location: StorageLocation.local,
      cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
      pendingChoice: StorageLocationChoice(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
      ),
    ),
    act: (cubit) => cubit.confirm(),
    verify: (cubit) {
      expect(cubit.state.status, StorageLocationStatus.failure);
      expect(cubit.state.location, StorageLocation.local);
      expect(cubit.state.pendingChoice, isNotNull);
    },
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'keeps selected iCloud authoritative when the account is unavailable',
    setUp: () {
      preferenceStore = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'icloud',
      });
      locations = StorageLocationPreferences(preferenceStore);
      platform.availabilityValue = 'signedOut';
    },
    build: buildCubit,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, StorageLocationStatus.unavailable);
      expect(cubit.state.location, StorageLocation.iCloud);
      expect(
        cubit.state.cloudAvailability.status,
        CloudAvailabilityStatus.signedOut,
      );
    },
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'maps a corrupt persisted authority to a recoverable failure',
    setUp: () {
      preferenceStore = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'invalid',
      });
      locations = StorageLocationPreferences(preferenceStore);
    },
    build: buildCubit,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, StorageLocationStatus.failure);
      expect(cubit.state.failure, isA<CorruptFileFailure>());
    },
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'reports unavailable when iCloud cannot be selected',
    setUp: () => platform.availabilityValue = 'restricted',
    build: buildCubit,
    seed: () => const StorageLocationState(
      status: StorageLocationStatus.readyLocal,
      location: StorageLocation.local,
      cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
    ),
    act: (cubit) => cubit.choose(StorageLocation.iCloud),
    verify: (cubit) {
      expect(cubit.state.status, StorageLocationStatus.unavailable);
      expect(cubit.state.location, StorageLocation.local);
      expect(cubit.state.failure, isA<StorageFailure>());
      expect(cubit.state.pendingChoice, isNull);
    },
  );

  test('safe cancellation returns to the source authority', () async {
    final migrationStarted = Completer<void>();
    final continueMigration = Completer<void>();
    final cubit = buildCubit(
      migration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async {
            onProgress?.call(
              const StorageMigrationProgress(
                phase: StorageMigrationPhase.copying,
                completedFiles: 0,
                totalFiles: 1,
              ),
            );
            migrationStarted.complete();
            await continueMigration.future;
            return shouldCancel?.call() ?? false
                ? const Result<void>.failure(Failure.cancelled())
                : const Result<void>.success(null);
          },
    );
    addTearDown(cubit.close);
    cubit.emit(
      const StorageLocationState(
        status: StorageLocationStatus.confirmationRequired,
        location: StorageLocation.local,
        cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
        pendingChoice: StorageLocationChoice(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        ),
      ),
    );

    final confirmation = cubit.confirm();
    await migrationStarted.future;
    cubit.cancel();
    continueMigration.complete();
    await confirmation;

    expect(cubit.state.status, StorageLocationStatus.readyLocal);
    expect(cubit.state.location, StorageLocation.local);
    expect(cubit.state.pendingChoice, isNull);
    expect(cubit.state.failure, isNull);
  });

  test('retry resumes a pending migration checkpoint', () async {
    var attempts = 0;
    final cubit = buildCubit(
      migration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async {
            attempts++;
            if (attempts == 1) {
              return const Result<void>.failure(
                Failure.storage(debugDetail: 'offline'),
              );
            }
            onProgress?.call(
              const StorageMigrationProgress(
                phase: StorageMigrationPhase.completed,
                completedFiles: 1,
                totalFiles: 1,
              ),
            );
            return const Result<void>.success(null);
          },
    );
    addTearDown(cubit.close);
    cubit.emit(
      const StorageLocationState(
        status: StorageLocationStatus.confirmationRequired,
        location: StorageLocation.local,
        cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
        pendingChoice: StorageLocationChoice(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        ),
      ),
    );

    await cubit.confirm();
    expect(cubit.state.status, StorageLocationStatus.failure);
    await cubit.retry();

    expect(attempts, 2);
    expect(cubit.state.status, StorageLocationStatus.completed);
    expect(cubit.state.location, StorageLocation.iCloud);
    expect(cubit.state.pendingChoice, isNull);
  });

  test('cancel is disabled after the authority-switch boundary', () async {
    var observedCancellation = true;
    late StorageLocationCubit cubit;
    cubit = buildCubit(
      migration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async {
            onProgress?.call(
              const StorageMigrationProgress(
                phase: StorageMigrationPhase.cleaning,
                completedFiles: 1,
                totalFiles: 1,
              ),
            );
            cubit.cancel();
            observedCancellation = shouldCancel?.call() ?? false;
            return const Result<void>.success(null);
          },
    );
    addTearDown(cubit.close);
    cubit.emit(
      const StorageLocationState(
        status: StorageLocationStatus.confirmationRequired,
        location: StorageLocation.local,
        pendingChoice: StorageLocationChoice(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        ),
      ),
    );

    await cubit.confirm();

    expect(observedCancellation, isFalse);
    expect(cubit.state.location, StorageLocation.iCloud);
  });

  test('state uses value equality', () {
    expect(
      const StorageLocationState(location: StorageLocation.local),
      const StorageLocationState(location: StorageLocation.local),
    );
  });
}
