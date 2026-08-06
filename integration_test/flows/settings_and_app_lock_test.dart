/// Flow — settings and the application lock.
///
/// Precondition: onboarding is complete.
///
/// What it proves: a setting the user changes is still there afterwards, and an
/// enabled lock actually stands in front of the application on the next launch.
/// The lock is the one setting where being wrong is a security problem rather
/// than an annoyance, and its gate is read once before the first frame — so a
/// gate that resolved late would show the library for a frame behind a lock the
/// user had switched on.
library;

import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a changed setting is still there after leaving the screen', (
    tester,
  ) async {
    final app = await bootDocScanly(tester, saveLocationDirectory: '/Exports');

    await DashboardRobot(tester).waitUntilLoaded();
    final shell = TabShellRobot(tester);
    await shell.openSettings();

    final settings = SettingsRobot(tester);
    await settings.waitUntilVisible();
    await settings.choose(SettingsKeys.theme, 'dark');
    await settings.choose(SettingsKeys.pdfQuality, PdfQuality.high.name);
    await settings.chooseDefaultSaveFolder();
    expect(
      (await app.dependencies.preferences.readString(
        PreferenceKeys.defaultSaveLocation,
      )).valueOrNull,
      '/Exports',
    );
    await settings.askForSaveLocationEachTime();
    expect(
      (await app.dependencies.preferences.readString(
        PreferenceKeys.defaultSaveLocation,
      )).valueOrNull,
      isNull,
    );
    await settings.openStorageDetails();
    await settings.closeDetails();
    await settings.revealPrivacyPolicy();
    expect(
      settings.privacyBottomClearance,
      greaterThanOrEqualTo(20),
      reason: 'Privacy Policy should not touch the tab bar or home indicator.',
    );

    // The theme is published to the application root, so choosing it is
    // visible immediately and everywhere — which is what the spec means by
    // "applies without a restart".
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
      reason:
          'Choosing a theme must apply it, not merely record it. A choice '
          'that changed nothing on screen would look broken to the user.',
    );

    // Away and back, because a setting that only survives while its screen is
    // mounted is not persisted — it is just state.
    await shell.openDashboard();
    await DashboardRobot(tester).waitUntilLoaded();
    await shell.openSettings();

    await settings.waitUntilVisible();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
      reason: 'The chosen theme must survive leaving the screen.',
    );
  });

  testWidgets('a successful unlock reaches the library', (tester) async {
    // Booted with the lock already on, which is what a relaunch after enabling
    // it looks like: the gate is read from secure storage before the first
    // frame, and the guard redirects on the strength of that.
    //
    // The screen prompts on mount and the substituted authenticator answers at
    // once, so the assertion is that the user *arrives* — waiting for the
    // unlock screen itself would be racing an animation that is already over.
    await bootDocScanly(tester, appLockEnabled: true);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(
      dashboard.isVisible,
      isTrue,
      reason:
          'Authenticating must let the user through to the library, not leave '
          'them sitting on the unlock screen — which is what happens when the '
          'gate is not told the lock was released.',
    );
  });

  testWidgets('a refused unlock leaves the application locked', (tester) async {
    // A rejected fingerprint is the mechanism working, not an error: the lock
    // stays on and the retry control stays available.
    await bootDocScanly(
      tester,
      appLockEnabled: true,
      unlocksSuccessfully: false,
    );

    final unlock = UnlockRobot(tester);
    await unlock.waitUntilVisible();

    expect(
      DashboardRobot(tester).isVisible,
      isFalse,
      reason: 'A refused unlock must not reveal the library behind it.',
    );
  });
}
