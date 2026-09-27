/// Widget keys for the onboarding feature.
///
/// Declared as constants so implementation and tests share one source of truth
/// and a rename is a compile error rather than a silently failing test. The
/// values are normative — they come from `specs/onboarding/spec.md` and are
/// what automated UI tests bind to.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the onboarding screens.
abstract final class OnboardingKeys {
  /// Root of the welcome screen.
  static const welcomeScreen = Key('onboarding_welcome_screen');

  /// Control advancing from welcome to the privacy introduction.
  static const welcomeContinueButton = Key(
    'onboarding_welcome_continue_button',
  );

  /// Root of the privacy and offline introduction screen.
  static const privacyScreen = Key('onboarding_privacy_screen');

  /// Control advancing from the privacy introduction to the permission step.
  static const privacyContinueButton = Key(
    'onboarding_privacy_continue_button',
  );

  /// Root of the camera permission screen.
  static const permissionScreen = Key('onboarding_permission_screen');

  /// Control that triggers the camera permission request.
  static const permissionAllowButton = Key(
    'onboarding_permission_allow_button',
  );

  /// Control that skips the permission request entirely.
  static const permissionSkipButton = Key('onboarding_permission_skip_button');

  /// Statement that documents are stored only on the device.
  static const privacyLocalStorageStatement = Key(
    'onboarding_privacy_local_storage',
  );

  /// Statement that no document is uploaded automatically.
  static const privacyNoUploadStatement = Key('onboarding_privacy_no_upload');

  /// Statement that scanning and OCR work offline.
  static const privacyOfflineStatement = Key('onboarding_privacy_offline');
}

/// The privacy step's storage and upload statements.
///
/// Held as constants so tests assert on one string, and so a change to a
/// privacy promise is a deliberate edit rather than a copy tweak in a widget.
abstract final class OnboardingCopy {
  /// Where documents live when the library is always on the device (Android).
  static const storageStatementDevice =
      'Your documents are stored only on this device.';

  /// Where documents live when the library uses iCloud whenever it is on (iOS).
  static const storageStatementICloud =
      'Your documents are kept in your own iCloud Drive when iCloud is on, '
      'otherwise only on this device.';

  /// The upload promise when nothing leaves the device automatically.
  static const noUploadStatement =
      'Nothing is uploaded automatically. You choose what to share.';

  /// The upload promise when the user's own iCloud Drive holds the library.
  static const noServerStatement =
      'Nothing is sent to DocScanly servers — we don’t have any.';
}
