import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_scanning/domain/perspective_transform.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a quad from four normalised corner pairs, in canonical order.
PageQuad quad(
  (double, double) topLeft,
  (double, double) topRight,
  (double, double) bottomRight,
  (double, double) bottomLeft,
) => PageQuad(
  topLeft: NormalisedPoint(x: topLeft.$1, y: topLeft.$2),
  topRight: NormalisedPoint(x: topRight.$1, y: topRight.$2),
  bottomRight: NormalisedPoint(x: bottomRight.$1, y: bottomRight.$2),
  bottomLeft: NormalisedPoint(x: bottomLeft.$1, y: bottomLeft.$2),
);

/// Asserts that mapping the output rectangle's corners lands on the quad's.
///
/// This is the property that actually matters — a homography is correct exactly
/// when it takes the four destination corners to the four source corners — and
/// it is checkable without any image at all.
void expectCornersMap(
  Homography transform,
  PageQuad source, {
  required int imageWidth,
  required int imageHeight,
  required CorrectedPageSize outputSize,
}) {
  final w = outputSize.width.toDouble();
  final h = outputSize.height.toDouble();
  final destinations = [(0.0, 0.0), (w, 0.0), (w, h), (0.0, h)];

  for (var i = 0; i < 4; i++) {
    final (u, v) = destinations[i];
    final mapped = transform.apply(u, v);
    final corner = source.corners[i];

    expect(
      mapped.x,
      closeTo(corner.x * imageWidth, 1e-6),
      reason: 'corner $i x',
    );
    expect(
      mapped.y,
      closeTo(corner.y * imageHeight, 1e-6),
      reason: 'corner $i y',
    );
  }
}

void main() {
  group('Homography', () {
    test('the identity transform leaves a point where it is', () {
      final mapped = Homography.identity.apply(37, 91);

      expect(mapped.x, 37);
      expect(mapped.y, 91);
    });

    test('a translation moves every point by the same offset', () {
      const translate = Homography(
        h00: 1,
        h01: 0,
        h02: 10,
        h10: 0,
        h11: 1,
        h12: -5,
        h20: 0,
        h21: 0,
      );

      expect(translate.apply(0, 0).x, 10);
      expect(translate.apply(0, 0).y, -5);
      expect(translate.apply(100, 100).x, 110);
      expect(translate.apply(100, 100).y, 95);
    });

    test('a perspective row compresses points as they move away', () {
      // h20 grows the divisor with x, so equal steps in the input produce
      // shrinking steps in the output — the defining behaviour of perspective.
      const perspective = Homography(
        h00: 1,
        h01: 0,
        h02: 0,
        h10: 0,
        h11: 1,
        h12: 0,
        h20: 0.01,
        h21: 0,
      );

      final near = perspective.apply(10, 0).x;
      final far = perspective.apply(100, 0).x;

      expect(near, closeTo(10 / 1.1, 1e-9));
      expect(far, closeTo(100 / 2, 1e-9));
      expect(far - near, lessThan(90));
    });

    test('a degenerate divisor falls back rather than producing infinity', () {
      const degenerate = Homography(
        h00: 1,
        h01: 0,
        h02: 0,
        h10: 0,
        h11: 1,
        h12: 0,
        h20: -1,
        h21: 0,
      );

      // w = -1 * 1 + 1 = 0.
      final mapped = degenerate.apply(1, 0);

      expect(mapped.x, isNot(double.infinity));
      expect(mapped.x.isFinite, isTrue);
      expect(mapped.y.isFinite, isTrue);
    });

    test('a non-finite coefficient is reported as invalid', () {
      const broken = Homography(
        h00: double.nan,
        h01: 0,
        h02: 0,
        h10: 0,
        h11: 1,
        h12: 0,
        h20: 0,
        h21: 0,
      );

      expect(broken.isValid, isFalse);
      expect(Homography.identity.isValid, isTrue);
    });
  });

  group('output size', () {
    test('a full-page quad keeps the original dimensions', () {
      final size = PerspectiveTransform.outputSizeFor(
        PageQuad.full,
        imageWidth: 1200,
        imageHeight: 1600,
      );

      expect(size, const CorrectedPageSize(1200, 1600));
    });

    test('a half-width crop halves the width', () {
      final size = PerspectiveTransform.outputSizeFor(
        quad((0, 0), (0.5, 0), (0.5, 1), (0, 1)),
        imageWidth: 1000,
        imageHeight: 800,
      );

      expect(size, const CorrectedPageSize(500, 800));
    });

    test('takes the longer of two opposite edges, never the shorter', () {
      // A trapezoid: the top edge spans 0.4 of the width, the bottom 0.8.
      final size = PerspectiveTransform.outputSizeFor(
        quad((0.3, 0), (0.7, 0), (0.9, 1), (0.1, 1)),
        imageWidth: 1000,
        imageHeight: 1000,
      );

      // 800, from the bottom edge — not 400 from the top and not 600 averaged.
      // Taking the shorter edge would throw away the near edge's resolution.
      expect(size.width, 800);
    });

    test('a degenerate quad still produces a usable size', () {
      final size = PerspectiveTransform.outputSizeFor(
        quad((0.5, 0.5), (0.5, 0.5), (0.5, 0.5), (0.5, 0.5)),
        imageWidth: 1000,
        imageHeight: 1000,
      );

      // Not zero: a zero-sized image would have to be special-cased everywhere
      // downstream.
      expect(size.width, greaterThanOrEqualTo(1));
      expect(size.height, greaterThanOrEqualTo(1));
    });
  });

  group('solving the homography', () {
    test('a full-page quad solves to the image-scaling transform', () {
      const outputSize = CorrectedPageSize(1000, 800);
      final transform = PerspectiveTransform.solve(
        PageQuad.full,
        imageWidth: 1000,
        imageHeight: 800,
        outputSize: outputSize,
      );

      // Output and input are the same size, so this must be the identity.
      expect(transform, Homography.identity);
    });

    test('every destination corner maps onto its source corner', () {
      // A tilted page: the classic photograph-of-a-document quad.
      final source = quad(
        (0.15, 0.10),
        (0.88, 0.18),
        (0.82, 0.92),
        (0.10, 0.84),
      );
      const imageWidth = 1200;
      const imageHeight = 1600;

      final outputSize = PerspectiveTransform.outputSizeFor(
        source,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
      final transform = PerspectiveTransform.solve(
        source,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        outputSize: outputSize,
      );

      expectCornersMap(
        transform,
        source,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        outputSize: outputSize,
      );
    });

    test('a translated rectangle solves to a pure offset', () {
      // The quad is the right half of the image; the output is that half at
      // full resolution, so the transform is a translation and nothing else.
      final source = quad((0.5, 0), (1, 0), (1, 1), (0.5, 1));
      const outputSize = CorrectedPageSize(500, 800);

      final transform = PerspectiveTransform.solve(
        source,
        imageWidth: 1000,
        imageHeight: 800,
        outputSize: outputSize,
      );

      expect(transform.h02, closeTo(500, 1e-9));
      expect(transform.h12, closeTo(0, 1e-9));
      // No perspective: the quad is a rectangle.
      expect(transform.h20, closeTo(0, 1e-9));
      expect(transform.h21, closeTo(0, 1e-9));
    });

    test('a scaled rectangle solves to a pure scale', () {
      // The quad is the top-left quarter; the output is at the source's own
      // pixel size, so each output pixel maps to exactly one input pixel.
      final source = quad((0, 0), (0.5, 0), (0.5, 0.5), (0, 0.5));
      const outputSize = CorrectedPageSize(250, 250);

      final transform = PerspectiveTransform.solve(
        source,
        imageWidth: 1000,
        imageHeight: 1000,
        outputSize: outputSize,
      );

      // Output 250 wide over a source 500 wide: two input pixels per output.
      expect(transform.h00, closeTo(2, 1e-9));
      expect(transform.h11, closeTo(2, 1e-9));
      expect(transform.h01, closeTo(0, 1e-9));
      expect(transform.h10, closeTo(0, 1e-9));
    });

    test('a genuinely skewed quad produces a non-zero perspective row', () {
      final source = quad((0.2, 0.1), (0.9, 0.25), (0.85, 0.9), (0.15, 0.8));
      const outputSize = CorrectedPageSize(800, 1000);

      final transform = PerspectiveTransform.solve(
        source,
        imageWidth: 1000,
        imageHeight: 1200,
        outputSize: outputSize,
      );

      // A zero perspective row would mean the correction is only an affine
      // shear, which does not deskew a photographed page.
      expect(transform.h20.abs() + transform.h21.abs(), greaterThan(1e-9));
    });

    test('an axis-aligned quad solves despite the zero pivots', () {
      // Every corner shares a coordinate with another, which puts zeros on the
      // diagonal. Without partial pivoting this divides by zero.
      final source = quad((0, 0), (1, 0), (1, 1), (0, 1));
      const outputSize = CorrectedPageSize(640, 480);

      final transform = PerspectiveTransform.solve(
        source,
        imageWidth: 640,
        imageHeight: 480,
        outputSize: outputSize,
      );

      expect(transform.isValid, isTrue);
      expectCornersMap(
        transform,
        source,
        imageWidth: 640,
        imageHeight: 480,
        outputSize: outputSize,
      );
    });

    test('a collinear quad falls back to identity rather than failing', () {
      // All four corners on one line: the system is singular.
      final source = quad((0, 0), (0.5, 0), (1, 0), (0.25, 0));

      final transform = PerspectiveTransform.solve(
        source,
        imageWidth: 1000,
        imageHeight: 1000,
        outputSize: const CorrectedPageSize(1000, 1),
      );

      // The capture survives untouched. The spec is explicit that a bad crop
      // must never cost the user the page.
      expect(transform, Homography.identity);
    });

    test('a quad with coincident corners falls back to identity', () {
      final source = quad((0.5, 0.5), (0.5, 0.5), (0.5, 0.5), (0.5, 0.5));

      final transform = PerspectiveTransform.solve(
        source,
        imageWidth: 800,
        imageHeight: 600,
        outputSize: const CorrectedPageSize(1, 1),
      );

      expect(transform, Homography.identity);
    });

    test('the solved transform is stable across repeated solves', () {
      final source = quad(
        (0.11, 0.07),
        (0.93, 0.21),
        (0.86, 0.95),
        (0.08, 0.82),
      );

      Homography solveOnce() => PerspectiveTransform.solve(
        source,
        imageWidth: 1440,
        imageHeight: 1920,
        outputSize: const CorrectedPageSize(1180, 1520),
      );

      // Determinism matters: the same crop must produce the same page every
      // time, or a retry after a failure would silently change the output.
      expect(solveOnce(), solveOnce());
    });
  });
}
