import 'dart:convert';

import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/models/native_image_processing_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  ImageRenderRequest requestFor(EnhancementFilter filter) => ImageRenderRequest(
    requestId: 'request-${filter.name}',
    sourcePath: '/app/source.jpg',
    destinationPath: '/app/${filter.name}.jpg',
    scale: ImageRenderScale.preview,
    enhancement: EnhancementSettings(
      filter: filter,
      brightness: 0.2,
      contrast: -0.1,
      sharpen: 0.4,
      shadowRemoval: true,
    ),
    jpegQuality: 82,
    transform: const Homography(
      h00: 1,
      h01: 0.1,
      h02: 2,
      h10: 0.2,
      h11: 1,
      h12: 3,
      h20: 0.001,
      h21: 0.002,
    ),
    outputWidth: 1200,
    outputHeight: 1600,
    maximumPreviewDimension: 1400,
  );

  group('NativeImageRenderRequestDto', () {
    for (final filter in EnhancementFilter.values) {
      test('round-trips ${filter.name} with geometry and adjustments', () {
        final domain = requestFor(filter);
        final dto = NativeImageRenderRequestDto.fromDomain(domain);
        final json =
            jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>;
        final decoded = NativeImageRenderRequestDto.fromJson(json);

        expect(decoded.toDomain(), domain);
        expect(json['schemaVersion'], nativeImageProcessingSchemaVersion);
        expect(json, isNot(contains('pixels')));
        expect(json, isNot(contains('documentId')));
      });
    }

    test('round-trips full resolution without optional geometry', () {
      const domain = ImageRenderRequest(
        requestId: 'full-1',
        sourcePath: '/app/source.jpg',
        destinationPath: '/app/output.jpg',
        scale: ImageRenderScale.fullResolution,
        enhancement: EnhancementSettings(),
        jpegQuality: 92,
      );

      final decoded = NativeImageRenderRequestDto.fromJson(
        jsonDecode(
              jsonEncode(
                NativeImageRenderRequestDto.fromDomain(domain).toJson(),
              ),
            )
            as Map<String, dynamic>,
      );

      expect(decoded.toDomain(), domain);
      expect(decoded.transform, isNull);
      expect(decoded.maximumPreviewDimension, isNull);
    });

    test('rejects unknown schema and colour-pipeline versions', () {
      final dto = NativeImageRenderRequestDto.fromDomain(
        requestFor(EnhancementFilter.original),
      );

      expect(
        () => dto.copyWith(schemaVersion: 99).toDomain(),
        throwsFormatException,
      );
      expect(
        () => dto.copyWith(colourPipelineVersion: 99).toDomain(),
        throwsFormatException,
      );
    });

    test('rejects an unknown generated enum value', () {
      final json = NativeImageRenderRequestDto.fromDomain(
        requestFor(EnhancementFilter.original),
      ).toJson();
      json['scale'] = 'poster';

      expect(
        () => NativeImageRenderRequestDto.fromJson(json),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('rejects malformed request values after deserialization', () {
      final dto = NativeImageRenderRequestDto.fromDomain(
        requestFor(EnhancementFilter.original),
      );

      expect(
        () => dto.copyWith(outputWidth: 0).toDomain(),
        throwsArgumentError,
      );
    });
  });

  test('capability round-trips backend identity and limits', () {
    const dto = NativeImageProcessingCapabilityDto(
      schemaVersion: nativeImageProcessingSchemaVersion,
      backend: ImageProcessingBackendKind.androidOpenGl,
      isSupported: true,
      maximumTextureSize: 8192,
      supportsTiling: true,
    );
    final decoded = NativeImageProcessingCapabilityDto.fromJson(
      jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>,
    );

    expect(
      decoded.toDomain(),
      const ImageProcessingCapability(
        backend: ImageProcessingBackendKind.androidOpenGl,
        isSupported: true,
        maximumTextureSize: 8192,
        supportsTiling: true,
      ),
    );
    expect(
      () => decoded.copyWith(schemaVersion: 0).toDomain(),
      throwsFormatException,
    );
  });

  test('success response round-trips timings and output', () {
    const dto = NativeImageProcessingResponseDto(
      schemaVersion: nativeImageProcessingSchemaVersion,
      result: NativeImageProcessingResultDto(
        destinationPath: '/app/output.jpg',
        sourceWidth: 4000,
        sourceHeight: 3000,
        outputWidth: 1200,
        outputHeight: 1600,
        backend: ImageProcessingBackendKind.iosCoreImage,
        timings: NativeImageProcessingTimingsDto(
          decodeMicroseconds: 10,
          transformMicroseconds: 20,
          encodeMicroseconds: 30,
          totalMicroseconds: 60,
        ),
      ),
    );
    final decoded = NativeImageProcessingResponseDto.fromJson(
      jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>,
    );

    final response = decoded.toDomain();
    expect(response, isA<ImageProcessingBackendSuccess>());
    expect(
      (response as ImageProcessingBackendSuccess)
          .result
          .timings
          .totalMicroseconds,
      60,
    );
  });

  test('failure response round-trips kind and diagnostic detail', () {
    const dto = NativeImageProcessingResponseDto(
      schemaVersion: nativeImageProcessingSchemaVersion,
      failureKind: ImageProcessingFailureKind.contextLost,
      debugDetail: 'context unavailable',
    );
    final decoded = NativeImageProcessingResponseDto.fromJson(
      jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>,
    );

    expect(
      decoded.toDomain(),
      const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.contextLost,
        debugDetail: 'context unavailable',
      ),
    );
  });

  test('rejects response envelopes with both or neither outcome', () {
    const result = NativeImageProcessingResultDto(
      destinationPath: '/app/output.jpg',
      sourceWidth: 1,
      sourceHeight: 1,
      outputWidth: 1,
      outputHeight: 1,
      backend: ImageProcessingBackendKind.cpuFallback,
      timings: NativeImageProcessingTimingsDto(
        totalMicroseconds: 1,
        decodeMicroseconds: 0,
        transformMicroseconds: 1,
        encodeMicroseconds: 0,
      ),
    );

    expect(
      () => const NativeImageProcessingResponseDto(
        schemaVersion: nativeImageProcessingSchemaVersion,
      ).toDomain(),
      throwsFormatException,
    );
    expect(
      () => const NativeImageProcessingResponseDto(
        schemaVersion: nativeImageProcessingSchemaVersion,
        result: result,
        failureKind: ImageProcessingFailureKind.shader,
      ).toDomain(),
      throwsFormatException,
    );
  });
}
