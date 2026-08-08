/// Generates the deterministic image-processing benchmark fixture.
///
/// Run with `dart run tool/generate_image_processing_benchmark_fixture.dart`.
/// The generated JPEG contains no personal data and is checked in so every
/// backend receives identical compressed input bytes.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _width = 4000;
const _height = 3000;
const _outputPath =
    'integration_test/fixtures/image_processing_benchmark_12mp.jpg';

/// Generates the synthetic 12-megapixel document fixture.
///
/// The output combines fine text, saturated patches, gradients, shadows, and
/// skewed page edges. It returns normally after writing [_outputPath] and can
/// throw [FileSystemException] when the fixture cannot be created.
void main() {
  final image = img.Image(width: _width, height: _height);

  // This is deliberately generated pixel-by-pixel: the smooth lighting field
  // gives shadow removal real work and remains deterministic on every host.
  for (var y = 0; y < _height; y++) {
    final vertical = y / (_height - 1);
    for (var x = 0; x < _width; x++) {
      final horizontal = x / (_width - 1);
      final cornerShadow = 0.64 + 0.36 * (1 - horizontal * vertical);
      final wave = 0.035 * math.sin(horizontal * math.pi * 6);
      final paper = (238 * (cornerShadow + wave)).round().clamp(0, 255);
      image.setPixelRgba(
        x,
        y,
        paper,
        (paper - 3).clamp(0, 255),
        (paper - 8).clamp(0, 255),
        255,
      );
    }
  }

  final ink = img.ColorRgb8(35, 39, 47);
  final mutedInk = img.ColorRgb8(75, 82, 94);
  final blue = img.ColorRgb8(35, 102, 210);
  final red = img.ColorRgb8(206, 62, 54);
  final green = img.ColorRgb8(40, 151, 92);

  img.drawString(
    image,
    'DOC SCANLY GPU BENCHMARK',
    font: img.arial48,
    x: 260,
    y: 220,
    color: ink,
  );
  img.drawString(
    image,
    'Synthetic document - no personal data',
    font: img.arial24,
    x: 265,
    y: 290,
    color: mutedInk,
  );

  for (var row = 0; row < 29; row++) {
    final y = 430 + row * 72;
    final inset = row.isEven ? 270 : 330;
    img.drawString(
      image,
      'Line ${(row + 1).toString().padLeft(2, '0')}  '
      'The quick brown fox tests fine document detail 0123456789',
      font: img.arial24,
      x: inset,
      y: y,
      color: row % 5 == 0 ? mutedInk : ink,
    );
    img.drawLine(
      image,
      x1: inset,
      y1: y + 34,
      x2: _width - 300 - (row % 4) * 150,
      y2: y + 34,
      color: img.ColorRgb8(130, 132, 136),
      thickness: 2,
    );
  }

  img.fillRect(
    image,
    x1: 275,
    y1: 2580,
    x2: 1160,
    y2: 2820,
    color: blue,
    radius: 24,
  );
  img.fillRect(
    image,
    x1: 1320,
    y1: 2580,
    x2: 2205,
    y2: 2820,
    color: red,
    radius: 24,
  );
  img.fillRect(
    image,
    x1: 2365,
    y1: 2580,
    x2: 3250,
    y2: 2820,
    color: green,
    radius: 24,
  );

  // A non-axis-aligned border makes geometry regressions visible at every
  // corner instead of measuring only enhancement passes.
  img.drawLine(
    image,
    x1: 120,
    y1: 90,
    x2: 3870,
    y2: 145,
    color: ink,
    thickness: 10,
  );
  img.drawLine(
    image,
    x1: 3870,
    y1: 145,
    x2: 3790,
    y2: 2900,
    color: ink,
    thickness: 10,
  );
  img.drawLine(
    image,
    x1: 3790,
    y1: 2900,
    x2: 155,
    y2: 2860,
    color: ink,
    thickness: 10,
  );
  img.drawLine(
    image,
    x1: 155,
    y1: 2860,
    x2: 120,
    y2: 90,
    color: ink,
    thickness: 10,
  );

  final output = File(_outputPath)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(img.encodeJpg(image, quality: 95), flush: true);

  stdout.writeln(
    'Generated ${output.path} (${image.width}x${image.height}, '
    '${output.lengthSync()} bytes)',
  );
}
