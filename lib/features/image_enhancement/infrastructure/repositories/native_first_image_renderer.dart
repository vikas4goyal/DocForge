/// Native-first image renderer with deterministic CPU fallback.
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';

/// Selects native GPU processing when supported and retries eligible failures.
///
/// Both dependencies are explicit [ImageProcessingBackend] instances, so host
/// tests can inject scripts and production can compose the native data source
/// with the isolate-backed CPU adapter. Capability is probed lazily once per
/// renderer instance; a render-time GPU failure does not permanently disable a
/// later independent request.
class NativeFirstImageRenderer implements ImageProcessingBackend {
  /// Creates a native-first renderer.
  NativeFirstImageRenderer({
    required this.native,
    required this.cpu,
    this.telemetry = const NoopAppTelemetry(),
  });

  /// The Android or iOS GPU backend.
  final ImageProcessingBackend native;

  /// The deterministic fallback and host implementation.
  final ImageProcessingBackend cpu;

  /// Privacy-safe operational telemetry.
  final AppTelemetry telemetry;

  Future<ImageProcessingCapability>? _nativeCapability;
  final Set<String> _cancelled = {};
  bool _isDisposed = false;

  @override
  Future<ImageProcessingCapability> capability() async {
    if (_isDisposed) return cpu.capability();
    final accelerated = await (_nativeCapability ??= native.capability());
    return accelerated.isSupported ? accelerated : cpu.capability();
  }

  @override
  Future<ImageProcessingBackendResponse> render(
    ImageRenderRequest request,
  ) async {
    final trace = await telemetry.startTrace('image_processing_render');
    final stopwatch = Stopwatch()..start();
    ImageProcessingFailureKind? fallbackReason;

    try {
      if (_isDisposed) {
        return _recordAndReturn(
          request: request,
          response: const ImageProcessingBackendResponse.failure(
            kind: ImageProcessingFailureKind.unsupported,
            debugDetail: 'renderer is disposed',
          ),
          trace: trace,
          elapsed: stopwatch.elapsed,
        );
      }

      try {
        request.validate();
      } on ArgumentError catch (error) {
        return _recordAndReturn(
          request: request,
          response: ImageProcessingBackendResponse.failure(
            kind: ImageProcessingFailureKind.invalidRequest,
            debugDetail: error.name,
          ),
          trace: trace,
          elapsed: stopwatch.elapsed,
        );
      }

      _cancelled.remove(request.requestId);
      final destinationExisted = File(request.destinationPath).existsSync();
      final accelerated = await (_nativeCapability ??= native.capability());

      if (_cancelled.contains(request.requestId)) {
        return _recordAndReturn(
          request: request,
          response: const ImageProcessingBackendResponse.failure(
            kind: ImageProcessingFailureKind.cancelled,
          ),
          trace: trace,
          elapsed: stopwatch.elapsed,
        );
      }

      ImageProcessingBackendResponse response;
      if (!accelerated.isSupported) {
        fallbackReason = ImageProcessingFailureKind.unsupported;
        response = await cpu.render(request);
      } else {
        response = await native.render(request);
        if (_cancelled.contains(request.requestId)) {
          if (!destinationExisted) _deleteIfPresent(request.destinationPath);
          response = const ImageProcessingBackendResponse.failure(
            kind: ImageProcessingFailureKind.cancelled,
          );
        } else if (response case ImageProcessingBackendFailure(
          :final kind,
        ) when kind.allowsCpuFallback) {
          fallbackReason = kind;
          if (!destinationExisted) _deleteIfPresent(request.destinationPath);
          response = await cpu.render(request);
        }
      }

      if (response case ImageProcessingBackendFailure()) {
        if (!destinationExisted) _deleteIfPresent(request.destinationPath);
      }

      return _recordAndReturn(
        request: request,
        response: response,
        trace: trace,
        elapsed: stopwatch.elapsed,
        fallbackReason: fallbackReason,
      );
    } finally {
      _cancelled.remove(request.requestId);
      await trace.stop();
    }
  }

  @override
  Future<void> cancel(String requestId) async {
    if (_isDisposed || requestId.trim().isEmpty) return;
    _cancelled.add(requestId);
    await Future.wait([native.cancel(requestId), cpu.cancel(requestId)]);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await Future.wait([native.dispose(), cpu.dispose()]);
  }

  Future<ImageProcessingBackendResponse> _recordAndReturn({
    required ImageRenderRequest request,
    required ImageProcessingBackendResponse response,
    required AppTrace trace,
    required Duration elapsed,
    ImageProcessingFailureKind? fallbackReason,
  }) async {
    final result = switch (response) {
      ImageProcessingBackendSuccess(:final result) => result,
      ImageProcessingBackendFailure() => null,
    };
    final failure = switch (response) {
      ImageProcessingBackendSuccess() => null,
      ImageProcessingBackendFailure(:final kind) => kind,
    };
    final backend = result?.backend.name ?? 'none';
    final outcome = failure?.name ?? 'success';
    final megapixelBucket = result == null
        ? 'unknown'
        : _megapixelBucket(result.sourceWidth * result.sourceHeight);

    trace
      ..putAttribute('backend', backend)
      ..putAttribute('render_kind', request.scale.name)
      ..putAttribute('megapixel_bucket', megapixelBucket)
      ..putAttribute('outcome', outcome)
      ..putAttribute('fallback_reason', fallbackReason?.name ?? 'none')
      ..setMetric('decode_us', result?.timings.decodeMicroseconds ?? 0)
      ..setMetric('transform_us', result?.timings.transformMicroseconds ?? 0)
      ..setMetric('encode_us', result?.timings.encodeMicroseconds ?? 0)
      ..setMetric(
        'total_us',
        result?.timings.totalMicroseconds ?? elapsed.inMicroseconds,
      );

    await telemetry.logEvent(
      'image_processing_completed',
      parameters: <String, Object>{
        'backend': backend,
        'render_kind': request.scale.name,
        'megapixel_bucket': megapixelBucket,
        'outcome': outcome,
        'fallback_reason': fallbackReason?.name ?? 'none',
      },
    );
    return response;
  }
}

String _megapixelBucket(int pixels) => switch (pixels) {
  < 2000000 => 'under_2mp',
  < 5000000 => '2_to_5mp',
  < 10000000 => '5_to_10mp',
  < 20000000 => '10_to_20mp',
  _ => '20mp_plus',
};

void _deleteIfPresent(String path) {
  try {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  } on FileSystemException {
    // Backends report the primary failure; derived partial cleanup is best-effort.
  }
}
