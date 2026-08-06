// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_entities.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDocumentEntityCollection on Isar {
  IsarCollection<DocumentEntity> get documentEntitys => this.collection();
}

const DocumentEntitySchema = CollectionSchema(
  name: r'DocumentEntity',
  id: 5395616779084000924,
  properties: {
    r'cloudRelativePath': PropertySchema(
      id: 0,
      name: r'cloudRelativePath',
      type: IsarType.string,
    ),
    r'cloudResourceIdentifier': PropertySchema(
      id: 1,
      name: r'cloudResourceIdentifier',
      type: IsarType.string,
    ),
    r'contentAvailability': PropertySchema(
      id: 2,
      name: r'contentAvailability',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'fileName': PropertySchema(
      id: 4,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'folderPath': PropertySchema(
      id: 5,
      name: r'folderPath',
      type: IsarType.string,
    ),
    r'folderUuid': PropertySchema(
      id: 6,
      name: r'folderUuid',
      type: IsarType.string,
    ),
    r'hasRecognisedText': PropertySchema(
      id: 7,
      name: r'hasRecognisedText',
      type: IsarType.bool,
    ),
    r'isArchived': PropertySchema(
      id: 8,
      name: r'isArchived',
      type: IsarType.bool,
    ),
    r'isFavourite': PropertySchema(
      id: 9,
      name: r'isFavourite',
      type: IsarType.bool,
    ),
    r'isProtected': PropertySchema(
      id: 10,
      name: r'isProtected',
      type: IsarType.bool,
    ),
    r'pageCount': PropertySchema(
      id: 11,
      name: r'pageCount',
      type: IsarType.long,
    ),
    r'schemaVersion': PropertySchema(
      id: 12,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'sizeInBytes': PropertySchema(
      id: 13,
      name: r'sizeInBytes',
      type: IsarType.long,
    ),
    r'title': PropertySchema(id: 14, name: r'title', type: IsarType.string),
    r'titleWords': PropertySchema(
      id: 15,
      name: r'titleWords',
      type: IsarType.stringList,
    ),
    r'trashUuid': PropertySchema(
      id: 16,
      name: r'trashUuid',
      type: IsarType.string,
    ),
    r'trashedAt': PropertySchema(
      id: 17,
      name: r'trashedAt',
      type: IsarType.dateTime,
    ),
    r'updatedAt': PropertySchema(
      id: 18,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 19, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _documentEntityEstimateSize,
  serialize: _documentEntitySerialize,
  deserialize: _documentEntityDeserialize,
  deserializeProp: _documentEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'titleWords': IndexSchema(
      id: 80481505061976672,
      name: r'titleWords',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'titleWords',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'folderUuid': IndexSchema(
      id: -1722021532825922287,
      name: r'folderUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'folderUuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isArchived': IndexSchema(
      id: 655844772568347876,
      name: r'isArchived',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isArchived',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'cloudResourceIdentifier': IndexSchema(
      id: -9186586345970305180,
      name: r'cloudResourceIdentifier',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'cloudResourceIdentifier',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'trashUuid': IndexSchema(
      id: 6959342789773877252,
      name: r'trashUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'trashUuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _documentEntityGetId,
  getLinks: _documentEntityGetLinks,
  attach: _documentEntityAttach,
  version: '3.3.2',
);

int _documentEntityEstimateSize(
  DocumentEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cloudRelativePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cloudResourceIdentifier;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.contentAvailability;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.fileName.length * 3;
  bytesCount += 3 + object.folderPath.length * 3;
  {
    final value = object.folderUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.titleWords.length * 3;
  {
    for (var i = 0; i < object.titleWords.length; i++) {
      final value = object.titleWords[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.trashUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _documentEntitySerialize(
  DocumentEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cloudRelativePath);
  writer.writeString(offsets[1], object.cloudResourceIdentifier);
  writer.writeString(offsets[2], object.contentAvailability);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.fileName);
  writer.writeString(offsets[5], object.folderPath);
  writer.writeString(offsets[6], object.folderUuid);
  writer.writeBool(offsets[7], object.hasRecognisedText);
  writer.writeBool(offsets[8], object.isArchived);
  writer.writeBool(offsets[9], object.isFavourite);
  writer.writeBool(offsets[10], object.isProtected);
  writer.writeLong(offsets[11], object.pageCount);
  writer.writeLong(offsets[12], object.schemaVersion);
  writer.writeLong(offsets[13], object.sizeInBytes);
  writer.writeString(offsets[14], object.title);
  writer.writeStringList(offsets[15], object.titleWords);
  writer.writeString(offsets[16], object.trashUuid);
  writer.writeDateTime(offsets[17], object.trashedAt);
  writer.writeDateTime(offsets[18], object.updatedAt);
  writer.writeString(offsets[19], object.uuid);
}

DocumentEntity _documentEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DocumentEntity();
  object.cloudRelativePath = reader.readStringOrNull(offsets[0]);
  object.cloudResourceIdentifier = reader.readStringOrNull(offsets[1]);
  object.contentAvailability = reader.readStringOrNull(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.fileName = reader.readString(offsets[4]);
  object.folderPath = reader.readString(offsets[5]);
  object.folderUuid = reader.readStringOrNull(offsets[6]);
  object.hasRecognisedText = reader.readBool(offsets[7]);
  object.id = id;
  object.isArchived = reader.readBool(offsets[8]);
  object.isFavourite = reader.readBool(offsets[9]);
  object.isProtected = reader.readBool(offsets[10]);
  object.pageCount = reader.readLong(offsets[11]);
  object.schemaVersion = reader.readLong(offsets[12]);
  object.sizeInBytes = reader.readLong(offsets[13]);
  object.title = reader.readString(offsets[14]);
  object.titleWords = reader.readStringList(offsets[15]) ?? [];
  object.trashUuid = reader.readStringOrNull(offsets[16]);
  object.trashedAt = reader.readDateTimeOrNull(offsets[17]);
  object.updatedAt = reader.readDateTime(offsets[18]);
  object.uuid = reader.readString(offsets[19]);
  return object;
}

P _documentEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringList(offset) ?? []) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 18:
      return (reader.readDateTime(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _documentEntityGetId(DocumentEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _documentEntityGetLinks(DocumentEntity object) {
  return [];
}

void _documentEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  DocumentEntity object,
) {
  object.id = id;
}

extension DocumentEntityByIndex on IsarCollection<DocumentEntity> {
  Future<DocumentEntity?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  DocumentEntity? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<DocumentEntity?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<DocumentEntity?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(DocumentEntity object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(DocumentEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<DocumentEntity> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<DocumentEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension DocumentEntityQueryWhereSort
    on QueryBuilder<DocumentEntity, DocumentEntity, QWhere> {
  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhere>
  anyTitleWordsElement() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'titleWords'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhere> anyIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isArchived'),
      );
    });
  }
}

extension DocumentEntityQueryWhere
    on QueryBuilder<DocumentEntity, DocumentEntity, QWhereClause> {
  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementEqualTo(String titleWordsElement) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'titleWords',
          value: [titleWordsElement],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementNotEqualTo(String titleWordsElement) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'titleWords',
                lower: [],
                upper: [titleWordsElement],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'titleWords',
                lower: [titleWordsElement],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'titleWords',
                lower: [titleWordsElement],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'titleWords',
                lower: [],
                upper: [titleWordsElement],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementGreaterThan(
    String titleWordsElement, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'titleWords',
          lower: [titleWordsElement],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementLessThan(String titleWordsElement, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'titleWords',
          lower: [],
          upper: [titleWordsElement],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementBetween(
    String lowerTitleWordsElement,
    String upperTitleWordsElement, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'titleWords',
          lower: [lowerTitleWordsElement],
          includeLower: includeLower,
          upper: [upperTitleWordsElement],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementStartsWith(String TitleWordsElementPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'titleWords',
          lower: [TitleWordsElementPrefix],
          upper: ['$TitleWordsElementPrefix\u{FFFFF}'],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'titleWords', value: ['']),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  titleWordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'titleWords', upper: ['']),
            )
            .addWhereClause(
              IndexWhereClause.greaterThan(
                indexName: r'titleWords',
                lower: [''],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.greaterThan(
                indexName: r'titleWords',
                lower: [''],
              ),
            )
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'titleWords', upper: ['']),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'updatedAt', value: [updatedAt]),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  updatedAtGreaterThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [updatedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  updatedAtLessThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [],
          upper: [updatedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [lowerUpdatedAt],
          includeLower: includeLower,
          upper: [upperUpdatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  folderUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'folderUuid', value: [null]),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  folderUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'folderUuid',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  folderUuidEqualTo(String? folderUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'folderUuid', value: [folderUuid]),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  folderUuidNotEqualTo(String? folderUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'folderUuid',
                lower: [],
                upper: [folderUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'folderUuid',
                lower: [folderUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'folderUuid',
                lower: [folderUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'folderUuid',
                lower: [],
                upper: [folderUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  isArchivedEqualTo(bool isArchived) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isArchived', value: [isArchived]),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  isArchivedNotEqualTo(bool isArchived) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isArchived',
                lower: [],
                upper: [isArchived],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isArchived',
                lower: [isArchived],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isArchived',
                lower: [isArchived],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isArchived',
                lower: [],
                upper: [isArchived],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  cloudResourceIdentifierIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'cloudResourceIdentifier',
          value: [null],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  cloudResourceIdentifierIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'cloudResourceIdentifier',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  cloudResourceIdentifierEqualTo(String? cloudResourceIdentifier) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'cloudResourceIdentifier',
          value: [cloudResourceIdentifier],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  cloudResourceIdentifierNotEqualTo(String? cloudResourceIdentifier) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cloudResourceIdentifier',
                lower: [],
                upper: [cloudResourceIdentifier],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cloudResourceIdentifier',
                lower: [cloudResourceIdentifier],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cloudResourceIdentifier',
                lower: [cloudResourceIdentifier],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cloudResourceIdentifier',
                lower: [],
                upper: [cloudResourceIdentifier],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  trashUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'trashUuid', value: [null]),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  trashUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'trashUuid',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  trashUuidEqualTo(String? trashUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'trashUuid', value: [trashUuid]),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterWhereClause>
  trashUuidNotEqualTo(String? trashUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [],
                upper: [trashUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [trashUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [trashUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [],
                upper: [trashUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension DocumentEntityQueryFilter
    on QueryBuilder<DocumentEntity, DocumentEntity, QFilterCondition> {
  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cloudRelativePath'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cloudRelativePath'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cloudRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cloudRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cloudRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cloudRelativePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cloudRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cloudRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cloudRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cloudRelativePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cloudRelativePath', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudRelativePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cloudRelativePath', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cloudResourceIdentifier'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cloudResourceIdentifier'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cloudResourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cloudResourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cloudResourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cloudResourceIdentifier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cloudResourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cloudResourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cloudResourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cloudResourceIdentifier',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cloudResourceIdentifier',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  cloudResourceIdentifierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'cloudResourceIdentifier',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contentAvailability'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contentAvailability'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contentAvailability',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contentAvailability',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contentAvailability',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contentAvailability',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contentAvailability',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contentAvailability',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contentAvailability',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contentAvailability',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contentAvailability', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  contentAvailabilityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'contentAvailability',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'folderPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'folderPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'folderPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'folderPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'folderPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'folderPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'folderPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'folderPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'folderPath', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'folderPath', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'folderUuid'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'folderUuid'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'folderUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'folderUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'folderUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'folderUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'folderUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'folderUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'folderUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'folderUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'folderUuid', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  folderUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'folderUuid', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  hasRecognisedTextEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasRecognisedText', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  isArchivedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isArchived', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  isFavouriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFavourite', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  isProtectedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isProtected', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  pageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pageCount', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  pageCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pageCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  pageCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pageCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  pageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pageCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  schemaVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  schemaVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schemaVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  sizeInBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sizeInBytes', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  sizeInBytesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sizeInBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  sizeInBytesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sizeInBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  sizeInBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sizeInBytes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'titleWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'titleWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'titleWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'titleWords',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'titleWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'titleWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'titleWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'titleWords',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'titleWords', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'titleWords', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'titleWords', length, true, length, true);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'titleWords', 0, true, 0, true);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'titleWords', 0, false, 999999, true);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'titleWords', 0, true, length, include);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'titleWords', length, include, 999999, true);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  titleWordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'titleWords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trashUuid'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trashUuid'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trashUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'trashUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trashUuid', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'trashUuid', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trashedAt'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trashedAt'),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trashedAt', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trashedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trashedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  trashedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trashedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension DocumentEntityQueryObject
    on QueryBuilder<DocumentEntity, DocumentEntity, QFilterCondition> {}

extension DocumentEntityQueryLinks
    on QueryBuilder<DocumentEntity, DocumentEntity, QFilterCondition> {}

extension DocumentEntityQuerySortBy
    on QueryBuilder<DocumentEntity, DocumentEntity, QSortBy> {
  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByCloudRelativePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudRelativePath', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByCloudRelativePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudRelativePath', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByCloudResourceIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudResourceIdentifier', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByCloudResourceIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudResourceIdentifier', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByContentAvailability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentAvailability', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByContentAvailabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentAvailability', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByFolderPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderPath', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByFolderPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderPath', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByFolderUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderUuid', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByFolderUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderUuid', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByHasRecognisedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRecognisedText', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByHasRecognisedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRecognisedText', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByIsFavourite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByIsFavouriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByIsProtected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProtected', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByIsProtectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProtected', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByPageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByPageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortBySizeInBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortBySizeInBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByTrashUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByTrashUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByTrashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByTrashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension DocumentEntityQuerySortThenBy
    on QueryBuilder<DocumentEntity, DocumentEntity, QSortThenBy> {
  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByCloudRelativePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudRelativePath', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByCloudRelativePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudRelativePath', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByCloudResourceIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudResourceIdentifier', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByCloudResourceIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudResourceIdentifier', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByContentAvailability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentAvailability', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByContentAvailabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentAvailability', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByFolderPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderPath', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByFolderPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderPath', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByFolderUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderUuid', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByFolderUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderUuid', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByHasRecognisedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRecognisedText', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByHasRecognisedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRecognisedText', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByIsFavourite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByIsFavouriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByIsProtected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProtected', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByIsProtectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProtected', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByPageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByPageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenBySizeInBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenBySizeInBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByTrashUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByTrashUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByTrashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByTrashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension DocumentEntityQueryWhereDistinct
    on QueryBuilder<DocumentEntity, DocumentEntity, QDistinct> {
  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByCloudRelativePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'cloudRelativePath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByCloudResourceIdentifier({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'cloudResourceIdentifier',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByContentAvailability({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'contentAvailability',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct> distinctByFileName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct> distinctByFolderPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'folderPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct> distinctByFolderUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'folderUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByHasRecognisedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasRecognisedText');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isArchived');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByIsFavourite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavourite');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByIsProtected() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isProtected');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByPageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageCount');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctBySizeInBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sizeInBytes');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByTitleWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'titleWords');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct> distinctByTrashUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trashUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByTrashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trashedAt');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<DocumentEntity, DocumentEntity, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension DocumentEntityQueryProperty
    on QueryBuilder<DocumentEntity, DocumentEntity, QQueryProperty> {
  QueryBuilder<DocumentEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DocumentEntity, String?, QQueryOperations>
  cloudRelativePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudRelativePath');
    });
  }

  QueryBuilder<DocumentEntity, String?, QQueryOperations>
  cloudResourceIdentifierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudResourceIdentifier');
    });
  }

  QueryBuilder<DocumentEntity, String?, QQueryOperations>
  contentAvailabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentAvailability');
    });
  }

  QueryBuilder<DocumentEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DocumentEntity, String, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<DocumentEntity, String, QQueryOperations> folderPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'folderPath');
    });
  }

  QueryBuilder<DocumentEntity, String?, QQueryOperations> folderUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'folderUuid');
    });
  }

  QueryBuilder<DocumentEntity, bool, QQueryOperations>
  hasRecognisedTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasRecognisedText');
    });
  }

  QueryBuilder<DocumentEntity, bool, QQueryOperations> isArchivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isArchived');
    });
  }

  QueryBuilder<DocumentEntity, bool, QQueryOperations> isFavouriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavourite');
    });
  }

  QueryBuilder<DocumentEntity, bool, QQueryOperations> isProtectedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isProtected');
    });
  }

  QueryBuilder<DocumentEntity, int, QQueryOperations> pageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageCount');
    });
  }

  QueryBuilder<DocumentEntity, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<DocumentEntity, int, QQueryOperations> sizeInBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sizeInBytes');
    });
  }

  QueryBuilder<DocumentEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<DocumentEntity, List<String>, QQueryOperations>
  titleWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'titleWords');
    });
  }

  QueryBuilder<DocumentEntity, String?, QQueryOperations> trashUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trashUuid');
    });
  }

  QueryBuilder<DocumentEntity, DateTime?, QQueryOperations>
  trashedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trashedAt');
    });
  }

  QueryBuilder<DocumentEntity, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<DocumentEntity, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTrashEntityCollection on Isar {
  IsarCollection<TrashEntity> get trashEntitys => this.collection();
}

const TrashEntitySchema = CollectionSchema(
  name: r'TrashEntity',
  id: 8413095562594234552,
  properties: {
    r'deletedAt': PropertySchema(
      id: 0,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'displayName': PropertySchema(
      id: 1,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'documentCount': PropertySchema(
      id: 2,
      name: r'documentCount',
      type: IsarType.long,
    ),
    r'documentUuids': PropertySchema(
      id: 3,
      name: r'documentUuids',
      type: IsarType.stringList,
    ),
    r'expiresAt': PropertySchema(
      id: 4,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'folderCount': PropertySchema(
      id: 5,
      name: r'folderCount',
      type: IsarType.long,
    ),
    r'folderUuids': PropertySchema(
      id: 6,
      name: r'folderUuids',
      type: IsarType.stringList,
    ),
    r'kind': PropertySchema(id: 7, name: r'kind', type: IsarType.string),
    r'originalRelativePath': PropertySchema(
      id: 8,
      name: r'originalRelativePath',
      type: IsarType.string,
    ),
    r'otherFileCount': PropertySchema(
      id: 9,
      name: r'otherFileCount',
      type: IsarType.long,
    ),
    r'schemaVersion': PropertySchema(
      id: 10,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'sizeInBytes': PropertySchema(
      id: 11,
      name: r'sizeInBytes',
      type: IsarType.long,
    ),
    r'uuid': PropertySchema(id: 12, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _trashEntityEstimateSize,
  serialize: _trashEntitySerialize,
  deserialize: _trashEntityDeserialize,
  deserializeProp: _trashEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'deletedAt': IndexSchema(
      id: -8969437169173379604,
      name: r'deletedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deletedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'expiresAt': IndexSchema(
      id: 4994901953235663716,
      name: r'expiresAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'expiresAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _trashEntityGetId,
  getLinks: _trashEntityGetLinks,
  attach: _trashEntityAttach,
  version: '3.3.2',
);

int _trashEntityEstimateSize(
  TrashEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.documentUuids.length * 3;
  {
    for (var i = 0; i < object.documentUuids.length; i++) {
      final value = object.documentUuids[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.folderUuids.length * 3;
  {
    for (var i = 0; i < object.folderUuids.length; i++) {
      final value = object.folderUuids[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.kind.length * 3;
  bytesCount += 3 + object.originalRelativePath.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _trashEntitySerialize(
  TrashEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.deletedAt);
  writer.writeString(offsets[1], object.displayName);
  writer.writeLong(offsets[2], object.documentCount);
  writer.writeStringList(offsets[3], object.documentUuids);
  writer.writeDateTime(offsets[4], object.expiresAt);
  writer.writeLong(offsets[5], object.folderCount);
  writer.writeStringList(offsets[6], object.folderUuids);
  writer.writeString(offsets[7], object.kind);
  writer.writeString(offsets[8], object.originalRelativePath);
  writer.writeLong(offsets[9], object.otherFileCount);
  writer.writeLong(offsets[10], object.schemaVersion);
  writer.writeLong(offsets[11], object.sizeInBytes);
  writer.writeString(offsets[12], object.uuid);
}

TrashEntity _trashEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TrashEntity();
  object.deletedAt = reader.readDateTime(offsets[0]);
  object.displayName = reader.readString(offsets[1]);
  object.documentCount = reader.readLong(offsets[2]);
  object.documentUuids = reader.readStringList(offsets[3]) ?? [];
  object.expiresAt = reader.readDateTime(offsets[4]);
  object.folderCount = reader.readLong(offsets[5]);
  object.folderUuids = reader.readStringList(offsets[6]) ?? [];
  object.id = id;
  object.kind = reader.readString(offsets[7]);
  object.originalRelativePath = reader.readString(offsets[8]);
  object.otherFileCount = reader.readLong(offsets[9]);
  object.schemaVersion = reader.readLong(offsets[10]);
  object.sizeInBytes = reader.readLong(offsets[11]);
  object.uuid = reader.readString(offsets[12]);
  return object;
}

P _trashEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _trashEntityGetId(TrashEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _trashEntityGetLinks(TrashEntity object) {
  return [];
}

void _trashEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  TrashEntity object,
) {
  object.id = id;
}

extension TrashEntityByIndex on IsarCollection<TrashEntity> {
  Future<TrashEntity?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  TrashEntity? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<TrashEntity?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<TrashEntity?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(TrashEntity object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(TrashEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<TrashEntity> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<TrashEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension TrashEntityQueryWhereSort
    on QueryBuilder<TrashEntity, TrashEntity, QWhere> {
  QueryBuilder<TrashEntity, TrashEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhere> anyDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deletedAt'),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhere> anyExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'expiresAt'),
      );
    });
  }
}

extension TrashEntityQueryWhere
    on QueryBuilder<TrashEntity, TrashEntity, QWhereClause> {
  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> uuidNotEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> deletedAtEqualTo(
    DateTime deletedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [deletedAt]),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> deletedAtNotEqualTo(
    DateTime deletedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause>
  deletedAtGreaterThan(DateTime deletedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [deletedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> deletedAtLessThan(
    DateTime deletedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [],
          upper: [deletedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> deletedAtBetween(
    DateTime lowerDeletedAt,
    DateTime upperDeletedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [lowerDeletedAt],
          includeLower: includeLower,
          upper: [upperDeletedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> expiresAtEqualTo(
    DateTime expiresAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'expiresAt', value: [expiresAt]),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> expiresAtNotEqualTo(
    DateTime expiresAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiresAt',
                lower: [],
                upper: [expiresAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiresAt',
                lower: [expiresAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiresAt',
                lower: [expiresAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expiresAt',
                lower: [],
                upper: [expiresAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause>
  expiresAtGreaterThan(DateTime expiresAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expiresAt',
          lower: [expiresAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> expiresAtLessThan(
    DateTime expiresAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expiresAt',
          lower: [],
          upper: [expiresAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterWhereClause> expiresAtBetween(
    DateTime lowerExpiresAt,
    DateTime upperExpiresAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expiresAt',
          lower: [lowerExpiresAt],
          includeLower: includeLower,
          upper: [upperExpiresAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension TrashEntityQueryFilter
    on QueryBuilder<TrashEntity, TrashEntity, QFilterCondition> {
  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  deletedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  deletedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  deletedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  deletedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'displayName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'displayName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentCount', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'documentUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentUuids',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'documentUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'documentUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'documentUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'documentUuids',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentUuids', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentUuids', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'documentUuids', length, true, length, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'documentUuids', 0, true, 0, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'documentUuids', 0, false, 999999, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'documentUuids', 0, true, length, include);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'documentUuids', length, include, 999999, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  documentUuidsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'documentUuids',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  expiresAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'expiresAt', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  expiresAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expiresAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  expiresAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expiresAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  expiresAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expiresAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'folderCount', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'folderCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'folderCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'folderCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'folderUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'folderUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'folderUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'folderUuids',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'folderUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'folderUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'folderUuids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'folderUuids',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'folderUuids', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'folderUuids', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'folderUuids', length, true, length, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'folderUuids', 0, true, 0, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'folderUuids', 0, false, 999999, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'folderUuids', 0, true, length, include);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'folderUuids', length, include, 999999, true);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  folderUuidsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'folderUuids',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'kind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'kind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kind', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalRelativePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'originalRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'originalRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'originalRelativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'originalRelativePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'originalRelativePath', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  originalRelativePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'originalRelativePath',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  otherFileCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'otherFileCount', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  otherFileCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'otherFileCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  otherFileCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'otherFileCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  otherFileCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'otherFileCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  schemaVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  schemaVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schemaVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  sizeInBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sizeInBytes', value: value),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  sizeInBytesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sizeInBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  sizeInBytesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sizeInBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  sizeInBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sizeInBytes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension TrashEntityQueryObject
    on QueryBuilder<TrashEntity, TrashEntity, QFilterCondition> {}

extension TrashEntityQueryLinks
    on QueryBuilder<TrashEntity, TrashEntity, QFilterCondition> {}

extension TrashEntityQuerySortBy
    on QueryBuilder<TrashEntity, TrashEntity, QSortBy> {
  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByDocumentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentCount', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  sortByDocumentCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentCount', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByFolderCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderCount', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByFolderCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderCount', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  sortByOriginalRelativePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalRelativePath', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  sortByOriginalRelativePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalRelativePath', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByOtherFileCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherFileCount', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  sortByOtherFileCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherFileCount', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortBySizeInBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortBySizeInBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension TrashEntityQuerySortThenBy
    on QueryBuilder<TrashEntity, TrashEntity, QSortThenBy> {
  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByDocumentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentCount', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  thenByDocumentCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentCount', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByFolderCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderCount', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByFolderCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folderCount', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  thenByOriginalRelativePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalRelativePath', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  thenByOriginalRelativePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalRelativePath', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByOtherFileCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherFileCount', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  thenByOtherFileCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherFileCount', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenBySizeInBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenBySizeInBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeInBytes', Sort.desc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension TrashEntityQueryWhereDistinct
    on QueryBuilder<TrashEntity, TrashEntity, QDistinct> {
  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByDisplayName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByDocumentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentCount');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByDocumentUuids() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentUuids');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByFolderCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'folderCount');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByFolderUuids() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'folderUuids');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByKind({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct>
  distinctByOriginalRelativePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'originalRelativePath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByOtherFileCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherFileCount');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctBySizeInBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sizeInBytes');
    });
  }

  QueryBuilder<TrashEntity, TrashEntity, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension TrashEntityQueryProperty
    on QueryBuilder<TrashEntity, TrashEntity, QQueryProperty> {
  QueryBuilder<TrashEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TrashEntity, DateTime, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<TrashEntity, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<TrashEntity, int, QQueryOperations> documentCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentCount');
    });
  }

  QueryBuilder<TrashEntity, List<String>, QQueryOperations>
  documentUuidsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentUuids');
    });
  }

  QueryBuilder<TrashEntity, DateTime, QQueryOperations> expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<TrashEntity, int, QQueryOperations> folderCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'folderCount');
    });
  }

  QueryBuilder<TrashEntity, List<String>, QQueryOperations>
  folderUuidsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'folderUuids');
    });
  }

  QueryBuilder<TrashEntity, String, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<TrashEntity, String, QQueryOperations>
  originalRelativePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalRelativePath');
    });
  }

  QueryBuilder<TrashEntity, int, QQueryOperations> otherFileCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherFileCount');
    });
  }

  QueryBuilder<TrashEntity, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<TrashEntity, int, QQueryOperations> sizeInBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sizeInBytes');
    });
  }

  QueryBuilder<TrashEntity, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFolderEntityCollection on Isar {
  IsarCollection<FolderEntity> get folderEntitys => this.collection();
}

const FolderEntitySchema = CollectionSchema(
  name: r'FolderEntity',
  id: 1865616643271602644,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(id: 1, name: r'name', type: IsarType.string),
    r'relativePath': PropertySchema(
      id: 2,
      name: r'relativePath',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 3,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'trashUuid': PropertySchema(
      id: 4,
      name: r'trashUuid',
      type: IsarType.string,
    ),
    r'trashedAt': PropertySchema(
      id: 5,
      name: r'trashedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 6, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _folderEntityEstimateSize,
  serialize: _folderEntitySerialize,
  deserialize: _folderEntityDeserialize,
  deserializeProp: _folderEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
    r'trashUuid': IndexSchema(
      id: 6959342789773877252,
      name: r'trashUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'trashUuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _folderEntityGetId,
  getLinks: _folderEntityGetLinks,
  attach: _folderEntityAttach,
  version: '3.3.2',
);

int _folderEntityEstimateSize(
  FolderEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.relativePath.length * 3;
  {
    final value = object.trashUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _folderEntitySerialize(
  FolderEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.name);
  writer.writeString(offsets[2], object.relativePath);
  writer.writeLong(offsets[3], object.schemaVersion);
  writer.writeString(offsets[4], object.trashUuid);
  writer.writeDateTime(offsets[5], object.trashedAt);
  writer.writeString(offsets[6], object.uuid);
}

FolderEntity _folderEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FolderEntity();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  object.relativePath = reader.readString(offsets[2]);
  object.schemaVersion = reader.readLong(offsets[3]);
  object.trashUuid = reader.readStringOrNull(offsets[4]);
  object.trashedAt = reader.readDateTimeOrNull(offsets[5]);
  object.uuid = reader.readString(offsets[6]);
  return object;
}

P _folderEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _folderEntityGetId(FolderEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _folderEntityGetLinks(FolderEntity object) {
  return [];
}

void _folderEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  FolderEntity object,
) {
  object.id = id;
}

extension FolderEntityByIndex on IsarCollection<FolderEntity> {
  Future<FolderEntity?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  FolderEntity? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<FolderEntity?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<FolderEntity?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(FolderEntity object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(FolderEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<FolderEntity> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<FolderEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension FolderEntityQueryWhereSort
    on QueryBuilder<FolderEntity, FolderEntity, QWhere> {
  QueryBuilder<FolderEntity, FolderEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FolderEntityQueryWhere
    on QueryBuilder<FolderEntity, FolderEntity, QWhereClause> {
  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> uuidNotEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> nameEqualTo(
    String name,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'name', value: [name]),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> nameNotEqualTo(
    String name,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [],
                upper: [name],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [name],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [name],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [],
                upper: [name],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause>
  trashUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'trashUuid', value: [null]),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause>
  trashUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'trashUuid',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause> trashUuidEqualTo(
    String? trashUuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'trashUuid', value: [trashUuid]),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterWhereClause>
  trashUuidNotEqualTo(String? trashUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [],
                upper: [trashUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [trashUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [trashUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'trashUuid',
                lower: [],
                upper: [trashUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension FolderEntityQueryFilter
    on QueryBuilder<FolderEntity, FolderEntity, QFilterCondition> {
  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'relativePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'relativePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'relativePath', value: ''),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  relativePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'relativePath', value: ''),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  schemaVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  schemaVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schemaVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trashUuid'),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trashUuid'),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trashUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'trashUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'trashUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trashUuid', value: ''),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'trashUuid', value: ''),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trashedAt'),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trashedAt'),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trashedAt', value: value),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trashedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trashedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  trashedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trashedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  uuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> uuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> uuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension FolderEntityQueryObject
    on QueryBuilder<FolderEntity, FolderEntity, QFilterCondition> {}

extension FolderEntityQueryLinks
    on QueryBuilder<FolderEntity, FolderEntity, QFilterCondition> {}

extension FolderEntityQuerySortBy
    on QueryBuilder<FolderEntity, FolderEntity, QSortBy> {
  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByRelativePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativePath', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy>
  sortByRelativePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativePath', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByTrashUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByTrashUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByTrashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByTrashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension FolderEntityQuerySortThenBy
    on QueryBuilder<FolderEntity, FolderEntity, QSortThenBy> {
  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByRelativePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativePath', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy>
  thenByRelativePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relativePath', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByTrashUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByTrashUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashUuid', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByTrashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByTrashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trashedAt', Sort.desc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension FolderEntityQueryWhereDistinct
    on QueryBuilder<FolderEntity, FolderEntity, QDistinct> {
  QueryBuilder<FolderEntity, FolderEntity, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QDistinct> distinctByRelativePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relativePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QDistinct> distinctByTrashUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trashUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QDistinct> distinctByTrashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trashedAt');
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension FolderEntityQueryProperty
    on QueryBuilder<FolderEntity, FolderEntity, QQueryProperty> {
  QueryBuilder<FolderEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FolderEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FolderEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<FolderEntity, String, QQueryOperations> relativePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relativePath');
    });
  }

  QueryBuilder<FolderEntity, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<FolderEntity, String?, QQueryOperations> trashUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trashUuid');
    });
  }

  QueryBuilder<FolderEntity, DateTime?, QQueryOperations> trashedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trashedAt');
    });
  }

  QueryBuilder<FolderEntity, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPageEntityCollection on Isar {
  IsarCollection<PageEntity> get pageEntitys => this.collection();
}

const PageEntitySchema = CollectionSchema(
  name: r'PageEntity',
  id: 7780399719172098451,
  properties: {
    r'brightness': PropertySchema(
      id: 0,
      name: r'brightness',
      type: IsarType.double,
    ),
    r'contrast': PropertySchema(
      id: 1,
      name: r'contrast',
      type: IsarType.double,
    ),
    r'documentUuid': PropertySchema(
      id: 2,
      name: r'documentUuid',
      type: IsarType.string,
    ),
    r'enhancementFilter': PropertySchema(
      id: 3,
      name: r'enhancementFilter',
      type: IsarType.string,
    ),
    r'imagePath': PropertySchema(
      id: 4,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'order': PropertySchema(id: 5, name: r'order', type: IsarType.long),
    r'rotationDegrees': PropertySchema(
      id: 6,
      name: r'rotationDegrees',
      type: IsarType.long,
    ),
    r'schemaVersion': PropertySchema(
      id: 7,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'shadowRemoval': PropertySchema(
      id: 8,
      name: r'shadowRemoval',
      type: IsarType.bool,
    ),
    r'sharpen': PropertySchema(id: 9, name: r'sharpen', type: IsarType.double),
    r'thumbnailPath': PropertySchema(
      id: 10,
      name: r'thumbnailPath',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(id: 11, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _pageEntityEstimateSize,
  serialize: _pageEntitySerialize,
  deserialize: _pageEntityDeserialize,
  deserializeProp: _pageEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'documentUuid': IndexSchema(
      id: -8936215794849628089,
      name: r'documentUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentUuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _pageEntityGetId,
  getLinks: _pageEntityGetLinks,
  attach: _pageEntityAttach,
  version: '3.3.2',
);

int _pageEntityEstimateSize(
  PageEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.documentUuid.length * 3;
  bytesCount += 3 + object.enhancementFilter.length * 3;
  bytesCount += 3 + object.imagePath.length * 3;
  {
    final value = object.thumbnailPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _pageEntitySerialize(
  PageEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.brightness);
  writer.writeDouble(offsets[1], object.contrast);
  writer.writeString(offsets[2], object.documentUuid);
  writer.writeString(offsets[3], object.enhancementFilter);
  writer.writeString(offsets[4], object.imagePath);
  writer.writeLong(offsets[5], object.order);
  writer.writeLong(offsets[6], object.rotationDegrees);
  writer.writeLong(offsets[7], object.schemaVersion);
  writer.writeBool(offsets[8], object.shadowRemoval);
  writer.writeDouble(offsets[9], object.sharpen);
  writer.writeString(offsets[10], object.thumbnailPath);
  writer.writeString(offsets[11], object.uuid);
}

PageEntity _pageEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PageEntity();
  object.brightness = reader.readDouble(offsets[0]);
  object.contrast = reader.readDouble(offsets[1]);
  object.documentUuid = reader.readString(offsets[2]);
  object.enhancementFilter = reader.readString(offsets[3]);
  object.id = id;
  object.imagePath = reader.readString(offsets[4]);
  object.order = reader.readLong(offsets[5]);
  object.rotationDegrees = reader.readLong(offsets[6]);
  object.schemaVersion = reader.readLong(offsets[7]);
  object.shadowRemoval = reader.readBool(offsets[8]);
  object.sharpen = reader.readDouble(offsets[9]);
  object.thumbnailPath = reader.readStringOrNull(offsets[10]);
  object.uuid = reader.readString(offsets[11]);
  return object;
}

P _pageEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pageEntityGetId(PageEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pageEntityGetLinks(PageEntity object) {
  return [];
}

void _pageEntityAttach(IsarCollection<dynamic> col, Id id, PageEntity object) {
  object.id = id;
}

extension PageEntityByIndex on IsarCollection<PageEntity> {
  Future<PageEntity?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  PageEntity? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<PageEntity?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<PageEntity?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(PageEntity object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(PageEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<PageEntity> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<PageEntity> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension PageEntityQueryWhereSort
    on QueryBuilder<PageEntity, PageEntity, QWhere> {
  QueryBuilder<PageEntity, PageEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PageEntityQueryWhere
    on QueryBuilder<PageEntity, PageEntity, QWhereClause> {
  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> uuidNotEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> documentUuidEqualTo(
    String documentUuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'documentUuid',
          value: [documentUuid],
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause>
  documentUuidNotEqualTo(String documentUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentUuid',
                lower: [],
                upper: [documentUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentUuid',
                lower: [documentUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentUuid',
                lower: [documentUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentUuid',
                lower: [],
                upper: [documentUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension PageEntityQueryFilter
    on QueryBuilder<PageEntity, PageEntity, QFilterCondition> {
  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> brightnessEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'brightness',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  brightnessGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'brightness',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  brightnessLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'brightness',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> brightnessBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'brightness',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> contrastEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contrast',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  contrastGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contrast',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> contrastLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contrast',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> contrastBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contrast',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'documentUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'documentUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'documentUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'documentUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'documentUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentUuid', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  documentUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentUuid', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'enhancementFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'enhancementFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'enhancementFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'enhancementFilter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'enhancementFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'enhancementFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'enhancementFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'enhancementFilter',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enhancementFilter', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  enhancementFilterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'enhancementFilter', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> imagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  imagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> imagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> imagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imagePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  imagePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> imagePathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> imagePathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imagePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imagePath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imagePath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> orderEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'order', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> orderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'order',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> orderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'order',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> orderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'order',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  rotationDegreesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rotationDegrees', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  rotationDegreesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rotationDegrees',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  rotationDegreesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rotationDegrees',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  rotationDegreesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rotationDegrees',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  schemaVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  schemaVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schemaVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  shadowRemovalEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shadowRemoval', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> sharpenEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sharpen',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  sharpenGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sharpen',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> sharpenLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sharpen',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> sharpenBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sharpen',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbnailPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbnailPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension PageEntityQueryObject
    on QueryBuilder<PageEntity, PageEntity, QFilterCondition> {}

extension PageEntityQueryLinks
    on QueryBuilder<PageEntity, PageEntity, QFilterCondition> {}

extension PageEntityQuerySortBy
    on QueryBuilder<PageEntity, PageEntity, QSortBy> {
  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByBrightness() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brightness', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByBrightnessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brightness', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contrast', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByContrastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contrast', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByDocumentUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByDocumentUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByEnhancementFilter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enhancementFilter', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  sortByEnhancementFilterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enhancementFilter', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByRotationDegrees() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotationDegrees', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  sortByRotationDegreesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotationDegrees', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByShadowRemoval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shadowRemoval', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByShadowRemovalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shadowRemoval', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortBySharpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharpen', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortBySharpenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharpen', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PageEntityQuerySortThenBy
    on QueryBuilder<PageEntity, PageEntity, QSortThenBy> {
  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByBrightness() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brightness', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByBrightnessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brightness', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contrast', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByContrastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contrast', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByDocumentUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByDocumentUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByEnhancementFilter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enhancementFilter', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  thenByEnhancementFilterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enhancementFilter', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByRotationDegrees() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotationDegrees', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  thenByRotationDegreesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotationDegrees', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByShadowRemoval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shadowRemoval', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByShadowRemovalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shadowRemoval', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenBySharpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharpen', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenBySharpenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharpen', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PageEntityQueryWhereDistinct
    on QueryBuilder<PageEntity, PageEntity, QDistinct> {
  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByBrightness() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'brightness');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contrast');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByDocumentUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByEnhancementFilter({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'enhancementFilter',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByImagePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'order');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByRotationDegrees() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rotationDegrees');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByShadowRemoval() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shadowRemoval');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctBySharpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sharpen');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByThumbnailPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'thumbnailPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension PageEntityQueryProperty
    on QueryBuilder<PageEntity, PageEntity, QQueryProperty> {
  QueryBuilder<PageEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PageEntity, double, QQueryOperations> brightnessProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'brightness');
    });
  }

  QueryBuilder<PageEntity, double, QQueryOperations> contrastProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contrast');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> documentUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentUuid');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations>
  enhancementFilterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enhancementFilter');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<PageEntity, int, QQueryOperations> orderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'order');
    });
  }

  QueryBuilder<PageEntity, int, QQueryOperations> rotationDegreesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rotationDegrees');
    });
  }

  QueryBuilder<PageEntity, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<PageEntity, bool, QQueryOperations> shadowRemovalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shadowRemoval');
    });
  }

  QueryBuilder<PageEntity, double, QQueryOperations> sharpenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sharpen');
    });
  }

  QueryBuilder<PageEntity, String?, QQueryOperations> thumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailPath');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
