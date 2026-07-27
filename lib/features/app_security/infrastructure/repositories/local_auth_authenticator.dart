/// Platform-backed and fake implementations of the security seams.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/features/app_security/domain/app_lock.dart';
import 'package:doc_forge/features/app_security/domain/repositories/app_lock_repository.dart';
import 'package:local_auth/local_auth.dart';

/// A [DeviceAuthenticator] backed by `local_auth`.
class LocalAuthAuthenticator implements DeviceAuthenticator {
  /// Creates the authenticator.
  const LocalAuthAuthenticator();

  @override
  Future<AuthOutcome> authenticate({required String reason}) async {
    final auth = LocalAuthentication();

    try {
      final succeeded = await auth.authenticate(
        localizedReason: reason,
        // `biometricOnly` is left at its default of false, which is what
        // supplies the device-credential fallback the spec requires: the system
        // offers the passcode when biometrics fail or are unavailable, without
        // DocForge having to detect and orchestrate that itself.
        // Keeps the prompt alive when the system backgrounds the app to show
        // its own dialogue, which would otherwise look like a dismissal.
        persistAcrossBackgrounding: true,
      );

      return succeeded ? AuthOutcome.succeeded : AuthOutcome.rejected;
    } on Object catch (error) {
      return _outcomeFor(error);
    }
  }

  @override
  Future<bool> get isAvailable async {
    try {
      final auth = LocalAuthentication();
      // Either is enough: the spec accepts the device credential in place of a
      // biometric, so a device with only a passcode can still use the lock.
      return await auth.isDeviceSupported() || await auth.canCheckBiometrics;
    } on Object {
      return false;
    }
  }

  /// Maps a plugin error onto the outcome that decides what happens next.
  ///
  /// The three cases are kept apart deliberately. "Nothing is enrolled" is the
  /// only one a retry cannot resolve — it needs a change in the system settings
  /// — and folding it into a generic error would leave the user pressing a
  /// button that can never work. A *cancellation* is a rejection rather than an
  /// error: the user dismissed the prompt, and nothing went wrong.
  AuthOutcome _outcomeFor(Object error) {
    if (error is! LocalAuthException) return AuthOutcome.error;

    return switch (error.code) {
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noBiometricHardware => AuthOutcome.notEnrolled,
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout => AuthOutcome.rejected,
      _ => AuthOutcome.error,
    };
  }
}

/// An [AppLockConfiguration] backed by secure storage.
class SecureAppLockConfiguration implements AppLockConfiguration {
  /// Creates the configuration over [_secrets].
  const SecureAppLockConfiguration(this._secrets);

  final SecureStore _secrets;

  @override
  Future<Result<bool>> isEnabled() async {
    final stored = await _secrets.read(SecureStorageKeys.appLockEnabled);

    return switch (stored) {
      // A missing value is a successful false: a lock nobody has enabled is
      // off, and failing here would leave the app unopenable.
      Success(:final value) => Result<bool>.success(value == 'true'),
      Failed(:final failure) => Result<bool>.failure(failure),
    };
  }

  @override
  Future<Result<void>> setEnabled({required bool enabled}) => enabled
      ? _secrets.write(SecureStorageKeys.appLockEnabled, 'true')
      : _secrets.delete(SecureStorageKeys.appLockEnabled);
}

/// A [DeviceAuthenticator] answering with a fixed outcome.
///
/// Ships in `lib/` rather than in `test/` because previews need it too: a
/// preview that reached the real authenticator would raise a biometric prompt
/// while the developer was looking at a widget.
class FakeDeviceAuthenticator implements DeviceAuthenticator {
  /// Creates an authenticator that answers with [outcome].
  FakeDeviceAuthenticator({
    this.outcome = AuthOutcome.succeeded,
    this.available = true,
  });

  /// What each attempt reports.
  AuthOutcome outcome;

  /// Whether the device claims any authentication method.
  bool available;

  /// The reason shown on each attempt, in order.
  final List<String> prompts = [];

  @override
  Future<AuthOutcome> authenticate({required String reason}) async {
    prompts.add(reason);
    return outcome;
  }

  @override
  Future<bool> get isAvailable async => available;
}

/// An [AppLockConfiguration] backed by memory.
class InMemoryAppLockConfiguration implements AppLockConfiguration {
  /// Creates a configuration starting at [enabled].
  InMemoryAppLockConfiguration({this.enabled = false, this.failure});

  /// Whether the lock is currently enabled. Settable by tests.
  bool enabled;

  /// When set, every operation fails with this.
  final Failure? failure;

  @override
  Future<Result<bool>> isEnabled() async {
    final configured = failure;
    return configured == null
        ? Result<bool>.success(enabled)
        : Result<bool>.failure(configured);
  }

  @override
  Future<Result<void>> setEnabled({required bool enabled}) async {
    final configured = failure;
    if (configured != null) return Result<void>.failure(configured);

    this.enabled = enabled;
    return const Result<void>.success(null);
  }
}
