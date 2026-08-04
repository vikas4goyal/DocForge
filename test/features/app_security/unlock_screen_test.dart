/// Cubit and widget tests for the unlock screen.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_scanly/features/app_security/domain/app_lock.dart';
import 'package:doc_scanly/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:doc_scanly/features/app_security/presentation/cubit/app_lock_cubit.dart';
import 'package:doc_scanly/features/app_security/presentation/screens/unlock_screen.dart';
import 'package:doc_scanly/features/app_security/presentation/security_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> unlocked;

  setUp(() => unlocked = []);

  AppLockCubit build({
    AuthOutcome outcome = AuthOutcome.succeeded,
    bool enabled = true,
  }) => AppLockCubit(
    AuthenticateAppLock(FakeDeviceAuthenticator(outcome: outcome)),
    IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: enabled)),
    onUnlocked: () => unlocked.add(1),
  );

  group('AppLockCubit', () {
    blocTest<AppLockCubit, AppLockState>(
      'starts unknown, which hides content',
      build: build,
      verify: (cubit) {
        expect(cubit.state.status, AppLockStatus.unknown);
        expect(cubit.state.hidesContent, isTrue);
      },
    );

    blocTest<AppLockCubit, AppLockState>(
      'an enabled lock settles to locked',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AppLockState>()
            .having((s) => s.status, 'status', AppLockStatus.locked)
            .having((s) => s.hidesContent, 'hidesContent', isTrue),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'a disabled lock unlocks without the user doing anything',
      build: () => build(enabled: false),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, AppLockStatus.unlocked);
        expect(unlocked, hasLength(1));
      },
    );

    blocTest<AppLockCubit, AppLockState>(
      'unknown → locked → authenticating → unlocked',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.authenticate();
      },
      expect: () => [
        isA<AppLockState>().having(
          (s) => s.status,
          'status',
          AppLockStatus.locked,
        ),
        isA<AppLockState>().having(
          (s) => s.status,
          'status',
          AppLockStatus.authenticating,
        ),
        isA<AppLockState>().having(
          (s) => s.status,
          'status',
          AppLockStatus.unlocked,
        ),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'tells the gate once authentication succeeds',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.authenticate();
      },
      verify: (cubit) => expect(unlocked, hasLength(1)),
    );

    blocTest<AppLockCubit, AppLockState>(
      'a rejection returns to locked with a retryable message',
      build: () => build(outcome: AuthOutcome.rejected),
      act: (cubit) async {
        await cubit.load();
        await cubit.authenticate();
      },
      verify: (cubit) {
        expect(cubit.state.status, AppLockStatus.locked);
        expect(cubit.state.canRetry, isTrue);
        expect(cubit.state.message, isNotEmpty);
        // Nothing was revealed and the gate was never told.
        expect(cubit.state.hidesContent, isTrue);
        expect(unlocked, isEmpty);
      },
    );

    blocTest<AppLockCubit, AppLockState>(
      'a mechanism error leaves the app locked',
      build: () => build(outcome: AuthOutcome.error),
      act: (cubit) async {
        await cubit.load();
        await cubit.authenticate();
      },
      verify: (cubit) {
        expect(cubit.state.status, AppLockStatus.locked);
        expect(cubit.state.canRetry, isTrue);
        expect(unlocked, isEmpty);
      },
    );

    blocTest<AppLockCubit, AppLockState>(
      'nothing enrolled offers device setup rather than a retry',
      build: () => build(outcome: AuthOutcome.notEnrolled),
      act: (cubit) async {
        await cubit.load();
        await cubit.authenticate();
      },
      verify: (cubit) {
        expect(cubit.state.canRetry, isFalse);
        expect(cubit.state.needsDeviceSetup, isTrue);
        expect(cubit.state.status, AppLockStatus.locked);
      },
    );

    blocTest<AppLockCubit, AppLockState>(
      'a fresh attempt clears the previous message',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.authenticate();
      },
      verify: (cubit) => expect(cubit.state.message, isNull),
    );
  });

  group('UnlockScreen', () {
    Future<AppLockCubit> pump(
      WidgetTester tester,
      AppLockState state, {
      Brightness brightness = Brightness.light,
      Size viewport = const Size(600, 1000),
      VoidCallback? onOpenSettings,
    }) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = build();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: BlocProvider<AppLockCubit>.value(
            value: cubit,
            // The automatic prompt is off: in a test it would fire on every
            // render and race the state being seeded.
            child: UnlockScreen(
              promptOnOpen: false,
              onOpenSettings: onOpenSettings,
            ),
          ),
        ),
      );

      cubit.emit(state);
      // Two bounded pumps: a Cubit delivers on a microtask.
      await tester.pump();
      await tester.pump();

      return cubit;
    }

    const locked = AppLockState.initial();

    testWidgets('shows the lock screen and its unlock control', (tester) async {
      await pump(tester, locked.copyWith(status: AppLockStatus.locked));

      expect(find.byKey(SecurityKeys.unlockScreen), findsOneWidget);
      expect(find.byKey(SecurityKeys.unlockRetryButton), findsOneWidget);
      expect(find.text(AppLockRules.unlockTitle), findsOneWidget);
    });

    testWidgets('renders no document content whatsoever', (tester) async {
      // The strongest assertion available at this level: the screen has no
      // document reader to leak from, and nothing on it names a document.
      await pump(tester, locked.copyWith(status: AppLockStatus.locked));

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('the unlock control starts authentication', (tester) async {
      final cubit = await pump(
        tester,
        locked.copyWith(status: AppLockStatus.locked),
      );

      await tester.tap(find.byKey(SecurityKeys.unlockRetryButton));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.status, AppLockStatus.unlocked);
    });

    testWidgets('shows progress while the system prompt is up', (tester) async {
      await pump(tester, locked.copyWith(status: AppLockStatus.authenticating));

      expect(find.byKey(SecurityKeys.authenticatingIndicator), findsOneWidget);
      // No retry while a prompt is already showing: two prompts at once is a
      // platform error, not a faster unlock.
      expect(find.byKey(SecurityKeys.unlockRetryButton), findsNothing);
    });

    testWidgets('a failed attempt keeps the app locked and says so', (
      tester,
    ) async {
      await pump(
        tester,
        locked.copyWith(
          status: AppLockStatus.locked,
          lastOutcome: AuthOutcome.rejected,
        ),
      );

      expect(find.byKey(SecurityKeys.unlockScreen), findsOneWidget);
      expect(find.byKey(SecurityKeys.unlockMessage), findsOneWidget);
      expect(find.byKey(SecurityKeys.unlockRetryButton), findsOneWidget);
    });

    testWidgets('nothing enrolled offers settings instead of a retry', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        locked.copyWith(
          status: AppLockStatus.locked,
          lastOutcome: AuthOutcome.notEnrolled,
        ),
        onOpenSettings: () => opened++,
      );

      expect(find.byKey(SecurityKeys.unlockRetryButton), findsNothing);

      await tester.tap(find.byKey(SecurityKeys.openSettingsButton));
      await tester.pump();

      expect(opened, 1);
    });

    testWidgets('offers no settings control without a handler', (tester) async {
      await pump(
        tester,
        locked.copyWith(
          status: AppLockStatus.locked,
          lastOutcome: AuthOutcome.notEnrolled,
        ),
      );

      expect(find.byKey(SecurityKeys.openSettingsButton), findsNothing);
    });

    group('accessibility', () {
      testWidgets('the unlock control describes what it does', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, locked.copyWith(status: AppLockStatus.locked));

        expect(
          find.bySemanticsLabel(AppLockRules.unlockSemanticsLabel),
          findsOneWidget,
        );

        handle.dispose();
      });

      testWidgets('a rejection is announced rather than merely shown', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          locked.copyWith(
            status: AppLockStatus.locked,
            lastOutcome: AuthOutcome.rejected,
          ),
        );

        expect(
          tester.getSemantics(find.byKey(SecurityKeys.unlockMessage)),
          isSemantics(isLiveRegion: true),
        );

        handle.dispose();
      });

      testWidgets('every control meets the minimum touch target', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, locked.copyWith(status: AppLockStatus.locked));

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        handle.dispose();
      });

      testWidgets('passes the contrast guideline in dark mode', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          locked.copyWith(
            status: AppLockStatus.locked,
            lastOutcome: AuthOutcome.rejected,
          ),
          brightness: Brightness.dark,
        );

        await expectLater(tester, meetsGuideline(textContrastGuideline));

        handle.dispose();
      });

      testWidgets('survives a tablet viewport at double text scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1024, 1366);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final cubit = build();
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 2,
              maxScaleFactor: 2,
              child: child!,
            ),
            home: BlocProvider<AppLockCubit>.value(
              value: cubit,
              child: const UnlockScreen(promptOnOpen: false),
            ),
          ),
        );
        cubit.emit(locked.copyWith(status: AppLockStatus.locked));
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });
  });
}
