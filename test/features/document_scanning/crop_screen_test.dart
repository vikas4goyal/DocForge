import 'dart:io';

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/scan_keys.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

PageQuad box(double left, double top, double right, double bottom) => PageQuad(
  topLeft: NormalisedPoint(x: left, y: top),
  topRight: NormalisedPoint(x: right, y: top),
  bottomRight: NormalisedPoint(x: right, y: bottom),
  bottomLeft: NormalisedPoint(x: left, y: bottom),
);

void main() {
  late Directory cache;
  late RenderPage renderPage;
  late List<PageDraft> continued;
  late int cancelled;

  PageDraft draft() => const PageDraft(
    id: PageId('page-1'),
    originalImagePath: '/staging/page-1.jpg',
  );

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('docscanly_crop_ui_');
    continued = [];
    cancelled = 0;

    renderPage = RenderPage(
      cacheDirectory: cache,
      sizeOf: (path) async => const Result<({int width, int height})>.success((
        width: 1000,
        height: 800,
      )),
      render: (plan, {required destinationPath, transform}) async {
        File(destinationPath).writeAsStringSync('rendered');
        return const Result<void>.success(null);
      },
    );
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  /// Lets a Cubit emission reach the widget tree.
  ///
  /// A single pump builds the frame before the emission's microtask has been
  /// delivered, so an assertion straight after a synchronous Cubit call would
  /// read the previous frame.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  Future<CropCubit> pumpCrop(WidgetTester tester, {PageDraft? page}) async {
    final cubit = CropCubit(page ?? draft(), renderPage);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CropCubit>.value(
          value: cubit,
          child: CropScreen(
            onNext: continued.add,
            onCancelled: () => cancelled++,
          ),
        ),
      ),
    );
    await tester.pump();
    return cubit;
  }

  group('controls', () {
    testWidgets('shows apply, revert and next', (tester) async {
      await pumpCrop(tester);

      expect(find.byKey(ScanKeys.cropConfirmButton), findsOneWidget);
      expect(find.byKey(ScanKeys.cropResetButton), findsOneWidget);
      expect(find.byKey(ScanKeys.cropNextButton), findsOneWidget);
    });

    testWidgets('offers no undo control', (tester) async {
      await pumpCrop(tester);

      // Deliberate: an undo that only ever unwinds to the bottom is a flag
      // pretending to be a stack, and revert already does that job.
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('apply is disabled until something is pending', (tester) async {
      await pumpCrop(tester);

      final apply = tester.widget<FilledButton>(
        find.byKey(ScanKeys.cropConfirmButton),
      );
      expect(apply.onPressed, isNull);
    });

    testWidgets('apply becomes available once the selection moves', (
      tester,
    ) async {
      final cubit = await pumpCrop(tester);

      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);

      final apply = tester.widget<FilledButton>(
        find.byKey(ScanKeys.cropConfirmButton),
      );
      expect(apply.onPressed, isNotNull);
    });

    testWidgets('flip updates the preview before Apply', (tester) async {
      await pumpCrop(tester);
      await tester.tap(find.byKey(ScanKeys.cropFlipHorizontalButton));
      await settle(tester);

      final preview = tester.widget<Transform>(
        find.byKey(ScanKeys.cropPreview),
      );
      expect(preview.transform.entry(0, 0), -1);
    });

    testWidgets('crop handles use forgiving 64 point hit regions', (
      tester,
    ) async {
      await pumpCrop(tester);
      final handle = tester.getSize(find.byKey(ScanKeys.cropHandle(0)));
      final edge = tester.getSize(find.byKey(ScanKeys.cropEdgeHandle(0)));
      expect(handle, const Size.square(64));
      expect(edge, const Size.square(64));
    });

    testWidgets('a corner follows the finger without snapping to it', (
      tester,
    ) async {
      await pumpCrop(tester);
      final finder = find.byKey(ScanKeys.cropHandle(0));
      final before = tester.getCenter(finder);
      var detector = tester.widget<GestureDetector>(finder);
      const grabPoint = Offset(50, 44);
      const firstMovement = Offset(10, 8);
      const fingerMovement = Offset(24, 18);

      // Grab away from the visual centre, as a real fingertip usually does.
      detector.onPanDown!(
        DragDownDetails(globalPosition: grabPoint, localPosition: grabPoint),
      );
      detector.onPanStart!(
        DragStartDetails(globalPosition: grabPoint, localPosition: grabPoint),
      );
      detector.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: grabPoint + firstMovement,
          localPosition: grabPoint + firstMovement,
          delta: firstMovement,
        ),
      );
      await tester.pump();

      // A rebuild moves the handle between pointer events. The next update
      // must still be measured from the original touch-down position.
      detector = tester.widget<GestureDetector>(finder);
      detector.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: grabPoint + fingerMovement,
          localPosition: grabPoint + fingerMovement,
          delta: fingerMovement - firstMovement,
        ),
      );
      await tester.pump();

      expect(tester.getCenter(finder) - before, fingerMovement);
    });

    testWidgets('an edge follows the finger without snapping to it', (
      tester,
    ) async {
      await pumpCrop(tester);
      final finder = find.byKey(ScanKeys.cropEdgeHandle(0));
      final before = tester.getCenter(finder);
      var detector = tester.widget<GestureDetector>(finder);
      const grabPoint = Offset(50, 44);
      const firstMovement = Offset(0, 10);
      const fingerMovement = Offset(0, 24);

      detector.onPanDown!(
        DragDownDetails(globalPosition: grabPoint, localPosition: grabPoint),
      );
      detector.onPanStart!(
        DragStartDetails(globalPosition: grabPoint, localPosition: grabPoint),
      );
      detector.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: grabPoint + firstMovement,
          localPosition: grabPoint + firstMovement,
          delta: firstMovement,
        ),
      );
      await tester.pump();

      detector = tester.widget<GestureDetector>(finder);
      detector.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: grabPoint + fingerMovement,
          localPosition: grabPoint + fingerMovement,
          delta: fingerMovement - firstMovement,
        ),
      );
      await tester.pump();

      expect(tester.getCenter(finder) - before, fingerMovement);
    });

    testWidgets('revert is disabled until a crop has been applied', (
      tester,
    ) async {
      await pumpCrop(tester);

      final revert = tester.widget<TextButton>(
        find.byKey(ScanKeys.cropResetButton),
      );
      // Disabled means "nothing of my own layer to revert", not "nothing has
      // been done" — the distinction the two-layer model rests on.
      expect(revert.onPressed, isNull);
    });

    testWidgets('revert becomes available after applying', (tester) async {
      final cubit = await pumpCrop(tester);

      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await cubit.apply();
      await tester.pump();

      final revert = tester.widget<TextButton>(
        find.byKey(ScanKeys.cropResetButton),
      );
      expect(revert.onPressed, isNotNull);
    });
  });

  group('apply', () {
    testWidgets('stays on the crop screen', (tester) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);

      await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
      await tester.pumpAndSettle();

      // The whole point: the result is on screen, ready to be cropped again.
      expect(find.byKey(ScanKeys.cropScreen), findsOneWidget);
      expect(continued, isEmpty);
    });

    testWidgets('records the crop on the page', (tester) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);

      await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
      await tester.pumpAndSettle();

      expect(cubit.state.page.geometry, hasLength(1));
    });

    testWidgets('can be applied twice in a row', (tester) async {
      final cubit = await pumpCrop(tester);

      for (var i = 0; i < 2; i++) {
        cubit.adjust(box(0.1, 0.1, 0.9, 0.9));
        await settle(tester);
        await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
        await tester.pumpAndSettle();
      }

      expect(cubit.state.page.geometry, hasLength(2));
    });
  });

  group('next', () {
    testWidgets('continues when nothing is pending', (tester) async {
      await pumpCrop(tester);

      await tester.tap(find.byKey(ScanKeys.cropNextButton));
      await tester.pumpAndSettle();

      expect(continued, hasLength(1));
      expect(find.byKey(ScanKeys.cropApplyPrompt), findsNothing);
    });

    testWidgets('prompts when a change was never applied', (tester) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);

      await tester.tap(find.byKey(ScanKeys.cropNextButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.cropApplyPrompt), findsOneWidget);
      expect(continued, isEmpty);
    });

    testWidgets('confirming applies and then continues', (tester) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);
      await tester.tap(find.byKey(ScanKeys.cropNextButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.cropPromptApply));
      await tester.pumpAndSettle();

      expect(continued.single.geometry, hasLength(1));
    });

    testWidgets('declining continues without applying', (tester) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);
      await tester.tap(find.byKey(ScanKeys.cropNextButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.cropPromptSkip));
      await tester.pumpAndSettle();

      expect(continued, hasLength(1));
      expect(continued.single.hasGeometry, isFalse);
    });

    testWidgets('dismissing the prompt stays put with the change intact', (
      tester,
    ) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);
      await tester.tap(find.byKey(ScanKeys.cropNextButton));
      await tester.pumpAndSettle();

      // Tapping the barrier dismisses without answering.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(continued, isEmpty);
      expect(find.byKey(ScanKeys.cropScreen), findsOneWidget);
      expect(cubit.state.hasUnappliedChanges, isTrue);
    });

    testWidgets('does not prompt after everything has been applied', (
      tester,
    ) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);
      await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.cropNextButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.cropApplyPrompt), findsNothing);
      expect(continued, hasLength(1));
    });
  });

  group('revert', () {
    testWidgets('clears the geometry', (tester) async {
      final cubit = await pumpCrop(tester);
      cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
      await settle(tester);
      await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.cropResetButton));
      await tester.pumpAndSettle();

      expect(cubit.state.page.hasGeometry, isFalse);
    });

    testWidgets('is labelled for the layer it affects', (tester) async {
      await pumpCrop(tester);

      // Not "Reset": with two revertible layers, a bare Reset reads as
      // undo-everything, which is exactly what it must not do.
      expect(find.text('Revert to original'), findsOneWidget);
    });
  });

  group('cancel', () {
    testWidgets('leaves without continuing', (tester) async {
      await pumpCrop(tester);

      await tester.tap(find.byKey(const Key('scan_crop_cancel_button')));
      await tester.pumpAndSettle();

      expect(cancelled, 1);
      expect(continued, isEmpty);
    });
  });
}
