/// Builds the two screens that stand in front of the application: onboarding
/// and the lock.
///
/// Both are gates rather than destinations — the router redirects into them and
/// they hand control back once satisfied — so they are built together and share
/// the gate objects the router's redirect reads.
library;

import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_forge/features/app_security/domain/repositories/app_lock_repository.dart';
import 'package:doc_forge/features/app_security/presentation/cubit/app_lock_cubit.dart';
import 'package:doc_forge/features/app_security/presentation/screens/unlock_screen.dart';
import 'package:doc_forge/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_forge/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_forge/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The screens the route guard redirects into.
class SecurityScreens {
  /// Creates the group.
  const SecurityScreens({required this.onboarding, required this.unlock});

  /// First-launch onboarding.
  final ScreenBuilder onboarding;

  /// The application lock screen.
  final ScreenBuilder unlock;
}

/// Builds onboarding and the lock screen over the gates the router consults.
///
/// [permissions] backs onboarding's camera request and the unlock screen's
/// "open settings" escape hatch. [onboardingRepository] persists the completion
/// flag and [onboardingGate] is the in-memory answer the router's synchronous
/// redirect reads — it is marked complete here rather than re-read from disk,
/// because a stale gate would bounce the user straight back into onboarding.
///
/// [lockConfiguration] is read to decide whether the lock applies at all, and
/// [lockGate] is told the moment authentication succeeds so GoRouter's redirect
/// stops sending the user back to the lock.
///
/// [authenticator] defaults, at the composition root, to the real device
/// authenticator. It is a parameter because biometrics are a platform edge with
/// no host-VM implementation: an end-to-end flow substitutes
/// `FakeDeviceAuthenticator` so unlocking is a decision the test makes rather
/// than a system prompt nothing can answer.
SecurityScreens buildSecurityScreens({
  required PermissionService permissions,
  required OnboardingRepositoryImpl onboardingRepository,
  required OnboardingGateImpl onboardingGate,
  required AppLockConfiguration lockConfiguration,
  required AppLockGateImpl lockGate,
  required DeviceAuthenticator authenticator,
}) {
  return SecurityScreens(
    onboarding: (context) => BlocProvider(
      create: (_) => OnboardingCubit(
        CompleteOnboarding(onboardingRepository),
        RequestOnboardingCameraPermission(permissions),
      ),
      child: OnboardingScreen(
        onFinished: () {
          // Update the gate first: the router re-evaluates its redirect on
          // navigation, and a stale gate would bounce the user straight back
          // into onboarding.
          onboardingGate.markComplete();
          context.go(AppRoutes.home);
        },
      ),
    ),
    unlock: (context) => BlocProvider(
      create: (_) => AppLockCubit(
        AuthenticateAppLock(authenticator),
        IsAppLockEnabled(lockConfiguration),
        onUnlocked: lockGate.markUnlocked,
      ),
      child: UnlockScreen(onOpenSettings: permissions.openSettings),
    ),
  );
}
