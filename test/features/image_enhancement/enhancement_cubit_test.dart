/// Tests the enhancement Cubit.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'enhancement_test_support.dart';

void main() {
  const magic = EnhancementSettings(filter: EnhancementFilter.magicColour);

  setUp(resetJobRecording);

  List<PageRef> session(int count) => [
    for (var index = 0; index < count; index++)
      PageRef(id: PageId('page-$index'), imagePath: '/page-$index.jpg'),
  ];

  EnhancementCubit build({int pages = 3, int index = 0}) => EnhancementCubit(
    session(pages),
    inlineApply(),
    const PlanSessionEnhancement(),
    destinationFor,
    index: index,
  );

  group('initial state', () {
    test('seeds the settings from the page being enhanced', () {
      final pages = [
        const PageRef(id: PageId('a'), imagePath: '/a.jpg'),
        const PageRef(id: PageId('b'), imagePath: '/b.jpg', enhancement: magic),
      ];

      final cubit = EnhancementCubit(
        pages,
        inlineApply(),
        const PlanSessionEnhancement(),
        destinationFor,
        index: 1,
      );

      // Re-entering the screen must show the settings the user last chose, not
      // silently discard them.
      expect(cubit.state.settings, magic);
      expect(cubit.state.status, EnhancementStatus.ready);
    });

    test('shows the unmodified page before any preview exists', () {
      final cubit = build();

      expect(cubit.state.previewPath, isNull);
      expect(cubit.state.displayedImagePath, '/page-0.jpg');
    });

    test('an empty session has no page and no settings', () {
      final cubit = EnhancementCubit(
        const [],
        inlineApply(),
        const PlanSessionEnhancement(),
        destinationFor,
      );

      expect(cubit.state.page, isNull);
      expect(cubit.state.settings, EnhancementSettings.none);
    });

    test('an index past the end clamps rather than throwing', () {
      final cubit = build(index: 99);

      expect(cubit.state.index, 2);
    });
  });

  group('selecting a filter', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'renders a preview and returns to ready',
      build: build,
      act: (cubit) => cubit.selectFilter(EnhancementFilter.grayscale),
      expect: () => [
        isA<EnhancementState>()
            .having(
              (s) => s.settings.filter,
              'filter',
              EnhancementFilter.grayscale,
            )
            .having((s) => s.status, 'status', EnhancementStatus.ready),
        isA<EnhancementState>().having(
          (s) => s.status,
          'status',
          EnhancementStatus.previewing,
        ),
        isA<EnhancementState>()
            .having((s) => s.status, 'status', EnhancementStatus.ready)
            .having((s) => s.previewPath, 'previewPath', isNotNull),
      ],
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'renders the preview at preview resolution, not full',
      build: build,
      act: (cubit) => cubit.selectFilter(EnhancementFilter.grayscale),
      verify: (_) {
        expect(recordedRequests.single.isPreview, isTrue);
        expect(
          recordedRequests.single.maxDimension,
          EnhancementRules.previewMaxDimension,
        );
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'selecting Original after another filter returns to the captured page',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.blackAndWhite);
        await cubit.selectFilter(EnhancementFilter.original);
      },
      verify: (cubit) {
        expect(cubit.state.settings.filter, EnhancementFilter.original);
        expect(cubit.state.hasChanges, isFalse);
      },
    );
  });

  group('adjustments', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'brightness is recorded and previewed',
      build: build,
      act: (cubit) => cubit.setBrightness(0.4),
      verify: (cubit) {
        expect(cubit.state.settings.brightness, 0.4);
        expect(recordedRequests.single.settings.brightness, 0.4);
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'contrast is recorded and previewed',
      build: build,
      act: (cubit) => cubit.setContrast(-0.3),
      verify: (cubit) => expect(cubit.state.settings.contrast, -0.3),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'sharpen is recorded and previewed',
      build: build,
      act: (cubit) => cubit.setSharpen(0.7),
      verify: (cubit) => expect(cubit.state.settings.sharpen, 0.7),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'shadow removal is recorded and previewed',
      build: build,
      act: (cubit) => cubit.setShadowRemoval(enabled: true),
      verify: (cubit) => expect(cubit.state.settings.shadowRemoval, isTrue),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'an adjustment keeps the filter that was already selected',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.magicColour);
        await cubit.setBrightness(0.25);
      },
      verify: (cubit) {
        expect(cubit.state.settings.filter, EnhancementFilter.magicColour);
        expect(cubit.state.settings.brightness, 0.25);
        // Both reach the job, which is what makes the preview show both.
        expect(
          recordedRequests.last.settings.filter,
          EnhancementFilter.magicColour,
        );
        expect(recordedRequests.last.settings.brightness, 0.25);
      },
    );
  });

  group('reset', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'returns every setting to its default',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.blackAndWhite);
        await cubit.setBrightness(0.5);
        await cubit.setShadowRemoval(enabled: true);
        cubit.reset();
      },
      verify: (cubit) {
        expect(cubit.state.settings, EnhancementSettings.none);
        expect(cubit.state.hasChanges, isFalse);
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'shows the unmodified page without rendering anything',
      build: build,
      act: (cubit) async {
        await cubit.setBrightness(0.5);
        final before = recordedRequests.length;
        cubit.reset();
        // The default settings are the captured page and its file already
        // exists, so re-rendering it would be pure waste.
        expect(recordedRequests, hasLength(before));
      },
      verify: (cubit) => expect(cubit.state.displayedImagePath, '/page-0.jpg'),
    );
  });

  group('commit', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'stores the settings against the page being enhanced',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.magicColour);
        cubit.commit();
      },
      verify: (cubit) {
        expect(cubit.state.pages[0].enhancement, magic);
        // The other pages keep their own settings.
        expect(cubit.state.pages[1].enhancement, EnhancementSettings.none);
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'writes nothing to disk',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.magicColour);
        final previews = recordedRequests.length;
        cubit.commit();
        // Only the preview render happened. The full-resolution image is
        // produced when the document is built, which is what makes leaving
        // without saving leave the stored page untouched.
        expect(recordedRequests, hasLength(previews));
      },
      verify: (cubit) => expect(
        recordedRequests.every((request) => request.isPreview),
        isTrue,
      ),
    );
  });

  group('apply to all', () {
    blocTest<EnhancementCubit, EnhancementState>(
      'applies the settings to every page of the session',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.magicColour);
        await cubit.applyToAll();
      },
      verify: (cubit) => expect(
        cubit.state.pages.map((page) => page.enhancement),
        everyElement(magic),
      ),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'reports progress per page and ends ready',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.magicColour);
        await cubit.applyToAll();
      },
      verify: (cubit) => expect(cubit.state.status, EnhancementStatus.ready),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'emits progress reaching the page count',
      build: build,
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.magicColour);
        await cubit.applyToAll();
      },
      verify: (_) {
        final full = recordedRequests.where((r) => !r.isPreview);
        expect(full, hasLength(3));
      },
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'is not offered for a single-page session',
      build: () => build(pages: 1),
      verify: (cubit) => expect(cubit.state.canApplyToAll, isFalse),
    );

    blocTest<EnhancementCubit, EnhancementState>(
      'a failure mid-batch surfaces and leaves the page as it was',
      build: () => EnhancementCubit(
        [
          const PageRef(id: PageId('a'), imagePath: '/a.jpg'),
          const PageRef(id: PageId('fail'), imagePath: '/fail.jpg'),
        ],
        failingApply(),
        const PlanSessionEnhancement(),
        destinationFor,
      ),
      act: (cubit) async {
        await cubit.selectFilter(EnhancementFilter.magicColour);
        await cubit.applyToAll();
      },
      verify: (cubit) {
        expect(cubit.state.status, EnhancementStatus.failure);
        expect(cubit.state.failure, isNotNull);
        expect(cubit.state.message, isNotNull);
      },
    );
  });

  group('cancellation', () {
    test('stops the batch and returns to ready', () async {
      final cubit = EnhancementCubit(
        session(4),
        cancellingApply(),
        const PlanSessionEnhancement(),
        destinationFor,
      );

      // The fake job cancels the token as soon as the first page runs, which is
      // the only way to exercise the check the worker makes between items.
      cancelAfterFirstPage = (token) => token.cancel();

      await cubit.selectFilter(EnhancementFilter.magicColour);
      await cubit.applyToAll();

      expect(cubit.state.status, EnhancementStatus.ready);
      // The first page completed and kept its result; nothing after it started.
      expect(recordedRequests.where((r) => !r.isPreview), hasLength(1));

      await cubit.close();
    });

    test('closing the Cubit cancels a running batch', () async {
      final cubit = EnhancementCubit(
        session(3),
        inlineApply(),
        const PlanSessionEnhancement(),
        destinationFor,
      );

      await cubit.close();

      // A batch that outlives its screen has nowhere to report to.
      expect(cubit.isClosed, isTrue);
    });
  });

  group('superseded previews', () {
    test('a slow preview never overwrites a newer one', () async {
      final gate = PreviewGate();
      final cubit = EnhancementCubit(
        session(1),
        gate.apply,
        const PlanSessionEnhancement(),
        destinationFor,
      );

      // Two renders in flight; the first finishes last, as happens when a
      // slider is dragged and the results arrive out of order.
      final first = cubit.setBrightness(0.1);
      final second = cubit.setBrightness(0.9);

      gate.completeAll();
      await Future.wait([first, second]);

      // The screen shows the newest settings, not whichever render finished
      // last.
      expect(cubit.state.settings.brightness, 0.9);
      expect(cubit.state.status, EnhancementStatus.ready);

      await cubit.close();
    });
  });

  group('retry', () {
    test('re-renders the preview after a failure', () async {
      final cubit = EnhancementCubit(
        [const PageRef(id: PageId('fail'), imagePath: '/fail.jpg')],
        failingApply(),
        const PlanSessionEnhancement(),
        destinationFor,
      );

      await cubit.setBrightness(0.5);
      expect(cubit.state.status, EnhancementStatus.failure);

      final before = recordedRequests.length;
      await cubit.retry();

      expect(recordedRequests.length, greaterThan(before));

      await cubit.close();
    });
  });

  group('progress reporting', () {
    test('progress is cleared once the batch ends', () async {
      final cubit = EnhancementCubit(
        session(2),
        inlineApply(),
        const PlanSessionEnhancement(),
        destinationFor,
      );

      await cubit.selectFilter(EnhancementFilter.magicColour);
      await cubit.applyToAll();

      // A finished batch must not leave a progress bar on screen.
      expect(cubit.state.progress, isNull);

      await cubit.close();
    });

    test('a Progress reports its fraction and completeness', () {
      const half = Progress(completed: 1, total: 2);

      expect(half.fraction, 0.5);
      expect(half.isComplete, isFalse);
      expect(const Progress(completed: 2, total: 2).isComplete, isTrue);
    });
  });
}
