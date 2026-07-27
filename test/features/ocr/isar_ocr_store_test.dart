/// Tests the Isar-backed recognised-text store against a real database.
@Tags(['isar'])
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/isar_ocr_text_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

const _document = DocumentId('doc-1');
const _other = DocumentId('doc-2');

RecognisedText textFor(
  String pageId, {
  List<String> lines = const ['Invoice 2026', 'Total due 240.00'],
  DocumentId? owner,
}) => RecognisedText(
  pageId: PageId(pageId),
  blocks: [
    for (var index = 0; index < lines.length; index++)
      TextBlock(
        text: lines[index],
        bounds: NormalisedRect(
          left: 0.1,
          top: 0.1 + index * 0.1,
          right: 0.9,
          bottom: 0.16 + index * 0.1,
        ),
      ),
  ],
  languageTag: 'la',
  // A local instant deliberately: the store has to normalise it, and a value
  // already in UTC would let a missing conversion pass unnoticed.
  recognisedAt: DateTime(2026, 3, 14, 9, 30),
);

void main() {
  late Directory directory;
  late Isar isar;
  late IsarOcrTextStore store;

  setUpAll(() async {
    // Isar needs its native binaries; on a test VM they are downloaded once to
    // a temp location rather than bundled with the app.
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('docforge_ocr_isar');
    isar = await Isar.open([OcrTextEntitySchema], directory: directory.path);
    store = IsarOcrTextStore(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  group('storing and reading', () {
    test('a stored result comes back with its text and boxes', () async {
      await store.save(textFor('a'), _document);

      final result = await store.find(const PageId('a'));
      final text = result.valueOrNull!;

      expect(text.blocks, hasLength(2));
      expect(text.blocks.first.text, 'Invoice 2026');
      expect(text.blocks.first.bounds.left, closeTo(0.1, 0.0001));
    });

    test(
      'a page never recognised is a successful null, not a failure',
      () async {
        final result = await store.find(const PageId('never'));

        expect(result, isA<Success<RecognisedText?>>());
        expect(result.valueOrNull, isNull);
      },
    );

    test('an empty result round-trips as empty', () async {
      await store.save(
        RecognisedText.empty(
          pageId: const PageId('blank'),
          languageTag: 'la',
          recognisedAt: DateTime.utc(2026),
        ),
        _document,
      );

      final result = await store.find(const PageId('blank'));

      expect(result.valueOrNull!.isEmpty, isTrue);
    });

    test(
      'saving the same page twice replaces rather than duplicates',
      () async {
        await store.save(textFor('a'), _document);
        await store.save(textFor('a', lines: ['Second reading']), _document);

        final result = await store.find(const PageId('a'));

        expect(result.valueOrNull!.plainText, 'Second reading');
        expect(await isar.ocrTextEntitys.count(), 1);
      },
    );

    test('the recognised timestamp is stored and returned in UTC', () async {
      // Isar returns local time on read. A document recognised in one timezone
      // must not appear to move when the device travels.
      await store.save(textFor('a'), _document);

      final result = await store.find(const PageId('a'));

      expect(result.valueOrNull!.recognisedAt.isUtc, isTrue);
      expect(
        result.valueOrNull!.recognisedAt,
        DateTime(2026, 3, 14, 9, 30).toUtc(),
      );
    });

    test('the language tag survives the round trip', () async {
      await store.save(textFor('a'), _document);

      expect(
        (await store.find(const PageId('a'))).valueOrNull!.languageTag,
        'la',
      );
    });
  });

  group('batch reads', () {
    test('returns every stored page requested', () async {
      await store.save(textFor('a'), _document);
      await store.save(textFor('b'), _document);

      final result = await store.findAll([
        const PageId('a'),
        const PageId('b'),
      ]);

      expect(result.valueOrNull, hasLength(2));
    });

    test('omits pages with no stored result', () async {
      await store.save(textFor('a'), _document);

      final result = await store.findAll([
        const PageId('a'),
        const PageId('missing'),
      ]);

      expect(result.valueOrNull!.keys.map((id) => id.value), ['a']);
    });

    test('an empty request does no query', () async {
      final result = await store.findAll(const []);

      expect(result.valueOrNull, isEmpty);
    });
  });

  group('the word index', () {
    test('tokenises the recognised text for search', () async {
      await store.save(textFor('a'), _document);

      final row = await isar.ocrTextEntitys.where().findFirst();

      expect(row!.words, containsAll(['invoice', '2026', 'total', 'due']));
    });

    test('lower-cases so search is case-insensitive', () async {
      await store.save(textFor('a', lines: ['ACME Limited']), _document);

      final row = await isar.ocrTextEntitys.where().findFirst();

      expect(row!.words, contains('acme'));
      expect(row.words, isNot(contains('ACME')));
    });

    test('drops punctuation, matching how titles are tokenised', () async {
      // The two indexes are queried together, so a term matching a title has to
      // tokenise the same way against page text.
      await store.save(textFor('a', lines: ['Invoice — Acme Ltd.']), _document);

      final row = await isar.ocrTextEntitys.where().findFirst();

      expect(row!.words, containsAll(['invoice', 'acme', 'ltd']));
    });

    test('keeps the full text so search can build a snippet', () async {
      // Reassembling a snippet from an unordered word list is not possible.
      await store.save(textFor('a'), _document);

      final row = await isar.ocrTextEntitys.where().findFirst();

      expect(row!.searchableText, contains('invoice 2026'));
    });

    test('a re-run refreshes the index rather than leaving it stale', () async {
      await store.save(textFor('a'), _document);
      await store.save(textFor('a', lines: ['Receipt']), _document);

      final row = await isar.ocrTextEntitys.where().findFirst();

      expect(row!.words, contains('receipt'));
      expect(row.words, isNot(contains('invoice')));
    });
  });

  group('removal', () {
    test('removes one page', () async {
      await store.save(textFor('a'), _document);
      await store.save(textFor('b'), _document);

      await store.remove(const PageId('a'));

      expect((await store.find(const PageId('a'))).valueOrNull, isNull);
      expect((await store.find(const PageId('b'))).valueOrNull, isNotNull);
    });

    test('removes several pages at once', () async {
      await store.save(textFor('a'), _document);
      await store.save(textFor('b'), _document);

      await store.removeAll([const PageId('a'), const PageId('b')]);

      expect(await isar.ocrTextEntitys.count(), 0);
    });

    test('an empty removal is a no-op', () async {
      await store.save(textFor('a'), _document);

      await store.removeAll(const []);

      expect(await isar.ocrTextEntitys.count(), 1);
    });

    test('removes a whole document\'s text', () async {
      // What permanent removal calls. Recognised text is document content:
      // leaving it behind would keep readable names and amounts for a document
      // the user believes they deleted.
      await store.save(textFor('a'), _document);
      await store.save(textFor('b'), _document);
      await store.save(textFor('c'), _other);

      await store.removeForDocument(_document);

      expect(await isar.ocrTextEntitys.count(), 1);
      expect((await store.find(const PageId('c'))).valueOrNull, isNotNull);
    });

    test('removing a document with no text succeeds', () async {
      expect(
        await store.removeForDocument(const DocumentId('never')),
        isA<Success<void>>(),
      );
    });
  });

  group('the schema', () {
    test('stamps its version on every row', () async {
      await store.save(textFor('a'), _document);

      final row = await isar.ocrTextEntitys.where().findFirst();

      expect(row!.schemaVersion, ocrSchemaVersion);
    });

    test('records the owning document on every row', () async {
      await store.save(textFor('a'), _document);

      final row = await isar.ocrTextEntitys.where().findFirst();

      expect(row!.documentUuid, _document.value);
    });

    test(
      'a block with missing coordinates reads as an unplaceable box',
      () async {
        // Isar's embedded objects must have nullable fields, so "impossible"
        // nulls are representable even though nothing writes them. A row from a
        // future schema is better read as unplaceable than as a crash on open.
        final entity = OcrTextEntity()
          ..pageUuid = 'partial'
          ..documentUuid = _document.value
          ..blocks = [TextBlockEntity()..text = 'no box']
          ..words = ['no', 'box']
          ..searchableText = 'no box'
          ..languageTag = 'la'
          ..recognisedAt = DateTime.utc(2026)
          ..schemaVersion = ocrSchemaVersion;

        await isar.writeTxn(() => isar.ocrTextEntitys.put(entity));

        final result = await store.find(const PageId('partial'));

        expect(result.valueOrNull!.blocks.single.bounds.isValid, isFalse);
      },
    );
  });
}
