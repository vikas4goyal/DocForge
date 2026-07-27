/// The Isar collection holding recognised text, and its domain mappers.
///
/// A storage shape, deliberately separate from [RecognisedText]: Isar needs a
/// mutable annotated class with an integer primary key, and it cannot store a
/// list of nested objects without an embedded type. Mapping at the repository
/// boundary keeps that from leaking upward.
///
/// The word index here is what makes recognised text searchable. Isar has no
/// full-text index, so search is implemented the same way document titles are:
/// tokenise on write, store the words as a list, and index its elements so
/// `anyStartsWith` can answer a prefix query.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:isar_community/isar.dart';

part 'ocr_entities.g.dart';

/// Current schema version written to every row.
const ocrSchemaVersion = 1;

/// One recognised text block, stored inside its page's row.
///
/// Embedded rather than a collection of its own: a block is meaningless without
/// its page, is never queried independently, and a separate collection would
/// turn reading one page's text into a join.
@embedded
class TextBlockEntity {
  /// The recognised text.
  String? text;

  /// Left edge in normalised page space.
  double? left;

  /// Top edge in normalised page space.
  double? top;

  /// Right edge in normalised page space.
  double? right;

  /// Bottom edge in normalised page space.
  double? bottom;

  /// Builds a row from [block].
  static TextBlockEntity fromDomain(TextBlock block) => TextBlockEntity()
    ..text = block.text
    ..left = block.bounds.left
    ..top = block.bounds.top
    ..right = block.bounds.right
    ..bottom = block.bounds.bottom;

  /// Converts this row to its domain type.
  ///
  /// Missing coordinates fall back to a zero-area box rather than throwing.
  /// Isar's embedded objects must have nullable fields with no-argument
  /// constructors, so "impossible" nulls are representable in the schema even
  /// though nothing ever writes them; a row from a future schema is better read
  /// as an unplaceable block — which `OcrRules.placeableBlocks` drops — than as
  /// a crash on open.
  TextBlock toDomain() => TextBlock(
    text: text ?? '',
    bounds: NormalisedRect(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    ),
  );
}

/// Isar row holding one page's recognition result.
@collection
class OcrTextEntity {
  /// Isar's local primary key. Never leaves this layer.
  Id id = Isar.autoIncrement;

  /// UUID of the page this text was read from.
  @Index(unique: true, replace: true)
  late String pageUuid;

  /// UUID of the document the page belongs to.
  ///
  /// Denormalised so search can group matches by document, and so permanently
  /// removing a document can delete its recognised text without first loading
  /// its pages.
  @Index()
  late String documentUuid;

  /// The recognised blocks with their positions.
  late List<TextBlockEntity> blocks;

  /// Lower-cased words of the recognised text, indexed for search.
  ///
  /// Derived on write by [wordsOf] so it cannot drift from [blocks].
  @Index(type: IndexType.value, caseSensitive: false)
  late List<String> words;

  /// The full recognised text, lower-cased.
  ///
  /// Held alongside the word index because search has to produce a *snippet*
  /// showing the match in context, and reassembling one from an unordered word
  /// list is not possible.
  late String searchableText;

  /// BCP-47 tag of the script recognition ran with.
  late String languageTag;

  /// When recognition ran, stored in UTC.
  late DateTime recognisedAt;

  /// Schema version this row was written with.
  late int schemaVersion;

  /// Splits [text] into lower-cased searchable words.
  ///
  /// Punctuation is dropped and empty tokens removed, matching how document
  /// titles are tokenised — the two indexes are queried together, so a term
  /// that matches a title must tokenise the same way against page text.
  static List<String> wordsOf(String text) => text
      .toLowerCase()
      .split(RegExp('[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toSet()
      .toList();

  /// Builds a row from [text], belonging to [documentId].
  static OcrTextEntity fromDomain(RecognisedText text, DocumentId documentId) {
    final plain = text.plainText;

    return OcrTextEntity()
      ..pageUuid = text.pageId.value
      ..documentUuid = documentId.value
      ..blocks = [
        for (final block in text.blocks) TextBlockEntity.fromDomain(block),
      ]
      ..words = wordsOf(plain)
      ..searchableText = plain.toLowerCase()
      ..languageTag = text.languageTag
      // Stored in UTC because Isar returns local time on read, and a document
      // recognised in one timezone must not appear to move when the device
      // travels.
      ..recognisedAt = text.recognisedAt.toUtc()
      ..schemaVersion = ocrSchemaVersion;
  }

  /// Converts this row to its domain type.
  RecognisedText toDomain() => RecognisedText(
    pageId: PageId(pageUuid),
    blocks: [for (final block in blocks) block.toDomain()],
    languageTag: languageTag,
    recognisedAt: recognisedAt.toUtc(),
  );
}
