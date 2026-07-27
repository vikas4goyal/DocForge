/// The pure arithmetic behind every enhancement filter and adjustment.
///
/// Deliberately free of the `image` package and of any notion of a bitmap:
/// every function here maps numbers to numbers. That split is what lets the
/// maths be verified against hand-checked values — "a mid-grey pixel at +50%
/// brightness becomes this exact number" — rather than by comparing two
/// photographs and hoping the difference means what we think it does. The
/// traversal that feeds these functions pixel by pixel lives in
/// `infrastructure/enhancement_job.dart`.
///
/// Channel values are doubles in the range 0–255 throughout, not the 0–1 the
/// sliders use. Working in the encoding's own units keeps rounding visible at
/// the point it happens instead of hiding it behind a rescale at each step.
library;

import 'dart:math' as math;

/// Pure per-channel and per-window enhancement arithmetic.
abstract final class EnhancementMaths {
  /// The largest value any channel can hold.
  static const maxChannel = 255.0;

  /// Red's share of perceived brightness, per ITU-R BT.601.
  ///
  /// BT.601 rather than the newer BT.709 because these coefficients are what
  /// JPEG itself uses to derive luma, and every page we handle arrives as a
  /// JPEG. Matching the source encoding means a grayscale conversion agrees
  /// with the luma the camera already computed.
  static const redLuminance = 0.299;

  /// Green's share of perceived brightness.
  static const greenLuminance = 0.587;

  /// Blue's share of perceived brightness.
  static const blueLuminance = 0.114;

  /// Returns the perceived brightness of the colour ([r], [g], [b]).
  static double luminance(num r, num g, num b) =>
      r * redLuminance + g * greenLuminance + b * blueLuminance;

  /// Clamps [value] into the valid channel range.
  static double clampChannel(double value) =>
      value.clamp(0.0, maxChannel).toDouble();

  /// Applies [brightness] and [contrast] to [value].
  ///
  /// Both arrive as offsets in the range -1.0 to 1.0 where 0.0 means unchanged,
  /// which is what the sliders expose and what makes "reset" simply the zero
  /// value.
  ///
  /// Contrast pivots around mid-grey rather than around zero, so increasing it
  /// pushes light tones lighter and dark tones darker instead of brightening
  /// the whole page. Brightness is applied first: a user who brightens an
  /// underexposed capture and then adds contrast expects the contrast to act on
  /// what they can now see, not on the original exposure.
  static double brightnessContrast(
    double value, {
    required double brightness,
    required double contrast,
  }) {
    final brightened = value + brightness * maxChannel;

    // Mapped from the -1..1 slider onto a multiplier from 0 (flat grey) through
    // 1 (unchanged) up to 4. The upper bound is capped rather than unbounded
    // because beyond roughly 4x every document becomes two-tone, at which point
    // the Black & White filter is the control the user actually wants.
    final factor = contrast >= 0 ? 1 + contrast * 3 : 1 + contrast;
    const midpoint = maxChannel / 2;

    return clampChannel(midpoint + (brightened - midpoint) * factor);
  }

  /// Returns the channel bounds that [histogram] should be stretched to fill.
  ///
  /// [histogram] holds one count per channel value, so its length is 256.
  /// [clipFraction] is the share of pixels ignored at each end before the
  /// bounds are taken.
  ///
  /// The clip is the whole point. Taking the true minimum and maximum makes the
  /// stretch hostage to a single stray pixel — one speck of dust reading zero,
  /// one specular highlight reading 255 — and the result is that a page with
  /// any blemish is left untouched. Discarding the extreme half-percent means
  /// the bounds describe the page rather than its outliers.
  ///
  /// Returns bounds that leave the image unchanged when the histogram is empty
  /// or too flat to stretch safely.
  static ({double low, double high}) autoLevelBounds(
    List<int> histogram, {
    double clipFraction = 0.005,
  }) {
    final total = histogram.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return (low: 0, high: maxChannel);

    final clip = (total * clipFraction).round();

    var seen = 0;
    var low = 0;
    for (var value = 0; value < histogram.length; value++) {
      seen += histogram[value];
      if (seen > clip) {
        low = value;
        break;
      }
    }

    seen = 0;
    var high = histogram.length - 1;
    for (var value = histogram.length - 1; value >= 0; value--) {
      seen += histogram[value];
      if (seen > clip) {
        high = value;
        break;
      }
    }

    // A histogram narrower than this is either a blank page or a capture that
    // failed. Stretching it would amplify sensor noise into what looks like
    // texture, so the image is left alone instead.
    const minimumSpread = 8;
    if (high - low < minimumSpread) return (low: 0, high: maxChannel);

    return (low: low.toDouble(), high: high.toDouble());
  }

  /// Maps [value] so that [low] becomes 0 and [high] becomes 255.
  ///
  /// Values outside the bounds clamp rather than extrapolate, which is what
  /// keeps the clipped outliers from [autoLevelBounds] at the extremes where
  /// they belong.
  static double stretch(double value, double low, double high) {
    if (high <= low) return value;
    return clampChannel((value - low) / (high - low) * maxChannel);
  }

  /// Moves [channel] away from [luminance] by [amount].
  ///
  /// [amount] of 0.0 leaves the colour untouched and 1.0 doubles its distance
  /// from grey. Interpolating away from luminance rather than converting to HSV
  /// and scaling S costs three multiplications instead of a colour-space round
  /// trip, and on a page of black text on white paper the two are
  /// indistinguishable — neither has any saturation to scale.
  static double saturate(double channel, double luminance, double amount) =>
      clampChannel(luminance + (channel - luminance) * (1 + amount));

  /// Returns how much detail an unsharp mask adds at [centre] given [blurred].
  ///
  /// Whatever the blur removed was detail, so adding that difference back
  /// amplifies it. [amount] of 0.0 returns zero.
  ///
  /// Returns the *offset* rather than the sharpened value because the caller
  /// applies it to all three channels equally. Sharpening each channel against
  /// its own difference from a shared luminance blur would treat a saturated
  /// region's colour as if it were detail and push it to the extremes; adding
  /// one luminance-derived offset to every channel sharpens the structure and
  /// leaves the hue exactly where it was.
  ///
  /// Preferred over a fixed convolution kernel because the strength is
  /// continuous, which is what the slider needs, and because the same blurred
  /// map the shadow-removal pass already computes can be reused.
  static double unsharpOffset(double centre, double blurred, double amount) =>
      (centre - blurred) * amount * _sharpenScale;

  /// How far the sharpen slider's 0–1 range is stretched.
  ///
  /// At 1.0 the difference is tripled, which is visibly crisp on small text
  /// without producing the white halo around every glyph that over-sharpening
  /// gives.
  static const _sharpenScale = 3.0;

  /// Normalises [value] against the local [background], relative to [reference].
  ///
  /// Shadow removal is division, not subtraction. A page lit unevenly is
  /// *multiplicatively* darkened — the shadow scales the reflected light rather
  /// than subtracting a constant from it — so dividing by an estimate of the
  /// illumination recovers the paper's true tone. Subtracting instead leaves
  /// dark text in shadowed regions crushed to black.
  ///
  /// [background] is the local illumination, taken from a heavily blurred copy
  /// of the page which at a large enough radius contains the lighting and none
  /// of the text. [reference] is the illumination of the best-lit part of the
  /// page.
  ///
  /// Dividing relative to [reference] rather than scaling to full white is what
  /// makes this safe on colour. Normalising every pixel to 255 would push any
  /// saturated region — a red logo, a highlighted line — straight to white,
  /// because a strongly coloured area has a low luminance background through no
  /// fault of the lighting. Against the reference, an evenly lit page has a
  /// gain of one everywhere and is returned untouched, which is precisely the
  /// behaviour a user who enables shadow removal on a good capture expects.
  static double shadowNormalise(
    double value,
    double background,
    double reference,
  ) {
    // A background this dark carries no usable signal; dividing by it would
    // amplify sensor noise by a factor of hundreds.
    if (background < 1) return value;

    // Capped because the gain grows without bound as the background darkens,
    // and an uncapped gain turns the deepest shadow — which holds the least
    // information — into the noisiest part of the result.
    final gain = math.min(reference / background, maxShadowGain);
    return clampChannel(value * gain);
  }

  /// The largest brightening shadow removal will apply.
  ///
  /// Three stops. Beyond that the shadowed region holds too little signal for
  /// the result to be worth showing, and the noise dominates.
  static const maxShadowGain = 3.0;

  /// Returns the illumination of the best-lit part of [background].
  ///
  /// Takes a high percentile rather than the maximum: a single specular
  /// highlight — the sheen off a staple, a glossy patch of paper — reads far
  /// brighter than any paper, and using it as the reference would leave the
  /// whole page under-corrected.
  static double illuminationReference(
    List<double> background, {
    double percentile = 0.95,
  }) {
    if (background.isEmpty) return maxChannel;

    final sorted = [...background]..sort();
    final index = (sorted.length * percentile).floor().clamp(
      0,
      sorted.length - 1,
    );
    return math.max(sorted[index], 1);
  }

  /// Returns black or white for [value] against its [localMean].
  ///
  /// Adaptive rather than global thresholding: a single cutoff for the whole
  /// page turns any shadowed corner into a solid black block, which is the
  /// single most common way a scanner ruins an otherwise good capture.
  /// Comparing each pixel to its own neighbourhood makes the threshold follow
  /// the illumination.
  ///
  /// [bias] shifts the cutoff below the local mean. Some bias is essential:
  /// with none, a uniform region — blank paper — has every pixel within noise
  /// of its own mean, so half of them fall either side and the background comes
  /// out as static.
  static double threshold(
    double value,
    double localMean, {
    double bias = 8.0,
  }) => value < localMean - bias ? 0.0 : maxChannel;

  /// Returns the radius, in pixels, for a blur over an image of [shorterSide].
  ///
  /// Scaled to the image rather than fixed, because a radius that isolates
  /// illumination on a 3000px capture is wide enough to blur away whole
  /// paragraphs on a 400px preview — and the preview must show the user what
  /// the saved page will look like, not a different result at a different size.
  static int blurRadiusFor(int shorterSide) =>
      math.max(1, (shorterSide * _blurRadiusFraction).round());

  /// The blur radius as a fraction of the image's shorter side.
  ///
  /// A twentieth is comfortably wider than any glyph but narrower than the
  /// scale illumination varies over, which is exactly the separation shadow
  /// removal and adaptive thresholding both depend on.
  static const _blurRadiusFraction = 0.05;
}
