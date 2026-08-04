/// Cubit tests for the import flow.
library;

import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_scanly/features/document_import/domain/import_rules.dart';
import 'package:doc_scanly/features/document_import/infrastructure/import_job.dart';
import 'package:doc_scanly/features/document_import/infrastructure/repositories/fake_import_sources.dart';
import 'package:doc_scanly/features/document_import/presentation/cubit/import_cubit.dart';
import 'package:doc_scanly/features/document_import/presentation/cubit/import_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _Writer implements DocumentWriter {
  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async => Result<Document>.success(document);

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}

void main() {
  late Directory temporary;

  setUp(() => temporary = Directory.systemTemp.createTempSync('import_cubit'));
  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  String writeSource(String name) {
    final file = File('${temporary.path}/$name')..writeAsStringSync('content');
    return file.path;
  }

  ImportCubit build({
    FakeGalleryPicker? gallery,
    FakeFileBrowser? files,
    FakePdfInspector? inspector,
  }) {
    Directory staging() =>
        Directory('${temporary.path}/staging')..createSync(recursive: true);

    return ImportCubit(
      gallery ?? FakeGalleryPicker(),
      files ?? FakeFileBrowser(),
      ImportFiles(
        ImportImages(
          const InlineBackgroundWorker(),
          staging,
          SequentialIdGenerator(),
          copyImportedFileJob,
        ),
        ImportPdf(
          inspector ?? FakePdfInspector(pageCount: 2),
          _Writer(),
          (id) => '${temporary.path}/documents/${id.value}.pdf',
          InMemoryPublicFileStore(),
          FixedClock(DateTime.utc(2026, 3, 14)),
          SequentialIdGenerator(),
        ),
      ),
    );
  }

  group('gallery', () {
    blocTest<ImportCubit, ImportState>(
      'copies the selection and reaches review',
      build: () =>
          build(gallery: FakeGalleryPicker(paths: [writeSource('a.jpg')])),
      act: (cubit) => cubit.fromGallery(),
      expect: () => [
        isA<ImportState>().having(
          (s) => s.status,
          'status',
          ImportStatus.choosing,
        ),
        isA<ImportState>().having(
          (s) => s.status,
          'status',
          ImportStatus.importing,
        ),
        isA<ImportState>().having((s) => s.progress?.completed, 'completed', 1),
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.readyForReview)
            .having((s) => s.bundle?.pageCount, 'pages', 1),
      ],
    );

    blocTest<ImportCubit, ImportState>(
      'returns to the sources when the picker is cancelled',
      build: build,
      act: (cubit) => cubit.fromGallery(),
      skip: 1,
      expect: () => [
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.idle)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );

    blocTest<ImportCubit, ImportState>(
      'shows the permission view when photo access is refused',
      build: () => build(
        gallery: FakeGalleryPicker(
          failure: const Failure.permission(
            kind: PermissionKind.photos,
            permanentlyDenied: true,
          ),
        ),
      ),
      act: (cubit) => cubit.fromGallery(),
      skip: 1,
      expect: () => [
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.permissionDenied)
            .having((s) => s.isPermanentlyDenied, 'permanentlyDenied', isTrue),
      ],
    );

    blocTest<ImportCubit, ImportState>(
      'reports any other picker failure as an error',
      build: () =>
          build(gallery: FakeGalleryPicker(failure: const Failure.import())),
      act: (cubit) => cubit.fromGallery(),
      skip: 1,
      expect: () => [
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.failure)
            .having((s) => s.message, 'message', isNotNull),
      ],
    );
  });

  group('files', () {
    blocTest<ImportCubit, ImportState>(
      'imports a PDF and reports done',
      build: () => build(files: FakeFileBrowser(paths: [writeSource('a.pdf')])),
      act: (cubit) => cubit.fromFiles(),
      skip: 2,
      expect: () => [
        isA<ImportState>().having((s) => s.imported, 'imported', hasLength(1)),
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.done)
            .having((s) => s.outcomeMessage, 'outcome', '1 document imported.'),
      ],
    );

    blocTest<ImportCubit, ImportState>(
      'reports how many documents a batch created',
      build: () => build(
        files: FakeFileBrowser(
          paths: [writeSource('a.pdf'), writeSource('b.pdf')],
        ),
      ),
      act: (cubit) => cubit.fromFiles(),
      verify: (cubit) =>
          expect(cubit.state.outcomeMessage, '2 documents imported.'),
    );

    blocTest<ImportCubit, ImportState>(
      'rejects an unsupported selection without importing anything',
      build: () => build(files: FakeFileBrowser(paths: [writeSource('a.txt')])),
      act: (cubit) => cubit.fromFiles(),
      skip: 2,
      expect: () => [
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.failure)
            .having((s) => s.imported, 'imported', isEmpty),
      ],
    );
  });

  group('protected PDFs', () {
    blocTest<ImportCubit, ImportState>(
      'prompts for a password rather than failing',
      build: () => build(
        files: FakeFileBrowser(paths: [writeSource('locked.pdf')]),
        inspector: FakePdfInspector(requiresPassword: true),
      ),
      act: (cubit) => cubit.fromFiles(),
      skip: 2,
      expect: () => [
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.awaitingPassword)
            // Not marked rejected on the first prompt: the file is simply
            // asking, and the user has not got anything wrong yet.
            .having((s) => s.passwordRejected, 'passwordRejected', isFalse),
      ],
    );

    blocTest<ImportCubit, ImportState>(
      'imports once the correct password is entered',
      build: () => build(
        files: FakeFileBrowser(paths: [writeSource('locked.pdf')]),
        inspector: FakePdfInspector(requiresPassword: true, pageCount: 4),
      ),
      act: (cubit) async {
        await cubit.fromFiles();
        await cubit.submitPassword('hunter2');
      },
      verify: (cubit) {
        expect(cubit.state.status, ImportStatus.done);
        expect(cubit.state.imported.single.pageCount, 4);
      },
    );

    blocTest<ImportCubit, ImportState>(
      'creates no document when the prompt is abandoned',
      build: () => build(
        files: FakeFileBrowser(paths: [writeSource('locked.pdf')]),
        inspector: FakePdfInspector(requiresPassword: true),
      ),
      act: (cubit) async {
        await cubit.fromFiles();
        cubit.cancelPassword();
      },
      verify: (cubit) {
        expect(cubit.state.status, ImportStatus.idle);
        expect(cubit.state.imported, isEmpty);
      },
    );
  });

  group('share sheet', () {
    blocTest<ImportCubit, ImportState>(
      'imports content handed over by another application',
      build: build,
      act: (cubit) => cubit.fromShareSheet([writeSource('shared.pdf')]),
      verify: (cubit) {
        expect(cubit.state.status, ImportStatus.done);
        expect(cubit.state.source, ImportSource.shareSheet);
      },
    );
  });

  group('dismissError', () {
    blocTest<ImportCubit, ImportState>(
      'returns to the sources',
      build: () =>
          build(gallery: FakeGalleryPicker(failure: const Failure.import())),
      act: (cubit) async {
        await cubit.fromGallery();
        cubit.dismissError();
      },
      skip: 2,
      expect: () => [
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.idle)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );
  });
}
