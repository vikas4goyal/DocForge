/// Cubit tests for the PDF editor.
///
/// Built over the real use cases and the fake editor, because what these assert
/// is the state sequence the screen renders — and mocked use cases would let
/// the Cubit and the use case disagree about what a rejected password means.
library;

import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_forge/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _Library implements DocumentReader, DocumentWriter {
  _Library(this.documents);

  final Map<DocumentId, Document> documents;

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
    documents[document.id] = document;
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async {
    documents[document.id] = document;
    return Result<Document>.success(document);
  }
}

void main() {
  late Directory temporary;
  late InMemorySecureStore secrets;

  const id = DocumentId('a');

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('pdf_edit_cubit');
    secrets = InMemorySecureStore();
  });

  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  Document given({
    String documentId = 'a',
    int pageCount = 4,
    String? password,
    int padding = 0,
  }) {
    final path = '${temporary.path}/$documentId.pdf';
    final file = writeFakePdf(
      path,
      pageCount: pageCount,
      password: password,
      padding: padding,
    );

    return Document(
      id: DocumentId(documentId),
      title: 'Invoice',
      createdAt: DateTime.utc(2026, 3),
      updatedAt: DateTime.utc(2026, 3),
      pageCount: pageCount,
      sizeInBytes: file.lengthSync(),
      filePath: path,
      isProtected: password != null,
    );
  }

  PdfEditCubit build(List<Document> documents, {FakePdfEditor? withEditor}) {
    final editor = withEditor ?? FakePdfEditor();
    final library = _Library({
      for (final document in documents) document.id: document,
    });

    final context = PdfEditContext(
      documents: library,
      writer: library,
      editor: editor,
      atomic: AtomicPdfWrite(
        (path, password) => editor.pageCountOf(path, password: password),
      ),
      secrets: secrets,
      destination: (newId) => '${temporary.path}/${newId.value}.pdf',
      clock: FixedClock(DateTime.utc(2026, 6)),
      ids: SequentialIdGenerator(),
    );

    return PdfEditCubit(
      id,
      PdfEditUseCases(
        rotate: RotatePage(context),
        delete: DeletePages(context),
        duplicate: DuplicatePage(context),
        extract: ExtractPages(context),
        merge: MergeDocuments(context),
        split: SplitDocument(context),
        compress: CompressDocument(context),
        watermark: WatermarkDocument(context),
        protect: ProtectDocument(context),
        removePassword: RemoveDocumentPassword(context),
        metadata: ReadPdfMetadata(context),
      ),
    );
  }

  group('load', () {
    blocTest<PdfEditCubit, PdfEditState>(
      'reaches ready with the document and its metadata',
      build: () => build([given()]),
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<PdfEditState>()
            .having((s) => s.status, 'status', PdfEditStatus.ready)
            .having((s) => s.pageCount, 'pageCount', 4)
            .having((s) => s.metadata, 'metadata', isNotNull),
      ],
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'fails for a document that does not exist',
      build: () => build(const []),
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<PdfEditState>().having(
          (s) => s.status,
          'status',
          PdfEditStatus.failure,
        ),
      ],
    );
  });

  group('selection', () {
    blocTest<PdfEditCubit, PdfEditState>(
      'toggling adds then removes a page',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        cubit
          ..toggleSelection(1)
          ..toggleSelection(1);
      },
      verify: (cubit) => expect(cubit.state.selection, isEmpty),
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'a single selection enables rotate and duplicate',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(0);
      },
      verify: (cubit) {
        expect(cubit.state.canRun(PdfEditOperation.rotate), isTrue);
        expect(cubit.state.canRun(PdfEditOperation.duplicate), isTrue);
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'a multiple selection disables rotate but allows extract',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        cubit
          ..toggleSelection(0)
          ..toggleSelection(1);
      },
      verify: (cubit) {
        // Rotating "these two pages" begs the question of which one.
        expect(cubit.state.canRun(PdfEditOperation.rotate), isFalse);
        expect(cubit.state.canRun(PdfEditOperation.extract), isTrue);
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'delete is unavailable when it would empty the document',
      build: () => build([given(pageCount: 1)]),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(0);
      },
      verify: (cubit) =>
          expect(cubit.state.canRun(PdfEditOperation.delete), isFalse),
    );
  });

  group('page operations', () {
    blocTest<PdfEditCubit, PdfEditState>(
      'rotating keeps the page count',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(1);
        await cubit.rotate();
      },
      verify: (cubit) {
        expect(cubit.state.status, PdfEditStatus.ready);
        expect(cubit.state.pageCount, 4);
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'deleting reduces the page count and clears the selection',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(0);
        await cubit.delete();
      },
      verify: (cubit) {
        expect(cubit.state.pageCount, 3);
        // A selection pointing past the end of a shorter document would enable
        // operations on pages that no longer exist.
        expect(cubit.state.selection, isEmpty);
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'duplicating increases the page count by one',
      build: () => build([given(pageCount: 2)]),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(0);
        await cubit.duplicate();
      },
      verify: (cubit) => expect(cubit.state.pageCount, 3),
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'extracting reports the new document without changing this one',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(0);
        await cubit.extract();
      },
      verify: (cubit) {
        expect(cubit.state.derived, isNotNull);
        expect(cubit.state.pageCount, 4);
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'reports a failure with its message',
      build: () => build([
        given(),
      ], withEditor: FakePdfEditor(failWith: const Failure.corruptFile())),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(0);
        await cubit.rotate();
      },
      verify: (cubit) {
        expect(cubit.state.status, PdfEditStatus.failure);
        expect(cubit.state.message, isNotNull);
      },
    );
  });

  group('document operations', () {
    blocTest<PdfEditCubit, PdfEditState>(
      'compressing reports the saving',
      build: () => build([given(padding: 500)]),
      act: (cubit) async {
        await cubit.load();
        await cubit.compress();
      },
      verify: (cubit) {
        expect(cubit.state.compression?.wasKept, isTrue);
        expect(cubit.state.compression?.message, contains('Reduced'));
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'compressing says so when there was nothing to save',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        await cubit.compress();
      },
      verify: (cubit) {
        expect(cubit.state.compression?.wasKept, isFalse);
        expect(cubit.state.compression?.message, contains('already as small'));
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'watermarking keeps the page count',
      build: () => build([given(pageCount: 3)]),
      act: (cubit) async {
        await cubit.load();
        await cubit.watermark('DRAFT');
      },
      verify: (cubit) {
        expect(cubit.state.status, PdfEditStatus.ready);
        expect(cubit.state.pageCount, 3);
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'splitting reports the first half',
      build: () => build([given()]),
      act: (cubit) async {
        await cubit.load();
        await cubit.split(2);
      },
      verify: (cubit) => expect(cubit.state.derived?.pageCount, 2),
    );
  });

  group('protection', () {
    blocTest<PdfEditCubit, PdfEditState>(
      'protecting marks the document and stores the password securely',
      build: () => build([given(pageCount: 2)]),
      act: (cubit) async {
        await cubit.load();
        await cubit.protect('hunter2');
      },
      verify: (cubit) async {
        expect(cubit.state.document?.isProtected, isTrue);
        final stored = await secrets.read(SecureStorageKeys.pdfPassword('a'));
        expect(stored.valueOrNull, 'hunter2');
      },
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'the password never appears in the emitted state',
      build: () => build([given(pageCount: 2)]),
      act: (cubit) async {
        await cubit.load();
        await cubit.protect('hunter2');
      },
      verify: (cubit) =>
          expect('${cubit.state.props}', isNot(contains('hunter2'))),
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'removing protection with the right password succeeds',
      build: () => build([given(pageCount: 2, password: 'hunter2')]),
      setUp: () async =>
          secrets.write(SecureStorageKeys.pdfPassword('a'), 'hunter2'),
      act: (cubit) async {
        await cubit.load();
        await cubit.removePassword('hunter2');
      },
      verify: (cubit) => expect(cubit.state.document?.isProtected, isFalse),
    );

    blocTest<PdfEditCubit, PdfEditState>(
      'a wrong password is a rejection, not an error',
      build: () => build([given(pageCount: 2, password: 'hunter2')]),
      setUp: () async =>
          secrets.write(SecureStorageKeys.pdfPassword('a'), 'hunter2'),
      act: (cubit) async {
        await cubit.load();
        await cubit.removePassword('wrong');
      },
      verify: (cubit) {
        // An error view would make a mistyped password look like a breakage.
        expect(cubit.state.status, PdfEditStatus.ready);
        expect(cubit.state.passwordRejected, isTrue);
        expect(cubit.state.failure, isNull);
      },
    );
  });

  group('dismissError', () {
    blocTest<PdfEditCubit, PdfEditState>(
      'returns to the editor',
      build: () => build([
        given(),
      ], withEditor: FakePdfEditor(failWith: const Failure.pdf())),
      act: (cubit) async {
        await cubit.load();
        cubit.toggleSelection(0);
        await cubit.rotate();
        cubit.dismissError();
      },
      verify: (cubit) {
        expect(cubit.state.status, PdfEditStatus.ready);
        expect(cubit.state.failure, isNull);
      },
    );
  });
}
