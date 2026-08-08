// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_resolution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CameraResolutionTier _$CameraResolutionTierFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CameraResolutionTier', json, ($checkedConvert) {
  final val = CameraResolutionTier(
    id: $checkedConvert('id', (v) => v as String),
    label: $checkedConvert('label', (v) => v as String),
    shortEdge: $checkedConvert('shortEdge', (v) => (v as num).toInt()),
    longEdge: $checkedConvert('longEdge', (v) => (v as num).toInt()),
    rank: $checkedConvert('rank', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$CameraResolutionTierToJson(
  CameraResolutionTier instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'shortEdge': instance.shortEdge,
  'longEdge': instance.longEdge,
  'rank': instance.rank,
};

SupportedCameraResolution _$SupportedCameraResolutionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SupportedCameraResolution', json, ($checkedConvert) {
  final val = SupportedCameraResolution(
    tier: $checkedConvert(
      'tier',
      (v) => CameraResolutionTier.fromJson(v as Map<String, dynamic>),
    ),
    width: $checkedConvert('width', (v) => (v as num).toInt()),
    height: $checkedConvert('height', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$SupportedCameraResolutionToJson(
  SupportedCameraResolution instance,
) => <String, dynamic>{
  'tier': instance.tier.toJson(),
  'width': instance.width,
  'height': instance.height,
};

FullCameraResolution _$FullCameraResolutionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('FullCameraResolution', json, ($checkedConvert) {
  final val = FullCameraResolution(
    $type: $checkedConvert('runtimeType', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {r'$type': 'runtimeType'});

Map<String, dynamic> _$FullCameraResolutionToJson(
  FullCameraResolution instance,
) => <String, dynamic>{'runtimeType': instance.$type};

TierCameraResolution _$TierCameraResolutionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TierCameraResolution', json, ($checkedConvert) {
  final val = TierCameraResolution(
    $checkedConvert(
      'value',
      (v) => CameraResolutionTier.fromJson(v as Map<String, dynamic>),
    ),
    $type: $checkedConvert('runtimeType', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {r'$type': 'runtimeType'});

Map<String, dynamic> _$TierCameraResolutionToJson(
  TierCameraResolution instance,
) => <String, dynamic>{
  'value': instance.value.toJson(),
  'runtimeType': instance.$type,
};
