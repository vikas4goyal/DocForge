/// The contracts the scanning feature depends on.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Where a scanning session writes its captures.
///
/// A session's pages are written before the document exists, so they cannot go
/// in the document's own directory yet. They live in a staging directory that
/// is handed to PDF generation on save and cleared if the session is abandoned.
///
/// Declared here rather than in infrastructure because the use cases depend on
/// it: discarding a session clears it, and correcting a page writes into it.
abstract interface class ScanStagingArea {
  /// Returns the directory this session's captures are written to.
  Future<Result<Directory>> directory();

  /// Removes everything the session wrote.
  ///
  /// Called when a session is abandoned. Without it, every cancelled scan would
  /// leave full-resolution captures on the device forever.
  Future<Result<void>> clear();
}

/// A capture written to disk, plus what was learned about it.
class CaptureResult {
  /// Creates a capture result.
  const CaptureResult({
    required this.id,
    required this.imagePath,
    this.thumbnailPath,
    this.actualWidth,
    this.actualHeight,
  });

  /// Identifier assigned to this capture.
  final PageId id;

  /// Path to the full-resolution image already written to disk.
  final String imagePath;

  /// Path to a generated thumbnail, when one was produced.
  final String? thumbnailPath;

  /// Actual captured width decoded from the staged image, when available.
  final int? actualWidth;

  /// Actual captured height decoded from the staged image, when available.
  final int? actualHeight;
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
  Future<Result<void>> initialise({SupportedCameraResolution? resolution});

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
