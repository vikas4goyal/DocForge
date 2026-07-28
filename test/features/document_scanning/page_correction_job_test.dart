/// Tests the correction job against real image files.
///
/// The maths is covered exhaustively in `perspective_transform_test.dart`
/// without any image. What this file verifies is the part that only shows up
/// once pixels are involved: that the output is written, that it has the
/// expected dimensions, and that the source image is left untouched.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/page_correction_job.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Writes a test image with a distinctive, position-dependent pattern.
///
/// A gradient rather than a flat colour: a flat image would pass even if the
/// resampler read the wrong pixel every time.
String writeTestImage(
  Directory directory,
  String name, {
  int width = 120,
  int height = 160,
}) {
  final image = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(
        x,
        y,
        (x * 255 / width).round(),
        (y * 255 / height).round(),
        128,
        255,
      );
    }
  }

  final path = '${directory.path}/$name';
  File(path).writeAsBytesSync(img.encodeJpg(image));
  return path;
}

void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('docforge_correction');
  });

  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  PageCorrectionRequest requestFor(
    String source,
    PageQuad quad, {
    String destination = 'corrected.jpg',
  }) => PageCorrectionRequest.forQuad(
    sourcePath: source,
    destinationPath: '${workspace.path}/$destination',
    quad: quad,
  );

  group('correctPageJob', () {
    test('writes the corrected page to the destination path', () {
      final source = writeTestImage(workspace, 'capture.jpg');

      final written = correctPageJob(requestFor(source, PageQuad.full));

      expect(File(written).existsSync(), isTrue);
      expect(File(written).lengthSync(), greaterThan(0));
    });

    test('a full-page crop preserves the original dimensions', () {
      final source = writeTestImage(workspace, 'capture.jpg');

      final written = correctPageJob(requestFor(source, PageQuad.full));
      final output = img.decodeImage(File(written).readAsBytesSync())!;

      expect(output.width, 120);
      expect(output.height, 160);
    });

    test('a half-width crop produces a half-width page', () {
      final source = writeTestImage(workspace, 'capture.jpg');
      const half = PageQuad(
        topLeft: NormalisedPoint(x: 0, y: 0),
        topRight: NormalisedPoint(x: 0.5, y: 0),
        bottomRight: NormalisedPoint(x: 0.5, y: 1),
        bottomLeft: NormalisedPoint(x: 0, y: 1),
      );

      final written = correctPageJob(requestFor(source, half));
      final output = img.decodeImage(File(written).readAsBytesSync())!;

      expect(output.width, 60);
      expect(output.height, 160);
    });

    test('never modifies the source image', () {
      final source = writeTestImage(workspace, 'capture.jpg');
      final before = File(source).readAsBytesSync();

      correctPageJob(
        requestFor(
          source,
          const PageQuad(
            topLeft: NormalisedPoint(x: 0.1, y: 0.05),
            topRight: NormalisedPoint(x: 0.9, y: 0.12),
            bottomRight: NormalisedPoint(x: 0.85, y: 0.95),
            bottomLeft: NormalisedPoint(x: 0.08, y: 0.88),
          ),
        ),
      );

      // getPixel returns a live view into the image buffer. A resampler that
      // wrote through one would corrupt the neighbours the next samples read,
      // and the damage would grow across the image rather than being obvious.
      expect(File(source).readAsBytesSync(), before);
    });

    test('a full-page crop reproduces the source content', () {
      final source = writeTestImage(workspace, 'capture.jpg');
      final original = img.decodeImage(File(source).readAsBytesSync())!;

      final written = correctPageJob(requestFor(source, PageQuad.full));
      final output = img.decodeImage(File(written).readAsBytesSync())!;

      // An identity transform must be close to a copy. JPEG round-tripping
      // moves values slightly, so this is a tolerance rather than equality —
      // but a resampler reading the wrong pixels misses it by far more.
      for (final (x, y) in [(10, 10), (60, 80), (110, 150)]) {
        final a = original.getPixel(x, y);
        final b = output.getPixel(x, y);

        expect(b.r, closeTo(a.r, 12), reason: 'red at $x,$y');
        expect(b.g, closeTo(a.g, 12), reason: 'green at $x,$y');
      }
    });

    test('a cropped region samples from the right part of the source', () {
      final source = writeTestImage(workspace, 'capture.jpg');
      const rightHalf = PageQuad(
        topLeft: NormalisedPoint(x: 0.5, y: 0),
        topRight: NormalisedPoint(x: 1, y: 0),
        bottomRight: NormalisedPoint(x: 1, y: 1),
        bottomLeft: NormalisedPoint(x: 0.5, y: 1),
      );

      final written = correctPageJob(requestFor(source, rightHalf));
      final output = img.decodeImage(File(written).readAsBytesSync())!;

      // Red rises with x across the source. The right half must therefore start
      // around mid-red, not near zero — which is what a crop that ignored its
      // offset would produce.
      expect(output.getPixel(1, 80).r, greaterThan(100));
    });

    test('a degenerate crop still produces a readable image', () {
      final source = writeTestImage(workspace, 'capture.jpg');
      const collinear = PageQuad(
        topLeft: NormalisedPoint(x: 0, y: 0.5),
        topRight: NormalisedPoint(x: 0.5, y: 0.5),
        bottomRight: NormalisedPoint(x: 1, y: 0.5),
        bottomLeft: NormalisedPoint(x: 0.25, y: 0.5),
      );

      final written = correctPageJob(requestFor(source, collinear));

      // The transform falls back to identity rather than failing, so the user
      // keeps a usable page instead of losing the capture to a bad crop.
      expect(File(written).existsSync(), isTrue);
      expect(img.decodeImage(File(written).readAsBytesSync()), isNotNull);
    });

    test('an unreadable capture fails loudly rather than silently', () {
      final path = '${workspace.path}/not-an-image.jpg';
      File(path).writeAsStringSync('this is not a JPEG');

      // Turned into a failure by the worker. A page the user watched the
      // shutter fire for must never disappear without explanation.
      expect(
        () => correctPageJob(requestFor(path, PageQuad.full)),
        throwsA(isA<FormatException>()),
      );
    });

    test('the same request twice produces the same bytes', () {
      final source = writeTestImage(workspace, 'capture.jpg');
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: 0.1, y: 0.1),
        topRight: NormalisedPoint(x: 0.9, y: 0.15),
        bottomRight: NormalisedPoint(x: 0.88, y: 0.9),
        bottomLeft: NormalisedPoint(x: 0.12, y: 0.85),
      );

      final first = correctPageJob(
        requestFor(source, quad, destination: 'a.jpg'),
      );
      final second = correctPageJob(
        requestFor(source, quad, destination: 'b.jpg'),
      );

      // Determinism matters: a retry after a failure must not silently produce
      // a different page from the one the user already approved.
      expect(File(first).readAsBytesSync(), File(second).readAsBytesSync());
    });
  });

  group('PageCorrectionRequest', () {
    test('flattens a quad to eight values and back again', () {
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: 0.1, y: 0.2),
        topRight: NormalisedPoint(x: 0.8, y: 0.25),
        bottomRight: NormalisedPoint(x: 0.75, y: 0.9),
        bottomLeft: NormalisedPoint(x: 0.15, y: 0.85),
      );

      final request = PageCorrectionRequest.forQuad(
        sourcePath: 'a.jpg',
        destinationPath: 'b.jpg',
        quad: quad,
      );

      expect(request.corners, hasLength(8));
      expect(request.quad, quad);
    });

    test('carries paths and numbers only', () {
      final request = PageCorrectionRequest.forQuad(
        sourcePath: 'a.jpg',
        destinationPath: 'b.jpg',
        quad: PageQuad.full,
      );

      // The payload that crosses into an isolate cannot hold a decoded image,
      // because the type has nowhere to put one.
      expect(request.sourcePath, isA<String>());
      expect(request.corners, everyElement(isA<double>()));
    });
  });
}
