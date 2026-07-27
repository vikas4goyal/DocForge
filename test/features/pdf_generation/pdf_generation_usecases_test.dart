/// Tests the PDF generation use cases.
///
/// The composer is faked here: what these tests are about is ordering and
/// cleanup — that no partial record survives a failure and no orphaned file
/// survives a cancellation — none of which needs a real PDF. Composition itself
/// is covered in `pdf_composer_test.dart`.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_support.dart';

/// A recognition step that does nothing.
///
/// The sink runs recognition before composing so the text layer is in the store
/// by the time the composer reads it; these tests are about naming and
/// ordering, not about OCR.
Future<void> _noRecognition(List<PageRef> pages, DocumentId documentId) async {}

void main() {
  late FakePdfComposer composer;
  late RecordingDocumentWriter writer;
  late List<String> deleted;
  late SaveDocument save;

  final clock = FixedClock(DateTime.utc(2026, 3, 14, 9, 30));
  final ids = SequentialIdGenerator(prefix: 'doc');

  setUp(() {
    composer = FakePdfComposer();
    writer = RecordingDocumentWriter();
    deleted = [];
    save = SaveDocument(
      BuildSearchablePdf(composer, (_) async => const {}),
      writer,
      clock,
      ids,
      (id) => '/documents/${id.value}.pdf',
      (path) async => deleted.add(path),
    );
  });

  ScannedPageBundle bundle({int pages = 3}) => ScannedPageBundle(
    pages: [
      for (var index = 0; index < pages; index++)
        PageRef(id: PageId('page-$index'), imagePath: '/page-$index.jpg'),
    ],
    source: PageSource.camera,
  );

  group('BuildSearchablePdf', () {
    test('composes the pages it is given, in order', () async {
      final build = BuildSearchablePdf(composer, (_) async => const {});

      await build(bundle().pages, destinationPath: '/out.pdf');

      expect(composer.requests.single.pages.map((page) => page.imagePath), [
        '/page-0.jpg',
        '/page-1.jpg',
        '/page-2.jpg',
      ]);
    });

    test('attaches recognised text as a layer', () async {
      final build = BuildSearchablePdf(
        composer,
        (ids) async => {
          'page-0': RecognisedText(
            pageId: const PageId('page-0'),
            blocks: const [
              TextBlock(
                text: 'Invoice',
                bounds: NormalisedRect(
                  left: 0.1,
                  top: 0.1,
                  right: 0.5,
                  bottom: 0.16,
                ),
              ),
            ],
            languageTag: 'la',
            recognisedAt: DateTime.utc(2026),
          ),
        },
      );

      await build(bundle().pages, destinationPath: '/out.pdf');

      expect(composer.requests.single.pages.first.hasTextLayer, isTrue);
      expect(composer.requests.single.isSearchable, isTrue);
    });

    test('still composes when the text lookup fails', () async {
      // The spec states outright that a PDF must be produced when OCR is
      // unavailable. A failed lookup degrades to an unsearchable document, not
      // to no document.
      final build = BuildSearchablePdf(
        composer,
        (_) async => throw StateError('the text store is unavailable'),
      );

      final result = await build(bundle().pages, destinationPath: '/out.pdf');

      expect(result, isA<Success<ComposedPdf>>());
      expect(composer.requests.single.isSearchable, isFalse);
    });

    test('passes the quality through', () async {
      final build = BuildSearchablePdf(composer, (_) async => const {});

      await build(
        bundle().pages,
        destinationPath: '/out.pdf',
        quality: PdfQuality.high,
      );

      expect(composer.requests.single.quality, PdfQuality.high);
    });

    test('a token cancelled before it starts composes nothing', () async {
      final build = BuildSearchablePdf(composer, (_) async => const {});
      final token = CancellationToken()..cancel();

      final result = await build(
        bundle().pages,
        destinationPath: '/out.pdf',
        token: token,
      );

      expect(result, isA<Failed<ComposedPdf>>());
      expect(composer.requests, isEmpty);
    });
  });

  group('SaveDocument', () {
    test('writes the record only after the PDF exists', () async {
      await save(bundle(), title: 'Invoice 2026');

      // A record written first would leave a document the user can see but not
      // open if composition then failed.
      expect(composer.requests, hasLength(1));
      expect(writer.saved, hasLength(1));
    });

    test(
      'records the title, page count and size from the composed file',
      () async {
        composer.result = const ComposedPdf(
          filePath: '/documents/doc-1.pdf',
          sizeInBytes: 40960,
          pageCount: 3,
        );

        final result = await save(bundle(), title: 'Invoice 2026');
        final document = (result as Success<Document>).value;

        expect(document.title, 'Invoice 2026');
        expect(document.pageCount, 3);
        expect(document.sizeInBytes, 40960);
        expect(document.filePath, '/documents/doc-1.pdf');
      },
    );

    test(
      'stamps creation and modification times from the clock, in UTC',
      () async {
        final result = await save(bundle(), title: 'Invoice');
        final document = (result as Success<Document>).value;

        expect(document.createdAt, DateTime.utc(2026, 3, 14, 9, 30));
        expect(document.updatedAt, document.createdAt);
        expect(document.createdAt.isUtc, isTrue);
      },
    );

    test('writes one page record per page, in order', () async {
      await save(bundle(), title: 'Invoice');

      expect(writer.savedPages.single.map((page) => page.order), [0, 1, 2]);
      expect(writer.savedPages.single.map((page) => page.id.value), [
        'page-0',
        'page-1',
        'page-2',
      ]);
    });

    test('carries each page its rotation and enhancement', () async {
      const rotated = ScannedPageBundle(
        pages: [
          PageRef(
            id: PageId('page-0'),
            imagePath: '/a.jpg',
            rotation: PageRotation.quarter,
            enhancement: EnhancementSettings(
              filter: EnhancementFilter.magicColour,
            ),
          ),
        ],
        source: PageSource.camera,
      );

      await save(rotated, title: 'Invoice');

      final page = writer.savedPages.single.single;
      expect(page.rotation, PageRotation.quarter);
      expect(page.enhancement.filter, EnhancementFilter.magicColour);
    });

    test('refuses a bundle with no pages', () async {
      // The library forbids a document with no pages, and refusing here means
      // the refusal is a validation the user can act on rather than a database
      // constraint surfacing as an internal error.
      final result = await save(
        ScannedPageBundle.empty(PageSource.camera),
        title: 'Empty',
      );

      expect((result as Failed<Document>).failure, isA<ValidationFailure>());
      expect(composer.requests, isEmpty);
      expect(writer.saved, isEmpty);
    });

    test('a composition failure creates no record', () async {
      composer.failure = const Failure.pdf();

      final result = await save(bundle(), title: 'Invoice');

      expect(result, isA<Failed<Document>>());
      expect(writer.saved, isEmpty);
    });

    test(
      'a composition failure deletes nothing, because nothing was written',
      () async {
        composer.failure = const Failure.pdf();

        await save(bundle(), title: 'Invoice');

        expect(deleted, isEmpty);
      },
    );

    test('a failed record write deletes the orphaned PDF', () async {
      // An orphaned file in app-private storage is invisible to the user and
      // never reclaimed, which is worse than none.
      writer.failure = const Failure.storage();

      final result = await save(bundle(), title: 'Invoice');

      expect(result, isA<Failed<Document>>());
      // The exact identifier is generated, so the assertion is on the shape:
      // exactly one file, the one just composed.
      expect(deleted, hasLength(1));
      expect(deleted.single, composer.requests.single.destinationPath);
    });

    test(
      'cancelling after composition removes the file and writes no record',
      () async {
        final token = CancellationToken();
        composer.onCompose = token.cancel;

        final result = await save(bundle(), title: 'Invoice', token: token);

        expect((result as Failed<Document>).failure, isA<CancelledFailure>());
        expect(writer.saved, isEmpty);
        expect(deleted, hasLength(1));
      },
    );

    test('cancelling before composition writes and deletes nothing', () async {
      final token = CancellationToken()..cancel();

      final result = await save(bundle(), title: 'Invoice', token: token);

      expect(result, isA<Failed<Document>>());
      expect(composer.requests, isEmpty);
      expect(writer.saved, isEmpty);
      expect(deleted, isEmpty);
    });

    test('a storage-full composition surfaces as such', () async {
      composer.failure = const Failure.storageFull();

      final result = await save(bundle(), title: 'Invoice');

      expect((result as Failed<Document>).failure, isA<StorageFullFailure>());
    });

    test('files the document into a folder when asked', () async {
      final result = await save(
        bundle(),
        title: 'Invoice',
        folderId: const FolderId('folder-1'),
      );

      expect(
        (result as Success<Document>).value.folderId,
        const FolderId('folder-1'),
      );
    });
  });

  group('GenerateDocumentName', () {
    late GenerateDocumentName generate;

    // A *local* instant, because a generated name uses local time — a user
    // naming a scan at half past nine expects "09.30", not the UTC equivalent.
    // The stored timestamps are separately asserted to be UTC above.
    final localClock = FixedClock(DateTime(2026, 3, 14, 9, 30));

    setUp(() {
      generate = GenerateDocumentName(localClock, StubDocumentReader(count: 4));
    });

    test('expands the configured pattern', () async {
      expect(
        await generate(NamingPattern.dateAndTime),
        'Scan 2026-03-14 09.30',
      );
    });

    test('sequential counts on from the library', () async {
      expect(await generate(NamingPattern.sequential), 'Scan 5');
    });

    test('what the user typed wins over everything', () async {
      expect(
        await generate(
          NamingPattern.dateAndTime,
          suggested: 'From a file',
          entered: 'My receipt',
        ),
        'My receipt',
      );
    });

    test('a suggested title wins over the pattern', () async {
      // An imported file's name is more useful than a generated timestamp.
      expect(
        await generate(NamingPattern.dateAndTime, suggested: 'Bank statement'),
        'Bank statement',
      );
    });

    test('a blank entry falls through to the pattern', () async {
      expect(
        await generate(NamingPattern.dateOnly, entered: '   '),
        'Scan 2026-03-14',
      );
    });

    test(
      'a failed count degrades to one rather than failing the save',
      () async {
        // A document named "Scan 1" twice is a nuisance; losing a scan is not.
        final failing = GenerateDocumentName(
          localClock,
          StubDocumentReader(failure: const Failure.storage()),
        );

        expect(await failing(NamingPattern.sequential), 'Scan 1');
      },
    );

    test('only the sequential pattern queries the library', () async {
      final reader = StubDocumentReader(count: 4);
      final counting = GenerateDocumentName(localClock, reader);

      await counting(NamingPattern.dateAndTime);
      expect(reader.queryCount, 0);

      await counting(NamingPattern.sequential);
      expect(reader.queryCount, 1);
    });
  });

  group('PageBundleSinkImpl', () {
    test('creates a document under the generated name', () async {
      final sink = PageBundleSinkImpl(
        save,
        GenerateDocumentName(
          FixedClock(DateTime(2026, 3, 14, 9, 30)),
          StubDocumentReader(),
        ),
        () => NamingPattern.dateOnly,
        _noRecognition,
        SequentialIdGenerator(prefix: 'doc'),
      );

      final result = await sink.createDocument(bundle());

      expect((result as Success<Document>).value.title, 'Scan 2026-03-14');
    });

    test('an explicit title overrides the pattern', () async {
      final sink = PageBundleSinkImpl(
        save,
        GenerateDocumentName(
          FixedClock(DateTime(2026, 3, 14, 9, 30)),
          StubDocumentReader(),
        ),
        () => NamingPattern.dateOnly,
        _noRecognition,
        SequentialIdGenerator(prefix: 'doc'),
      );

      final result = await sink.createDocument(bundle(), title: 'Receipts');

      expect((result as Success<Document>).value.title, 'Receipts');
    });

    test('a bundle carrying its own suggestion uses it', () async {
      final sink = PageBundleSinkImpl(
        save,
        GenerateDocumentName(
          FixedClock(DateTime(2026, 3, 14, 9, 30)),
          StubDocumentReader(),
        ),
        () => NamingPattern.dateOnly,
        _noRecognition,
        SequentialIdGenerator(prefix: 'doc'),
      );

      final result = await sink.createDocument(
        ScannedPageBundle(
          pages: bundle().pages,
          source: PageSource.files,
          suggestedTitle: 'Bank statement',
        ),
      );

      expect((result as Success<Document>).value.title, 'Bank statement');
    });
  });
}
