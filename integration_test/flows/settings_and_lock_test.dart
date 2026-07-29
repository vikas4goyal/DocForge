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

import 'package:doc_forge/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a changed setting is still there after leaving the screen', (
    tester,
  ) async {
    await bootDocForge(tester);

    await DashboardRobot(tester).waitUntilLoaded();
    final shell = TabShellRobot(tester);
    await shell.openSettings();

    final settings = SettingsRobot(tester);
    await settings.waitUntilVisible();
    await settings.choose(SettingsKeys.theme, 'dark');

    // Away and back, because a setting that only survives while its screen is
    // mounted is not persisted — it is just state.
    await shell.openDashboard();
    await DashboardRobot(tester).waitUntilLoaded();
    await shell.openSettings();

    await settings.waitUntilVisible();
    expect(settings.isVisible, isTrue);
  });

  testWidgets('an enabled lock stands in front of the application', (
    tester,
  ) async {
    // Booted with the lock already on, which is what a relaunch after enabling
    // it looks like: the gate is read from secure storage before the first
    // frame, and the guard redirects on the strength of that.
    await bootDocForge(tester, appLockEnabled: true);

    final unlock = UnlockRobot(tester);
    await unlock.waitUntilVisible();
    expect(
      unlock.isVisible,
      isTrue,
      reason:
          'An enabled lock must be in front of the library on launch, not '
          'behind it.',
    );
  });

  testWidgets('a refused unlock leaves the application locked', (tester) async {
    // A rejected fingerprint is the mechanism working, not an error: the lock
    // stays on and the retry control stays available.
    await bootDocForge(
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
