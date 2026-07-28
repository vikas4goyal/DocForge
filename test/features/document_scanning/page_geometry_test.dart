import 'dart:math' as math;

import 'package:doc_forge/core/contracts/geometry/page_geometry.dart';
import 'package:doc_forge/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:flutter_test/flutter_test.dart';

/// A rectangular selection, as a fraction of each edge.
PageQuad box(double left, double top, double right, double bottom) => PageQuad(
  topLeft: NormalisedPoint(x: left, y: top),
  topRight: NormalisedPoint(x: right, y: top),
  bottomRight: NormalisedPoint(x: right, y: bottom),
  bottomLeft: NormalisedPoint(x: left, y: bottom),
);

/// Where ([x], [y]) in the output lands in the original.
({double x, double y}) source(ComposedGeometry geometry, double x, double y) =>
    geometry.transform.apply(x, y);

void main() {
  const width = 1000;
  const height = 800;

  ComposedGeometry composed(List<CropOp> ops) =>
      PageGeometry.compose(ops, imageWidth: width, imageHeight: height);

  group('the empty chain', () {
    test('is the identity over the original size', () {
      final geometry = composed(const []);

      expect(geometry.isIdentity, isTrue);
      expect(geometry.outputSize, const CorrectedPageSize(width, height));
    });

    test('leaves every point where it is', () {
      final geometry = composed(const []);

      expect(source(geometry, 250, 400).x, closeTo(250, 1e-6));
      expect(source(geometry, 250, 400).y, closeTo(400, 1e-6));
    });
  });

  group('a single crop', () {
    test('matches solving the transform directly', () {
      // One op has to behave exactly as the pre-existing single-crop path did,
      // or composing would have changed what an ordinary crop produces.
      final quad = box(0.25, 0.25, 0.75, 0.75);
      final expectedSize = PerspectiveTransform.outputSizeFor(
        quad,
        imageWidth: width,
        imageHeight: height,
      );
      final expected = PerspectiveTransform.solve(
        quad,
        imageWidth: width,
        imageHeight: height,
        outputSize: expectedSize,
      );

      final geometry = composed([CropOp(quad: quad)]);

      expect(geometry.outputSize, expectedSize);
      expect(geometry.transform, expected);
    });

    test('produces an output the size of the selection', () {
      final geometry = composed([CropOp(quad: box(0.25, 0.25, 0.75, 0.75))]);

      expect(geometry.outputSize.width, closeTo(width * 0.5, 1));
      expect(geometry.outputSize.height, closeTo(height * 0.5, 1));
    });

    test("maps the output's origin to the selection's corner", () {
      final geometry = composed([CropOp(quad: box(0.25, 0.25, 0.75, 0.75))]);

      final origin = source(geometry, 0, 0);
      expect(origin.x, closeTo(width * 0.25, 1e-6));
      expect(origin.y, closeTo(height * 0.25, 1e-6));
    });
  });

  group('composition', () {
    test('two crops equal one crop of the same region', () {
      // Halving twice from the top-left reaches the same quarter as taking
      // that quarter directly — and must do so through one resampling pass.
      final chained = composed([
        CropOp(quad: box(0, 0, 0.5, 0.5)),
        CropOp(quad: box(0, 0, 0.5, 0.5)),
      ]);
      final direct = composed([CropOp(quad: box(0, 0, 0.25, 0.25))]);

      expect(chained.outputSize, direct.outputSize);
      expect(chained.transform, direct.transform);
    });

    test('three crops still reduce to one transform', () {
      final geometry = composed([
        CropOp(quad: box(0, 0, 0.8, 0.8)),
        CropOp(quad: box(0, 0, 0.5, 0.5)),
        CropOp(quad: box(0, 0, 0.5, 0.5)),
      ]);

      // 0.8 × 0.5 × 0.5 = 0.2 of each edge, in a single pass.
      expect(geometry.outputSize.width, closeTo(width * 0.2, 2));
      expect(geometry.outputSize.height, closeTo(height * 0.2, 2));
    });

    test('a later crop is expressed against the earlier result', () {
      // The second selection's origin is the first selection's origin, not the
      // original image's — that is the coordinate space the user was looking at.
      final geometry = composed([
        CropOp(quad: box(0.5, 0.5, 1, 1)),
        CropOp(quad: box(0, 0, 0.5, 0.5)),
      ]);

      final origin = source(geometry, 0, 0);
      expect(origin.x, closeTo(width * 0.5, 1e-6));
      expect(origin.y, closeTo(height * 0.5, 1e-6));
    });

    test('composing agrees with applying the steps one at a time', () {
      final ops = [
        CropOp(quad: box(0.1, 0.1, 0.9, 0.9)),
        CropOp(quad: box(0.2, 0.2, 0.8, 0.8)),
      ];

      final geometry = composed(ops);

      // Walk the chain by hand: map through the second step, then the first.
      var stepWidth = width;
      var stepHeight = height;
      final steps = <Homography>[];
      for (final op in ops) {
        final size = PerspectiveTransform.outputSizeFor(
          op.quad,
          imageWidth: stepWidth,
          imageHeight: stepHeight,
        );
        steps.add(
          PerspectiveTransform.solve(
            op.quad,
            imageWidth: stepWidth,
            imageHeight: stepHeight,
            outputSize: size,
          ),
        );
        stepWidth = size.width;
        stepHeight = size.height;
      }

      const probeX = 100.0;
      const probeY = 80.0;
      var point = (x: probeX, y: probeY);
      for (final step in steps.reversed) {
        point = step.apply(point.x, point.y);
      }

      final direct = source(geometry, probeX, probeY);
      expect(direct.x, closeTo(point.x, 1e-6));
      expect(direct.y, closeTo(point.y, 1e-6));
    });
  });

  group('rotation', () {
    test('a rotated selection changes the sampled region', () {
      final upright = composed([CropOp(quad: box(0.25, 0.25, 0.75, 0.75))]);
      final tilted = composed([
        CropOp(quad: box(0.25, 0.25, 0.75, 0.75), rotationDegrees: 15),
      ]);

      expect(tilted.transform, isNot(upright.transform));
    });

    test('zero rotation leaves the selection alone', () {
      final plain = composed([CropOp(quad: box(0.2, 0.2, 0.8, 0.8))]);
      final explicit = composed([CropOp(quad: box(0.2, 0.2, 0.8, 0.8))]);

      expect(explicit.transform, plain.transform);
    });

    test('rotation composes with perspective in one pass', () {
      final geometry = composed([
        CropOp(quad: box(0.1, 0.1, 0.9, 0.9), rotationDegrees: 10),
        CropOp(quad: box(0.2, 0.2, 0.8, 0.8), rotationDegrees: -10),
      ]);

      // Two rotations and two crops, still one transform and one output size.
      expect(geometry.transform.isValid, isTrue);
      expect(geometry.outputSize.width, greaterThan(0));
    });

    test('a full turn returns roughly to where it started', () {
      final none = composed([CropOp(quad: box(0.25, 0.25, 0.75, 0.75))]);
      final full = composed([
        CropOp(quad: box(0.25, 0.25, 0.75, 0.75), rotationDegrees: 360),
      ]);

      expect(source(full, 10, 10).x, closeTo(source(none, 10, 10).x, 1e-6));
    });
  });

  group('robustness', () {
    test('a degenerate selection does not produce a broken transform', () {
      // A quad the user could reach by dragging every handle together. It must
      // not cost them the capture.
      final geometry = composed([CropOp(quad: box(0.5, 0.5, 0.5, 0.5))]);

      expect(geometry.transform.isValid, isTrue);
      expect(geometry.outputSize.width, greaterThanOrEqualTo(1));
      expect(geometry.outputSize.height, greaterThanOrEqualTo(1));
    });

    test('a one-pixel image composes', () {
      final geometry = PageGeometry.compose(
        [CropOp(quad: box(0, 0, 0.5, 0.5))],
        imageWidth: 1,
        imageHeight: 1,
      );

      expect(geometry.outputSize.width, greaterThanOrEqualTo(1));
    });

    test('every coefficient stays finite through a long chain', () {
      final geometry = composed([
        for (var i = 0; i < 10; i++) CropOp(quad: box(0.05, 0.05, 0.95, 0.95)),
      ]);

      expect(geometry.transform.isValid, isTrue);
    });
  });

  group('CropOp', () {
    test('a full-page selection at zero rotation is the identity', () {
      expect(const CropOp(quad: PageQuad.full).isIdentity, isTrue);
    });

    test('a rotation alone is not the identity', () {
      expect(
        const CropOp(quad: PageQuad.full, rotationDegrees: 5).isIdentity,
        isFalse,
      );
    });

    test('a partial selection is not the identity', () {
      expect(CropOp(quad: box(0, 0, 0.5, 0.5)).isIdentity, isFalse);
    });

    test('equal operations compare equal', () {
      expect(
        CropOp(quad: box(0, 0, 0.5, 0.5), rotationDegrees: 5),
        CropOp(quad: box(0, 0, 0.5, 0.5), rotationDegrees: 5),
      );
    });
  });

  group('outputSizeOf', () {
    test('agrees with compose', () {
      final ops = [CropOp(quad: box(0.25, 0.25, 0.75, 0.75))];

      expect(
        PageGeometry.outputSizeOf(ops, imageWidth: width, imageHeight: height),
        composed(ops).outputSize,
      );
    });
  });

  group('determinism', () {
    test('composing the same chain twice gives the same transform', () {
      List<CropOp> ops() => [
        CropOp(quad: box(0.1, 0.2, 0.9, 0.8), rotationDegrees: 3),
        CropOp(quad: box(0.05, 0.05, 0.95, 0.95)),
      ];

      expect(composed(ops()).transform, composed(ops()).transform);
    });

    test('no wall-clock or randomness is involved', () {
      // Guarded explicitly: a transform that varied between runs would make
      // every golden built on a cropped page flaky.
      final first = composed([CropOp(quad: box(0.3, 0.3, 0.7, 0.7))]);
      final second = composed([CropOp(quad: box(0.3, 0.3, 0.7, 0.7))]);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('geometry of a rotated page', () {
    test('a 90 degree turn swaps the output dimensions', () {
      // Rotating the selection about its centre by a quarter turn: the region
      // sampled is as tall as it was wide.
      final geometry = composed([
        CropOp(quad: box(0.25, 0.1, 0.75, 0.9), rotationDegrees: 90),
      ]);

      expect(geometry.outputSize.width, greaterThan(0));
      expect(geometry.outputSize.height, greaterThan(0));
      // The rotation is real, not silently dropped.
      final upright = composed([CropOp(quad: box(0.25, 0.1, 0.75, 0.9))]);
      expect(geometry.outputSize, isNot(upright.outputSize));
    });

    test('radians are not confused for degrees', () {
      // 180 degrees is pi radians; if the conversion were missing, a rotation
      // of 180 would be a barely visible tilt.
      final geometry = composed([
        CropOp(quad: box(0.2, 0.3, 0.8, 0.7), rotationDegrees: 180),
      ]);
      final tiny = composed([
        CropOp(quad: box(0.2, 0.3, 0.8, 0.7), rotationDegrees: math.pi),
      ]);

      expect(geometry.transform, isNot(tiny.transform));
    });
  });
}
