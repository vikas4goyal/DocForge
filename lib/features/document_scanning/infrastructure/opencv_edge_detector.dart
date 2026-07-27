/// Automatic document edge detection, backed by OpenCV.
///
/// Only the computer-vision primitives live here — greyscale, blur, Canny,
/// `findContours`, `approxPolyDP`. Every *decision* made from their output is
/// in `domain/page_edge_geometry.dart`: which candidate is the page, whether it
/// is plausible, and which corner is which.
///
/// That split is not stylistic. The OpenCV binding loads a native library that
/// is present on Android and iOS but not in the host test VM, so nothing in
/// this file can run under `flutter test`. Keeping it to calls whose behaviour
/// is guaranteed upstream, and putting the judgement where it can be tested
/// exhaustively, is what stops "automatic detection" from being a large block
/// of untested logic. See `design.md` §22.
library;

import 'dart:isolate';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_scanning/domain/page_edge_geometry.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';

/// Finds the document outline in a capture using OpenCV.
///
/// Falls back to the whole page whenever detection finds nothing plausible or
/// fails outright. That fallback is the specified behaviour rather than an
/// error path: the spec requires an undetected capture to be kept, with the
/// full page as the default crop for the user to adjust.
class OpenCvEdgeDetector implements EdgeDetector {
  /// Creates the detector.
  const OpenCvEdgeDetector();

  @override
  Future<PageQuad> detect(String imagePath) async {
    try {
      // Run off the UI thread. Contour finding on a capture is tens of
      // milliseconds, which is enough to drop frames on the live preview the
      // user is still looking at.
      return await Isolate.run(() => detectPageQuadJob(imagePath));
    } on Object {
      // Detection is best-effort by contract: `EdgeDetector.detect` never
      // fails, because a page whose edges cannot be found still has a usable
      // crop and must not be lost.
      return PageQuad.full;
    }
  }
}

/// Detects the page outline in the image at [imagePath].
///
/// A top-level function because a closure cannot be sent to an isolate.
///
/// Returns [PageQuad.full] when no plausible outline is found, which is the
/// behaviour the spec requires rather than a failure.
PageQuad detectPageQuadJob(String imagePath) {
  final source = cv.imread(imagePath);
  if (source.isEmpty) return PageQuad.full;

  try {
    final scaled = _downscaled(source);

    try {
      final candidates = _candidatesIn(scaled.mat);

      return PageEdgeGeometry.quadFor(
        candidates,
        imageWidth: scaled.mat.cols,
        imageHeight: scaled.mat.rows,
      );
    } finally {
      // Only dispose the scaled copy when it really is a copy; disposing the
      // source twice would free the same native buffer twice.
      if (!identical(scaled.mat, source)) scaled.mat.dispose();
    }
  } finally {
    source.dispose();
  }
}

/// Returns [source] scaled so its longest edge is within the detection bound.
({cv.Mat mat, double scale}) _downscaled(cv.Mat source) {
  final longest = source.cols > source.rows ? source.cols : source.rows;
  if (longest <= PageEdgeGeometry.detectionMaxDimension) {
    return (mat: source, scale: 1);
  }

  final scale = PageEdgeGeometry.detectionMaxDimension / longest;
  final resized = cv.resize(source, (
    (source.cols * scale).round().clamp(1, source.cols),
    (source.rows * scale).round().clamp(1, source.rows),
  ), interpolation: cv.INTER_AREA);

  return (mat: resized, scale: scale);
}

/// The Canny lower threshold.
///
/// Low, because the edge that matters — white paper against a desk — is often a
/// gentle gradient rather than a hard step, and a high threshold loses exactly
/// the boundary we are looking for. The plausibility checks downstream are what
/// discard the extra contours a permissive threshold produces.
const _cannyLowThreshold = 50.0;

/// The Canny upper threshold.
///
/// Three times the lower, the ratio OpenCV's own documentation recommends for
/// hysteresis: strong edges seed a contour and weak ones may only extend it.
const _cannyHighThreshold = 150.0;

/// How much of a contour's perimeter a corner may be displaced by, when the
/// contour is approximated to a polygon.
///
/// Two per cent is enough to collapse the hundreds of points along a slightly
/// wavy paper edge into four corners, and tight enough that a genuinely curved
/// object does not approximate to a quadrilateral.
const _polygonEpsilonFraction = 0.02;

/// Returns every quadrilateral contour found in [image].
List<EdgeCandidate> _candidatesIn(cv.Mat image) {
  final grey = cv.cvtColor(image, cv.COLOR_BGR2GRAY);

  try {
    // Blurred before edge detection so paper texture and print do not each
    // produce their own contour. Without it, a page of dense text yields
    // hundreds of small candidates and the page outline is lost among them.
    final blurred = cv.gaussianBlur(grey, (5, 5), 0);

    try {
      final edges = cv.canny(blurred, _cannyLowThreshold, _cannyHighThreshold);

      try {
        // Dilated to close the small gaps Canny leaves where a paper edge
        // crosses a similarly-coloured background. An outline broken in one
        // place is not a closed contour, and `findContours` would return the
        // page as an open curve rather than as a shape.
        final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));

        try {
          final closed = cv.dilate(edges, kernel);

          try {
            final (contours, _) = cv.findContours(
              closed,
              cv.RETR_EXTERNAL,
              cv.CHAIN_APPROX_SIMPLE,
            );

            return [for (final contour in contours) ?_asQuadrilateral(contour)];
          } finally {
            closed.dispose();
          }
        } finally {
          kernel.dispose();
        }
      } finally {
        edges.dispose();
      }
    } finally {
      blurred.dispose();
    }
  } finally {
    grey.dispose();
  }
}

/// Approximates [contour] to a polygon, returning it only if it has four
/// corners.
///
/// Returns null for anything else. A three- or five-sided approximation is not
/// a sheet of paper seen at an angle, whatever else it might be.
EdgeCandidate? _asQuadrilateral(cv.VecPoint contour) {
  final perimeter = cv.arcLength(contour, true);
  if (perimeter <= 0) return null;

  final approximated = cv.approxPolyDP(
    contour,
    _polygonEpsilonFraction * perimeter,
    true,
  );

  try {
    if (approximated.length != 4) return null;

    return EdgeCandidate([
      for (final point in approximated)
        (x: point.x.toDouble(), y: point.y.toDouble()),
    ]);
  } finally {
    approximated.dispose();
  }
}
