// ignore_for_file: avoid_slow_async_io

import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/features/document_library/infrastructure/document_page_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('page-cache-');
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  File target(String document, String fingerprint, String name) =>
      File('${directory.path}/$document/$fingerprint/$name.png');

  test('prunes by count and bytes using least-recently-used order', () async {
    var tick = 0;
    final cache = DocumentPageCacheMaintenance(
      root: directory,
      maxFiles: 2,
      maxBytes: 6,
      now: () => DateTime.utc(2026, 1, 1, 0, 0, tick++),
    );
    final first = target('a', 'v1', '1');
    final second = target('b', 'v1', '1');
    final third = target('c', 'v1', '1');

    await cache.write(first, Uint8List.fromList([1, 2, 3]));
    await cache.write(second, Uint8List.fromList([1, 2, 3]));
    await cache.touch(first);
    await cache.write(third, Uint8List.fromList([1, 2, 3]));

    final files = await directory
        .list(recursive: true)
        .where((entry) => entry is File)
        .toList();
    expect(files, hasLength(2));
    expect(await first.exists(), isTrue);
    expect(await second.exists(), isFalse);
    expect(await third.exists(), isTrue);
    expect(
      (await Future.wait(
        files.cast<File>().map((file) => file.length()),
      )).fold<int>(0, (sum, size) => sum + size),
      lessThanOrEqualTo(6),
    );
  });

  test('path is the deterministic tie-breaker for equal timestamps', () async {
    final sameTime = DateTime.utc(2026);
    final first = target('a', 'v1', '1');
    final second = target('b', 'v1', '1');
    for (final file in [first, second]) {
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1]);
      await file.setLastModified(sameTime);
    }
    final cache = DocumentPageCacheMaintenance(
      root: directory,
      maxFiles: 2,
      maxBytes: 3,
      now: () => sameTime,
    );

    await cache.write(target('c', 'v1', '1'), Uint8List.fromList([1]));

    expect(await first.exists(), isFalse);
    expect(await second.exists(), isTrue);
  });

  test('a cache hit refreshes its timestamp', () async {
    final written = DateTime.utc(2026);
    final touched = written.add(const Duration(hours: 1));
    var now = written;
    final cache = DocumentPageCacheMaintenance(root: directory, now: () => now);
    final file = target('a', 'v1', '1');
    await cache.write(file, Uint8List.fromList([1]));

    now = touched;
    final result = await cache.touch(file);

    expect(result.valueOrNull, isTrue);
    expect((await file.stat()).modified.toUtc(), touched);
  });

  test('concurrent writes finish within both global limits', () async {
    final cache = DocumentPageCacheMaintenance(
      root: directory,
      maxFiles: 3,
      maxBytes: 9,
    );

    await Future.wait([
      for (var index = 0; index < 12; index++)
        cache.write(
          target('doc-$index', 'v1', '1'),
          Uint8List.fromList([1, 2, 3]),
        ),
    ]);

    final files = await directory
        .list(recursive: true)
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    expect(files.length, lessThanOrEqualTo(3));
    expect(
      (await Future.wait(
        files.map((file) => file.length()),
      )).fold<int>(0, (sum, size) => sum + size),
      lessThanOrEqualTo(9),
    );
  });
}
