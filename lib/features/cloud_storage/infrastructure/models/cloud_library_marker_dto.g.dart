// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_library_marker_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CloudLibraryMarkerDto _$CloudLibraryMarkerDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_CloudLibraryMarkerDto', json, ($checkedConvert) {
  final val = _CloudLibraryMarkerDto(
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
    libraryIdentifier: $checkedConvert('libraryIdentifier', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CloudLibraryMarkerDtoToJson(
  _CloudLibraryMarkerDto instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'libraryIdentifier': instance.libraryIdentifier,
};
