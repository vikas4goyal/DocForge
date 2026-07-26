import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Doubles [input]. Top-level so it can be sent to a real isolate.
int double_(int input) => input * 2;

/// Always throws, to exercise the failure path.
int alwaysFails(int input) => throw StateError('boom');

/// Throws [CancelledException], to exercise cooperative cancellation.
int alwaysCancels(int input) => throw const CancelledException();

void main() {
  group('CancellationToken', () {
    test('starts uncancelled', () {
      expect(CancellationToken().isCancelled, isFalse);
    });

    test('reports cancellation once requested', () {
      final token = CancellationToken()..cancel();

      expect(token.isCancelled, isTrue);
    });

    test('stays cancelled — a late check still sees the request', () {
      final token = CancellationToken()..cancel();

      expect(token.isCancelled, isTrue);
      expect(token.isCancelled, isTrue);
    });

    test('cancelling twice is safe', () {
      final token = CancellationToken()
        ..cancel()
        ..cancel();

      expect(token.isCancelled, isTrue);
    });

    test('emits on the cancel stream', () async {
      final token = CancellationToken();
      final emissions = <void>[];
      token.onCancel.listen(emissions.add);

      token.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
    });

    test('throwIfCancelled does nothing while uncancelled', () {
      expect(CancellationToken().throwIfCancelled, returnsNormally);
    });

    test('throwIfCancelled throws once cancelled', () {
      final token = CancellationToken()..cancel();

      expect(token.throwIfCancelled, throwsA(isA<CancelledException>()));
    });

    test('dispose is safe on an uncancelled token', () {
      expect(CancellationToken().dispose, returnsNormally);
    });
  });

  group('Progress', () {
    test('computes a fraction', () {
      expect(const Progress(completed: 1, total: 4).fraction, 0.25);
    });

    test('treats zero total as complete', () {
      // A progress bar for zero work must not sit at zero forever.
      const progress = Progress(completed: 0, total: 0);

      expect(progress.fraction, 1.0);
      expect(progress.isComplete, isTrue);
    });

    test('reports completion', () {
      expect(const Progress(completed: 3, total: 3).isComplete, isTrue);
      expect(const Progress(completed: 2, total: 3).isComplete, isFalse);
    });

    test('compares by value so states de-duplicate correctly', () {
      expect(
        const Progress(completed: 1, total: 2),
        const Progress(completed: 1, total: 2),
      );
      expect(
        const Progress(completed: 1, total: 2),
        isNot(const Progress(completed: 2, total: 2)),
      );
    });

    test('rejects negative values', () {
      expect(() => Progress(completed: -1, total: 2), throwsAssertionError);
      expect(() => Progress(completed: 0, total: -2), throwsAssertionError);
    });
  });

  // Both implementations must behave identically, or tests written against the
  // fake would not tell us anything about production.
  for (final entry in <String, BackgroundWorker>{
    'InlineBackgroundWorker': const InlineBackgroundWorker(),
    'IsolateBackgroundWorker': const IsolateBackgroundWorker(),
  }.entries) {
    final name = entry.key;
    final worker = entry.value;

    group('$name.run', () {
      test('returns the job result', () async {
        final result = await worker.run(double_, 21);

        expect(result.valueOrNull, 42);
      });

      test('converts a thrown error into a failure', () async {
        final result = await worker.run(alwaysFails, 1);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnexpectedFailure>());
      });

      test('converts CancelledException into a cancellation failure', () async {
        final result = await worker.run(alwaysCancels, 1);

        expect(result.failureOrNull?.isCancellation, isTrue);
      });
    });

    group('$name.runBatch', () {
      test('emits one completion per item, in order', () async {
        final events = await worker.runBatch(double_, [1, 2, 3]).toList();

        expect(events, hasLength(3));
        expect(
          events.whereType<BatchItemCompleted<int>>().map((e) => e.value),
          [2, 4, 6],
        );
        expect(
          events.whereType<BatchItemCompleted<int>>().map((e) => e.index),
          [0, 1, 2],
        );
      });

      test('reports progress after each item', () async {
        final events = await worker.runBatch(double_, [1, 2, 3]).toList();

        expect(
          events.whereType<BatchItemCompleted<int>>().map((e) => e.progress),
          const [
            Progress(completed: 1, total: 3),
            Progress(completed: 2, total: 3),
            Progress(completed: 3, total: 3),
          ],
        );
      });

      test('an empty batch emits nothing', () async {
        expect(await worker.runBatch(double_, <int>[]).toList(), isEmpty);
      });

      test('stops at the first failure', () async {
        final events = await worker.runBatch(alwaysFails, [1, 2, 3]).toList();

        expect(events, hasLength(1));
        expect(events.single, isA<BatchItemFailed<int>>());
        expect((events.single as BatchItemFailed<int>).index, 0);
      });

      test('a token cancelled before starting stops immediately', () async {
        final token = CancellationToken()..cancel();

        final events = await worker.runBatch(double_, [
          1,
          2,
          3,
        ], token: token).toList();

        expect(events, hasLength(1));
        expect(events.single, isA<BatchCancelled<int>>());
        expect(
          (events.single as BatchCancelled<int>).progress,
          const Progress(completed: 0, total: 3),
        );
      });

      test('cancelling mid-batch keeps completed results and stops', () async {
        final token = CancellationToken();
        final completed = <int>[];
        BatchCancelled<int>? cancellation;

        await for (final event in worker.runBatch(double_, [
          1,
          2,
          3,
          4,
          5,
        ], token: token)) {
          switch (event) {
            case BatchItemCompleted<int>(:final value):
              completed.add(value);
              // Cancel after the second item finishes.
              if (completed.length == 2) token.cancel();
            case BatchCancelled<int>():
              cancellation = event;
            case BatchItemFailed<int>():
              fail('no item should fail');
          }
        }

        // Already-processed work survives — the guarantee every long-running
        // spec depends on.
        expect(completed, [2, 4]);
        expect(cancellation, isNotNull);
        expect(cancellation!.progress, const Progress(completed: 2, total: 5));
      });

      test('an item either completes fully or never starts', () async {
        final token = CancellationToken();
        final seen = <int>[];

        await for (final event in worker.runBatch(double_, [
          1,
          2,
          3,
        ], token: token)) {
          if (event is BatchItemCompleted<int>) {
            seen.add(event.index);
            token.cancel();
          }
        }

        // No partially-processed item is ever reported.
        expect(seen, [0]);
      });
    });
  }
}
