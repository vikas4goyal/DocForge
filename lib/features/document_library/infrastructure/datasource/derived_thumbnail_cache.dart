/// Page thumbnails, derived from the PDF rather than stored beside it.
///
/// After a save the PDF is the only representation of a document that survives
/// (`design.md` D4a), so a thumbnail cannot be retained data — it is rendered
/// on first display and cached where the operating system may reclaim it.
///
/// The cache is keyed by the document's fingerprint as well as its identifier,
/// so a file edited in place — or replaced from outside the application —
/// invalidates its thumbnails instead of showing the previous version's.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';

/// Renders one page of a PDF to thumbnail-sized image bytes.
typedef ThumbnailRenderer =
    Future<Result<Uint8List>> Function(
      String filePath, {
      required int pageNumber,
      required int width,
      String? password,
    });

/// A thumbnail store that renders what it does not already hold.
class DerivedThumbnailCache {
  /// Creates a cache rooted at [cacheDirectory].
  const DerivedThumbnailCache({
    required this.cacheDirectory,
    required this.render,
    this.width = defaultWidth,
    this.directoryName = 'thumbnails',
  });

  /// The width thumbnails are rendered at, in pixels.
  ///
  /// Display resolution, not full resolution: a list row is a few hundred
  /// pixels wide, and rendering a page at its true size to draw it at that
  /// width is most of the cost of a scroll.
  static const defaultWidth = 320;

  /// The cache directory the thumbnail root sits in.
  final Directory cacheDirectory;

  /// The thumbnail root's name.
  final String directoryName;

  /// The width thumbnails are rendered at.
  final int width;

  /// Renders one page of a PDF at thumbnail size.
  ///
  /// Injected rather than constructed here so a test can render without a
  /// plugin, and so the library does not depend on the viewer.
  final ThumbnailRenderer render;

  /// The root every document's thumbnails sit under.
  Directory get root => Directory('${cacheDirectory.path}/$directoryName');

  /// Returns a path to the thumbnail for [pageNumber] of [document].
  ///
  /// Renders it from [filePath] when the cache does not hold a current one.
  /// A missing cached thumbnail is not a failure — it is the ordinary state
  /// after the operating system has reclaimed the cache.
  ///
  /// [password] is required for a protected document; without it the render
  /// fails and the caller shows a placeholder rather than a broken row.
  Future<Result<String>> thumbnailFor(
    Document document, {
    required String filePath,
    int pageNumber = 1,
    String? password,
  }) async {
    final cached = File(_pathFor(document, pageNumber));
    if (cached.existsSync()) return Result<String>.success(cached.path);

    final rendered = await render(
      filePath,
      pageNumber: pageNumber,
      width: width,
      password: password,
    );
    if (rendered case Failed(:final failure)) {
      return Result<String>.failure(failure);
    }

    try {
      cached.parent.createSync(recursive: true);
      await cached.writeAsBytes(rendered.valueOrNull!);
      return Result<String>.success(cached.path);
    } on Object catch (error) {
      return Result<String>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  /// Removes every thumbnail belonging to [id].
  ///
  /// Called when a document is deleted, and when reconciliation finds its file
  /// gone: a thumbnail of something that no longer exists is worse than none,
  /// because a list would keep rendering it.
  Future<Result<void>> evict(DocumentId id) async {
    try {
      final directory = Directory('${root.path}/${id.value}');
      if (directory.existsSync()) await directory.delete(recursive: true);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  /// Removes thumbnails for [document] that were rendered from older bytes.
  ///
  /// Keyed by fingerprint, so this is a matter of deleting the directories that
  /// do not match the document's current one.
  Future<Result<void>> invalidateStale(Document document) async {
    try {
      final directory = Directory('${root.path}/${document.id.value}');
      if (!directory.existsSync()) return const Result<void>.success(null);

      final current = _fingerprintOf(document);
      await for (final entity in directory.list()) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name == current) continue;
        if (entity is Directory) await entity.delete(recursive: true);
      }
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  /// Total bytes the thumbnail cache currently holds.
  Future<Result<int>> totalBytes() async {
    try {
      if (!root.existsSync()) return const Result<int>.success(0);

      var total = 0;
      await for (final entity in root.list(recursive: true)) {
        if (entity is File) total += entity.statSync().size;
      }
      return Result<int>.success(total);
    } on Object catch (error) {
      return Result<int>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  /// Where the thumbnail for [pageNumber] of [document] is cached.
  String _pathFor(Document document, int pageNumber) =>
      '${root.path}/${document.id.value}/${_fingerprintOf(document)}'
      '/$pageNumber.jpg';

  /// What the cached thumbnails were rendered from.
  ///
  /// Size and modified time: an in-place edit changes at least one of them, and
  /// a file replaced from outside the application changes both.
  static String _fingerprintOf(Document document) =>
      '${document.sizeInBytes}-${document.updatedAt.millisecondsSinceEpoch}';
}
