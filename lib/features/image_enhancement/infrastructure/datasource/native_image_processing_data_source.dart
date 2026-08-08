/// Typed Flutter bridge to the Android and iOS image-processing backends.
library;

import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/models/native_image_processing_dto.dart';
import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

/// Invokes native image processing through one versioned method channel.
///
/// The data source itself satisfies [ImageProcessingBackend], which keeps the
/// repository unaware of Flutter transport types. It sends paths and immutable
/// numeric settings only and never sends decoded pixels or document metadata.
class NativeImageProcessingDataSource implements ImageProcessingBackend {
  /// Creates the data source for [backend] over an injectable [channel].
  NativeImageProcessingDataSource({
    required this.backend,
    this.channel = const MethodChannel(channelName),
  });

  /// Channel name shared by the Android and iOS implementations.
  static const channelName = 'com.bruxkey.docscanly/image_processing_v1';

  /// The native backend expected on this platform.
  final ImageProcessingBackendKind backend;

  /// Injectable method transport.
  final MethodChannel channel;

  bool _isDisposed = false;

  @override
  Future<ImageProcessingCapability> capability() async {
    if (_isDisposed) return _unsupportedCapability();
    try {
      final values = await channel.invokeMapMethod<String, Object?>(
        'capability',
        const {'schemaVersion': nativeImageProcessingSchemaVersion},
      );
      if (values == null) return _unsupportedCapability();
      final capability = NativeImageProcessingCapabilityDto.fromJson(
        _stringKeyedMap(values),
      ).toDomain();
      if (capability.backend != backend) return _unsupportedCapability();
      return capability;
    } on Object {
      // Capability probing is allowed to fail closed. The native-first
      // repository will select CPU without first attempting a broken backend.
      return _unsupportedCapability();
    }
  }

  @override
  Future<ImageProcessingBackendResponse> render(
    ImageRenderRequest request,
  ) async {
    if (_isDisposed) {
      return const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.unsupported,
        debugDetail: 'native backend is disposed',
      );
    }

    try {
      final dto = NativeImageRenderRequestDto.fromDomain(request);
      final values = await channel.invokeMapMethod<String, Object?>(
        'render',
        dto.toJson(),
      );
      if (values == null) {
        return const ImageProcessingBackendResponse.failure(
          kind: ImageProcessingFailureKind.unexpected,
          debugDetail: 'native render returned no response',
        );
      }
      return NativeImageProcessingResponseDto.fromJson(
        _stringKeyedMap(values),
      ).toDomain();
    } on PlatformException catch (error) {
      return ImageProcessingBackendResponse.failure(
        kind: _failureKindForCode(error.code),
        // Codes are finite and path-free; native messages/details are omitted
        // because platform exceptions can contain local file paths.
        debugDetail: 'platform code=${error.code}',
      );
    } on MissingPluginException {
      return const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.unsupported,
        debugDetail: 'native image-processing plugin is unavailable',
      );
    } on FormatException catch (error) {
      return ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.invalidRequest,
        debugDetail: '$error',
      );
    } on CheckedFromJsonException catch (error) {
      return ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.invalidRequest,
        debugDetail: '${error.className}.${error.key}',
      );
    } on ArgumentError catch (error) {
      return ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.invalidRequest,
        debugDetail: error.name,
      );
    } on Object {
      return const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.unexpected,
        debugDetail: 'unclassified channel failure',
      );
    }
  }

  @override
  Future<void> cancel(String requestId) async {
    if (_isDisposed || requestId.trim().isEmpty) return;
    try {
      await channel.invokeMethod<void>('cancel', {
        'schemaVersion': nativeImageProcessingSchemaVersion,
        'requestId': requestId,
      });
    } on Object {
      // Cancellation is best-effort. Latest-request guards still suppress a
      // result when a platform codec cannot be interrupted.
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      await channel.invokeMethod<void>('dispose', const {
        'schemaVersion': nativeImageProcessingSchemaVersion,
      });
    } on Object {
      // Engine detachment can remove the plugin before Dart disposes it; native
      // lifecycle ownership still releases the same resources.
    }
  }

  ImageProcessingCapability _unsupportedCapability() =>
      ImageProcessingCapability(
        backend: backend,
        isSupported: false,
        maximumTextureSize: 0,
        supportsTiling: false,
      );
}

ImageProcessingFailureKind _failureKindForCode(String code) => switch (code) {
  'unsupported' => ImageProcessingFailureKind.unsupported,
  'initialization' => ImageProcessingFailureKind.initialization,
  'context_lost' => ImageProcessingFailureKind.contextLost,
  'allocation' => ImageProcessingFailureKind.allocation,
  'shader' => ImageProcessingFailureKind.shader,
  'codec' => ImageProcessingFailureKind.codec,
  'corrupt_input' => ImageProcessingFailureKind.corruptInput,
  'invalid_request' => ImageProcessingFailureKind.invalidRequest,
  'invalid_path' => ImageProcessingFailureKind.invalidPath,
  'storage_full' => ImageProcessingFailureKind.storageFull,
  'storage' => ImageProcessingFailureKind.storage,
  'cancelled' => ImageProcessingFailureKind.cancelled,
  _ => ImageProcessingFailureKind.unexpected,
};

Map<String, dynamic> _stringKeyedMap(Map<Object?, Object?> values) =>
    values.map((key, value) => MapEntry('$key', _normaliseValue(value)));

Object? _normaliseValue(Object? value) => switch (value) {
  Map<Object?, Object?>() => _stringKeyedMap(value),
  List<Object?>() => value.map(_normaliseValue).toList(growable: false),
  _ => value,
};
