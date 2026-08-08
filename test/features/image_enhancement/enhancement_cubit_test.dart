import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:flutter_test/flutter_test.dart';

PageQuad box(double left, double top, double right, double bottom) => PageQuad(
  topLeft: NormalisedPoint(x: left, y: top),
  topRight: NormalisedPoint(x: right, y: top),
  bottomRight: NormalisedPoint(x: right, y: bottom),
  bottomLeft: NormalisedPoint(x: left, y: bottom),
);

/// Long enough for the Cubit's preview debounce to elapse.
const afterDebounce = Duration(milliseconds: 200);

void main() {
  late Directory cache;
  late List<PageRenderPlan> renders;
  late Failure? renderFailure;
  late RenderPage renderPage;
  late List<String?> renderScopes;
  late List<String> cancelledScopes;

  PageDraft draft({List<CropOp> geometry = const []}) => PageDraft(
    id: const PageId('page-1'),
    originalImagePath: '/staging/page-1.jpg',
    geometry: geometry,
  );

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('docscanly_enhance_');
    renders = [];
    renderFailure = null;
    renderScopes = [];
    cancelledScopes = [];

    renderPage = RenderPage(
      cacheDirectory: cache,
      sizeOf: (path) async => const Result<({int width, int height})>.success((
        width: 1000,
        height: 800,
      )),
      render: (plan, {required destinationPath, transform, scope}) async {
        renders.add(plan);
        renderScopes.add(scope);
        final configured = renderFailure;
        if (configured != null) return Result<void>.failure(configured);
        File(destinationPath).writeAsStringSync('rendered');
        return const Result<void>.success(null);
      },
      cancelRender: (scope) async => cancelledScopes.add(scope),
    );
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  EnhancementCubit build({PageDraft? page}) =>
      EnhancementCubit(page ?? draft(), renderPage);

  group('initial state', () {
    test('holds exactly one page', () {
      final state = EnhancementState.initial(draft());

      expect(state.page.id, const PageId('page-1'));
    });

    test('seeds from the settings the page already carries', () {
      const settings = EnhancementSettings(
        filter: EnhancementFilter.magicColour,
      );

      final state = EnhancementState.initial(draft().withEnhancement(settings));

      // Leaving and re-entering must show what the user last chose rather than
      // silently discarding it.
      expect(state.settings, settings);
      expect(state.hasChanges, isTrue);
    });

    test('shows the original before the first render lands', () {
      expect(
        EnhancementState.initial(draft()).displayedImagePath,
        '/staging/page-1.jpg',
      );
    });
  });

  group('adjustments', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'selecting a filter records it',
      build: build,
      act: (cubit) => cubit.selectFilter(EnhancementFilter.blackAndWhite),
      wait: afterDebounce,
      verify: (cubit) =>
          expect(cubit.state.settings.filter, EnhancementFilter.blackAndWhite),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'sliders record their values',
      build: build,
      act: (cubit) async {
        await cubit.setBrightness(0.3);
        await cubit.setContrast(-0.2);
        await cubit.setSharpen(0.5);
        await cubit.setShadowRemoval(enabled: true);
      },
      wait: afterDebounce,
      verify: (cubit) {
        expect(cubit.state.settings.brightness, 0.3);
        expect(cubit.state.settings.contrast, -0.2);
        expect(cubit.state.settings.sharpen, 0.5);
        expect(cubit.state.settings.shadowRemoval, isTrue);
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'a drag on one slider is a single undo step',
      build: build,
      act: (cubit) async {
        await cubit.setBrightness(0.1);
        await cubit.setBrightness(0.2);
        await cubit.setBrightness(0.3);
      },
      wait: afterDebounce,
      verify: (cubit) {
        // Undo steps back through decisions, not through pixels.
        expect(cubit.state.history, hasLength(1));
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'moving to a different control starts a new step',
      build: build,
      act: (cubit) async {
        await cubit.setBrightness(0.3);
        await cubit.setContrast(0.2);
      },
      wait: afterDebounce,
      verify: (cubit) => expect(cubit.state.history, hasLength(2)),
    );
  });

  group('undo', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'steps back one adjustment',
      build: build,
      act: (cubit) async {
        await cubit.setBrightness(0.3);
        await cubit.setContrast(0.2);
        await cubit.undo();
      },
      wait: afterDebounce,
      verify: (cubit) {
        expect(cubit.state.settings.contrast, 0);
        expect(cubit.state.settings.brightness, 0.3);
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'does nothing with an empty history',
      build: build,
      act: (cubit) => cubit.undo(),
      verify: (cubit) => expect(cubit.state.canUndo, isFalse),
    );
  });

  group('revert enhancement', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'returns every setting to its default',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.blackAndWhite);
        await cubit.setBrightness(0.4);
        await cubit.revertEnhancement();
      },
      wait: afterDebounce,
      verify: (cubit) {
        expect(cubit.state.settings, EnhancementSettings.none);
        expect(cubit.state.hasChanges, isFalse);
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'keeps the page cropped',
      build: () => build(
        page: draft(geometry: [CropOp(quad: box(0.1, 0.1, 0.9, 0.9))]),
      ),
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.grayscale);
        await cubit.revertEnhancement();
      },
      wait: afterDebounce,
      verify: (cubit) {
        // The counterpart of the crop screen's revert keeping the enhancement:
        // the page stays cropped, at its cropped size.
        expect(cubit.state.page.geometry, hasLength(1));
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'is itself undoable',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.blackAndWhite);
        await cubit.revertEnhancement();
        await cubit.undo();
      },
      wait: afterDebounce,
      verify: (cubit) =>
          expect(cubit.state.settings.filter, EnhancementFilter.blackAndWhite),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'does nothing when there is nothing to revert',
      build: build,
      act: (cubit) => cubit.revertEnhancement(),
      verify: (cubit) => expect(cubit.state.history, isEmpty),
    );
  });

  group('rendering', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'uses one cancellable scope for every preview and cancels it on close',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.grayscale);
      },
      wait: afterDebounce,
      verify: (cubit) async {
        expect(renderScopes, isNotEmpty);
        expect(renderScopes.toSet(), {'enhancement:page-1'});
        await cubit.close();
        expect(cancelledScopes, isNotEmpty);
        expect(cancelledScopes, everyElement('enhancement:page-1'));
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'renders from the original, never from a previous render',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.blackAndWhite);
        await cubit.selectFilter(EnhancementFilter.grayscale);
      },
      wait: afterDebounce,
      verify: (cubit) {
        // Enhancing an already-enhanced image is what makes settings compound.
        for (final plan in renders) {
          expect(plan.originalImagePath, '/staging/page-1.jpg');
        }
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'renders over the page current geometry',
      build: () => build(
        page: draft(geometry: [CropOp(quad: box(0.1, 0.1, 0.9, 0.9))]),
      ),
      act: (cubit) => cubit.selectFilter(EnhancementFilter.grayscale),
      wait: afterDebounce,
      verify: (cubit) {
        // The settings apply to whatever the crop produces, which is what makes
        // them follow a later crop rather than being stale relative to it.
        expect(renders.last.geometry, hasLength(1));
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'coalesces a drag into one render',
      build: build,
      act: (cubit) async {
        renders.clear();
        unawaited(cubit.setBrightness(0.1));
        unawaited(cubit.setBrightness(0.2));
        await cubit.setBrightness(0.3);
      },
      wait: afterDebounce,
      verify: (cubit) {
        // Each frame of a drag spawning an isolate leaves the screen busy long
        // after the finger stopped.
        expect(renders, hasLength(1));
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'a failed render is reported with a retry',
      build: build,
      act: (cubit) async {
        renderFailure = const Failure.unexpected();
        await cubit.selectFilter(EnhancementFilter.blackAndWhite);
      },
      wait: afterDebounce,
      verify: (cubit) {
        expect(cubit.state.status, EnhancementStatus.failure);
        expect(cubit.state.failure, isNotNull);
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'retry clears the failure',
      build: build,
      act: (cubit) async {
        renderFailure = const Failure.unexpected();
        await cubit.selectFilter(EnhancementFilter.blackAndWhite);
        renderFailure = null;
        await cubit.retry();
      },
      wait: afterDebounce,
      verify: (cubit) => expect(cubit.state.failure, isNull),
    );
  });

  group('what it hands back', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'carries the settings on the page',
      build: build,
      act: (cubit) => cubit.selectFilter(EnhancementFilter.magicColour),
      wait: afterDebounce,
      verify: (cubit) => expect(
        cubit.edited.enhancement.filter,
        EnhancementFilter.magicColour,
      ),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'carries the geometry through untouched',
      build: () => build(
        page: draft(geometry: [CropOp(quad: box(0.1, 0.1, 0.9, 0.9))]),
      ),
      act: (cubit) => cubit.selectFilter(EnhancementFilter.grayscale),
      wait: afterDebounce,
      verify: (cubit) => expect(cubit.edited.geometry, hasLength(1)),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'writes nothing to the page until it is asked for',
      build: build,
      act: (cubit) => cubit.selectFilter(EnhancementFilter.grayscale),
      wait: afterDebounce,
      verify: (cubit) {
        // Leaving without finishing has to leave the page exactly as it was.
        expect(cubit.state.page.enhancement, EnhancementSettings.none);
      },
    );
  });

  group('no bulk apply', () {
    test('the state exposes no session of other pages', () {
      // Enhancement is per page: the flow adds pages one at a time, so at the
      // moment a page is enhanced there is no session of siblings.
      final state = EnhancementState.initial(draft());

      expect(state.props.whereType<List<PageDraft>>(), isEmpty);
    });
  });
}
