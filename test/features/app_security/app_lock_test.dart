/// Tests for the application-lock domain, repositories and use cases.
///
/// The biometric plugin does not load in the host test VM, so what each
/// outcome *means* — retry, send to settings, stay locked — is verified here or
/// nowhere until the app runs on a device.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_scanly/features/app_security/domain/app_lock.dart';
import 'package:doc_scanly/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:flutter_test/flutter_test.dart';

/// A secure store whose every operation fails.
class _UnavailableSecureStore implements SecureStore {
  @override
  Future<Result<String?>> read(String key) async =>
      const Result<String?>.failure(Failure.secureStorageUnavailable());

  @override
  Future<Result<void>> write(String key, String value) async =>
      const Result<void>.failure(Failure.secureStorageUnavailable());

  @override
  Future<Result<void>> delete(String key) async =>
      const Result<void>.failure(Failure.secureStorageUnavailable());
}

void main() {
  group('AppLockRules', () {
    test('every outcome except success has something to say', () {
      expect(AppLockRules.messageFor(AuthOutcome.succeeded), isNull);

      for (final outcome in [
        AuthOutcome.rejected,
        AuthOutcome.notEnrolled,
        AuthOutcome.error,
      ]) {
        expect(
          AppLockRules.messageFor(outcome),
          isNotEmpty,
          reason: '${outcome.name} must explain itself',
        );
      }
    });

    test('a rejection mentions the passcode fallback', () {
      // The user whose fingerprint will not read needs to know there is another
      // way in.
      expect(
        AppLockRules.messageFor(AuthOutcome.rejected),
        contains('passcode'),
      );
    });

    test('nothing enrolled cannot be retried here', () {
      // Only the system settings can resolve it; a retry button would be inert.
      expect(AppLockRules.canRetry(AuthOutcome.notEnrolled), isFalse);
      expect(AppLockRules.needsDeviceSetup(AuthOutcome.notEnrolled), isTrue);
    });

    test('a rejection and an error can both be retried', () {
      expect(AppLockRules.canRetry(AuthOutcome.rejected), isTrue);
      expect(AppLockRules.canRetry(AuthOutcome.error), isTrue);
      expect(AppLockRules.needsDeviceSetup(AuthOutcome.rejected), isFalse);
    });

    test('an unknown status hides content', () {
      // The safe answer before the configuration has been read. Guessing the
      // other way shows a document list for a frame behind an enabled lock.
      expect(AppLockRules.hidesContent(AppLockStatus.unknown), isTrue);
      expect(AppLockRules.isResolved(AppLockStatus.unknown), isFalse);
    });

    test('only the unlocked status reveals content', () {
      expect(AppLockRules.hidesContent(AppLockStatus.unlocked), isFalse);
      expect(AppLockRules.hidesContent(AppLockStatus.locked), isTrue);
      expect(AppLockRules.hidesContent(AppLockStatus.authenticating), isTrue);
    });

    test('the lock engages only when enabled and unauthenticated', () {
      expect(
        AppLockRules.shouldLock(isEnabled: true, isSessionAuthenticated: false),
        isTrue,
      );
      expect(
        AppLockRules.shouldLock(isEnabled: true, isSessionAuthenticated: true),
        isFalse,
      );
      expect(
        AppLockRules.shouldLock(
          isEnabled: false,
          isSessionAuthenticated: false,
        ),
        isFalse,
      );
    });

    test('each outcome maps to a distinguishable failure', () {
      final rejected = AppLockRules.failureFor(AuthOutcome.rejected);
      final notEnrolled = AppLockRules.failureFor(AuthOutcome.notEnrolled);
      final error = AppLockRules.failureFor(AuthOutcome.error);

      expect((rejected as AuthFailure).rejected, isTrue);
      expect((notEnrolled as AuthFailure).notEnrolled, isTrue);
      expect((error as AuthFailure).rejected, isFalse);
      expect(error.notEnrolled, isFalse);
    });

    test('the prompt reason names what is being unlocked', () {
      // It appears inside the system dialogue, where "authenticate" alone tells
      // the user nothing about what they are authorising.
      expect(AppLockRules.promptReason, contains('DocScanly'));
      expect(AppLockRules.changeLockReason, isNot(AppLockRules.promptReason));
    });
  });

  group('SecureAppLockConfiguration', () {
    test('an unset lock is off, not a failure', () async {
      final configuration = SecureAppLockConfiguration(InMemorySecureStore());

      expect((await configuration.isEnabled()).valueOrNull, isFalse);
    });

    test('round-trips being enabled', () async {
      final configuration = SecureAppLockConfiguration(InMemorySecureStore());

      await configuration.setEnabled(enabled: true);

      expect((await configuration.isEnabled()).valueOrNull, isTrue);
    });

    test('disabling removes the stored value', () async {
      final store = InMemorySecureStore();
      final configuration = SecureAppLockConfiguration(store);

      await configuration.setEnabled(enabled: true);
      await configuration.setEnabled(enabled: false);

      final stored = await store.read(SecureStorageKeys.appLockEnabled);
      expect(stored.valueOrNull, isNull);
    });

    test('stores the flag in secure storage, not preferences', () async {
      // A flag in an unprotected file can be flipped on a rooted device, which
      // would disable the lock without authenticating.
      final store = InMemorySecureStore();

      await SecureAppLockConfiguration(store).setEnabled(enabled: true);

      final stored = await store.read(SecureStorageKeys.appLockEnabled);
      expect(stored.valueOrNull, 'true');
      expect(SecureStorageKeys.appLockEnabled, startsWith('secure.'));
    });

    test('reports a secure-storage failure rather than guessing', () async {
      final configuration = SecureAppLockConfiguration(
        _UnavailableSecureStore(),
      );

      expect(await configuration.isEnabled(), isA<Failed<bool>>());
    });
  });

  group('IsAppLockEnabled', () {
    test('reports what is stored', () async {
      expect(
        await IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: true))(),
        isTrue,
      );
      expect(await IsAppLockEnabled(InMemoryAppLockConfiguration())(), isFalse);
    });

    test('degrades to locked when the configuration cannot be read', () async {
      // The safe direction: guessing "unlocked" would open the library on a
      // device where the user had turned the lock on.
      final enabled = await IsAppLockEnabled(
        InMemoryAppLockConfiguration(
          failure: const Failure.secureStorageUnavailable(),
        ),
      )();

      expect(enabled, isTrue);
    });
  });

  group('AuthenticateAppLock', () {
    test('passes the unlock reason to the prompt', () async {
      final authenticator = FakeDeviceAuthenticator();

      await AuthenticateAppLock(authenticator)();

      expect(authenticator.prompts.single, AppLockRules.promptReason);
    });

    test('reports each outcome unchanged', () async {
      for (final outcome in AuthOutcome.values) {
        final result = await AuthenticateAppLock(
          FakeDeviceAuthenticator(outcome: outcome),
        )();

        expect(result, outcome);
      }
    });
  });

  group('SetAppLockEnabled', () {
    test('enabling requires authentication first', () async {
      final authenticator = FakeDeviceAuthenticator();
      final configuration = InMemoryAppLockConfiguration();

      await SetAppLockEnabled(authenticator, configuration)(enabled: true);

      expect(authenticator.prompts.single, AppLockRules.changeLockReason);
      expect(configuration.enabled, isTrue);
    });

    test('disabling also requires authentication', () async {
      // Requiring it only to enable would let anyone holding an unlocked phone
      // switch the lock off — precisely what the lock exists for.
      final authenticator = FakeDeviceAuthenticator();
      final configuration = InMemoryAppLockConfiguration(enabled: true);

      await SetAppLockEnabled(authenticator, configuration)(enabled: false);

      expect(authenticator.prompts, hasLength(1));
      expect(configuration.enabled, isFalse);
    });

    test('a rejected attempt changes nothing', () async {
      final configuration = InMemoryAppLockConfiguration();

      final result = await SetAppLockEnabled(
        FakeDeviceAuthenticator(outcome: AuthOutcome.rejected),
        configuration,
      )(enabled: true);

      expect((result as Success<AuthOutcome>).value, AuthOutcome.rejected);
      expect(configuration.enabled, isFalse);
    });

    test('refuses to enable when the device has nothing enrolled', () async {
      // The lock would be one nobody could open. Reported before prompting, so
      // the user gets an explanation rather than a dialogue that fails.
      final authenticator = FakeDeviceAuthenticator(available: false);
      final configuration = InMemoryAppLockConfiguration();

      final result = await SetAppLockEnabled(authenticator, configuration)(
        enabled: true,
      );

      expect((result as Success<AuthOutcome>).value, AuthOutcome.notEnrolled);
      expect(authenticator.prompts, isEmpty);
      expect(configuration.enabled, isFalse);
    });

    test(
      'surfaces a secure-storage failure rather than swallowing it',
      () async {
        final result = await SetAppLockEnabled(
          FakeDeviceAuthenticator(),
          InMemoryAppLockConfiguration(
            failure: const Failure.secureStorageUnavailable(),
          ),
        )(enabled: true);

        expect(result, isA<Failed<AuthOutcome>>());
      },
    );
  });

  group('ForgetDocumentPassword', () {
    test('removes the stored password', () async {
      final store = InMemorySecureStore();
      await store.write(SecureStorageKeys.pdfPassword('a'), 'hunter2');

      await ForgetDocumentPassword(store)('a');

      expect(
        (await store.read(SecureStorageKeys.pdfPassword('a'))).valueOrNull,
        isNull,
      );
    });

    test('forgetting a document that had no password succeeds', () async {
      // The common case: most documents are unprotected, and a purge must not
      // fail because there was nothing to delete.
      final result = await ForgetDocumentPassword(InMemorySecureStore())('a');

      expect(result, isA<Success<void>>());
    });

    test('touches only that document’s password', () async {
      final store = InMemorySecureStore();
      await store.write(SecureStorageKeys.pdfPassword('a'), 'hunter2');
      await store.write(SecureStorageKeys.pdfPassword('b'), 'correcthorse');

      await ForgetDocumentPassword(store)('a');

      expect(
        (await store.read(SecureStorageKeys.pdfPassword('b'))).valueOrNull,
        'correcthorse',
      );
    });
  });

  group('AppLockGateImpl', () {
    test('is locked before the configuration has been read', () async {
      // The router asks on the very first navigation, which happens before the
      // secure read has finished.
      final gate = AppLockGateImpl(
        IsAppLockEnabled(InMemoryAppLockConfiguration()),
      );
      addTearDown(gate.dispose);

      expect(gate.status, AppLockStatus.unknown);
      expect(gate.isLocked, isTrue);
    });

    test('settles to unlocked when the lock is off', () async {
      final gate = AppLockGateImpl(
        IsAppLockEnabled(InMemoryAppLockConfiguration()),
      );
      addTearDown(gate.dispose);

      await gate.load();

      expect(gate.isLocked, isFalse);
    });

    test('settles to locked when the lock is on', () async {
      final gate = AppLockGateImpl(
        IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: true)),
      );
      addTearDown(gate.dispose);

      await gate.load();

      expect(gate.isLocked, isTrue);
    });

    test('unlocks once the session authenticates', () async {
      final gate = AppLockGateImpl(
        IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: true)),
      );
      addTearDown(gate.dispose);

      await gate.load();
      gate.markUnlocked();

      expect(gate.isLocked, isFalse);
    });

    test('locks again on resume when the lock is enabled', () async {
      // A launch-only check would let a backgrounded, unlocked session be
      // resumed by whoever picks the phone up.
      final gate = AppLockGateImpl(
        IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: true)),
      );
      addTearDown(gate.dispose);

      await gate.load();
      gate.markUnlocked();
      await gate.lock();

      expect(gate.isLocked, isTrue);
    });

    test('does not lock on resume when the lock is disabled', () async {
      final gate = AppLockGateImpl(
        IsAppLockEnabled(InMemoryAppLockConfiguration()),
      );
      addTearDown(gate.dispose);

      await gate.load();
      await gate.lock();

      expect(gate.isLocked, isFalse);
    });

    test('emits only when locked-ness actually changes', () async {
      final gate = AppLockGateImpl(
        IsAppLockEnabled(InMemoryAppLockConfiguration(enabled: true)),
      );
      addTearDown(gate.dispose);

      final emitted = <bool>[];
      final subscription = gate.lockChanges.listen(emitted.add);

      await gate.load();
      gate
        ..markUnlocked()
        // Already unlocked — the router has nothing to re-evaluate.
        ..markUnlocked();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emitted, [false]);
    });
  });
}
