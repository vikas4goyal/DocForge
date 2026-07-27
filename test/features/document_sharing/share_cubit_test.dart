/// Cubit tests for the sharing options.
///
/// The use cases are the real ones over fake platform seams, because what these
/// tests are really asserting is the state sequence the UI renders — and a
/// mocked use case would let the Cubit and the use case disagree about what a
/// cancelled picker or a dismissed print dialogue means.
library;

import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:doc_forge/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _Reader implements DocumentReader {
  _Reader({required this.document, this.pages = const []});

  final Document document;
  final List<DocumentPage> pages;

  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      Result<Document>.success(document);

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

class _Text implements OcrTextSource {
  _Text(this.text);

  final String text;

  @override
  Future<Result<RecognisedText?>> textForPage(PageId pageId) async =>
      const Result<RecognisedText?>.success(null);

  @override
  Future<Result<String>> textForDocument(DocumentId documentId) async =>
      Result<String>.success(text);
}

void main() {
  const id = DocumentId('a');
  late Directory temporary;

  setUp(() => temporary = Directory.systemTemp.createTempSync('share_cubit'));
  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  Document doc({bool hasRecognisedText = false}) => Document(
    id: id,
    title: 'Invoice',
    createdAt: DateTime.utc(2026, 3, 14),
    updatedAt: DateTime.utc(2026, 3, 14),
    pageCount: 2,
    sizeInBytes: 1024,
    filePath: '${temporary.path}/a.pdf',
    hasRecognisedText: hasRecognisedText,
  );

  DocumentPage page(int order) => DocumentPage(
    id: PageId('p$order'),
    documentId: id,
    order: order,
    imagePath: '${temporary.path}/page_$order.jpg',
  );

  String renderJob(SharePageRequest request) {
    File(request.destinationPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('image');
    return request.destinationPath;
  }

  ShareCubit build({
    FakeShareRepository? share,
    FakePrintRepository? printer,
    FakeExportDestinationPicker? picker,
    List<DocumentPage> pages = const [],
    String text = '',
    bool hasRecognisedText = false,
    IsolateJob<SharePageRequest, String>? job,
  }) {
    File('${temporary.path}/a.pdf').writeAsStringSync('%PDF');

    final reader = _Reader(
      document: doc(hasRecognisedText: hasRecognisedText),
      pages: pages,
    );
    final sharing = share ?? FakeShareRepository();

    return ShareCubit(
      id,
      ShareDocumentPdf(reader, sharing),
      SharePageImages(
        reader,
        sharing,
        const InlineBackgroundWorker(),
        () => temporary,
        job ?? renderJob,
      ),
      ShareExtractedText(reader, _Text(text), sharing),
      PrintDocument(reader, printer ?? FakePrintRepository()),
      ExportDocument(reader, picker ?? FakeExportDestinationPicker()),
      initial: ShareState.initial(
        title: 'Invoice',
        pageCount: 2,
        canShareText: hasRecognisedText,
      ),
    );
  }

  group('sharePdf', () {
    blocTest<ShareCubit, ShareState>(
      'prepares then reports done',
      build: build,
      act: (cubit) => cubit.sharePdf(),
      expect: () => [
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.preparing)
            .having((s) => s.format, 'format', ShareFormat.pdf),
        isA<ShareState>().having((s) => s.status, 'status', ShareStatus.done),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'reports a failure with its message',
      build: () =>
          build(share: FakeShareRepository(failure: const Failure.export())),
      act: (cubit) => cubit.sharePdf(),
      skip: 1,
      expect: () => [
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.failure)
            .having((s) => s.message, 'message', isNotNull),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'offers export when nothing can receive the share',
      build: () => build(
        share: FakeShareRepository(
          failure: const Failure.export(noReceivingApp: true),
        ),
      ),
      act: (cubit) => cubit.sharePdf(),
      skip: 1,
      expect: () => [
        isA<ShareState>().having(
          (s) => s.canOfferExportInstead,
          'canOfferExportInstead',
          isTrue,
        ),
      ],
    );
  });

  group('shareImages', () {
    blocTest<ShareCubit, ShareState>(
      'emits progress per page before reporting done',
      build: () => build(pages: [page(0), page(1)]),
      act: (cubit) => cubit.shareImages(),
      expect: () => [
        isA<ShareState>().having(
          (s) => s.status,
          'status',
          ShareStatus.preparing,
        ),
        isA<ShareState>().having((s) => s.progress?.completed, 'completed', 1),
        isA<ShareState>().having((s) => s.progress?.completed, 'completed', 2),
        isA<ShareState>().having((s) => s.status, 'status', ShareStatus.done),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'returns to the options when cancelled, saying nothing',
      build: () => build(pages: [page(0), page(1)]),
      act: (cubit) async {
        // Cancelled before the stream is subscribed, so the batch stops at its
        // first check rather than racing the first render.
        cubit.cancel();
        final pending = cubit.shareImages();
        cubit.cancel();
        await pending;
      },
      expect: () => [
        isA<ShareState>().having(
          (s) => s.status,
          'status',
          ShareStatus.preparing,
        ),
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.idle)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'reports a render failure',
      build: () => build(
        pages: [page(0)],
        job: (_) => throw const FormatException('undecodable'),
      ),
      act: (cubit) => cubit.shareImages(),
      skip: 1,
      expect: () => [
        isA<ShareState>().having(
          (s) => s.status,
          'status',
          ShareStatus.failure,
        ),
      ],
    );
  });

  group('shareText', () {
    blocTest<ShareCubit, ShareState>(
      'shares the recognised text',
      build: () => build(hasRecognisedText: true, text: 'Acme'),
      act: (cubit) => cubit.shareText(),
      expect: () => [
        isA<ShareState>().having((s) => s.format, 'format', ShareFormat.text),
        isA<ShareState>().having((s) => s.status, 'status', ShareStatus.done),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'fails when there is no text',
      build: build,
      act: (cubit) => cubit.shareText(),
      skip: 1,
      expect: () => [
        isA<ShareState>().having(
          (s) => s.status,
          'status',
          ShareStatus.failure,
        ),
      ],
    );
  });

  group('print', () {
    blocTest<ShareCubit, ShareState>(
      'reports done when the job was submitted',
      build: build,
      act: (cubit) => cubit.printDocument(),
      expect: () => [
        isA<ShareState>().having((s) => s.action, 'action', ShareAction.print),
        isA<ShareState>().having((s) => s.status, 'status', ShareStatus.done),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'returns to the options when the dialogue is dismissed',
      build: () => build(printer: FakePrintRepository(submitted: false)),
      act: (cubit) => cubit.printDocument(),
      skip: 1,
      expect: () => [
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.idle)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'reports a print failure',
      build: () =>
          build(printer: FakePrintRepository(failure: const Failure.export())),
      act: (cubit) => cubit.printDocument(),
      skip: 1,
      expect: () => [
        isA<ShareState>().having(
          (s) => s.status,
          'status',
          ShareStatus.failure,
        ),
      ],
    );
  });

  group('export', () {
    blocTest<ShareCubit, ShareState>(
      'confirms the destination once written',
      build: () => build(
        picker: FakeExportDestinationPicker(
          destination: '${Directory.systemTemp.path}/never_written.pdf',
        ),
      ),
      act: (cubit) => cubit.export(),
      skip: 1,
      expect: () => [
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.done)
            .having(
              (s) => s.exportConfirmation,
              'exportConfirmation',
              contains('never_written.pdf'),
            ),
      ],
      tearDown: () {
        final written = File('${Directory.systemTemp.path}/never_written.pdf');
        if (written.existsSync()) written.deleteSync();
      },
    );

    blocTest<ShareCubit, ShareState>(
      'says nothing when the picker is cancelled',
      build: build,
      act: (cubit) => cubit.export(),
      skip: 1,
      expect: () => [
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.idle)
            .having((s) => s.exportedTo, 'exportedTo', isNull),
      ],
    );
  });

  group('dismissError', () {
    blocTest<ShareCubit, ShareState>(
      'returns to the options',
      build: () =>
          build(share: FakeShareRepository(failure: const Failure.export())),
      act: (cubit) async {
        await cubit.sharePdf();
        cubit.dismissError();
      },
      skip: 2,
      expect: () => [
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.idle)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );
  });
}
