import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first install has no established authority', () async {
    final repository = StorageLocationPreferences(InMemoryPreferenceStore());

    expect((await repository.readLocation()).valueOrNull, isNull);
    expect((await repository.readCheckpoint()).valueOrNull, isNull);
  });

  test('round-trips location and durable checkpoint', () async {
    final repository = StorageLocationPreferences(InMemoryPreferenceStore());
    const checkpoint = StorageMigrationCheckpoint(
      source: StorageLocation.local,
      destination: StorageLocation.iCloud,
      phase: StorageMigrationPhase.verifying,
      verifiedRelativePaths: ['Folder/a.pdf', '.docscanly-trash/t/a.pdf'],
    );

    await repository.writeLocation(StorageLocation.local);
    await repository.writeCheckpoint(checkpoint);

    expect(
      (await repository.readLocation()).valueOrNull,
      StorageLocation.local,
    );
    expect((await repository.readCheckpoint()).valueOrNull, checkpoint);
  });

  test(
    'rejects corrupt persisted values instead of silently defaulting',
    () async {
      final repository = StorageLocationPreferences(
        InMemoryPreferenceStore({PreferenceKeys.libraryStorageLocation: 'bad'}),
      );

      expect((await repository.readLocation()).isFailure, isTrue);
    },
  );

  test('rejects an incomplete migration checkpoint', () async {
    final repository = StorageLocationPreferences(
      InMemoryPreferenceStore({
        PreferenceKeys.migrationSource: 'local',
        PreferenceKeys.migrationDestination: 'icloud',
      }),
    );

    expect((await repository.readCheckpoint()).isFailure, isTrue);
  });

  test('reports write failure and does not claim location succeeded', () async {
    final store = InMemoryPreferenceStore()..failNextWrite = true;
    final repository = StorageLocationPreferences(store);

    expect(
      (await repository.writeLocation(StorageLocation.iCloud)).isFailure,
      isTrue,
    );
    expect(store.values, isEmpty);
  });

  test('clears all restart data', () async {
    final store = InMemoryPreferenceStore();
    final repository = StorageLocationPreferences(store);
    await repository.writeCheckpoint(
      const StorageMigrationCheckpoint(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        phase: StorageMigrationPhase.copying,
      ),
    );

    await repository.clearCheckpoint();

    expect((await repository.readCheckpoint()).valueOrNull, isNull);
  });
}
