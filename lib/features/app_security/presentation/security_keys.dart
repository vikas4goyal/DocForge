/// Widget keys for the application lock.
///
/// The values are normative — they come from `specs/app-security/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the unlock screen.
abstract final class SecurityKeys {
  /// Root of the unlock screen.
  static const unlockScreen = Key('security_unlock_screen');

  /// The control that starts, or retries, authentication.
  static const unlockRetryButton = Key('security_unlock_retry_button');

  /// The message shown after a failed or unavailable authentication.
  static const unlockMessage = Key('security_unlock_message');

  /// The control that opens the system settings when nothing is enrolled.
  static const openSettingsButton = Key('security_open_settings_button');

  /// The indicator shown while the system prompt is up.
  static const authenticatingIndicator = Key('security_authenticating');

  /// The wrapper that re-locks the application when it leaves the foreground.
  ///
  /// Keyed even though it renders nothing of its own: it wraps the whole
  /// application, and a flow that asserts the lock re-engages needs to prove it
  /// is mounted rather than infer it from the lock happening to work.
  static const appLockObserver = Key('security_app_lock_observer');
}
