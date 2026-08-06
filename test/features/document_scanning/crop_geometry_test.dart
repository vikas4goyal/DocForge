import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/crop_screen.dart';
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

  group('holding the selection still while the page turns', () {
    test('re-reading its screen corners through the new placement keeps it '
        'where it was', () {
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: 0.2, y: 0.2),
        topRight: NormalisedPoint(x: 0.8, y: 0.2),
        bottomRight: NormalisedPoint(x: 0.8, y: 0.8),
        bottomLeft: NormalisedPoint(x: 0.2, y: 0.8),
      );

      final before = PageTransform.fit(
        imageSize: portrait,
        available: available,
        degrees: 0,
      );
      final after = PageTransform.fit(
        imageSize: portrait,
        available: available,
        degrees: 20,
      );

      final held = [for (final c in quad.corners) before.toScreen(c)];
      final rewritten = [
        for (final point in held) after.toPage(point, clamp: false),
      ];

      // The selection belongs to the canvas, so turning the page must not move
      // it. Mapping the same page coordinates through the new placement instead
      // would swing the box around with the image — which is the bug.
      for (var i = 0; i < 4; i++) {
        final returned = after.toScreen(rewritten[i]);
        expect(returned.dx, closeTo(held[i].dx, 0.5));
        expect(returned.dy, closeTo(held[i].dy, 0.5));
      }

      // And it now describes a different part of the page, because a different
      // part of the page is under it.
      expect(rewritten[0].x, isNot(closeTo(quad.topLeft.x, 0.01)));
    });
  });

  group('flips', () {
    const quad = PageQuad(
      topLeft: NormalisedPoint(x: 0.1, y: 0.2),
      topRight: NormalisedPoint(x: 0.9, y: 0.2),
      bottomRight: NormalisedPoint(x: 0.9, y: 0.8),
      bottomLeft: NormalisedPoint(x: 0.1, y: 0.8),
    );

    test('each is its own inverse', () {
      expect(flipQuadHorizontally(flipQuadHorizontally(quad)), quad);
      expect(flipQuadVertically(flipQuadVertically(quad)), quad);
    });

    test('both together are a half turn', () {
      // Which is why the slider only needs a quarter turn either way: the
      // orientations outside its range are reachable through the flips.
      final turned = flipQuadVertically(flipQuadHorizontally(quad));

      expect(turned.topLeft, quad.bottomRight);
      expect(turned.bottomRight, quad.topLeft);
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
