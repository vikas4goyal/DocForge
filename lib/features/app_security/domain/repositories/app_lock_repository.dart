/// The seams between the lock and the platform.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/app_security/domain/app_lock.dart';

/// Performs device authentication.
///
/// Returns an [AuthOutcome] rather than a bare boolean, because the four
/// outcomes lead to four different things happening: unlock, retry, send to
/// system settings, or report an error. Collapsing them to true/false is how a
/// device with nothing enrolled ends up being offered a retry that can never
/// succeed.
abstract interface class DeviceAuthenticator {
  /// Prompts for authentication, showing [reason] in the system dialogue.
  ///
  /// Biometrics first, with the device credential as fallback — which the spec
  /// requires and which is also what makes the lock usable on a device whose
  /// sensor is wet, covered or simply absent.
  Future<AuthOutcome> authenticate({required String reason});

  /// Whether any authentication method is available on this device.
  Future<bool> get isAvailable;
}

/// Stores whether the lock is enabled.
///
/// Backed by secure storage, never preferences: a flag in an unprotected file
/// can be flipped on a rooted device, which would disable the lock without
/// authenticating (`design.md` §8).
abstract interface class AppLockConfiguration {
  /// Whether the lock is currently enabled.
  ///
  /// Fails only when secure storage itself is unavailable; a *missing* value is
  /// a successful false, because a lock nobody has enabled is off.
  Future<Result<bool>> isEnabled();

  /// Enables or disables the lock.
  Future<Result<void>> setEnabled({required bool enabled});
}
