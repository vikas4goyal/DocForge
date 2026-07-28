import 'dart:io';
import 'dart:typed_data';

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_library/infrastructure/datasource/derived_thumbnail_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory cache;
  late List<String> renders;
  late Failure? renderFailure;
  late DerivedThumbnailCache thumbnails;

  Document document({int sizeBytes = 1024, DateTime? updatedAt}) => Document(
    id: const DocumentId('doc-1'),
    title: 'Invoice',
    createdAt: DateTime.utc(2026),
    updatedAt: updatedAt ?? DateTime.utc(2026, 3),
    pageCount: 4,
    sizeInBytes: sizeBytes,
    libraryPath: LibraryPath.parse('Invoice.pdf'),
  );

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('docforge_thumbs_');
    renders = [];
    renderFailure = null;
    thumbnails = DerivedThumbnailCache(
      cacheDirectory: cache,
      render: (path, {required pageNumber, required width, password}) async {
        renders.add('$path#$pageNumber@$width');
        final configured = renderFailure;
        return configured == null
            ? Result<Uint8List>.success(Uint8List.fromList([1, 2, 3]))
            : Result<Uint8List>.failure(configured);
      },
    );
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  group('rendering', () {
    test('renders a thumbnail that is not cached', () async {
      final result = await thumbnails.thumbnailFor(
        document(),
        filePath: '/library/Invoice.pdf',
      );

      expect(result.isSuccess, isTrue);
      expect(File(result.valueOrNull!).readAsBytesSync(), [1, 2, 3]);
      expect(renders, hasLength(1));
    });

    test('reuses a cached thumbnail rather than rendering again', () async {
      final subject = document();
      await thumbnails.thumbnailFor(subject, filePath: '/library/Invoice.pdf');

      await thumbnails.thumbnailFor(subject, filePath: '/library/Invoice.pdf');

      // Re-rendering on every list frame is most of the cost of a scroll.
      expect(renders, hasLength(1));
    });

    test('renders at display width, not full resolution', () async {
      await thumbnails.thumbnailFor(
        document(),
        filePath: '/library/Invoice.pdf',
      );

      expect(
        renders.single,
        endsWith('@${DerivedThumbnailCache.defaultWidth}'),
      );
    });

    test('renders each page separately', () async {
      final subject = document();
      await thumbnails.thumbnailFor(subject, filePath: '/x.pdf');
      await thumbnails.thumbnailFor(subject, filePath: '/x.pdf', pageNumber: 2);

      expect(renders, hasLength(2));
    });

    test('a render failure is reported rather than cached', () async {
      renderFailure = const Failure.corruptFile();

      final result = await thumbnails.thumbnailFor(
        document(),
        filePath: '/library/Invoice.pdf',
      );

      expect(result.isFailure, isTrue);
    });

    test('re-renders after the cache is reclaimed', () async {
      final subject = document();
      final first = await thumbnails.thumbnailFor(subject, filePath: '/x.pdf');
      // The operating system may reclaim the cache at any time; a missing
      // thumbnail is the ordinary state, not a failure.
      File(first.valueOrNull!).deleteSync();

      final second = await thumbnails.thumbnailFor(subject, filePath: '/x.pdf');

      expect(second.isSuccess, isTrue);
      expect(renders, hasLength(2));
    });
  });

  group('invalidation', () {
    test('a file edited in place gets a fresh thumbnail', () async {
      await thumbnails.thumbnailFor(document(sizeBytes: 100), filePath: '/x');

      await thumbnails.thumbnailFor(document(sizeBytes: 200), filePath: '/x');

      // Serving the old thumbnail would show the previous version of a page
      // the user has just changed.
      expect(renders, hasLength(2));
    });

    test('a file replaced from outside gets a fresh thumbnail', () async {
      await thumbnails.thumbnailFor(
        document(updatedAt: DateTime.utc(2026, 3)),
        filePath: '/x',
      );

      await thumbnails.thumbnailFor(
        document(updatedAt: DateTime.utc(2026, 4)),
        filePath: '/x',
      );

      expect(renders, hasLength(2));
    });

    test('invalidateStale removes only the superseded renders', () async {
      final old = document(sizeBytes: 100);
      final current = document(sizeBytes: 200);
      final oldPath = (await thumbnails.thumbnailFor(
        old,
        filePath: '/x',
      )).valueOrNull!;
      final currentPath = (await thumbnails.thumbnailFor(
        current,
        filePath: '/x',
      )).valueOrNull!;

      await thumbnails.invalidateStale(current);

      expect(File(oldPath).existsSync(), isFalse);
      expect(File(currentPath).existsSync(), isTrue);
    });

    test('invalidateStale on an unknown document succeeds', () async {
      expect((await thumbnails.invalidateStale(document())).isSuccess, isTrue);
    });
  });

  group('eviction', () {
    test('evict removes every thumbnail of a document', () async {
      final subject = document();
      final path = (await thumbnails.thumbnailFor(
        subject,
        filePath: '/x',
      )).valueOrNull!;

      await thumbnails.evict(subject.id);

      expect(File(path).existsSync(), isFalse);
    });

    test('evicting an unknown document succeeds', () async {
      expect(
        (await thumbnails.evict(const DocumentId('never'))).isSuccess,
        isTrue,
      );
    });
  });

  group('totalBytes', () {
    test('reports what the cache holds', () async {
      await thumbnails.thumbnailFor(document(), filePath: '/x');

      expect((await thumbnails.totalBytes()).valueOrNull, 3);
    });

    test('is zero before anything is rendered', () async {
      expect((await thumbnails.totalBytes()).valueOrNull, 0);
    });
  });
}
