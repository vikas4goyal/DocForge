/// The perspective-correction maths.
///
/// Pure Dart with no image library and no isolate: the transform is derived and
/// tested here against known fixtures, and the code that actually moves pixels
/// (`infrastructure/`) applies it. Splitting them is what lets the maths — the
/// part that is genuinely easy to get subtly wrong — be verified by hand-checked
/// numbers rather than by comparing photographs.
library;

import 'dart:math' as math;

import 'package:doc_scanly/core/contracts/models/page.dart';

/// A 3×3 homography mapping output page coordinates to input image coordinates.
///
/// Stored row-major with `h22` fixed at 1. A homography is defined only up to
/// scale, so fixing one element removes that freedom and makes two transforms
/// comparable by value.
///
/// The direction matters: this maps *destination* to *source*. Resampling walks
/// every output pixel and asks where it came from, because the reverse — walking
/// input pixels and scattering them forwards — leaves unwritten holes wherever
/// the transform expands the image.
class Homography {
  /// Creates a homography from its eight free coefficients.
  const Homography({
    required this.h00,
    required this.h01,
    required this.h02,
    required this.h10,
    required this.h11,
    required this.h12,
    required this.h20,
    required this.h21,
  });

  /// The identity transform, which leaves every point where it is.
  static const identity = Homography(
    h00: 1,
    h01: 0,
    h02: 0,
    h10: 0,
    h11: 1,
    h12: 0,
    h20: 0,
    h21: 0,
  );

  /// Row 0, column 0.
  final double h00;

  /// Row 0, column 1.
  final double h01;

  /// Row 0, column 2.
  final double h02;

  /// Row 1, column 0.
  final double h10;

  /// Row 1, column 1.
  final double h11;

  /// Row 1, column 2.
  final double h12;

  /// Row 2, column 0.
  final double h20;

  /// Row 2, column 1.
  final double h21;

  /// Maps the point ([x], [y]) through this transform.
  ///
  /// The divide by `w` is the perspective part: it is what makes the far edge
  /// of a tilted page compress and the near edge spread, rather than the whole
  /// page merely being sheared.
  ({double x, double y}) apply(double x, double y) {
    final w = h20 * x + h21 * y + 1;

    // A degenerate quad can drive w to zero, which would send the point to
    // infinity. Falling back to the input point keeps a bad crop from producing
    // NaN coordinates that propagate into every later pixel.
    if (w.abs() < 1e-12) return (x: x, y: y);

    return (x: (h00 * x + h01 * y + h02) / w, y: (h10 * x + h11 * y + h12) / w);
  }

  /// Whether every coefficient is finite.
  ///
  /// Checked before a transform is used: a non-finite coefficient means the
  /// solve failed, and applying it would produce an unrecoverable image.
  bool get isValid =>
      [h00, h01, h02, h10, h11, h12, h20, h21].every((v) => v.isFinite);

  @override
  bool operator ==(Object other) =>
      other is Homography &&
      _closeTo(other.h00, h00) &&
      _closeTo(other.h01, h01) &&
      _closeTo(other.h02, h02) &&
      _closeTo(other.h10, h10) &&
      _closeTo(other.h11, h11) &&
      _closeTo(other.h12, h12) &&
      _closeTo(other.h20, h20) &&
      _closeTo(other.h21, h21);

  @override
  int get hashCode => Object.hash(h00, h01, h02, h10, h11, h12, h20, h21);

  static bool _closeTo(double a, double b) => (a - b).abs() < 1e-9;

  @override
  String toString() =>
      'Homography($h00, $h01, $h02, $h10, $h11, $h12, $h20, $h21)';
}

/// The size of the rectangle a corrected page is rendered into.
class CorrectedPageSize {
  /// Creates a size in pixels.
  const CorrectedPageSize(this.width, this.height);

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  @override
  bool operator ==(Object other) =>
      other is CorrectedPageSize &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}

/// Derives and applies the perspective correction for a cropped page.
abstract final class PerspectiveTransform {
  /// Computes the output size for [quad] over an image of [imageWidth] by
  /// [imageHeight] pixels.
  ///
  /// Each output dimension is the longer of the two corresponding quad edges.
  /// Taking the longer edge rather than the average or the shorter one means
  /// the correction never *discards* detail: the compressed far edge is
  /// stretched up to match the near edge, instead of the near edge being
  /// squashed down and its resolution thrown away.
  static CorrectedPageSize outputSizeFor(
    PageQuad quad, {
    required int imageWidth,
    required int imageHeight,
  }) {
    double distance(NormalisedPoint a, NormalisedPoint b) {
      final dx = (a.x - b.x) * imageWidth;
      final dy = (a.y - b.y) * imageHeight;
      return math.sqrt(dx * dx + dy * dy);
    }

    final top = distance(quad.topLeft, quad.topRight);
    final bottom = distance(quad.bottomLeft, quad.bottomRight);
    final left = distance(quad.topLeft, quad.bottomLeft);
    final right = distance(quad.topRight, quad.bottomRight);

    // At least one pixel each way: a degenerate quad must not produce a
    // zero-sized image that every downstream step then has to special-case.
    return CorrectedPageSize(
      math.max(1, math.max(top, bottom).round()),
      math.max(1, math.max(left, right).round()),
    );
  }

  /// Solves the homography mapping the output rectangle back onto [quad].
  ///
  /// The four corners of the output rectangle map to the four corners of the
  /// quad, which is exactly eight equations in the eight unknowns — a unique
  /// solution, no least-squares fitting involved.
  ///
  /// For each corresponding pair (destination `(u,v)` → source `(x,y)`), the
  /// two rows are:
  ///
  /// ```
  /// [u v 1 0 0 0 -u·x -v·x] · h = x
  /// [0 0 0 u v 1 -u·y -v·y] · h = y
  /// ```
  ///
  /// which is the projective relation `x = (h00·u + h01·v + h02) / (h20·u +
  /// h21·v + 1)` rearranged to be linear in the unknowns. Solved by Gaussian
  /// elimination with partial pivoting; the pivoting matters because a quad
  /// with an axis-aligned edge produces zeros on the diagonal.
  ///
  /// Returns [Homography.identity] when the system is singular, which happens
  /// for a quad with collinear or coincident corners. An identity transform
  /// leaves the capture untouched — the spec's requirement that a bad crop
  /// never costs the user the capture.
  static Homography solve(
    PageQuad quad, {
    required int imageWidth,
    required int imageHeight,
    required CorrectedPageSize outputSize,
  }) {
    final w = outputSize.width.toDouble();
    final h = outputSize.height.toDouble();

    // Destination corners: the output rectangle, in the same corner order the
    // quad uses, so corner i of one maps to corner i of the other.
    final destination = [
      (u: 0.0, v: 0.0),
      (u: w, v: 0.0),
      (u: w, v: h),
      (u: 0.0, v: h),
    ];

    // Source corners: the quad, converted from normalised to pixel coordinates.
    final source = [
      for (final corner in quad.corners)
        (x: corner.x * imageWidth, y: corner.y * imageHeight),
    ];

    final matrix = List.generate(8, (_) => List<double>.filled(9, 0));

    for (var i = 0; i < 4; i++) {
      final (:u, :v) = destination[i];
      final (:x, :y) = source[i];

      matrix[i * 2] = [u, v, 1, 0, 0, 0, -u * x, -v * x, x];
      matrix[i * 2 + 1] = [0, 0, 0, u, v, 1, -u * y, -v * y, y];
    }

    final solution = _solve(matrix);
    if (solution == null) return Homography.identity;

    final result = Homography(
      h00: solution[0],
      h01: solution[1],
      h02: solution[2],
      h10: solution[3],
      h11: solution[4],
      h12: solution[5],
      h20: solution[6],
      h21: solution[7],
    );

    return result.isValid ? result : Homography.identity;
  }

  /// Gaussian elimination with partial pivoting on an 8×9 augmented matrix.
  ///
  /// Returns null when the system is singular.
  static List<double>? _solve(List<List<double>> matrix) {
    const size = 8;

    for (var column = 0; column < size; column++) {
      // Partial pivoting: swap in the row with the largest magnitude in this
      // column. Without it a legitimate quad with an axis-aligned edge divides
      // by a zero pivot and the whole solve collapses.
      var pivot = column;
      for (var row = column + 1; row < size; row++) {
        if (matrix[row][column].abs() > matrix[pivot][column].abs()) {
          pivot = row;
        }
      }

      if (matrix[pivot][column].abs() < 1e-12) return null;

      if (pivot != column) {
        final swap = matrix[pivot];
        matrix[pivot] = matrix[column];
        matrix[column] = swap;
      }

      final divisor = matrix[column][column];
      for (var c = column; c <= size; c++) {
        matrix[column][c] /= divisor;
      }

      for (var row = 0; row < size; row++) {
        if (row == column) continue;
        final factor = matrix[row][column];
        if (factor == 0) continue;

        for (var c = column; c <= size; c++) {
          matrix[row][c] -= factor * matrix[column][c];
        }
      }
    }

    return [for (var row = 0; row < size; row++) matrix[row][size]];
  }
}

/// What a correction job needs, and all that crosses the isolate boundary.
///
/// Paths and eight doubles — no decoded image. Sending a full-resolution bitmap
/// to an isolate copies it, and a batch correction would run out of memory long
/// before it finished (`design.md` §7).
class PageCorrectionRequest {
  /// Creates a correction request.
  const PageCorrectionRequest({
    required this.sourcePath,
    required this.destinationPath,
    required this.corners,
  }) : assert(corners.length == 8, 'need four x,y pairs');

  /// Creates a request for [quad], flattening it for the isolate boundary.
  factory PageCorrectionRequest.forQuad({
    required String sourcePath,
    required String destinationPath,
    required PageQuad quad,
  }) => PageCorrectionRequest(
    sourcePath: sourcePath,
    destinationPath: destinationPath,
    corners: [
      for (final corner in quad.corners) ...[corner.x, corner.y],
    ],
  );

  /// Path to the capture to correct.
  final String sourcePath;

  /// Path the corrected page is written to.
  final String destinationPath;

  /// Corner coordinates in canonical order, x before y, normalised.
  ///
  /// A flat list rather than the `PageQuad` itself: the Freezed type would
  /// survive the copy, but a payload type that *cannot* hold anything large is
  /// a rule that stays kept rather than one that has to be remembered.
  final List<double> corners;

  /// Rebuilds the quad these corners describe.
  PageQuad get quad => PageQuad(
    topLeft: NormalisedPoint(x: corners[0], y: corners[1]),
    topRight: NormalisedPoint(x: corners[2], y: corners[3]),
    bottomRight: NormalisedPoint(x: corners[4], y: corners[5]),
    bottomLeft: NormalisedPoint(x: corners[6], y: corners[7]),
  );
}
