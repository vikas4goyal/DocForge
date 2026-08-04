/// Tests the enhancement pipeline against real image files.
///
/// The arithmetic is covered exhaustively in `enhancement_maths_test.dart`
/// without any image. What this file verifies is the part that only shows up
/// once pixels are involved: that each filter changes the page in the direction
/// it claims to, that adjustments combine with a filter, that the source file
/// is never modified, and that a preview really is downscaled.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_maths.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/enhancement_job.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Builds a page-like fixture: a light background with darker text-like bars,
/// a colour patch, and a lighting gradient across the width.
///
/// Every property under test needs one of those features. A flat colour would
/// pass even if a filter did nothing at all.
img.Image pageFixture({int width = 120, int height = 160}) {
  final image = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      // Illumination falls off to the right, which is what shadow removal has
      // to find and undo.
      final illumination = 0.55 + 0.45 * (1 - x / width);

      var r = 220.0 * illumination;
      var g = 218.0 * illumination;
      var b = 214.0 * illumination;

      // Horizontal bars standing in for lines of text.
      if (y % 16 < 4) {
        r = 40 * illumination;
        g = 42 * illumination;
        b = 45 * illumination;
      }

      // A saturated patch, so a colour filter has something to act on and
      // shadow removal has something it must not blow out.
      if (x > width * 0.6 && y > height * 0.7) {
        r = 200 * illumination;
        g = 60 * illumination;
        b = 55 * illumination;
      }

      image.setPixelRgba(x, y, r.round(), g.round(), b.round(), 255);
    }
  }

  return image;
}

/// Writes [image] into [directory] as a JPEG and returns its path.
String writeFixture(Directory directory, String name, img.Image image) {
  final path = '${directory.path}/$name';
  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 95));
  return path;
}

/// Returns the mean luminance of [image].
double meanLuminance(img.Image image) {
  var total = 0.0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      total += EnhancementMaths.luminance(pixel.r, pixel.g, pixel.b);
    }
  }

  return total / (image.width * image.height);
}

/// Returns the standard deviation of [image]'s luminance.
///
/// The measure of contrast: a filter that increases contrast increases this,
/// whatever it does to the mean.
double luminanceSpread(img.Image image) {
  final mean = meanLuminance(image);
  var total = 0.0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final delta =
          EnhancementMaths.luminance(pixel.r, pixel.g, pixel.b) - mean;
      total += delta * delta;
    }
  }

  return (total / (image.width * image.height)).abs();
}

/// Returns the mean distance of each pixel's channels from its own luminance.
///
/// The measure of saturation, which is what Magic Colour claims to raise.
double meanSaturation(img.Image image) {
  var total = 0.0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final luminance = EnhancementMaths.luminance(pixel.r, pixel.g, pixel.b);
      total +=
          ((pixel.r - luminance).abs() +
              (pixel.g - luminance).abs() +
              (pixel.b - luminance).abs()) /
          3;
    }
  }

  return total / (image.width * image.height);
}

/// Returns the mean luminance of the leftmost and rightmost columns.
///
/// Shadow removal's job is to bring these together.
({double left, double right}) edgeBrightness(img.Image image) {
  var left = 0.0;
  var right = 0.0;
  final band = (image.width * 0.15).round();

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < band; x++) {
      final near = image.getPixel(x, y);
      final far = image.getPixel(image.width - 1 - x, y);
      left += EnhancementMaths.luminance(near.r, near.g, near.b);
      right += EnhancementMaths.luminance(far.r, far.g, far.b);
    }
  }

  final count = image.height * band;
  return (left: left / count, right: right / count);
}

void main() {
  late Directory directory;
  late img.Image fixture;
  late String sourcePath;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('enhancement_job');
    fixture = pageFixture();
    sourcePath = writeFixture(directory, 'page.jpg', fixture);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  /// Runs the job for [settings] and returns the decoded result.
  img.Image run(
    EnhancementSettings settings, {
    int? maxDimension,
    String name = 'out.jpg',
  }) {
    final path = enhancePageJob(
      EnhancementRequest(
        sourcePath: sourcePath,
        destinationPath: '${directory.path}/$name',
        settings: settings,
        maxDimension: maxDimension,
      ),
    );

    return img.decodeImage(File(path).readAsBytesSync())!;
  }

  group('filters', () {
    test('Original leaves the page as captured', () {
      final result = run(EnhancementSettings.none);

      expect(result.width, fixture.width);
      expect(result.height, fixture.height);
      // Copied rather than re-encoded, so the bytes are identical to the source
      // and the page has not lost a JPEG generation for nothing.
      expect(
        File('${directory.path}/out.jpg').readAsBytesSync(),
        File(sourcePath).readAsBytesSync(),
      );
    });

    test('Grayscale removes all colour', () {
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.grayscale),
      );

      expect(meanSaturation(result), lessThan(2));
    });

    test('Grayscale retains tonal detail rather than flattening the page', () {
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.grayscale),
      );

      // Distinguishes grayscale from black and white: the bars must still be
      // separable from the paper by more than two values.
      expect(luminanceSpread(result), greaterThan(100));
    });

    test('Auto Enhance widens the tonal range', () {
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.autoEnhance),
      );

      expect(luminanceSpread(result), greaterThan(luminanceSpread(fixture)));
    });

    test('Magic Colour raises saturation', () {
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.magicColour),
      );

      expect(meanSaturation(result), greaterThan(meanSaturation(fixture)));
    });

    test('Black & White produces only the two extremes', () {
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.blackAndWhite),
      );

      // Sampled rather than exhaustive, and tolerant, because the result is
      // written as a JPEG: the encoder's chroma subsampling shifts values a
      // little either side of the two it was given.
      for (var y = 0; y < result.height; y += 7) {
        for (var x = 0; x < result.width; x += 7) {
          final pixel = result.getPixel(x, y);
          final luminance = EnhancementMaths.luminance(
            pixel.r,
            pixel.g,
            pixel.b,
          );
          expect(
            luminance < 40 || luminance > 215,
            isTrue,
            reason: 'pixel ($x, $y) reads $luminance, which is neither tone',
          );
        }
      }
    });

    test('Black & White keeps the text bars dark and the paper light', () {
      // Adaptive thresholding is only worth its cost if the shadowed side of
      // the page survives it. A global cutoff would turn the darker right-hand
      // side into a solid block.
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.blackAndWhite),
      );

      final edges = edgeBrightness(result);

      expect(edges.left, greaterThan(120));
      expect(edges.right, greaterThan(120));
    });
  });

  group('adjustments', () {
    test('positive brightness lightens the page', () {
      final result = run(const EnhancementSettings(brightness: 0.3));

      expect(meanLuminance(result), greaterThan(meanLuminance(fixture)));
    });

    test('negative brightness darkens it', () {
      final result = run(const EnhancementSettings(brightness: -0.3));

      expect(meanLuminance(result), lessThan(meanLuminance(fixture)));
    });

    test('positive contrast widens the tonal range', () {
      final result = run(const EnhancementSettings(contrast: 0.4));

      expect(luminanceSpread(result), greaterThan(luminanceSpread(fixture)));
    });

    test('negative contrast narrows it', () {
      final result = run(const EnhancementSettings(contrast: -0.5));

      expect(luminanceSpread(result), lessThan(luminanceSpread(fixture)));
    });

    test('sharpening increases local difference at the text edges', () {
      final result = run(const EnhancementSettings(sharpen: 1));

      expect(luminanceSpread(result), greaterThan(luminanceSpread(fixture)));
    });

    test('sharpening leaves colour where it was', () {
      // The offset is derived from luminance and applied to all three channels
      // equally. Sharpening each channel against a shared luminance blur would
      // push the colour patch towards the extremes.
      final result = run(const EnhancementSettings(sharpen: 1));

      expect(
        meanSaturation(result),
        closeTo(meanSaturation(fixture), meanSaturation(fixture) * 0.5),
      );
    });

    test('shadow removal evens out the lighting across the page', () {
      final before = edgeBrightness(fixture);
      final result = run(const EnhancementSettings(shadowRemoval: true));
      final after = edgeBrightness(result);

      expect(before.left - before.right, greaterThan(20));
      expect(
        (after.left - after.right).abs(),
        lessThan((before.left - before.right).abs()),
      );
    });

    test('shadow removal does not blow out a saturated region', () {
      // Normalising every pixel to full white rather than to the page's own
      // illumination reference would push the colour patch straight to white.
      final result = run(const EnhancementSettings(shadowRemoval: true));

      expect(meanSaturation(result), greaterThan(1));
    });
  });

  group('combinations', () {
    test('a filter and an adjustment are both reflected in the result', () {
      final filterOnly = run(
        const EnhancementSettings(filter: EnhancementFilter.grayscale),
        name: 'filter.jpg',
      );
      final both = run(
        const EnhancementSettings(
          filter: EnhancementFilter.grayscale,
          brightness: 0.3,
        ),
        name: 'both.jpg',
      );

      // The filter's effect survives.
      expect(meanSaturation(both), lessThan(2));
      // And so does the adjustment's.
      expect(meanLuminance(both), greaterThan(meanLuminance(filterOnly)));
    });

    test('every filter combines with every adjustment without failing', () {
      for (final filter in EnhancementFilter.values) {
        final result = run(
          EnhancementSettings(
            filter: filter,
            brightness: 0.2,
            contrast: 0.2,
            sharpen: 0.5,
            shadowRemoval: true,
          ),
          name: 'combo_${filter.name}.jpg',
        );

        expect(result.width, fixture.width);
        expect(result.height, fixture.height);
      }
    });
  });

  group('the source page', () {
    test('is never modified, whatever is applied', () {
      final before = File(sourcePath).readAsBytesSync();

      for (final filter in EnhancementFilter.values) {
        run(
          EnhancementSettings(
            filter: filter,
            brightness: 0.5,
            sharpen: 1,
            shadowRemoval: true,
          ),
          name: 'src_${filter.name}.jpg',
        );
      }

      expect(File(sourcePath).readAsBytesSync(), before);
    });
  });

  group('previews', () {
    test('are downscaled to the preview bound', () {
      final large = writeFixture(
        directory,
        'large.jpg',
        pageFixture(width: 2400, height: 3200),
      );

      final path = enhancePageJob(
        EnhancementRequest.preview(
          sourcePath: large,
          destinationPath: '${directory.path}/preview.jpg',
          settings: const EnhancementSettings(
            filter: EnhancementFilter.autoEnhance,
          ),
        ),
      );

      final preview = img.decodeImage(File(path).readAsBytesSync())!;

      expect(
        preview.height,
        lessThanOrEqualTo(EnhancementRules.previewMaxDimension),
      );
      // Aspect ratio is preserved, so what the user judges is the shape they
      // will get.
      expect(preview.width / preview.height, closeTo(2400 / 3200, 0.01));
    });

    test('leave an already-small page at its own size', () {
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.grayscale),
        maxDimension: EnhancementRules.previewMaxDimension,
      );

      expect(result.width, fixture.width);
      expect(result.height, fixture.height);
    });

    test('apply the same filters the saved page would get', () {
      final result = run(
        const EnhancementSettings(filter: EnhancementFilter.grayscale),
        maxDimension: 64,
        name: 'small.jpg',
      );

      expect(meanSaturation(result), lessThan(2));
    });
  });

  group('failure', () {
    test('an undecodable page throws rather than writing a broken file', () {
      final broken = '${directory.path}/broken.jpg';
      File(broken).writeAsStringSync('this is not an image');

      expect(
        () => enhancePageJob(
          EnhancementRequest(
            sourcePath: broken,
            destinationPath: '${directory.path}/never.jpg',
            settings: const EnhancementSettings(brightness: 0.5),
          ),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(File('${directory.path}/never.jpg').existsSync(), isFalse);
    });

    test('a missing page throws', () {
      expect(
        () => enhancePageJob(
          EnhancementRequest(
            sourcePath: '${directory.path}/absent.jpg',
            destinationPath: '${directory.path}/never.jpg',
            settings: const EnhancementSettings(brightness: 0.5),
          ),
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
