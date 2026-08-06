/// Golden tests for the unlock screen.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_scanly/features/app_security/domain/app_lock.dart';
import 'package:doc_scanly/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:doc_scanly/features/app_security/presentation/cubit/app_lock_cubit.dart';
import 'package:doc_scanly/features/app_security/presentation/screens/unlock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

/// A Cubit frozen at a chosen state.
class _SeededCubit extends AppLockCubit {
  _SeededCubit(this._seeded)
    : super(
        AuthenticateAppLock(FakeDeviceAuthenticator()),
        IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: true)),
        onUnlocked: _ignore,
      );

  static void _ignore() {}

  final AppLockState _seeded;

  @override
  AppLockState get state => _seeded;
}

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    AppLockState state, {
    Brightness brightness = Brightness.light,
    bool offerSettings = false,
  }) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _SeededCubit(state);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: UnlockScreen(
            promptOnOpen: false,
            onOpenSettings: offerSettings ? () {} : null,
          ),
        ),
      ),
    );

    // Bounded rather than `pumpAndSettle`: the authenticating state shows an
    // indefinite progress indicator, which never settles.
    await tester.pump();
    await tester.pump();
  }

  const locked = AppLockState.initial();
  final ready = locked.copyWith(status: AppLockStatus.locked);

  group('unlock goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, _phone, ready);

      await expectLater(
        find.byType(UnlockScreen),
        matchesGoldenFile('unlock_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, _phone, ready, brightness: Brightness.dark);

      await expectLater(
        find.byType(UnlockScreen),
        matchesGoldenFile('unlock_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, _tablet, ready);

      await expectLater(
        find.byType(UnlockScreen),
        matchesGoldenFile('unlock_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, _tablet, ready, brightness: Brightness.dark);

      await expectLater(
        find.byType(UnlockScreen),
        matchesGoldenFile('unlock_tablet_dark.png'),
      );
    });

    testWidgets('rejected, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        ready.copyWith(lastOutcome: AuthOutcome.rejected),
      );

      await expectLater(
        find.byType(UnlockScreen),
        matchesGoldenFile('unlock_rejected_light.png'),
      );
    });

    testWidgets('not enrolled, dark', (tester) async {
      await pumpAt(
        tester,
        _phone,
        ready.copyWith(lastOutcome: AuthOutcome.notEnrolled),
        brightness: Brightness.dark,
        offerSettings: true,
      );

      await expectLater(
        find.byType(UnlockScreen),
        matchesGoldenFile('unlock_not_enrolled_dark.png'),
      );
    });

    testWidgets('authenticating, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        locked.copyWith(status: AppLockStatus.authenticating),
      );

      await expectLater(
        find.byType(UnlockScreen),
        matchesGoldenFile('unlock_authenticating_light.png'),
      );
    });
  });
}
