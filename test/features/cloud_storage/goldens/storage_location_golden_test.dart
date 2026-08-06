/// Golden coverage for the iOS-only storage-location screen.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_previews.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _phone = Size(390, 844);
const _tablet = Size(1024, 1366);

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    Size size = _phone,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        builder: (context, appChild) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: appChild!,
        ),
        home: child,
      ),
    );
    await tester.pump();
  }

  testWidgets('local phone light', (tester) async {
    await pumpAt(tester, storageLocationLocal());
    await expectLater(
      find.byType(StorageLocationScreen),
      matchesGoldenFile('storage_location_phone_light.png'),
    );
  });

  testWidgets('iCloud phone dark', (tester) async {
    await pumpAt(
      tester,
      storageLocationICloudDark(),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(StorageLocationScreen),
      matchesGoldenFile('storage_location_phone_dark.png'),
    );
  });

  testWidgets('loading phone light', (tester) async {
    await pumpAt(tester, storageLocationLoading());
    await expectLater(
      find.byType(StorageLocationScreen),
      matchesGoldenFile('storage_location_loading_light.png'),
    );
  });

  testWidgets('migration tablet light', (tester) async {
    await pumpAt(tester, storageLocationMigration(), size: _tablet);
    await expectLater(
      find.byType(StorageLocationScreen),
      matchesGoldenFile('storage_location_migration_tablet_light.png'),
    );
  });

  testWidgets('unavailable phone light', (tester) async {
    await pumpAt(tester, storageLocationUnavailable());
    await expectLater(
      find.byType(StorageLocationScreen),
      matchesGoldenFile('storage_location_unavailable_light.png'),
    );
  });

  testWidgets('error phone dark', (tester) async {
    await pumpAt(tester, storageLocationError(), brightness: Brightness.dark);
    await expectLater(
      find.byType(StorageLocationScreen),
      matchesGoldenFile('storage_location_error_dark.png'),
    );
  });

  testWidgets('large text remains scrollable', (tester) async {
    await pumpAt(tester, storageLocationConfirmation(), textScale: 1.6);
    await expectLater(
      find.byType(StorageLocationScreen),
      matchesGoldenFile('storage_location_large_text.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
