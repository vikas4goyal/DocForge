/// Coordinates the onboarding flow's UI state.
library;

import 'package:doc_scanly/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_scanly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns which onboarding step is showing and the permission outcome.
///
/// Holds no business logic: each method emits a state, awaits a use case, and
/// emits the result. The rules — that onboarding completes exactly once, and
/// that the user proceeds whether or not permission is granted — live in the
/// use cases and are unit-tested there.
class OnboardingCubit extends Cubit<OnboardingState> {
  /// Creates the Cubit over its use cases.
  OnboardingCubit(this._completeOnboarding, this._requestCameraPermission)
    : super(const OnboardingState());

  final CompleteOnboarding _completeOnboarding;
  final RequestOnboardingCameraPermission _requestCameraPermission;

  /// Advances from the welcome screen to the privacy introduction.
  void continueFromWelcome() =>
      emit(state.copyWith(step: OnboardingStep.privacy));

  /// Advances from the privacy introduction to the permission request.
  void continueFromPrivacy() =>
      emit(state.copyWith(step: OnboardingStep.permission));

  /// Requests camera permission, then finishes the flow.
  ///
  /// Finishes regardless of the answer: the spec requires the user to reach
  /// Home whether permission was granted or refused.
  Future<void> requestCameraPermission() async {
    if (state.isRequestingPermission) return;

    emit(state.copyWith(isRequestingPermission: true));
    final permission = await _requestCameraPermission();
    emit(state.copyWith(permission: permission, isRequestingPermission: false));

    await _finish();
  }

  /// Skips the permission request and finishes the flow.
  ///
  /// No system prompt is shown, so the permission outcome stays unknown.
  Future<void> skipPermission() => _finish();

  /// Persists completion, then moves to the finished step.
  ///
  /// The flag is written *before* the finished state is emitted so the router's
  /// gate cannot observe a completed flow whose flag has not landed yet.
  Future<void> _finish() async {
    await _completeOnboarding();
    emit(state.copyWith(step: OnboardingStep.finished));
  }
}
