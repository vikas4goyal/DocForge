/// Widget tests for the tab bar.
library;

import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/app_shell/presentation/screens/app_tab_scaffold.dart';
import 'package:doc_forge/features/app_shell/presentation/shell_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<AppTab> selected;
  late int creates;

  setUp(() {
    selected = [];
    creates = 0;
  });

  Future<void> pumpScaffold(
    WidgetTester tester, {
    AppTab tab = AppTab.dashboard,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: AppTabScaffold(
          tab: tab,
          onTabSelected: selected.add,
          onCreate: () => creates++,
          child: Text('${tab.name} content'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('composition', () {
    testWidgets('shows both destinations and the create control', (
      tester,
    ) async {
      await pumpScaffold(tester);

      expect(find.byKey(ShellKeys.tabScaffold), findsOneWidget);
      expect(find.byKey(ShellKeys.dashboardTab), findsOneWidget);
      expect(find.byKey(ShellKeys.settingsTab), findsOneWidget);
      expect(find.byKey(ShellKeys.createTab), findsOneWidget);
    });

    testWidgets('renders the selected destination', (tester) async {
      await pumpScaffold(tester, tab: AppTab.settings);

      expect(find.text('settings content'), findsOneWidget);
    });
  });

  group('selecting', () {
    testWidgets('the dashboard destination', (tester) async {
      await pumpScaffold(tester, tab: AppTab.settings);

      await tester.tap(find.byKey(ShellKeys.dashboardTab));
      await tester.pumpAndSettle();

      expect(selected, [AppTab.dashboard]);
    });

    testWidgets('the settings destination', (tester) async {
      await pumpScaffold(tester);

      await tester.tap(find.byKey(ShellKeys.settingsTab));
      await tester.pumpAndSettle();

      // Settings is one tap from anywhere now, rather than reachable only by
      // tapping the storage card.
      expect(selected, [AppTab.settings]);
    });
  });

  group('create', () {
    testWidgets('starts a document rather than selecting a tab', (
      tester,
    ) async {
      await pumpScaffold(tester);

      await tester.tap(find.byKey(ShellKeys.createTab));
      await tester.pumpAndSettle();

      // A Create tab that stayed selected would leave the bar highlighting a
      // screen that is not there.
      expect(creates, 1);
      expect(selected, isEmpty);
    });
  });

  group('accessibility', () {
    testWidgets('each destination announces its selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScaffold(tester);

      expect(
        tester.getSemantics(find.byKey(ShellKeys.dashboardTab)),
        matchesSemantics(
          label: 'Dashboard',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the unselected destination says so', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScaffold(tester);

      expect(
        tester.getSemantics(find.byKey(ShellKeys.settingsTab)),
        matchesSemantics(
          label: 'Settings',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the create control is labelled', (tester) async {
      await pumpScaffold(tester);

      expect(find.byTooltip('Create PDF'), findsOneWidget);
    });

    testWidgets('every target meets the minimum touch size', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScaffold(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in light mode', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScaffold(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });
  });

  group('dark mode', () {
    testWidgets('distinguishes the selection by more than colour', (
      tester,
    ) async {
      await pumpScaffold(tester, brightness: Brightness.dark);

      // The filled icon marks the selection, so it survives for anyone who
      // cannot see the colour difference.
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
