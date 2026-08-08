/// Use cases for the scanning flow.
library;

import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/camera_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';

/// Loads exact resolution choices supported by the active camera.
class LoadCameraResolutions {
  /// Creates the use case with its scanning-owned capability boundary.
  const LoadCameraResolutions(this._repository);

  final CameraCapabilityRepository _repository;

  /// Returns supported choices, an empty list when enumeration is unavailable,
  /// or a typed failure that presentation can expose with Retry.
  Future<Result<List<SupportedCameraResolution>>> call() =>
      _repository.loadActiveResolutions();
}

/// Resolves a stable desired tier for the active camera.
class ResolveCaptureResolution {
  /// Creates the use case from the capability loader it invokes each time.
  const ResolveCaptureResolution(this._load);

  final LoadCameraResolutions _load;

  /// Returns the exact supported choice to request.
  ///
  /// A successful null means capability enumeration is unavailable. The
  /// camera adapter must then request its maximum preset and verify the actual
  /// captured dimensions rather than claiming a fixed tier.
  Future<Result<SupportedCameraResolution?>> call(
    DesiredCameraResolution desired,
  ) async {
    final loaded = await _load();
    return switch (loaded) {
      Success(:final value) => Result<SupportedCameraResolution?>.success(
        desired.resolve(value),
      ),
      Failed(:final failure) => Result<SupportedCameraResolution?>.failure(
        failure,
      ),
    };
  }
}

/// Captures one page and adds it to the session.
class CapturePage {
  /// Creates the use case.
  const CapturePage(
    this._scanner,
    this._edges, {
    this.resolveCaptureResolution,
    this.edgeDetectionTimeout = const Duration(seconds: 4),
  });

  final ScannerRepository _scanner;
  final EdgeDetector _edges;

  /// Maximum time capture navigation waits for best-effort edge detection.
  ///
  /// The image is already durably staged at this point, so falling back to the
  /// full page is safer than trapping the user on the camera if a native
  /// detector stalls on an unusual high-resolution frame.
  final Duration edgeDetectionTimeout;

  /// Resolves the current desired tier before camera preparation.
  final ResolveCaptureResolution? resolveCaptureResolution;

  /// Resolves and prepares the camera for [desired].
  Future<Result<SupportedCameraResolution?>> initialise(
    DesiredCameraResolution desired,
  ) async {
    final resolver = resolveCaptureResolution;
    if (resolver == null) {
      final opened = await _scanner.initialise();
      return opened.map((_) => null);
    }
    final resolved = await resolver(desired);
    if (resolved case Failed(:final failure)) {
      return Result<SupportedCameraResolution?>.failure(failure);
    }
    final resolution = resolved.valueOrNull;
    final opened = await _scanner.initialise(resolution: resolution);
    return opened.map((_) => resolution);
  }

  /// Captures a page, detects its edges, and returns it.
  ///
  /// The order is deliberate: the repository writes the image to disk *before*
  /// returning, so by the time edge detection runs the capture is already
  /// durable. A detection failure, an abandoned session or a crash therefore
  /// cannot lose a page the user has already seen the shutter fire for.
  ///
  /// Only a path is ever held. The bytes are read by whichever step needs them
  /// and released again, which is what lets a long batch run on a low-end
  /// device without exhausting memory (`design.md` §7).
  ///
  /// Opens the camera first when it is not already open. The capture screen
  /// opens it on mount, but the page table captures through this use case
  /// without ever showing that screen — so leaving it to the caller meant "Add
  /// page → Camera" failed with "capture before initialise" every time, staged
  /// nothing, and added no page without saying why.
  Future<Result<CapturedPage>> call({
    DesiredCameraResolution desired =
        const DesiredCameraResolution.fullResolution(),
  }) async {
    if (resolveCaptureResolution != null || !_scanner.isReady) {
      final opened = await initialise(desired);
      // A permission refusal or an unopenable camera is reported as itself:
      // the two lead to different recovery actions and must not be collapsed
      // into a generic capture failure.
      if (opened case Failed(:final failure)) {
        return Result<CapturedPage>.failure(failure);
      }
    }

    final captured = await _scanner.capture();

    return captured.flatMapAsync((result) async {
      // Never fails: an undetected page keeps the full-page crop rather than
      // being rejected, which the spec requires explicitly.
      final quad = await _edges
          .detect(result.imagePath)
          .timeout(edgeDetectionTimeout, onTimeout: () => PageQuad.full);

      return Result<CapturedPage>.success(
        CapturedPage(
          id: result.id,
          imagePath: result.imagePath,
          quad: quad,
          thumbnailPath: result.thumbnailPath,
        ),
      );
    });
  }
}

/// Straightens cropped pages, off the UI thread.
class ApplyPerspectiveCorrection {
  /// Creates the use case over its [_worker] and the [_job] it runs.
  ///
  /// The job is injected rather than referenced directly because the code that
  /// moves pixels is infrastructure, and the application layer may not import
  /// it. It must be a top-level or static function: a closure cannot be sent to
  /// an isolate, and one capturing UI state would reintroduce exactly the
  /// hidden coupling the architecture forbids.
  const ApplyPerspectiveCorrection(this._worker, this._job);

  final BackgroundWorker _worker;
  final IsolateJob<PageCorrectionRequest, String> _job;

  /// Corrects every page in [requests], reporting progress as it goes.
  ///
  /// Runs in a background isolate so the UI stays responsive, which the spec
  /// requires. Cancellation is checked between pages rather than during one: a
  /// page is either fully written or never started, so cancelling mid-batch
  /// leaves finished pages intact and no half-written file behind.
  Stream<BatchEvent<String>> call(
    List<PageCorrectionRequest> requests, {
    CancellationToken? token,
  }) => _worker.runBatch(_job, requests, token: token);

  /// Corrects a single page, returning the path it was written to.
  Future<Result<String>> single(PageCorrectionRequest request) =>
      _worker.run(_job, request);
}

/// Clears an abandoned scanning session's captures.
class DiscardScanSession {
  /// Creates the use case.
  const DiscardScanSession(this._staging, this._scanner);

  final ScanStagingArea _staging;
  final ScannerRepository _scanner;

  /// Releases the camera and removes every capture the session wrote.
  ///
  /// The camera is released first and unconditionally: leaving the device held
  /// because a file delete failed would make the next scan impossible, which is
  /// far worse than an orphaned file the cache directory will reclaim.
  Future<Result<void>> call() async {
    await _scanner.dispose();
    return _staging.clear();
  }
}
