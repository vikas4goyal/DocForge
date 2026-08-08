// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_quality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PdfQualityPercent _$PdfQualityPercentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PdfQualityPercent', json, ($checkedConvert) {
      final val = PdfQualityPercent(
        value: $checkedConvert('value', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$PdfQualityPercentToJson(PdfQualityPercent instance) =>
    <String, dynamic>{'value': instance.value};

_PageQualityPlan _$PageQualityPlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PageQualityPlan', json, ($checkedConvert) {
      final val = _PageQualityPlan(
        documentQuality: $checkedConvert(
          'documentQuality',
          (v) => PdfQualityPercent.fromJson(v as Map<String, dynamic>),
        ),
        pageOverrides: $checkedConvert(
          'pageOverrides',
          (v) =>
              (v as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(
                  k,
                  PdfQualityPercent.fromJson(e as Map<String, dynamic>),
                ),
              ) ??
              const <String, PdfQualityPercent>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$PageQualityPlanToJson(_PageQualityPlan instance) =>
    <String, dynamic>{
      'documentQuality': instance.documentQuality.toJson(),
      'pageOverrides': instance.pageOverrides.map(
        (k, e) => MapEntry(k, e.toJson()),
      ),
    };
