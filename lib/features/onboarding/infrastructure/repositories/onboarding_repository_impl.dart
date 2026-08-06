/// SharedPreferences-backed onboarding persistence, and the router's gate.
library;

import 'dart:async';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Stores the onboarding-completed flag in preferences.
///
/// Not secure storage: whether onboarding has run is not a secret, and it must
/// be readable on a cold start before any authentication has happened.
class OnboardingRepositoryImpl implements OnboardingRepository {
  /// Creates the repository over [_preferences].
  const OnboardingRepositoryImpl(this._preferences);

  final PreferenceStore _preferences;

  @override
  Future<Result<bool>> isComplete() async {
    final result = await _preferences.readBool(
      PreferenceKeys.onboardingComplete,
    );

    // An absent flag means onboarding has never run — the normal first-launch
    // state, not an error.
    return result.map((value) => value ?? false);
  }

  @override
  Future<Result<void>> markComplete() =>
      _preferences.writeBool(PreferenceKeys.onboardingComplete, true);
}

/// Tells the router whether onboarding still needs to run.
///
/// The router's redirect is synchronous and runs on every navigation, so the
/// flag is loaded once at startup via [load] and held in memory. Changes are
/// published on [onboardingChanges] so the router can re-evaluate after the
/// user finishes the flow.
class OnboardingGateImpl implements OnboardingGate {
  /// Creates a gate over [_useCase], initially assuming onboarding is needed.
  ///
  /// Assuming "needed" until proven otherwise means a slow read can never let a
  /// first-time user slip past onboarding to Home.
  OnboardingGateImpl(this._useCase);

  final IsOnboardingCompleteReader _useCase;
  final _controller = StreamController<bool>.broadcast();

  bool _needsOnboarding = true;

  @override
  bool get needsOnboarding => _needsOnboarding;

  @override
  Stream<bool> get onboardingChanges => _controller.stream;

  /// Reads the persisted flag and updates the gate.
  ///
  /// Call once during startup, before the first frame.
  Future<void> load() async {
    _update(!await _useCase());
  }

  /// Marks onboarding as no longer required and notifies the router.
  void markComplete() => _update(false);

  void _update(bool value) {
    if (_needsOnboarding == value) return;
    _needsOnboarding = value;
    if (!_controller.isClosed) _controller.add(value);
  }

  /// Releases the gate's resources.
  void dispose() => _controller.close();
}

/// The shape [OnboardingGateImpl] needs from its use case.
///
/// Declared as a typedef rather than importing the concrete use case so the
/// gate can be tested with a plain function.
typedef IsOnboardingCompleteReader = Future<bool> Function();
