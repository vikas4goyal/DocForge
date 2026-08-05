import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/ocr/application/usecases/ocr_usecases.dart';
import 'package:doc_scanly/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_scanly/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _Reader documents;
  late _Writer writer;
  late _PageAccess pages;
  late FakeOcrRepository recogniser;
  late InMemoryOcrTextStore store;
  late ExtractDocumentText extract;

  setUp(() {
    documents = _Reader(
      sampleDocument.copyWith(pageCount: 2, hasRecognisedText: false),
    );
    writer = _Writer();
    pages = _PageAccess(documents.document);
    recogniser = FakeOcrRepository();
    store = InMemoryOcrTextStore();
    extract = ExtractDocumentText(
      documents,
      writer,
      pages,
      recogniser,
      store,
      FixedClock(DateTime.utc(2026, 8, 4)),
    );
  });

  test('embedded text is persisted without rendering or OCR', () async {
    pages.embedded[pages.handles.first.id] = 'Policy heading';
    pages.embedded[pages.handles.last.id] = 'Terms and conditions';

    final events = await extract(
      documents.document.id,
      script: OcrScript.latin,
    ).toList();

    expect(events, hasLength(2));
    expect(recogniser.requested, isEmpty);
    expect(pages.materialized, isEmpty);
    expect(store.texts.values.map((text) => text.plainText), [
      'Policy heading',
      'Terms and conditions',
    ]);
    expect(writer.saved.single.hasRecognisedText, isTrue);
  });

  test('mixed PDF recognises only the page without embedded text', () async {
    pages.embedded[pages.handles.first.id] = 'Embedded first page';

    await extract(documents.document.id, script: OcrScript.latin).toList();

    expect(recogniser.requested, [pages.handles.last.id]);
    expect(pages.materialized, [pages.handles.last.id]);
    expect(pages.releaseCount, 1);
  });

  test('stored results are reused unless force is requested', () async {
    pages.embedded[pages.handles.first.id] = 'First';
    pages.embedded[pages.handles.last.id] = 'Second';
    await extract(documents.document.id, script: OcrScript.latin).toList();
    pages.embeddedCalls = 0;

    await extract(documents.document.id, script: OcrScript.latin).toList();
    expect(pages.embeddedCalls, 0);

    await extract(
      documents.document.id,
      script: OcrScript.latin,
      force: true,
    ).toList();
    expect(pages.embeddedCalls, 2);
  });

  test(
    'blank embedded and OCR text persists as an empty valid result',
    () async {
      recogniser = FakeOcrRepository(
        emptyFor: {for (final page in pages.handles) page.id.value},
      );
      extract = ExtractDocumentText(
        documents,
        writer,
        pages,
        recogniser,
        store,
        FixedClock(DateTime.utc(2026, 8, 4)),
      );

      final events = await extract(
        documents.document.id,
        script: OcrScript.latin,
      ).toList();

      expect(events.every((event) => event.text?.isEmpty ?? false), isTrue);
      expect(store.texts.values, everyElement(isA<RecognisedText>()));
      expect(writer.saved, isEmpty);
    },
  );

  test('pre-cancelled extraction does not read or persist a page', () async {
    final token = CancellationToken()..cancel();

    final events = await extract(
      documents.document.id,
      script: OcrScript.latin,
      token: token,
    ).toList();

    expect(events, isEmpty);
    expect(pages.embeddedCalls, 0);
    expect(store.texts, isEmpty);
  });

  test('unified text source returns virtual pages in page order', () async {
    pages.embedded[pages.handles.first.id] = 'First';
    pages.embedded[pages.handles.last.id] = 'Second';

    final text = await DocumentPageOcrTextSource(
      documents,
      pages,
      store,
      extract,
      () => OcrScript.latin,
    ).textForDocument(documents.document.id);

    expect(text.valueOrNull, 'First\n\nSecond');
  });

  test('unified text source reads one stored page directly', () async {
    final text = RecognisedText(
      pageId: pages.handles.first.id,
      blocks: const [
        TextBlock(
          text: 'Stored policy',
          bounds: NormalisedRect(left: 0, top: 0, right: 1, bottom: 1),
        ),
      ],
      languageTag: 'en',
      recognisedAt: DateTime.utc(2026, 8, 4),
    );
    await store.save(text, documents.document.id);
    final source = DocumentPageOcrTextSource(documents, pages, store);

    final result = await source.textForPage(text.pageId);

    expect(result.valueOrNull, text);
  });

  test('unified text source preserves document lookup failure', () async {
    documents.failure = const Failure.notFound();

    final result = await DocumentPageOcrTextSource(
      documents,
      pages,
      store,
    ).textForDocument(documents.document.id);

    expect(result.failureOrNull, const Failure.notFound());
  });

  test('unified text source preserves page enumeration failure', () async {
    pages.failure = const Failure.corruptFile();

    final result = await DocumentPageOcrTextSource(
      documents,
      pages,
      store,
    ).textForDocument(documents.document.id);

    expect(result.failureOrNull, const Failure.corruptFile());
  });

  test('unified text source preserves initial stored-text failure', () async {
    final broken = InMemoryOcrTextStore(failure: const Failure.storage());

    final result = await DocumentPageOcrTextSource(
      documents,
      pages,
      broken,
    ).textForDocument(documents.document.id);

    expect(result.failureOrNull, const Failure.storage());
  });

  test('unified text source preserves failure after lazy extraction', () async {
    pages.embedded[pages.handles.first.id] = 'First';
    pages.embedded[pages.handles.last.id] = 'Second';
    final delayedFailure = _FailsOnSecondFindAllStore();
    final lazyExtract = ExtractDocumentText(
      documents,
      writer,
      pages,
      recogniser,
      delayedFailure,
      FixedClock(DateTime.utc(2026, 8, 4)),
    );

    final result = await DocumentPageOcrTextSource(
      documents,
      pages,
      delayedFailure,
      lazyExtract,
    ).textForDocument(documents.document.id);

    expect(result.failureOrNull, const Failure.storage());
  });
}

class _Reader implements DocumentReader {
  _Reader(this.document);

  final Document document;
  Failure? failure;

  @override
  Future<Result<Document>> findById(DocumentId id) async => failure == null
      ? Result<Document>.success(document)
      : Result<Document>.failure(failure!);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => Result<List<Document>>.success([document]);
}

class _Writer implements DocumentWriter {
  final List<Document> saved = [];

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    saved.add(document);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async {
    saved.add(document);
    return Result<Document>.success(document);
  }
}

class _PageAccess implements DocumentPageAccessRepository {
  _PageAccess(Document document)
    : handles = List.generate(
        document.pageCount,
        (index) => DocumentPageHandle(
          id: DocumentPageHandle.virtualPdfPageId(document.id, index + 1),
          documentId: document.id,
          pageNumber: index + 1,
          source: const DocumentPageSource.pdfPage(),
        ),
      );

  final List<DocumentPageHandle> handles;
  final Map<PageId, String?> embedded = {};
  final List<PageId> materialized = [];
  int embeddedCalls = 0;
  int releaseCount = 0;
  Failure? failure;

  @override
  Future<Result<String?>> embeddedText(
    Document document,
    DocumentPageHandle page,
  ) async {
    embeddedCalls += 1;
    return Result<String?>.success(embedded[page.id]);
  }

  @override
  Future<Result<MaterializedDocumentPage>> materialize(
    Document document,
    DocumentPageHandle page,
    DocumentPageRenderPurpose purpose,
  ) async {
    materialized.add(page.id);
    return Result<MaterializedDocumentPage>.success(
      MaterializedDocumentPage.temporary(path: '/tmp/${page.id.value}.png'),
    );
  }

  @override
  Future<Result<List<DocumentPageHandle>>> pagesOf(Document document) async =>
      failure == null
      ? Result<List<DocumentPageHandle>>.success(handles)
      : Result<List<DocumentPageHandle>>.failure(failure!);

  @override
  Future<Result<void>> release(MaterializedDocumentPage page) async {
    releaseCount += 1;
    return const Result<void>.success(null);
  }
}

class _FailsOnSecondFindAllStore implements OcrTextStore {
  final delegate = InMemoryOcrTextStore();
  var findAllCalls = 0;

  @override
  Future<Result<Map<PageId, RecognisedText>>> findAll(
    List<PageId> pageIds,
  ) async {
    findAllCalls += 1;
    return findAllCalls == 1
        ? const Result<Map<PageId, RecognisedText>>.success({})
        : const Result<Map<PageId, RecognisedText>>.failure(Failure.storage());
  }

  @override
  Future<Result<RecognisedText?>> find(PageId pageId) => delegate.find(pageId);

  @override
  Future<Result<void>> save(RecognisedText text, DocumentId documentId) =>
      delegate.save(text, documentId);

  @override
  Future<Result<void>> remove(PageId pageId) => delegate.remove(pageId);

  @override
  Future<Result<void>> removeAll(List<PageId> pageIds) =>
      delegate.removeAll(pageIds);

  @override
  Future<Result<void>> removeForDocument(DocumentId documentId) =>
      delegate.removeForDocument(documentId);
}
