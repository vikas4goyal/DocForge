// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'native_image_processing_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NativeHomographyDto _$NativeHomographyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NativeHomographyDto', json, ($checkedConvert) {
      final val = _NativeHomographyDto(
        h00: $checkedConvert('h00', (v) => (v as num).toDouble()),
        h01: $checkedConvert('h01', (v) => (v as num).toDouble()),
        h02: $checkedConvert('h02', (v) => (v as num).toDouble()),
        h10: $checkedConvert('h10', (v) => (v as num).toDouble()),
        h11: $checkedConvert('h11', (v) => (v as num).toDouble()),
        h12: $checkedConvert('h12', (v) => (v as num).toDouble()),
        h20: $checkedConvert('h20', (v) => (v as num).toDouble()),
        h21: $checkedConvert('h21', (v) => (v as num).toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$NativeHomographyDtoToJson(
  _NativeHomographyDto instance,
) => <String, dynamic>{
  'h00': instance.h00,
  'h01': instance.h01,
  'h02': instance.h02,
  'h10': instance.h10,
  'h11': instance.h11,
  'h12': instance.h12,
  'h20': instance.h20,
  'h21': instance.h21,
};

_NativeEnhancementSettingsDto _$NativeEnhancementSettingsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_NativeEnhancementSettingsDto', json, ($checkedConvert) {
  final val = _NativeEnhancementSettingsDto(
    filter: $checkedConvert(
      'filter',
      (v) => $enumDecode(_$EnhancementFilterEnumMap, v),
    ),
    brightness: $checkedConvert('brightness', (v) => (v as num).toDouble()),
    contrast: $checkedConvert('contrast', (v) => (v as num).toDouble()),
    sharpen: $checkedConvert('sharpen', (v) => (v as num).toDouble()),
    shadowRemoval: $checkedConvert('shadowRemoval', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$NativeEnhancementSettingsDtoToJson(
  _NativeEnhancementSettingsDto instance,
) => <String, dynamic>{
  'filter': _$EnhancementFilterEnumMap[instance.filter]!,
  'brightness': instance.brightness,
  'contrast': instance.contrast,
  'sharpen': instance.sharpen,
  'shadowRemoval': instance.shadowRemoval,
};

const _$EnhancementFilterEnumMap = {
  EnhancementFilter.original: 'original',
  EnhancementFilter.autoEnhance: 'autoEnhance',
  EnhancementFilter.magicColour: 'magicColour',
  EnhancementFilter.blackAndWhite: 'blackAndWhite',
  EnhancementFilter.grayscale: 'grayscale',
};

_NativeImageRenderRequestDto _$NativeImageRenderRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_NativeImageRenderRequestDto', json, ($checkedConvert) {
  final val = _NativeImageRenderRequestDto(
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
    requestId: $checkedConvert('requestId', (v) => v as String),
    sourcePath: $checkedConvert('sourcePath', (v) => v as String),
    destinationPath: $checkedConvert('destinationPath', (v) => v as String),
    scale: $checkedConvert(
      'scale',
      (v) => $enumDecode(_$ImageRenderScaleEnumMap, v),
    ),
    enhancement: $checkedConvert(
      'enhancement',
      (v) => NativeEnhancementSettingsDto.fromJson(v as Map<String, dynamic>),
    ),
    jpegQuality: $checkedConvert('jpegQuality', (v) => (v as num).toInt()),
    colourPipelineVersion: $checkedConvert(
      'colourPipelineVersion',
      (v) => (v as num).toInt(),
    ),
    transform: $checkedConvert(
      'transform',
      (v) => v == null
          ? null
          : NativeHomographyDto.fromJson(v as Map<String, dynamic>),
    ),
    outputWidth: $checkedConvert('outputWidth', (v) => (v as num?)?.toInt()),
    outputHeight: $checkedConvert('outputHeight', (v) => (v as num?)?.toInt()),
    maximumPreviewDimension: $checkedConvert(
      'maximumPreviewDimension',
      (v) => (v as num?)?.toInt(),
    ),
  );
  return val;
});

Map<String, dynamic> _$NativeImageRenderRequestDtoToJson(
  _NativeImageRenderRequestDto instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'requestId': instance.requestId,
  'sourcePath': instance.sourcePath,
  'destinationPath': instance.destinationPath,
  'scale': _$ImageRenderScaleEnumMap[instance.scale]!,
  'enhancement': instance.enhancement.toJson(),
  'jpegQuality': instance.jpegQuality,
  'colourPipelineVersion': instance.colourPipelineVersion,
  'transform': instance.transform?.toJson(),
  'outputWidth': instance.outputWidth,
  'outputHeight': instance.outputHeight,
  'maximumPreviewDimension': instance.maximumPreviewDimension,
};

const _$ImageRenderScaleEnumMap = {
  ImageRenderScale.preview: 'preview',
  ImageRenderScale.fullResolution: 'full_resolution',
};

_NativeImageProcessingCapabilityDto
_$NativeImageProcessingCapabilityDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NativeImageProcessingCapabilityDto', json, (
      $checkedConvert,
    ) {
      final val = _NativeImageProcessingCapabilityDto(
        schemaVersion: $checkedConvert(
          'schemaVersion',
          (v) => (v as num).toInt(),
        ),
        backend: $checkedConvert(
          'backend',
          (v) => $enumDecode(_$ImageProcessingBackendKindEnumMap, v),
        ),
        isSupported: $checkedConvert('isSupported', (v) => v as bool),
        maximumTextureSize: $checkedConvert(
          'maximumTextureSize',
          (v) => (v as num).toInt(),
        ),
        supportsTiling: $checkedConvert('supportsTiling', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$NativeImageProcessingCapabilityDtoToJson(
  _NativeImageProcessingCapabilityDto instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'backend': _$ImageProcessingBackendKindEnumMap[instance.backend]!,
  'isSupported': instance.isSupported,
  'maximumTextureSize': instance.maximumTextureSize,
  'supportsTiling': instance.supportsTiling,
};

const _$ImageProcessingBackendKindEnumMap = {
  ImageProcessingBackendKind.iosCoreImage: 'ios_core_image',
  ImageProcessingBackendKind.androidOpenGl: 'android_open_gl',
  ImageProcessingBackendKind.cpuFallback: 'cpu_fallback',
};

_NativeImageProcessingTimingsDto _$NativeImageProcessingTimingsDtoFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('_NativeImageProcessingTimingsDto', json, ($checkedConvert) {
      final val = _NativeImageProcessingTimingsDto(
        decodeMicroseconds: $checkedConvert(
          'decodeMicroseconds',
          (v) => (v as num).toInt(),
        ),
        transformMicroseconds: $checkedConvert(
          'transformMicroseconds',
          (v) => (v as num).toInt(),
        ),
        encodeMicroseconds: $checkedConvert(
          'encodeMicroseconds',
          (v) => (v as num).toInt(),
        ),
        totalMicroseconds: $checkedConvert(
          'totalMicroseconds',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$NativeImageProcessingTimingsDtoToJson(
  _NativeImageProcessingTimingsDto instance,
) => <String, dynamic>{
  'decodeMicroseconds': instance.decodeMicroseconds,
  'transformMicroseconds': instance.transformMicroseconds,
  'encodeMicroseconds': instance.encodeMicroseconds,
  'totalMicroseconds': instance.totalMicroseconds,
};

_NativeImageProcessingResultDto _$NativeImageProcessingResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_NativeImageProcessingResultDto', json, ($checkedConvert) {
  final val = _NativeImageProcessingResultDto(
    destinationPath: $checkedConvert('destinationPath', (v) => v as String),
    sourceWidth: $checkedConvert('sourceWidth', (v) => (v as num).toInt()),
    sourceHeight: $checkedConvert('sourceHeight', (v) => (v as num).toInt()),
    outputWidth: $checkedConvert('outputWidth', (v) => (v as num).toInt()),
    outputHeight: $checkedConvert('outputHeight', (v) => (v as num).toInt()),
    backend: $checkedConvert(
      'backend',
      (v) => $enumDecode(_$ImageProcessingBackendKindEnumMap, v),
    ),
    timings: $checkedConvert(
      'timings',
      (v) =>
          NativeImageProcessingTimingsDto.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$NativeImageProcessingResultDtoToJson(
  _NativeImageProcessingResultDto instance,
) => <String, dynamic>{
  'destinationPath': instance.destinationPath,
  'sourceWidth': instance.sourceWidth,
  'sourceHeight': instance.sourceHeight,
  'outputWidth': instance.outputWidth,
  'outputHeight': instance.outputHeight,
  'backend': _$ImageProcessingBackendKindEnumMap[instance.backend]!,
  'timings': instance.timings.toJson(),
};

_NativeImageProcessingResponseDto _$NativeImageProcessingResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_NativeImageProcessingResponseDto', json, (
  $checkedConvert,
) {
  final val = _NativeImageProcessingResponseDto(
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
    result: $checkedConvert(
      'result',
      (v) => v == null
          ? null
          : NativeImageProcessingResultDto.fromJson(v as Map<String, dynamic>),
    ),
    failureKind: $checkedConvert(
      'failureKind',
      (v) => $enumDecodeNullable(_$ImageProcessingFailureKindEnumMap, v),
    ),
    debugDetail: $checkedConvert('debugDetail', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$NativeImageProcessingResponseDtoToJson(
  _NativeImageProcessingResponseDto instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'result': instance.result?.toJson(),
  'failureKind': _$ImageProcessingFailureKindEnumMap[instance.failureKind],
  'debugDetail': instance.debugDetail,
};

const _$ImageProcessingFailureKindEnumMap = {
  ImageProcessingFailureKind.unsupported: 'unsupported',
  ImageProcessingFailureKind.initialization: 'initialization',
  ImageProcessingFailureKind.contextLost: 'context_lost',
  ImageProcessingFailureKind.allocation: 'allocation',
  ImageProcessingFailureKind.shader: 'shader',
  ImageProcessingFailureKind.codec: 'codec',
  ImageProcessingFailureKind.corruptInput: 'corrupt_input',
  ImageProcessingFailureKind.invalidRequest: 'invalid_request',
  ImageProcessingFailureKind.invalidPath: 'invalid_path',
  ImageProcessingFailureKind.storageFull: 'storage_full',
  ImageProcessingFailureKind.storage: 'storage',
  ImageProcessingFailureKind.cancelled: 'cancelled',
  ImageProcessingFailureKind.unexpected: 'unexpected',
};
