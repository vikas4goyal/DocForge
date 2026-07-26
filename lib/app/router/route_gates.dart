/// The two redirect gates that guard every route.
///
/// Ordering matters and is not arbitrary: the **lock gate runs before the
/// onboarding gate**. If onboarding were checked first, a locked app relaunched
/// by a user who had not finished onboarding would render onboarding content
/// before authentication. Onboarding shows no documents, so the leak is small —
/// but the rule "no screen renders before the lock is satisfied" is much easier
/// to keep true if it has no exceptions at all (`design.md` §8).
///
/// Both gates are injected implementations of core contracts, so the router
/// depends on no feature and either gate can be faked in a navigation test.
library;

import 'package:doc_forge/core/contracts/contracts.dart';

/// Routes that must remain reachable regardless of gate state.
///
/// Without these the gates would redirect to a location that itself redirects,
/// producing an infinite loop rather than a screen.
abstract final class GateExemptRoutes {
  /// Where the lock gate sends an unauthenticated user.
  static const unlock = '/unlock';

  /// Where the onboarding gate sends a first-time user.
  static const onboarding = '/onboarding';
}

/// Decides where navigation should be redirected, if anywhere.
///
/// Pure and synchronous: GoRouter's redirect runs on every navigation and
/// cannot await, so both gates expose their state synchronously and refresh the
/// router through a listenable when it changes.
class RouteGuard {
  /// Creates a guard over the given gates.
  const RouteGuard({required this.lockGate, required this.onboardingGate});

  /// Reports whether the application is locked.
  final AppLockGate lockGate;

  /// Reports whether onboarding still needs to run.
  final OnboardingGate onboardingGate;

  /// Returns the location to redirect to, or null to allow [location].
  String? redirectFor(String location) {
    // 1. Lock first, unconditionally. Nothing renders behind the lock screen.
    if (lockGate.isLocked) {
      return location == GateExemptRoutes.unlock
          ? null
          : GateExemptRoutes.unlock;
    }

    // Once unlocked, the unlock screen itself is no longer a valid destination.
    if (location == GateExemptRoutes.unlock) {
      return onboardingGate.needsOnboarding ? GateExemptRoutes.onboarding : '/';
    }

    // 2. Onboarding, only once the app is unlocked.
    if (onboardingGate.needsOnboarding) {
      return location == GateExemptRoutes.onboarding
          ? null
          : GateExemptRoutes.onboarding;
    }

    // Onboarding is complete, so its route is no longer reachable.
    if (location == GateExemptRoutes.onboarding) return '/';

    return null;
  }
}

/// An [AppLockGate] with a settable state, for tests and previews.
class FakeAppLockGate implements AppLockGate {
  /// Creates a gate that is initially locked when [isLocked] is true.
  FakeAppLockGate({this.isLocked = false});

  /// Whether the application is currently locked. Settable by tests.
  @override
  bool isLocked;

  @override
  Stream<bool> get lockChanges => const Stream<bool>.empty();
}

/// An [OnboardingGate] with a settable state, for tests and previews.
class FakeOnboardingGate implements OnboardingGate {
  /// Creates a gate that initially needs onboarding when [needsOnboarding] is
  /// true.
  FakeOnboardingGate({this.needsOnboarding = false});

  /// Whether onboarding is still required. Settable by tests.
  @override
  bool needsOnboarding;

  @override
  Stream<bool> get onboardingChanges => const Stream<bool>.empty();
}
