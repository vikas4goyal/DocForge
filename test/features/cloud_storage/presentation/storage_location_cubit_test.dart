import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_status.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingPlatform extends ScriptedICloudPlatform {
  @override
  Future<String> availability() async =>
      throw PlatformException(code: 'unavailable');
}

void main() {
  late ScriptedICloudPlatform platform;
  late int moves;

  setUp(() {
    platform = ScriptedICloudPlatform();
    moves = 0;
  });

  tearDown(() => platform.dispose());

  StorageLocationCubit buildCubit(
    StorageLocation authority, {
    bool canRecompose = true,
  }) => StorageLocationCubit(
    loadStatus: LoadStorageStatus(
      authority: authority,
      cloud: PlatformCloudContainerRepository(platform),
    ),
    onMoveNow: canRecompose ? () async => moves++ : null,
  );

  const available = CloudAvailability(CloudAvailabilityStatus.available);

  blocTest<StorageLocationCubit, StorageLocationState>(
    'reports an active iCloud library',
    build: () => buildCubit(StorageLocation.iCloud),
    act: (cubit) => cubit.load(),
    expect: () => const [
      StorageLocationState(),
      StorageLocationState(
        status: StorageLocationStatus.iCloudActive,
        location: StorageLocation.iCloud,
        cloudAvailability: available,
      ),
    ],
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'reports an unreachable iCloud library as unavailable',
    setUp: () => platform.availabilityValue = 'signedOut',
    build: () => buildCubit(StorageLocation.iCloud),
    act: (cubit) => cubit.load(),
    expect: () => const [
      StorageLocationState(),
      StorageLocationState(
        status: StorageLocationStatus.unavailable,
        location: StorageLocation.iCloud,
        cloudAvailability: CloudAvailability(CloudAvailabilityStatus.signedOut),
      ),
    ],
  );

  for (final (value, status) in [
    ('signedOut', CloudAvailabilityStatus.signedOut),
    ('disabled', CloudAvailabilityStatus.disabled),
    ('restricted', CloudAvailabilityStatus.restricted),
    ('unavailable', CloudAvailabilityStatus.unavailable),
  ]) {
    blocTest<StorageLocationCubit, StorageLocationState>(
      'a device library reports ${status.name} and cannot move now',
      setUp: () => platform.availabilityValue = value,
      build: () => buildCubit(StorageLocation.local),
      act: (cubit) async {
        await cubit.load();
        await cubit.moveNow();
      },
      expect: () => [
        const StorageLocationState(),
        StorageLocationState(
          status: StorageLocationStatus.localFallback,
          location: StorageLocation.local,
          cloudAvailability: CloudAvailability(status),
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.canMoveNow, isFalse);
        expect(moves, 0);
      },
    );
  }

  blocTest<StorageLocationCubit, StorageLocationState>(
    'a device library moves now once iCloud is available',
    build: () => buildCubit(StorageLocation.local),
    act: (cubit) async {
      await cubit.load();
      await cubit.moveNow();
    },
    expect: () => const [
      StorageLocationState(),
      StorageLocationState(
        status: StorageLocationStatus.localFallback,
        location: StorageLocation.local,
        cloudAvailability: available,
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.canMoveNow, isTrue);
      expect(moves, 1);
    },
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'moving now is inert without a recompose callback',
    build: () => buildCubit(StorageLocation.local, canRecompose: false),
    act: (cubit) async {
      await cubit.load();
      await cubit.moveNow();
    },
    verify: (_) => expect(moves, 0),
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'an availability failure is recoverable by retry',
    build: () {
      final failing = _ThrowingPlatform();
      addTearDown(failing.dispose);
      return StorageLocationCubit(
        loadStatus: LoadStorageStatus(
          authority: StorageLocation.local,
          cloud: PlatformCloudContainerRepository(failing),
        ),
      );
    },
    act: (cubit) => cubit.retry(),
    expect: () => [
      const StorageLocationState(),
      isA<StorageLocationState>()
          .having((s) => s.status, 'status', StorageLocationStatus.failure)
          .having((s) => s.failure, 'failure', isA<StorageFailure>()),
    ],
  );

  blocTest<StorageLocationCubit, StorageLocationState>(
    'reloading passes through loading again',
    build: () => buildCubit(StorageLocation.iCloud),
    seed: () => const StorageLocationState(
      status: StorageLocationStatus.unavailable,
      location: StorageLocation.iCloud,
    ),
    act: (cubit) => cubit.retry(),
    expect: () => const [
      StorageLocationState(),
      StorageLocationState(
        status: StorageLocationStatus.iCloudActive,
        location: StorageLocation.iCloud,
        cloudAvailability: available,
      ),
    ],
  );
}
