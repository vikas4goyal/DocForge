// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_jobs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PdfCandidate _$PdfCandidateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PdfCandidate', json, ($checkedConvert) {
      final val = PdfCandidate(
        handle: $checkedConvert('handle', (v) => v as String),
        exactBytes: $checkedConvert('exactBytes', (v) => (v as num).toInt()),
        pageCount: $checkedConvert('pageCount', (v) => (v as num).toInt()),
        fingerprint: $checkedConvert(
          'fingerprint',
          (v) => PdfCandidateFingerprint.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PdfCandidateToJson(PdfCandidate instance) =>
    <String, dynamic>{
      'handle': instance.handle,
      'exactBytes': instance.exactBytes,
      'pageCount': instance.pageCount,
      'fingerprint': instance.fingerprint.toJson(),
    };

JobProgress _$JobProgressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JobProgress', json, ($checkedConvert) {
      final val = JobProgress(
        percent: $checkedConvert('percent', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$JobProgressToJson(JobProgress instance) =>
    <String, dynamic>{'percent': instance.percent};

_PdfCandidateFingerprint _$PdfCandidateFingerprintFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_PdfCandidateFingerprint', json, ($checkedConvert) {
  final val = _PdfCandidateFingerprint(
    sourceIdentity: $checkedConvert('sourceIdentity', (v) => v as String),
    configurationIdentity: $checkedConvert(
      'configurationIdentity',
      (v) => v as String,
    ),
    orderedPageQualities: $checkedConvert(
      'orderedPageQualities',
      (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
    ),
    isProtected: $checkedConvert('isProtected', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$PdfCandidateFingerprintToJson(
  _PdfCandidateFingerprint instance,
) => <String, dynamic>{
  'sourceIdentity': instance.sourceIdentity,
  'configurationIdentity': instance.configurationIdentity,
  'orderedPageQualities': instance.orderedPageQualities,
  'isProtected': instance.isProtected,
};
