/// A bounded least-recently-used cache for page thumbnails.
///
/// Full-resolution page images live on disk and are never held in memory. What
/// *is* held is the display-resolution thumbnail a list row or page rail shows,
/// and even that has to be bounded: a library of several thousand documents
/// would otherwise accumulate thumbnails until the app is killed.
///
/// Two limits apply together, because either alone is insufficient — a count
/// limit says nothing about size when thumbnails vary, and a byte limit alone
/// permits unbounded bookkeeping for many tiny entries. Whichever binds first
/// triggers eviction of the least recently used entry (`design.md` §7).
library;

import 'dart:typed_data';

/// Least-recently-used cache with both a count and a byte ceiling.
///
/// Not thread-safe: it is owned by the UI isolate, which is the only place
/// thumbnails are displayed.
class ThumbnailCache {
  /// Creates a cache holding at most [maxEntries] thumbnails totalling at most
  /// [maxBytes].
  ThumbnailCache({this.maxEntries = 200, this.maxBytes = 32 * 1024 * 1024})
    : assert(maxEntries > 0, 'maxEntries must be positive'),
      assert(maxBytes > 0, 'maxBytes must be positive');

  /// Maximum number of thumbnails retained.
  final int maxEntries;

  /// Maximum total bytes retained.
  final int maxBytes;

  // A LinkedHashMap preserves insertion order, so re-inserting on access makes
  // the first key the least recently used without a separate ordering list.
  final Map<String, Uint8List> _entries = <String, Uint8List>{};

  int _bytes = 0;

  /// Number of thumbnails currently held.
  int get length => _entries.length;

  /// Total bytes currently held.
  int get bytes => _bytes;

  /// Whether the cache holds nothing.
  bool get isEmpty => _entries.isEmpty;

  /// The cached keys, least recently used first.
  Iterable<String> get keys => List.unmodifiable(_entries.keys);

  /// Returns the thumbnail cached for [key], or null when absent.
  ///
  /// A hit marks the entry as most recently used.
  Uint8List? get(String key) {
    final value = _entries.remove(key);
    if (value == null) return null;
    // Re-inserting moves it to the end, which is the most-recently-used slot.
    _entries[key] = value;
    return value;
  }

  /// Whether a thumbnail is cached for [key], without affecting its recency.
  bool containsKey(String key) => _entries.containsKey(key);

  /// Caches [value] under [key], evicting as needed to stay within both limits.
  ///
  /// A thumbnail larger than [maxBytes] on its own is not cached at all —
  /// storing it would immediately evict everything else and still not fit.
  void put(String key, Uint8List value) {
    final existing = _entries.remove(key);
    if (existing != null) _bytes -= existing.lengthInBytes;

    if (value.lengthInBytes > maxBytes) {
      _evictToFit();
      return;
    }

    _entries[key] = value;
    _bytes += value.lengthInBytes;
    _evictToFit();
  }

  /// Removes the thumbnail cached for [key], if any.
  void remove(String key) {
    final removed = _entries.remove(key);
    if (removed != null) _bytes -= removed.lengthInBytes;
  }

  /// Removes everything.
  ///
  /// Called when a document is permanently removed, so its thumbnails do not
  /// linger after the underlying files are gone.
  void clear() {
    _entries.clear();
    _bytes = 0;
  }

  /// Evicts least-recently-used entries until both limits are satisfied.
  void _evictToFit() {
    while (_entries.isNotEmpty &&
        (_entries.length > maxEntries || _bytes > maxBytes)) {
      final oldest = _entries.keys.first;
      final removed = _entries.remove(oldest);
      if (removed != null) _bytes -= removed.lengthInBytes;
    }
  }
}
