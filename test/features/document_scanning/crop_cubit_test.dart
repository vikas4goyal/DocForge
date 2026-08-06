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
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:flutter_test/flutter_test.dart';

PageQuad box(double left, double top, double right, double bottom) => PageQuad(
  topLeft: NormalisedPoint(x: left, y: top),
  topRight: NormalisedPoint(x: right, y: top),
  bottomRight: NormalisedPoint(x: right, y: bottom),
  bottomLeft: NormalisedPoint(x: left, y: bottom),
);

const enhancement = EnhancementSettings(
  filter: EnhancementFilter.blackAndWhite,
  contrast: 0.4,
);

void main() {
  late Directory cache;
  late List<PageRenderPlan> renders;
  late Failure? renderFailure;
  late RenderPage renderPage;

  PageDraft draft({EnhancementSettings? withEnhancement}) => PageDraft(
    id: const PageId('page-1'),
    originalImagePath: '/staging/page-1.jpg',
    enhancement: withEnhancement ?? EnhancementSettings.none,
  );

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('docscanly_crop_');
    renders = [];
    renderFailure = null;

    renderPage = RenderPage(
      cacheDirectory: cache,
      sizeOf: (path) async => const Result<({int width, int height})>.success((
        width: 1000,
        height: 800,
      )),
      render: (plan, {required destinationPath, transform}) async {
        renders.add(plan);
        final configured = renderFailure;
        if (configured != null) return Result<void>.failure(configured);
        File(destinationPath).writeAsStringSync('rendered');
        return const Result<void>.success(null);
      },
    );
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  CropCubit build({PageDraft? page}) => CropCubit(page ?? draft(), renderPage);

  group('initial state', () {
    test('starts with nothing pending', () {
      final state = CropState.adjusting(draft());

      expect(state.quad, PageQuad.full);
      expect(state.rotationDegrees, 0);
      expect(state.hasUnappliedChanges, isFalse);
      expect(state.canApply, isFalse);
    });

    test('revert is unavailable on a page with no crop', () {
      expect(CropState.adjusting(draft()).canRevert, isFalse);
    });

    test('revert is available on a page that was already cropped', () {
      final cropped = draft().withCrop(CropOp(quad: box(0.1, 0.1, 0.9, 0.9)));

      expect(CropState.adjusting(cropped).canRevert, isTrue);
    });
  });

  group('adjusting', () {
    blocTest<CropCubit, CropState>(
      'moving a handle marks the change as unapplied',
      build: build,
      act: (cubit) => cubit.adjust(box(0.2, 0.2, 0.8, 0.8)),
      verify: (cubit) {
        expect(cubit.state.hasUnappliedChanges, isTrue);
        expect(cubit.state.canApply, isTrue);
      },
    );

    blocTest<CropCubit, CropState>(
      'rotating alone counts as an unapplied change',
      build: build,
      act: (cubit) => cubit.rotate(7),
      verify: (cubit) => expect(cubit.state.hasUnappliedChanges, isTrue),
    );

    blocTest<CropCubit, CropState>(
      'adjusting does not touch the page',
      build: build,
      act: (cubit) => cubit.adjust(box(0.2, 0.2, 0.8, 0.8)),
      verify: (cubit) {
        // Leaving without applying has to leave the page exactly as it was.
        expect(cubit.state.page.hasGeometry, isFalse);
      },
    );
  });

  group('apply', () {
    blocTest<CropCubit, CropState>(
      'appends to the geometry rather than replacing the original',
      build: build,
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
      },
      verify: (cubit) {
        expect(cubit.state.page.geometry, hasLength(1));
        expect(cubit.state.page.originalImagePath, '/staging/page-1.jpg');
      },
    );

    blocTest<CropCubit, CropState>(
      'resets the view so the result can be cropped again',
      build: build,
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        cubit.rotate(5);
        await cubit.apply();
      },
      verify: (cubit) {
        // The crop just made is part of the picture now, not still pending.
        expect(cubit.state.quad, PageQuad.full);
        expect(cubit.state.rotationDegrees, 0);
        expect(cubit.state.hasUnappliedChanges, isFalse);
      },
    );

    blocTest<CropCubit, CropState>(
      'applying twice accumulates two operations',
      build: build,
      act: (cubit) async {
        cubit.adjust(box(0.1, 0.1, 0.9, 0.9));
        await cubit.apply();
        cubit.adjust(box(0.1, 0.1, 0.9, 0.9));
        await cubit.apply();
      },
      verify: (cubit) => expect(cubit.state.page.geometry, hasLength(2)),
    );

    blocTest<CropCubit, CropState>(
      'carries the rotation into the recorded operation',
      build: build,
      act: (cubit) async {
        cubit.rotate(12);
        await cubit.apply();
      },
      verify: (cubit) =>
          expect(cubit.state.page.geometry.single.rotationDegrees, 12),
    );

    blocTest<CropCubit, CropState>(
      'does nothing when there is nothing pending',
      build: build,
      act: (cubit) => cubit.apply(),
      verify: (cubit) => expect(cubit.state.page.hasGeometry, isFalse),
    );

    blocTest<CropCubit, CropState>(
      'leaves the enhancement untouched',
      build: () => build(page: draft(withEnhancement: enhancement)),
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
      },
      verify: (cubit) => expect(cubit.state.page.enhancement, enhancement),
    );

    blocTest<CropCubit, CropState>(
      'renders the enhanced result, not raw pixels',
      build: () => build(page: draft(withEnhancement: enhancement)),
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
      },
      verify: (cubit) {
        // The row thumbnail is enhanced; a crop screen showing raw pixels
        // would read as though the enhancement had been lost.
        expect(renders.last.enhancement, enhancement);
      },
    );
  });

  group('apply failure', () {
    blocTest<CropCubit, CropState>(
      'reports the failure and keeps the page unchanged',
      build: build,
      act: (cubit) async {
        renderFailure = const Failure.unexpected();
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isNotNull);
        // The crop was never appended, so the user can adjust and try again.
        expect(cubit.state.page.hasGeometry, isFalse);
        expect(cubit.state.status, CropStatus.adjusting);
      },
    );

    blocTest<CropCubit, CropState>(
      'a later success clears the error',
      build: build,
      act: (cubit) async {
        renderFailure = const Failure.unexpected();
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();

        renderFailure = null;
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
      },
      verify: (cubit) => expect(cubit.state.failure, isNull),
    );
  });

  group('revert', () {
    blocTest<CropCubit, CropState>(
      'discards every crop applied',
      build: build,
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
        await cubit.revertToOriginal();
      },
      verify: (cubit) {
        expect(cubit.state.page.geometry, isEmpty);
        expect(cubit.state.canRevert, isFalse);
      },
    );

    blocTest<CropCubit, CropState>(
      'keeps the enhancement',
      build: () => build(page: draft(withEnhancement: enhancement)),
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
        await cubit.revertToOriginal();
      },
      verify: (cubit) {
        // The user gets the full original frame back, still enhanced — that is
        // the whole point of holding the two layers apart.
        expect(cubit.state.page.enhancement, enhancement);
        expect(cubit.state.page.geometry, isEmpty);
      },
    );

    blocTest<CropCubit, CropState>(
      'resets the pending selection and rotation',
      build: build,
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
        cubit.rotate(20);
        await cubit.revertToOriginal();
      },
      verify: (cubit) {
        expect(cubit.state.quad, PageQuad.full);
        expect(cubit.state.rotationDegrees, 0);
      },
    );

    blocTest<CropCubit, CropState>(
      'does nothing when no crop has been applied',
      build: build,
      act: (cubit) => cubit.revertToOriginal(),
      verify: (cubit) => expect(cubit.state.page.hasGeometry, isFalse),
    );
  });

  group('the page it hands back', () {
    blocTest<CropCubit, CropState>(
      'carries whatever geometry was applied',
      build: build,
      act: (cubit) async {
        cubit.adjust(box(0.2, 0.2, 0.8, 0.8));
        await cubit.apply();
      },
      verify: (cubit) => expect(cubit.page.geometry, hasLength(1)),
    );

    blocTest<CropCubit, CropState>(
      'carries no geometry when the user only looked',
      build: build,
      act: (cubit) async {},
      verify: (cubit) => expect(cubit.page.hasGeometry, isFalse),
    );
  });
}
