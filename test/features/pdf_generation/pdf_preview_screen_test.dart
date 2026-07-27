/// Widget tests for the document preview and save screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_cubit.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_state.dart';
import 'package:doc_forge/features/pdf_generation/presentation/pdf_keys.dart';
import 'package:doc_forge/features/pdf_generation/presentation/screens/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_support.dart';

void main() {
  late FakePdfComposer composer;
  late RecordingDocumentWriter writer;
  late Document? savedDocument;
  late int backCount;

  setUp(() {
    composer = FakePdfComposer();
    writer = RecordingDocumentWriter();
    savedDocument = null;
    backCount = 0;
  });

  List<PageRef> pages(int count) => [
    for (var index = 0; index < count; index++)
      PageRef(id: PageId('page-$index'), imagePath: '/page-$index.jpg'),
  ];

  PdfGenerationCubit buildCubit({int pageCount = 3}) => PdfGenerationCubit(
    pages(pageCount),
    SaveDocument(
      BuildSearchablePdf(composer, (_) async => const {}),
      writer,
      FixedClock(DateTime.utc(2026, 3, 14, 9, 30)),
      SequentialIdGenerator(prefix: 'doc'),
      (id) => '/documents/${id.value}.pdf',
      (path) async {},
    ),
    GenerateDocumentName(
      FixedClock(DateTime(2026, 3, 14, 9, 30)),
      StubDocumentReader(),
    ),
    source: PageSource.camera,
    pattern: NamingPattern.dateOnly,
  );

  Future<PdfGenerationCubit> pump(
    WidgetTester tester, {
    PdfGenerationCubit? cubit,
    Size viewport = const Size(600, 1000),
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final active = cubit ?? buildCubit();
    addTearDown(active.close);
    await active.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<PdfGenerationCubit>.value(
          value: active,
          child: PdfPreviewScreen(
            onSaved: (document) => savedDocument = document,
            onBack: () => backCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return active;
  }

  group('composition', () {
    testWidgets('shows the name field, quality choice and save control', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(PdfKeys.previewScreen), findsOneWidget);
      expect(find.byKey(PdfKeys.documentNameField), findsOneWidget);
      expect(find.byKey(PdfKeys.qualitySelector), findsOneWidget);
      expect(find.byKey(PdfKeys.saveButton), findsOneWidget);
    });

    testWidgets('shows a preview for every page', (tester) async {
      await pump(tester);

      expect(find.byKey(PdfKeys.pageList), findsOneWidget);
      expect(find.byKey(PdfKeys.pageItem('page-0')), findsOneWidget);
      expect(find.byKey(PdfKeys.pageItem('page-2')), findsOneWidget);
    });

    testWidgets('shows the generated name in the field, not as a hint', (
      tester,
    ) async {
      // A user who saves without typing must get the name they can see rather
      // than one they have to guess.
      await pump(tester);

      expect(find.text('Scan 2026-03-14'), findsOneWidget);
    });

    testWidgets('names the save control with the page count', (tester) async {
      await pump(tester);

      expect(find.text('Save 3-page document'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('writes the document and reports it', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(PdfKeys.saveButton));
      await tester.pumpAndSettle();

      expect(writer.saved, hasLength(1));
      expect(savedDocument, isNotNull);
    });

    testWidgets('an edited name is what gets saved', (tester) async {
      await pump(tester);

      await tester.enterText(find.byKey(PdfKeys.documentNameField), 'Receipts');
      await tester.tap(find.byKey(PdfKeys.saveButton));
      await tester.pumpAndSettle();

      expect(writer.saved.single.title, 'Receipts');
    });

    testWidgets('the chosen quality is applied', (tester) async {
      await pump(tester);

      await tester.tap(find.text(PdfQuality.high.label));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PdfKeys.saveButton));
      await tester.pumpAndSettle();

      expect(composer.requests.single.quality, PdfQuality.high);
    });
  });

  group('leaving without saving', () {
    testWidgets('preserves the session and writes no PDF', (tester) async {
      final cubit = await pump(tester);

      await tester.enterText(find.byKey(PdfKeys.documentNameField), 'Receipts');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(backCount, 1);
      // The session is intact and nothing was composed.
      expect(cubit.state.pages, hasLength(3));
      expect(composer.requests, isEmpty);
      expect(writer.saved, isEmpty);
    });
  });

  group('states', () {
    testWidgets('shows progress and a cancel control while generating', (
      tester,
    ) async {
      final cubit = await pump(tester);

      // Seeded directly: the fake composer finishes within one frame, so the
      // generating state would never be observable through a real save.
      _StateHolder(
        cubit,
      ).set(cubit.state.copyWith(status: PdfGenerationStatus.generating));
      // Two pumps, and bounded rather than `pumpAndSettle`: a Cubit delivers
      // its state on a microtask, so one frame rebuilds nothing — and the
      // progress bar is indefinite, so settling never completes.
      await tester.pump();
      await tester.pump();

      expect(find.byKey(PdfKeys.generationProgress), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows an error view with a retry when generation fails', (
      tester,
    ) async {
      composer.failure = const Failure.pdf();
      await pump(tester);

      await tester.tap(find.byKey(PdfKeys.saveButton));
      await tester.pumpAndSettle();

      expect(find.byKey(PdfKeys.errorView), findsOneWidget);
      expect(find.byKey(PdfKeys.errorRetryButton), findsOneWidget);
    });

    testWidgets('retrying after a failure saves', (tester) async {
      composer.failure = const Failure.pdf();
      await pump(tester);

      await tester.tap(find.byKey(PdfKeys.saveButton));
      await tester.pumpAndSettle();

      composer.failure = null;
      await tester.tap(find.byKey(PdfKeys.errorRetryButton));
      await tester.pumpAndSettle();

      expect(writer.saved, hasLength(1));
    });

    testWidgets('a session with no pages cannot be saved', (tester) async {
      await pump(tester, cubit: buildCubit(pageCount: 0));

      expect(
        tester.widget<FilledButton>(find.byKey(PdfKeys.saveButton)).onPressed,
        isNull,
      );
      expect(find.text('No pages'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('a tablet viewport uses the extra width for more pages', (
      tester,
    ) async {
      await pump(
        tester,
        cubit: buildCubit(pageCount: 8),
        viewport: const Size(1280, 1000),
      );

      final grid = tester.widget<GridView>(find.byKey(PdfKeys.pageList));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;

      expect(delegate.maxCrossAxisExtent, lessThan(1280));
      expect(tester.takeException(), isNull);
    });

    testWidgets('neither viewport overflows', (tester) async {
      for (final size in [const Size(390, 844), const Size(1280, 1000)]) {
        await pump(tester, viewport: size);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('accessibility', () {
    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, brightness: Brightness.dark);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('the quality control announces its current value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(
        tester.getSemantics(find.byKey(PdfKeys.qualitySelector)),
        isSemantics(
          label: 'Document quality',
          value: PdfQuality.defaultQuality.label,
        ),
      );

      handle.dispose();
    });

    testWidgets('each page announces its number', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsLabel('Page 1'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('survives the largest supported text scale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<PdfGenerationCubit>.value(
            value: cubit,
            child: PdfPreviewScreen(onSaved: (_) {}, onBack: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Drives a Cubit to a chosen state from a test.
///
/// `emit` is protected, and a generation caught mid-run cannot be reached
/// through the public API in a widget test: the fake composer finishes within
/// one frame.
class _StateHolder {
  _StateHolder(this._cubit);

  final PdfGenerationCubit _cubit;

  void set(PdfGenerationState state) => _cubit.emit(state);
}
