// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_page_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScannedPageBundle _$ScannedPageBundleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ScannedPageBundle', json, ($checkedConvert) {
      final val = _ScannedPageBundle(
        pages: $checkedConvert(
          'pages',
          (v) => (v as List<dynamic>)
              .map((e) => PageRef.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        source: $checkedConvert(
          'source',
          (v) => $enumDecode(_$PageSourceEnumMap, v),
        ),
        suggestedTitle: $checkedConvert('suggestedTitle', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ScannedPageBundleToJson(_ScannedPageBundle instance) =>
    <String, dynamic>{
      'pages': instance.pages.map((e) => e.toJson()).toList(),
      'source': _$PageSourceEnumMap[instance.source]!,
      'suggestedTitle': instance.suggestedTitle,
    };

const _$PageSourceEnumMap = {
  PageSource.camera: 'camera',
  PageSource.gallery: 'gallery',
  PageSource.files: 'files',
  PageSource.shareSheet: 'shareSheet',
};
