// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Document _$DocumentFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_Document', json, ($checkedConvert) {
  final val = _Document(
    id: $checkedConvert('id', (v) => DocumentId.fromJson(v as String)),
    title: $checkedConvert('title', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    pageCount: $checkedConvert('pageCount', (v) => (v as num).toInt()),
    sizeInBytes: $checkedConvert('sizeInBytes', (v) => (v as num).toInt()),
    libraryPath: $checkedConvert(
      'libraryPath',
      (v) => LibraryPath.fromJson(v as String),
    ),
    folderId: $checkedConvert(
      'folderId',
      (v) => v == null ? null : FolderId.fromJson(v as String),
    ),
    isFavourite: $checkedConvert('isFavourite', (v) => v as bool? ?? false),
    isArchived: $checkedConvert('isArchived', (v) => v as bool? ?? false),
    isProtected: $checkedConvert('isProtected', (v) => v as bool? ?? false),
    hasRecognisedText: $checkedConvert(
      'hasRecognisedText',
      (v) => v as bool? ?? false,
    ),
    cloudResourceIdentifier: $checkedConvert(
      'cloudResourceIdentifier',
      (v) => v as String?,
    ),
    cloudRelativePath: $checkedConvert(
      'cloudRelativePath',
      (v) => v as String?,
    ),
    contentAvailability: $checkedConvert(
      'contentAvailability',
      (v) =>
          $enumDecodeNullable(_$DocumentContentAvailabilityEnumMap, v) ??
          DocumentContentAvailability.local,
    ),
    trashId: $checkedConvert(
      'trashId',
      (v) => v == null ? null : TrashId.fromJson(v as String),
    ),
    trashedAt: $checkedConvert(
      'trashedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
  );
  return val;
});

Map<String, dynamic> _$DocumentToJson(_Document instance) => <String, dynamic>{
  'id': instance.id.toJson(),
  'title': instance.title,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'pageCount': instance.pageCount,
  'sizeInBytes': instance.sizeInBytes,
  'libraryPath': instance.libraryPath.toJson(),
  'folderId': instance.folderId?.toJson(),
  'isFavourite': instance.isFavourite,
  'isArchived': instance.isArchived,
  'isProtected': instance.isProtected,
  'hasRecognisedText': instance.hasRecognisedText,
  'cloudResourceIdentifier': instance.cloudResourceIdentifier,
  'cloudRelativePath': instance.cloudRelativePath,
  'contentAvailability':
      _$DocumentContentAvailabilityEnumMap[instance.contentAvailability]!,
  'trashId': instance.trashId?.toJson(),
  'trashedAt': instance.trashedAt?.toIso8601String(),
};

const _$DocumentContentAvailabilityEnumMap = {
  DocumentContentAvailability.local: 'local',
  DocumentContentAvailability.remote: 'remote',
  DocumentContentAvailability.downloading: 'downloading',
  DocumentContentAvailability.available: 'available',
  DocumentContentAvailability.failed: 'failed',
};

_Folder _$FolderFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_Folder', json, ($checkedConvert) {
  final val = _Folder(
    id: $checkedConvert('id', (v) => FolderId.fromJson(v as String)),
    name: $checkedConvert('name', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    relativePath: $checkedConvert('relativePath', (v) => v as String? ?? ''),
    documentCount: $checkedConvert(
      'documentCount',
      (v) => (v as num?)?.toInt() ?? 0,
    ),
    trashId: $checkedConvert(
      'trashId',
      (v) => v == null ? null : TrashId.fromJson(v as String),
    ),
    trashedAt: $checkedConvert(
      'trashedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
  );
  return val;
});

Map<String, dynamic> _$FolderToJson(_Folder instance) => <String, dynamic>{
  'id': instance.id.toJson(),
  'name': instance.name,
  'createdAt': instance.createdAt.toIso8601String(),
  'relativePath': instance.relativePath,
  'documentCount': instance.documentCount,
  'trashId': instance.trashId?.toJson(),
  'trashedAt': instance.trashedAt?.toIso8601String(),
};

_StorageSummary _$StorageSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StorageSummary', json, ($checkedConvert) {
      final val = _StorageSummary(
        totalBytes: $checkedConvert('totalBytes', (v) => (v as num).toInt()),
        documentCount: $checkedConvert(
          'documentCount',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StorageSummaryToJson(_StorageSummary instance) =>
    <String, dynamic>{
      'totalBytes': instance.totalBytes,
      'documentCount': instance.documentCount,
    };
