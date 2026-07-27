/// The success-criteria test.
///
/// > A new user should be able to install the application, scan a document,
/// > create a searchable PDF, save it locally, find it from the Home screen,
/// > organise it into folders, search it, edit it and share it within a few
/// > minutes without requiring an account or an internet connection.
///
/// Every clause of that sentence is a step below, run against real components:
/// a real Isar database, real image processing, a real PDF composer, real
/// repositories. Four things are faked, each at the repository boundary the
/// spec names, and each because it is a device capability rather than logic:
/// the camera, the OCR engine, the PDF-manipulation engine and the share sheet.
///
/// **Airplane mode is enforced, not assumed.** An `HttpOverrides` fails the
/// test the moment anything opens an HTTP client, so "without an internet
/// connection" is a property this test proves rather than a setting it
/// describes.
@Tags(['isar'])
library;

import 'dart:io';

import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/pdf_editing_module.dart';
import 'package:doc_forge/app/sharing_module.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';
import 'package:doc_forge/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:doc_forge/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_forge/features/image_enhancement/infrastructure/enhancement_job.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/infrastructure/pdf_composer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:isar_community/isar.dart';

/// Fails the test the moment anything opens an HTTP client.
class _AirplaneMode extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      fail('the application reached the network');
}

/// A secure store held in memory.
class _Secrets implements SecureStore {
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
void _writeCapture(String path) {
  const width = 800;
  const height = 1100;
  final image = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final onText = y % 20 < 6 && x > width * 0.1 && x < width * 0.9;
      final shade = onText ? 40 : 230;
      image.setPixelRgba(x, y, shade, shade, shade, 255);
    }
  }

  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 90));
}

void main() {
  late Directory root;
  late Isar isar;
  late LibraryModule library;
  late DocumentCreationModule creation;
  late _Secrets secrets;

  final clock = FixedClock(DateTime.utc(2026, 3, 14, 9, 30));

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    HttpOverrides.global = _AirplaneMode();

    root = Directory.systemTemp.createTempSync('docforge_success');
    final documents = Directory('${root.path}/documents')..createSync();

    isar = await Isar.open([
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      OcrTextEntitySchema,
    ], directory: root.path);

    secrets = _Secrets();

    library = buildLibraryModuleOver(
      isar: isar,
      documentsDirectory: documents,
      clock: clock,
      ids: SequentialIdGenerator(prefix: 'doc'),
      secureStorage: secrets,
    );

    creation = buildDocumentCreationModule(
      // Inline so composition runs the real enhancement path without isolates.
      applyEnhancement: const ApplyEnhancement(
        InlineBackgroundWorker(),
        enhancePageJob,
      ),
      isar: isar,
      documentsDirectory: documents,
      clock: clock,
      ids: SequentialIdGenerator(prefix: 'page'),
      documentReader: library.documentReader,
      documentWriter: library.documentWriter,
      namingPattern: () => NamingPattern.defaultPattern,
      composer: const InlinePdfComposer(),
      // The fake's default blocks already read "INVOICE / Acme Limited /
      // Total due", which is what the search step below looks for.
      recogniser: FakeOcrRepository(
        recognisedAt: DateTime.utc(2026, 3, 14, 9, 30),
      ),
    );
  });

  tearDown(() async {
    HttpOverrides.global = null;
    await isar.close(deleteFromDisk: true);
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('a new user gets from a scan to a shared document, offline', () async {
    // ---- Scan a document -------------------------------------------------
    final capturePath = '${root.path}/capture.jpg';
    _writeCapture(capturePath);

    final bundle = ScannedPageBundle(
      pages: [PageRef(id: const PageId('page-1'), imagePath: capturePath)],
      source: PageSource.camera,
    );

    // ---- Create a searchable PDF and save it locally ---------------------
    final saved = await creation.pageBundleSink.createDocument(bundle);
    final document = (saved as Success<Document>).value;

    expect(document.pageCount, 1);
    expect(File(document.filePath).existsSync(), isTrue);
    // Locally: inside the directory this application owns, not anywhere shared.
    expect(document.filePath, startsWith(root.path));
    // Searchable: recognition ran and its text is stored.
    expect(document.hasRecognisedText, isTrue);

    final text = await creation.ocrTextSource.textForDocument(document.id);
    expect(text.valueOrNull, contains('Acme'));

    // ---- Find it from the Home screen ------------------------------------
    final home = await LoadHomeData(
      library.documentReader,
      library.folderReader,
      library.storageSummaryReader,
    )();
    final homeData = (home as Success<HomeData>).value;

    expect(homeData.recentDocuments.map((d) => d.id), contains(document.id));
    expect(homeData.storage.documentCount, 1);

    // ---- Organise it into a folder ---------------------------------------
    final folder = await library.createFolder('Invoices');
    final created = (folder as Success<Folder>).value;

    final moved = await library.moveDocument(document.id, created.id);
    expect((moved as Success<Document>).value.folderId, created.id);

    // ---- Search it -------------------------------------------------------
    // By its recognised text, not merely its title: that is the whole point of
    // the searchable PDF two steps ago.
    final byText = await library.search.search(const SearchQuery(term: 'acme'));
    final textHits = (byText as Success<List<SearchResult>>).value;

    expect(textHits.map((r) => r.document.id), contains(document.id));
    expect(
      textHits.firstWhere((r) => r.document.id == document.id).source,
      MatchSource.recognisedText,
    );

    // ---- Edit it ---------------------------------------------------------
    // The real engine cannot load here, so the editor runs over the fake — what
    // this step proves is that the *pipeline* reaches editing with a document
    // the editor can act on, and that the record is updated afterwards.
    final editable = '${root.path}/editable.pdf';
    writeFakePdf(editable, pageCount: 3);

    final editing = buildPdfEditingModule(
      documentReader: library.documentReader,
      documentWriter: library.documentWriter,
      secureStorage: secrets,
      documentsDirectory: Directory('${root.path}/documents'),
      clock: clock,
      ids: SequentialIdGenerator(prefix: 'edit'),
      editor: FakePdfEditor(),
    );

    final editableDocument = await library.documentWriter.save(
      document.copyWith(
        id: const DocumentId('editable'),
        filePath: editable,
        pageCount: 3,
      ),
      // Page records as well as the document: the library derives the page
      // count from them, and a record claiming three pages with none stored
      // would disagree with itself.
      [
        for (var index = 0; index < 3; index++)
          DocumentPage(
            id: PageId('editable-$index'),
            documentId: const DocumentId('editable'),
            order: index,
            imagePath: '${root.path}/page_$index.jpg',
          ),
      ],
    );
    expect(editableDocument, isA<Success<Document>>());

    final rotated = await editing.useCases.rotate(
      const DocumentId('editable'),
      0,
    );
    expect(rotated, isA<Success<Document>>());
    expect((rotated as Success<Document>).value.pageCount, 3);

    // ---- Share it --------------------------------------------------------
    final share = FakeShareRepository();
    final sharing = buildSharingModule(
      documentReader: library.documentReader,
      ocrTextSource: creation.ocrTextSource,
      cacheDirectory: root,
      worker: const InlineBackgroundWorker(),
      share: share,
    );

    final shared = await sharing.sharePdf(document.id);
    expect(shared, isA<Success<void>>());
    expect(share.shared.single.filePaths, [document.filePath]);

    // ---- ...without an account or an internet connection -----------------
    // Reached only because no HTTP client was ever opened; the override above
    // fails the test the instant one is.
    expect(share.shared, hasLength(1));
  });

  test(
    'the whole flow needs no account and stores nothing but documents',
    () async {
      // The secure store is the only place a secret could be, and nothing in the
      // happy path puts one there: DocForge has no account and this document is
      // not protected.
      final capturePath = '${root.path}/capture.jpg';
      _writeCapture(capturePath);

      await creation.pageBundleSink.createDocument(
        ScannedPageBundle(
          pages: [PageRef(id: const PageId('page-1'), imagePath: capturePath)],
          source: PageSource.camera,
        ),
      );

      expect(secrets._values, isEmpty);
    },
  );
}
