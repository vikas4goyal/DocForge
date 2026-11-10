/// Golden coverage for the startup migration gate.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_migration_gate_previews.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/cloud_migration_gate_screen.dart';
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

  testWidgets('copying phone light', (tester) async {
    await pumpAt(tester, migrationGateCopying());
    await expectLater(
      find.byType(CloudMigrationGateScreen),
      matchesGoldenFile('cloud_migration_gate_copying_phone_light.png'),
    );
  });

  testWidgets('completed phone dark', (tester) async {
    await pumpAt(tester, migrationGateCompleted(), brightness: Brightness.dark);
    await expectLater(
      find.byType(CloudMigrationGateScreen),
      matchesGoldenFile('cloud_migration_gate_completed_phone_dark.png'),
    );
  });

  testWidgets('failed tablet light', (tester) async {
    await pumpAt(tester, migrationGateFailed(), size: _tablet);
    await expectLater(
      find.byType(CloudMigrationGateScreen),
      matchesGoldenFile('cloud_migration_gate_failed_tablet_light.png'),
    );
  });

  testWidgets('large text remains scrollable', (tester) async {
    await pumpAt(tester, migrationGateFailed(), textScale: 1.6);
    await expectLater(
      find.byType(CloudMigrationGateScreen),
      matchesGoldenFile('cloud_migration_gate_large_text.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
