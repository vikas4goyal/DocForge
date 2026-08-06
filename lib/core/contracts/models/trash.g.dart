// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrashInventory _$TrashInventoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TrashInventory', json, ($checkedConvert) {
      final val = _TrashInventory(
        documentCount: $checkedConvert(
          'documentCount',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        otherFileCount: $checkedConvert(
          'otherFileCount',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        folderCount: $checkedConvert(
          'folderCount',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        sizeInBytes: $checkedConvert(
          'sizeInBytes',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
      );
      return val;
    });

Map<String, dynamic> _$TrashInventoryToJson(_TrashInventory instance) =>
    <String, dynamic>{
      'documentCount': instance.documentCount,
      'otherFileCount': instance.otherFileCount,
      'folderCount': instance.folderCount,
      'sizeInBytes': instance.sizeInBytes,
    };

_TrashEntry _$TrashEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_TrashEntry', json, ($checkedConvert) {
  final val = _TrashEntry(
    id: $checkedConvert('id', (v) => TrashId.fromJson(v as String)),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$TrashEntryKindEnumMap, v),
    ),
    displayName: $checkedConvert('displayName', (v) => v as String),
    originalRelativePath: $checkedConvert(
      'originalRelativePath',
      (v) => v as String,
    ),
    deletedAt: $checkedConvert('deletedAt', (v) => DateTime.parse(v as String)),
    expiresAt: $checkedConvert('expiresAt', (v) => DateTime.parse(v as String)),
    inventory: $checkedConvert(
      'inventory',
      (v) => TrashInventory.fromJson(v as Map<String, dynamic>),
    ),
    documentIds: $checkedConvert(
      'documentIds',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => DocumentId.fromJson(e as String))
              .toList() ??
          const <DocumentId>[],
    ),
    folderIds: $checkedConvert(
      'folderIds',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => FolderId.fromJson(e as String))
              .toList() ??
          const <FolderId>[],
    ),
  );
  return val;
});

Map<String, dynamic> _$TrashEntryToJson(_TrashEntry instance) =>
    <String, dynamic>{
      'id': instance.id.toJson(),
      'kind': _$TrashEntryKindEnumMap[instance.kind]!,
      'displayName': instance.displayName,
      'originalRelativePath': instance.originalRelativePath,
      'deletedAt': instance.deletedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'inventory': instance.inventory.toJson(),
      'documentIds': instance.documentIds.map((e) => e.toJson()).toList(),
      'folderIds': instance.folderIds.map((e) => e.toJson()).toList(),
    };

const _$TrashEntryKindEnumMap = {
  TrashEntryKind.document: 'document',
  TrashEntryKind.folderTree: 'folderTree',
};
