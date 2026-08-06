/// The pixel work behind rendering a page from its plan.
///
/// One decode, one resample, one enhancement pass, one encode — in that order,
/// whatever the user did. The composed transform arrives already reduced to a
/// single homography, so a page cropped five times costs exactly what a page
/// cropped once costs (`design.md` D6).
///
/// Everything here runs **inside a background isolate**: it may not touch
/// Flutter, and only the request and the returned path cross the boundary,
/// never a decoded image.
///
/// Lives in `app/` rather than in a feature because it is the one place that
/// joins two of them — the geometry maths in `core` and the enhancement pass
/// owned by `image_enhancement` — and the composition root is the only layer
/// allowed to know both.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/enhancement_job.dart';
import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';

/// The longest edge a preview render is allowed.
///
/// A page drawn a few hundred pixels wide gains nothing from being rendered at
/// twelve megapixels, and the difference is most of the cost of a scroll.
const previewMaxDimension = 1400;

/// JPEG quality for a full-resolution render.
///
/// Matches what correction and enhancement already write at, so a page passing
/// through the pipeline is not degraded twice at different rates.
const renderQuality = 92;

/// JPEG quality for a preview render.
const previewRenderQuality = 82;

/// Everything the isolate needs to render one page.
///
/// A plain value rather than the plan itself: only sendable types may cross an
/// isolate boundary, and this keeps that constraint visible at the call site.
@immutable
class PageRenderRequest {
  /// Creates a request.
  const PageRenderRequest({
    required this.sourcePath,
    required this.destinationPath,
    required this.enhancement,
    required this.isPreview,
    this.transform,
    this.outputWidth,
    this.outputHeight,
  });

  /// The untouched original.
  final String sourcePath;

  /// Where the render is written.
  final String destinationPath;

  /// The settings applied after the geometry.
  final EnhancementSettings enhancement;

  /// Whether this is a display-resolution render.
  final bool isPreview;

  /// The composed geometry, or null when there is none to apply.
  final Homography? transform;

  /// The composed output width, when there is a transform.
  final int? outputWidth;

  /// The composed output height, when there is a transform.
  final int? outputHeight;
}

/// Renders one page and returns the path it was written to.
///
/// A top-level function because a closure cannot be sent to an isolate.
String pageRenderJob(PageRenderRequest request) {
  final bytes = File(request.sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    // An unreadable original is not silently skipped: the caller turns a
    // thrown error into a failure, and a page the user can see must never
    // vanish without explanation.
    throw const FormatException('the page image could not be decoded');
  }

  var working = decoded;

  final transform = request.transform;
  if (transform != null) {
    // One resample, from the original, through the whole composed chain.
    working = _resample(
      working,
      transform,
      CorrectedPageSize(request.outputWidth!, request.outputHeight!),
    );
  }

  if (request.isPreview) {
    working = _downscaledTo(working, previewMaxDimension);
  }

  if (!request.enhancement.isIdentity) {
    // Applied to the geometry's result, which is what makes the enhancement
    // follow a later crop rather than being stale relative to it.
    working = enhance(working, request.enhancement);
  }

  final encoded = img.encodeJpg(
    working,
    quality: request.isPreview ? previewRenderQuality : renderQuality,
  );
  File(request.destinationPath)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(encoded);

  return request.destinationPath;
}

/// Reads an image's pixel dimensions without decoding all of it.
///
/// Used to compose the geometry, which needs the original's size and nothing
/// else. Decoding the whole image to learn two numbers would be the most
/// expensive part of opening the crop screen.
Future<Result<({int width, int height})>> readImageSize(
  String imagePath,
) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const Result<({int width, int height})>.failure(
        Failure.corruptFile(debugDetail: 'the page image could not be decoded'),
      );
    }
    return Result<({int width, int height})>.success((
      width: decoded.width,
      height: decoded.height,
    ));
  } on Object catch (error) {
    return Result<({int width, int height})>.failure(
      Failure.storage(debugDetail: '$error'),
    );
  }
}

/// Runs [pageRenderJob] on [worker] for [plan].
///
/// The adapter between the use case's contract and the isolate's: it flattens
/// the plan into a sendable request and maps a thrown error onto the project's
/// failure vocabulary.
Future<Result<void>> renderPageJob(
  BackgroundWorker worker,
  PageRenderPlan plan, {
  required String destinationPath,
  ComposedGeometry? transform,
}) async {
  try {
    await worker.run(
      pageRenderJob,
      PageRenderRequest(
        sourcePath: plan.originalImagePath,
        destinationPath: destinationPath,
        enhancement: plan.enhancement,
        isPreview: plan.scale == RenderScale.preview,
        transform: transform?.transform,
        outputWidth: transform?.outputSize.width,
        outputHeight: transform?.outputSize.height,
      ),
    );
    return const Result<void>.success(null);
  } on FormatException catch (error) {
    return Result<void>.failure(Failure.corruptFile(debugDetail: '$error'));
  } on FileSystemException catch (error) {
    return Result<void>.failure(
      error.osError?.errorCode == 28
          ? Failure.storageFull(debugDetail: '$error')
          : Failure.storage(debugDetail: '$error'),
    );
  } on Object catch (error) {
    return Result<void>.failure(Failure.unexpected(debugDetail: '$error'));
  }
}

/// Resamples [source] through [transform] into [outputSize].
///
/// Walks output pixels and asks where each came from, because the reverse —
/// scattering input pixels forwards — leaves unwritten holes wherever the
/// transform expands the image.
img.Image _resample(
  img.Image source,
  Homography transform,
  CorrectedPageSize outputSize,
) {
  final output = img.Image(width: outputSize.width, height: outputSize.height);

  for (var y = 0; y < outputSize.height; y++) {
    for (var x = 0; x < outputSize.width; x++) {
      // Sampled at the pixel centre rather than its corner: sampling at the
      // corner biases the whole page half a pixel up and left, which shows as
      // a soft edge on a cropped page.
      final mapped = transform.apply(x + 0.5, y + 0.5);
      final sample = _bilinearSample(source, mapped.x - 0.5, mapped.y - 0.5);
      output.setPixelRgba(x, y, sample.r, sample.g, sample.b, sample.a);
    }
  }

  return output;
}

/// Samples [source] at the fractional position ([x], [y]).
///
/// Bilinear rather than nearest-neighbour: nearest-neighbour turns the
/// near-horizontal lines of text on a slightly rotated page into visible
/// staircases, which is exactly the artefact a document scanner must not add.
({int r, int g, int b, int a}) _bilinearSample(
  img.Image source,
  double x,
  double y,
) {
  final clampedX = x.clamp(0.0, (source.width - 1).toDouble());
  final clampedY = y.clamp(0.0, (source.height - 1).toDouble());

  final x0 = clampedX.floor();
  final y0 = clampedY.floor();
  final x1 = (x0 + 1).clamp(0, source.width - 1);
  final y1 = (y0 + 1).clamp(0, source.height - 1);

  final fx = clampedX - x0;
  final fy = clampedY - y0;

  final p00 = source.getPixel(x0, y0);
  final p10 = source.getPixel(x1, y0);
  final p01 = source.getPixel(x0, y1);
  final p11 = source.getPixel(x1, y1);

  int blend(num a, num b, num c, num d) =>
      (a * (1 - fx) * (1 - fy) +
              b * fx * (1 - fy) +
              c * (1 - fx) * fy +
              d * fx * fy)
          .round()
          .clamp(0, 255);

  return (
    r: blend(p00.r, p10.r, p01.r, p11.r),
    g: blend(p00.g, p10.g, p01.g, p11.g),
    b: blend(p00.b, p10.b, p01.b, p11.b),
    a: blend(p00.a, p10.a, p01.a, p11.a),
  );
}

/// Returns [source] scaled so its longest edge is at most [maxDimension].
///
/// Applied after the geometry, not before: cropping a downscaled image would
/// throw away the detail the crop was meant to keep.
img.Image _downscaledTo(img.Image source, int maxDimension) {
  final longest = source.width > source.height ? source.width : source.height;
  if (longest <= maxDimension) return source;

  final scale = maxDimension / longest;
  return img.copyResize(
    source,
    width: (source.width * scale).round().clamp(1, source.width),
    height: (source.height * scale).round().clamp(1, source.height),
    interpolation: img.Interpolation.average,
  );
}
