/// Use cases for the onboarding flow.
///
/// The flow has exactly two business operations: ask whether onboarding is
/// still needed, and record that it is finished. Both live here rather than in
/// the Cubit, which only coordinates UI state.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Reports whether the first-launch flow still needs to run.
class IsOnboardingComplete {
  /// Creates the use case over [_repository].
  const IsOnboardingComplete(this._repository);

  final OnboardingRepository _repository;

  /// Returns whether onboarding has been completed.
  ///
  /// A read failure is reported as *not* complete: showing onboarding a second
  /// time is a minor annoyance, whereas skipping it would leave a user who has
  /// never granted camera permission on a Home screen whose primary action
  /// silently fails.
  Future<bool> call() async {
    final result = await _repository.isComplete();
    return result.getOrElse(false);
  }
}

/// Records that the user has finished onboarding.
class CompleteOnboarding {
  /// Creates the use case over [_repository].
  const CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  /// Marks onboarding complete.
  ///
  /// Returns the failure when the flag cannot be persisted, so the caller can
  /// decide what to do; navigation proceeds regardless, because trapping the
  /// user in onboarding because of a storage error would be worse than showing
  /// it again next launch.
  Future<Result<void>> call() => _repository.markComplete();
}

/// Requests camera access during onboarding.
///
/// Wraps the permission service so the Cubit does not talk to it directly, and
/// so the "the user may proceed whether or not permission is granted" rule
/// lives in the application layer where it can be unit-tested.
class RequestOnboardingCameraPermission {
  /// Creates the use case over [_permissions].
  const RequestOnboardingCameraPermission(this._permissions);

  final PermissionService _permissions;

  /// Requests camera access and returns the resulting state.
  ///
  /// Never fails: a refusal is an outcome the flow continues past, not an
  /// error, so the caller gets the state rather than a [Result].
  Future<PermissionState> call() => _permissions.request(PermissionKind.camera);
}
