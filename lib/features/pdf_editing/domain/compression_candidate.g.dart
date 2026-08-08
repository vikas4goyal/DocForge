// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compression_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompressionDraft _$CompressionDraftFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CompressionDraft', json, ($checkedConvert) {
  final val = CompressionDraft(
    sourceDocumentId: $checkedConvert('sourceDocumentId', (v) => v as String),
    pageCount: $checkedConvert('pageCount', (v) => (v as num).toInt()),
    originalBytes: $checkedConvert('originalBytes', (v) => (v as num).toInt()),
    qualityPlan: $checkedConvert(
      'qualityPlan',
      (v) => PageQualityPlan.fromJson(v as Map<String, dynamic>),
    ),
    destination: $checkedConvert(
      'destination',
      (v) => $enumDecodeNullable(_$CompressionDestinationEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$CompressionDraftToJson(CompressionDraft instance) =>
    <String, dynamic>{
      'sourceDocumentId': instance.sourceDocumentId,
      'pageCount': instance.pageCount,
      'originalBytes': instance.originalBytes,
      'qualityPlan': instance.qualityPlan.toJson(),
      'destination': _$CompressionDestinationEnumMap[instance.destination],
    };

const _$CompressionDestinationEnumMap = {
  CompressionDestination.copy: 'copy',
  CompressionDestination.overwrite: 'overwrite',
};

CompressionCommitResult _$CompressionCommitResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CompressionCommitResult', json, ($checkedConvert) {
  final val = CompressionCommitResult(
    documentId: $checkedConvert('documentId', (v) => v as String),
    destination: $checkedConvert(
      'destination',
      (v) => $enumDecode(_$CompressionDestinationEnumMap, v),
    ),
    originalBytes: $checkedConvert('originalBytes', (v) => (v as num).toInt()),
    resultBytes: $checkedConvert('resultBytes', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$CompressionCommitResultToJson(
  CompressionCommitResult instance,
) => <String, dynamic>{
  'documentId': instance.documentId,
  'destination': _$CompressionDestinationEnumMap[instance.destination]!,
  'originalBytes': instance.originalBytes,
  'resultBytes': instance.resultBytes,
};
