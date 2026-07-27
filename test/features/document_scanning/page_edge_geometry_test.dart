/// Tests the decisions behind automatic edge detection.
///
/// OpenCV's contour finding is not exercised here — it cannot be, since its
/// native library is absent from the host test VM, and its behaviour is
/// guaranteed upstream anyway. What is exercised is everything that turns
/// contours into a crop, which is where a detector actually gets a document
/// wrong: choosing the page over what is printed on it, refusing an implausible
/// outline, and putting the corners in the right order.
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_scanning/domain/page_edge_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// A frame the size of a downscaled capture.
const _width = 1000;
const _height = 1400;

({double x, double y}) p(double x, double y) => (x: x, y: y);

/// A rectangle inset by [inset] on every side.
List<({double x, double y})> rectangle(double inset) => [
  p(inset, inset),
  p(_width - inset, inset),
  p(_width - inset, _height - inset),
  p(inset, _height - inset),
];

/// A page seen at an angle: still a rectangle in the world, a trapezium here.
final _tilted = [p(140, 120), p(880, 190), p(840, 1290), p(100, 1210)];

void main() {
  group('ordering corners', () {
    test('puts an axis-aligned rectangle in canonical order', () {
      final ordered = PageEdgeGeometry.orderCorners([
        p(900, 1300),
        p(100, 100),
        p(100, 1300),
        p(900, 100),
      ]);

      expect(ordered, [p(100, 100), p(900, 100), p(900, 1300), p(100, 1300)]);
    });

    test('orders a tilted page correctly whatever order it arrives in', () {
      final shuffled = [_tilted[2], _tilted[0], _tilted[3], _tilted[1]];

      expect(PageEdgeGeometry.orderCorners(shuffled), _tilted);
    });

    test('is idempotent', () {
      final once = PageEdgeGeometry.orderCorners(_tilted);

      expect(PageEdgeGeometry.orderCorners(once), once);
    });

    test('orders a nearly-square page correctly', () {
      // The case that separates the sum-and-difference rule from ordering by
      // angle around the centroid: on a near-square the two disagree, and only
      // this one stays right.
      final square = [p(100, 100), p(500, 110), p(490, 505), p(95, 495)];

      final shuffled = [square[1], square[3], square[2], square[0]];

      expect(PageEdgeGeometry.orderCorners(shuffled), square);
    });

    test('leaves a candidate with the wrong number of corners alone', () {
      final triangle = [p(0, 0), p(10, 0), p(5, 10)];

      expect(PageEdgeGeometry.orderCorners(triangle), triangle);
    });

    test(
      'leaves a degenerate candidate alone rather than duplicating a corner',
      () {
        // `approxPolyDP` does produce contours with coincident corners. Building
        // a quad from one would put the same point in two roles silently; the
        // plausibility check rejects it instead.
        final degenerate = [
          p(100, 100),
          p(100, 100),
          p(900, 100),
          p(900, 1300),
        ];

        expect(PageEdgeGeometry.orderCorners(degenerate), degenerate);
      },
    );
  });

  group('area', () {
    test('measures an axis-aligned rectangle', () {
      expect(PageEdgeGeometry.area(rectangle(0)), _width * _height);
    });

    test('does not depend on winding direction', () {
      final clockwise = rectangle(100);
      final anticlockwise = clockwise.reversed.toList();

      expect(
        PageEdgeGeometry.area(anticlockwise),
        closeTo(PageEdgeGeometry.area(clockwise), 0.001),
      );
    });

    test('is zero for fewer than three points', () {
      expect(PageEdgeGeometry.area([p(0, 0), p(1, 1)]), 0);
    });
  });

  group('corner angles', () {
    test('a right angle measures ninety degrees', () {
      expect(
        PageEdgeGeometry.angleAt(p(0, 0), previous: p(0, 10), next: p(10, 0)),
        closeTo(90, 0.001),
      );
    });

    test('a straight line measures a hundred and eighty', () {
      expect(
        PageEdgeGeometry.angleAt(p(0, 0), previous: p(-10, 0), next: p(10, 0)),
        closeTo(180, 0.001),
      );
    });

    test('coincident points measure zero rather than dividing by zero', () {
      expect(
        PageEdgeGeometry.angleAt(p(5, 5), previous: p(5, 5), next: p(10, 10)),
        0,
      );
    });
  });

  group('plausibility', () {
    bool plausible(List<({double x, double y})> corners) =>
        PageEdgeGeometry.isPlausiblePage(
          PageEdgeGeometry.orderCorners(corners),
          imageWidth: _width,
          imageHeight: _height,
        );

    test('accepts a page filling most of the frame', () {
      expect(plausible(rectangle(60)), isTrue);
    });

    test('accepts a page photographed at an angle', () {
      expect(plausible(_tilted), isTrue);
    });

    test('rejects something too small to be the document', () {
      // A business card on a desk, a logo, a signature box. Cropping to one
      // would silently remove most of a document the user believes they
      // scanned — far worse than not detecting anything.
      expect(plausible(rectangle(420)), isFalse);
    });

    test('rejects a contour that is the frame border', () {
      // Canny finds the frame edge reliably and it is never the document.
      // Rejecting it costs nothing: the fallback is the full page, which is
      // what that contour describes anyway.
      expect(plausible(rectangle(0)), isFalse);
    });

    test('rejects a wedge, whose opposite edges cannot both be page edges', () {
      // Eight hundred pixels across at the top, sixty at the bottom. Under
      // perspective a page's near edge is longer than its far one, but nowhere
      // near thirteen times longer. Note that this shape passes the corner-angle
      // check comfortably — a trapezium's interior angles stay moderate however
      // extreme its taper — so the edge-ratio test is what earns its keep here.
      final wedge = [p(100, 100), p(900, 100), p(560, 1300), p(500, 1300)];

      expect(plausible(wedge), isFalse);
    });

    test('rejects a shape that doubles back on itself', () {
      // Not a sheet of paper from any angle, and exactly what corner ordering
      // produces from a contour that was never a page.
      final bowtie = [p(100, 100), p(900, 100), p(100, 1300), p(900, 1300)];

      expect(
        PageEdgeGeometry.isPlausiblePage(
          bowtie,
          imageWidth: _width,
          imageHeight: _height,
        ),
        isFalse,
      );
    });

    test('accepts the foreshortening a real perspective view produces', () {
      // The near edge longer than the far one, which is what a page
      // photographed from above at an angle actually looks like. This must not
      // be rejected by the edge-ratio rule.
      final foreshortened = [
        p(250, 150),
        p(750, 150),
        p(900, 1250),
        p(100, 1250),
      ];

      expect(plausible(foreshortened), isTrue);
    });

    test('rejects anything without exactly four corners', () {
      expect(plausible([p(100, 100), p(900, 100), p(500, 1300)]), isFalse);
    });

    test('rejects a degenerate quad with coincident corners', () {
      expect(
        plausible([p(100, 100), p(100, 100), p(900, 100), p(900, 1300)]),
        isFalse,
      );
    });

    test('rejects everything when the frame has no size', () {
      expect(
        PageEdgeGeometry.isPlausiblePage(
          rectangle(60),
          imageWidth: 0,
          imageHeight: 0,
        ),
        isFalse,
      );
    });
  });

  group('choosing between candidates', () {
    List<({double x, double y})>? best(List<EdgeCandidate> candidates) =>
        PageEdgeGeometry.bestCandidate(
          candidates,
          imageWidth: _width,
          imageHeight: _height,
        );

    test('prefers the page over what is printed on it', () {
      // The competing contours on a real capture are a printed table, a
      // photograph, a boxed field — and those are often *more* perfectly
      // rectangular than the page, which is seen at an angle. Size is what
      // distinguishes the sheet from its contents.
      final page = EdgeCandidate(_tilted);
      final table = EdgeCandidate(rectangle(300));

      expect(best([table, page]), PageEdgeGeometry.orderCorners(_tilted));
    });

    test('ignores candidates that are not quadrilaterals', () {
      final triangle = EdgeCandidate([p(100, 100), p(900, 100), p(500, 1300)]);
      final page = EdgeCandidate(rectangle(80));

      expect(
        best([triangle, page]),
        PageEdgeGeometry.orderCorners(rectangle(80)),
      );
    });

    test('returns nothing when no candidate is plausible', () {
      expect(best([EdgeCandidate(rectangle(450))]), isNull);
    });

    test('returns nothing for an empty candidate list', () {
      expect(best(const []), isNull);
    });
  });

  group('the resulting quadrilateral', () {
    PageQuad quadFor(List<EdgeCandidate> candidates) =>
        PageEdgeGeometry.quadFor(
          candidates,
          imageWidth: _width,
          imageHeight: _height,
        );

    test('normalises pixel corners onto the unit square', () {
      final quad = quadFor([EdgeCandidate(rectangle(100))]);

      expect(quad.topLeft.x, closeTo(0.1, 0.001));
      expect(quad.topLeft.y, closeTo(100 / _height, 0.001));
      expect(quad.bottomRight.x, closeTo(0.9, 0.001));
    });

    test(
      'is normalised so a crop found on a downscale still fits the original',
      () {
        // Detection runs on a downscaled copy, because contour finding on a
        // twelve-megapixel capture is needlessly slow and finds no more edges.
        // The same page at two sizes must produce the same normalised quad.
        final small = PageEdgeGeometry.quadFor(
          [EdgeCandidate(rectangle(100))],
          imageWidth: _width,
          imageHeight: _height,
        );
        final large = PageEdgeGeometry.quadFor(
          [
            EdgeCandidate([
              p(400, 400),
              p(_width * 4 - 400, 400),
              p(_width * 4 - 400, _height * 4 - 400),
              p(400, _height * 4 - 400),
            ]),
          ],
          imageWidth: _width * 4,
          imageHeight: _height * 4,
        );

        expect(large.topLeft.x, closeTo(small.topLeft.x, 0.001));
        expect(large.bottomRight.y, closeTo(small.bottomRight.y, 0.001));
      },
    );

    test('stays inside the page even if a corner reaches past the frame', () {
      final quad = PageEdgeGeometry.toQuad(
        [p(-50, -50), p(1200, 0), p(1100, 1500), p(0, 1450)],
        imageWidth: _width,
        imageHeight: _height,
      );

      expect(quad.isWithinBounds, isTrue);
    });

    test('falls back to the full page when nothing is detected', () {
      // The specified behaviour, not a failure path: an undetected capture is
      // kept, the whole frame becomes the default crop, and the user adjusts
      // the corners by hand.
      expect(quadFor(const []), PageQuad.full);
    });

    test('falls back to the full page when no candidate is plausible', () {
      expect(quadFor([EdgeCandidate(rectangle(460))]), PageQuad.full);
    });

    test('preserves corner order through normalisation', () {
      final quad = quadFor([EdgeCandidate(_tilted)]);

      expect(quad.topLeft.x, lessThan(quad.topRight.x));
      expect(quad.topLeft.y, lessThan(quad.bottomLeft.y));
      expect(quad.topRight.y, lessThan(quad.bottomRight.y));
    });
  });

  group('detection bounds', () {
    test('the detection size is smaller than a modern capture', () {
      expect(PageEdgeGeometry.detectionMaxDimension, lessThan(2000));
    });

    test('the area bounds leave room between them', () {
      expect(
        PageEdgeGeometry.minimumAreaFraction,
        lessThan(PageEdgeGeometry.maximumAreaFraction),
      );
    });
  });
}
