/// Tests the enhancement arithmetic against hand-checked values.
///
/// No images appear here at all. Every function under test maps numbers to
/// numbers, which is what makes "a mid-grey pixel at +50% brightness becomes
/// this exact value" an assertion rather than a visual impression. The
/// traversal that feeds these functions is covered in `enhancement_job_test`.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_maths.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('luminance', () {
    test('weights the channels by BT.601', () {
      expect(EnhancementMaths.luminance(255, 255, 255), closeTo(255, 0.001));
      expect(EnhancementMaths.luminance(0, 0, 0), 0);
      expect(EnhancementMaths.luminance(255, 0, 0), closeTo(76.245, 0.001));
      expect(EnhancementMaths.luminance(0, 255, 0), closeTo(149.685, 0.001));
      expect(EnhancementMaths.luminance(0, 0, 255), closeTo(29.07, 0.001));
    });

    test('green contributes more than red, which contributes more than blue', () {
      // The ordering is the whole reason for weighting rather than averaging:
      // a naive mean turns a green highlight and a blue one into the same grey.
      expect(
        EnhancementMaths.greenLuminance,
        greaterThan(EnhancementMaths.redLuminance),
      );
      expect(
        EnhancementMaths.redLuminance,
        greaterThan(EnhancementMaths.blueLuminance),
      );
    });
  });

  group('brightness and contrast', () {
    test('zero for both leaves the value unchanged', () {
      for (final value in [0.0, 64.0, 127.5, 200.0, 255.0]) {
        expect(
          EnhancementMaths.brightnessContrast(
            value,
            brightness: 0,
            contrast: 0,
          ),
          closeTo(value, 0.001),
        );
      }
    });

    test(
      'positive brightness raises the value by that share of full scale',
      () {
        expect(
          EnhancementMaths.brightnessContrast(
            100,
            brightness: 0.2,
            contrast: 0,
          ),
          closeTo(151, 0.001),
        );
      },
    );

    test('negative brightness lowers it symmetrically', () {
      expect(
        EnhancementMaths.brightnessContrast(151, brightness: -0.2, contrast: 0),
        closeTo(100, 0.001),
      );
    });

    test('contrast pivots around mid-grey, leaving it untouched', () {
      const midpoint = EnhancementMaths.maxChannel / 2;

      for (final contrast in [-1.0, -0.5, 0.5, 1.0]) {
        expect(
          EnhancementMaths.brightnessContrast(
            midpoint,
            brightness: 0,
            contrast: contrast,
          ),
          closeTo(midpoint, 0.001),
          reason: 'mid-grey is the pivot at contrast $contrast',
        );
      }
    });

    test('positive contrast pushes light lighter and dark darker', () {
      final light = EnhancementMaths.brightnessContrast(
        200,
        brightness: 0,
        contrast: 0.5,
      );
      final dark = EnhancementMaths.brightnessContrast(
        50,
        brightness: 0,
        contrast: 0.5,
      );

      expect(light, greaterThan(200));
      expect(dark, lessThan(50));
    });

    test('contrast of -1 flattens everything to mid-grey', () {
      // The factor reaches zero, so every input collapses onto the pivot.
      for (final value in [0.0, 90.0, 255.0]) {
        expect(
          EnhancementMaths.brightnessContrast(
            value,
            brightness: 0,
            contrast: -1,
          ),
          closeTo(127.5, 0.001),
        );
      }
    });

    test('results never leave the channel range', () {
      for (final value in [0.0, 128.0, 255.0]) {
        for (final brightness in [-1.0, 0.0, 1.0]) {
          for (final contrast in [-1.0, 0.0, 1.0]) {
            final result = EnhancementMaths.brightnessContrast(
              value,
              brightness: brightness,
              contrast: contrast,
            );
            expect(result, inInclusiveRange(0, 255));
          }
        }
      }
    });
  });

  group('auto-level bounds', () {
    test('finds the occupied range of a narrow histogram', () {
      final histogram = List<int>.filled(256, 0);
      for (var value = 80; value <= 180; value++) {
        histogram[value] = 100;
      }

      final bounds = EnhancementMaths.autoLevelBounds(histogram);

      expect(bounds.low, closeTo(80, 1));
      expect(bounds.high, closeTo(180, 1));
    });

    test('ignores a single stray pixel at each extreme', () {
      // This is the entire reason for clipping. One dust speck reading zero and
      // one specular highlight reading 255 would otherwise report the full
      // range and leave the page untouched.
      final histogram = List<int>.filled(256, 0);
      for (var value = 90; value <= 170; value++) {
        histogram[value] = 500;
      }
      histogram[0] = 1;
      histogram[255] = 1;

      final bounds = EnhancementMaths.autoLevelBounds(histogram);

      expect(bounds.low, greaterThan(0));
      expect(bounds.high, lessThan(255));
    });

    test('leaves an empty histogram at the full range', () {
      final bounds = EnhancementMaths.autoLevelBounds(List<int>.filled(256, 0));

      expect(bounds.low, 0);
      expect(bounds.high, 255);
    });

    test('refuses to stretch a histogram too narrow to be real', () {
      // A near-uniform image is a blank page or a failed capture. Stretching it
      // would amplify sensor noise into what looks like texture.
      final histogram = List<int>.filled(256, 0);
      histogram[128] = 1000;
      histogram[129] = 1000;

      final bounds = EnhancementMaths.autoLevelBounds(histogram);

      expect(bounds.low, 0);
      expect(bounds.high, 255);
    });
  });

  group('stretch', () {
    test('maps the bounds onto the full range', () {
      expect(EnhancementMaths.stretch(80, 80, 180), 0);
      expect(EnhancementMaths.stretch(180, 80, 180), 255);
      expect(EnhancementMaths.stretch(130, 80, 180), closeTo(127.5, 0.001));
    });

    test('clamps rather than extrapolating outside the bounds', () {
      expect(EnhancementMaths.stretch(10, 80, 180), 0);
      expect(EnhancementMaths.stretch(250, 80, 180), 255);
    });

    test('returns the value unchanged for degenerate bounds', () {
      expect(EnhancementMaths.stretch(120, 180, 80), 120);
      expect(EnhancementMaths.stretch(120, 100, 100), 120);
    });
  });

  group('saturate', () {
    test('an amount of zero changes nothing', () {
      expect(EnhancementMaths.saturate(200, 120, 0), closeTo(200, 0.001));
    });

    test('pushes the channel further from its luminance', () {
      expect(EnhancementMaths.saturate(200, 100, 0.5), closeTo(250, 0.001));
      expect(EnhancementMaths.saturate(50, 100, 0.5), closeTo(25, 0.001));
    });

    test('leaves a fully desaturated pixel alone at any amount', () {
      // A grey pixel has no saturation to scale, which is why a page of black
      // text on white paper looks the same under Magic Colour as under Auto.
      expect(EnhancementMaths.saturate(128, 128, 1), closeTo(128, 0.001));
    });
  });

  group('unsharp', () {
    test('adds nothing where the image is already flat', () {
      expect(EnhancementMaths.unsharpOffset(120, 120, 1), 0);
    });

    test('adds nothing at an amount of zero', () {
      expect(EnhancementMaths.unsharpOffset(200, 120, 0), 0);
    });

    test('pushes an edge further from its surroundings', () {
      expect(EnhancementMaths.unsharpOffset(200, 120, 1), greaterThan(0));
      expect(EnhancementMaths.unsharpOffset(60, 120, 1), lessThan(0));
    });

    test('scales with the amount', () {
      final half = EnhancementMaths.unsharpOffset(200, 120, 0.5);
      final full = EnhancementMaths.unsharpOffset(200, 120, 1);

      expect(full, closeTo(half * 2, 0.001));
    });
  });

  group('shadow removal', () {
    test('leaves an evenly lit pixel untouched', () {
      // The gain is exactly one when the local illumination equals the
      // reference, which is what makes enabling shadow removal on a good
      // capture a no-op rather than a brightening.
      expect(
        EnhancementMaths.shadowNormalise(180, 200, 200),
        closeTo(180, 0.001),
      );
    });

    test('brightens a pixel in shadow', () {
      expect(
        EnhancementMaths.shadowNormalise(90, 100, 200),
        closeTo(180, 0.001),
      );
    });

    test('caps the gain so the deepest shadow is not amplified into noise', () {
      expect(
        EnhancementMaths.shadowNormalise(10, 2, 200),
        closeTo(10 * EnhancementMaths.maxShadowGain, 0.001),
      );
    });

    test('refuses to divide by an unusably dark background', () {
      expect(EnhancementMaths.shadowNormalise(40, 0, 200), 40);
    });

    test('never exceeds the channel range', () {
      expect(EnhancementMaths.shadowNormalise(250, 100, 200), 255);
    });
  });

  group('illumination reference', () {
    test('takes a high percentile rather than the maximum', () {
      // One specular highlight must not become the reference, or the whole page
      // is under-corrected against a value no paper ever reaches.
      final background = [...List<double>.filled(99, 100), 250.0];

      final reference = EnhancementMaths.illuminationReference(background);

      expect(reference, closeTo(100, 0.001));
    });

    test('falls back to full scale for an empty background', () {
      expect(
        EnhancementMaths.illuminationReference(const []),
        EnhancementMaths.maxChannel,
      );
    });

    test('never returns zero, which would make the gain infinite', () {
      expect(
        EnhancementMaths.illuminationReference(List<double>.filled(10, 0)),
        greaterThanOrEqualTo(1),
      );
    });
  });

  group('threshold', () {
    test('returns black below the local mean and white above it', () {
      expect(EnhancementMaths.threshold(50, 200), 0);
      expect(EnhancementMaths.threshold(240, 200), 255);
    });

    test('biases towards white so flat paper does not come out as noise', () {
      // Without bias, every pixel of a uniform region sits within noise of its
      // own mean and half of them fall either side.
      expect(EnhancementMaths.threshold(199, 200), 255);
    });

    test('follows the illumination rather than using one global cutoff', () {
      // The same dark-grey value is text on a bright region and background in a
      // shadowed one. A global cutoff turns the shadowed corner solid black.
      const value = 100.0;

      expect(EnhancementMaths.threshold(value, 220), 0);
      expect(EnhancementMaths.threshold(value, 105), 255);
    });
  });

  group('blur radius', () {
    test('scales with the image so a preview matches the saved page', () {
      expect(
        EnhancementMaths.blurRadiusFor(2000),
        greaterThan(EnhancementMaths.blurRadiusFor(400)),
      );
    });

    test('is never zero, which would make the blur a no-op', () {
      expect(EnhancementMaths.blurRadiusFor(1), greaterThanOrEqualTo(1));
      expect(EnhancementMaths.blurRadiusFor(0), greaterThanOrEqualTo(1));
    });
  });

  group('EnhancementRules', () {
    test('clamps every adjustment into its valid range', () {
      final clamped = EnhancementRules.clamp(
        const EnhancementSettings(brightness: 5, contrast: -9, sharpen: 3),
      );

      expect(clamped.brightness, EnhancementRules.maxBrightness);
      expect(clamped.contrast, EnhancementRules.minContrast);
      expect(clamped.sharpen, EnhancementRules.maxSharpen);
    });

    test('clamps sharpen at zero rather than at minus one', () {
      // Negative sharpening is blurring, which is not a control the screen
      // offers and not something the maths was designed for.
      final clamped = EnhancementRules.clamp(
        const EnhancementSettings(sharpen: -0.5),
      );

      expect(clamped.sharpen, 0);
    });

    test('default settings require no processing', () {
      expect(
        EnhancementRules.requiresProcessing(EnhancementSettings.none),
        isFalse,
      );
    });

    test('any non-default setting requires processing', () {
      const changed = [
        EnhancementSettings(filter: EnhancementFilter.grayscale),
        EnhancementSettings(brightness: 0.1),
        EnhancementSettings(contrast: -0.1),
        EnhancementSettings(sharpen: 0.2),
        EnhancementSettings(shadowRemoval: true),
      ];

      for (final settings in changed) {
        expect(
          EnhancementRules.requiresProcessing(settings),
          isTrue,
          reason: '$settings should require processing',
        );
      }
    });

    test('an out-of-range setting that clamps to default requires no work', () {
      expect(
        EnhancementRules.requiresProcessing(
          const EnhancementSettings(sharpen: -1),
        ),
        isFalse,
      );
    });
  });

  group('applying settings to a session', () {
    final pages = [
      const PageRef(id: PageId('a'), imagePath: '/a.jpg'),
      const PageRef(
        id: PageId('b'),
        imagePath: '/b.jpg',
        enhancement: EnhancementSettings(filter: EnhancementFilter.grayscale),
      ),
      const PageRef(id: PageId('c'), imagePath: '/c.jpg'),
    ];

    const magic = EnhancementSettings(filter: EnhancementFilter.magicColour);

    test('apply-to-all sets every page to the same settings', () {
      final updated = EnhancementRules.applyToAll(pages, magic);

      expect(updated.map((page) => page.enhancement), everyElement(magic));
    });

    test('apply-to-all leaves the original list untouched', () {
      EnhancementRules.applyToAll(pages, magic);

      expect(pages[0].enhancement, EnhancementSettings.none);
    });

    test('applying to one page leaves the others on their own settings', () {
      final updated = EnhancementRules.applyToPage(pages, 0, magic);

      expect(updated[0].enhancement, magic);
      expect(updated[1].enhancement.filter, EnhancementFilter.grayscale);
      expect(updated[2].enhancement, EnhancementSettings.none);
    });

    test('applying to an index outside the session changes nothing', () {
      expect(EnhancementRules.applyToPage(pages, 9, magic), pages);
      expect(EnhancementRules.applyToPage(pages, -1, magic), pages);
    });

    test('settings are clamped on the way in', () {
      final updated = EnhancementRules.applyToPage(
        pages,
        0,
        const EnhancementSettings(brightness: 4),
      );

      expect(updated[0].enhancement.brightness, EnhancementRules.maxBrightness);
    });
  });

  group('EnhancementRequest', () {
    test('a preview request carries the downscale bound', () {
      const request = EnhancementRequest.preview(
        sourcePath: '/a.jpg',
        destinationPath: '/a-preview.jpg',
        settings: EnhancementSettings.none,
      );

      expect(request.isPreview, isTrue);
      expect(request.maxDimension, EnhancementRules.previewMaxDimension);
    });

    test('a full-resolution request carries none', () {
      const request = EnhancementRequest(
        sourcePath: '/a.jpg',
        destinationPath: '/a-out.jpg',
        settings: EnhancementSettings.none,
      );

      expect(request.isPreview, isFalse);
      expect(request.maxDimension, isNull);
    });

    test('equal requests compare equal', () {
      const one = EnhancementRequest(
        sourcePath: '/a.jpg',
        destinationPath: '/b.jpg',
        settings: EnhancementSettings(brightness: 0.5),
      );
      const two = EnhancementRequest(
        sourcePath: '/a.jpg',
        destinationPath: '/b.jpg',
        settings: EnhancementSettings(brightness: 0.5),
      );

      expect(one, two);
      expect(one.hashCode, two.hashCode);
    });

    test('requests differing only in settings do not compare equal', () {
      const one = EnhancementRequest(
        sourcePath: '/a.jpg',
        destinationPath: '/b.jpg',
        settings: EnhancementSettings(brightness: 0.5),
      );
      const two = EnhancementRequest(
        sourcePath: '/a.jpg',
        destinationPath: '/b.jpg',
        settings: EnhancementSettings(brightness: 0.4),
      );

      expect(one, isNot(two));
    });
  });

  group('adaptive preview dimensions', () {
    test('rounds the measured physical longest edge upward exactly', () {
      expect(
        EnhancementRules.previewDimensionFor(
          logicalLongestEdge: 456.2,
          devicePixelRatio: 2,
        ),
        913,
      );
    });

    test('does not quantise the result into fixed buckets', () {
      expect(
        EnhancementRules.previewDimensionFor(
          logicalLongestEdge: 390.1,
          devicePixelRatio: 3,
        ),
        1171,
      );
    });
  });
}
