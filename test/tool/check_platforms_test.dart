import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_platforms.dart';

void main() {
  group('findForbiddenDirs', () {
    late Directory tempDir;

    setUp(
      () => tempDir = Directory.systemTemp.createTempSync('platform_check'),
    );
    tearDown(() => tempDir.deleteSync(recursive: true));

    test('returns nothing when only android and ios exist', () {
      Directory('${tempDir.path}/android').createSync();
      Directory('${tempDir.path}/ios').createSync();

      expect(findForbiddenDirs(tempDir), isEmpty);
    });

    test('flags a web folder', () {
      Directory('${tempDir.path}/web').createSync();

      expect(findForbiddenDirs(tempDir), ['web']);
    });

    test('flags every desktop folder', () {
      for (final name in ['macos', 'windows', 'linux']) {
        Directory('${tempDir.path}/$name').createSync();
      }

      expect(findForbiddenDirs(tempDir), ['macos', 'windows', 'linux']);
    });
  });

  group('findForbiddenPackages', () {
    test('returns nothing for a mobile-only pubspec', () {
      const pubspec = '''
name: doc_forge
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  isar_community: ^3.3.2
dev_dependencies:
  build_runner: ^2.15.1
''';

      expect(findForbiddenPackages(pubspec), isEmpty);
    });

    test('flags a web-only direct dependency', () {
      const pubspec = '''
name: doc_forge
dependencies:
  flutter:
    sdk: flutter
  universal_html: ^2.2.4
''';

      expect(findForbiddenPackages(pubspec), ['universal_html']);
    });

    test('flags a desktop-only dev dependency', () {
      const pubspec = '''
name: doc_forge
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  window_manager: ^0.3.0
''';

      expect(findForbiddenPackages(pubspec), ['window_manager']);
    });

    test('ignores forbidden names outside dependency blocks', () {
      const pubspec = '''
name: doc_forge
# universal_html: never add this
dependencies:
  flutter:
    sdk: flutter
dependency_overrides:
  window_manager: ^0.3.0
flutter:
  uses-material-design: true
''';

      expect(findForbiddenPackages(pubspec), isEmpty);
    });

    test('does not flag transitive desktop packages', () {
      // win32 arrives transitively under share_plus and is never compiled into
      // a mobile binary, so it must not fail the build.
      const pubspec = '''
name: doc_forge
dependencies:
  flutter:
    sdk: flutter
  share_plus: ^12.0.2
''';

      expect(findForbiddenPackages(pubspec), isEmpty);
    });
  });

  group('the real project', () {
    test('has no forbidden platform folders', () {
      expect(findForbiddenDirs(Directory('.')), isEmpty);
    });

    test('has no forbidden direct dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(findForbiddenPackages(pubspec), isEmpty);
    });
  });
}
