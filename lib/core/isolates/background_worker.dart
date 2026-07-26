/// Runs heavy work off the UI thread.
///
/// Every image enhancement, perspective correction, OCR pass and PDF operation
/// goes through here. Two shapes are supported:
///
/// * [BackgroundWorker.run] — a single one-shot job.
/// * [BackgroundWorker.runBatch] — a sequence of items reporting progress and
///   honouring cancellation between items.
///
/// **Only paths and small value objects may cross the isolate boundary.** Never
/// decoded image buffers: sending a full-resolution bitmap copies it, and a
/// batch scan on a low-end device runs out of memory long before it finishes.
/// Each job reads from disk, processes, and writes back to disk (`design.md`
/// §7).
library;

import 'dart:async';
import 'dart:isolate';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';

/// A unit of work that can run inside an isolate.
///
/// Must be a top-level or static function — a closure capturing state cannot be
/// sent to an isolate, and capturing UI state would reintroduce exactly the
/// hidden coupling the architecture forbids.
typedef IsolateJob<T, R> = R Function(T input);

/// Executes work away from the UI thread.
///
/// An interface rather than a bare function so tests and previews can run jobs
/// inline — a real isolate makes failures harder to assert on and is needless
/// overhead for a fake.
abstract interface class BackgroundWorker {
  /// Runs [job] with [input] and returns its result.
  Future<Result<R>> run<T, R>(IsolateJob<T, R> job, T input);

  /// Runs [job] over each of [inputs], in order.
  ///
  /// Emits a [Progress] event after each item. Checks [token] between items, so
  /// cancelling leaves everything already processed intact and stops before the
  /// next item starts. On cancellation the stream closes after emitting the
  /// results completed so far.
  Stream<BatchEvent<R>> runBatch<T, R>(
    IsolateJob<T, R> job,
    List<T> inputs, {
    CancellationToken? token,
  });
}

/// An event emitted while a batch runs.
sealed class BatchEvent<R> {
  const BatchEvent();
}

/// One item finished successfully.
class BatchItemCompleted<R> extends BatchEvent<R> {
  /// Creates a completion event for [index] carrying [value].
  const BatchItemCompleted({
    required this.index,
    required this.value,
    required this.progress,
  });

  /// Position of the finished item in the input list.
  final int index;

  /// What the job produced.
  final R value;

  /// Progress after this item.
  final Progress progress;
}

/// One item failed.
///
/// The batch stops here: continuing past a failure would leave the caller
/// unable to tell which outputs are trustworthy.
class BatchItemFailed<R> extends BatchEvent<R> {
  /// Creates a failure event for [index] carrying [failure].
  const BatchItemFailed({required this.index, required this.failure});

  /// Position of the failed item in the input list.
  final int index;

  /// Why the item failed.
  final Failure failure;
}

/// The batch stopped because cancellation was requested.
class BatchCancelled<R> extends BatchEvent<R> {
  /// Creates a cancellation event recording [progress] reached before stopping.
  const BatchCancelled(this.progress);

  /// How far the batch got before stopping.
  final Progress progress;
}

/// Shared batch sequencing for [BackgroundWorker] implementations.
///
/// Both implementations differ only in how a single job is executed, so the
/// batching, progress and cancellation rules live here once. Duplicating them
/// would let the real and fake workers drift apart, and the fake is what every
/// test asserts against.
mixin BatchRunner implements BackgroundWorker {
  @override
  Stream<BatchEvent<R>> runBatch<T, R>(
    IsolateJob<T, R> job,
    List<T> inputs, {
    CancellationToken? token,
  }) async* {
    final total = inputs.length;

    for (var index = 0; index < total; index++) {
      // Checked before starting each item rather than during it: an item either
      // completes and is durable, or never starts. That is what makes "already
      // processed pages keep their results" true.
      if (token?.isCancelled ?? false) {
        yield BatchCancelled<R>(Progress(completed: index, total: total));
        return;
      }

      final result = await run(job, inputs[index]);

      switch (result) {
        case Success<R>(:final value):
          yield BatchItemCompleted<R>(
            index: index,
            value: value,
            progress: Progress(completed: index + 1, total: total),
          );
        case Failed<R>(:final failure):
          yield BatchItemFailed<R>(index: index, failure: failure);
          return;
      }
    }
  }
}

/// Converts an error thrown inside a job into a [Failure].
///
/// [CancelledException] becomes `Failure.cancelled()` so cancellation stays a
/// normal outcome rather than surfacing to the user as an error.
Failure _failureFor(Object error) => error is CancelledException
    ? const Failure.cancelled()
    : Failure.unexpected(debugDetail: '$error');

/// A [BackgroundWorker] backed by real isolates.
class IsolateBackgroundWorker with BatchRunner implements BackgroundWorker {
  /// Creates a worker that spawns an isolate per job.
  const IsolateBackgroundWorker();

  @override
  Future<Result<R>> run<T, R>(IsolateJob<T, R> job, T input) async {
    try {
      // Isolate.run spawns, executes and tears down; there is no long-lived
      // isolate to leak if the caller abandons the future.
      final value = await Isolate.run(() => job(input));
      return Result<R>.success(value);
    } on Object catch (error) {
      return Result<R>.failure(_failureFor(error));
    }
  }
}

/// A [BackgroundWorker] that runs jobs inline on the calling thread.
///
/// For tests, previews and goldens: deterministic, synchronous enough to assert
/// on, and free of isolate spawn cost. Never used in production, where blocking
/// the UI thread is exactly what the worker exists to prevent.
class InlineBackgroundWorker with BatchRunner implements BackgroundWorker {
  /// Creates an inline worker.
  const InlineBackgroundWorker();

  @override
  Future<Result<R>> run<T, R>(IsolateJob<T, R> job, T input) async {
    try {
      return Result<R>.success(job(input));
    } on Object catch (error) {
      return Result<R>.failure(_failureFor(error));
    }
  }
}
