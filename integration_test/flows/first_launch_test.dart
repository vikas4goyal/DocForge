/// Flow — first launch.
///
/// Precondition: nothing has ever been stored. Onboarding has not run, the lock
/// is off, the library is empty.
///
/// What it proves: a brand-new install completes onboarding and lands on the
/// dashboard. That sounds trivial and is not — cold start runs the guard's full
/// redirect chain, home → unlock → onboarding → home, with both gates read
/// before the first frame. A gate that resolved a moment late, or an onboarding
/// completion that did not update the in-memory gate, would bounce the user
/// straight back into the introduction they just finished.
library;

import 'dart:io';

import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/onboarding/presentation/onboarding_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a first-time user completes onboarding and reaches the '
      'dashboard', (tester) async {
    await bootDocScanly(tester, onboardingComplete: false);

    final onboarding = OnboardingRobot(tester);
    await onboarding.complete();

    // The assertion is the *dashboard*, not the absence of onboarding: a
    // redirect that sent the user to a blank route would also have made
    // onboarding disappear.
    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(dashboard.isVisible, isTrue);

    // A fresh install has nothing in it. Asserting this here is what stops a
    // later flow's "the document appears" from being satisfied by something
    // that was already there.
    expect(dashboard.isEmpty, isTrue);
  });

  testWidgets('on iOS with iCloud, a first-time user lands on an iCloud '
      'library without being asked', (tester) async {
    if (!Platform.isIOS) return;
    final cloud = ScriptedICloudPlatform();
    addTearDown(cloud.dispose);
    final app = await bootDocScanly(
      tester,
      onboardingComplete: false,
      iCloudPlatform: cloud,
      isIOS: true,
    );

    await OnboardingRobot(tester).complete();
    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();

    expect(dashboard.isEmpty, isTrue);
    final stored = await app.dependencies.preferences.readString(
      PreferenceKeys.libraryStorageLocation,
    );
    expect(stored.valueOrNull, StorageLocation.iCloud.id);
  });

  testWidgets('onboarding does not run again on the next launch', (
    tester,
  ) async {
    // The completion flag is what the guard reads, and it is the difference
    // between an introduction and an obstacle.
    await bootDocScanly(tester);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(dashboard.isVisible, isTrue);
  });

  testWidgets('the privacy step states what the spec requires it to state', (
    tester,
  ) async {
    await bootDocScanly(tester, onboardingComplete: false);

    final onboarding = OnboardingRobot(tester);
    await onboarding.openPrivacyStep();

    // Three specific promises, named in the onboarding spec: documents stay on
    // the device, nothing is uploaded, and scanning works offline. They are
    // the reason a user grants camera access at the next step, so a build that
    // silently dropped one would be asking for permission it had not earned.
    onboarding
      ..expectPresent(OnboardingKeys.privacyLocalStorageStatement)
      ..expectPresent(OnboardingKeys.privacyNoUploadStatement)
      ..expectPresent(OnboardingKeys.privacyOfflineStatement);
  });
}
