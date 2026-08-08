/// Deterministic maintenance for reproducible PDF page previews.
library;

// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Supplies timestamps for cache access ordering.
typedef PageCacheClock = DateTime Function();

/// Deletes one reproducible cache file during maintenance.
typedef PageCacheDelete = Future<void> Function(File file);

/// Bounds the private `document-pages` cache by count and total bytes.
///
/// Maintenance is serialized so two concurrent renders cannot both observe
/// spare capacity and then exceed the limits. Entries are evicted by oldest
/// access/modification time, with path as a stable tie-breaker.
class DocumentPageCacheMaintenance {
  /// Creates cache maintenance rooted at [root].
  DocumentPageCacheMaintenance({
    required this.root,
    this.maxFiles = defaultMaxFiles,
    this.maxBytes = defaultMaxBytes,
    PageCacheClock? now,
    PageCacheDelete? deleteFile,
  }) : _now = now ?? DateTime.now,
       _deleteFile = deleteFile ?? _delete;

  /// Default global file-count limit.
  static const defaultMaxFiles = 128;

  /// Default global byte limit (64 MiB).
  static const defaultMaxBytes = 64 * 1024 * 1024;

  /// Root containing reproducible page previews only.
  final Directory root;

  /// Maximum number of cached files.
  final int maxFiles;

  /// Maximum aggregate cached bytes.
  final int maxBytes;

  final PageCacheClock _now;
  final PageCacheDelete _deleteFile;
  Future<void> _tail = Future<void>.value();

  /// Returns whether [target] is a hit and refreshes its LRU timestamp.
  Future<Result<bool>> touch(File target) => _serialized(() async {
    try {
      if (!await target.exists()) return const Result<bool>.success(false);
      await target.setLastModified(_now());
      return const Result<bool>.success(true);
    } on Object catch (error) {
      return Result<bool>.failure(Failure.storage(debugDetail: '$error'));
    }
  });

  /// Prunes before atomically accepting [bytes] at [target].
  ///
  /// The target and the fingerprint directory being produced are never
  /// candidates. Older fingerprints for the same document are invalidated
  /// before ordinary global LRU pruning.
  Future<Result<void>> write(File target, Uint8List bytes) => _serialized(
    () async {
      if (maxFiles < 1 || bytes.length > maxBytes) {
        return const Result<void>.failure(
          Failure.storage(
            debugDetail: 'Rendered page exceeds document-page cache limits.',
          ),
        );
      }

      try {
        await root.create(recursive: true);
        final currentFingerprint = target.parent.path;
        final currentDocument = target.parent.parent.path;
        final entries = await _entries();

        // A changed PDF has a new fingerprint directory. Its prior previews
        // are reproducible and must not survive as stale cache entries.
        for (final entry in entries) {
          if (entry.file.path != target.path &&
              entry.file.parent.parent.path == currentDocument &&
              entry.file.parent.path != currentFingerprint) {
            await _deleteFile(entry.file);
          }
        }

        final remaining = await _entries();
        final existing = remaining
            .where((entry) => entry.file.path == target.path)
            .firstOrNull;
        var count = remaining.length - (existing == null ? 0 : 1);
        var size = remaining.fold<int>(
          0,
          (total, entry) =>
              total + (entry.file.path == target.path ? 0 : entry.size),
        );
        final candidates =
            [
              for (final entry in remaining)
                if (entry.file.path != target.path) entry,
            ]..sort((a, b) {
              final byTime = a.modified.compareTo(b.modified);
              return byTime != 0 ? byTime : a.file.path.compareTo(b.file.path);
            });

        var candidate = 0;
        while (count + 1 > maxFiles || size + bytes.length > maxBytes) {
          if (candidate >= candidates.length) {
            return const Result<void>.failure(
              Failure.storage(
                debugDetail: 'Document-page cache could not be bounded.',
              ),
            );
          }
          final evicted = candidates[candidate++];
          await _deleteFile(evicted.file);
          count -= 1;
          size -= evicted.size;
        }

        await target.parent.create(recursive: true);
        await target.writeAsBytes(bytes, flush: true);
        await target.setLastModified(_now());
        return const Result<void>.success(null);
      } on Object catch (error) {
        return Result<void>.failure(Failure.storage(debugDetail: '$error'));
      }
    },
  );

  Future<List<_CacheEntry>> _entries() async {
    if (!await root.exists()) return const [];
    final entries = <_CacheEntry>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      entries.add(
        _CacheEntry(file: entity, size: stat.size, modified: stat.modified),
      );
    }
    return entries;
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  static Future<void> _delete(File file) => file.delete();
}

class _CacheEntry {
  const _CacheEntry({
    required this.file,
    required this.size,
    required this.modified,
  });

  final File file;
  final int size;
  final DateTime modified;
}
