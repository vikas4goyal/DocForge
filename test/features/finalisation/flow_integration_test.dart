/// End-to-end tests for the import, PDF-edit and app-lock flows.
///
/// Each runs against a real Isar database and real repositories, with only the
/// device capabilities faked. What they prove is that the *flow* holds together
/// — that a file picked from a browser becomes a document the library can find,
/// that an edit updates the record the list renders from, and that a locked
/// launch reaches the library only after authenticating.
@Tags(['isar'])
library;

import 'dart:io';

import 'package:doc_forge/app/import_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/pdf_editing_module.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_forge/features/app_security/domain/app_lock.dart';
import 'package:doc_forge/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:doc_forge/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_forge/features/document_import/domain/import_rules.dart';
import 'package:doc_forge/features/document_import/infrastructure/repositories/fake_import_sources.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_forge/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  late Directory root;
  late Directory documents;
  late Isar isar;
  late FilesystemPublicFileStore publicStore;
  late LibraryModule library;
  late InMemorySecureStore secrets;

  final clock = FixedClock(DateTime.utc(2026, 3, 14, 9, 30));

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    root = Directory.systemTemp.createTempSync('docforge_flows');
    documents = Directory('${root.path}/documents')..createSync();
    secrets = InMemorySecureStore();

    isar = await Isar.open([
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      TrashEntitySchema,
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
      secureStorage: secrets,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('the import flow', () {
    test(
      'a PDF picked from device files becomes a findable document',
      () async {
        // A PDF the renderer can actually open, so the page count on the record
        // is read from the file rather than asserted into existence.
        final source = '${root.path}/Statement.pdf';
        File(source).writeAsBytesSync(_minimalPdfBytes());

        final importing = buildImportModule(
          renderer: const PdfrxRenderer(),
          documentWriter: library.documentWriter,
          store: publicStore,
          cacheDirectory: root,
          clock: clock,
          ids: SequentialIdGenerator(prefix: 'imported'),
          worker: const InlineBackgroundWorker(),
          files: FakeFileBrowser(paths: [source]),
          shared: FakeSharedContentSource(),
        );

        final picked = await importing.files.pickFiles();
        final paths = (picked as Success<List<String>>).value;

        final events = await importing
            .importFiles(paths, source: ImportSource.files)
            .toList();

        final imported = events.whereType<ImportedDocument>().single.document;

        expect(imported.title, 'Statement');
        expect(imported.pageCount, greaterThan(0));
        // Copied into the library, not referenced where it sat: the source
        // file must survive untouched.
        expect(imported.relativePath, 'Statement.pdf');
        expect(File(source).existsSync(), isTrue);

        // And the library can find it, which is what makes it a document rather
        // than a file.
        final found = await library.documentReader.findById(imported.id);
        expect((found as Success<Document>).value.title, 'Statement');
      },
    );

    test('an unsupported file creates nothing at all', () async {
      final source = '${root.path}/notes.txt';
      File(source).writeAsStringSync('not a document');

      final importing = buildImportModule(
        renderer: const PdfrxRenderer(),
        documentWriter: library.documentWriter,
        store: publicStore,
        cacheDirectory: root,
        clock: clock,
        ids: SequentialIdGenerator(prefix: 'imported'),
        worker: const InlineBackgroundWorker(),
        shared: FakeSharedContentSource(),
      );

      final events = await importing.importFiles([
        source,
      ], source: ImportSource.files).toList();

      expect(events.single, isA<ImportFailed>());

      final all = await library.documentReader.query();
      expect((all as Success<List<Document>>).value, isEmpty);
    });
  });

  group('the PDF-edit flow', () {
    test('an edit updates the record the library renders from', () async {
      // The real engine cannot load here, so the fake supplies page semantics.
      // What this proves is the round trip: library → editor → library.
      // Written into the library folder, which is where a document lives now.
      final path = '${documents.path}/DocForge/editable.pdf';
      Directory(path).parent.createSync(recursive: true);
      writeFakePdf(path, pageCount: 4);

      final saved = await library.documentWriter.save(
        Document(
          id: const DocumentId('editable'),
          title: 'Invoice',
          createdAt: DateTime.utc(2026, 3),
          updatedAt: DateTime.utc(2026, 3),
          pageCount: 4,
          sizeInBytes: File(path).lengthSync(),
          libraryPath: LibraryPath.parse('editable.pdf'),
        ),
        const [],
      );
      expect(saved, isA<Success<Document>>());

      final editing = buildPdfEditingModule(
        documentReader: library.documentReader,
        documentWriter: library.documentWriter,
        secureStorage: secrets,
        store: publicStore,
        workingDirectory: documents,
        clock: FixedClock(DateTime.utc(2026, 6)),
        ids: SequentialIdGenerator(prefix: 'derived'),
        editor: FakePdfEditor(),
      );

      final deleted = await editing.useCases.delete(
        const DocumentId('editable'),
        {0},
      );
      expect(deleted, isA<Success<Document>>());

      final reread = await library.documentReader.findById(
        const DocumentId('editable'),
      );
      final document = (reread as Success<Document>).value;

      expect(document.pageCount, 3);
      // Stamped by the *library's* clock, not the editor's: the library owns
      // modified dates, so two subsystems cannot disagree about when a document
      // last changed. In the running application both come from the same clock.
      expect(document.updatedAt, clock.now());
      expect(fakePdfPages(path), hasLength(3));
    });

    test('a failed edit leaves the stored document untouched', () async {
      // Written into the library folder, which is where a document lives now.
      final path = '${documents.path}/DocForge/editable.pdf';
      Directory(path).parent.createSync(recursive: true);
      writeFakePdf(path, pageCount: 4);
      final before = File(path).readAsStringSync();

      await library.documentWriter.save(
        Document(
          id: const DocumentId('editable'),
          title: 'Invoice',
          createdAt: DateTime.utc(2026, 3),
          updatedAt: DateTime.utc(2026, 3),
          pageCount: 4,
          sizeInBytes: File(path).lengthSync(),
          libraryPath: LibraryPath.parse('editable.pdf'),
        ),
        const [],
      );

      final editing = buildPdfEditingModule(
        documentReader: library.documentReader,
        documentWriter: library.documentWriter,
        secureStorage: secrets,
        store: publicStore,
        workingDirectory: documents,
        clock: clock,
        ids: SequentialIdGenerator(prefix: 'derived'),
        editor: FakePdfEditor(failWith: const Failure.corruptFile()),
      );

      final result = await editing.useCases.rotate(
        const DocumentId('editable'),
        0,
      );

      expect(result, isA<Failed<Document>>());
      expect(File(path).readAsStringSync(), before);

      final reread = await library.documentReader.findById(
        const DocumentId('editable'),
      );
      expect((reread as Success<Document>).value.pageCount, 4);
    });
  });

  group('the app-lock flow', () {
    test('enable, relaunch, authenticate, reach the library', () async {
      final authenticator = FakeDeviceAuthenticator();
      final configuration = SecureAppLockConfiguration(secrets);

      // ---- Enable it, which requires authenticating -----------------------
      final enabled = await SetAppLockEnabled(authenticator, configuration)(
        enabled: true,
      );

      expect((enabled as Success<AuthOutcome>).value, AuthOutcome.succeeded);
      expect(
        (await secrets.read(SecureStorageKeys.appLockEnabled)).valueOrNull,
        'true',
      );

      // ---- Relaunch: a fresh gate over the same storage --------------------
      final gate = AppLockGateImpl(IsAppLockEnabled(configuration));
      addTearDown(gate.dispose);

      expect(gate.isLocked, isTrue, reason: 'unknown must read as locked');
      await gate.load();
      expect(gate.isLocked, isTrue);

      // ---- Authenticate ---------------------------------------------------
      final outcome = await AuthenticateAppLock(authenticator)();
      expect(outcome, AuthOutcome.succeeded);
      gate.markUnlocked();

      expect(gate.isLocked, isFalse);

      // ---- Background and return ------------------------------------------
      await gate.lock();
      expect(gate.isLocked, isTrue);
    });

    test(
      'disabling it also requires authenticating, and then launches are direct',
      () async {
        final configuration = SecureAppLockConfiguration(secrets);
        await configuration.setEnabled(enabled: true);

        final rejecting = FakeDeviceAuthenticator(
          outcome: AuthOutcome.rejected,
        );

        final refused = await SetAppLockEnabled(rejecting, configuration)(
          enabled: false,
        );

        expect((refused as Success<AuthOutcome>).value, AuthOutcome.rejected);
        // Still enabled: a rejected attempt changes nothing.
        expect((await configuration.isEnabled()).valueOrNull, isTrue);

        final accepted = await SetAppLockEnabled(
          FakeDeviceAuthenticator(),
          configuration,
        )(enabled: false);
        expect((accepted as Success<AuthOutcome>).value, AuthOutcome.succeeded);

        final gate = AppLockGateImpl(IsAppLockEnabled(configuration));
        addTearDown(gate.dispose);
        await gate.load();

        expect(gate.isLocked, isFalse);
      },
    );

    test('a purged document takes its password with it', () async {
      final path = '${documents.path}/DocForge/protected.pdf';
      File(path)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('%PDF');

      await library.documentWriter.save(
        Document(
          id: const DocumentId('protected'),
          title: 'Statement',
          createdAt: DateTime.utc(2026, 3),
          updatedAt: DateTime.utc(2026, 3),
          pageCount: 1,
          sizeInBytes: 4,
          libraryPath: LibraryPath.parse('protected.pdf'),
          isProtected: true,
        ),
        const [],
      );

      await secrets.write(
        SecureStorageKeys.pdfPassword('protected'),
        'hunter2',
      );

      await library.purgeDocument(const DocumentId('protected'));

      expect(
        (await secrets.read(
          SecureStorageKeys.pdfPassword('protected'),
        )).valueOrNull,
        isNull,
      );
    });
  });
}

/// The bytes of the smallest PDF a renderer will open.
///
/// Built by hand rather than composed, because this test is about the import
/// flow rather than about PDF generation — and a generated one would make the
/// test depend on the composer it is not exercising.
List<int> _minimalPdfBytes() {
  const pdf = '''
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]>>endobj
trailer<</Root 1 0 R>>
%%EOF
''';

  return pdf.codeUnits;
}
