/// Tier 2 coverage for the adaptive top-level tab shell.
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/app_shell/presentation/screens/app_tab_scaffold.dart';
import 'package:doc_scanly/features/app_shell/presentation/shell_keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';

class _StatefulShell extends StatefulWidget {
  const _StatefulShell({required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<_StatefulShell> createState() => _StatefulShellState();
}

class _StatefulShellState extends State<_StatefulShell> {
  AppTab tab = AppTab.dashboard;

  @override
  Widget build(BuildContext context) => AppTabScaffold(
    tab: tab,
    onTabSelected: (value) => setState(() => tab = value),
    onCreate: widget.onCreate,
    child: IndexedStack(
      index: tab.index,
      children: const [
        Text('Dashboard state', key: Key('dashboard_state')),
        Text('Settings state', key: Key('settings_state')),
      ],
    ),
  );
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      '$platform preserves destination state and Create is an action',
      (tester) async {
        var creates = 0;
        final baseTheme = AppTheme.light.copyWith(platform: platform);
        await pumpComponent(
          tester,
          _StatefulShell(onCreate: () => creates++),
          theme: baseTheme,
        );

        expect(find.byKey(const Key('dashboard_state')), findsOneWidget);
        await tester.tap(find.byKey(ShellKeys.settingsTab));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('settings_state')), findsOneWidget);

        await tester.tap(find.byKey(ShellKeys.createTab));
        await tester.pumpAndSettle();
        expect(creates, 1);
        expect(find.byKey(const Key('settings_state')), findsOneWidget);

        await tester.tap(find.byKey(ShellKeys.dashboardTab));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dashboard_state')), findsOneWidget);
        expect(
          platform == TargetPlatform.iOS
              ? find.byType(CupertinoTabBar)
              : find.byType(NavigationBar),
          findsOneWidget,
        );
      },
    );
  }
}
