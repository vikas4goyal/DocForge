/// The pixel work behind perspective correction.
///
/// Separated from the maths in `domain/perspective_transform.dart` so the
/// homography can be verified against hand-checked numbers without an image,
/// and this file can be replaced without touching the maths.
///
/// Everything here runs **inside a background isolate**. Two consequences that
/// are easy to forget: it may not touch Flutter, and only the request and the
/// returned path cross the boundary — never a decoded image (`design.md` §7).
library;

import 'dart:io';

import 'package:doc_forge/features/document_scanning/domain/perspective_transform.dart';
import 'package:image/image.dart' as img;

/// JPEG quality used for a corrected page.
///
/// High enough that a second pass through PDF generation does not visibly
/// compound artefacts, low enough that a fifty-page scan stays a sane size.
const correctedPageQuality = 92;

/// Straightens one page and returns the path it was written to.
///
/// A top-level function because a closure cannot be sent to an isolate.
///
/// Reads the image, computes the transform from the request's quad, resamples,
/// writes, and releases. Nothing is retained between calls, so correcting fifty
/// pages costs one page's memory rather than fifty.
String correctPageJob(PageCorrectionRequest request) {
  final bytes = File(request.sourcePath).readAsBytesSync();
  final source = img.decodeImage(bytes);

  if (source == null) {
    // An unreadable capture is not silently skipped: the caller turns a thrown
    // error into a failure, and a page the user can see must never vanish
    // without explanation.
    throw const FormatException('the captured page could not be decoded');
  }

  final quad = request.quad;

  // Dimensions come from the decoded image rather than from the caller, so a
  // caller cannot describe an image incorrectly and silently produce a skewed
  // page.
  final outputSize = PerspectiveTransform.outputSizeFor(
    quad,
    imageWidth: source.width,
    imageHeight: source.height,
  );

  final transform = PerspectiveTransform.solve(
    quad,
    imageWidth: source.width,
    imageHeight: source.height,
    outputSize: outputSize,
  );

  final corrected = _resample(source, transform, outputSize);

  File(
    request.destinationPath,
  ).writeAsBytesSync(img.encodeJpg(corrected, quality: correctedPageQuality));

  return request.destinationPath;
}

/// Renders [source] through [transform] into an image of [outputSize].
///
/// Walks every *output* pixel and asks the transform where it came from. The
/// reverse — walking input pixels and scattering them forward — leaves
/// unwritten holes wherever the transform expands the image, which is exactly
/// what correcting the compressed far edge of a tilted page does.
img.Image _resample(
  img.Image source,
  Homography transform,
  CorrectedPageSize outputSize,
) {
  final output = img.Image(width: outputSize.width, height: outputSize.height);

  for (var y = 0; y < outputSize.height; y++) {
    for (var x = 0; x < outputSize.width; x++) {
      // Sampled at the pixel centre rather than its corner. Sampling at the
      // corner biases the whole page half a pixel up and left, which is
      // invisible on one page and shows as a soft edge on a cropped one.
      final mapped = transform.apply(x + 0.5, y + 0.5);
      final sample = _bilinearSample(source, mapped.x - 0.5, mapped.y - 0.5);

      // Written straight into the output. Nothing here ever writes to `source`:
      // `getPixel` hands back a live view into the image's own buffer, so
      // mutating one would corrupt the neighbours the next samples read.
      output.setPixelRgba(x, y, sample.r, sample.g, sample.b, sample.a);
    }
  }

  return output;
}

/// Samples [source] at the fractional position ([x], [y]).
///
/// Bilinear rather than nearest-neighbour: nearest-neighbour turns the near-
/// horizontal lines of text on a slightly rotated page into visible staircases,
/// which is precisely the artefact a document scanner must not introduce.
///
/// Coordinates outside the image clamp to the edge rather than wrapping or
/// returning transparent, so a crop that reaches slightly past the capture
/// produces a smeared border rather than a black one.
({num r, num g, num b, num a}) _bilinearSample(
  img.Image source,
  double x,
  double y,
) {
  final x0 = x.floor().clamp(0, source.width - 1);
  final y0 = y.floor().clamp(0, source.height - 1);
  final x1 = (x0 + 1).clamp(0, source.width - 1);
  final y1 = (y0 + 1).clamp(0, source.height - 1);

  final fx = (x - x0).clamp(0.0, 1.0);
  final fy = (y - y0).clamp(0.0, 1.0);

  // Channel values are read out immediately rather than the pixels being held:
  // each is a view into the shared buffer, and holding four of them across the
  // interpolation would be four aliases of whatever was read last.
  final tl = _channelsAt(source, x0, y0);
  final tr = _channelsAt(source, x1, y0);
  final bl = _channelsAt(source, x0, y1);
  final br = _channelsAt(source, x1, y1);

  num blend(num a, num b, num c, num d) =>
      (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy;

  return (
    r: blend(tl.r, tr.r, bl.r, br.r),
    g: blend(tl.g, tr.g, bl.g, br.g),
    b: blend(tl.b, tr.b, bl.b, br.b),
    a: blend(tl.a, tr.a, bl.a, br.a),
  );
}

/// Reads the four channel values at ([x], [y]) as plain numbers.
({num r, num g, num b, num a}) _channelsAt(img.Image source, int x, int y) {
  final pixel = source.getPixel(x, y);
  return (r: pixel.r, g: pixel.g, b: pixel.b, a: pixel.a);
}
