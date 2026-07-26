import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreferenceKeys', () {
    test('every key is unique', () {
      expect(PreferenceKeys.all.toSet(), hasLength(PreferenceKeys.all.length));
    });

    test('every key uses the app or settings namespace', () {
      for (final key in PreferenceKeys.all) {
        expect(
          key.startsWith('app.') || key.startsWith('settings.'),
          isTrue,
          reason: '"$key" is not namespaced',
        );
      }
    });

    test('no preference key uses the secure namespace', () {
      // A secret reaching SharedPreferences would be stored in plain text.
      for (final key in PreferenceKeys.all) {
        expect(
          key.startsWith('secure.'),
          isFalse,
          reason: '"$key" looks secure',
        );
      }
    });

    test('no key is empty or whitespace', () {
      for (final key in PreferenceKeys.all) {
        expect(key.trim(), isNotEmpty);
      }
    });
  });

  group('SecureStorageKeys', () {
    test('every fixed key is unique', () {
      expect(
        SecureStorageKeys.all.toSet(),
        hasLength(SecureStorageKeys.all.length),
      );
    });

    test('every fixed key uses the secure namespace', () {
      for (final key in SecureStorageKeys.all) {
        expect(
          key.startsWith('secure.'),
          isTrue,
          reason: '"$key" is not secure',
        );
      }
    });

    test('pdfPassword builds a namespaced per-document key', () {
      final key = SecureStorageKeys.pdfPassword('doc-123');

      expect(key, 'secure.pdfPassword.doc-123');
      expect(key.startsWith('secure.'), isTrue);
    });

    test('pdfPassword produces a distinct key per document', () {
      expect(
        SecureStorageKeys.pdfPassword('a'),
        isNot(SecureStorageKeys.pdfPassword('b')),
      );
    });

    test('pdfPassword is stable for the same document', () {
      expect(
        SecureStorageKeys.pdfPassword('doc-1'),
        SecureStorageKeys.pdfPassword('doc-1'),
      );
    });
  });

  group('namespaces do not collide', () {
    test('no preference key equals a secure key', () {
      final overlap = PreferenceKeys.all.toSet().intersection(
        SecureStorageKeys.all.toSet(),
      );

      expect(overlap, isEmpty);
    });
  });
}
