/// Contracts for file-to-file image processing backends.
///
/// These types live in `core` so scanning, enhancement, and document creation
/// can share one renderer without importing one another. They contain paths and
/// small immutable values only; decoded pixel buffers never cross this API.
library;

import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_processing.freezed.dart';

/// Identifies the implementation that performed image processing.
@JsonEnum(fieldRename: FieldRename.snake)
enum ImageProcessingBackendKind {
  /// Apple's Core Image pipeline backed by Metal.
  iosCoreImage,

  /// Android's offscreen OpenGL ES pipeline.
  androidOpenGl,

  /// The Dart image pipeline running in a background isolate.
  cpuFallback,
}

/// Identifies whether a render is interactive or full resolution.
@JsonEnum(fieldRename: FieldRename.snake)
enum ImageRenderScale {
  /// A bounded render used while editing.
  preview,

  /// A render at the page's required output resolution.
  fullResolution,
}

/// Classifies backend failures without leaking platform exception types.
@JsonEnum(fieldRename: FieldRename.snake)
enum ImageProcessingFailureKind {
  /// The device does not expose the required accelerated API or limits.
  unsupported,

  /// The native backend could not initialize its GPU context.
  initialization,

  /// An initialized GPU context became invalid.
  contextLost,

  /// A required texture, framebuffer, or bitmap could not be allocated.
  allocation,

  /// A shader failed to compile, link, or execute.
  shader,

  /// Native image decoding or encoding failed for a recoverable reason.
  codec,

  /// The source bytes do not describe a readable supported image.
  corruptInput,

  /// The request has invalid dimensions, settings, geometry, or schema.
  invalidRequest,

  /// A source or destination path is outside the application-owned roots.
  invalidPath,

  /// The destination volume has no space for the output.
  storageFull,

  /// File input, output, or atomic publication failed.
  storage,

  /// The caller superseded or explicitly cancelled the request.
  cancelled,

  /// Processing failed for an unclassified reason.
  unexpected,
}

/// Recovery policy for [ImageProcessingFailureKind].
extension ImageProcessingFailurePolicy on ImageProcessingFailureKind {
  /// Whether a native failure can be retried once through the CPU backend.
  bool get allowsCpuFallback => switch (this) {
    ImageProcessingFailureKind.unsupported ||
    ImageProcessingFailureKind.initialization ||
    ImageProcessingFailureKind.contextLost ||
    ImageProcessingFailureKind.allocation ||
    ImageProcessingFailureKind.shader ||
    ImageProcessingFailureKind.codec => true,
    ImageProcessingFailureKind.corruptInput ||
    ImageProcessingFailureKind.invalidRequest ||
    ImageProcessingFailureKind.invalidPath ||
    ImageProcessingFailureKind.storageFull ||
    ImageProcessingFailureKind.storage ||
    ImageProcessingFailureKind.cancelled ||
    ImageProcessingFailureKind.unexpected => false,
  };
}

/// Describes whether and within which limits a backend can render.
@freezed
abstract class ImageProcessingCapability with _$ImageProcessingCapability {
  /// Creates a backend capability response.
  const factory ImageProcessingCapability({
    required ImageProcessingBackendKind backend,
    required bool isSupported,
    required int maximumTextureSize,
    required bool supportsTiling,
  }) = _ImageProcessingCapability;

  const ImageProcessingCapability._();

  /// Validates the capability reported by a backend.
  ///
  /// Returns normally when values are coherent and throws [ArgumentError]
  /// when the texture size is negative or a supported backend reports zero.
  void validate() {
    if (maximumTextureSize < 0) {
      throw ArgumentError.value(
        maximumTextureSize,
        'maximumTextureSize',
        'must not be negative',
      );
    }
    if (isSupported && maximumTextureSize == 0) {
      throw ArgumentError.value(
        maximumTextureSize,
        'maximumTextureSize',
        'must be positive for a supported backend',
      );
    }
  }
}

/// Timing information produced by one file-to-file render.
@freezed
abstract class ImageProcessingTimings with _$ImageProcessingTimings {
  /// Creates stage timings measured in microseconds.
  const factory ImageProcessingTimings({
    @Default(0) int decodeMicroseconds,
    @Default(0) int transformMicroseconds,
    @Default(0) int encodeMicroseconds,
    required int totalMicroseconds,
  }) = _ImageProcessingTimings;

  const ImageProcessingTimings._();

  /// Validates every duration.
  ///
  /// Returns normally for non-negative values and throws [ArgumentError] when
  /// any stage or total duration is negative.
  void validate() {
    final values = <String, int>{
      'decodeMicroseconds': decodeMicroseconds,
      'transformMicroseconds': transformMicroseconds,
      'encodeMicroseconds': encodeMicroseconds,
      'totalMicroseconds': totalMicroseconds,
    };
    for (final MapEntry(:key, :value) in values.entries) {
      if (value < 0) {
        throw ArgumentError.value(value, key, 'must not be negative');
      }
    }
  }
}

/// Describes one immutable file-to-file page render.
@freezed
abstract class ImageRenderRequest with _$ImageRenderRequest {
  /// Creates a render request.
  const factory ImageRenderRequest({
    required String requestId,
    required String sourcePath,
    required String destinationPath,
    required ImageRenderScale scale,
    required EnhancementSettings enhancement,
    required int jpegQuality,
    @Default(1) int colourPipelineVersion,
    Homography? transform,
    int? outputWidth,
    int? outputHeight,
    int? maximumPreviewDimension,
  }) = _ImageRenderRequest;

  const ImageRenderRequest._();

  /// Validates paths, dimensions, geometry, quality, and enhancement ranges.
  ///
  /// Returns normally when the request is safe to submit. Throws
  /// [ArgumentError] for malformed values; it does not access the filesystem
  /// or decide whether a path belongs to the application.
  void validate() {
    if (requestId.trim().isEmpty) {
      throw ArgumentError.value(requestId, 'requestId', 'must not be empty');
    }
    if (sourcePath.trim().isEmpty) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'must not be empty');
    }
    if (destinationPath.trim().isEmpty) {
      throw ArgumentError.value(
        destinationPath,
        'destinationPath',
        'must not be empty',
      );
    }
    if (sourcePath == destinationPath) {
      throw ArgumentError.value(
        destinationPath,
        'destinationPath',
        'must differ from sourcePath',
      );
    }
    if (jpegQuality < 1 || jpegQuality > 100) {
      throw ArgumentError.value(
        jpegQuality,
        'jpegQuality',
        'must be in the range 1..100',
      );
    }
    if (colourPipelineVersion <= 0) {
      throw ArgumentError.value(
        colourPipelineVersion,
        'colourPipelineVersion',
        'must be positive',
      );
    }
    if (maximumPreviewDimension case final dimension?) {
      if (dimension <= 0) {
        throw ArgumentError.value(
          dimension,
          'maximumPreviewDimension',
          'must be positive',
        );
      }
      if (scale != ImageRenderScale.preview) {
        throw ArgumentError(
          'maximumPreviewDimension is valid only for preview renders',
        );
      }
    }

    final hasAnyOutputDimension = outputWidth != null || outputHeight != null;
    final hasEveryOutputDimension = outputWidth != null && outputHeight != null;
    if (hasAnyOutputDimension != hasEveryOutputDimension) {
      throw ArgumentError(
        'outputWidth and outputHeight must be supplied together',
      );
    }
    if (hasEveryOutputDimension && (outputWidth! <= 0 || outputHeight! <= 0)) {
      throw ArgumentError('output dimensions must be positive');
    }
    if ((transform == null) != !hasEveryOutputDimension) {
      throw ArgumentError(
        'transform and output dimensions must either all be present or all be absent',
      );
    }
    if (transform case final value? when !value.isValid) {
      throw ArgumentError.value(value, 'transform', 'must be finite');
    }
    if (enhancement.brightness < -1 || enhancement.brightness > 1) {
      throw ArgumentError.value(
        enhancement.brightness,
        'enhancement.brightness',
        'must be in the range -1..1',
      );
    }
    if (enhancement.contrast < -1 || enhancement.contrast > 1) {
      throw ArgumentError.value(
        enhancement.contrast,
        'enhancement.contrast',
        'must be in the range -1..1',
      );
    }
    if (enhancement.sharpen < 0 || enhancement.sharpen > 1) {
      throw ArgumentError.value(
        enhancement.sharpen,
        'enhancement.sharpen',
        'must be in the range 0..1',
      );
    }
  }
}

/// Describes a successfully published image-processing output.
@freezed
abstract class ImageProcessingResult with _$ImageProcessingResult {
  /// Creates a successful result.
  const factory ImageProcessingResult({
    required String destinationPath,
    required int sourceWidth,
    required int sourceHeight,
    required int outputWidth,
    required int outputHeight,
    required ImageProcessingBackendKind backend,
    required ImageProcessingTimings timings,
  }) = _ImageProcessingResult;

  const ImageProcessingResult._();

  /// Validates dimensions, path, and timing values.
  ///
  /// Returns normally for a coherent result and throws [ArgumentError] when
  /// the destination is empty or either dimension is not positive.
  void validate() {
    if (destinationPath.trim().isEmpty) {
      throw ArgumentError.value(
        destinationPath,
        'destinationPath',
        'must not be empty',
      );
    }
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      throw ArgumentError('source dimensions must be positive');
    }
    if (outputWidth <= 0 || outputHeight <= 0) {
      throw ArgumentError('output dimensions must be positive');
    }
    timings.validate();
  }
}

/// The typed outcome returned by an [ImageProcessingBackend].
@freezed
sealed class ImageProcessingBackendResponse
    with _$ImageProcessingBackendResponse {
  /// Creates a successful backend response.
  const factory ImageProcessingBackendResponse.success(
    ImageProcessingResult result,
  ) = ImageProcessingBackendSuccess;

  /// Creates a failed backend response.
  const factory ImageProcessingBackendResponse.failure({
    required ImageProcessingFailureKind kind,
    String? debugDetail,
  }) = ImageProcessingBackendFailure;
}

/// Processes immutable page-render requests without exposing pixel buffers.
abstract interface class ImageProcessingBackend {
  /// Reports whether this backend can process requests in the current runtime.
  ///
  /// Returns its capability and can throw only for a programming error in the
  /// implementation; operational unavailability is represented by
  /// `isSupported: false`.
  Future<ImageProcessingCapability> capability();

  /// Renders [request] to its destination.
  ///
  /// Returns a typed [ImageProcessingBackendResponse]. Implementations operate
  /// fully offline and must publish output atomically. Operational failures do
  /// not escape as exceptions.
  Future<ImageProcessingBackendResponse> render(ImageRenderRequest request);

  /// Requests cancellation of [requestId] at the next safe stage boundary.
  ///
  /// Returns after the cancellation signal is recorded. Unknown or already
  /// completed identifiers are ignored and no exception is produced.
  Future<void> cancel(String requestId);

  /// Releases backend resources after in-flight work has settled.
  ///
  /// Returns when resources are released. Repeated calls are safe and do not
  /// throw for an already disposed backend.
  Future<void> dispose();
}
