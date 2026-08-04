/// Use cases for the scanning flow.
library;

import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';

/// Captures one page and adds it to the session.
class CapturePage {
  /// Creates the use case.
  const CapturePage(this._scanner, this._edges);

  final ScannerRepository _scanner;
  final EdgeDetector _edges;

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
  Future<Result<CapturedPage>> call() async {
    if (!_scanner.isReady) {
      final opened = await _scanner.initialise();
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
      final quad = await _edges.detect(result.imagePath);

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
