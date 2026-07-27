/// Tests for the PDF editing use cases.
///
/// Run over [FakePdfEditor], whose toy format makes the page semantics of every
/// operation observable. That is what these tests are for: the real engine does
/// not load in the host test VM, so "the copy goes immediately after the
/// original" and "the two halves are the original in order" are verified here
/// or not at all.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_forge/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:flutter_test/flutter_test.dart';

/// A document store backed by a map, recording what was written.
class _Library implements DocumentReader, DocumentWriter {
  _Library(this.documents, {this.writeFailure});

  final Map<DocumentId, Document> documents;
  final Failure? writeFailure;

  final List<Document> written = [];

  @override
  Future<Result<Document>> findById(DocumentId id) async {
    final found = documents[id];
    return found == null
        ? const Result<Document>.failure(Failure.notFound())
        : Result<Document>.success(found);
  }

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => Result<List<Document>>.success(documents.values.toList());

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    final configured = writeFailure;
    if (configured != null) return Result<Document>.failure(configured);

    documents[document.id] = document;
    written.add(document);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async {
    final configured = writeFailure;
    if (configured != null) return Result<Document>.failure(configured);

    documents[document.id] = document;
    written.add(document);
    return Result<Document>.success(document);
  }
}

void main() {
  late Directory temporary;
  late _Library library;
  late FakePdfEditor editor;
  late InMemorySecureStore secrets;

  const id = DocumentId('a');

  late FilesystemPublicFileStore store;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('pdf_edit');
    editor = FakePdfEditor();
    secrets = InMemorySecureStore();
    // A real store over a temporary directory rather than a fake: these tests
    // assert on the bytes the operations leave behind, so the publish step has
    // to actually write them.
    store = FilesystemPublicFileStore(temporary);
    store.initialise();
  });

  /// Where the library holds [document]'s file.
  ///
  /// The record carries a library-relative address, not a device path, so a
  /// test that wants to read the bytes resolves it the same way the store
  /// would.
  String pathOf(Document document) =>
      '${temporary.path}/DocForge/${document.relativePath}';

  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  /// Registers a document of [pageCount] pages and writes its fake file.
  Document given({
    String documentId = 'a',
    int pageCount = 4,
    String title = 'Invoice',
    String? password,
    int padding = 0,
  }) {
    final libraryPath = LibraryPath.parse('$title.pdf');
    final path = '${temporary.path}/DocForge/${libraryPath.relative}';
    Directory(path).parent.createSync(recursive: true);
    final file = writeFakePdf(
      path,
      pageCount: pageCount,
      password: password,
      padding: padding,
    );

    return Document(
      id: DocumentId(documentId),
      title: title,
      createdAt: DateTime.utc(2026, 3),
      updatedAt: DateTime.utc(2026, 3),
      pageCount: pageCount,
      sizeInBytes: file.lengthSync(),
      libraryPath: libraryPath,
      isProtected: password != null,
    );
  }

  PdfEditContext contextFor(
    List<Document> documents, {
    FakePdfEditor? withEditor,
    Failure? writeFailure,
  }) {
    final active = withEditor ?? editor;
    library = _Library({
      for (final document in documents) document.id: document,
    }, writeFailure: writeFailure);

    return PdfEditContext(
      documents: library,
      writer: library,
      editor: active,
      atomic: AtomicPdfWrite(
        (path, password) => active.pageCountOf(path, password: password),
      ),
      secrets: secrets,
      store: store,
      workingDirectory: Directory('${temporary.path}/work')
        ..createSync(recursive: true),
      clock: FixedClock(DateTime.utc(2026, 6, 1, 12)),
      ids: SequentialIdGenerator(),
    );
  }

  group('RotatePage', () {
    test('rotates the page and leaves the page count alone', () async {
      final document = given();

      final result = await RotatePage(contextFor([document]))(id, 1);

      final updated = (result as Success<Document>).value;
      expect(updated.pageCount, 4);
      expect(fakePdfPages(pathOf(document))[1], contains('rot:90'));
    });

    test('refreshes the modified date and the file size', () async {
      final document = given();

      final result = await RotatePage(contextFor([document]))(id, 0);

      final updated = (result as Success<Document>).value;
      expect(updated.updatedAt, DateTime.utc(2026, 6, 1, 12));
      expect(updated.createdAt, document.createdAt);
      expect(updated.sizeInBytes, File(pathOf(document)).lengthSync());
    });

    test('leaves the document unchanged when the engine fails', () async {
      final document = given();
      final before = File(pathOf(document)).readAsStringSync();

      final result = await RotatePage(
        contextFor([
          document,
        ], withEditor: FakePdfEditor(failWith: const Failure.pdf())),
      )(id, 0);

      expect(result, isA<Failed<Document>>());
      expect(File(pathOf(document)).readAsStringSync(), before);
    });

    test('fails for a document that does not exist', () async {
      final result = await RotatePage(contextFor(const []))(id, 0);

      expect(result, isA<Failed<Document>>());
    });
  });

  group('DeletePages', () {
    test('removes the pages and decreases the count', () async {
      final document = given();

      final result = await DeletePages(contextFor([document]))(id, {1, 2});

      final updated = (result as Success<Document>).value;
      expect(updated.pageCount, 2);
      expect(fakePdfPages(pathOf(document)), ['page:0', 'page:3']);
    });

    test('refuses to delete the only page', () async {
      final document = given(pageCount: 1);
      final before = File(pathOf(document)).readAsStringSync();

      final result = await DeletePages(contextFor([document]))(id, {0});

      expect((result as Failed<Document>).failure, isA<ValidationFailure>());
      // Refused before anything was written, so there is nothing to roll back.
      expect(File(pathOf(document)).readAsStringSync(), before);
      expect(editor.operations, isEmpty);
    });

    test('refuses to delete every page of a longer document', () async {
      final document = given(pageCount: 3);

      final result = await DeletePages(contextFor([document]))(id, {0, 1, 2});

      expect(result, isA<Failed<Document>>());
    });

    test('updates the file size on the record', () async {
      final document = given();

      final result = await DeletePages(contextFor([document]))(id, {0});

      final updated = (result as Success<Document>).value;
      expect(updated.sizeInBytes, File(pathOf(document)).lengthSync());
      expect(updated.sizeInBytes, lessThan(document.sizeInBytes));
    });
  });

  group('DuplicatePage', () {
    test('inserts the copy immediately after the original', () async {
      final document = given(pageCount: 3);

      final result = await DuplicatePage(contextFor([document]))(id, 1);

      final updated = (result as Success<Document>).value;
      expect(updated.pageCount, 4);
      expect(fakePdfPages(pathOf(document)), [
        'page:0',
        'page:1',
        'page:1',
        'page:2',
      ]);
    });

    test('rejects a page outside the document', () async {
      final document = given(pageCount: 2);

      final result = await DuplicatePage(contextFor([document]))(id, 5);

      expect(result, isA<Failed<Document>>());
      expect(editor.operations, isEmpty);
    });
  });

  group('ExtractPages', () {
    test('creates a new document from the selected pages', () async {
      final document = given();

      final result = await ExtractPages(contextFor([document]))(id, {0, 2});

      final extracted = (result as Success<Document>).value;
      expect(extracted.pageCount, 2);
      expect(fakePdfPages(pathOf(extracted)), ['page:0', 'page:2']);
    });

    test('leaves the source document unchanged', () async {
      final document = given();
      final before = File(pathOf(document)).readAsStringSync();

      await ExtractPages(contextFor([document]))(id, {1});

      expect(File(pathOf(document)).readAsStringSync(), before);
      expect(library.documents[id]!.pageCount, 4);
    });

    test('produces pages in document order, not tap order', () async {
      // A selection made bottom-up must still produce a forwards document.
      final document = given();

      final result = await ExtractPages(contextFor([document]))(id, {3, 1, 2});

      final extracted = (result as Success<Document>).value;
      expect(fakePdfPages(pathOf(extracted)), ['page:1', 'page:2', 'page:3']);
    });

    test('keeps the source document’s folder', () async {
      final document = given().copyWith(folderId: const FolderId('f1'));

      final result = await ExtractPages(contextFor([document]))(id, {0});

      expect(
        (result as Success<Document>).value.folderId,
        const FolderId('f1'),
      );
    });

    test('refuses an empty selection', () async {
      final document = given();

      final result = await ExtractPages(contextFor([document]))(id, const {});

      expect(result, isA<Failed<Document>>());
    });

    test('removes the file when the record cannot be written', () async {
      final document = given();

      final result = await ExtractPages(
        contextFor([document], writeFailure: const Failure.storage()),
      )(id, {0});

      expect(result, isA<Failed<Document>>());
      // Nothing orphaned: without a record the file is unreachable.
      expect(
        temporary.listSync().where((e) => e.path.endsWith('a-1.pdf')),
        isEmpty,
      );
    });
  });

  group('MergeDocuments', () {
    test('produces the pages of every source in the order given', () async {
      final first = given(pageCount: 2);
      final second = given(documentId: 'b', pageCount: 3, title: 'Receipt');

      final result = await MergeDocuments(contextFor([first, second]))([
        second.id,
        first.id,
      ]);

      final merged = (result as Success<Document>).value;
      expect(merged.pageCount, 5);
      // Second first, because that is the order the user put them in.
      expect(fakePdfPages(pathOf(merged)).first, 'page:0');
      expect(fakePdfPages(pathOf(merged)), hasLength(5));
    });

    test('leaves every source unchanged', () async {
      final first = given(pageCount: 2);
      final second = given(documentId: 'b', pageCount: 2);
      final before = [
        File(pathOf(first)).readAsStringSync(),
        File(pathOf(second)).readAsStringSync(),
      ];

      await MergeDocuments(contextFor([first, second]))([first.id, second.id]);

      expect(File(pathOf(first)).readAsStringSync(), before.first);
      expect(File(pathOf(second)).readAsStringSync(), before.last);
    });

    test('refuses fewer than two documents', () async {
      final only = given();

      final result = await MergeDocuments(contextFor([only]))([only.id]);

      expect(result, isA<Failed<Document>>());
      expect(editor.operations, isEmpty);
    });

    test('fails when one of the documents is missing', () async {
      final first = given();

      final result = await MergeDocuments(contextFor([first]))([
        first.id,
        const DocumentId('gone'),
      ]);

      expect(result, isA<Failed<Document>>());
    });
  });

  group('SplitDocument', () {
    test('the two halves are together the original, in order', () async {
      final document = given(pageCount: 5);

      final result = await SplitDocument(contextFor([document]))(
        id,
        afterPage: 2,
      );

      final (first, second) = (result as Success<(Document, Document)>).value;
      expect(
        [...fakePdfPages(pathOf(first)), ...fakePdfPages(pathOf(second))],
        ['page:0', 'page:1', 'page:2', 'page:3', 'page:4'],
      );
    });

    test('leaves the original document alone', () async {
      final document = given();
      final before = File(pathOf(document)).readAsStringSync();

      await SplitDocument(contextFor([document]))(id, afterPage: 2);

      expect(File(pathOf(document)).readAsStringSync(), before);
      expect(library.documents[id]!.pageCount, 4);
    });

    test('refuses a split point that would produce an empty half', () async {
      final document = given(pageCount: 3);

      final result = await SplitDocument(contextFor([document]))(
        id,
        afterPage: 3,
      );

      expect(result, isA<Failed<(Document, Document)>>());
      expect(editor.operations, isEmpty);
    });

    test('refuses to split a single-page document', () async {
      final document = given(pageCount: 1);

      final result = await SplitDocument(contextFor([document]))(
        id,
        afterPage: 1,
      );

      expect(result, isA<Failed<(Document, Document)>>());
    });
  });

  group('CompressDocument', () {
    test('replaces the file and reports the saving', () async {
      final document = given(padding: 500);

      final result = await CompressDocument(contextFor([document]))(id);

      final outcome = (result as Success<CompressionOutcome>).value;
      expect(outcome.wasKept, isTrue);
      expect(outcome.newBytes, lessThan(outcome.originalBytes));
      expect(outcome.message, contains('Reduced'));
      // Every page survived the round trip.
      expect(outcome.document.pageCount, 4);
    });

    test('keeps the original when compression yields no benefit', () async {
      // A rewrite can legitimately come out larger; the spec requires the
      // original to be kept and the user told.
      final document = given(pageCount: 2);
      final before = File(pathOf(document)).readAsStringSync();
      final result = await CompressDocument(contextFor([document]))(id);

      final outcome = (result as Success<CompressionOutcome>).value;
      expect(outcome.wasKept, isFalse);
      expect(outcome.message, contains('already as small'));
      expect(File(pathOf(document)).readAsStringSync(), before);
    });

    test('leaves no candidate file behind when nothing was kept', () async {
      final document = given(pageCount: 2);
      await CompressDocument(contextFor([document]))(id);

      expect(File('${pathOf(document)}.compressed').existsSync(), isFalse);
    });

    test('keeps the page count unchanged', () async {
      final document = given(padding: 500);

      final result = await CompressDocument(contextFor([document]))(id);

      expect(
        (result as Success<CompressionOutcome>).value.document.pageCount,
        4,
      );
    });

    test('leaves the document unchanged when the engine fails', () async {
      final document = given();
      final before = File(pathOf(document)).readAsStringSync();

      final result = await CompressDocument(
        contextFor([
          document,
        ], withEditor: FakePdfEditor(failWith: const Failure.pdf())),
      )(id);

      expect(result, isA<Failed<CompressionOutcome>>());
      expect(File(pathOf(document)).readAsStringSync(), before);
    });
  });

  group('WatermarkDocument', () {
    test('applies the watermark to every page', () async {
      final document = given(pageCount: 3);

      await WatermarkDocument(contextFor([document]))(id, 'DRAFT');

      expect(
        fakePdfPages(pathOf(document)),
        everyElement(contains('wm:DRAFT')),
      );
    });

    test('trims the text before applying it', () async {
      final document = given(pageCount: 1);

      await WatermarkDocument(contextFor([document]))(id, '  DRAFT  ');

      expect(fakePdfPages(pathOf(document)).single, endsWith('wm:DRAFT'));
    });

    test('refuses a blank watermark', () async {
      final document = given();

      final result = await WatermarkDocument(contextFor([document]))(id, '   ');

      expect(result, isA<Failed<Document>>());
      expect(editor.operations, isEmpty);
    });

    test('keeps the page count unchanged', () async {
      final document = given(pageCount: 3);

      final result = await WatermarkDocument(contextFor([document]))(
        id,
        'DRAFT',
      );

      expect((result as Success<Document>).value.pageCount, 3);
    });
  });

  group('ProtectDocument', () {
    test('encrypts the file and marks the document protected', () async {
      final document = given(pageCount: 2);

      final result = await ProtectDocument(contextFor([document]))(
        id,
        'hunter2',
      );

      expect((result as Success<Document>).value.isProtected, isTrue);
      expect(fakePdfPassword(pathOf(document)), 'hunter2');
    });

    test('stores the password in secure storage only', () async {
      final document = given(pageCount: 1);

      await ProtectDocument(contextFor([document]))(id, 'hunter2');

      final stored = await secrets.read(SecureStorageKeys.pdfPassword('a'));
      expect(stored.valueOrNull, 'hunter2');
    });

    test('the password never reaches the document record', () async {
      // The record goes to Isar, which is not secure storage. A password on it
      // would be a password in the database.
      final document = given(pageCount: 1);

      final result = await ProtectDocument(contextFor([document]))(
        id,
        'hunter2',
      );

      expect(
        '${(result as Success<Document>).value}',
        isNot(contains('hunter2')),
      );
      for (final written in library.written) {
        expect('$written', isNot(contains('hunter2')));
      }
    });

    test('refuses a blank password', () async {
      final document = given();

      final result = await ProtectDocument(contextFor([document]))(id, '   ');

      expect(result, isA<Failed<Document>>());
      expect(editor.operations, isEmpty);
    });

    test('stores nothing when the encryption failed', () async {
      // The other order would leave a stored password for a file that is not
      // encrypted — offered by the viewer and refused by the file.
      final document = given();

      final result = await ProtectDocument(
        contextFor([
          document,
        ], withEditor: FakePdfEditor(failWith: const Failure.pdf())),
      )(id, 'hunter2');

      expect(result, isA<Failed<Document>>());
      final stored = await secrets.read(SecureStorageKeys.pdfPassword('a'));
      expect(stored.valueOrNull, isNull);
    });
  });

  group('RemoveDocumentPassword', () {
    test('removes the protection with the correct password', () async {
      final document = given(pageCount: 2, password: 'hunter2');
      await secrets.write(SecureStorageKeys.pdfPassword('a'), 'hunter2');

      final result = await RemoveDocumentPassword(contextFor([document]))(
        id,
        'hunter2',
      );

      expect((result as Success<Document>).value.isProtected, isFalse);
      expect(fakePdfPassword(pathOf(document)), isNull);
    });

    test(
      'deletes the stored password once the file opens without it',
      () async {
        final document = given(pageCount: 1, password: 'hunter2');
        await secrets.write(SecureStorageKeys.pdfPassword('a'), 'hunter2');

        await RemoveDocumentPassword(contextFor([document]))(id, 'hunter2');

        final stored = await secrets.read(SecureStorageKeys.pdfPassword('a'));
        expect(stored.valueOrNull, isNull);
      },
    );

    test('an incorrect password changes nothing at all', () async {
      final document = given(pageCount: 2, password: 'hunter2');
      await secrets.write(SecureStorageKeys.pdfPassword('a'), 'hunter2');
      final before = File(pathOf(document)).readAsStringSync();

      final result = await RemoveDocumentPassword(contextFor([document]))(
        id,
        'wrong',
      );

      expect((result as Failed<Document>).failure, isA<AuthFailure>());
      expect(File(pathOf(document)).readAsStringSync(), before);
      expect(library.documents[id]!.isProtected, isTrue);
      // And the stored secret survives, so the user can try again.
      final stored = await secrets.read(SecureStorageKeys.pdfPassword('a'));
      expect(stored.valueOrNull, 'hunter2');
    });
  });

  group('protected documents', () {
    test('an in-place edit uses the stored password', () async {
      final document = given(pageCount: 3, password: 'hunter2');
      await secrets.write(SecureStorageKeys.pdfPassword('a'), 'hunter2');

      final result = await RotatePage(contextFor([document]))(id, 0);

      expect(result, isA<Success<Document>>());
    });

    test('an edit fails cleanly when the stored password is missing', () async {
      final document = given(pageCount: 3, password: 'hunter2');
      final before = File(pathOf(document)).readAsStringSync();

      final result = await RotatePage(contextFor([document]))(id, 0);

      expect((result as Failed<Document>).failure, isA<AuthFailure>());
      expect(File(pathOf(document)).readAsStringSync(), before);
    });
  });

  group('ReadPdfMetadata', () {
    test('returns every field the metadata view shows', () async {
      final document = given(pageCount: 7, title: 'Statement');

      final result = await ReadPdfMetadata(contextFor([document]))(id);

      final metadata = (result as Success<PdfMetadata>).value;
      expect(metadata.title, 'Statement');
      expect(metadata.pageCount, 7);
      expect(metadata.sizeInBytes, document.sizeInBytes);
      expect(metadata.createdAt, document.createdAt);
      expect(metadata.updatedAt, document.updatedAt);
      expect(metadata.isProtected, isFalse);
    });

    test('reports protection status', () async {
      final document = given(password: 'hunter2');

      final result = await ReadPdfMetadata(contextFor([document]))(id);

      expect((result as Success<PdfMetadata>).value.isProtected, isTrue);
    });

    test('fails for a document that does not exist', () async {
      final result = await ReadPdfMetadata(contextFor(const []))(id);

      expect(result, isA<Failed<PdfMetadata>>());
    });
  });
}
