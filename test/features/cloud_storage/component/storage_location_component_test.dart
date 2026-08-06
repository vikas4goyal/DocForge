import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory localContainer;
  late Directory cloudRoot;
  late FilesystemPublicFileStore local;
  late FilesystemPublicFileStore iCloud;
  late ScriptedICloudPlatform platform;

  setUp(() async {
    localContainer = await Directory.systemTemp.createTemp(
      'docscanly_component_local_',
    );
    cloudRoot = await Directory.systemTemp.createTemp(
      'docscanly_component_cloud_',
    );
    local = FilesystemPublicFileStore(localContainer);
    iCloud = FilesystemPublicFileStore.atRoot(cloudRoot);
    await local.initialise();
    await iCloud.initialise();
    platform = ScriptedICloudPlatform(rootPath: cloudRoot.path);
  });

  tearDown(() async {
    await platform.dispose();
    if (localContainer.existsSync()) {
      await localContainer.delete(recursive: true);
    }
    if (cloudRoot.existsSync()) await cloudRoot.delete(recursive: true);
  });

  test('real Cubit and migration move one authoritative library', () async {
    final source = File('${localContainer.path}/source.pdf')
      ..writeAsStringSync('authoritative-pdf');
    await local.writeFile(LibraryPath.parse('Invoices/A.pdf'), source.path);
    final preferenceStore = InMemoryPreferenceStore({
      'settings.storage.location.v1': 'local',
    });
    final locations = StorageLocationPreferences(preferenceStore);
    final cloud = PlatformCloudContainerRepository(platform);
    final migrate = MigrateLibraryLocation(
      locations: locations,
      stores: FixedLibraryStoreResolver(local: local, iCloud: iCloud),
      cloud: cloud,
    );
    final cubit = StorageLocationCubit(
      loadLocation: LoadStorageLocation(locations: locations, cloud: cloud),
      chooseLocation: ChooseStorageLocation(cloud),
      runMigration: migrate.call,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.choose(StorageLocation.iCloud);
    await cubit.confirm();

    expect(
      (await iCloud.exists(LibraryPath.parse('Invoices/A.pdf'))).valueOrNull,
      isTrue,
    );
    expect(
      (await local.exists(LibraryPath.parse('Invoices/A.pdf'))).valueOrNull,
      isFalse,
    );
    expect(preferenceStore.values['settings.storage.location.v1'], 'icloud');
    expect(platform.marker, isNotNull);
    expect(cubit.state.location, StorageLocation.iCloud);
  });

  test(
    'interrupted migration remains retryable through the real Cubit',
    () async {
      final source = File('${localContainer.path}/retry-source.pdf')
        ..writeAsStringSync('retryable-pdf');
      await local.writeFile(LibraryPath.parse('Retry.pdf'), source.path);
      final preferenceStore = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'local',
      });
      final locations = StorageLocationPreferences(preferenceStore);
      final cloud = PlatformCloudContainerRepository(platform);
      final migrate = MigrateLibraryLocation(
        locations: locations,
        stores: FixedLibraryStoreResolver(local: local, iCloud: iCloud),
        cloud: cloud,
      );
      var attempts = 0;
      final cubit = StorageLocationCubit(
        loadLocation: LoadStorageLocation(locations: locations, cloud: cloud),
        chooseLocation: ChooseStorageLocation(cloud),
        runMigration:
            ({
              required source,
              required destination,
              onProgress,
              shouldCancel,
            }) async {
              attempts++;
              if (attempts == 1) {
                return const Result<void>.failure(
                  Failure.storage(debugDetail: 'interrupted copy'),
                );
              }
              return migrate(
                source: source,
                destination: destination,
                onProgress: onProgress,
                shouldCancel: shouldCancel,
              );
            },
      );
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.choose(StorageLocation.iCloud);
      await cubit.confirm();
      expect(cubit.state.failure, isA<StorageFailure>());
      expect(cubit.state.location, StorageLocation.local);

      await cubit.retry();

      expect(attempts, 2);
      expect(cubit.state.location, StorageLocation.iCloud);
      expect(
        (await iCloud.exists(LibraryPath.parse('Retry.pdf'))).valueOrNull,
        isTrue,
      );
      expect(
        (await local.exists(LibraryPath.parse('Retry.pdf'))).valueOrNull,
        isFalse,
      );
    },
  );

  testWidgets('valid marker discovers an established library on a new device', (
    tester,
  ) async {
    platform.marker = {
      'schemaVersion': cloudLibraryMarkerSchemaVersion,
      'libraryIdentifier': CloudLibraryMarker.defaultLibraryIdentifier,
    };
    final locations = StorageLocationPreferences(InMemoryPreferenceStore());
    final cloud = PlatformCloudContainerRepository(platform);
    final cubit = StorageLocationCubit(
      loadLocation: LoadStorageLocation(locations: locations, cloud: cloud),
      chooseLocation: ChooseStorageLocation(cloud),
      runMigration:
          ({
            required source,
            required destination,
            onProgress,
            shouldCancel,
          }) async => throw StateError('migration is not part of discovery'),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: StorageLocationScreen(onBack: () {}),
        ),
      ),
    );
    await cubit.load();
    await tester.pump();

    final option = tester.widget<ListTile>(
      find.descendant(
        of: find.byKey(CloudStorageKeys.iCloudOption),
        matching: find.byType(ListTile),
      ),
    );
    expect(option.leading, isA<Icon>());
    expect(cubit.state.location?.name, 'iCloud');
  });
}
