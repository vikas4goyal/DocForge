import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_state.dart';
import 'package:flutter_test/flutter_test.dart';

StorageMigrationProgress _progress(
  StorageMigrationPhase phase,
  int done, [
  int total = 2,
]) => StorageMigrationProgress(
  phase: phase,
  completedFiles: done,
  totalFiles: total,
);

/// A scripted migration: reports [steps], then returns [result].
RunStorageMigration _scripted(
  List<StorageMigrationProgress> steps,
  Result<void> result, {
  List<(StorageLocation, StorageLocation)>? calls,
}) =>
    ({required source, required destination, onProgress, shouldCancel}) async {
      calls?.add((source, destination));
      steps.forEach(onProgress!);
      return result;
    };

void main() {
  const failure = Failure.storageFull(debugDetail: 'quota');

  blocTest<CloudMigrationGateCubit, CloudMigrationGateState>(
    'moves the device library into iCloud and completes',
    build: () => CloudMigrationGateCubit(
      runMigration: _scripted([
        _progress(StorageMigrationPhase.copying, 0),
        _progress(StorageMigrationPhase.verifying, 1),
        _progress(StorageMigrationPhase.verifying, 2),
        _progress(StorageMigrationPhase.cleaning, 2),
        _progress(StorageMigrationPhase.completed, 2),
      ], const Result<void>.success(null)),
    ),
    act: (cubit) => cubit.start(),
    expect: () => const [
      CloudMigrationGateState(),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.copying,
        totalFiles: 2,
      ),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.verifying,
        completedFiles: 1,
        totalFiles: 2,
      ),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.verifying,
        completedFiles: 2,
        totalFiles: 2,
      ),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.cleaning,
        completedFiles: 2,
        totalFiles: 2,
      ),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.completed,
        completedFiles: 2,
        totalFiles: 2,
      ),
    ],
  );

  test('always moves from the device to iCloud', () async {
    final calls = <(StorageLocation, StorageLocation)>[];
    final cubit = CloudMigrationGateCubit(
      runMigration: _scripted(
        const [],
        const Result<void>.success(null),
        calls: calls,
      ),
    );
    await cubit.start();
    expect(calls, [(StorageLocation.local, StorageLocation.iCloud)]);
    await cubit.close();
  });

  blocTest<CloudMigrationGateCubit, CloudMigrationGateState>(
    'a pre-switch failure keeps the device and retry succeeds',
    build: () {
      var attempts = 0;
      return CloudMigrationGateCubit(
        runMigration:
            ({
              required source,
              required destination,
              onProgress,
              shouldCancel,
            }) async {
              onProgress!(_progress(StorageMigrationPhase.verifying, 1));
              return attempts++ == 0
                  ? const Result<void>.failure(failure)
                  : const Result<void>.success(null);
            },
      );
    },
    act: (cubit) async {
      await cubit.start();
      await cubit.retry();
    },
    expect: () => const [
      CloudMigrationGateState(),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.verifying,
        completedFiles: 1,
        totalFiles: 2,
      ),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.failed,
        completedFiles: 1,
        totalFiles: 2,
        failure: failure,
      ),
      CloudMigrationGateState(),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.verifying,
        completedFiles: 1,
        totalFiles: 2,
      ),
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.completed,
        completedFiles: 2,
        totalFiles: 2,
      ),
    ],
  );

  blocTest<CloudMigrationGateCubit, CloudMigrationGateState>(
    'a post-switch cleanup failure still completes into iCloud',
    build: () => CloudMigrationGateCubit(
      runMigration: _scripted([
        _progress(StorageMigrationPhase.verifying, 2),
        _progress(StorageMigrationPhase.cleaning, 2),
      ], const Result<void>.failure(Failure.storage(debugDetail: 'delete'))),
    ),
    act: (cubit) => cubit.start(),
    skip: 3,
    expect: () => const [
      CloudMigrationGateState(
        status: CloudMigrationGateStatus.completed,
        completedFiles: 2,
        totalFiles: 2,
      ),
    ],
  );

  test('continuing on the device cancels a running move first', () async {
    final release = Completer<void>();
    bool Function()? cancelProbe;
    final cubit = CloudMigrationGateCubit(
      runMigration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async {
            cancelProbe = shouldCancel;
            onProgress!(_progress(StorageMigrationPhase.copying, 0));
            await release.future;
            return shouldCancel!()
                ? const Result<void>.failure(Failure.cancelled())
                : const Result<void>.success(null);
          },
    );

    unawaited(cubit.start());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isRunning, isTrue);
    final leaving = cubit.continueOnDevice();
    expect(cancelProbe!(), isTrue);
    release.complete();

    expect(await leaving, isTrue);
    expect(cubit.state.status, CloudMigrationGateStatus.failed);
    expect(cubit.state.failure, const Failure.cancelled());
    await cubit.close();
  });

  test('continuing after the switch reports completion instead', () async {
    final release = Completer<void>();
    final cubit = CloudMigrationGateCubit(
      runMigration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async {
            onProgress!(_progress(StorageMigrationPhase.cleaning, 2));
            await release.future;
            return const Result<void>.success(null);
          },
    );

    unawaited(cubit.start());
    await Future<void>.delayed(Duration.zero);
    final leaving = cubit.continueOnDevice();
    release.complete();

    expect(await leaving, isFalse);
    expect(cubit.state.status, CloudMigrationGateStatus.completed);
    await cubit.close();
  });

  test('a second start while running reuses the same move', () async {
    var runs = 0;
    final release = Completer<void>();
    final cubit = CloudMigrationGateCubit(
      runMigration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async {
            runs++;
            await release.future;
            return const Result<void>.success(null);
          },
    );

    final first = cubit.start();
    final second = cubit.start();
    release.complete();
    await Future.wait([first, second]);

    expect(runs, 1);
    await cubit.close();
  });

  test('progress is bounded and running reflects the phase', () {
    const copying = CloudMigrationGateState(
      status: CloudMigrationGateStatus.copying,
      completedFiles: 1,
      totalFiles: 4,
    );
    expect(copying.progress, .25);
    expect(copying.isRunning, isTrue);
    expect(const CloudMigrationGateState().progress, 0);
    expect(
      const CloudMigrationGateState(
        status: CloudMigrationGateStatus.cleaning,
      ).progress,
      1,
    );
    expect(
      const CloudMigrationGateState(
        status: CloudMigrationGateStatus.failed,
      ).isRunning,
      isFalse,
    );
  });
}
