// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NormalisedPoint _$NormalisedPointFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NormalisedPoint', json, ($checkedConvert) {
      final val = _NormalisedPoint(
        x: $checkedConvert('x', (v) => (v as num).toDouble()),
        y: $checkedConvert('y', (v) => (v as num).toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$NormalisedPointToJson(_NormalisedPoint instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

_PageQuad _$PageQuadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PageQuad', json, ($checkedConvert) {
      final val = _PageQuad(
        topLeft: $checkedConvert(
          'topLeft',
          (v) => NormalisedPoint.fromJson(v as Map<String, dynamic>),
        ),
        topRight: $checkedConvert(
          'topRight',
          (v) => NormalisedPoint.fromJson(v as Map<String, dynamic>),
        ),
        bottomRight: $checkedConvert(
          'bottomRight',
          (v) => NormalisedPoint.fromJson(v as Map<String, dynamic>),
        ),
        bottomLeft: $checkedConvert(
          'bottomLeft',
          (v) => NormalisedPoint.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PageQuadToJson(_PageQuad instance) => <String, dynamic>{
  'topLeft': instance.topLeft.toJson(),
  'topRight': instance.topRight.toJson(),
  'bottomRight': instance.bottomRight.toJson(),
  'bottomLeft': instance.bottomLeft.toJson(),
};

_EnhancementSettings _$EnhancementSettingsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_EnhancementSettings', json, ($checkedConvert) {
  final val = _EnhancementSettings(
    filter: $checkedConvert(
      'filter',
      (v) =>
          $enumDecodeNullable(_$EnhancementFilterEnumMap, v) ??
          EnhancementFilter.original,
    ),
    brightness: $checkedConvert(
      'brightness',
      (v) => (v as num?)?.toDouble() ?? 0.0,
    ),
    contrast: $checkedConvert(
      'contrast',
      (v) => (v as num?)?.toDouble() ?? 0.0,
    ),
    sharpen: $checkedConvert('sharpen', (v) => (v as num?)?.toDouble() ?? 0.0),
    shadowRemoval: $checkedConvert('shadowRemoval', (v) => v as bool? ?? false),
  );
  return val;
});

Map<String, dynamic> _$EnhancementSettingsToJson(
  _EnhancementSettings instance,
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

_DocumentPage _$DocumentPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_DocumentPage', json, ($checkedConvert) {
      final val = _DocumentPage(
        id: $checkedConvert('id', (v) => PageId.fromJson(v as String)),
        documentId: $checkedConvert(
          'documentId',
          (v) => DocumentId.fromJson(v as String),
        ),
        order: $checkedConvert('order', (v) => (v as num).toInt()),
        imagePath: $checkedConvert('imagePath', (v) => v as String),
        rotation: $checkedConvert(
          'rotation',
          (v) =>
              $enumDecodeNullable(_$PageRotationEnumMap, v) ??
              PageRotation.none,
        ),
        enhancement: $checkedConvert(
          'enhancement',
          (v) => v == null
              ? const EnhancementSettings()
              : EnhancementSettings.fromJson(v as Map<String, dynamic>),
        ),
        thumbnailPath: $checkedConvert('thumbnailPath', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DocumentPageToJson(_DocumentPage instance) =>
    <String, dynamic>{
      'id': instance.id.toJson(),
      'documentId': instance.documentId.toJson(),
      'order': instance.order,
      'imagePath': instance.imagePath,
      'rotation': _$PageRotationEnumMap[instance.rotation]!,
      'enhancement': instance.enhancement.toJson(),
      'thumbnailPath': instance.thumbnailPath,
    };

const _$PageRotationEnumMap = {
  PageRotation.none: 'none',
  PageRotation.quarter: 'quarter',
  PageRotation.half: 'half',
  PageRotation.threeQuarter: 'threeQuarter',
};

_PageRef _$PageRefFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_PageRef',
  json,
  ($checkedConvert) {
    final val = _PageRef(
      id: $checkedConvert('id', (v) => PageId.fromJson(v as String)),
      imagePath: $checkedConvert('imagePath', (v) => v as String),
      rotation: $checkedConvert(
        'rotation',
        (v) =>
            $enumDecodeNullable(_$PageRotationEnumMap, v) ?? PageRotation.none,
      ),
      enhancement: $checkedConvert(
        'enhancement',
        (v) => v == null
            ? const EnhancementSettings()
            : EnhancementSettings.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$PageRefToJson(_PageRef instance) => <String, dynamic>{
  'id': instance.id.toJson(),
  'imagePath': instance.imagePath,
  'rotation': _$PageRotationEnumMap[instance.rotation]!,
  'enhancement': instance.enhancement.toJson(),
};
