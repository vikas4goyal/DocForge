/// The pixel work behind image enhancement.
///
/// Separated from the arithmetic in `domain/enhancement_maths.dart` so the
/// maths can be verified against hand-checked numbers without an image, and so
/// this file can be replaced without touching them.
///
/// Everything here runs **inside a background isolate**. Two consequences that
/// are easy to forget: it may not touch Flutter, and only the request and the
/// returned path cross the boundary — never a decoded image (`design.md` §7).
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_maths.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:image/image.dart' as img;

/// JPEG quality used for an enhanced page.
///
/// Matches the quality perspective correction writes at, so a page that passes
/// through both steps is not degraded twice at different rates.
const enhancedPageQuality = 92;

/// JPEG quality used for an enhancement preview.
///
/// Lower than the saved page because the preview is displayed once at a
/// fraction of the size and then discarded; the artefacts this introduces are
/// below the threshold of visibility at preview scale, and the saving shows up
/// directly as slider responsiveness.
const previewQuality = 80;

/// Enhances one page and returns the path it was written to.
///
/// A top-level function because a closure cannot be sent to an isolate.
///
/// Reads the image, applies the filter and then the adjustments, writes, and
/// releases. Nothing is retained between calls, so enhancing fifty pages costs
/// one page's memory rather than fifty.
String enhancePageJob(EnhancementRequest request) {
  final settings = EnhancementRules.clamp(request.settings);

  // Previews read a cached downscaled copy rather than the capture itself.
  // Decoding a ~12 megapixel JPEG only to shrink it to the preview bound cost
  // more than the filtering did, and it was paid again on every slider
  // movement — which is what made the enhance screen feel stuck.
  final readPath = _sourceForRequest(request);
  final bytes = File(readPath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    // An unreadable page is not silently skipped: the caller turns a thrown
    // error into a failure, and a page the user can see must never vanish
    // without explanation.
    throw const FormatException('the page image could not be decoded');
  }

  final source = _downscaled(decoded, request.maxDimension);

  // Nothing to do beyond a resize. Re-encoding an untouched full-resolution
  // page would cost it a generation of JPEG loss for no visible benefit, so the
  // original file is copied instead of rewritten.
  if (!EnhancementRules.requiresProcessing(settings)) {
    if (identical(source, decoded)) {
      // Copies whatever was actually read: for a preview that is the working
      // copy, so an unfiltered preview does not hand the UI the full-resolution
      // capture to decode and display.
      File(readPath).copySync(request.destinationPath);
    } else {
      File(
        request.destinationPath,
      ).writeAsBytesSync(img.encodeJpg(source, quality: previewQuality));
    }
    return request.destinationPath;
  }

  final enhanced = enhance(source, settings);

  File(request.destinationPath).writeAsBytesSync(
    img.encodeJpg(
      enhanced,
      quality: request.isPreview ? previewQuality : enhancedPageQuality,
    ),
  );

  return request.destinationPath;
}

/// Applies [settings] to [source], returning a new image.
///
/// Exposed rather than private so the filters can be tested against fixture
/// images without going through the filesystem.
///
/// Order matters and is fixed: shadow removal first, because it normalises the
/// illumination every later step assumes is even; then the filter, which
/// decides the page's colour character; then brightness and contrast, so the
/// sliders act on what the user can currently see; then sharpening last,
/// because sharpening before a contrast increase amplifies the halo the
/// contrast then exaggerates.
img.Image enhance(img.Image source, EnhancementSettings settings) {
  final blurRadius = EnhancementMaths.blurRadiusFor(
    math.min(source.width, source.height),
  );

  // Computed once and shared. Shadow removal, adaptive thresholding and the
  // unsharp mask all need the same blurred copy, and a box blur over a
  // full-resolution page is the most expensive single step in the pipeline.
  final needsBlur =
      settings.shadowRemoval ||
      settings.sharpen > 0 ||
      settings.filter == EnhancementFilter.blackAndWhite;
  final blurred = needsBlur ? _boxBlurLuminance(source, blurRadius) : null;

  var working = source;

  if (settings.shadowRemoval) {
    working = _removeShadows(working, blurred!);
  }

  working = switch (settings.filter) {
    EnhancementFilter.original => working,
    EnhancementFilter.grayscale => _grayscale(working),
    EnhancementFilter.autoEnhance => _autoEnhance(working),
    EnhancementFilter.magicColour => _magicColour(working),
    EnhancementFilter.blackAndWhite => _blackAndWhite(working, blurred!),
  };

  if (settings.brightness != 0 || settings.contrast != 0) {
    working = _brightnessContrast(
      working,
      brightness: settings.brightness,
      contrast: settings.contrast,
    );
  }

  if (settings.sharpen > 0) {
    working = _sharpen(working, blurred!, settings.sharpen);
  }

  return working;
}

/// The path a request should actually decode.
///
/// A full-resolution render reads the capture. A preview reads a downscaled
/// working copy kept beside it, creating that copy the first time it is asked
/// for. Every later preview of the same page then decodes roughly one megapixel
/// instead of twelve, which is the difference between a slider that tracks the
/// finger and one that does not.
///
/// The working copy is derived data: if anything goes wrong producing it, the
/// capture is used directly. A slow preview is worth far more than a failed one.
String _sourceForRequest(EnhancementRequest request) {
  final maxDimension = request.maxDimension;
  if (maxDimension == null) return request.sourcePath;

  final source = File(request.sourcePath);
  final working = File('${request.sourcePath}.work.jpg');

  try {
    // Regenerated when the capture is newer, so a re-crop of the same page
    // cannot leave a stale working copy behind for the enhance screen to show.
    if (working.existsSync() &&
        !working.lastModifiedSync().isBefore(source.lastModifiedSync())) {
      return working.path;
    }

    final decoded = img.decodeImage(source.readAsBytesSync());
    if (decoded == null) return request.sourcePath;

    final scaled = _downscaled(decoded, maxDimension);
    if (identical(scaled, decoded)) {
      // Already within the bound — a working copy would be a second file with
      // nothing to offer over the original.
      return request.sourcePath;
    }

    working.writeAsBytesSync(img.encodeJpg(scaled, quality: previewQuality));
    return working.path;
  } on Object {
    return request.sourcePath;
  }
}

/// Returns [source] scaled so its longest edge is at most [maxDimension].
///
/// Returns [source] itself when no downscale is needed, which the caller uses
/// to decide whether the original file can simply be copied.
img.Image _downscaled(img.Image source, int? maxDimension) {
  if (maxDimension == null) return source;

  final longest = math.max(source.width, source.height);
  if (longest <= maxDimension) return source;

  final scale = maxDimension / longest;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
}

/// Reads the four channel values at ([x], [y]) as plain numbers.
///
/// Values are read out immediately rather than the pixel being held, because
/// `getPixel` returns a live view into the image's own buffer: keeping two of
/// them would leave both aliasing whatever was read last.
({num r, num g, num b, num a}) _channelsAt(img.Image source, int x, int y) {
  final pixel = source.getPixel(x, y);
  return (r: pixel.r, g: pixel.g, b: pixel.b, a: pixel.a);
}

/// Builds a blurred luminance map of [source] with the given [radius].
///
/// Returned as a flat `Float64List`-shaped list rather than an image because
/// every consumer wants a single brightness number per pixel, and carrying
/// three identical channels through the most memory-hungry step in the
/// pipeline would triple its cost for nothing.
///
/// Implemented as two separable one-dimensional passes over a running sum. A
/// naive two-dimensional box blur costs `radius²` reads per pixel, which at the
/// radii shadow removal needs — a twentieth of the page — makes a
/// full-resolution page take minutes rather than moments.
List<double> _boxBlurLuminance(img.Image source, int radius) {
  final width = source.width;
  final height = source.height;
  final luminance = List<double>.filled(width * height, 0);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final c = _channelsAt(source, x, y);
      luminance[y * width + x] = EnhancementMaths.luminance(c.r, c.g, c.b);
    }
  }

  final horizontal = List<double>.filled(width * height, 0);
  for (var y = 0; y < height; y++) {
    final row = y * width;
    var sum = 0.0;

    // Seed the window at x = 0, where everything left of the image clamps to
    // the first column. Clamping rather than treating the outside as black is
    // what stops shadow removal from inventing a dark border on every page.
    for (var offset = -radius; offset <= radius; offset++) {
      sum += luminance[row + offset.clamp(0, width - 1)];
    }

    final window = radius * 2 + 1;
    for (var x = 0; x < width; x++) {
      horizontal[row + x] = sum / window;
      final leaving = (x - radius).clamp(0, width - 1);
      final entering = (x + radius + 1).clamp(0, width - 1);
      sum += luminance[row + entering] - luminance[row + leaving];
    }
  }

  final blurred = List<double>.filled(width * height, 0);
  for (var x = 0; x < width; x++) {
    var sum = 0.0;
    for (var offset = -radius; offset <= radius; offset++) {
      sum += horizontal[offset.clamp(0, height - 1) * width + x];
    }

    final window = radius * 2 + 1;
    for (var y = 0; y < height; y++) {
      blurred[y * width + x] = sum / window;
      final leaving = (y - radius).clamp(0, height - 1);
      final entering = (y + radius + 1).clamp(0, height - 1);
      sum += horizontal[entering * width + x] - horizontal[leaving * width + x];
    }
  }

  return blurred;
}

/// Applies [transform] to every pixel of [source], returning a new image.
///
/// Always writes into a fresh image. Writing back into [source] would corrupt
/// the neighbours any windowed operation still has to read, and would mutate
/// the caller's image behind its back.
img.Image _map(
  img.Image source,
  ({num r, num g, num b}) Function(
    ({num r, num g, num b, num a}) pixel,
    int x,
    int y,
  )
  transform,
) {
  final output = img.Image(width: source.width, height: source.height);

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = _channelsAt(source, x, y);
      final mapped = transform(pixel, x, y);
      output.setPixelRgba(x, y, mapped.r, mapped.g, mapped.b, pixel.a);
    }
  }

  return output;
}

/// Divides out the uneven illumination described by [background].
img.Image _removeShadows(img.Image source, List<double> background) {
  final width = source.width;
  final reference = EnhancementMaths.illuminationReference(background);

  return _map(source, (pixel, x, y) {
    final illumination = background[y * width + x];
    double normalise(num channel) => EnhancementMaths.shadowNormalise(
      channel.toDouble(),
      illumination,
      reference,
    );

    return (
      r: normalise(pixel.r),
      g: normalise(pixel.g),
      b: normalise(pixel.b),
    );
  });
}

/// Converts [source] to grayscale, retaining tonal detail.
img.Image _grayscale(img.Image source) => _map(source, (pixel, _, _) {
  final value = EnhancementMaths.luminance(pixel.r, pixel.g, pixel.b);
  return (r: value, g: value, b: value);
});

/// Stretches each channel of [source] to fill the full range.
///
/// Channels are levelled independently rather than together, which corrects a
/// colour cast as well as the contrast: a page photographed under tungsten
/// light has a blue channel that never reaches its maximum, and stretching each
/// channel to its own bounds is what neutralises that.
img.Image _autoEnhance(img.Image source) {
  final red = List<int>.filled(256, 0);
  final green = List<int>.filled(256, 0);
  final blue = List<int>.filled(256, 0);

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = _channelsAt(source, x, y);
      red[pixel.r.round().clamp(0, 255)]++;
      green[pixel.g.round().clamp(0, 255)]++;
      blue[pixel.b.round().clamp(0, 255)]++;
    }
  }

  final redBounds = EnhancementMaths.autoLevelBounds(red);
  final greenBounds = EnhancementMaths.autoLevelBounds(green);
  final blueBounds = EnhancementMaths.autoLevelBounds(blue);

  return _map(source, (pixel, _, _) {
    return (
      r: EnhancementMaths.stretch(
        pixel.r.toDouble(),
        redBounds.low,
        redBounds.high,
      ),
      g: EnhancementMaths.stretch(
        pixel.g.toDouble(),
        greenBounds.low,
        greenBounds.high,
      ),
      b: EnhancementMaths.stretch(
        pixel.b.toDouble(),
        blueBounds.low,
        blueBounds.high,
      ),
    );
  });
}

/// How far Magic Colour pushes saturation beyond the original.
///
/// Tuned for printed material: enough that a highlighter stroke or a company
/// logo reads as the colour it is on paper, short of the point where skin tones
/// in a photographed ID card turn orange.
const _magicColourSaturation = 0.45;

/// The contrast lift Magic Colour applies along with its saturation boost.
const _magicColourContrast = 0.15;

/// Applies the saturated, contrast-lifted Magic Colour profile.
img.Image _magicColour(img.Image source) {
  final levelled = _autoEnhance(source);

  final saturated = _map(levelled, (pixel, _, _) {
    final luminance = EnhancementMaths.luminance(pixel.r, pixel.g, pixel.b);
    return (
      r: EnhancementMaths.saturate(
        pixel.r.toDouble(),
        luminance,
        _magicColourSaturation,
      ),
      g: EnhancementMaths.saturate(
        pixel.g.toDouble(),
        luminance,
        _magicColourSaturation,
      ),
      b: EnhancementMaths.saturate(
        pixel.b.toDouble(),
        luminance,
        _magicColourSaturation,
      ),
    );
  });

  return _brightnessContrast(
    saturated,
    brightness: 0,
    contrast: _magicColourContrast,
  );
}

/// Reduces [source] to black and white against the local mean in [background].
img.Image _blackAndWhite(img.Image source, List<double> background) {
  final width = source.width;

  return _map(source, (pixel, x, y) {
    final value = EnhancementMaths.luminance(pixel.r, pixel.g, pixel.b);
    final binary = EnhancementMaths.threshold(value, background[y * width + x]);
    return (r: binary, g: binary, b: binary);
  });
}

/// Applies [brightness] and [contrast] to every channel of [source].
img.Image _brightnessContrast(
  img.Image source, {
  required double brightness,
  required double contrast,
}) {
  // Precomputed as a 256-entry lookup rather than evaluated per pixel: the
  // arithmetic is identical for every pixel of the same value, and a
  // twelve-megapixel page has forty-eight thousand pixels per distinct value.
  final lookup = List<double>.generate(
    256,
    (value) => EnhancementMaths.brightnessContrast(
      value.toDouble(),
      brightness: brightness,
      contrast: contrast,
    ),
  );

  double at(num channel) => lookup[channel.round().clamp(0, 255)];

  return _map(
    source,
    (pixel, _, _) => (r: at(pixel.r), g: at(pixel.g), b: at(pixel.b)),
  );
}

/// Sharpens [source] against its [blurred] luminance by [amount].
///
/// One offset, derived from luminance, is added to all three channels. See
/// [EnhancementMaths.unsharpOffset] for why sharpening each channel
/// independently against a shared blur would distort colour.
img.Image _sharpen(img.Image source, List<double> blurred, double amount) {
  final width = source.width;

  return _map(source, (pixel, x, y) {
    final luminance = EnhancementMaths.luminance(pixel.r, pixel.g, pixel.b);
    final offset = EnhancementMaths.unsharpOffset(
      luminance,
      blurred[y * width + x],
      amount,
    );

    return (
      r: EnhancementMaths.clampChannel(pixel.r + offset),
      g: EnhancementMaths.clampChannel(pixel.g + offset),
      b: EnhancementMaths.clampChannel(pixel.b + offset),
    );
  });
}
