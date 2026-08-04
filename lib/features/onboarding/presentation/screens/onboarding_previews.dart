/// Widget previews for the onboarding flow.
///
/// Every screen must preview default, loading, empty, error and long content,
/// plus phone, tablet, light and dark. Onboarding is a fixed three-step flow
/// with no data to load, so its "loading" variant is the in-flight permission
/// request and its "long content" variant is the maximum text scale — the two
/// states that actually vary here.
///
/// Each preview seeds a fake Cubit rather than constructing the real one, so no
/// repository, preference store or permission plugin is touched.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/core/previews/fakes/fake_cubit.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_scanly/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:doc_scanly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_scanly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:doc_scanly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A repository that records nothing, for previews.
class _InertRepository implements OnboardingRepository {
  const _InertRepository();

  @override
  Future<Result<bool>> isComplete() async => const Result<bool>.success(false);

  @override
  Future<Result<void>> markComplete() async => const Result<void>.success(null);
}

/// An [OnboardingCubit] frozen at a chosen state.
///
/// Subclasses the real Cubit because BlocProvider resolves by concrete type,
/// and mixes in [SeededCubit] to set the state without invoking any use case.
class _PreviewOnboardingCubit extends OnboardingCubit
    with SeededCubit<OnboardingState> {
  _PreviewOnboardingCubit(OnboardingState state)
    : super(
        const CompleteOnboarding(_InertRepository()),
        RequestOnboardingCameraPermission(FakePermissionService()),
      ) {
    seed(state);
  }
}

/// Builds the flow seeded to [state], with collaborators that do nothing.
Widget _onboardingAt(OnboardingState state) => BlocProvider<OnboardingCubit>(
  create: (_) => _PreviewOnboardingCubit(state),
  child: OnboardingScreen(onFinished: () {}),
);

/// Welcome step.
@Preview(
  name: 'Onboarding — welcome',
  group: 'Onboarding',
  theme: appPreviewTheme,
)
Widget onboardingWelcome() => _onboardingAt(const OnboardingState());

/// Welcome step in dark mode.
@Preview(
  name: 'Onboarding — welcome, dark',
  group: 'Onboarding',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget onboardingWelcomeDark() => _onboardingAt(const OnboardingState());

/// Welcome step on a tablet.
@Preview(
  name: 'Onboarding — welcome, tablet',
  group: 'Onboarding',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget onboardingWelcomeTablet() => _onboardingAt(const OnboardingState());

/// Privacy introduction.
@Preview(
  name: 'Onboarding — privacy',
  group: 'Onboarding',
  theme: appPreviewTheme,
)
Widget onboardingPrivacy() =>
    _onboardingAt(const OnboardingState(step: OnboardingStep.privacy));

/// Privacy introduction in dark mode.
@Preview(
  name: 'Onboarding — privacy, dark',
  group: 'Onboarding',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget onboardingPrivacyDark() =>
    _onboardingAt(const OnboardingState(step: OnboardingStep.privacy));

/// Privacy introduction on a tablet.
@Preview(
  name: 'Onboarding — privacy, tablet',
  group: 'Onboarding',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget onboardingPrivacyTablet() =>
    _onboardingAt(const OnboardingState(step: OnboardingStep.privacy));

/// Privacy introduction at the maximum text scale.
///
/// The long-content case: three statements plus a heading is the most text the
/// flow ever shows, so this is where overflow would appear first.
@Preview(
  name: 'Onboarding — privacy, large text',
  group: 'Onboarding',
  theme: appPreviewTheme,
  textScaleFactor: 3,
)
Widget onboardingPrivacyLargeText() =>
    _onboardingAt(const OnboardingState(step: OnboardingStep.privacy));

/// Permission request.
@Preview(
  name: 'Onboarding — permission',
  group: 'Onboarding',
  theme: appPreviewTheme,
)
Widget onboardingPermission() =>
    _onboardingAt(const OnboardingState(step: OnboardingStep.permission));

/// Permission request while the system prompt is in flight.
///
/// The loading case: the allow control is disabled so a double tap cannot raise
/// two prompts.
@Preview(
  name: 'Onboarding — permission, requesting',
  group: 'Onboarding',
  theme: appPreviewTheme,
)
Widget onboardingPermissionRequesting() => _onboardingAt(
  const OnboardingState(
    step: OnboardingStep.permission,
    isRequestingPermission: true,
  ),
);

/// Permission request after a refusal.
///
/// The error case: the flow explains the consequence and still lets the user
/// continue, as the spec requires.
@Preview(
  name: 'Onboarding — permission, denied',
  group: 'Onboarding',
  theme: appPreviewTheme,
)
Widget onboardingPermissionDenied() => _onboardingAt(
  const OnboardingState(
    step: OnboardingStep.permission,
    permission: PermissionState.denied,
  ),
);

/// Permission request in dark mode.
@Preview(
  name: 'Onboarding — permission, dark',
  group: 'Onboarding',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget onboardingPermissionDark() =>
    _onboardingAt(const OnboardingState(step: OnboardingStep.permission));

/// Permission request on a tablet.
@Preview(
  name: 'Onboarding — permission, tablet',
  group: 'Onboarding',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget onboardingPermissionTablet() =>
    _onboardingAt(const OnboardingState(step: OnboardingStep.permission));
