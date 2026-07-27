/// Tests the OCR use cases and the store contract.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/ocr/application/usecases/ocr_usecases.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/mlkit_ocr_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _document = DocumentId('doc-1');

PageRef page(String id) => PageRef(id: PageId(id), imagePath: '/$id.jpg');

DocumentPage documentPage(String id, int order) => DocumentPage(
  id: PageId(id),
  documentId: _document,
  order: order,
  imagePath: '/$id.jpg',
);

void main() {
  late FakeOcrRepository recogniser;
  late InMemoryOcrTextStore store;
  late RecogniseText recognise;

  final pages = [page('a'), page('b'), page('c')];

  setUp(() {
    recogniser = FakeOcrRepository();
    store = InMemoryOcrTextStore();
    recognise = RecogniseText(recogniser, store);
  });

  Future<List<RecognitionEvent>> run({
    bool force = false,
    CancellationToken? token,
    List<PageRef>? over,
  }) => recognise(
    over ?? pages,
    documentId: _document,
    script: OcrScript.latin,
    force: force,
    token: token,
  ).toList();

  group('RecogniseText', () {
    test('recognises every page of a fresh document', () async {
      final events = await run();

      expect(events, hasLength(3));
      expect(events.every((event) => event.isSuccess), isTrue);
    });

    test('persists each result as it is produced', () async {
      await run();

      expect(store.texts.keys.map((id) => id.value), ['a', 'b', 'c']);
    });

    test('records the owning document against each result', () async {
      // Permanently removing a document has to be able to delete its
      // recognised text after its pages are gone, so the link has to be
      // recorded at write time.
      await run();

      expect(store.owners.values, everyElement(_document));
    });

    test('reports progress that reaches the page count', () async {
      final events = await run();

      expect(events.map((event) => event.progress.completed), [1, 2, 3]);
      expect(events.last.progress.total, 3);
    });

    test('does not re-recognise a page that already has a result', () async {
      await run();
      recogniser.requested.clear();

      await run();

      expect(recogniser.requested, isEmpty);
    });

    test('re-recognises everything when forced', () async {
      await run();
      recogniser.requested.clear();

      await run(force: true);

      expect(recogniser.requested, hasLength(3));
    });

    test('a forced run replaces the stored text', () async {
      await run();

      final replacement = FakeOcrRepository(
        blocks: const [
          TextBlock(
            text: 'Second reading',
            bounds: NormalisedRect(
              left: 0.1,
              top: 0.1,
              right: 0.9,
              bottom: 0.2,
            ),
          ),
        ],
      );

      await RecogniseText(replacement, store)(
        pages,
        documentId: _document,
        script: OcrScript.latin,
        force: true,
      ).toList();

      expect(store.texts[const PageId('a')]!.plainText, 'Second reading');
    });

    test(
      'stores an empty result rather than treating it as a failure',
      () async {
        recogniser = FakeOcrRepository(emptyFor: {'b'});
        recognise = RecogniseText(recogniser, store);

        final events = await run();

        expect(events.every((event) => event.isSuccess), isTrue);
        expect(store.texts[const PageId('b')]!.isEmpty, isTrue);
      },
    );

    test('an empty page counts as recognised and is not read again', () async {
      recogniser = FakeOcrRepository(emptyFor: {'b'});
      recognise = RecogniseText(recogniser, store);

      await run();
      recogniser.requested.clear();
      await run();

      expect(recogniser.requested, isEmpty);
    });

    test('a failed page does not stop the run', () async {
      // Unlike an enhancement batch, one unreadable page says nothing about the
      // next, and the spec requires the document to stay usable without text.
      final failing = _FailOnRepository({'b'});
      final events = await RecogniseText(failing, store)(
        pages,
        documentId: _document,
        script: OcrScript.latin,
      ).toList();

      expect(events, hasLength(3));
      expect(events[1].isSuccess, isFalse);
      expect(events[2].isSuccess, isTrue);
    });

    test('a failed page stores nothing for that page', () async {
      final failing = _FailOnRepository({'b'});
      await RecogniseText(failing, store)(
        pages,
        documentId: _document,
        script: OcrScript.latin,
      ).toList();

      expect(store.texts.containsKey(const PageId('b')), isFalse);
    });

    test('recognises with the script it is given', () async {
      await recognise(
        pages,
        documentId: _document,
        script: OcrScript.japanese,
      ).toList();

      expect(
        store.texts.values.first.languageTag,
        OcrScript.japanese.languageTag,
      );
    });

    test('cancelling stops the run and keeps finished pages', () async {
      final token = CancellationToken();
      final events = <RecognitionEvent>[];

      await for (final event in recognise(
        pages,
        documentId: _document,
        script: OcrScript.latin,
        token: token,
      )) {
        events.add(event);
        // Cancelled from inside the run, which is the only way to exercise the
        // check made between pages rather than before the first.
        if (events.length == 1) token.cancel();
      }

      expect(events, hasLength(1));
      // The finished page keeps its result; nothing after it started.
      expect(store.texts.keys.map((id) => id.value), ['a']);
    });

    test('a token cancelled before the run recognises nothing', () async {
      final token = CancellationToken()..cancel();

      expect(await run(token: token), isEmpty);
      expect(recogniser.requested, isEmpty);
    });

    test('a document with no pages completes without work', () async {
      expect(await run(over: const []), isEmpty);
    });

    test('an unreadable store is treated as empty rather than fatal', () async {
      // Worst case every page is recognised again, which is slow but correct.
      // Failing outright would leave a usable document with no text at all.
      final broken = InMemoryOcrTextStore(failure: const Failure.storage());
      final events = await RecogniseText(recogniser, broken)(
        pages,
        documentId: _document,
        script: OcrScript.latin,
      ).toList();

      expect(events, hasLength(3));
    });
  });

  group('LoadRecognisedText', () {
    test('returns what has been stored, keyed by page', () async {
      await run();

      final result = await LoadRecognisedText(store)(pages);

      expect(result.valueOrNull, hasLength(3));
    });

    test('omits pages never recognised', () async {
      await run(over: [page('a')]);

      final result = await LoadRecognisedText(store)(pages);

      expect(result.valueOrNull!.keys.map((id) => id.value), ['a']);
    });

    test('reports a store failure', () async {
      final broken = InMemoryOcrTextStore(failure: const Failure.storage());

      expect(
        await LoadRecognisedText(broken)(pages),
        isA<Failed<Map<PageId, RecognisedText>>>(),
      );
    });
  });

  group('ForgetRecognisedText', () {
    test('removes every result belonging to the document', () async {
      await run();

      await ForgetRecognisedText(store)(_document);

      expect(store.texts, isEmpty);
    });

    test('leaves another document\'s text alone', () async {
      await run();
      await store.save(
        RecognisedText.empty(
          pageId: const PageId('other'),
          languageTag: 'la',
          recognisedAt: DateTime.utc(2026),
        ),
        const DocumentId('doc-2'),
      );

      await ForgetRecognisedText(store)(_document);

      expect(store.texts.keys.map((id) => id.value), ['other']);
    });
  });

  group('OcrTextSourceImpl', () {
    Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
        Result<List<DocumentPage>>.success([
          documentPage('a', 0),
          documentPage('b', 1),
        ]);

    test('returns one page\'s text', () async {
      await run();

      final source = OcrTextSourceImpl(store, pagesOf);
      final result = await source.textForPage(const PageId('a'));

      expect(result.valueOrNull, isNotNull);
    });

    test('returns a successful null for a page never recognised', () async {
      // Absence is a normal state, not an error.
      final source = OcrTextSourceImpl(store, pagesOf);
      final result = await source.textForPage(const PageId('never'));

      expect(result, isA<Success<RecognisedText?>>());
      expect(result.valueOrNull, isNull);
    });

    test('joins a document\'s pages in page order', () async {
      await run();

      final source = OcrTextSourceImpl(store, pagesOf);
      final result = await source.textForDocument(_document);

      expect(result.valueOrNull, contains('INVOICE'));
    });

    test('returns empty text for a document never recognised', () async {
      final source = OcrTextSourceImpl(store, pagesOf);
      final result = await source.textForDocument(_document);

      expect(result.valueOrNull, isEmpty);
    });

    test('reports a page-lookup failure', () async {
      final source = OcrTextSourceImpl(
        store,
        (_) async =>
            const Result<List<DocumentPage>>.failure(Failure.notFound()),
      );

      expect(await source.textForDocument(_document), isA<Failed<String>>());
    });
  });

  group('BundledOcrLanguagePacks', () {
    const packs = BundledOcrLanguagePacks();

    test('reports only the bundled scripts as available', () async {
      final result = await packs.available();

      expect(result.valueOrNull, {OcrScript.latin});
    });

    test(
      'installing a bundled script succeeds without doing anything',
      () async {
        expect(await packs.install(OcrScript.latin), isA<Success<void>>());
      },
    );

    test('installing a script this build does not ship fails', () async {
      // Reported as unavailable rather than offered and then failing at the
      // point of use, which is what the settings screen needs to show.
      expect(await packs.install(OcrScript.japanese), isA<Failed<void>>());
    });
  });
}

/// A recogniser that fails on the named pages and succeeds on the rest.
class _FailOnRepository implements OcrRepository {
  _FailOnRepository(this._failing);

  final Set<String> _failing;

  @override
  Future<Result<RecognisedText>> recognise({
    required PageId pageId,
    required String imagePath,
    required OcrScript script,
  }) async {
    if (_failing.contains(pageId.value)) {
      return const Result<RecognisedText>.failure(Failure.ocr());
    }

    return Result<RecognisedText>.success(
      RecognisedText.empty(
        pageId: pageId,
        languageTag: script.languageTag,
        recognisedAt: DateTime.utc(2026),
      ),
    );
  }

  @override
  Future<void> dispose() async {}
}
