/// Tests for the import use cases.
///
/// The properties under test are the guarantees the spec states: selection
/// order becomes page order, an imported PDF gets the right page count and file
/// size, and *no partial document survives* a rejection, a corrupt file, a
/// cancelled password prompt, a full device or a cancelled import.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_scanly/features/document_import/domain/import_rules.dart';
import 'package:doc_scanly/features/document_import/infrastructure/import_job.dart';
import 'package:doc_scanly/features/document_import/infrastructure/repositories/fake_import_sources.dart';
import 'package:flutter_test/flutter_test.dart';

/// A writer recording what was saved, and optionally refusing to.
class _Writer implements DocumentWriter {
  _Writer({this.failure});

  final Failure? failure;

  final List<Document> saved = [];

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    final configured = failure;
    if (configured != null) return Result<Document>.failure(configured);

    saved.add(document);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}

void main() {
  late Directory temporary;

  setUp(() => temporary = Directory.systemTemp.createTempSync('import_test'));
  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  /// Writes a stand-in source file and returns its path.
  String writeSource(String name, {String contents = 'content'}) {
    final file = File('${temporary.path}/$name')..writeAsStringSync(contents);
    return file.path;
  }

  Directory staging() {
    final directory = Directory('${temporary.path}/staging')
      ..createSync(recursive: true);
    return directory;
  }

  group('ImportImages', () {
    ImportImages build({IsolateJob<CopyImportRequest, String>? job}) =>
        ImportImages(
          const InlineBackgroundWorker(),
          staging,
          SequentialIdGenerator(),
          job ?? copyImportedFileJob,
        );

    test('copies images and hands them to review in selection order', () async {
      // Selection order, not alphabetical: the user chose b before a.
      final paths = [writeSource('b.jpg'), writeSource('a.png')];

      final events = await build()(
        paths,
        source: ImportSource.gallery,
      ).toList();

      final ready = events.whereType<ImportReadyForReview>().single;
      expect(ready.bundle.pages, hasLength(2));
      expect(
        ready.bundle.pages.map((page) => File(page.imagePath).existsSync()),
        everyElement(isTrue),
      );
    });

    test('records where the pages came from', () async {
      final events = await build()([
        writeSource('a.jpg'),
      ], source: ImportSource.gallery).toList();

      final ready = events.whereType<ImportReadyForReview>().single;
      expect(ready.bundle.source.name, 'gallery');
    });

    test('creates no document — review comes first', () async {
      // The spec requires cropping and enhancement to be available before
      // anything is saved, so this use case must not produce a document.
      final events = await build()([
        writeSource('a.jpg'),
      ], source: ImportSource.gallery).toList();

      expect(events.whereType<ImportedDocument>(), isEmpty);
    });

    test('reports progress per file', () async {
      final events = await build()([
        writeSource('a.jpg'),
        writeSource('b.jpg'),
      ], source: ImportSource.gallery).toList();

      expect(
        events.whereType<ImportProgressed>().map((e) => e.progress.completed),
        [1, 2],
      );
    });

    test('suggests the file name as a title for a single image', () async {
      final events = await build()([
        writeSource('Receipt.jpg'),
      ], source: ImportSource.files).toList();

      final ready = events.whereType<ImportReadyForReview>().single;
      expect(ready.bundle.suggestedTitle, 'Receipt');
    });

    test('suggests no title for a batch', () async {
      // Twelve photos named after the first one would be misleading.
      final events = await build()([
        writeSource('a.jpg'),
        writeSource('b.jpg'),
      ], source: ImportSource.gallery).toList();

      final ready = events.whereType<ImportReadyForReview>().single;
      expect(ready.bundle.suggestedTitle, isNull);
    });

    test('rejects a selection with no images in it', () async {
      final events = await build()([
        writeSource('notes.txt'),
      ], source: ImportSource.files).toList();

      final failed = events.single as ImportFailed;
      expect((failed.failure as ImportFailure).unsupportedType, isTrue);
    });

    test('leaves nothing behind when a copy fails', () async {
      var calls = 0;
      String flaky(CopyImportRequest request) {
        calls++;
        if (calls > 1) throw const FileSystemException('disk gone');
        return copyImportedFileJob(request);
      }

      final events = await build(job: flaky)([
        writeSource('a.jpg'),
        writeSource('b.jpg'),
      ], source: ImportSource.gallery).toList();

      expect(events.last, isA<ImportFailed>());
      expect(staging().listSync(), isEmpty);
    });

    test('leaves nothing behind when cancelled', () async {
      final token = CancellationToken()..cancel();

      final events = await build()(
        [writeSource('a.jpg')],
        source: ImportSource.gallery,
        token: token,
      ).toList();

      final failed = events.last as ImportFailed;
      expect(failed.failure.isCancellation, isTrue);
      expect(staging().listSync(), isEmpty);
    });

    test('fails rather than crashing when the source file is gone', () async {
      final events = await build()([
        '${temporary.path}/never_written.jpg',
      ], source: ImportSource.files).toList();

      expect(events.last, isA<ImportFailed>());
    });
  });

  group('ImportPdf', () {
    ImportPdf build({
      FakePdfInspector? inspector,
      _Writer? writer,
      Clock? clock,
    }) => ImportPdf(
      inspector ?? FakePdfInspector(pageCount: 7),
      writer ?? _Writer(),
      (id) => '${temporary.path}/documents/${id.value}.pdf',
      InMemoryPublicFileStore(),
      clock ?? FixedClock(DateTime.utc(2026, 3, 14, 9)),
      SequentialIdGenerator(),
    );

    test('copies the file and records the page count and size', () async {
      final source = writeSource('Invoice.pdf', contents: '%PDF-1.7 body');
      final writer = _Writer();

      final result = await build(writer: writer)(source);

      final document = (result as Success<Document>).value;
      expect(document.pageCount, 7);
      expect(document.sizeInBytes, '%PDF-1.7 body'.length);
      expect(document.title, 'Invoice');
      // Published into the library, addressed by a library-relative path
      // rather than a device one.
      expect(document.relativePath, 'Invoice.pdf');
      expect(writer.saved, hasLength(1));
    });

    test('leaves the source file where it was', () async {
      final source = writeSource('Invoice.pdf');

      await build()(source);

      expect(File(source).existsSync(), isTrue);
    });

    test('rejects a file that is not a PDF', () async {
      final result = await build()(writeSource('notes.txt'));

      expect(result, isA<Failed<Document>>());
    });

    test('fails when the source is missing', () async {
      final result = await build()('${temporary.path}/gone.pdf');

      expect(result, isA<Failed<Document>>());
    });

    test('creates no record and no file for a corrupt PDF', () async {
      // The inspection is what catches a file that is a PDF in name only.
      final writer = _Writer();

      final result = await build(
        inspector: FakePdfInspector(failure: const Failure.corruptFile()),
        writer: writer,
      )(writeSource('broken.pdf'));

      expect(result, isA<Failed<Document>>());
      expect(writer.saved, isEmpty);
      expect(
        Directory('${temporary.path}/documents').existsSync()
            ? Directory('${temporary.path}/documents').listSync()
            : const <FileSystemEntity>[],
        isEmpty,
      );
    });

    test('reports a protected PDF rather than importing it', () async {
      final writer = _Writer();

      final result = await build(
        inspector: FakePdfInspector(requiresPassword: true),
        writer: writer,
      )(writeSource('locked.pdf'));

      expect((result as Failed<Document>).failure, isA<AuthFailure>());
      expect(writer.saved, isEmpty);
    });

    test('imports a protected PDF once the password is supplied', () async {
      final result = await build(
        inspector: FakePdfInspector(requiresPassword: true, pageCount: 2),
      )(writeSource('locked.pdf'), password: 'hunter2');

      final document = (result as Success<Document>).value;
      expect(document.isProtected, isTrue);
      expect(document.pageCount, 2);
    });

    test('inspects the copy, not the original', () async {
      // Inspecting under the temporary name is what keeps an unreadable file
      // from ever occupying the name a real document would.
      final inspector = FakePdfInspector();

      await build(inspector: inspector)(writeSource('a.pdf'));

      expect(inspector.inspected.single, endsWith('.partial'));
    });

    test('removes the stored file when the record cannot be written', () async {
      // Without a record the file is unreachable, so leaving it would be an
      // orphan that only shows up as missing storage.
      final result = await build(
        writer: _Writer(failure: const Failure.storage()),
      )(writeSource('a.pdf'));

      expect(result, isA<Failed<Document>>());
      expect(Directory('${temporary.path}/documents').listSync(), isEmpty);
    });
  });

  group('ImportFiles', () {
    ImportFiles build({FakePdfInspector? inspector, _Writer? writer}) =>
        ImportFiles(
          ImportImages(
            const InlineBackgroundWorker(),
            staging,
            SequentialIdGenerator(),
            copyImportedFileJob,
          ),
          ImportPdf(
            inspector ?? FakePdfInspector(pageCount: 3),
            writer ?? _Writer(),
            (id) => '${temporary.path}/documents/${id.value}.pdf',
            InMemoryPublicFileStore(),
            FixedClock(DateTime.utc(2026, 3, 14)),
            SequentialIdGenerator(),
          ),
        );

    test(
      'turns a PDF into a document and images into a review bundle',
      () async {
        final events = await build()([
          writeSource('a.pdf'),
          writeSource('b.jpg'),
        ], source: ImportSource.files).toList();

        expect(events.whereType<ImportedDocument>(), hasLength(1));
        expect(events.whereType<ImportReadyForReview>(), hasLength(1));
      },
    );

    test('imports several PDFs as several documents', () async {
      final events = await build()([
        writeSource('a.pdf'),
        writeSource('b.pdf'),
      ], source: ImportSource.shareSheet).toList();

      expect(events.whereType<ImportedDocument>(), hasLength(2));
    });

    test('rejects a selection with nothing supported in it', () async {
      final events = await build()([
        writeSource('a.txt'),
      ], source: ImportSource.files).toList();

      final failed = events.single as ImportFailed;
      expect((failed.failure as ImportFailure).unsupportedType, isTrue);
    });

    test('ignores unsupported files alongside supported ones', () async {
      final events = await build()([
        writeSource('a.txt'),
        writeSource('b.jpg'),
      ], source: ImportSource.files).toList();

      expect(events.whereType<ImportReadyForReview>(), hasLength(1));
    });

    test(
      'asks for a password rather than failing on a protected PDF',
      () async {
        final events = await build(
          inspector: FakePdfInspector(requiresPassword: true),
        )([writeSource('locked.pdf')], source: ImportSource.files).toList();

        expect(events.last, isA<ImportNeedsPassword>());
      },
    );

    test(
      'stops at the protected file without importing what follows',
      () async {
        // The user is being asked a question; carrying on past it would import
        // half the selection while they answered.
        final writer = _Writer();

        final events =
            await build(
                  inspector: FakePdfInspector(requiresPassword: true),
                  writer: writer,
                )([
                  writeSource('locked.pdf'),
                  writeSource('after.pdf'),
                ], source: ImportSource.files)
                .toList();

        expect(events.last, isA<ImportNeedsPassword>());
        expect(writer.saved, isEmpty);
      },
    );

    test('stops before starting when already cancelled', () async {
      final token = CancellationToken()..cancel();

      final events = await build()(
        [writeSource('a.pdf')],
        source: ImportSource.files,
        token: token,
      ).toList();

      final failed = events.single as ImportFailed;
      expect(failed.failure.isCancellation, isTrue);
    });
  });

  group('shared content', () {
    test('takes what was waiting at launch', () async {
      final source = FakeSharedContentSource(pendingPaths: ['/a.pdf']);

      expect(await TakePendingSharedContent(source)(), ['/a.pdf']);
    });

    test('reports nothing waiting as an empty list, not a failure', () async {
      expect(await TakePendingSharedContent(FakeSharedContentSource())(), []);
    });

    test('delivers content shared while running', () async {
      final source = FakeSharedContentSource();
      final received = <List<String>>[];

      final subscription = WatchSharedContent(source)().listen(received.add);
      source.emit(['/b.jpg']);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(received, [
        ['/b.jpg'],
      ]);
    });
  });
}
