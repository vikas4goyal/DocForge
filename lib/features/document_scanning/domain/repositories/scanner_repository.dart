/// The contracts the scanning feature depends on.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/result.dart';

/// A capture written to disk, plus what was learned about it.
class CaptureResult {
  /// Creates a capture result.
  const CaptureResult({
    required this.id,
    required this.imagePath,
    this.thumbnailPath,
  });

  /// Identifier assigned to this capture.
  final PageId id;

  /// Path to the full-resolution image already written to disk.
  final String imagePath;

  /// Path to a generated thumbnail, when one was produced.
  final String? thumbnailPath;
}

/// Drives the device camera and writes captures to disk.
///
/// Declared here and implemented in infrastructure, so the capture use cases
/// depend on this rather than on `camera`, and every one of them can be tested
/// against a fake that never opens a device.
abstract interface class ScannerRepository {
  /// Prepares the camera for capture.
  ///
  /// Fails with a permission failure when access was refused and a camera
  /// failure when the device could not be opened — the two lead to different
  /// recovery actions, so they are never collapsed into one.
  Future<Result<void>> initialise();

  /// Captures one page, writing it to disk before returning.
  ///
  /// Returns only paths. The bytes never come back across this boundary, which
  /// is what keeps a long batch from accumulating images in memory.
  Future<Result<CaptureResult>> capture();

  /// Releases the camera.
  ///
  /// Must be safe to call more than once and safe to call when the camera was
  /// never opened: the capture screen releases on every exit path, and some of
  /// those paths run without a successful initialise.
  Future<Result<void>> dispose();

  /// Whether the torch is currently on.
  bool get isTorchOn;

  /// Turns the torch on or off.
  Future<Result<void>> setTorch({required bool on});

  /// Whether the camera is currently ready to capture.
  bool get isReady;
}

/// Finds the document edges in a captured image.
///
/// Behind an interface because V1 ships the fallback below and automatic
/// detection lands later (task 6.20); the capture flow is written against this
/// contract so that change is a substitution rather than a rewrite.
abstract interface class EdgeDetector {
  /// Returns the detected document quadrilateral for the image at [imagePath].
  ///
  /// Never fails: a page whose edges cannot be found still has a usable crop.
  /// The spec is explicit that an undetected capture is kept, not rejected.
  Future<PageQuad> detect(String imagePath);
}

/// The edge detector used until automatic detection lands.
///
/// Returns the full page every time, which the spec names as the required
/// behaviour when edges cannot be detected: the capture is kept, the full page
/// becomes the default crop, and the user adjusts the corners by hand.
///
/// Shipping this rather than blocking the capture flow on detection means the
/// flow is complete and testable now, and gaining detection later changes one
/// injected object.
class FullPageEdgeDetector implements EdgeDetector {
  /// Creates the fallback detector.
  const FullPageEdgeDetector();

  @override
  Future<PageQuad> detect(String imagePath) async => PageQuad.full;
}
