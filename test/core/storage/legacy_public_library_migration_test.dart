import 'dart:io';

import 'package:doc_scanly/core/storage/legacy_public_library_migration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory documents;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('docscanly_brand_');
  });

  tearDown(() async {
    if (documents.existsSync()) await documents.delete(recursive: true);
  });

  test(
    'copies active and Trash trees, verifies, then removes source',
    () async {
      final oldRoot = Directory('${documents.path}/DocForge');
      File('${oldRoot.path}/Folder/a.pdf')
        ..createSync(recursive: true)
        ..writeAsStringSync('active');
      File('${oldRoot.path}/.docforge-trash/t/a.pdf')
        ..createSync(recursive: true)
        ..writeAsStringSync('trash');

      final report = await LegacyPublicLibraryMigration(documents).run();

      expect(report.copiedFiles, 2);
      expect(report.removedSource, isTrue);
      expect(
        File('${documents.path}/DocScanly/Folder/a.pdf').readAsStringSync(),
        'active',
      );
      expect(
        File(
          '${documents.path}/DocScanly/.docscanly-trash/t/a.pdf',
        ).readAsStringSync(),
        'trash',
      );
    },
  );

  test('restart adopts an already verified copy without duplication', () async {
    final source = File('${documents.path}/DocForge/a.pdf')
      ..createSync(recursive: true)
      ..writeAsStringSync('same');
    File('${documents.path}/DocScanly/a.pdf')
      ..createSync(recursive: true)
      ..writeAsStringSync('same');

    final report = await LegacyPublicLibraryMigration(documents).run();

    expect(report.copiedFiles, 0);
    expect(source.existsSync(), isFalse);
    expect(
      Directory('${documents.path}/DocScanly').listSync().whereType<File>(),
      hasLength(1),
    );
  });

  test(
    'different collision payloads are both preserved deterministically',
    () async {
      File('${documents.path}/DocForge/a.pdf')
        ..createSync(recursive: true)
        ..writeAsStringSync('legacy');
      File('${documents.path}/DocScanly/a.pdf')
        ..createSync(recursive: true)
        ..writeAsStringSync('current');

      await LegacyPublicLibraryMigration(documents).run();

      expect(
        File('${documents.path}/DocScanly/a.pdf').readAsStringSync(),
        'current',
      );
      expect(
        File('${documents.path}/DocScanly/a (legacy 1).pdf').readAsStringSync(),
        'legacy',
      );
    },
  );

  test('missing source is a successful no-op', () async {
    final report = await LegacyPublicLibraryMigration(documents).run();

    expect(report.copiedFiles, 0);
    expect(report.removedSource, isTrue);
  });

  test('Trash manifest keeps original path and expiry metadata', () async {
    const manifest =
        '{"originalRelativePath":"Receipts/a.pdf",'
        '"expiresAt":"2026-09-03T00:00:00.000Z"}';
    File('${documents.path}/DocForge/.docforge-trash/trash-1/manifest.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(manifest);

    await LegacyPublicLibraryMigration(documents).run();

    expect(
      File(
        '${documents.path}/DocScanly/.docscanly-trash/trash-1/manifest.json',
      ).readAsStringSync(),
      manifest,
    );
  });
}
