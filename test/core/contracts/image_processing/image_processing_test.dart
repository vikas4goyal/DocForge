import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ImageRenderRequest request({
    String requestId = 'preview-1',
    String sourcePath = '/app/source.jpg',
    String destinationPath = '/app/output.jpg',
    ImageRenderScale scale = ImageRenderScale.preview,
    EnhancementSettings enhancement = const EnhancementSettings(),
    int jpegQuality = 82,
    int colourPipelineVersion = 1,
    Homography? transform,
    int? outputWidth,
    int? outputHeight,
    int? maximumPreviewDimension = 1400,
  }) => ImageRenderRequest(
    requestId: requestId,
    sourcePath: sourcePath,
    destinationPath: destinationPath,
    scale: scale,
    enhancement: enhancement,
    jpegQuality: jpegQuality,
    colourPipelineVersion: colourPipelineVersion,
    transform: transform,
    outputWidth: outputWidth,
    outputHeight: outputHeight,
    maximumPreviewDimension: maximumPreviewDimension,
  );

  group('ImageRenderRequest', () {
    test('has value equality and preserves backend-independent values', () {
      final first = request();
      final second = request();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.scale, ImageRenderScale.preview);
      expect(first.maximumPreviewDimension, 1400);
      expect(first.validate, returnsNormally);
    });

    test('accepts finite geometry with paired positive dimensions', () {
      final value = request(
        transform: Homography.identity,
        outputWidth: 1200,
        outputHeight: 1600,
      );

      expect(value.validate, returnsNormally);
    });

    test('rejects empty identifiers and paths', () {
      expect(() => request(requestId: '').validate(), throwsArgumentError);
      expect(() => request(sourcePath: '').validate(), throwsArgumentError);
      expect(
        () => request(destinationPath: '').validate(),
        throwsArgumentError,
      );
      expect(
        () => request(destinationPath: '/app/source.jpg').validate(),
        throwsArgumentError,
      );
    });

    test('rejects quality and preview-bound violations', () {
      expect(() => request(jpegQuality: 0).validate(), throwsArgumentError);
      expect(() => request(jpegQuality: 101).validate(), throwsArgumentError);
      expect(
        () => request(maximumPreviewDimension: 0).validate(),
        throwsArgumentError,
      );
      expect(
        () => request(scale: ImageRenderScale.fullResolution).validate(),
        throwsArgumentError,
      );
    });

    test('rejects partial, non-positive, and transformless output sizes', () {
      expect(() => request(outputWidth: 10).validate(), throwsArgumentError);
      expect(
        () => request(outputWidth: 0, outputHeight: 10).validate(),
        throwsArgumentError,
      );
      expect(
        () => request(outputWidth: 10, outputHeight: 10).validate(),
        throwsArgumentError,
      );
      expect(
        () => request(transform: Homography.identity).validate(),
        throwsArgumentError,
      );
    });

    test('rejects non-finite geometry', () {
      const invalid = Homography(
        h00: double.nan,
        h01: 0,
        h02: 0,
        h10: 0,
        h11: 1,
        h12: 0,
        h20: 0,
        h21: 0,
      );

      expect(
        () => request(
          transform: invalid,
          outputWidth: 10,
          outputHeight: 10,
        ).validate(),
        throwsArgumentError,
      );
    });

    test('rejects enhancement values outside domain ranges', () {
      expect(
        () => request(
          enhancement: const EnhancementSettings(brightness: 1.1),
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => request(
          enhancement: const EnhancementSettings(contrast: -1.1),
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => request(
          enhancement: const EnhancementSettings(sharpen: -0.1),
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('capability and backend identity', () {
    test('validates supported and unsupported texture limits', () {
      const supported = ImageProcessingCapability(
        backend: ImageProcessingBackendKind.androidOpenGl,
        isSupported: true,
        maximumTextureSize: 8192,
        supportsTiling: true,
      );
      const unsupported = ImageProcessingCapability(
        backend: ImageProcessingBackendKind.iosCoreImage,
        isSupported: false,
        maximumTextureSize: 0,
        supportsTiling: false,
      );

      expect(() => supported.validate(), returnsNormally);
      expect(() => unsupported.validate(), returnsNormally);
      expect(supported.backend, ImageProcessingBackendKind.androidOpenGl);
      expect(supported, supported.copyWith());
    });

    test('rejects incoherent texture limits', () {
      expect(
        () => const ImageProcessingCapability(
          backend: ImageProcessingBackendKind.iosCoreImage,
          isSupported: true,
          maximumTextureSize: 0,
          supportsTiling: true,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const ImageProcessingCapability(
          backend: ImageProcessingBackendKind.cpuFallback,
          isSupported: false,
          maximumTextureSize: -1,
          supportsTiling: false,
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('failure and cancellation policy', () {
    test('allows fallback only for recoverable native failures', () {
      expect(ImageProcessingFailureKind.unsupported.allowsCpuFallback, isTrue);
      expect(
        ImageProcessingFailureKind.initialization.allowsCpuFallback,
        isTrue,
      );
      expect(ImageProcessingFailureKind.contextLost.allowsCpuFallback, isTrue);
      expect(ImageProcessingFailureKind.allocation.allowsCpuFallback, isTrue);
      expect(ImageProcessingFailureKind.shader.allowsCpuFallback, isTrue);
      expect(ImageProcessingFailureKind.codec.allowsCpuFallback, isTrue);

      expect(
        ImageProcessingFailureKind.corruptInput.allowsCpuFallback,
        isFalse,
      );
      expect(
        ImageProcessingFailureKind.invalidRequest.allowsCpuFallback,
        isFalse,
      );
      expect(ImageProcessingFailureKind.invalidPath.allowsCpuFallback, isFalse);
      expect(ImageProcessingFailureKind.storageFull.allowsCpuFallback, isFalse);
      expect(ImageProcessingFailureKind.storage.allowsCpuFallback, isFalse);
      expect(ImageProcessingFailureKind.cancelled.allowsCpuFallback, isFalse);
      expect(ImageProcessingFailureKind.unexpected.allowsCpuFallback, isFalse);
    });

    test('models cancellation as a typed backend response', () {
      const response = ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.cancelled,
      );

      expect(response, isA<ImageProcessingBackendFailure>());
      expect(
        (response as ImageProcessingBackendFailure).kind,
        ImageProcessingFailureKind.cancelled,
      );
    });
  });

  test('result and timings validate and compare by value', () {
    const timings = ImageProcessingTimings(
      decodeMicroseconds: 10,
      transformMicroseconds: 20,
      encodeMicroseconds: 30,
      totalMicroseconds: 60,
    );
    const result = ImageProcessingResult(
      destinationPath: '/app/output.jpg',
      sourceWidth: 4000,
      sourceHeight: 3000,
      outputWidth: 1200,
      outputHeight: 1600,
      backend: ImageProcessingBackendKind.cpuFallback,
      timings: timings,
    );

    expect(() => result.validate(), returnsNormally);
    expect(result, result.copyWith());
    expect(
      () => timings.copyWith(totalMicroseconds: -1).validate(),
      throwsArgumentError,
    );
    expect(
      () => result.copyWith(outputWidth: 0).validate(),
      throwsArgumentError,
    );
  });
}
