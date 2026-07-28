/// One page of a creation session.
///
/// A page is never "an image that gets replaced". It is an untouched original
/// plus two independent layers over it — geometry (the crops and rotations the
/// user applied) and enhancement (the settings they chose) — and everything
/// shown anywhere is derived by applying the first to the original and then the
/// second (`design.md` D6).
///
/// That is what lets either layer be reverted without disturbing the other:
/// clearing the geometry gives back the full original frame *still enhanced*,
/// and clearing the enhancement leaves the crop at its cropped size.
library;

import 'package:doc_forge/core/contracts/geometry/page_geometry.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:meta/meta.dart';

/// A page being built, holding no pixels of its own.
@immutable
class PageDraft {
  /// Creates a draft over [originalImagePath].
  const PageDraft({
    required this.id,
    required this.originalImagePath,
    this.geometry = const [],
    this.enhancement = EnhancementSettings.none,
    this.thumbnailPath,
  });

  /// Identifies this page for the life of the session.
  final PageId id;

  /// The untouched capture or picked image.
  ///
  /// Never written to. Every render starts here, which is why reverting a layer
  /// is possible at all — and why the original is retained until the session
  /// ends rather than being replaced by each edit.
  final String originalImagePath;

  /// The crops and rotations applied, in the order the user applied them.
  ///
  /// Empty means the full original frame. Kept as a list rather than collapsed
  /// to a single quad because reverting has to be exact, and because the list
  /// composes into one resampling pass anyway.
  final List<CropOp> geometry;

  /// The enhancement settings chosen for this page.
  ///
  /// Settings, not pixels: they re-apply to whatever the geometry currently
  /// produces, so cropping further does not lose them and does not double them.
  final EnhancementSettings enhancement;

  /// A cached render of this page at thumbnail size, when one exists.
  final String? thumbnailPath;

  /// Whether any crop or rotation has been applied.
  ///
  /// Drives whether "Revert to original" does anything.
  bool get hasGeometry => geometry.isNotEmpty;

  /// Whether any enhancement has been chosen.
  ///
  /// Drives whether "Revert enhancement" does anything.
  bool get hasEnhancement => !enhancement.isIdentity;

  /// Returns a copy with [op] appended to the geometry.
  ///
  /// An identity operation is ignored: applying a full-page selection at zero
  /// rotation would lengthen the chain without changing the picture.
  PageDraft withCrop(CropOp op) =>
      op.isIdentity ? this : copyWith(geometry: [...geometry, op]);

  /// Returns a copy with every crop and rotation discarded.
  ///
  /// The enhancement is deliberately untouched — that is the whole point of
  /// holding the two layers apart.
  PageDraft revertGeometry() => copyWith(geometry: const []);

  /// Returns a copy with the enhancement back at its defaults.
  ///
  /// The geometry is deliberately untouched: the page stays cropped.
  PageDraft revertEnhancement() =>
      copyWith(enhancement: EnhancementSettings.none);

  /// Returns a copy carrying [settings].
  PageDraft withEnhancement(EnhancementSettings settings) =>
      copyWith(enhancement: settings);

  /// Returns a copy with the given fields replaced.
  ///
  /// [thumbnailPath] is cleared unless supplied, because every other field on
  /// this object changes what a thumbnail should look like: keeping a stale one
  /// would show the user the page as it was before their last edit.
  PageDraft copyWith({
    PageId? id,
    String? originalImagePath,
    List<CropOp>? geometry,
    EnhancementSettings? enhancement,
    String? thumbnailPath,
  }) => PageDraft(
    id: id ?? this.id,
    originalImagePath: originalImagePath ?? this.originalImagePath,
    geometry: geometry ?? this.geometry,
    enhancement: enhancement ?? this.enhancement,
    thumbnailPath: thumbnailPath,
  );

  /// Converts to the cross-capability page reference.
  ///
  /// The reference carries the *original* path: composition applies the same
  /// geometry and enhancement when it builds the PDF, so handing it a
  /// pre-rendered image would apply both layers twice.
  PageRef toPageRef() =>
      PageRef(id: id, imagePath: originalImagePath, enhancement: enhancement);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageDraft &&
          other.id == id &&
          other.originalImagePath == originalImagePath &&
          other.enhancement == enhancement &&
          other.thumbnailPath == thumbnailPath &&
          _sameGeometry(other.geometry, geometry);

  @override
  int get hashCode => Object.hash(
    id,
    originalImagePath,
    Object.hashAll(geometry),
    enhancement,
    thumbnailPath,
  );

  @override
  String toString() =>
      'PageDraft(${id.value}, ${geometry.length} crops, $enhancement)';

  static bool _sameGeometry(List<CropOp> a, List<CropOp> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
