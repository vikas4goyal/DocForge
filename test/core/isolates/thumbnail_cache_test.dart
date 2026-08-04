import 'dart:typed_data';

import 'package:doc_scanly/core/isolates/thumbnail_cache.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a thumbnail of [size] bytes.
Uint8List thumb(int size) => Uint8List(size);

void main() {
  group('basic storage', () {
    test('starts empty', () {
      final cache = ThumbnailCache();

      expect(cache.isEmpty, isTrue);
      expect(cache.length, 0);
      expect(cache.bytes, 0);
    });

    test('stores and retrieves a thumbnail', () {
      final cache = ThumbnailCache();
      final value = thumb(10);

      cache.put('a', value);

      expect(cache.get('a'), same(value));
      expect(cache.length, 1);
      expect(cache.bytes, 10);
    });

    test('returns null for an absent key', () {
      expect(ThumbnailCache().get('missing'), isNull);
    });

    test('containsKey reports presence', () {
      final cache = ThumbnailCache()..put('a', thumb(1));

      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('replacing a key does not double-count its bytes', () {
      final cache = ThumbnailCache()
        ..put('a', thumb(10))
        ..put('a', thumb(30));

      expect(cache.length, 1);
      expect(cache.bytes, 30);
    });

    test('removes a single entry and its bytes', () {
      final cache = ThumbnailCache()
        ..put('a', thumb(10))
        ..put('b', thumb(20))
        ..remove('a');

      expect(cache.containsKey('a'), isFalse);
      expect(cache.bytes, 20);
    });

    test('removing an absent key is safe', () {
      final cache = ThumbnailCache()..put('a', thumb(10));

      cache.remove('missing');

      expect(cache.bytes, 10);
    });

    test('clear empties the cache and resets the byte count', () {
      final cache = ThumbnailCache()
        ..put('a', thumb(10))
        ..put('b', thumb(20))
        ..clear();

      expect(cache.isEmpty, isTrue);
      expect(cache.bytes, 0);
    });
  });

  group('count limit', () {
    test('evicts the least recently used entry when full', () {
      final cache = ThumbnailCache(maxEntries: 2)
        ..put('a', thumb(1))
        ..put('b', thumb(1))
        ..put('c', thumb(1));

      expect(cache.containsKey('a'), isFalse);
      expect(cache.containsKey('b'), isTrue);
      expect(cache.containsKey('c'), isTrue);
      expect(cache.length, 2);
    });

    test('never exceeds the entry limit', () {
      final cache = ThumbnailCache(maxEntries: 3);

      for (var i = 0; i < 50; i++) {
        cache.put('key-$i', thumb(1));
      }

      expect(cache.length, 3);
    });
  });

  group('byte limit', () {
    test('evicts until the byte ceiling is satisfied', () {
      final cache = ThumbnailCache(maxEntries: 100, maxBytes: 100)
        ..put('a', thumb(60))
        ..put('b', thumb(60));

      // 'a' must go: 60 + 60 exceeds 100.
      expect(cache.containsKey('a'), isFalse);
      expect(cache.containsKey('b'), isTrue);
      expect(cache.bytes, 60);
    });

    test('evicts several entries when one large entry arrives', () {
      final cache = ThumbnailCache(maxEntries: 100, maxBytes: 100)
        ..put('a', thumb(30))
        ..put('b', thumb(30))
        ..put('c', thumb(30))
        ..put('d', thumb(90));

      expect(cache.containsKey('d'), isTrue);
      expect(cache.bytes, lessThanOrEqualTo(100));
      expect(cache.containsKey('a'), isFalse);
      expect(cache.containsKey('b'), isFalse);
    });

    test('never exceeds the byte ceiling', () {
      final cache = ThumbnailCache(maxEntries: 1000, maxBytes: 500);

      for (var i = 0; i < 100; i++) {
        cache.put('key-$i', thumb(80));
      }

      expect(cache.bytes, lessThanOrEqualTo(500));
    });

    test('an oversized thumbnail is not cached and evicts nothing else', () {
      final cache = ThumbnailCache(maxEntries: 10, maxBytes: 100)
        ..put('a', thumb(50));

      cache.put('huge', thumb(500));

      // Caching it would evict everything and still not fit.
      expect(cache.containsKey('huge'), isFalse);
      expect(cache.containsKey('a'), isTrue);
      expect(cache.bytes, 50);
    });

    test('replacing an entry with an oversized one removes the original', () {
      final cache = ThumbnailCache(maxEntries: 10, maxBytes: 100)
        ..put('a', thumb(50));

      cache.put('a', thumb(500));

      expect(cache.containsKey('a'), isFalse);
      expect(cache.bytes, 0);
    });
  });

  group('recency', () {
    test('a hit promotes an entry away from eviction', () {
      final cache = ThumbnailCache(maxEntries: 2)
        ..put('a', thumb(1))
        ..put('b', thumb(1));

      // Touch 'a' so 'b' becomes least recently used.
      cache.get('a');
      cache.put('c', thumb(1));

      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
      expect(cache.containsKey('c'), isTrue);
    });

    test('containsKey does not affect recency', () {
      final cache = ThumbnailCache(maxEntries: 2)
        ..put('a', thumb(1))
        ..put('b', thumb(1));

      cache.containsKey('a');
      cache.put('c', thumb(1));

      // 'a' was still the least recently used, so it goes.
      expect(cache.containsKey('a'), isFalse);
    });

    test('a miss does not change ordering', () {
      final cache = ThumbnailCache(maxEntries: 2)
        ..put('a', thumb(1))
        ..put('b', thumb(1));

      cache.get('nonexistent');
      cache.put('c', thumb(1));

      expect(cache.containsKey('a'), isFalse);
    });

    test('keys are reported least recently used first', () {
      final cache = ThumbnailCache()
        ..put('a', thumb(1))
        ..put('b', thumb(1))
        ..put('c', thumb(1));

      cache.get('a');

      expect(cache.keys.toList(), ['b', 'c', 'a']);
    });
  });

  group('construction', () {
    test('rejects non-positive limits', () {
      expect(() => ThumbnailCache(maxEntries: 0), throwsAssertionError);
      expect(() => ThumbnailCache(maxBytes: 0), throwsAssertionError);
    });

    test('has bounded defaults', () {
      final cache = ThumbnailCache();

      expect(cache.maxEntries, greaterThan(0));
      expect(cache.maxBytes, greaterThan(0));
    });
  });
}
