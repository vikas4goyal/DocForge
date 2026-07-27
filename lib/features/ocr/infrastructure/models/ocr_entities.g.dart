// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_entities.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOcrTextEntityCollection on Isar {
  IsarCollection<OcrTextEntity> get ocrTextEntitys => this.collection();
}

const OcrTextEntitySchema = CollectionSchema(
  name: r'OcrTextEntity',
  id: -8574280650508505885,
  properties: {
    r'blocks': PropertySchema(
      id: 0,
      name: r'blocks',
      type: IsarType.objectList,

      target: r'TextBlockEntity',
    ),
    r'documentUuid': PropertySchema(
      id: 1,
      name: r'documentUuid',
      type: IsarType.string,
    ),
    r'languageTag': PropertySchema(
      id: 2,
      name: r'languageTag',
      type: IsarType.string,
    ),
    r'pageUuid': PropertySchema(
      id: 3,
      name: r'pageUuid',
      type: IsarType.string,
    ),
    r'recognisedAt': PropertySchema(
      id: 4,
      name: r'recognisedAt',
      type: IsarType.dateTime,
    ),
    r'schemaVersion': PropertySchema(
      id: 5,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'searchableText': PropertySchema(
      id: 6,
      name: r'searchableText',
      type: IsarType.string,
    ),
    r'words': PropertySchema(id: 7, name: r'words', type: IsarType.stringList),
  },

  estimateSize: _ocrTextEntityEstimateSize,
  serialize: _ocrTextEntitySerialize,
  deserialize: _ocrTextEntityDeserialize,
  deserializeProp: _ocrTextEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'pageUuid': IndexSchema(
      id: 6216968766606849244,
      name: r'pageUuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'pageUuid',
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
    r'words': IndexSchema(
      id: -8729652909246617716,
      name: r'words',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'words',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {r'TextBlockEntity': TextBlockEntitySchema},

  getId: _ocrTextEntityGetId,
  getLinks: _ocrTextEntityGetLinks,
  attach: _ocrTextEntityAttach,
  version: '3.3.2',
);

int _ocrTextEntityEstimateSize(
  OcrTextEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blocks.length * 3;
  {
    final offsets = allOffsets[TextBlockEntity]!;
    for (var i = 0; i < object.blocks.length; i++) {
      final value = object.blocks[i];
      bytesCount += TextBlockEntitySchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.documentUuid.length * 3;
  bytesCount += 3 + object.languageTag.length * 3;
  bytesCount += 3 + object.pageUuid.length * 3;
  bytesCount += 3 + object.searchableText.length * 3;
  bytesCount += 3 + object.words.length * 3;
  {
    for (var i = 0; i < object.words.length; i++) {
      final value = object.words[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _ocrTextEntitySerialize(
  OcrTextEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<TextBlockEntity>(
    offsets[0],
    allOffsets,
    TextBlockEntitySchema.serialize,
    object.blocks,
  );
  writer.writeString(offsets[1], object.documentUuid);
  writer.writeString(offsets[2], object.languageTag);
  writer.writeString(offsets[3], object.pageUuid);
  writer.writeDateTime(offsets[4], object.recognisedAt);
  writer.writeLong(offsets[5], object.schemaVersion);
  writer.writeString(offsets[6], object.searchableText);
  writer.writeStringList(offsets[7], object.words);
}

OcrTextEntity _ocrTextEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OcrTextEntity();
  object.blocks =
      reader.readObjectList<TextBlockEntity>(
        offsets[0],
        TextBlockEntitySchema.deserialize,
        allOffsets,
        TextBlockEntity(),
      ) ??
      [];
  object.documentUuid = reader.readString(offsets[1]);
  object.id = id;
  object.languageTag = reader.readString(offsets[2]);
  object.pageUuid = reader.readString(offsets[3]);
  object.recognisedAt = reader.readDateTime(offsets[4]);
  object.schemaVersion = reader.readLong(offsets[5]);
  object.searchableText = reader.readString(offsets[6]);
  object.words = reader.readStringList(offsets[7]) ?? [];
  return object;
}

P _ocrTextEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<TextBlockEntity>(
                offset,
                TextBlockEntitySchema.deserialize,
                allOffsets,
                TextBlockEntity(),
              ) ??
              [])
          as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ocrTextEntityGetId(OcrTextEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ocrTextEntityGetLinks(OcrTextEntity object) {
  return [];
}

void _ocrTextEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  OcrTextEntity object,
) {
  object.id = id;
}

extension OcrTextEntityByIndex on IsarCollection<OcrTextEntity> {
  Future<OcrTextEntity?> getByPageUuid(String pageUuid) {
    return getByIndex(r'pageUuid', [pageUuid]);
  }

  OcrTextEntity? getByPageUuidSync(String pageUuid) {
    return getByIndexSync(r'pageUuid', [pageUuid]);
  }

  Future<bool> deleteByPageUuid(String pageUuid) {
    return deleteByIndex(r'pageUuid', [pageUuid]);
  }

  bool deleteByPageUuidSync(String pageUuid) {
    return deleteByIndexSync(r'pageUuid', [pageUuid]);
  }

  Future<List<OcrTextEntity?>> getAllByPageUuid(List<String> pageUuidValues) {
    final values = pageUuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'pageUuid', values);
  }

  List<OcrTextEntity?> getAllByPageUuidSync(List<String> pageUuidValues) {
    final values = pageUuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'pageUuid', values);
  }

  Future<int> deleteAllByPageUuid(List<String> pageUuidValues) {
    final values = pageUuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'pageUuid', values);
  }

  int deleteAllByPageUuidSync(List<String> pageUuidValues) {
    final values = pageUuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'pageUuid', values);
  }

  Future<Id> putByPageUuid(OcrTextEntity object) {
    return putByIndex(r'pageUuid', object);
  }

  Id putByPageUuidSync(OcrTextEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'pageUuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPageUuid(List<OcrTextEntity> objects) {
    return putAllByIndex(r'pageUuid', objects);
  }

  List<Id> putAllByPageUuidSync(
    List<OcrTextEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'pageUuid', objects, saveLinks: saveLinks);
  }
}

extension OcrTextEntityQueryWhereSort
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QWhere> {
  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhere> anyWordsElement() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'words'),
      );
    });
  }
}

extension OcrTextEntityQueryWhere
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QWhereClause> {
  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause> pageUuidEqualTo(
    String pageUuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'pageUuid', value: [pageUuid]),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  pageUuidNotEqualTo(String pageUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pageUuid',
                lower: [],
                upper: [pageUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pageUuid',
                lower: [pageUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pageUuid',
                lower: [pageUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pageUuid',
                lower: [],
                upper: [pageUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  documentUuidEqualTo(String documentUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'documentUuid',
          value: [documentUuid],
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementEqualTo(String wordsElement) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'words', value: [wordsElement]),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementNotEqualTo(String wordsElement) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'words',
                lower: [],
                upper: [wordsElement],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'words',
                lower: [wordsElement],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'words',
                lower: [wordsElement],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'words',
                lower: [],
                upper: [wordsElement],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementGreaterThan(String wordsElement, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'words',
          lower: [wordsElement],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementLessThan(String wordsElement, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'words',
          lower: [],
          upper: [wordsElement],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementBetween(
    String lowerWordsElement,
    String upperWordsElement, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'words',
          lower: [lowerWordsElement],
          includeLower: includeLower,
          upper: [upperWordsElement],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementStartsWith(String WordsElementPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'words',
          lower: [WordsElementPrefix],
          upper: ['$WordsElementPrefix\u{FFFFF}'],
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'words', value: ['']),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterWhereClause>
  wordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'words', upper: ['']),
            )
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'words', lower: ['']),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'words', lower: ['']),
            )
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'words', upper: ['']),
            );
      }
    });
  }
}

extension OcrTextEntityQueryFilter
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QFilterCondition> {
  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  blocksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blocks', length, true, length, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  blocksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blocks', 0, true, 0, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  blocksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blocks', 0, false, 999999, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  blocksLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blocks', 0, true, length, include);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  blocksLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blocks', length, include, 999999, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  blocksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blocks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  documentUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentUuid', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  documentUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentUuid', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'languageTag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'languageTag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'languageTag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'languageTag',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'languageTag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'languageTag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'languageTag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'languageTag',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'languageTag', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  languageTagIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'languageTag', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pageUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pageUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pageUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pageUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pageUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pageUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pageUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pageUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pageUuid', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  pageUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pageUuid', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  recognisedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recognisedAt', value: value),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  recognisedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recognisedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  recognisedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'recognisedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  recognisedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recognisedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
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

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'searchableText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'searchableText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'searchableText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'searchableText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'searchableText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'searchableText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'searchableText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'searchableText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'searchableText', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  searchableTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'searchableText', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'words',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'words',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'words',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'words',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'words',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'words',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'words',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'words',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'words', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'words', value: ''),
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'words', length, true, length, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'words', 0, true, 0, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'words', 0, false, 999999, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'words', 0, true, length, include);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'words', length, include, 999999, true);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  wordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'words',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension OcrTextEntityQueryObject
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QFilterCondition> {
  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterFilterCondition>
  blocksElement(FilterQuery<TextBlockEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'blocks');
    });
  }
}

extension OcrTextEntityQueryLinks
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QFilterCondition> {}

extension OcrTextEntityQuerySortBy
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QSortBy> {
  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortByDocumentUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortByDocumentUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy> sortByLanguageTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageTag', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortByLanguageTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageTag', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy> sortByPageUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageUuid', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortByPageUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageUuid', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortByRecognisedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognisedAt', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortByRecognisedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognisedAt', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortBySearchableText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchableText', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  sortBySearchableTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchableText', Sort.desc);
    });
  }
}

extension OcrTextEntityQuerySortThenBy
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QSortThenBy> {
  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenByDocumentUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenByDocumentUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentUuid', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy> thenByLanguageTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageTag', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenByLanguageTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageTag', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy> thenByPageUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageUuid', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenByPageUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageUuid', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenByRecognisedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognisedAt', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenByRecognisedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognisedAt', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenBySearchableText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchableText', Sort.asc);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QAfterSortBy>
  thenBySearchableTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchableText', Sort.desc);
    });
  }
}

extension OcrTextEntityQueryWhereDistinct
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct> {
  QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct> distinctByDocumentUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct> distinctByLanguageTag({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'languageTag', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct> distinctByPageUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct>
  distinctByRecognisedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recognisedAt');
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct>
  distinctBySearchableText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'searchableText',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OcrTextEntity, OcrTextEntity, QDistinct> distinctByWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'words');
    });
  }
}

extension OcrTextEntityQueryProperty
    on QueryBuilder<OcrTextEntity, OcrTextEntity, QQueryProperty> {
  QueryBuilder<OcrTextEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OcrTextEntity, List<TextBlockEntity>, QQueryOperations>
  blocksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blocks');
    });
  }

  QueryBuilder<OcrTextEntity, String, QQueryOperations> documentUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentUuid');
    });
  }

  QueryBuilder<OcrTextEntity, String, QQueryOperations> languageTagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'languageTag');
    });
  }

  QueryBuilder<OcrTextEntity, String, QQueryOperations> pageUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageUuid');
    });
  }

  QueryBuilder<OcrTextEntity, DateTime, QQueryOperations>
  recognisedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recognisedAt');
    });
  }

  QueryBuilder<OcrTextEntity, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<OcrTextEntity, String, QQueryOperations>
  searchableTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'searchableText');
    });
  }

  QueryBuilder<OcrTextEntity, List<String>, QQueryOperations> wordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'words');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TextBlockEntitySchema = Schema(
  name: r'TextBlockEntity',
  id: -4112458558810260550,
  properties: {
    r'bottom': PropertySchema(id: 0, name: r'bottom', type: IsarType.double),
    r'left': PropertySchema(id: 1, name: r'left', type: IsarType.double),
    r'right': PropertySchema(id: 2, name: r'right', type: IsarType.double),
    r'text': PropertySchema(id: 3, name: r'text', type: IsarType.string),
    r'top': PropertySchema(id: 4, name: r'top', type: IsarType.double),
  },

  estimateSize: _textBlockEntityEstimateSize,
  serialize: _textBlockEntitySerialize,
  deserialize: _textBlockEntityDeserialize,
  deserializeProp: _textBlockEntityDeserializeProp,
);

int _textBlockEntityEstimateSize(
  TextBlockEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.text;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _textBlockEntitySerialize(
  TextBlockEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.bottom);
  writer.writeDouble(offsets[1], object.left);
  writer.writeDouble(offsets[2], object.right);
  writer.writeString(offsets[3], object.text);
  writer.writeDouble(offsets[4], object.top);
}

TextBlockEntity _textBlockEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TextBlockEntity();
  object.bottom = reader.readDoubleOrNull(offsets[0]);
  object.left = reader.readDoubleOrNull(offsets[1]);
  object.right = reader.readDoubleOrNull(offsets[2]);
  object.text = reader.readStringOrNull(offsets[3]);
  object.top = reader.readDoubleOrNull(offsets[4]);
  return object;
}

P _textBlockEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TextBlockEntityQueryFilter
    on QueryBuilder<TextBlockEntity, TextBlockEntity, QFilterCondition> {
  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  bottomIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'bottom'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  bottomIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'bottom'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  bottomEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'bottom',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  bottomGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bottom',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  bottomLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'bottom',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  bottomBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bottom',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  leftIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'left'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  leftIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'left'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  leftEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'left',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  leftGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'left',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  leftLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'left',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  leftBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'left',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  rightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'right'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  rightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'right'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  rightEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'right',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  rightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'right',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  rightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'right',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  rightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'right',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'text'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'text'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  topIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'top'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  topIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'top'),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  topEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'top',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  topGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'top',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  topLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'top',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TextBlockEntity, TextBlockEntity, QAfterFilterCondition>
  topBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'top',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension TextBlockEntityQueryObject
    on QueryBuilder<TextBlockEntity, TextBlockEntity, QFilterCondition> {}
