/// Widget tests for the share options sheet.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:doc_forge/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:doc_forge/features/document_sharing/presentation/screens/share_options_sheet.dart';
import 'package:doc_forge/features/document_sharing/presentation/share_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collaborators the stub Cubit never reaches, because every method that would
/// use one is overridden below. They exist only to satisfy the constructor.
final _reader = _InertReader();
final _share = FakeShareRepository();
final _printer = FakePrintRepository();
final _picker = FakeExportDestinationPicker();
final _text = _InertText();

Directory _staging() => Directory.systemTemp;

String _neverRendered(SharePageRequest request) =>
    throw StateError('the stub Cubit never renders');

/// A document reader that finds nothing.
class _InertReader implements DocumentReader {
  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      const Result<Document>.failure(Failure.notFound());

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
      const Result<List<DocumentPage>>.success([]);
}

/// A text source with nothing in it.
class _InertText implements OcrTextSource {
  @override
  Future<Result<RecognisedText?>> textForPage(PageId pageId) async =>
      const Result<RecognisedText?>.success(null);

  @override
  Future<Result<String>> textForDocument(DocumentId documentId) async =>
      const Result<String>.success('');
}

/// A Cubit frozen at a chosen state that records what was asked of it.
///
/// The sheet's job is to offer the right controls and route a tap to the right
/// method; whether the method then works is the Cubit test's business. Freezing
/// the state is what lets a single test render the progress and error views
/// without having to drive a whole share to reach them.
class _StubCubit extends ShareCubit {
  _StubCubit(this._seeded)
    : super(
        const DocumentId('a'),
        ShareDocumentPdf(_reader, _share),
        SharePageImages(
          _reader,
          _share,
          const InlineBackgroundWorker(),
          _staging,
          _neverRendered,
        ),
        ShareExtractedText(_reader, _text, _share),
        PrintDocument(_reader, _printer),
        ExportDocument(_reader, _picker),
      );

  final ShareState _seeded;

  final List<String> calls = [];

  @override
  ShareState get state => _seeded;

  @override
  Future<void> sharePdf() async => calls.add('pdf');

  @override
  Future<void> shareImages({List<PageId> pageIds = const []}) async =>
      calls.add('images');

  @override
  Future<void> shareText() async => calls.add('text');

  @override
  Future<void> printDocument() async => calls.add('print');

  @override
  Future<void> export({String? initialDirectory}) async => calls.add('export');

  @override
  void cancel() => calls.add('cancel');

  @override
  void dismissError() => calls.add('dismiss');
}

void main() {
  Future<_StubCubit> pump(
    WidgetTester tester,
    ShareState state, {
    Brightness brightness = Brightness.light,
    Size viewport = const Size(600, 1200),
    VoidCallback? onRunRecognition,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _StubCubit(state);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: BlocProvider<ShareCubit>.value(
            value: cubit,
            child: ShareOptionsSheet(onRunRecognition: onRunRecognition),
          ),
        ),
      ),
    );
    await tester.pump();

    return cubit;
  }

  const withText = ShareState.initial(
    title: 'Invoice',
    pageCount: 3,
    canShareText: true,
  );
  const withoutText = ShareState.initial(title: 'Invoice', pageCount: 3);

  group('options', () {
    testWidgets('offers every share, print and export control', (tester) async {
      await pump(tester, withText);

      expect(find.byKey(ShareKeys.sheet), findsOneWidget);
      expect(find.byKey(ShareKeys.pdfButton), findsOneWidget);
      expect(find.byKey(ShareKeys.imagesButton), findsOneWidget);
      expect(find.byKey(ShareKeys.textButton), findsOneWidget);
      expect(find.byKey(ShareKeys.printButton), findsOneWidget);
      expect(find.byKey(ShareKeys.exportButton), findsOneWidget);
    });

    testWidgets('each option routes to its own action', (tester) async {
      final cubit = await pump(tester, withText);

      for (final key in [
        ShareKeys.pdfButton,
        ShareKeys.imagesButton,
        ShareKeys.textButton,
        ShareKeys.printButton,
        ShareKeys.exportButton,
      ]) {
        await tester.tap(find.byKey(key));
        await tester.pump();
      }

      expect(cubit.calls, ['pdf', 'images', 'text', 'print', 'export']);
    });

    testWidgets('shows the document title', (tester) async {
      await pump(tester, withText);

      expect(find.text('Invoice'), findsOneWidget);
    });
  });

  group('no recognised text', () {
    testWidgets('disables the text control and explains why', (tester) async {
      final cubit = await pump(tester, withoutText);

      expect(find.byKey(ShareKeys.noTextMessage), findsOneWidget);

      await tester.tap(find.byKey(ShareKeys.textButton));
      await tester.pump();

      expect(cubit.calls, isEmpty);
    });

    testWidgets('offers to run recognition when a handler is supplied', (
      tester,
    ) async {
      var asked = 0;
      await pump(tester, withoutText, onRunRecognition: () => asked++);

      await tester.tap(find.byKey(ShareKeys.runRecognitionButton));
      await tester.pump();

      expect(asked, 1);
    });

    testWidgets('offers no recognition control without a handler', (
      tester,
    ) async {
      await pump(tester, withoutText);

      expect(find.byKey(ShareKeys.runRecognitionButton), findsNothing);
    });
  });

  group('preparing', () {
    testWidgets('shows progress with the page being prepared', (tester) async {
      await pump(
        tester,
        withText.copyWith(
          status: ShareStatus.preparing,
          format: ShareFormat.images,
          progress: const Progress(completed: 1, total: 3),
        ),
      );

      expect(find.byKey(ShareKeys.progressIndicator), findsOneWidget);
      expect(find.textContaining('Preparing page 1 of 3'), findsOneWidget);
    });

    testWidgets('offers cancellation while pages are rendered', (tester) async {
      final cubit = await pump(
        tester,
        withText.copyWith(
          status: ShareStatus.preparing,
          format: ShareFormat.images,
          progress: const Progress(completed: 1, total: 3),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cubit.calls, ['cancel']);
    });

    testWidgets('offers no cancellation for a single-file hand-off', (
      tester,
    ) async {
      // There is nothing to cancel: handing one existing file to the share
      // sheet completes before a control could be pressed.
      await pump(
        tester,
        withText.copyWith(
          status: ShareStatus.preparing,
          format: ShareFormat.pdf,
        ),
      );

      expect(find.text('Cancel'), findsNothing);
    });
  });

  group('failures', () {
    testWidgets('shows the error view with a recovery control', (tester) async {
      await pump(
        tester,
        withText.copyWith(
          status: ShareStatus.failure,
          failure: const Failure.storageFull(),
        ),
      );

      expect(find.byKey(ShareKeys.errorView), findsOneWidget);
      expect(find.byKey(ShareKeys.errorRetryButton), findsOneWidget);
    });

    testWidgets('offers export when nothing can receive the share', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        withText.copyWith(
          status: ShareStatus.failure,
          failure: const Failure.export(noReceivingApp: true),
        ),
      );

      await tester.tap(find.byKey(ShareKeys.errorExportButton));
      await tester.pump();

      expect(cubit.calls, ['export']);
    });

    testWidgets('offers no export alternative for other failures', (
      tester,
    ) async {
      await pump(
        tester,
        withText.copyWith(
          status: ShareStatus.failure,
          failure: const Failure.storageFull(),
        ),
      );

      expect(find.byKey(ShareKeys.errorExportButton), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('each option names what is shared and in what format', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, withText);

      expect(
        find.bySemanticsLabel('Share the document "Invoice" as a PDF'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Share 3 pages of "Invoice" as images'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Print .*Invoice')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Export .*to device storage')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, withText);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, withText, brightness: Brightness.dark);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives a tablet viewport at double text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = _StubCubit(withText);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: Scaffold(
            body: BlocProvider<ShareCubit>.value(
              value: cubit,
              child: const ShareOptionsSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
