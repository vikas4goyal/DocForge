/// Widget tests for the enhancement screen and its controls.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:doc_forge/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:doc_forge/features/image_enhancement/presentation/screens/enhancement_screen.dart';
import 'package:doc_forge/features/image_enhancement/presentation/widgets/enhancement_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'enhancement_test_support.dart';

void main() {
  setUp(resetJobRecording);

  List<PageRef> session(int count) => [
    for (var index = 0; index < count; index++)
      PageRef(id: PageId('page-$index'), imagePath: '/page-$index.jpg'),
  ];

  late List<PageRef>? doneWith;

  setUp(() => doneWith = null);

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

    final cubit = EnhancementCubit(
      state?.pages ?? session(pages),
      inlineApply(),
      const PlanSessionEnhancement(),
      destinationFor,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<EnhancementCubit>.value(
          value: cubit,
          child: EnhancementScreen(onDone: (pages) => doneWith = pages),
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

    testWidgets('offers apply-to-all for a multi-page session', (tester) async {
      await pumpScreen(tester, pages: 4);

      expect(find.byKey(EnhanceKeys.applyToAllButton), findsOneWidget);
    });

    testWidgets('hides apply-to-all for a single page', (tester) async {
      // Offering a control that visibly does nothing is worse than not offering
      // it at all.
      await pumpScreen(tester, pages: 1);

      expect(find.byKey(EnhanceKeys.applyToAllButton), findsNothing);
    });
  });

  group('selecting a filter', () {
    testWidgets('records the selection and renders a preview', (tester) async {
      final cubit = await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterGrayscale);

      expect(cubit.state.settings.filter, EnhancementFilter.grayscale);
      expect(recordedRequests.single.isPreview, isTrue);
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
      await tester.pumpAndSettle();

      expect(cubit.state.settings.brightness, greaterThan(0));
    });

    testWidgets('the shadow toggle updates the settings', (tester) async {
      final cubit = await pumpScreen(tester);

      await tester.tap(find.byKey(EnhanceKeys.shadowRemovalToggle));
      await tester.pumpAndSettle();

      expect(cubit.state.settings.shadowRemoval, isTrue);
    });

    testWidgets('sharpening cannot express a negative value', (tester) async {
      await pumpScreen(tester);

      // Asserted on the control's range rather than by dragging it. Negative
      // sharpening is blurring, which is not a thing this screen offers, and
      // the floor is a property of the control — the clamping behind it is
      // covered in `enhancement_maths_test`.
      final slider = tester.widget<AdjustmentSlider>(
        find.byKey(EnhanceKeys.sharpenControl),
      );

      expect(slider.min, 0);
    });
  });

  group('reset', () {
    testWidgets('is inert until something has changed', (tester) async {
      await pumpScreen(tester);

      final button = tester.widget<OutlinedButton>(
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
    testWidgets('done commits the settings and hands back the pages', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tapFilter(tester, EnhanceKeys.filterGrayscale);
      await tester.tap(find.byKey(EnhanceKeys.doneButton));
      await tester.pumpAndSettle();

      expect(doneWith, isNotNull);
      expect(doneWith!.first.enhancement.filter, EnhancementFilter.grayscale);
    });

    testWidgets('leaving without saving does not modify the stored page', (
      tester,
    ) async {
      final pages = session(2);
      final cubit = await pumpScreen(
        tester,
        state: EnhancementState.initial(pages),
      );

      await tapFilter(tester, EnhanceKeys.filterBlackWhite);

      // The screen is abandoned rather than completed: no commit, so the page
      // in the session still carries its original settings and nothing
      // full-resolution was ever written.
      expect(cubit.state.pages.first.enhancement, EnhancementSettings.none);
      expect(recordedRequests.every((request) => request.isPreview), isTrue);
    });
  });

  group('apply to all', () {
    testWidgets('shows progress and a cancel control while running', (
      tester,
    ) async {
      final cubit = await pumpScreen(tester, pages: 6);

      // Seeded directly rather than by running a batch: the inline worker
      // finishes within one frame, so the running state would never be
      // observable through a real run.
      final holder = _StateHolder(cubit);
      holder.set(
        cubit.state.copyWith(
          status: EnhancementStatus.applyingToAll,
          progress: const Progress(completed: 2, total: 6),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(EnhanceKeys.progressIndicator), findsOneWidget);
      expect(find.byKey(EnhanceKeys.cancelButton), findsOneWidget);
      expect(find.text('Enhancing pages — 2 of 6'), findsOneWidget);
    });

    testWidgets('disables the controls while running', (tester) async {
      final cubit = await pumpScreen(tester, pages: 6);

      _StateHolder(cubit).set(
        cubit.state.copyWith(
          status: EnhancementStatus.applyingToAll,
          progress: const Progress(completed: 1, total: 6),
        ),
      );
      await tester.pumpAndSettle();

      // Changing a setting mid-batch would leave some pages on the old settings
      // and some on the new, with nothing on screen to say which.
      final slider = tester.widget<AdjustmentSlider>(
        find.byKey(EnhanceKeys.brightnessSlider),
      );
      expect(slider.enabled, isFalse);
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

    testWidgets('retrying re-renders the preview', (tester) async {
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

      expect(recordedRequests, isNotEmpty);
      expect(cubit.state.status, EnhancementStatus.ready);
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

      final cubit = EnhancementCubit(
        session(3),
        inlineApply(),
        const PlanSessionEnhancement(),
        destinationFor,
      );
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
