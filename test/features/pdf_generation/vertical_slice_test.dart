/// The vertical-slice integration test.
///
/// Runs the whole document-creation pipeline against real components — a real
/// Isar database, real image processing, a real PDF composer, real repositories
/// — with exactly two things faked, at the repository boundary the spec names:
/// the camera and the OCR engine. Neither can run on a test VM, and neither is
/// what this test is about.
///
/// What it proves is that the parts fit together: a capture becomes a cropped,
/// enhanced, recognised page; that page becomes a searchable PDF; that PDF
/// becomes a document record; and the document appears at the top of Recent.
@Tags(['isar'])
library;

import 'dart:io';

import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_forge/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_forge/features/document_scanning/domain/perspective_transform.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/page_correction_job.dart';
import 'package:doc_forge/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_forge/features/image_enhancement/infrastructure/enhancement_job.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/infrastructure/pdf_composer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:isar_community/isar.dart';

/// A secure store held in memory.
class _InMemorySecureStore implements SecureStore {
  final _values = <String, String>{};

  @override
  Future<Result<String?>> read(String key) async =>
      Result<String?>.success(_values[key]);

  @override
  Future<Result<void>> write(String key, String value) async {
    _values[key] = value;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _values.remove(key);
    return const Result<void>.success(null);
  }
}

/// Writes a page-like image, so the pipeline has real pixels to work on.
void writeCapture(String path) {
  const width = 900;
  const height = 1200;
  final image = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      // Lighting falls off to the right, which shadow removal has to correct.
      final illumination = 0.6 + 0.4 * (1 - x / width);
      final onText = y % 18 < 5 && x > width * 0.12 && x < width * 0.88;
      final shade = ((onText ? 40 : 225) * illumination).round();
      image.setPixelRgba(x, y, shade, shade, shade, 255);
    }
  }

  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 92));
}

void main() {
  late Directory root;
  late Directory staging;
  late Directory documents;
  late Isar isar;
  late FilesystemPublicFileStore publicStore;
  late LibraryModule library;
  late DocumentCreationModule creation;
  late FakeScannerRepository scanner;
  late FakeOcrRepository recogniser;

  final clock = FixedClock(DateTime.utc(2026, 3, 14, 9, 30));

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    root = Directory.systemTemp.createTempSync('docforge_slice');
    staging = Directory('${root.path}/staging')..createSync();
    documents = Directory('${root.path}/documents')..createSync();

    isar = await Isar.open([
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      OcrTextEntitySchema,
    ], directory: root.path);

    publicStore = FilesystemPublicFileStore(documents);
    await publicStore.initialise();

    library = buildLibraryModuleOver(
      isar: isar,
      documentsDirectory: documents,
      store: publicStore,
      preferences: InMemoryPreferenceStore(),
      // Reconciliation reads the page count of a file it has never seen;
      // a fixed answer keeps these tests off a real renderer.
      pageCountOf: (path, {String? password}) async =>
          const Result<int>.success(1),
      clock: clock,
      ids: SequentialIdGenerator(prefix: 'doc'),
      secureStorage: _InMemorySecureStore(),
    );

    scanner = FakeScannerRepository(
      ids: SequentialIdGenerator(prefix: 'page'),
      directory: staging,
    );
    recogniser = FakeOcrRepository();

    creation = buildDocumentCreationModule(
      // Inline so composition runs the real enhancement path without isolates.
      applyEnhancement: const ApplyEnhancement(
        InlineBackgroundWorker(),
        enhancePageJob,
      ),
      isar: isar,
      workingDirectory: documents,
      publicStore: publicStore,
      clock: clock,
      ids: SequentialIdGenerator(prefix: 'doc'),
      documentReader: library.documentReader,
      documentWriter: library.documentWriter,
      namingPattern: () => NamingPattern.dateOnly,
      // Inline rather than isolate-backed: an isolate cannot be spawned from a
      // test VM with a closure over this test's state, and what is under test
      // is the pipeline, not where it runs.
      composer: const InlinePdfComposer(),
      recogniser: recogniser,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// Captures [count] pages through the real capture use case.
  Future<List<CapturedPage>> capture(int count) async {
    final capturePage = CapturePage(scanner, const FullPageEdgeDetector());
    final pages = <CapturedPage>[];

    await scanner.initialise();

    for (var index = 0; index < count; index++) {
      final result = await capturePage();
      final page = (result as Success<CapturedPage>).value;
      // The fake writes an empty file; give it real pixels so enhancement and
      // composition have something to work on.
      writeCapture(page.imagePath);
      pages.add(page);
    }

    return pages;
  }

  test(
    'scan, crop, enhance, recognise, generate, save, appear in Recent',
    () async {
      // --- Capture -----------------------------------------------------------
      final captured = await capture(3);
      expect(captured, hasLength(3));

      // --- Review: rotate one page and reorder ------------------------------
      final rotatedId = captured[1].id;
      var reviewed = ScanSessionRules.rotate(captured, 1);
      reviewed = ScanSessionRules.reorder(reviewed, 2, 0);

      // Asserted by identity, not by position: the reorder moved the rotated
      // page, and checking index 1 would be checking a different page.
      expect(
        reviewed.firstWhere((page) => page.id == rotatedId).rotation,
        isNot(PageRotation.none),
      );
      expect(reviewed.first.id, captured[2].id);

      // --- Crop: straighten the first page ----------------------------------
      const correct = ApplyPerspectiveCorrection(
        InlineBackgroundWorker(),
        correctPageJob,
      );
      const cropped = PageQuad(
        topLeft: NormalisedPoint(x: 0.06, y: 0.05),
        topRight: NormalisedPoint(x: 0.94, y: 0.08),
        bottomRight: NormalisedPoint(x: 0.92, y: 0.95),
        bottomLeft: NormalisedPoint(x: 0.05, y: 0.92),
      );

      final correctedPath = await correct.single(
        PageCorrectionRequest.forQuad(
          sourcePath: reviewed.first.imagePath,
          destinationPath: '${reviewed.first.imagePath}.cropped.jpg',
          quad: cropped,
        ),
      );

      expect(correctedPath, isA<Success<String>>());
      reviewed[0] = reviewed.first.copyWith(
        imagePath: (correctedPath as Success<String>).value,
        quad: cropped,
        isCorrected: true,
      );
      expect(File(reviewed.first.imagePath).existsSync(), isTrue);

      // --- Enhance: apply a filter to every page -----------------------------
      var pages = [for (final page in reviewed) page.toPageRef()];
      const settings = EnhancementSettings(
        filter: EnhancementFilter.autoEnhance,
        shadowRemoval: true,
      );
      pages = EnhancementRules.applyToAll(pages, settings);

      const enhance = ApplyEnhancement(
        InlineBackgroundWorker(),
        enhancePageJob,
      );
      const plan = PlanSessionEnhancement();
      final requests = plan(
        pages,
        destinationFor: (page) => '${page.imagePath}.enhanced.jpg',
      );
      expect(requests, hasLength(3));

      final events = await enhance.batch(requests).toList();
      expect(events.whereType<BatchItemCompleted<String>>(), hasLength(3));

      pages = [
        for (var index = 0; index < pages.length; index++)
          pages[index].copyWith(imagePath: requests[index].destinationPath),
      ];
      for (final page in pages) {
        expect(File(page.imagePath).existsSync(), isTrue);
      }

      // --- Recognise ---------------------------------------------------------
      final recognitionEvents = await creation
          .recogniseText(
            pages,
            documentId: const DocumentId('pending'),
            script: OcrScript.latin,
          )
          .toList();

      expect(recognitionEvents, hasLength(3));
      expect(recognitionEvents.every((event) => event.isSuccess), isTrue);

      // --- Generate and save -------------------------------------------------
      final saved = await creation.pageBundleSink.createDocument(
        ScannedPageBundle(pages: pages, source: PageSource.camera),
      );

      final document = (saved as Success<Document>).value;

      expect(document.title, 'Scan 2026-03-14');
      expect(document.pageCount, 3);
      expect(document.sizeInBytes, greaterThan(0));
      final published = File(
        '${documents.path}/DocForge/${document.relativePath}',
      );
      expect(published.existsSync(), isTrue);
      // A real PDF, not a stub.
      expect(published.readAsBytesSync().take(5).toList(), '%PDF-'.codeUnits);

      // --- The document is in the library, in order --------------------------
      final stored = await library.documentReader.findById(document.id);
      expect((stored as Success<Document>).value.title, 'Scan 2026-03-14');

      final storedPages = await library.documentReader.pagesOf(document.id);
      expect(
        (storedPages as Success<List<DocumentPage>>).value.map((p) => p.order),
        [0, 1, 2],
      );

      // --- And at the top of Recent on Home ----------------------------------
      final home = await LoadHomeData(
        library.documentReader,
        library.folderReader,
        library.storageSummaryReader,
      )();

      final data = (home as Success<HomeData>).value;
      expect(data.isEmpty, isFalse);
      expect(data.recentDocuments.first.id, document.id);
      expect(data.storage.documentCount, 1);
    },
  );

  test('the document is searchable: its recognised text is stored', () async {
    final captured = await capture(1);
    for (final page in captured) {
      writeCapture(page.imagePath);
    }
    final pages = [for (final page in captured) page.toPageRef()];

    final saved = await creation.pageBundleSink.createDocument(
      ScannedPageBundle(pages: pages, source: PageSource.camera),
    );
    final document = (saved as Success<Document>).value;

    await creation
        .recogniseText(pages, documentId: document.id, script: OcrScript.latin)
        .toList();

    final text = await creation.ocrTextSource.textForDocument(document.id);

    expect((text as Success<String>).value, contains('INVOICE'));
  });

  test('a document with no recognised text is still created', () async {
    // The spec is explicit: OCR failure must not prevent a document existing.
    final captured = await capture(2);
    for (final page in captured) {
      writeCapture(page.imagePath);
    }

    final saved = await creation.pageBundleSink.createDocument(
      ScannedPageBundle(
        pages: [for (final page in captured) page.toPageRef()],
        source: PageSource.camera,
      ),
    );

    final document = (saved as Success<Document>).value;
    expect(document.pageCount, 2);
    expect(
      File('${documents.path}/DocForge/${document.relativePath}').existsSync(),
      isTrue,
    );
  });

  test('the PDF is published and the captures stay private', () async {
    final captured = await capture(1);
    writeCapture(captured.single.imagePath);

    final saved = await creation.pageBundleSink.createDocument(
      ScannedPageBundle(
        pages: [captured.single.toPageRef()],
        source: PageSource.camera,
      ),
    );

    final document = (saved as Success<Document>).value;

    // The finished PDF goes into the user-visible library folder — that is the
    // point of it. The captures it was built from stay in private staging.
    expect(
      File('${documents.path}/DocForge/${document.relativePath}').existsSync(),
      isTrue,
    );
    expect(captured.single.imagePath, startsWith(staging.path));
  });
}
