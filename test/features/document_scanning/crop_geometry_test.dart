import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rotateQuad', () {
    const size = Size(1000, 2000);

    test('keeps the selection inside the page', () {
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: 0.05, y: 0.05),
        topRight: NormalisedPoint(x: 0.95, y: 0.05),
        bottomRight: NormalisedPoint(x: 0.95, y: 0.95),
        bottomLeft: NormalisedPoint(x: 0.05, y: 0.95),
      );

      for (final degrees in [5.0, 30.0, 90.0, 175.0, -45.0]) {
        final turned = rotateQuad(quad, degrees, size);
        for (final corner in turned.corners) {
          expect(
            corner.isWithinBounds,
            isTrue,
            reason: 'corner left the page at $degrees degrees',
          );
        }
      }
    });

    test('a full turn returns the shape it started from', () {
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: 0.2, y: 0.2),
        topRight: NormalisedPoint(x: 0.8, y: 0.25),
        bottomRight: NormalisedPoint(x: 0.75, y: 0.8),
        bottomLeft: NormalisedPoint(x: 0.25, y: 0.75),
      );

      final turned = rotateQuad(quad, 360, size);

      for (var i = 0; i < 4; i++) {
        expect(turned.corners[i].x, closeTo(quad.corners[i].x, 0.001));
        expect(turned.corners[i].y, closeTo(quad.corners[i].y, 0.001));
      }
    });

    test('does not deform a square selection', () {
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: 0.3, y: 0.4),
        topRight: NormalisedPoint(x: 0.7, y: 0.4),
        bottomRight: NormalisedPoint(x: 0.7, y: 0.6),
        bottomLeft: NormalisedPoint(x: 0.3, y: 0.6),
      );

      final turned = rotateQuad(quad, 90, size);

      double edge(NormalisedPoint a, NormalisedPoint b) {
        final dx = (a.x - b.x) * size.width;
        final dy = (a.y - b.y) * size.height;
        return dx * dx + dy * dy;
      }

      // Opposite edges stay equal: the shape is turned, not skewed.
      expect(
        edge(turned.topLeft, turned.topRight),
        closeTo(edge(turned.bottomLeft, turned.bottomRight), 1),
      );
    });
  });

  group('flips', () {
    const quad = PageQuad(
      topLeft: NormalisedPoint(x: 0.1, y: 0.2),
      topRight: NormalisedPoint(x: 0.9, y: 0.2),
      bottomRight: NormalisedPoint(x: 0.9, y: 0.8),
      bottomLeft: NormalisedPoint(x: 0.1, y: 0.8),
    );

    test('flipping horizontally twice is the original', () {
      expect(flipQuadHorizontally(flipQuadHorizontally(quad)), quad);
    });

    test('flipping vertically twice is the original', () {
      expect(flipQuadVertically(flipQuadVertically(quad)), quad);
    });
  });
}
