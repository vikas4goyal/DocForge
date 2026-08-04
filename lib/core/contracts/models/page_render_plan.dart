/// What a page should look like, as a value.
///
/// Everything the user sees of a page — the row thumbnail, the crop screen, the
/// enhancement preview, the generated PDF — is the same pipeline: apply the
/// geometry to the original, then apply the enhancement (`design.md` D6).
///
/// Describing that as a value with equality is what makes rendering cacheable:
/// a plan that has not changed has a render that is still correct, and a plan
/// that has changed invalidates its own cache by not matching the old key.
library;

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:meta/meta.dart';

/// How large a render is wanted.
enum RenderScale {
  /// Display resolution, for a thumbnail or an on-screen preview.
  ///
  /// A page rendered at its true size to be drawn a few hundred pixels wide is
  /// most of the cost of a scroll, and none of it reaches the user's eye.
  preview,

  /// Full resolution, for the page that goes into the PDF.
  full,
}

/// A page's appearance, as a value.
@immutable
class PageRenderPlan {
  /// Creates a plan.
  const PageRenderPlan({
    required this.originalImagePath,
    required this.geometry,
    required this.enhancement,
    this.scale = RenderScale.preview,
  });

  /// Builds the plan describing [draft] at [scale].
  factory PageRenderPlan.of(
    PageDraft draft, {
    RenderScale scale = RenderScale.preview,
  }) => PageRenderPlan(
    originalImagePath: draft.originalImagePath,
    geometry: draft.geometry,
    enhancement: draft.enhancement,
    scale: scale,
  );

  /// The untouched image every render starts from.
  final String originalImagePath;

  /// The crops and rotations to apply, in order.
  final List<CropOp> geometry;

  /// The enhancement to apply afterwards.
  final EnhancementSettings enhancement;

  /// How large the result should be.
  final RenderScale scale;

  /// Whether this plan leaves the original untouched.
  ///
  /// A page with neither layer applied needs no render at all: the original is
  /// already what the user should see.
  bool get isPassThrough => geometry.isEmpty && enhancement.isIdentity;

  /// A stable key identifying this plan.
  ///
  /// Used as a cache file name, so it has to be filesystem-safe and has to
  /// change whenever anything about the appearance changes.
  String get cacheKey {
    final buffer = StringBuffer()
      ..write(originalImagePath.hashCode.toUnsigned(32).toRadixString(16))
      ..write('-')
      ..write(scale.name)
      ..write('-')
      ..write(Object.hashAll(geometry).toUnsigned(32).toRadixString(16))
      ..write('-')
      ..write(enhancement.hashCode.toUnsigned(32).toRadixString(16));
    return buffer.toString();
  }

  /// Returns a copy at [scale].
  PageRenderPlan atScale(RenderScale scale) => PageRenderPlan(
    originalImagePath: originalImagePath,
    geometry: geometry,
    enhancement: enhancement,
    scale: scale,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRenderPlan &&
          other.originalImagePath == originalImagePath &&
          other.enhancement == enhancement &&
          other.scale == scale &&
          _sameGeometry(other.geometry, geometry);

  @override
  int get hashCode => Object.hash(
    originalImagePath,
    Object.hashAll(geometry),
    enhancement,
    scale,
  );

  @override
  String toString() => 'PageRenderPlan($cacheKey)';

  static bool _sameGeometry(List<CropOp> a, List<CropOp> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
