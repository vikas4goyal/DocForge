import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_branding.dart';

void main() {
  late Directory temporary;

  setUp(() => temporary = Directory.systemTemp.createTempSync('brand_check'));
  tearDown(() => temporary.deleteSync(recursive: true));

  test('accepts the current DocScanly identity', () {
    File('${temporary.path}/README.md')
      ..createSync(recursive: true)
      ..writeAsStringSync('# DocScanly\npackage:doc_scanly/app.dart');

    expect(findRetiredBrandOccurrences(temporary), isEmpty);
  });

  test('reports retired spellings with their lines', () {
    File('${temporary.path}/lib/example.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '// DocForge\n// Doc Forge\npackage:doc_forge/a.dart',
      );

    expect(findRetiredBrandOccurrences(temporary), [
      'lib/example.dart:1',
      'lib/example.dart:2',
      'lib/example.dart:3',
    ]);
  });

  test('ignores archived specifications', () {
    File('${temporary.path}/openspec/changes/archive/old/proposal.md')
      ..createSync(recursive: true)
      ..writeAsStringSync('DocForge');

    expect(findRetiredBrandOccurrences(temporary), isEmpty);
  });

  test('the active repository contains no retired branding', () {
    expect(findRetiredBrandOccurrences(Directory('.')), isEmpty);
  });
}
