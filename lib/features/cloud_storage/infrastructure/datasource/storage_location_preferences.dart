/// SharedPreferences-backed library authority and migration checkpoints.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/library_location_repository.dart';

/// Persists non-sensitive cloud-storage selection in [PreferenceStore].
class StorageLocationPreferences implements LibraryLocationRepository {
  /// Creates the repository over [preferences].
  const StorageLocationPreferences(this.preferences);

  /// The non-sensitive preference store.
  final PreferenceStore preferences;

  @override
  Future<Result<StorageLocation?>> readLocation() async {
    final result = await preferences.readString(
      PreferenceKeys.libraryStorageLocation,
    );
    if (result case Failed(failure: final failure)) {
      return Result<StorageLocation?>.failure(failure);
    }
    final value = result.valueOrNull;
    if (value == null) return const Result<StorageLocation?>.success(null);
    final location = StorageLocation.fromId(value);
    return location == null
        ? const Result<StorageLocation?>.failure(
            Failure.corruptFile(
              debugDetail: 'invalid storage location preference',
            ),
          )
        : Result<StorageLocation?>.success(location);
  }

  @override
  Future<Result<void>> writeLocation(StorageLocation location) => preferences
      .writeString(PreferenceKeys.libraryStorageLocation, location.id);

  @override
  Future<Result<StorageMigrationCheckpoint?>> readCheckpoint() async {
    final results = await (
      preferences.readString(PreferenceKeys.migrationSource),
      preferences.readString(PreferenceKeys.migrationDestination),
      preferences.readString(PreferenceKeys.migrationPhase),
      preferences.readString(PreferenceKeys.migrationVerifiedPaths),
    ).wait;
    for (final result in [results.$1, results.$2, results.$3, results.$4]) {
      if (result case Failed(failure: final failure)) {
        return Result<StorageMigrationCheckpoint?>.failure(failure);
      }
    }

    final sourceValue = results.$1.valueOrNull;
    final destinationValue = results.$2.valueOrNull;
    final phaseValue = results.$3.valueOrNull;
    final pathsValue = results.$4.valueOrNull;
    if ([
      sourceValue,
      destinationValue,
      phaseValue,
      pathsValue,
    ].every((value) => value == null)) {
      return const Result<StorageMigrationCheckpoint?>.success(null);
    }

    final source = StorageLocation.fromId(sourceValue);
    final destination = StorageLocation.fromId(destinationValue);
    StorageMigrationPhase? phase;
    for (final candidate in StorageMigrationPhase.values) {
      if (candidate.name == phaseValue) phase = candidate;
    }
    if (source == null || destination == null || phase == null) {
      return const Result<StorageMigrationCheckpoint?>.failure(
        Failure.corruptFile(debugDetail: 'incomplete migration checkpoint'),
      );
    }

    return Result<StorageMigrationCheckpoint?>.success(
      StorageMigrationCheckpoint(
        source: source,
        destination: destination,
        phase: phase,
        verifiedRelativePaths: pathsValue == null || pathsValue.isEmpty
            ? const []
            : pathsValue.split('\n'),
      ),
    );
  }

  @override
  Future<Result<void>> writeCheckpoint(
    StorageMigrationCheckpoint checkpoint,
  ) async {
    final writes = <Future<Result<void>> Function()>[
      () => preferences.writeString(
        PreferenceKeys.migrationSource,
        checkpoint.source.id,
      ),
      () => preferences.writeString(
        PreferenceKeys.migrationDestination,
        checkpoint.destination.id,
      ),
      () => preferences.writeString(
        PreferenceKeys.migrationPhase,
        checkpoint.phase.name,
      ),
      () => preferences.writeString(
        PreferenceKeys.migrationVerifiedPaths,
        checkpoint.verifiedRelativePaths.join('\n'),
      ),
    ];
    for (final write in writes) {
      final result = await write();
      if (result case Failed(failure: final failure)) {
        return Result<void>.failure(failure);
      }
    }
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> clearCheckpoint() async {
    for (final key in [
      PreferenceKeys.migrationSource,
      PreferenceKeys.migrationDestination,
      PreferenceKeys.migrationPhase,
      PreferenceKeys.migrationVerifiedPaths,
    ]) {
      final result = await preferences.remove(key);
      if (result case Failed(failure: final failure)) {
        return Result<void>.failure(failure);
      }
    }
    return const Result<void>.success(null);
  }
}
