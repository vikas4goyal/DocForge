/// Tier 2 — the unavailable-library screen wired to the real device-escape use
/// case and real preferences; only the recomposed app is substituted.
library;

import 'package:doc_scanly/app/cloud_storage_module.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/adopt_device_library.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryPreferenceStore preferences;
  late StorageLocationPreferences locations;

  setUp(() async {
    preferences = InMemoryPreferenceStore({
      'settings.storage.location.v1': 'icloud',
    });
    locations = StorageLocationPreferences(preferences);
    await locations.writeCheckpoint(
      const StorageMigrationCheckpoint(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        phase: StorageMigrationPhase.cleaning,
      ),
    );
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    CloudLibraryUnavailableApp(
      onRetry: () async => _stand('still iCloud'),
      onUseDevice: () async {
        await AdoptDeviceLibrary(locations)();
        return _stand('device library');
      },
    ),
  );

  testWidgets('confirming makes the device library authoritative', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(CloudStorageKeys.useDevice));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CloudStorageKeys.useDeviceConfirm));
    await tester.pumpAndSettle();

    expect(find.text('device library'), findsOneWidget);
    expect(preferences.values['settings.storage.location.v1'], 'local');
    expect((await locations.readCheckpoint()).valueOrNull, isNull);
  });

  testWidgets('dismissing leaves the iCloud authority unchanged', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(CloudStorageKeys.useDevice));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(CloudStorageKeys.unavailable), findsOneWidget);
    expect(preferences.values['settings.storage.location.v1'], 'icloud');
    expect((await locations.readCheckpoint()).valueOrNull, isNotNull);
  });
}

/// A recomposed-app stand-in; it replaces the whole app, so it brings its own
/// text direction.
Widget _stand(String label) =>
    Directionality(textDirection: TextDirection.ltr, child: Text(label));
