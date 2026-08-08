/// Widget tests for the enhancement screen and its controls.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/screens/enhancement_screen.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/widgets/enhancement_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'enhancement_test_support.dart';

void main() {
  setUp(resetJobRecording);

  /// The page every test enhances.
  PageDraft draft() =>
      const PageDraft(id: PageId('page-0'), originalImagePath: '/page-0.jpg');

  /// Plans the renderer was asked for, so a test can assert what was rendered.
  final renderedPlans = <PageRenderPlan>[];

  /// A renderer that records its plans and touches no real image.
  RenderPage testRenderer() => RenderPage(
    cacheDirectory: Directory.systemTemp.createTempSync('enhance_ui_'),
    sizeOf: (path) async => const Result<({int width, int height})>.success((
      width: 800,
      height: 600,
    )),
    render: (plan, {required destinationPath, transform, scope}) async {
      renderedPlans.add(plan);
      File(destinationPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('rendered');
      return const Result<void>.success(null);
    },
  );

  late PageDraft? doneWith;

  setUp(() {
    doneWith = null;
    renderedPlans.clear();
  });

  /// Pumps the screen over a Cubit seeded to [state].
  Future<EnhancementCubit> pumpScreen(
    WidgetTester tester, {
    EnhancementState? state,
    int pages = 3,
    Size? viewport,
  }) async {
    // Tall by default. The controls sit in a lazy ListView, so on the 800x600
    // test window everything below the sliders is never built and a finder for
    // it reports "not found" where the real cause is "not scrolled to".
    tester.view.physicalSize = viewport ?? const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = EnhancementCubit(state?.page ?? draft(), testRenderer());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<EnhancementCubit>.value(
          value: cubit,
          child: EnhancementScreen(onDone: (page) => doneWith = page),
        ),
      ),
    );

    addTearDown(cubit.close);
    return cubit;
  }

  /// Brings the control for [filter] into view and taps it.
  ///
  /// The filter row scrolls horizontally and is built lazily, so the filters
  /// past the third are genuinely absent from the tree until scrolled to —
  /// which is correct behaviour, not something to assert around.
  Future<void> tapFilter(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      120,
      scrollable: find.descendant(
        of: find.byKey(EnhanceKeys.filterList),
        matching: find.byType(Scrollable),
      ),
    );
    // `scrollUntilVisible` stops as soon as the chip is in the *tree*, and a
    // lazy list builds a little beyond the viewport, so it can still be off
    // screen at that point — a tap would land on nothing.
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  group('composition', () {
    testWidgets('preview reports its exact rounded physical longest edge', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(828, 914);
      addTearDown(tester.view.reset);
      final dimensions = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancementPreview(
            imagePath: null,
            onPhysicalLongestEdgeChanged: dimensions.add,
          ),
        ),
      );
      await tester.pump();

      expect(dimensions, [914]);

      tester.view
        ..devicePixelRatio = 3
        ..physicalSize = const Size(1170, 1272);
      await tester.pump();
      await tester.pump();

      expect(dimensions, [914, 1272]);
    });

    testWidgets('shows a control for every filter the spec names', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byKey(EnhanceKeys.screen), findsOneWidget);

      const filters = [
        EnhanceKeys.filterOriginal,
        EnhanceKeys.filterAuto,
        EnhanceKeys.filterMagicColour,
        EnhanceKeys.filterBlackWhite,
        EnhanceKeys.filterGrayscale,
      ];

      // Scrolled to one at a time: the row is a lazy horizontal list, so the
      // later filters are not in the tree until they are reachable.
      final row = find.descendant(
        of: find.byKey(EnhanceKeys.filterList),
        matching: find.byType(Scrollable),
      );

      for (final key in filters) {
        await tester.scrollUntilVisible(find.byKey(key), 120, scrollable: row);
        await tester.ensureVisible(find.byKey(key));
        expect(find.byKey(key), findsOneWidget);
      }
    });

    testWidgets('shows every adjustment control', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(EnhanceKeys.brightnessSlider), findsOneWidget);
      expect(find.byKey(EnhanceKeys.contrastSlider), findsOneWidget);
      expect(find.byKey(EnhanceKeys.sharpenControl), findsOneWidget);
      expect(find.byKey(EnhanceKeys.shadowRemovalToggle), findsOneWidget);
      expect(find.byKey(EnhanceKeys.resetButton), findsOneWidget);
    });
    testWidgets('offers no apply-to-all control', (tester) async {
      await pumpScreen(tester);

      // Enhancement is per page: the flow adds pages one at a time, so at the
      // moment a page is enhanced there is no session of siblings to apply the
      // settings to.
      expect(find.text('Apply to all'), findsNothing);
    });
  });

  group('selecting a filter', () {
    testWidgets('records the selection and renders a preview', (tester) async {
      final cubit = await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterGrayscale);

      expect(cubit.state.settings.filter, EnhancementFilter.grayscale);
      // Rendered at display resolution: a page drawn a few hundred pixels wide
      // gains nothing from being rendered at its true size.
      expect(renderedPlans.last.scale, RenderScale.preview);
    });

    testWidgets('marks the selected filter as selected', (tester) async {
      await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterMagicColour);

      final chip = tester.widget<EnhancementFilterChip>(
        find.ancestor(
          of: find.byKey(EnhanceKeys.filterMagicColour),
          matching: find.byType(EnhancementFilterChip),
        ),
      );

      expect(chip.selected, isTrue);
    });
  });

  group('adjustments', () {
    testWidgets('dragging brightness updates the settings', (tester) async {
      final cubit = await pumpScreen(tester);

      await tester.drag(
        find.descendant(
          of: find.byKey(EnhanceKeys.brightnessSlider),
          matching: find.byType(Slider),
        ),
        const Offset(60, 0),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(cubit.state.settings.brightness, greaterThan(0));
    });

    testWidgets('the shadow toggle updates the settings', (tester) async {
      final cubit = await pumpScreen(tester);

      await tester.tap(find.byKey(EnhanceKeys.shadowRemovalToggle));
      await tester.pumpAndSettle();

      expect(cubit.state.settings.shadowRemoval, isTrue);
    });

    testWidgets('adjustment sliders expose only useful ranges', (tester) async {
      await pumpScreen(tester);

      final brightness = tester.widget<AdjustmentSlider>(
        find.byKey(EnhanceKeys.brightnessSlider),
      );
      final contrast = tester.widget<AdjustmentSlider>(
        find.byKey(EnhanceKeys.contrastSlider),
      );
      final sharpen = tester.widget<AdjustmentSlider>(
        find.byKey(EnhanceKeys.sharpenControl),
      );

      expect(brightness.min, EnhancementRules.minBrightness);
      expect(brightness.max, EnhancementRules.maxBrightness);
      expect(contrast.min, EnhancementRules.minContrast);
      expect(contrast.max, EnhancementRules.maxContrast);
      expect(sharpen.min, EnhancementRules.minSharpen);
      expect(sharpen.max, EnhancementRules.maxSharpen);
    });
  });

  group('undo', () {
    testWidgets('is inert until something has been adjusted', (tester) async {
      await pumpScreen(tester);

      final button = tester.widget<IconButton>(
        find.byKey(EnhanceKeys.undoButton),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('becomes available once a filter is chosen', (tester) async {
      await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterBlackWhite);
      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(
        find.byKey(EnhanceKeys.undoButton),
      );

      expect(button.onPressed, isNotNull);
    });
  });

  group('revert enhancement', () {
    testWidgets('is inert until something has changed', (tester) async {
      await pumpScreen(tester);

      final button = tester.widget<IconButton>(
        find.byKey(EnhanceKeys.resetButton),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('returns every control to its default', (tester) async {
      final cubit = await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterBlackWhite);
      await tester.tap(find.byKey(EnhanceKeys.shadowRemovalToggle));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(EnhanceKeys.resetButton));
      await tester.pumpAndSettle();

      expect(cubit.state.settings, EnhancementSettings.none);
    });
  });

  group('leaving the screen', () {
    testWidgets('done hands back the page carrying the settings', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterGrayscale);
      await tester.tap(find.byKey(EnhanceKeys.doneButton));
      await tester.pumpAndSettle();

      expect(doneWith, isNotNull);
      expect(doneWith!.enhancement.filter, EnhancementFilter.grayscale);
    });

    testWidgets('leaving without finishing does not modify the page', (
      tester,
    ) async {
      final cubit = await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterBlackWhite);

      // Abandoned rather than completed: the page still carries its original
      // settings, and nothing full-resolution was ever written.
      expect(cubit.state.page.enhancement, EnhancementSettings.none);
    });
  });

  group('failure', () {
    testWidgets('shows an error view with a retry control', (tester) async {
      final cubit = await pumpScreen(tester);

      _StateHolder(cubit).set(
        cubit.state.copyWith(
          status: EnhancementStatus.failure,
          failure: const Failure.unexpected(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(EnhanceKeys.errorView), findsOneWidget);
      expect(find.byKey(EnhanceKeys.errorRetryButton), findsOneWidget);
    });

    testWidgets('retrying recovers the screen', (tester) async {
      final cubit = await pumpScreen(tester);

      _StateHolder(cubit).set(
        cubit.state.copyWith(
          status: EnhancementStatus.failure,
          failure: const Failure.unexpected(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(EnhanceKeys.errorRetryButton));
      await tester.pumpAndSettle();

      // The render itself may be served from cache — asking for an unchanged
      // plan twice must not redo the work — so recovery is what is asserted,
      // not that pixels were produced again.
      expect(cubit.state.status, EnhancementStatus.ready);
      expect(cubit.state.failure, isNull);
      expect(find.byKey(EnhanceKeys.errorView), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('a phone viewport stacks the preview above the controls', (
      tester,
    ) async {
      await pumpScreen(tester, viewport: const Size(390, 844));

      final preview = tester.getRect(find.byType(EnhancementPreview));
      final filter = tester.getRect(find.byKey(EnhanceKeys.filterOriginal));

      expect(preview.bottom, lessThanOrEqualTo(filter.top));
    });

    testWidgets('a tablet viewport puts the controls beside the preview', (
      tester,
    ) async {
      await pumpScreen(tester, viewport: const Size(1280, 900));

      final preview = tester.getRect(find.byType(EnhancementPreview));
      final filter = tester.getRect(find.byKey(EnhanceKeys.filterOriginal));

      expect(preview.right, lessThanOrEqualTo(filter.left));
    });

    testWidgets('neither layout overflows', (tester) async {
      for (final size in [const Size(390, 844), const Size(1280, 900)]) {
        await pumpScreen(tester, viewport: size);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });
  });

  group('accessibility', () {
    testWidgets('each filter announces its name and selection state', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Checked before scrolling: selecting Grayscale carries Original off the
      // end of the row, and a scrolled-away chip is not in the tree at all.
      expect(
        tester.getSemantics(find.byKey(EnhanceKeys.filterOriginal)),
        isSemantics(label: 'Original', isSelected: true),
      );

      await tapFilter(tester, EnhanceKeys.filterGrayscale);

      expect(
        tester.getSemantics(find.byKey(EnhanceKeys.filterGrayscale)),
        isSemantics(label: 'Grayscale', isSelected: true),
      );
    });

    testWidgets('each slider announces its current value', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      // The spec requires the *value*, not just the name: "brightness" alone
      // tells a listener nothing about where the control currently sits.
      expect(
        find.bySemanticsLabel(RegExp('Brightness')),
        findsAtLeastNWidgets(1),
      );

      final node = tester.getSemantics(
        find.byKey(EnhanceKeys.brightnessSlider),
      );
      expect(node.value, isNotEmpty);

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('the screen passes the contrast guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives the largest supported text scale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = EnhancementCubit(draft(), testRenderer());
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<EnhancementCubit>.value(
            value: cubit,
            child: EnhancementScreen(onDone: (_) {}),
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
/// `emit` is protected, and the states this file needs — a batch mid-flight, a
/// failure — cannot be reached through the public API within a single frame:
/// the inline worker completes before the widget tree rebuilds, so the running
/// state is never observable.
class _StateHolder {
  _StateHolder(this._cubit);

  final EnhancementCubit _cubit;

  void set(EnhancementState state) => _cubit.emit(state);
}
