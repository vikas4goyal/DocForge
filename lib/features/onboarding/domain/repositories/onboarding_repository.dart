/// Persistence contract for onboarding completion.
///
/// Onboarding runs exactly once per installation, so the only state it owns is
/// a single durable flag. Keeping that behind an interface lets the use cases
/// be tested without a platform binding, and lets the router's gate read it
/// without knowing it comes from SharedPreferences.
library;

import 'package:doc_forge/core/failures/result.dart';

/// Reads and writes the onboarding-completed flag.
abstract interface class OnboardingRepository {
  /// Whether the user has completed onboarding.
  ///
  /// A missing flag means onboarding has never run, which is reported as
  /// `false` rather than a failure — that is the normal first-launch state.
  Future<Result<bool>> isComplete();

  /// Records that onboarding has been completed.
  ///
  /// Must succeed before the user is navigated to Home, or a relaunch would
  /// show onboarding again.
  Future<Result<void>> markComplete();
}
