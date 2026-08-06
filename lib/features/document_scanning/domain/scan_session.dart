/// The rules governing a scanning session.
///
/// Pure functions over value objects: no camera, no filesystem, no Flutter, so
/// every rule here is directly unit-testable and none of it can leak into a
/// Cubit.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';

/// A page captured in the current session, before it becomes a document page.
///
/// Holds a *path*, never bytes. The spec requires each capture to be written to
/// storage immediately with only a thumbnail retained in memory, and a value
/// object that cannot hold image data is what makes that unmissable — a large
/// batch has nothing to exhaust memory with (`design.md` §7).
class CapturedPage {
  /// Creates a captured page.
  const CapturedPage({
    required this.id,
    required this.imagePath,
    required this.quad,
    this.rotation = PageRotation.none,
    this.thumbnailPath,
    this.isCorrected = false,
  });

  /// Identifier for this capture, stable for the life of the session.
  final PageId id;

  /// Path to the full-resolution capture on disk.
  final String imagePath;

  /// The crop currently applied, detected or adjusted by the user.
  final PageQuad quad;

  /// Rotation applied when the page is rendered.
  final PageRotation rotation;

  /// Path to a display-resolution thumbnail, when one has been generated.
  final String? thumbnailPath;

  /// Whether perspective correction has already been applied to [imagePath].
  ///
  /// Tracked so a page is never corrected twice: applying the transform to an
  /// already-rectangular image would distort it further.
  final bool isCorrected;

  /// Whether the crop covers the whole page, so no correction is needed.
  bool get needsCorrection => !isCorrected && !quad.isFullPage;

  /// Returns a copy with the given fields replaced.
  CapturedPage copyWith({
    PageId? id,
    String? imagePath,
    PageQuad? quad,
    PageRotation? rotation,
    String? thumbnailPath,
    bool? isCorrected,
  }) => CapturedPage(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    quad: quad ?? this.quad,
    rotation: rotation ?? this.rotation,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    isCorrected: isCorrected ?? this.isCorrected,
  );

  /// Converts to the cross-capability page reference.
  PageRef toPageRef() =>
      PageRef(id: id, imagePath: imagePath, rotation: rotation);

  @override
  bool operator ==(Object other) =>
      other is CapturedPage &&
      other.id == id &&
      other.imagePath == imagePath &&
      other.quad == quad &&
      other.rotation == rotation &&
      other.thumbnailPath == thumbnailPath &&
      other.isCorrected == isCorrected;

  @override
  int get hashCode =>
      Object.hash(id, imagePath, quad, rotation, thumbnailPath, isCorrected);
}

/// The ordering and membership rules of a scanning session.
///
/// A session is just an ordered list of captures; these are the operations the
/// review screen offers, expressed so the screen holds none of the logic.
abstract final class ScanSessionRules {
  /// Returns [pages] with the page at [index] rotated one quarter clockwise.
  ///
  /// Rotation is metadata, not a re-encode: the file on disk is untouched and
  /// the thumbnail is rotated at render time, so rotating a page four times
  /// costs nothing and loses no quality.
  static List<CapturedPage> rotate(List<CapturedPage> pages, int index) {
    if (index < 0 || index >= pages.length) return pages;

    final updated = [...pages];
    updated[index] = updated[index].copyWith(
      rotation: updated[index].rotation.rotatedClockwise,
    );
    return updated;
  }

  /// Returns [pages] with the page at [from] moved to [to].
  ///
  /// Out-of-range indices return the list unchanged rather than throwing: a
  /// drag that ends outside the list is a normal gesture, not an error.
  static List<CapturedPage> reorder(
    List<CapturedPage> pages,
    int from,
    int to,
  ) {
    if (from < 0 || from >= pages.length) return pages;
    if (to < 0 || to >= pages.length) return pages;
    if (from == to) return pages;

    final updated = [...pages];
    updated.insert(to, updated.removeAt(from));
    return updated;
  }

  /// Returns [pages] without the page at [index].
  static List<CapturedPage> delete(List<CapturedPage> pages, int index) {
    if (index < 0 || index >= pages.length) return pages;
    return [...pages]..removeAt(index);
  }

  /// Returns [pages] with [page] re-inserted at [index].
  ///
  /// The undo half of [delete]. Restoring by index rather than appending is
  /// what makes an undo put the page back where it was rather than at the end.
  static List<CapturedPage> restore(
    List<CapturedPage> pages,
    CapturedPage page,
    int index,
  ) {
    final updated = [...pages];
    updated.insert(index.clamp(0, updated.length), page);
    return updated;
  }

  /// Whether the session can be turned into a document.
  ///
  /// The library forbids a document with no pages, so the save action stays
  /// disabled until at least one capture survives.
  static bool canSave(List<CapturedPage> pages) => pages.isNotEmpty;

  /// Converts the session into the bundle PDF generation consumes.
  static ScannedPageBundle toBundle(
    List<CapturedPage> pages, {
    PageSource source = PageSource.camera,
    String? suggestedTitle,
  }) => ScannedPageBundle(
    pages: [for (final page in pages) page.toPageRef()],
    source: source,
    suggestedTitle: suggestedTitle,
  );
}
