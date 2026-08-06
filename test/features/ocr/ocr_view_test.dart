/// Widget tests for the extracted-text view.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_cubit.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_state.dart';
import 'package:doc_scanly/features/ocr/presentation/ocr_keys.dart';
import 'package:doc_scanly/features/ocr/presentation/screens/extracted_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ocr_test_support.dart';

void main() {
  late OcrHarness harness;

  setUp(() => harness = OcrHarness());

  Future<OcrCubit> pump(
    WidgetTester tester, {
    OcrCubit? cubit,
    Brightness brightness = Brightness.light,
    Size viewport = const Size(600, 900),
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final active = cubit ?? harness.build();
    addTearDown(active.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: BlocProvider<OcrCubit>.value(
            value: active,
            child: const ExtractedTextView(),
          ),
        ),
      ),
    );
    // Bounded rather than `pumpAndSettle`: the view opens on an indefinite
    // progress indicator, which never settles.
    await tester.pump();
    await tester.pump();

    return active;
  }

  group('composition', () {
    testWidgets('shows the view and its controls', (tester) async {
      await pump(tester);

      expect(find.byKey(OcrKeys.textView), findsOneWidget);
      expect(find.byKey(OcrKeys.copyTextButton), findsOneWidget);
      expect(find.byKey(OcrKeys.exportTextButton), findsOneWidget);
    });

    testWidgets('offers to extract text on a document never recognised', (
      tester,
    ) async {
      final cubit = await pump(tester);
      await cubit.load();
      await tester.pumpAndSettle();

      expect(find.byKey(OcrKeys.emptyState), findsOneWidget);
      expect(find.byKey(OcrKeys.recogniseButton), findsOneWidget);
      // Re-running something never run makes no sense, so it is not offered.
      expect(find.byKey(OcrKeys.rerunButton), findsNothing);
    });

    testWidgets('shows the recognised text once it exists', (tester) async {
      final cubit = await pump(tester);
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(find.byKey(OcrKeys.textScrollView), findsOneWidget);
      expect(find.textContaining('INVOICE'), findsOneWidget);
      expect(find.byKey(OcrKeys.rerunButton), findsOneWidget);
    });
  });

  group('copy and export', () {
    testWidgets('are unavailable before anything is recognised', (
      tester,
    ) async {
      await pump(tester);

      expect(
        tester.widget<IconButton>(find.byKey(OcrKeys.copyTextButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(OcrKeys.exportTextButton))
            .onPressed,
        isNull,
      );
    });

    testWidgets('copying shows a confirmation', (tester) async {
      final cubit = await pump(tester);
      await cubit.recognise();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(OcrKeys.copyTextButton));
      await tester.pump();

      expect(harness.copied, hasLength(1));
      expect(find.text('Text copied to clipboard'), findsOneWidget);
    });

    testWidgets('exporting requests a file', (tester) async {
      final cubit = await pump(tester);
      await cubit.recognise();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(OcrKeys.exportTextButton));
      await tester.pumpAndSettle();

      expect(harness.exported, hasLength(1));
    });

    testWidgets('are unavailable when recognition found nothing', (
      tester,
    ) async {
      final cubit = harness.build(
        recogniser: FakeOcrRepository(emptyFor: {'a', 'b', 'c'}),
      );
      await pump(tester, cubit: cubit);
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(
        tester.widget<IconButton>(find.byKey(OcrKeys.copyTextButton)).onPressed,
        isNull,
      );
    });
  });

  group('states', () {
    testWidgets('shows an empty state when nothing was legible', (
      tester,
    ) async {
      final cubit = harness.build(
        recogniser: FakeOcrRepository(emptyFor: {'a', 'b', 'c'}),
      );
      await pump(tester, cubit: cubit);
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(find.byKey(OcrKeys.emptyState), findsOneWidget);
      expect(find.text('No text found'), findsOneWidget);
      // Distinguished from "not read yet": offering to try again would imply
      // the result was a failure.
      expect(find.byKey(OcrKeys.recogniseButton), findsNothing);
    });

    testWidgets('shows an error view with a retry when recognition fails', (
      tester,
    ) async {
      final cubit = harness.build(
        recogniser: FakeOcrRepository(failure: const Failure.ocr()),
      );
      await pump(tester, cubit: cubit);
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(find.byKey(OcrKeys.errorView), findsOneWidget);
      expect(find.byKey(OcrKeys.errorRetryButton), findsOneWidget);
    });

    testWidgets('shows progress and a cancel control while running', (
      tester,
    ) async {
      final cubit = await pump(tester);

      // Seeded directly rather than by holding a recognition open. A gated fake
      // completes on a real timer, and `testWidgets` runs in a fake-async zone
      // where such a timer never fires — the test would hang rather than fail.
      _StateHolder(cubit).set(
        OcrState.initial(testPages()).copyWith(
          status: OcrStatus.running,
          progress: const Progress(completed: 1, total: 3),
        ),
      );
      await tester.pump();

      expect(find.byKey(OcrKeys.progressIndicator), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Extracting text — 1 of 3'), findsOneWidget);
    });
  });

  group('long text', () {
    testWidgets('scrolls rather than truncating', (tester) async {
      final cubit = harness.build(
        recogniser: FakeOcrRepository(
          blocks: [
            for (var index = 0; index < 200; index++)
              FakeOcrRepository.defaultBlocks.first,
          ],
        ),
      );
      await pump(tester, cubit: cubit);
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(find.byKey(OcrKeys.textScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byKey(OcrKeys.textScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('exposes the recognised text as readable content', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final cubit = await pump(tester);
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('Recognised text')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('labels the copy, export and re-run controls', (tester) async {
      final handle = tester.ensureSemantics();
      final cubit = await pump(tester);
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Copy recognised text')),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.bySemanticsLabel(RegExp('Export recognised text')),
        findsAtLeastNWidgets(1),
      );
      expect(find.bySemanticsLabel(RegExp('Run again')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      final cubit = await pump(tester);
      await cubit.recognise();
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      final cubit = await pump(tester, brightness: Brightness.dark);
      await cubit.recognise();
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives a tablet viewport at double text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = harness.build();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: Scaffold(
            body: BlocProvider<OcrCubit>.value(
              value: cubit,
              child: const ExtractedTextView(),
            ),
          ),
        ),
      );
      await cubit.recognise();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Drives a Cubit to a chosen state from a test.
///
/// `emit` is protected, and a recognition caught mid-run cannot be reached
/// through the public API inside a widget test: holding one open needs a real
/// timer, and `testWidgets` runs in a fake-async zone where one never fires.
class _StateHolder {
  _StateHolder(this._cubit);

  final OcrCubit _cubit;

  void set(OcrState state) => _cubit.emit(state);
}
