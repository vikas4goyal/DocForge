/// The decisions behind automatic edge detection.
///
/// OpenCV finds candidate outlines; everything that turns a set of outlines
/// into "this is the page" lives here — which candidate to trust, whether it is
/// plausible at all, and which corner is which. That split is deliberate: the
/// contour finding is battle-tested upstream and needs a device to run, while
/// the decisions are where a detector actually gets a document wrong, and they
/// are pure functions that can be tested exhaustively without a camera.
library;

import 'dart:math' as math;

import 'package:doc_forge/core/contracts/models/page.dart';

/// A candidate page outline, in pixel coordinates.
///
/// Four points in whatever order the contour finder produced them — putting
/// them in order is [PageEdgeGeometry.orderCorners]' job, not the caller's.
class EdgeCandidate {
  /// Creates a candidate from four [points].
  const EdgeCandidate(this.points);

  /// The candidate's corners, unordered.
  final List<({double x, double y})> points;

  /// Whether this candidate has exactly four corners.
  ///
  /// A contour approximated to three or five points is not a sheet of paper
  /// seen at an angle, whatever else it might be.
  bool get isQuadrilateral => points.length == 4;
}

/// Pure geometry for turning contours into a page quadrilateral.
abstract final class PageEdgeGeometry {
  /// The smallest share of the frame a detected page may occupy.
  ///
  /// A document the user is photographing fills most of the viewfinder. A
  /// candidate smaller than this is a business card on a desk, a logo, or a
  /// shadow — accepting it would crop the page down to a fragment, which is far
  /// worse than not detecting anything and leaving the full frame.
  static const minimumAreaFraction = 0.15;

  /// The largest share of the frame a detected page may occupy.
  ///
  /// A contour covering essentially the whole frame is the frame border itself,
  /// which Canny finds reliably and which is never the document. Rejecting it
  /// costs nothing: the fallback for "nothing detected" is the full page, which
  /// is what that contour describes anyway.
  static const maximumAreaFraction = 0.995;

  /// How far from a right angle a page corner may be, in degrees.
  ///
  /// A rectangle photographed at an angle has corners well away from ninety
  /// degrees, so this has to be generous — which also means it catches less
  /// than it appears to. On its own it does not reject a wedge tapering from
  /// eight hundred pixels wide to sixty, because a trapezium's interior angles
  /// stay moderate however extreme its taper. [maximumEdgeRatio] is what
  /// actually rules that out; this check earns its place against shapes with a
  /// genuinely acute or reflex corner.
  static const maximumCornerDeviation = 45.0;

  /// The most one edge may exceed the edge opposite it.
  ///
  /// This is the real test of "is this a rectangle seen at an angle". Under
  /// perspective, the near edge of a sheet is longer than the far one, but only
  /// by so much: to make the far edge a third of the near one, the camera has
  /// to be so close and so oblique that the page is unreadable anyway. A shape
  /// whose opposite edges differ by more than this is a wedge, a shadow or a
  /// desk corner — not a document.
  static const maximumEdgeRatio = 3.0;

  /// Returns [points] in the canonical order: top-left, top-right,
  /// bottom-right, bottom-left.
  ///
  /// Ordered by coordinate sums and differences rather than by angle around the
  /// centroid. On a page photographed at an angle the two orderings agree; on a
  /// nearly-square page they do not, and the sum-and-difference rule is the one
  /// that stays correct — the top-left corner always has the smallest `x + y`
  /// and the top-right always the largest `x - y`, however the page is rotated
  /// within reason.
  static List<({double x, double y})> orderCorners(
    List<({double x, double y})> points,
  ) {
    if (points.length != 4) return points;

    final bySum = [...points]..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final byDifference = [...points]
      ..sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));

    final topLeft = bySum.first;
    final bottomRight = bySum.last;
    final bottomLeft = byDifference.first;
    final topRight = byDifference.last;

    // A degenerate candidate can put the same point in two roles — a contour
    // with two coincident corners, which `approxPolyDP` does produce. Returning
    // it unchanged lets the plausibility check reject it, rather than silently
    // building a quad with a duplicated corner.
    final distinct = {topLeft, topRight, bottomRight, bottomLeft};
    if (distinct.length != 4) return points;

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  /// Returns the area enclosed by [corners].
  ///
  /// The shoelace formula, taken as an absolute value so the result does not
  /// depend on whether the corners wind clockwise or anticlockwise.
  static double area(List<({double x, double y})> corners) {
    if (corners.length < 3) return 0;

    var total = 0.0;
    for (var index = 0; index < corners.length; index++) {
      final current = corners[index];
      final next = corners[(index + 1) % corners.length];
      total += current.x * next.y - next.x * current.y;
    }

    return total.abs() / 2;
  }

  /// Returns the interior angle at [corner], in degrees, between its neighbours.
  static double angleAt(
    ({double x, double y}) corner, {
    required ({double x, double y}) previous,
    required ({double x, double y}) next,
  }) {
    final ax = previous.x - corner.x;
    final ay = previous.y - corner.y;
    final bx = next.x - corner.x;
    final by = next.y - corner.y;

    final magnitude =
        math.sqrt(ax * ax + ay * ay) * math.sqrt(bx * bx + by * by);
    if (magnitude == 0) return 0;

    final cosine = ((ax * bx + ay * by) / magnitude).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180 / math.pi;
  }

  /// Whether [corners] could plausibly be a sheet of paper in a frame of the
  /// given [imageWidth] and [imageHeight].
  ///
  /// This is the check that decides whether the user sees an automatic crop or
  /// the full page. It is deliberately conservative: a wrong crop silently
  /// removes part of a document the user believes they scanned, while no crop
  /// costs them four corner drags and nothing else.
  static bool isPlausiblePage(
    List<({double x, double y})> corners, {
    required int imageWidth,
    required int imageHeight,
  }) {
    if (corners.length != 4) return false;
    if (imageWidth <= 0 || imageHeight <= 0) return false;

    final frameArea = imageWidth * imageHeight;
    final fraction = area(corners) / frameArea;

    if (fraction < minimumAreaFraction) return false;
    if (fraction > maximumAreaFraction) return false;

    for (var index = 0; index < 4; index++) {
      final angle = angleAt(
        corners[index],
        previous: corners[(index + 3) % 4],
        next: corners[(index + 1) % 4],
      );

      if ((angle - 90).abs() > maximumCornerDeviation) return false;
    }

    if (!isConvex(corners)) return false;

    final top = _distance(corners[0], corners[1]);
    final right = _distance(corners[1], corners[2]);
    final bottom = _distance(corners[2], corners[3]);
    final left = _distance(corners[3], corners[0]);

    return _withinRatio(top, bottom) && _withinRatio(left, right);
  }

  /// Whether [corners] wind consistently, without doubling back.
  ///
  /// A concave or self-intersecting quadrilateral is not a sheet of paper from
  /// any angle. It is also what corner ordering produces from a contour that
  /// was never a page, so this rejects a whole class of nonsense before the
  /// perspective transform is asked to make sense of it.
  static bool isConvex(List<({double x, double y})> corners) {
    if (corners.length != 4) return false;

    var sawPositive = false;
    var sawNegative = false;

    for (var index = 0; index < 4; index++) {
      final a = corners[index];
      final b = corners[(index + 1) % 4];
      final c = corners[(index + 2) % 4];

      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);

      if (cross > 0) sawPositive = true;
      if (cross < 0) sawNegative = true;

      // Turns in both directions means the outline doubles back on itself.
      if (sawPositive && sawNegative) return false;
    }

    return true;
  }

  /// Whether [a] and [b] are within [maximumEdgeRatio] of each other.
  static bool _withinRatio(double a, double b) {
    final longer = math.max(a, b);
    final shorter = math.min(a, b);

    if (shorter <= 0) return false;
    return longer / shorter <= maximumEdgeRatio;
  }

  /// Returns the distance between [a] and [b].
  static double _distance(({double x, double y}) a, ({double x, double y}) b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

  /// Returns the most plausible page outline among [candidates], or null.
  ///
  /// Picks the largest plausible candidate. Largest rather than
  /// most-rectangular because the competing contours on a real capture are
  /// things *inside* the page — a printed table, a photograph, a signature box
  /// — and those are often more perfectly rectangular than the page itself,
  /// which is seen at an angle. Size is what distinguishes the sheet from what
  /// is printed on it.
  static List<({double x, double y})>? bestCandidate(
    List<EdgeCandidate> candidates, {
    required int imageWidth,
    required int imageHeight,
  }) {
    List<({double x, double y})>? best;
    var bestArea = 0.0;

    for (final candidate in candidates) {
      if (!candidate.isQuadrilateral) continue;

      final ordered = orderCorners(candidate.points);
      if (!isPlausiblePage(
        ordered,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      )) {
        continue;
      }

      final candidateArea = area(ordered);
      if (candidateArea > bestArea) {
        bestArea = candidateArea;
        best = ordered;
      }
    }

    return best;
  }

  /// Converts ordered pixel [corners] into a normalised [PageQuad].
  ///
  /// Normalised so a crop detected on a downscaled copy — which is how
  /// detection is actually run, because contour finding on a twelve-megapixel
  /// capture is needlessly slow — applies unchanged to the full-resolution
  /// image.
  static PageQuad toQuad(
    List<({double x, double y})> corners, {
    required int imageWidth,
    required int imageHeight,
  }) {
    NormalisedPoint at(int index) => NormalisedPoint(
      x: (corners[index].x / imageWidth).clamp(0.0, 1.0),
      y: (corners[index].y / imageHeight).clamp(0.0, 1.0),
    );

    return PageQuad(
      topLeft: at(0),
      topRight: at(1),
      bottomRight: at(2),
      bottomLeft: at(3),
    );
  }

  /// Returns the quadrilateral for [candidates], falling back to the full page.
  ///
  /// The fallback is the specified behaviour, not a failure path: when no page
  /// can be found the whole frame becomes the default crop and the user adjusts
  /// the corners by hand.
  static PageQuad quadFor(
    List<EdgeCandidate> candidates, {
    required int imageWidth,
    required int imageHeight,
  }) {
    final best = bestCandidate(
      candidates,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    if (best == null) return PageQuad.full;

    return toQuad(best, imageWidth: imageWidth, imageHeight: imageHeight);
  }

  /// The longest edge, in pixels, detection is run against.
  ///
  /// Contour finding on a full twelve-megapixel capture is many times slower
  /// than on a downscaled copy and finds no more edges: the outline of a sheet
  /// of paper is a feature hundreds of pixels across. Detecting small and
  /// normalising the result is what keeps the shutter responsive.
  static const detectionMaxDimension = 1024;
}
