/// State for the onboarding flow.
library;

import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:equatable/equatable.dart';

/// Which step of the onboarding flow is showing.
enum OnboardingStep {
  /// Welcome screen.
  welcome,

  /// Privacy and offline introduction.
  privacy,

  /// Camera permission request.
  permission,

  /// The flow is done and the user should be sent to Home.
  finished,
}

/// Immutable state of the onboarding flow.
///
/// Extends [Equatable] with every field in [props], so `emit` de-duplicates
/// identical states and `bloc_test` can assert on the sequence by value.
class OnboardingState extends Equatable {
  /// Creates an onboarding state.
  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.permission,
    this.isRequestingPermission = false,
  });

  /// The step currently showing.
  final OnboardingStep step;

  /// Result of the camera permission request, or null before it is made.
  ///
  /// Nullable rather than defaulting to `denied` so "not asked yet" is
  /// distinguishable from "asked and refused" — they lead to different UI.
  final PermissionState? permission;

  /// Whether a permission request is in flight.
  ///
  /// Drives the disabled state of the allow control, so a double tap cannot
  /// produce two system prompts.
  final bool isRequestingPermission;

  /// Whether the flow has finished and the user should be routed to Home.
  bool get isFinished => step == OnboardingStep.finished;

  /// Returns a copy with the given fields replaced.
  ///
  /// [permission] cannot be cleared back to null once set; nothing in the flow
  /// needs to un-ask a permission, and allowing it would let a state claim the
  /// question was never asked after it was.
  OnboardingState copyWith({
    OnboardingStep? step,
    PermissionState? permission,
    bool? isRequestingPermission,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      permission: permission ?? this.permission,
      isRequestingPermission:
          isRequestingPermission ?? this.isRequestingPermission,
    );
  }

  @override
  List<Object?> get props => [step, permission, isRequestingPermission];
}
