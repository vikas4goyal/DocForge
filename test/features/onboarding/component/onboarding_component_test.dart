/// Tier 2 — onboarding over its real Cubit and real use cases.
///
/// Onboarding is a three-screen sequence whose whole job is to end in a written
/// flag. A widget test that stubbed the Cubit could prove each screen renders
/// and still leave the flag unwritten — which is the one failure that matters,
/// because the router reads that flag on every launch and an unwritten one puts
/// the user back at the welcome screen forever.
library;

import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_scanly/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_scanly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_scanly/features/onboarding/presentation/onboarding_keys.dart';
import 'package:doc_scanly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';

void main() {
  late InMemoryPreferenceStore preferences;
  late FakePermissionService permissions;
  late int finishedCount;

  setUp(() {
    preferences = InMemoryPreferenceStore();
    permissions = FakePermissionService();
    finishedCount = 0;
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await pumpComponent(
      tester,
      OnboardingScreen(onFinished: () => finishedCount++),
      providers: [
        BlocProvider(
          create: (_) => OnboardingCubit(
            // Real use cases over a real repository, with only the preference
            // store substituted — so "the flag was written" is a claim about
            // the production write path.
            CompleteOnboarding(OnboardingRepositoryImpl(preferences)),
            RequestOnboardingCameraPermission(permissions),
          ),
        ),
      ],
    );
    await settleComponent(tester);
  }

  group('OnboardingScreen over its real state machine', () {
    testWidgets('walks welcome, privacy, permission in order', (tester) async {
      await pumpOnboarding(tester);

      expectVisible(OnboardingKeys.welcomeScreen);
      await tester.tap(find.byKey(OnboardingKeys.welcomeContinueButton));
      await settleComponent(tester);

      expectVisible(OnboardingKeys.privacyScreen);
      await tester.tap(find.byKey(OnboardingKeys.privacyContinueButton));
      await settleComponent(tester);

      expectVisible(OnboardingKeys.permissionScreen);
    });

    testWidgets('skipping the permission still completes onboarding', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await tester.tap(find.byKey(OnboardingKeys.welcomeContinueButton));
      await settleComponent(tester);
      await tester.tap(find.byKey(OnboardingKeys.privacyContinueButton));
      await settleComponent(tester);
      await tester.tap(find.byKey(OnboardingKeys.permissionSkipButton));
      await settleComponent(tester);

      // The flag, not the callback, is what the router reads on the next
      // launch. Asserting only on the callback would pass against a build that
      // never persisted anything and sent the user back to welcome forever.
      final stored = await preferences.readBool(
        PreferenceKeys.onboardingComplete,
      );
      expect(
        stored.valueOrNull,
        isTrue,
        reason: 'Completing onboarding must write the flag the router reads.',
      );
      expect(finishedCount, 1);
    });

    testWidgets('the privacy step states all three promises', (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.byKey(OnboardingKeys.welcomeContinueButton));
      await settleComponent(tester);

      // Named in the spec, and the reason a user grants camera access at the
      // next step: a build that dropped one would be asking for permission it
      // had not earned.
      expectVisible(OnboardingKeys.privacyLocalStorageStatement);
      expectVisible(OnboardingKeys.privacyNoUploadStatement);
      expectVisible(OnboardingKeys.privacyOfflineStatement);
    });
  });
}
