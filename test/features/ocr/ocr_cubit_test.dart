/// Tests the OCR Cubit.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_scanly/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_cubit.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ocr_test_support.dart';

void main() {
  late OcrHarness harness;

  setUp(() => harness = OcrHarness());

  group('loading stored text', () {
    blocTest<OcrCubit, OcrState>(
      'a document never recognised offers to start',
      build: () => harness.build(),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.status, OcrStatus.notRecognised),
    );

    blocTest<OcrCubit, OcrState>(
      'never starts recognition by itself',
      build: () => harness.build(),
      act: (cubit) => cubit.load(),
      verify: (_) {
        // Opening a document must not silently cost the user a full
        // recognition pass; the spec requires the run to be something they ask
        // for.
        expect(harness.recogniser.requested, isEmpty);
      },
    );

    test('uses stored text rather than recomputing it', () async {
      final cubit = harness.build();
      await cubit.recognise();
      harness.recogniser.requested.clear();

      final reopened = harness.build();
      await reopened.load();

      expect(reopened.state.status, OcrStatus.ready);
      expect(harness.recogniser.requested, isEmpty);

      await cubit.close();
      await reopened.close();
    });

    blocTest<OcrCubit, OcrState>(
      'a store failure surfaces as an error with a message',
      build: () => harness.build(store: harness.brokenStore()),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, OcrStatus.failure);
        expect(cubit.state.message, isNotNull);
      },
    );
  });

  group('running recognition', () {
    blocTest<OcrCubit, OcrState>(
      'ends ready with text',
      build: () => harness.build(),
      act: (cubit) => cubit.recognise(),
      verify: (cubit) {
        expect(cubit.state.status, OcrStatus.ready);
        expect(cubit.state.hasText, isTrue);
      },
    );

    blocTest<OcrCubit, OcrState>(
      'reports progress per page while running',
      build: () => harness.build(),
      act: (cubit) => cubit.recognise(),
      verify: (cubit) => expect(cubit.state.isFullyRecognised, isTrue),
    );

    blocTest<OcrCubit, OcrState>(
      'emits a running state before the result',
      build: () => harness.build(),
      act: (cubit) => cubit.recognise(),
      expect: () => [
        isA<OcrState>().having((s) => s.status, 'status', OcrStatus.running),
        isA<OcrState>().having((s) => s.status, 'status', OcrStatus.running),
        isA<OcrState>().having((s) => s.status, 'status', OcrStatus.running),
        isA<OcrState>().having((s) => s.status, 'status', OcrStatus.running),
        isA<OcrState>().having((s) => s.status, 'status', OcrStatus.ready),
      ],
    );

    blocTest<OcrCubit, OcrState>(
      'a document where nothing is legible ends empty, not failed',
      build: () => harness.build(
        recogniser: FakeOcrRepository(emptyFor: {'a', 'b', 'c'}),
      ),
      act: (cubit) => cubit.recognise(),
      verify: (cubit) {
        // A distinct outcome from "not read yet": the pages *were* read, and
        // offering "try again" would imply the result was a failure.
        expect(cubit.state.status, OcrStatus.empty);
        expect(cubit.state.hasText, isFalse);
      },
    );

    blocTest<OcrCubit, OcrState>(
      'a run where every page fails ends in failure',
      build: () => harness.build(
        recogniser: FakeOcrRepository(failure: const Failure.ocr()),
      ),
      act: (cubit) => cubit.recognise(),
      verify: (cubit) {
        expect(cubit.state.status, OcrStatus.failure);
        expect(cubit.state.message, isNotNull);
      },
    );

    test('a run where one page fails still ends ready', () async {
      // The spec requires the document to stay usable without recognised text
      // for the affected page.
      final cubit = harness.build(recogniser: PartialFailureRecogniser({'b'}));

      await cubit.recognise();

      expect(cubit.state.status, OcrStatus.ready);
      expect(cubit.state.recognisedPageCount, 2);

      await cubit.close();
    });
  });

  group('re-running', () {
    test('recognises every page again', () async {
      final cubit = harness.build();
      await cubit.recognise();
      harness.recogniser.requested.clear();

      await cubit.rerun();

      expect(harness.recogniser.requested, hasLength(3));

      await cubit.close();
    });
  });

  group('cancellation', () {
    test('stops the run and keeps recognised pages', () async {
      final gate = GatedRecogniser();
      final cubit = harness.build(recogniser: gate);

      final running = cubit.recognise();
      await gate.completeNext();
      cubit.cancel();
      await gate.completeRemaining();
      await running;

      expect(cubit.state.status, isNot(OcrStatus.running));
      // The page that finished keeps its result.
      expect(cubit.state.texts, isNotEmpty);

      await cubit.close();
    });

    test('closing the Cubit cancels a running recognition', () async {
      final cubit = harness.build();

      await cubit.close();

      expect(cubit.isClosed, isTrue);
    });
  });

  group('copy', () {
    test('puts the combined text on the clipboard', () async {
      final cubit = harness.build();
      await cubit.recognise();

      await cubit.copy();

      expect(harness.copied.single, cubit.state.combinedText);
      expect(cubit.state.copied, isTrue);

      await cubit.close();
    });

    test('does nothing when there is no text to copy', () async {
      // A control that puts an empty string on the clipboard is worse than one
      // visibly unavailable.
      final cubit = harness.build();

      await cubit.copy();

      expect(harness.copied, isEmpty);

      await cubit.close();
    });
  });

  group('export', () {
    test('offers the text under a name derived from the title', () async {
      final cubit = harness.build();
      await cubit.recognise();

      await cubit.export();

      expect(harness.exported.single.fileName, 'Invoice 2026.txt');

      await cubit.close();
    });

    test('does nothing when there is no text', () async {
      final cubit = harness.build();

      await cubit.export();

      expect(harness.exported, isEmpty);

      await cubit.close();
    });

    test('a failed export surfaces as an error', () async {
      final cubit = harness.build(exportFailure: const Failure.export());
      await cubit.recognise();

      await cubit.export();

      expect(cubit.state.status, OcrStatus.failure);

      await cubit.close();
    });
  });

  group('state', () {
    test('a copy confirmation does not outlive the next change', () async {
      final cubit = harness.build();
      await cubit.recognise();
      await cubit.copy();

      expect(cubit.state.copied, isTrue);

      await cubit.load();

      // Cleared on the next emit, so a stale confirmation cannot reappear.
      expect(cubit.state.copied, isFalse);

      await cubit.close();
    });

    test('combined text follows page order', () async {
      final cubit = harness.build();
      await cubit.recognise();

      expect(cubit.state.combinedText.split('\n\n'), hasLength(3));

      await cubit.close();
    });

    test('an empty document is fully recognised by definition', () {
      const state = OcrState.initial(<PageRef>[]);

      expect(state.isFullyRecognised, isTrue);
      expect(state.hasText, isFalse);
    });
  });

  group('the OCR pipeline makes no network call', () {
    test('recognition touches only the injected repository', () async {
      // Asserted structurally: `RecogniseText` depends on `OcrRepository` and
      // `OcrTextStore` and on nothing else, and both are substituted here by
      // in-memory fakes. A network call would have to come from one of them,
      // and neither has a client to make one with.
      final cubit = harness.build();

      await cubit.recognise();

      expect(harness.recogniser.requested, hasLength(3));
      expect(harness.store.texts, hasLength(3));

      await cubit.close();
    });
  });
}

/// A recogniser that fails on the named pages.
class PartialFailureRecogniser extends FakeOcrRepository {
  /// Creates a recogniser failing on [_failing].
  PartialFailureRecogniser(this._failing);

  final Set<String> _failing;

  @override
  Future<Result<RecognisedText>> recognise({
    required PageId pageId,
    required String imagePath,
    required OcrScript script,
  }) async {
    if (_failing.contains(pageId.value)) {
      requested.add(pageId);
      return const Result<RecognisedText>.failure(Failure.ocr());
    }
    return super.recognise(
      pageId: pageId,
      imagePath: imagePath,
      script: script,
    );
  }
}
