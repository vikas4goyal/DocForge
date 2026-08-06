/// The rules governing the application lock.
///
/// Pure: no Flutter, no plugins, no storage. What the lock screen says, when
/// re-authentication is required, and what each authentication outcome means
/// are decisions — and the biometric plugin cannot run in the host test VM, so
/// every one of them is tested here rather than through it.
library;

import 'package:doc_scanly/core/failures/failure.dart';

/// What the authentication mechanism reported.
enum AuthOutcome {
  /// The user proved who they are.
  succeeded,

  /// The user was rejected, or dismissed the prompt.
  ///
  /// Not an error: a wrong fingerprint is the mechanism working. The lock stays
  /// on and the retry control stays available.
  rejected,

  /// Nothing is enrolled on the device — no biometric and no device credential.
  ///
  /// Distinct from [rejected] because it is the one outcome the user cannot fix
  /// by trying again; it needs a change in the system settings.
  notEnrolled,

  /// The mechanism itself failed.
  error,
}

/// Where the lock is in its lifecycle.
///
/// [unknown] exists because the very first frame happens before secure storage
/// has been read, and a gate that answered "unlocked" in that instant would let
/// a document list render for one frame behind an enabled lock.
enum AppLockStatus {
  /// The stored configuration has not been read yet.
  unknown,

  /// The lock is enabled and this session has not authenticated.
  locked,

  /// Authentication is in progress.
  authenticating,

  /// The session is authenticated, or the lock is disabled.
  unlocked,
}

/// Decisions about the application lock.
abstract final class AppLockRules {
  /// The reason shown by the system authentication prompt.
  ///
  /// Required by both platforms and shown inside the system dialogue, so it has
  /// to say what is being unlocked rather than merely "authenticate".
  static const promptReason = 'Unlock DocScanly to open your documents';

  /// The reason shown when confirming a change to the lock itself.
  static const changeLockReason = 'Confirm it is you before changing the lock';

  /// The title of the unlock screen.
  static const unlockTitle = 'DocScanly is locked';

  /// The instruction shown beneath it.
  static const unlockInstruction =
      'Authenticate to open your documents. Nothing is shown until you do.';

  /// The label of the control that starts authentication.
  static const unlockActionLabel = 'Unlock';

  /// What a screen reader announces for the unlock control.
  static const unlockSemanticsLabel =
      'Unlock DocScanly using biometrics or your device passcode';

  /// The message shown for [outcome], or null when there is nothing to say.
  ///
  /// A rejection gets a message rather than silence: a prompt that vanishes
  /// with no explanation reads as a crash.
  static String? messageFor(AuthOutcome outcome) => switch (outcome) {
    AuthOutcome.succeeded => null,
    AuthOutcome.rejected =>
      'That did not match. Try again, or use your device passcode.',
    AuthOutcome.notEnrolled =>
      'This device has no biometrics or passcode set up. Add one in the '
          'device settings to use the app lock.',
    AuthOutcome.error =>
      'Authentication could not be completed. Please try again.',
  };

  /// Whether [outcome] leaves the user able to try again here.
  ///
  /// Everything except "nothing is enrolled", which only the system settings
  /// can resolve — offering a retry for it would be a button that cannot work.
  static bool canRetry(AuthOutcome outcome) =>
      outcome != AuthOutcome.notEnrolled;

  /// Whether [outcome] should send the user to the system settings.
  static bool needsDeviceSetup(AuthOutcome outcome) =>
      outcome == AuthOutcome.notEnrolled;

  /// The failure carrying [outcome] to the presentation layer.
  static Failure failureFor(AuthOutcome outcome) => switch (outcome) {
    AuthOutcome.succeeded => const Failure.unexpected(
      debugDetail: 'success is not a failure',
    ),
    AuthOutcome.rejected => const Failure.auth(),
    AuthOutcome.notEnrolled => const Failure.auth(
      rejected: false,
      notEnrolled: true,
    ),
    AuthOutcome.error => const Failure.auth(rejected: false),
  };

  /// Whether the lock should engage given its configuration and session state.
  ///
  /// The single definition of "locked", used by the gate and by the resume
  /// handler alike. Two definitions is how an application ends up locked on
  /// launch but not on resume.
  static bool shouldLock({
    required bool isEnabled,
    required bool isSessionAuthenticated,
  }) => isEnabled && !isSessionAuthenticated;

  /// Whether the lock status is settled enough for the router to act on.
  ///
  /// The router must not treat [AppLockStatus.unknown] as unlocked; it holds at
  /// the lock screen until the stored configuration has been read.
  static bool isResolved(AppLockStatus status) =>
      status != AppLockStatus.unknown;

  /// Whether [status] means content must stay hidden.
  static bool hidesContent(AppLockStatus status) => switch (status) {
    AppLockStatus.unlocked => false,
    // Deliberately includes `unknown`: before the configuration has been read,
    // the safe answer is "hidden". Guessing the other way shows a document list
    // for one frame behind an enabled lock.
    _ => true,
  };
}
