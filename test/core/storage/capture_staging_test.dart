import 'dart:io';

import 'package:doc_scanly/core/storage/capture_staging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory cache;
  late CaptureStaging staging;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('docscanly_staging_');
    staging = CaptureStaging(cache);
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  /// Writes a page image into [sessionId]'s directory.
  File writeCapture(String sessionId, String name) {
    final file = File('${staging.directoryFor(sessionId).path}/$name')
      ..writeAsStringSync('jpeg-bytes');
    return file;
  }

  group('directoryFor', () {
    test('creates a directory per session', () {
      final directory = staging.directoryFor('session-1');

      expect(directory.existsSync(), isTrue);
      expect(directory.path, endsWith('creation/session-1'));
    });

    test('returns the same directory on a second call', () {
      final first = staging.directoryFor('session-1');
      writeCapture('session-1', 'page.jpg');

      final second = staging.directoryFor('session-1');

      expect(second.path, first.path);
      expect(second.listSync(), hasLength(1));
    });

    test('sessions do not see each other', () {
      writeCapture('session-1', 'page.jpg');
      writeCapture('session-2', 'page.jpg');

      expect(staging.directoryFor('session-1').listSync(), hasLength(1));
      expect(staging.directoryFor('session-2').listSync(), hasLength(1));
    });
  });

  group('discardSession', () {
    test('removes every capture the session made', () async {
      writeCapture('session-1', 'page-1.jpg');
      writeCapture('session-1', 'page-2.jpg');

      final result = await staging.discardSession('session-1');

      expect(result.isSuccess, isTrue);
      expect(Directory('${staging.root.path}/session-1').existsSync(), isFalse);
    });

    test('leaves other sessions alone', () async {
      writeCapture('session-1', 'page.jpg');
      writeCapture('session-2', 'page.jpg');

      await staging.discardSession('session-1');

      expect(staging.directoryFor('session-2').listSync(), hasLength(1));
    });

    test('discarding twice succeeds', () async {
      writeCapture('session-1', 'page.jpg');
      await staging.discardSession('session-1');

      // Cleanup runs on the save path and the discard path; both must be safe
      // to repeat, or a retry after a partial failure would itself fail.
      expect((await staging.discardSession('session-1')).isSuccess, isTrue);
    });

    test('discarding a session that never existed succeeds', () async {
      expect((await staging.discardSession('never')).isSuccess, isTrue);
    });
  });

  group('sweepOrphans', () {
    test('removes sessions left by a killed run', () async {
      writeCapture('dead-1', 'page.jpg');
      writeCapture('dead-2', 'page.jpg');

      final result = await staging.sweepOrphans();

      expect(result.valueOrNull, 2);
      expect(staging.root.listSync(), isEmpty);
    });

    test('spares a session that is still open', () async {
      writeCapture('open', 'page.jpg');
      writeCapture('dead', 'page.jpg');

      final result = await staging.sweepOrphans(keep: {'open'});

      expect(result.valueOrNull, 1);
      expect(Directory('${staging.root.path}/open').existsSync(), isTrue);
    });

    test('removes stray files as well as directories', () async {
      staging.root.createSync(recursive: true);
      File('${staging.root.path}/stray.jpg').writeAsStringSync('bytes');

      expect((await staging.sweepOrphans()).valueOrNull, 1);
    });

    test('succeeds when nothing has ever been staged', () async {
      expect((await staging.sweepOrphans()).valueOrNull, 0);
    });
  });

  group('totalBytes', () {
    test('sums what open sessions hold', () async {
      writeCapture('session-1', 'page-1.jpg');
      writeCapture('session-2', 'page-2.jpg');

      expect((await staging.totalBytes()).valueOrNull, 'jpeg-bytes'.length * 2);
    });

    test('is zero when nothing is staged', () async {
      expect((await staging.totalBytes()).valueOrNull, 0);
    });

    test('is zero after a sweep', () async {
      writeCapture('session-1', 'page.jpg');
      await staging.sweepOrphans();

      expect((await staging.totalBytes()).valueOrNull, 0);
    });
  });
}
