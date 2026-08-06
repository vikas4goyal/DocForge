import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
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
  test('fixed key registry is unique and complete', () {
    expect(CloudStorageKeys.fixedValues, hasLength(10));
  });

  testWidgets(
    'selection, confirmation, and migration fit in a scrollable screen',
    (tester) async {
      final platform = ScriptedICloudPlatform();
      final locations = StorageLocationPreferences(
        InMemoryPreferenceStore({'settings.storage.location.v1': 'local'}),
      );
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
            }) async => const Result<void>.success(null),
      );

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

      expect(find.byKey(CloudStorageKeys.screen), findsOneWidget);
      expect(find.byKey(CloudStorageKeys.localOption), findsOneWidget);
      expect(find.byKey(CloudStorageKeys.iCloudOption), findsOneWidget);

      await tester.tap(find.byKey(CloudStorageKeys.iCloudOption));
      await tester.pump();

      expect(find.byKey(CloudStorageKeys.migrationConfirm), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cubit.close();
      await platform.dispose();
    },
  );

  testWidgets('unavailable state explains no local fallback and retries', (
    tester,
  ) async {
    final platform = ScriptedICloudPlatform(availabilityValue: 'signedOut');
    final locations = StorageLocationPreferences(
      InMemoryPreferenceStore({'settings.storage.location.v1': 'icloud'}),
    );
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
          }) async => const Result<void>.success(null),
    );

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

    expect(find.byKey(CloudStorageKeys.unavailable), findsOneWidget);
    expect(find.textContaining('will not switch to local'), findsOneWidget);
    expect(find.byKey(CloudStorageKeys.retry), findsOneWidget);
    expect(cubit.state.location, StorageLocation.iCloud);
    await cubit.close();
    await platform.dispose();
  });
}
