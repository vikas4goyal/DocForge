/// CPU fallback adapter for the composed Dart page-rendering pipeline.
///
/// It lives in `app` because the existing job composes geometry from `core`
/// with enhancement infrastructure; the composition layer is the only place
/// allowed to know both. Production executes the job through a background
/// worker, so no pixel work runs on Flutter's UI isolate.
library;

import 'dart:io';

import 'package:doc_scanly/app/page_render_job.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:image/image.dart' as img;

/// Runs the current Dart image pipeline as a typed fallback backend.
class CpuImageProcessingBackend implements ImageProcessingBackend {
  /// Creates the backend over [worker].
  CpuImageProcessingBackend(this.worker);

  /// Executes CPU pixel work outside the Flutter UI isolate.
  final BackgroundWorker worker;

  final Map<String, CancellationToken> _active = {};
  bool _isDisposed = false;

  @override
  Future<ImageProcessingCapability> capability() async =>
      ImageProcessingCapability(
        backend: ImageProcessingBackendKind.cpuFallback,
        isSupported: !_isDisposed,
        // CPU memory, rather than a GPU texture, is the limiting resource.
        maximumTextureSize: _isDisposed ? 0 : 0x7fffffff,
        supportsTiling: false,
      );

  @override
  Future<ImageProcessingBackendResponse> render(
    ImageRenderRequest request,
  ) async {
    if (_isDisposed) {
      return const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.unsupported,
        debugDetail: 'CPU backend is disposed',
      );
    }

    try {
      request.validate();
    } on ArgumentError catch (error) {
      return ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.invalidRequest,
        debugDetail: error.name,
      );
    }

    if (_active.containsKey(request.requestId)) {
      return const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.invalidRequest,
        debugDetail: 'requestId is already active',
      );
    }

    final token = CancellationToken();
    _active[request.requestId] = token;
    final temporaryPath = _temporaryPathFor(request);

    try {
      token.throwIfCancelled();
      final workerResult = await worker.run(
        cpuImageProcessingJob,
        CpuImageProcessingJobRequest(
          request: request,
          temporaryPath: temporaryPath,
        ),
      );

      // A Dart image operation cannot be interrupted safely mid-pixel-loop.
      // Checking immediately after the isolate returns guarantees obsolete
      // bytes are removed and never atomically published.
      if (token.isCancelled) {
        _deleteIfPresent(temporaryPath);
        return const ImageProcessingBackendResponse.failure(
          kind: ImageProcessingFailureKind.cancelled,
        );
      }

      final job = workerResult.valueOrNull;
      if (job == null) {
        _deleteIfPresent(temporaryPath);
        return ImageProcessingBackendResponse.failure(
          kind: workerResult.failureOrNull?.isCancellation ?? false
              ? ImageProcessingFailureKind.cancelled
              : ImageProcessingFailureKind.unexpected,
          debugDetail: 'background worker did not return an output',
        );
      }
      if (job.failureKind case final kind?) {
        _deleteIfPresent(temporaryPath);
        return ImageProcessingBackendResponse.failure(
          kind: kind,
          debugDetail: job.debugDetail,
        );
      }

      try {
        final destination = File(request.destinationPath);
        destination.parent.createSync(recursive: true);
        File(temporaryPath).renameSync(destination.path);
      } on FileSystemException catch (error) {
        _deleteIfPresent(temporaryPath);
        return ImageProcessingBackendResponse.failure(
          kind: error.osError?.errorCode == 28
              ? ImageProcessingFailureKind.storageFull
              : ImageProcessingFailureKind.storage,
          debugDetail: 'atomic publication failed',
        );
      }

      return ImageProcessingBackendResponse.success(
        ImageProcessingResult(
          destinationPath: request.destinationPath,
          sourceWidth: job.sourceWidth!,
          sourceHeight: job.sourceHeight!,
          outputWidth: job.outputWidth!,
          outputHeight: job.outputHeight!,
          backend: ImageProcessingBackendKind.cpuFallback,
          timings: ImageProcessingTimings(
            transformMicroseconds: job.totalMicroseconds,
            totalMicroseconds: job.totalMicroseconds,
          ),
        ),
      );
    } on CancelledException {
      _deleteIfPresent(temporaryPath);
      return const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.cancelled,
      );
    } on Object {
      _deleteIfPresent(temporaryPath);
      return const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.unexpected,
        debugDetail: 'unclassified CPU adapter failure',
      );
    } finally {
      _active.remove(request.requestId)?.dispose();
    }
  }

  @override
  Future<void> cancel(String requestId) async {
    _active[requestId]?.cancel();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final token in _active.values) {
      token.cancel();
    }
  }
}

/// Everything the background isolate needs for one CPU render.
class CpuImageProcessingJobRequest {
  /// Creates a job for [request] writing first to [temporaryPath].
  const CpuImageProcessingJobRequest({
    required this.request,
    required this.temporaryPath,
  });

  /// The validated render request.
  final ImageRenderRequest request;

  /// The unpublished sibling output path.
  final String temporaryPath;
}

/// The sendable outcome produced inside the CPU worker.
class CpuImageProcessingJobOutput {
  /// Creates a successful job output.
  const CpuImageProcessingJobOutput.success({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.outputWidth,
    required this.outputHeight,
    required this.totalMicroseconds,
  }) : failureKind = null,
       debugDetail = null;

  /// Creates a classified failed job output.
  const CpuImageProcessingJobOutput.failure({
    required this.failureKind,
    this.debugDetail,
  }) : outputWidth = null,
       outputHeight = null,
       sourceWidth = null,
       sourceHeight = null,
       totalMicroseconds = 0;

  /// Decoded source width when successful.
  final int? sourceWidth;

  /// Decoded source height when successful.
  final int? sourceHeight;

  /// Published width when successful.
  final int? outputWidth;

  /// Published height when successful.
  final int? outputHeight;

  /// Total job duration measured inside the worker.
  final int totalMicroseconds;

  /// Typed failure when unsuccessful.
  final ImageProcessingFailureKind? failureKind;

  /// Path-free diagnostic detail.
  final String? debugDetail;
}

/// Runs one composed page render on the CPU.
///
/// Returns dimensions and total duration without decoding the output a second
/// time. All operational exceptions are converted into a typed, sendable job
/// output. The caller performs cancellation checks and atomic publication.
CpuImageProcessingJobOutput cpuImageProcessingJob(
  CpuImageProcessingJobRequest input,
) {
  final stopwatch = Stopwatch()..start();
  try {
    final request = input.request;
    final sourceBytes = File(request.sourcePath).readAsBytesSync();
    final sourceDecoder = sourceBytes.length < 16
        ? null
        : img.findDecoderForData(sourceBytes);
    final sourceInfo = sourceDecoder?.startDecode(sourceBytes);
    if (sourceInfo == null) {
      return const CpuImageProcessingJobOutput.failure(
        failureKind: ImageProcessingFailureKind.corruptInput,
        debugDetail: 'source image format is unsupported or corrupt',
      );
    }
    final path = pageRenderJob(
      PageRenderRequest(
        sourcePath: request.sourcePath,
        destinationPath: input.temporaryPath,
        enhancement: request.enhancement,
        isPreview: request.scale == ImageRenderScale.preview,
        transform: request.transform,
        outputWidth: request.outputWidth,
        outputHeight: request.outputHeight,
      ),
    );

    final bytes = File(path).readAsBytesSync();
    final info = img.JpegDecoder().startDecode(bytes);
    if (info == null) {
      _deleteIfPresent(path);
      return const CpuImageProcessingJobOutput.failure(
        failureKind: ImageProcessingFailureKind.codec,
        debugDetail: 'CPU output header could not be decoded',
      );
    }
    stopwatch.stop();
    return CpuImageProcessingJobOutput.success(
      sourceWidth: sourceInfo.width,
      sourceHeight: sourceInfo.height,
      outputWidth: info.width,
      outputHeight: info.height,
      totalMicroseconds: stopwatch.elapsedMicroseconds,
    );
  } on FormatException {
    _deleteIfPresent(input.temporaryPath);
    return const CpuImageProcessingJobOutput.failure(
      failureKind: ImageProcessingFailureKind.corruptInput,
      debugDetail: 'source image could not be decoded',
    );
  } on img.ImageException {
    _deleteIfPresent(input.temporaryPath);
    return const CpuImageProcessingJobOutput.failure(
      failureKind: ImageProcessingFailureKind.corruptInput,
      debugDetail: 'source image could not be decoded',
    );
  } on FileSystemException catch (error) {
    _deleteIfPresent(input.temporaryPath);
    return CpuImageProcessingJobOutput.failure(
      failureKind: error.osError?.errorCode == 28
          ? ImageProcessingFailureKind.storageFull
          : ImageProcessingFailureKind.storage,
      debugDetail: 'CPU file operation failed',
    );
  } on Object {
    _deleteIfPresent(input.temporaryPath);
    return const CpuImageProcessingJobOutput.failure(
      failureKind: ImageProcessingFailureKind.unexpected,
      debugDetail: 'CPU processing failed',
    );
  }
}

String _temporaryPathFor(ImageRenderRequest request) {
  final safeId = request.requestId.replaceAll(RegExp('[^A-Za-z0-9_.-]'), '_');
  return '${request.destinationPath}.$safeId.cpu.tmp';
}

void _deleteIfPresent(String path) {
  try {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  } on FileSystemException {
    // Derived temporary data: cleanup failure must not hide the render failure.
  }
}
