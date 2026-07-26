import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryPreferenceStore', () {
    late InMemoryPreferenceStore store;

    setUp(() => store = InMemoryPreferenceStore());

    test('returns null for an absent key', () async {
      final result = await store.readString('missing');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('round-trips a string', () async {
      await store.writeString(PreferenceKeys.themeMode, 'dark');

      expect(
        (await store.readString(PreferenceKeys.themeMode)).valueOrNull,
        'dark',
      );
    });

    test('round-trips a bool', () async {
      await store.writeBool(PreferenceKeys.onboardingComplete, true);

      expect(
        (await store.readBool(PreferenceKeys.onboardingComplete)).valueOrNull,
        isTrue,
      );
    });

    test('round-trips an int', () async {
      await store.writeInt(PreferenceKeys.documentLayoutVersion, 3);

      expect(
        (await store.readInt(PreferenceKeys.documentLayoutVersion)).valueOrNull,
        3,
      );
    });

    test('overwrites an existing value', () async {
      await store.writeString('k', 'first');
      await store.writeString('k', 'second');

      expect((await store.readString('k')).valueOrNull, 'second');
    });

    test('removes a value', () async {
      await store.writeString('k', 'v');

      await store.remove('k');

      expect((await store.readString('k')).valueOrNull, isNull);
    });

    test('can be seeded with initial values', () async {
      final seeded = InMemoryPreferenceStore({'k': 'v'});

      expect((await seeded.readString('k')).valueOrNull, 'v');
    });

    test(
      'reports a simulated write failure and keeps the previous value',
      () async {
        await store.writeString('k', 'original');
        store.failNextWrite = true;

        final result = await store.writeString('k', 'updated');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());
        expect((await store.readString('k')).valueOrNull, 'original');
      },
    );

    test('the failure flag applies only to the next write', () async {
      store.failNextWrite = true;
      await store.writeString('k', 'blocked');

      final result = await store.writeString('k', 'allowed');

      expect(result.isSuccess, isTrue);
      expect((await store.readString('k')).valueOrNull, 'allowed');
    });

    test('exposes its contents as an unmodifiable view', () {
      expect(() => store.values['x'] = 'y', throwsUnsupportedError);
    });
  });

  group('InMemorySecureStore', () {
    late InMemorySecureStore store;

    setUp(() => store = InMemorySecureStore());

    test('returns null for an absent secret', () async {
      expect((await store.read('missing')).valueOrNull, isNull);
    });

    test('round-trips a secret', () async {
      await store.write(SecureStorageKeys.appLockEnabled, 'true');

      expect(
        (await store.read(SecureStorageKeys.appLockEnabled)).valueOrNull,
        'true',
      );
    });

    test('deletes a secret', () async {
      final key = SecureStorageKeys.pdfPassword('doc-1');
      await store.write(key, 'hunter2');

      await store.delete(key);

      expect((await store.read(key)).valueOrNull, isNull);
    });

    test('reports secure storage being unavailable on read', () async {
      store.failNextOperation = true;

      final result = await store.read('k');

      expect(result.failureOrNull, isA<SecureStorageFailure>());
    });

    test('reports secure storage being unavailable on write', () async {
      store.failNextOperation = true;

      final result = await store.write('k', 'v');

      expect(result.failureOrNull, isA<SecureStorageFailure>());
      // The value must not have been written anywhere as a fallback.
      expect(store.values, isEmpty);
    });

    test('reports secure storage being unavailable on delete', () async {
      await store.write('k', 'v');
      store.failNextOperation = true;

      final result = await store.delete('k');

      expect(result.failureOrNull, isA<SecureStorageFailure>());
      expect((await store.read('k')).valueOrNull, 'v');
    });
  });

  group('secure and preference stores are separate types', () {
    test(
      'a secure store cannot be used where a preference store is required',
      () {
        // The type system is what prevents a secret reaching SharedPreferences;
        // this test documents that intent rather than exercising behaviour.
        expect(InMemorySecureStore(), isNot(isA<PreferenceStore>()));
        expect(InMemoryPreferenceStore(), isNot(isA<SecureStore>()));
      },
    );
  });

  group('failure detail never leaks secrets', () {
    test('a secure-store failure carries no stored value', () async {
      final store = InMemorySecureStore()..failNextOperation = true;

      final failure = (await store.write('k', 'hunter2')).failureOrNull!;

      expect(failure.toString(), isNot(contains('hunter2')));
    });
  });
}
