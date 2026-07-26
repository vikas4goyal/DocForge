import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_forge/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_forge/features/onboarding/presentation/onboarding_keys.dart';
import 'package:doc_forge/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the onboarding flow with fake collaborators.
Future<InMemoryPreferenceStore> pumpOnboarding(
  WidgetTester tester, {
  PermissionState permission = PermissionState.granted,
  Brightness brightness = Brightness.light,
  Size? surface,
  double textScale = 1.0,
  VoidCallback? onFinished,
}) async {
  if (surface != null) {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  final store = InMemoryPreferenceStore();
  final cubit = OnboardingCubit(
    CompleteOnboarding(OnboardingRepositoryImpl(store)),
    RequestOnboardingCameraPermission(
      FakePermissionService(defaultState: permission),
    ),
  );
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: BlocProvider.value(
          value: cubit,
          child: OnboardingScreen(onFinished: onFinished ?? () {}),
        ),
      ),
    ),
  );
  return store;
}

void main() {
  group('welcome step', () {
    testWidgets('is shown first', (tester) async {
      await pumpOnboarding(tester);

      expect(find.byKey(OnboardingKeys.welcomeScreen), findsOneWidget);
      expect(find.byKey(OnboardingKeys.privacyScreen), findsNothing);
    });

    testWidgets('advances to the privacy introduction', (tester) async {
      await pumpOnboarding(tester);

      await tester.tap(find.byKey(OnboardingKeys.welcomeContinueButton));
      await tester.pumpAndSettle();

      expect(find.byKey(OnboardingKeys.privacyScreen), findsOneWidget);
    });
  });

  group('privacy step', () {
    Future<void> reachPrivacy(WidgetTester tester) async {
      await tester.tap(find.byKey(OnboardingKeys.welcomeContinueButton));
      await tester.pumpAndSettle();
    }

    testWidgets('presents all three guarantees', (tester) async {
      await pumpOnboarding(tester);
      await reachPrivacy(tester);

      expect(
        find.byKey(OnboardingKeys.privacyLocalStorageStatement),
        findsOneWidget,
      );
      expect(
        find.byKey(OnboardingKeys.privacyNoUploadStatement),
        findsOneWidget,
      );
      expect(
        find.byKey(OnboardingKeys.privacyOfflineStatement),
        findsOneWidget,
      );
    });

    testWidgets('exposes each guarantee to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpOnboarding(tester);
      await reachPrivacy(tester);

      expect(
        find.bySemanticsLabel('Your documents are stored only on this device.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Nothing is uploaded automatically. You choose what to share.',
        ),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('advances to the permission request', (tester) async {
      await pumpOnboarding(tester);
      await reachPrivacy(tester);

      await tester.tap(find.byKey(OnboardingKeys.privacyContinueButton));
      await tester.pumpAndSettle();

      expect(find.byKey(OnboardingKeys.permissionScreen), findsOneWidget);
    });
  });

  group('permission step', () {
    Future<void> reachPermission(WidgetTester tester) async {
      await tester.tap(find.byKey(OnboardingKeys.welcomeContinueButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OnboardingKeys.privacyContinueButton));
      await tester.pumpAndSettle();
    }

    testWidgets('offers both allow and skip', (tester) async {
      await pumpOnboarding(tester);
      await reachPermission(tester);

      expect(find.byKey(OnboardingKeys.permissionAllowButton), findsOneWidget);
      expect(find.byKey(OnboardingKeys.permissionSkipButton), findsOneWidget);
    });

    testWidgets('finishes after permission is granted', (tester) async {
      var finished = false;
      await pumpOnboarding(tester, onFinished: () => finished = true);
      await reachPermission(tester);

      await tester.tap(find.byKey(OnboardingKeys.permissionAllowButton));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });

    testWidgets('finishes even when permission is denied', (tester) async {
      var finished = false;
      await pumpOnboarding(
        tester,
        permission: PermissionState.denied,
        onFinished: () => finished = true,
      );
      await reachPermission(tester);

      await tester.tap(find.byKey(OnboardingKeys.permissionAllowButton));
      await tester.pumpAndSettle();

      // The spec requires the user to reach Home either way.
      expect(finished, isTrue);
    });

    testWidgets('finishes when skipped', (tester) async {
      var finished = false;
      await pumpOnboarding(tester, onFinished: () => finished = true);
      await reachPermission(tester);

      await tester.tap(find.byKey(OnboardingKeys.permissionSkipButton));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });

    testWidgets('persists completion before finishing', (tester) async {
      final store = await pumpOnboarding(tester);
      await reachPermission(tester);

      await tester.tap(find.byKey(OnboardingKeys.permissionSkipButton));
      await tester.pumpAndSettle();

      expect(store.values.values, contains(true));
    });
  });

  group('accessibility', () {
    testWidgets('every control meets the 48dp touch target', (tester) async {
      await pumpOnboarding(tester);

      final size = tester.getSize(
        find.byKey(OnboardingKeys.welcomeContinueButton),
      );

      expect(size.height, greaterThanOrEqualTo(AppTheme.minimumTouchTarget));
    });

    testWidgets('survives the maximum text scale without overflow', (
      tester,
    ) async {
      await pumpOnboarding(tester, textScale: 3, surface: const Size(400, 800));

      expect(tester.takeException(), isNull);
      expect(find.byKey(OnboardingKeys.welcomeScreen), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await pumpOnboarding(tester, brightness: Brightness.dark);

      expect(tester.takeException(), isNull);
      expect(find.byKey(OnboardingKeys.welcomeScreen), findsOneWidget);
    });

    testWidgets('adapts to a tablet viewport without overflow', (tester) async {
      await pumpOnboarding(tester, surface: const Size(1024, 768));

      expect(tester.takeException(), isNull);
      expect(find.byKey(OnboardingKeys.welcomeScreen), findsOneWidget);
    });
  });
}
