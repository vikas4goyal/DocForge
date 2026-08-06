/// Tests for the sharing, printing and export use cases.
///
/// The properties under test are the ones the spec states as guarantees:
/// nothing leaves unless it was asked for, what leaves is in page order, a
/// protected document keeps its protection and its password is never touched,
/// and a failure leaves no partial file anywhere.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_scanly/features/document_sharing/domain/document_export_result.dart';
import 'package:doc_scanly/features/document_sharing/domain/share_content.dart';
import 'package:doc_scanly/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

/// A document reader over fixed fixtures.
class _Reader implements DocumentReader {
  _Reader({this.document, this.pages = const [], this.failure});

  final Document? document;
  final List<DocumentPage> pages;
  final Failure? failure;

  @override
  Future<Result<Document>> findById(DocumentId id) async {
    final configured = failure;
    if (configured != null) return Result<Document>.failure(configured);

    final found = document;
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
  }) async => const Result<List<Document>>.success([]);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      Result<List<DocumentPage>>.success(pages);
}

/// A text source over a fixed string.

void main() {
  const id = DocumentId('a');
  late Directory temporary;
  late FilesystemPublicFileStore store;
  late DocumentFileResolver testFiles;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('share_test');
    // A real store over a temporary directory: these tests assert on the bytes
    // that reach the share sheet, so resolution has to produce a real file.
    store = FilesystemPublicFileStore(temporary);
    store.initialise();
    testFiles = PublicStoreDocumentFileResolver(store);
  });

  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  Document doc({
    String title = 'Invoice',
    bool isProtected = false,
    bool hasRecognisedText = false,
    String? filePath,
  }) => Document(
    id: id,
    title: title,
    createdAt: DateTime.utc(2026, 3, 14),
    updatedAt: DateTime.utc(2026, 3, 14),
    pageCount: 2,
    sizeInBytes: 1024,
    libraryPath: LibraryPath.parse(filePath ?? 'a.pdf'),
    isProtected: isProtected,
    hasRecognisedText: hasRecognisedText,
  );

  /// Writes a stand-in PDF into the library so resolution finds one.
  File writeStoredPdf({String contents = '%PDF-1.7 protected bytes'}) {
    final file = File('${temporary.path}/DocScanly/a.pdf')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(contents);
    return file;
  }

  DocumentPage page(int order) => DocumentPage(
    id: PageId('p$order'),
    documentId: id,
    order: order,
    imagePath: '${temporary.path}/page_$order.jpg',
  );

  group('ShareDocumentPdf', () {
    test('hands the stored file to the share sheet', () async {
      final stored = writeStoredPdf();
      final share = FakeShareRepository();

      final result = await ShareDocumentPdf(
        _Reader(document: doc()),
        share,
        testFiles,
      )(id);

      expect(result, isA<Success<void>>());
      expect(share.shared.single.filePaths, [stored.path]);
      expect(share.shared.single.subject, 'Invoice');
    });

    test('shares a protected document as-is, touching no password', () async {
      // The protection lives in the bytes on disk. The guarantee is that the
      // use case shares the very same file and carries no text alongside it.
      const secret = 'hunter2';
      final stored = writeStoredPdf();
      final share = FakeShareRepository();

      await ShareDocumentPdf(
        _Reader(document: doc(isProtected: true)),
        share,
        testFiles,
      )(id);

      final payload = share.shared.single;
      expect(payload.filePaths, [stored.path]);
      expect(payload.text, isEmpty);
      expect(payload.subject, isNot(contains(secret)));
      expect(stored.readAsStringSync(), '%PDF-1.7 protected bytes');
    });

    test('fails when the stored file is missing', () async {
      final share = FakeShareRepository();

      final result = await ShareDocumentPdf(
        _Reader(document: doc(filePath: 'gone.pdf')),
        share,
        testFiles,
      )(id);

      expect(result, isA<Failed<void>>());
      expect(share.shared, isEmpty);
    });

    test('propagates a lookup failure without sharing', () async {
      final share = FakeShareRepository();

      final result = await ShareDocumentPdf(
        _Reader(failure: const Failure.storage()),
        share,
        testFiles,
      )(id);

      expect(result, isA<Failed<void>>());
      expect(share.shared, isEmpty);
    });
  });

  group('SharePageImages', () {
    /// A job that writes a marker file, standing in for a rendered image.
    String renderJob(SharePageRequest request) {
      File(request.destinationPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('image of ${request.page.imagePath}');
      return request.destinationPath;
    }

    /// A job that always fails.
    String failingJob(SharePageRequest request) =>
        throw const FormatException('undecodable');

    SharePageImages build(
      FakeShareRepository share, {
      List<DocumentPage> pages = const [],
      IsolateJob<SharePageRequest, String>? job,
    }) => SharePageImages(
      _Reader(document: doc(), pages: pages),
      share,
      const InlineBackgroundWorker(),
      () => temporary,
      job ?? renderJob,
    );

    test(
      'shares every page in page order, whatever order they arrive',
      () async {
        final share = FakeShareRepository();
        // Deliberately out of order, as a tap-ordered selection would be.
        final events = await build(share, pages: [page(1), page(0)])(
          id,
        ).toList();

        expect(events.whereType<SharePreparationReady>(), hasLength(1));
        expect(share.shared.single.filePaths, [
          '${temporary.path}/Invoice_001.jpg',
          '${temporary.path}/Invoice_002.jpg',
        ]);
      },
    );

    test('reports progress per page', () async {
      final share = FakeShareRepository();

      final events = await build(share, pages: [page(0), page(1)])(id).toList();

      final progress = events
          .whereType<SharePreparationProgress>()
          .map((e) => e.progress.completed)
          .toList();

      expect(progress, [1, 2]);
    });

    test('shares only the selected pages', () async {
      final share = FakeShareRepository();

      await build(share, pages: [page(0), page(1)])(
        id,
        pageIds: [const PageId('p1')],
      ).toList();

      expect(share.shared.single.filePaths, hasLength(1));
    });

    test(
      'fails and leaves nothing staged when a page cannot be rendered',
      () async {
        final share = FakeShareRepository();

        final events = await build(share, pages: [page(0)], job: failingJob)(
          id,
        ).toList();

        expect(events.last, isA<SharePreparationFailed>());
        expect(share.shared, isEmpty);
        expect(
          temporary.listSync().where((e) => e.path.endsWith('.jpg')),
          isEmpty,
        );
      },
    );

    test('removes already-rendered pages when a later one fails', () async {
      // The guarantee is that a partial set is never handed over and never left
      // behind: half a document looks like data loss.
      var calls = 0;
      String flakyJob(SharePageRequest request) {
        calls++;
        if (calls > 1) throw const FormatException('undecodable');
        return renderJob(request);
      }

      final share = FakeShareRepository();

      final events = await build(
        share,
        pages: [page(0), page(1)],
        job: flakyJob,
      )(id).toList();

      expect(events.last, isA<SharePreparationFailed>());
      expect(
        temporary.listSync().where((e) => e.path.endsWith('.jpg')),
        isEmpty,
      );
    });

    test('stops and cleans up when cancelled', () async {
      final share = FakeShareRepository();
      final token = CancellationToken()..cancel();

      final events = await build(share, pages: [page(0), page(1)])(
        id,
        token: token,
      ).toList();

      final failed = events.last as SharePreparationFailed;
      expect(failed.failure.isCancellation, isTrue);
      expect(share.shared, isEmpty);
    });

    test('fails when the selection matches no page', () async {
      final share = FakeShareRepository();

      final events = await build(share, pages: [page(0)])(
        id,
        pageIds: [const PageId('missing')],
      ).toList();

      expect(events.single, isA<SharePreparationFailed>());
    });

    test('reports a share-sheet failure', () async {
      final share = FakeShareRepository(
        failure: const Failure.export(noReceivingApp: true),
      );

      final events = await build(share, pages: [page(0)])(id).toList();

      expect(events.last, isA<SharePreparationFailed>());
    });

    test('propagates a document lookup failure', () async {
      final events = await SharePageImages(
        _Reader(failure: const Failure.storage()),
        FakeShareRepository(),
        const InlineBackgroundWorker(),
        () => temporary,
        renderJob,
      )(id).toList();

      expect(events.single, isA<SharePreparationFailed>());
    });
  });

  group('PrintDocument', () {
    test('submits the stored file under the sanitised title', () async {
      writeStoredPdf();
      final printer = FakePrintRepository();

      final result = await PrintDocument(
        _Reader(document: doc(title: 'Invoice/2026')),
        printer,
        testFiles,
      )(id);

      expect(result, isA<Success<bool>>());
      expect(printer.printed.single.$2, 'Invoice 2026');
    });

    test('reports a dismissed dialogue as a successful false', () async {
      writeStoredPdf();
      // The spec requires no message and no change when the user cancels, which
      // an error result could not express.
      final result = await PrintDocument(
        _Reader(document: doc()),
        FakePrintRepository(submitted: false),
        testFiles,
      )(id);

      expect((result as Success<bool>).value, isFalse);
    });

    test('propagates a print failure', () async {
      final result = await PrintDocument(
        _Reader(document: doc()),
        FakePrintRepository(failure: const Failure.export()),
        testFiles,
      )(id);

      expect(result, isA<Failed<bool>>());
    });
  });

  group('ExportDocument', () {
    test('copies the document to the chosen destination', () async {
      writeStoredPdf(contents: 'the document');
      final destination = '${temporary.path}/exported.pdf';

      final result = await ExportDocument(
        _Reader(document: doc()),
        FakeExportDestinationPicker(destination: destination),
        testFiles,
      )(id);

      expect(
        (result as Success<DocumentExportResult>).value,
        DocumentExportResult.completed(destinationLabel: destination),
      );
      expect(File(destination).readAsStringSync(), 'the document');
    });

    test('leaves the source in place', () async {
      final stored = writeStoredPdf();

      await ExportDocument(
        _Reader(document: doc()),
        FakeExportDestinationPicker(
          destination: '${temporary.path}/exported.pdf',
        ),
        testFiles,
      )(id);

      expect(stored.existsSync(), isTrue);
    });

    test('offers the sanitised title as the file name', () async {
      writeStoredPdf();
      final picker = FakeExportDestinationPicker(
        destination: '${temporary.path}/exported.pdf',
      );

      await ExportDocument(
        _Reader(document: doc(title: 'a/b')),
        picker,
        testFiles,
      )(id);

      expect(picker.suggestions.single, 'a b.pdf');
    });

    test('writes nothing when the picker is cancelled', () async {
      writeStoredPdf();

      final result = await ExportDocument(
        _Reader(document: doc()),
        FakeExportDestinationPicker(),
        testFiles,
      )(id);

      expect(
        (result as Success<DocumentExportResult>).value,
        const DocumentExportResult.cancelled(),
      );
      expect(
        temporary.listSync().where((e) => e.path.endsWith('exported.pdf')),
        isEmpty,
      );
    });

    test(
      'leaves no partial file when the destination is not writable',
      () async {
        writeStoredPdf();
        final destination = '${temporary.path}/missing_dir/exported.pdf';

        final result = await ExportDocument(
          _Reader(document: doc()),
          FakeExportDestinationPicker(destination: destination),
          testFiles,
        )(id);

        expect(result, isA<Failed<DocumentExportResult>>());
        expect(File(destination).existsSync(), isFalse);
        expect(File('$destination.partial').existsSync(), isFalse);
      },
    );

    test('fails when the stored file is missing', () async {
      final result = await ExportDocument(
        _Reader(document: doc(filePath: 'gone.pdf')),
        FakeExportDestinationPicker(destination: '${temporary.path}/x.pdf'),
        testFiles,
      )(id);

      expect(result, isA<Failed<DocumentExportResult>>());
    });

    test('propagates a picker failure', () async {
      writeStoredPdf();

      final result = await ExportDocument(
        _Reader(document: doc()),
        FakeExportDestinationPicker(failure: const Failure.export()),
        testFiles,
      )(id);

      expect(result, isA<Failed<DocumentExportResult>>());
    });
  });
}
