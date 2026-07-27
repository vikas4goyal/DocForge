/// The security guarantees, asserted directly against the source tree.
///
/// These are the ones a feature test cannot make on its own: they are claims
/// about what the *whole* application does and does not do, and they hold only
/// as long as nobody adds the offending line anywhere. Scanning the source is
/// the only check that stays true for code no test happens to walk.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart source file under `lib/`, excluding generated output.
Iterable<File> _sources() sync* {
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    if (entity.path.endsWith('.freezed.dart')) continue;
    yield entity;
  }
}

void main() {
  group('nothing leaves the device on its own', () {
    test('no feature opens an HTTP client or uses Dio', () {
      // Dio is declared in pubspec for a future cloud-sync layer, and this is
      // what keeps that future from arriving by accident. The exception list is
      // empty on purpose: no feature has any reason to reach the network today.
      final offenders = <String>[];

      for (final file in _sources()) {
        final code = file.readAsStringSync();
        if (code.contains('package:dio') ||
            code.contains('package:http/') ||
            code.contains('HttpClient(')) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'these files can reach the network: $offenders',
      );
    });

    test('no feature writes to shared or external storage', () {
      // The paths that would take a document out of app-private storage on
      // Android. `getApplicationDocumentsDirectory` and
      // `getApplicationCacheDirectory` are the two that stay private.
      const forbidden = [
        'getExternalStorageDirectory',
        'getExternalStorageDirectories',
        'getDownloadsDirectory',
        '/sdcard/',
        'Environment.getExternalStorage',
      ];

      final offenders = <String>[];

      for (final file in _sources()) {
        final code = file.readAsStringSync();
        for (final path in forbidden) {
          // The export path deliberately writes wherever the user pointed the
          // system picker, which is a user-initiated action rather than a
          // storage-location decision DocForge makes.
          if (code.contains(path)) offenders.add('${file.path}: $path');
        }
      }

      expect(offenders, isEmpty);
    });
  });

  group('secrets go to secure storage only', () {
    test('no preference key lives in the secure namespace, or vice versa', () {
      final keys = File(
        'lib/core/storage/storage_keys.dart',
      ).readAsStringSync();

      // The two namespaces are what makes a misplaced secret greppable. A
      // secure key under `settings.` would end up in an unprotected file.
      expect(keys, contains("static const appLockEnabled = 'secure."));
      expect(keys, contains("pdfPasswordPrefix = 'secure."));
      expect(keys, isNot(contains("themeMode = 'secure.")));
    });

    test('nothing writes a PDF password through the preference store', () {
      // The type system already prevents it — `SecureStore` and
      // `PreferenceStore` are different types — and this catches the case where
      // someone widens one of them.
      final offenders = <String>[];

      for (final file in _sources()) {
        final code = file.readAsStringSync();

        final touchesPasswordKey = code.contains(
          'SecureStorageKeys.pdfPassword',
        );
        final touchesPreferences =
            code.contains('PreferenceStore') ||
            code.contains('SharedPreferences');

        if (touchesPasswordKey && touchesPreferences) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty);
    });

    test('no secret is written to a log line', () {
      // `print` and `debugPrint` are absent from `lib/` entirely, which is the
      // only version of this rule that cannot be got subtly wrong.
      final offenders = <String>[];

      for (final file in _sources()) {
        final code = file.readAsStringSync();
        for (final line in code.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('//')) continue;
          // A *call* to the top-level function, not a method that happens to
          // be named `print` — the lookbehind excludes `cubit.print(...)`, and
          // the declaration check excludes `Future<void> print()`. Both would
          // otherwise be false positives that trained everyone to ignore this
          // test.
          if (RegExp(r'(?<![\w.])(print|debugPrint)\s*\(').hasMatch(trimmed) &&
              !RegExp(
                r'(Future<\w*>|void)\s+(print|debugPrint)\s*\(',
              ).hasMatch(trimmed)) {
            offenders.add('${file.path}: $trimmed');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'logging in lib/ risks printing a secret: $offenders',
      );
    });

    test('the app-lock flag is never read from preferences', () {
      final settings = File(
        'lib/features/app_settings/infrastructure/repositories/'
        'preference_settings_repository.dart',
      ).readAsStringSync();

      // It is read through an injected reader that goes to secure storage; a
      // preference key for it would be flippable on a rooted device.
      expect(settings, isNot(contains('appLockEnabled')));
      expect(settings, contains('isAppLockEnabled'));
    });
  });

  group('the domain layer stays pure', () {
    test('no domain file imports a plugin', () {
      // A plugin in the domain layer is a rule that cannot be tested without a
      // device, which is how untestable business logic gets in.
      const plugins = [
        'package:camera/',
        'package:local_auth/',
        'package:pdfrx/',
        'package:image_picker/',
        'package:file_picker/',
        'package:share_plus/',
        'package:printing/',
        'package:isar_community/',
        'package:shared_preferences/',
        'package:flutter_secure_storage/',
      ];

      final offenders = <String>[];

      for (final file in _sources()) {
        if (!file.path.contains('/domain/')) continue;

        final code = file.readAsStringSync();
        for (final plugin in plugins) {
          if (code.contains(plugin)) offenders.add('${file.path}: $plugin');
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
