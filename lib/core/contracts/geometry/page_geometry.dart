/// The crop-and-rotate layer of a page, and how a chain of edits composes.
///
/// A page is an untouched original plus two independent layers: geometry and
/// enhancement (`design.md` D6). This is the geometry half — an ordered list of
/// the crops and rotations the user applied, kept rather than baked in, so it
/// can be reverted without disturbing the enhancement.
///
/// Applying the list literally would resample the photograph once per
/// operation, losing a little sharpness each time and costing N passes. Instead
/// the whole list composes into a single homography and the original is
/// resampled exactly once, however many times the user cropped.
library;

import 'dart:math' as math;

import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:meta/meta.dart';

/// One crop-and-rotate the user applied.
///
/// Both fields are expressed against the result of every operation before it,
/// which is the coordinate space the user was actually looking at when they
/// dragged the handles.
@immutable
class CropOp {
  /// Creates an operation.
  const CropOp({required this.quad, this.rotationDegrees = 0});

  /// The region selected, in the coordinates of the preceding result.
  final PageQuad quad;

  /// Clockwise rotation applied with the crop, in degrees.
  ///
  /// Free-form rather than quarter turns: the crop screen lets the user
  /// straighten a page by a few degrees, and rounding that to 90 would make
  /// the control useless.
  final double rotationDegrees;

  /// Whether this operation would change anything.
  ///
  /// A full-page selection at zero rotation is the identity, and applying it
  /// would re-encode the image for no benefit.
  bool get isIdentity => quad.isFullPage && rotationDegrees == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropOp &&
          other.quad == quad &&
          other.rotationDegrees == rotationDegrees;

  @override
  int get hashCode => Object.hash(quad, rotationDegrees);

  @override
  String toString() => 'CropOp($quad, $rotationDegrees°)';
}

/// The single resampling step a chain of [CropOp]s reduces to.
@immutable
class ComposedGeometry {
  /// Creates a composed transform.
  const ComposedGeometry({required this.transform, required this.outputSize});

  /// The transform mapping output pixels back onto the original image.
  final Homography transform;

  /// The size the result is rendered at.
  final CorrectedPageSize outputSize;

  /// Whether this leaves the original untouched.
  ///
  /// True for an empty chain, which is what a page with no crop applied has.
  bool get isIdentity => transform == Homography.identity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComposedGeometry &&
          other.transform == transform &&
          other.outputSize == outputSize;

  @override
  int get hashCode => Object.hash(transform, outputSize);
}

/// Composes a chain of crop operations into one transform.
abstract final class PageGeometry {
  /// Reduces [ops] to the single transform equivalent to applying them in
  /// order to an image of [imageWidth] by [imageHeight] pixels.
  ///
  /// Each step is solved against the size of the *previous* step's output,
  /// because that is the image the user was looking at when they made the
  /// selection. The results are then multiplied, which is exact — a homography
  /// composed with a homography is a homography, so nothing is approximated by
  /// doing this once instead of resampling repeatedly.
  ///
  /// An empty list yields the identity over the original's own size, so a page
  /// with no crop applied needs no special case anywhere downstream.
  static ComposedGeometry compose(
    List<CropOp> ops, {
    required int imageWidth,
    required int imageHeight,
  }) {
    var transform = Homography.identity;
    var width = imageWidth;
    var height = imageHeight;

    for (final op in ops) {
      final rotated = _withRotation(op);

      final outputSize = PerspectiveTransform.outputSizeFor(
        rotated,
        imageWidth: width,
        imageHeight: height,
      );
      final step = PerspectiveTransform.solve(
        rotated,
        imageWidth: width,
        imageHeight: height,
        outputSize: outputSize,
      );

      // `step` maps this step's output back to its input, which is the
      // previous step's output. Composing in this order — earlier steps on the
      // left — keeps the chain mapping the final output back to the original.
      transform = _multiply(transform, step);
      width = outputSize.width;
      height = outputSize.height;
    }

    return ComposedGeometry(
      transform: transform,
      outputSize: CorrectedPageSize(width, height),
    );
  }

  /// The size a chain of [ops] produces, without solving for the transform.
  ///
  /// Used to lay out a preview before the render has finished.
  static CorrectedPageSize outputSizeOf(
    List<CropOp> ops, {
    required int imageWidth,
    required int imageHeight,
  }) =>
      compose(ops, imageWidth: imageWidth, imageHeight: imageHeight).outputSize;

  /// Rewrites [op] as a quad that carries its rotation.
  ///
  /// Rotation and perspective have to be solved together rather than applied
  /// one after the other: two passes would resample twice, which is exactly
  /// what composing exists to avoid. Rotating the selection about its own
  /// centre and solving for the result gives the same picture in one pass.
  static PageQuad _withRotation(CropOp op) {
    if (op.rotationDegrees == 0) return op.quad;

    final radians = op.rotationDegrees * math.pi / 180;
    final cos = math.cos(radians);
    final sin = math.sin(radians);

    final corners = op.quad.corners;
    final centreX =
        corners.map((c) => c.x).reduce((a, b) => a + b) / corners.length;
    final centreY =
        corners.map((c) => c.y).reduce((a, b) => a + b) / corners.length;

    return PageQuad(
      topLeft: _rotate(corners[0], centreX, centreY, cos, sin),
      topRight: _rotate(corners[1], centreX, centreY, cos, sin),
      bottomRight: _rotate(corners[2], centreX, centreY, cos, sin),
      bottomLeft: _rotate(corners[3], centreX, centreY, cos, sin),
    );
  }

  /// Rotates [point] about ([centreX], [centreY]).
  static NormalisedPoint _rotate(
    NormalisedPoint point,
    double centreX,
    double centreY,
    double cos,
    double sin,
  ) {
    final dx = point.x - centreX;
    final dy = point.y - centreY;
    return NormalisedPoint(
      x: (centreX + dx * cos - dy * sin).clamp(0.0, 1.0),
      y: (centreY + dx * sin + dy * cos).clamp(0.0, 1.0),
    );
  }

  /// Multiplies two homographies, [first] then [second].
  ///
  /// Both map destination to source, so the product maps the final destination
  /// all the way back to the original image. The `h22` element is normalised
  /// back to 1, because a homography is defined only up to scale and leaving it
  /// free would make two equal transforms compare unequal.
  static Homography _multiply(Homography first, Homography second) {
    final a = [
      [first.h00, first.h01, first.h02],
      [first.h10, first.h11, first.h12],
      [first.h20, first.h21, 1.0],
    ];
    final b = [
      [second.h00, second.h01, second.h02],
      [second.h10, second.h11, second.h12],
      [second.h20, second.h21, 1.0],
    ];

    final product = List.generate(
      3,
      (row) => List.generate(3, (column) {
        var sum = 0.0;
        for (var k = 0; k < 3; k++) {
          sum += a[row][k] * b[k][column];
        }
        return sum;
      }),
    );

    final scale = product[2][2];
    if (scale.abs() < 1e-12) return Homography.identity;

    return Homography(
      h00: product[0][0] / scale,
      h01: product[0][1] / scale,
      h02: product[0][2] / scale,
      h10: product[1][0] / scale,
      h11: product[1][1] / scale,
      h12: product[1][2] / scale,
      h20: product[2][0] / scale,
      h21: product[2][1] / scale,
    );
  }
}
