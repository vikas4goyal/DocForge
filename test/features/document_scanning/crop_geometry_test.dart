import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const available = Rect.fromLTWH(20, 20, 360, 640);
  const portrait = Size(3000, 4000);

  group('PageTransform.fit', () {
    test('never enlarges a page that already fits', () {
      final transform = PageTransform.fit(
        imageSize: const Size(100, 120),
        available: available,
        degrees: 0,
      );

      // Scaling a small capture up would only turn it into blur.
      expect(transform.scale, 1.0);
    });

    test('keeps the page inside the area at every rotation', () {
      for (final degrees in [0.0, 15.0, 45.0, 90.0, 137.0, -60.0]) {
        final transform = PageTransform.fit(
          imageSize: portrait,
          available: available,
          degrees: degrees,
        );

        // Every corner of the page, once turned, must still be inside — a page
        // measured unrotated would have its corners cut off as it turned.
        for (final corner in const [
          NormalisedPoint(x: 0, y: 0),
          NormalisedPoint(x: 1, y: 0),
          NormalisedPoint(x: 1, y: 1),
          NormalisedPoint(x: 0, y: 1),
        ]) {
          final point = transform.toScreen(corner);
          expect(
            available.inflate(0.5).contains(point),
            isTrue,
            reason: 'corner escaped at $degrees degrees',
          );
        }
      }
    });
  });

  group('screen and page coordinates', () {
    test('round-trip unchanged, rotated or not', () {
      const points = [
        NormalisedPoint(x: 0.25, y: 0.4),
        NormalisedPoint(x: 0.5, y: 0.5),
        NormalisedPoint(x: 0.9, y: 0.15),
      ];

      for (final degrees in [0.0, 30.0, -45.0, 180.0]) {
        final transform = PageTransform.fit(
          imageSize: portrait,
          available: available,
          degrees: degrees,
        );

        for (final point in points) {
          final returned = transform.toPage(transform.toScreen(point));
          expect(returned.x, closeTo(point.x, 0.001));
          expect(returned.y, closeTo(point.y, 0.001));
        }
      }
    });

    test('a corner dragged on screen lands where the page is, not where the '
        'canvas is', () {
      final upright = PageTransform.fit(
        imageSize: portrait,
        available: available,
        degrees: 0,
      );
      final turned = PageTransform.fit(
        imageSize: portrait,
        available: available,
        degrees: 90,
      );

      // The same page point is drawn somewhere else once the page is turned.
      // Anything mapping through the canvas rather than the page would put the
      // selection on top of pixels the user is not looking at.
      const topLeft = NormalisedPoint(x: 0, y: 0);
      expect(
        (upright.toScreen(topLeft) - turned.toScreen(topLeft)).distance,
        greaterThan(1),
      );
    });

    test('a point outside the page is pulled back onto it', () {
      final transform = PageTransform.fit(
        imageSize: portrait,
        available: available,
        degrees: 0,
      );

      final outside = transform.toPage(const Offset(-500, -500));

      // A selection corner off the page would describe pixels that do not
      // exist, which the correction would then have to guess at.
      expect(outside.isWithinBounds, isTrue);
    });
  });

  group('replaceCorner', () {
    const quad = PageQuad(
      topLeft: NormalisedPoint(x: 0.1, y: 0.1),
      topRight: NormalisedPoint(x: 0.9, y: 0.1),
      bottomRight: NormalisedPoint(x: 0.9, y: 0.9),
      bottomLeft: NormalisedPoint(x: 0.1, y: 0.9),
    );

    test('moves only the corner it names', () {
      const moved = NormalisedPoint(x: 0.4, y: 0.3);
      final next = replaceCorner(quad, 1, moved);

      expect(next.topRight, moved);
      expect(next.topLeft, quad.topLeft);
      expect(next.bottomRight, quad.bottomRight);
      expect(next.bottomLeft, quad.bottomLeft);
    });
  });
}
