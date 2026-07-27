/// Widget previews for the application lock.
///
/// Every preview is fed by fixtures through a Cubit frozen at a chosen state,
/// and the automatic prompt is off: a preview that raised a biometric dialogue
/// would do so while the developer was looking at a widget (`design.md` §15).
library;

import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_forge/features/app_security/domain/app_lock.dart';
import 'package:doc_forge/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:doc_forge/features/app_security/presentation/cubit/app_lock_cubit.dart';
import 'package:doc_forge/features/app_security/presentation/screens/unlock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A Cubit frozen at [_seeded], with authentication inert.
class _PreviewAppLockCubit extends AppLockCubit {
  _PreviewAppLockCubit(this._seeded)
    : super(
        AuthenticateAppLock(FakeDeviceAuthenticator()),
        IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: true)),
        onUnlocked: _ignore,
      );

  static void _ignore() {}

  final AppLockState _seeded;

  @override
  AppLockState get state => _seeded;

  @override
  Future<void> load() async {}

  @override
  Future<void> authenticate() async {}
}

Widget _screen(AppLockState state) => BlocProvider<AppLockCubit>(
  create: (_) => _PreviewAppLockCubit(state),
  child: const UnlockScreen(promptOnOpen: false),
);

const _locked = AppLockState.initial();

// ---------------------------------------------------------------------------
// Unlock screen
// ---------------------------------------------------------------------------

/// The lock screen as it first appears.
@Preview(name: 'Unlock — default', group: 'Security', theme: appPreviewTheme)
Widget unlockDefault() =>
    _screen(_locked.copyWith(status: AppLockStatus.locked));

/// The system prompt is up — this screen's loading state.
@Preview(name: 'Unlock — loading', group: 'Security', theme: appPreviewTheme)
Widget unlockLoading() =>
    _screen(_locked.copyWith(status: AppLockStatus.authenticating));

/// Before the stored configuration has been read — its empty state.
///
/// Renders as locked, deliberately: the safe answer while the answer is
/// unknown is to reveal nothing.
@Preview(name: 'Unlock — unknown', group: 'Security', theme: appPreviewTheme)
Widget unlockUnknown() => _screen(_locked);

/// Authentication was rejected.
@Preview(name: 'Unlock — error', group: 'Security', theme: appPreviewTheme)
Widget unlockRejected() => _screen(
  _locked.copyWith(
    status: AppLockStatus.locked,
    lastOutcome: AuthOutcome.rejected,
  ),
);

/// The mechanism itself failed.
@Preview(
  name: 'Unlock — mechanism error',
  group: 'Security',
  theme: appPreviewTheme,
)
Widget unlockError() => _screen(
  _locked.copyWith(
    status: AppLockStatus.locked,
    lastOutcome: AuthOutcome.error,
  ),
);

/// Nothing is enrolled on the device — the longest message this screen shows.
@Preview(
  name: 'Unlock — long content',
  group: 'Security',
  theme: appPreviewTheme,
)
Widget unlockNotEnrolled() => BlocProvider<AppLockCubit>(
  create: (_) => _PreviewAppLockCubit(
    _locked.copyWith(
      status: AppLockStatus.locked,
      lastOutcome: AuthOutcome.notEnrolled,
    ),
  ),
  child: UnlockScreen(promptOnOpen: false, onOpenSettings: () {}),
);

/// The lock screen on a phone, light.
@Preview(
  name: 'Unlock — phone, light',
  group: 'Security',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget unlockPhoneLight() =>
    _screen(_locked.copyWith(status: AppLockStatus.locked));

/// The lock screen on a phone, dark.
@Preview(
  name: 'Unlock — phone, dark',
  group: 'Security',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget unlockPhoneDark() =>
    _screen(_locked.copyWith(status: AppLockStatus.locked));

/// The lock screen on a tablet, light.
@Preview(
  name: 'Unlock — tablet, light',
  group: 'Security',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget unlockTabletLight() =>
    _screen(_locked.copyWith(status: AppLockStatus.locked));

/// The lock screen on a tablet, dark.
@Preview(
  name: 'Unlock — tablet, dark',
  group: 'Security',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget unlockTabletDark() =>
    _screen(_locked.copyWith(status: AppLockStatus.locked));
