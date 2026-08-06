/// Golden coverage for the platform-adaptive application tab bar.
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/app_shell/presentation/screens/app_tab_scaffold.dart';
import 'package:doc_scanly/features/app_shell/presentation/shell_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    required TargetPlatform platform,
    required Brightness brightness,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
    await tester.pumpWidget(
      MaterialApp(
        theme: base.copyWith(platform: platform),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewPadding: EdgeInsets.only(
              bottom: platform == TargetPlatform.iOS ? 34 : 0,
            ),
          ),
          child: child!,
        ),
        home: AppTabScaffold(
          tab: AppTab.dashboard,
          onTabSelected: (_) {},
          onCreate: () {},
          child: const Center(child: Text('Dashboard')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('iOS phone ${brightness.name}', (tester) async {
      await pumpShell(
        tester,
        size: const Size(390, 844),
        platform: TargetPlatform.iOS,
        brightness: brightness,
      );

      await expectLater(
        find.byKey(ShellKeys.tabScaffold),
        matchesGoldenFile('app_tab_ios_phone_${brightness.name}.png'),
      );
    });

    testWidgets('Android tablet ${brightness.name}', (tester) async {
      await pumpShell(
        tester,
        size: const Size(1024, 768),
        platform: TargetPlatform.android,
        brightness: brightness,
      );

      await expectLater(
        find.byKey(ShellKeys.tabScaffold),
        matchesGoldenFile('app_tab_android_tablet_${brightness.name}.png'),
      );
    });
  }
}
