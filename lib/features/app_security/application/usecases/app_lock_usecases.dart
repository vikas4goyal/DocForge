/// Use cases for the application lock.
library;

import 'dart:async';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/app_security/domain/app_lock.dart';
import 'package:doc_scanly/features/app_security/domain/repositories/app_lock_repository.dart';

/// Authenticates the current session.
class AuthenticateAppLock {
  /// Creates the use case.
  const AuthenticateAppLock(this._authenticator);

  final DeviceAuthenticator _authenticator;

  /// Prompts for authentication and reports what happened.
  ///
  /// [reason] is shown inside the system dialogue; it differs between unlocking
  /// the app and confirming a change to the lock, and the user is entitled to
  /// know which one they are being asked about.
  Future<AuthOutcome> call({String reason = AppLockRules.promptReason}) =>
      _authenticator.authenticate(reason: reason);
}

/// Turns the lock on or off.
class SetAppLockEnabled {
  /// Creates the use case.
  const SetAppLockEnabled(this._authenticator, this._configuration);

  final DeviceAuthenticator _authenticator;
  final AppLockConfiguration _configuration;

  /// Enables or disables the lock, after confirming who is asking.
  ///
  /// Authentication comes first in **both** directions. Requiring it only to
  /// enable would let anyone holding an unlocked phone switch the lock off,
  /// which is precisely the situation the lock exists for — and the spec
  /// requires confirmation to disable explicitly.
  ///
  /// Returns the outcome rather than a bare success, so the caller can tell
  /// "you were rejected" from "this device has nothing set up", which need
  /// different messages.
  Future<Result<AuthOutcome>> call({required bool enabled}) async {
    if (enabled) {
      // Enabling on a device with nothing enrolled would produce a lock nobody
      // can open. Checked before prompting, so the user gets an explanation
      // rather than a dialogue that fails.
      final available = await _authenticator.isAvailable;
      if (!available) {
        return const Result<AuthOutcome>.success(AuthOutcome.notEnrolled);
      }
    }

    final outcome = await _authenticator.authenticate(
      reason: AppLockRules.changeLockReason,
    );

    if (outcome != AuthOutcome.succeeded) {
      return Result<AuthOutcome>.success(outcome);
    }

    final written = await _configuration.setEnabled(enabled: enabled);

    return switch (written) {
      Success() => const Result<AuthOutcome>.success(AuthOutcome.succeeded),
      // A secure-storage failure is surfaced rather than swallowed: the user
      // asked for the lock and it is not on, and no value is written anywhere
      // insecure as a consolation.
      Failed(:final failure) => Result<AuthOutcome>.failure(failure),
    };
  }
}

/// Reads whether the lock is enabled.
class IsAppLockEnabled {
  /// Creates the use case.
  const IsAppLockEnabled(this._configuration);

  final AppLockConfiguration _configuration;

  /// Whether the lock is on.
  ///
  /// Degrades to *enabled* when secure storage cannot be read. The safe answer
  /// when the configuration is unknown is to lock: guessing the other way would
  /// open the library on a device where the user had turned the lock on.
  Future<bool> call() async {
    final enabled = await _configuration.isEnabled();
    return enabled.valueOrNull ?? true;
  }
}

/// Deletes a document's stored password.
///
/// Called when a document is permanently removed, so a password never outlives
/// the document it protected.
class ForgetDocumentPassword {
  /// Creates the use case.
  const ForgetDocumentPassword(this._secrets);

  final SecureStore _secrets;

  /// Removes any password stored for [documentId].
  ///
  /// Deleting a key that was never written is a success, not a failure: a
  /// document that was never protected has no password to forget, and that is
  /// the common case.
  Future<Result<void>> call(String documentId) =>
      _secrets.delete(SecureStorageKeys.pdfPassword(documentId));
}

/// The lock gate the router consults.
///
/// Synchronous, because the router's redirect runs on every navigation and
/// cannot await. The state is loaded once at startup and updated on
/// authentication and on resume from background — which is exactly why
/// [AppLockStatus.unknown] exists: before the first load the honest answer is
/// "I do not know", and the gate treats that as locked (`design.md` §8).
class AppLockGateImpl implements AppLockGate {
  /// Creates the gate over [_isEnabled].
  AppLockGateImpl(this._isEnabled);

  final IsAppLockEnabled _isEnabled;
  final _changes = StreamController<bool>.broadcast();

  AppLockStatus _status = AppLockStatus.unknown;

  /// Where the lock currently stands.
  AppLockStatus get status => _status;

  @override
  bool get isLocked => AppLockRules.hidesContent(_status);

  @override
  Stream<bool> get lockChanges => _changes.stream;

  /// Reads the stored configuration and settles the initial status.
  ///
  /// Awaited before the first frame, so the router never has to guess.
  Future<void> load() async {
    final enabled = await _isEnabled();
    _moveTo(enabled ? AppLockStatus.locked : AppLockStatus.unlocked);
  }

  /// Records that the session has authenticated.
  void markUnlocked() => _moveTo(AppLockStatus.unlocked);

  /// Locks the session again.
  ///
  /// Called when the application returns from the background with the lock
  /// enabled, which the spec requires and which a launch-only check would miss.
  Future<void> lock() async {
    final enabled = await _isEnabled();
    if (enabled) _moveTo(AppLockStatus.locked);
  }

  /// Releases the gate's resources.
  void dispose() => _changes.close();

  void _moveTo(AppLockStatus next) {
    if (_status == next) return;

    final wasLocked = isLocked;
    _status = next;

    // Emitted only on a genuine change of *locked-ness*, so the router does not
    // re-evaluate its redirect for a transition nobody can observe.
    if (wasLocked != isLocked && !_changes.isClosed) _changes.add(isLocked);
  }
}
