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

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';

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

/// A [BackgroundWorker] backed by one isolate kept alive between jobs.
///
/// [IsolateBackgroundWorker] spawns, runs and tears down per job. Spawning is
/// not free — it allocates a heap and starts an event loop — and the app pays it
/// on every preview render, every perspective correction and every page of a
/// batch. Over a scanning session that is the single largest source of overhead
/// that does no useful work.
///
/// Jobs run one at a time, which is what they already did: batches are
/// sequential by construction, and the screens that correct or enhance a page
/// block on the result. Sharing one isolate therefore removes the spawn without
/// changing what runs when.
///
/// The isolate starts on first use and lives until [shutdown]. A worker that is
/// never used never spawns anything.
class PooledIsolateBackgroundWorker
    with BatchRunner
    implements BackgroundWorker {
  /// Creates a worker that shares one isolate across jobs.
  PooledIsolateBackgroundWorker();

  Isolate? _isolate;
  SendPort? _commands;
  Future<void>? _starting;

  @override
  Future<Result<R>> run<T, R>(IsolateJob<T, R> job, T input) async {
    try {
      await _ensureStarted();

      // One port per request rather than one shared reply port: it correlates
      // the answer with its question without a request id, and it is closed the
      // moment the answer arrives.
      final reply = ReceivePort();
      _commands!.send((job, input, reply.sendPort));

      final response = await reply.first;
      reply.close();

      // The job's own failure is carried back as a message rather than thrown
      // across the boundary, because an arbitrary error object may not be
      // sendable — and losing the error would turn a reportable failure into a
      // hang.
      return switch (response) {
        (_workerOk, final Object? value) => Result<R>.success(value as R),
        // Cancellation is carried as its own outcome rather than as an error
        // message. The exception itself cannot be relied on to survive the
        // boundary, and a cancelled job reported as an unexpected failure would
        // show the user an error for something they chose.
        (_workerCancelled, _) => Result<R>.failure(const Failure.cancelled()),
        (_workerFailed, final Object? error) => Result<R>.failure(
          _failureFor(error ?? 'the job failed without reporting why'),
        ),
        _ => Result<R>.failure(
          Failure.unexpected(debugDetail: 'malformed worker reply: $response'),
        ),
      };
    } on Object catch (error) {
      return Result<R>.failure(_failureFor(error));
    }
  }

  /// Starts the isolate if it is not already running.
  ///
  /// Concurrent callers await the same start rather than racing to spawn one
  /// each, which would leave every isolate but the last unreachable and alive.
  Future<void> _ensureStarted() {
    if (_commands != null) return Future<void>.value();
    return _starting ??= _start();
  }

  Future<void> _start() async {
    final ready = ReceivePort();
    _isolate = await Isolate.spawn(_workerMain, ready.sendPort);
    _commands = await ready.first as SendPort;
    ready.close();
  }

  /// Stops the isolate and releases it.
  ///
  /// Safe to call when nothing was ever started, and safe to call twice. A
  /// worker used again afterwards simply starts a new isolate.
  Future<void> shutdown() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commands = null;
    _starting = null;
  }
}

/// The job completed and its value is attached.
const _workerOk = 0;

/// The job threw. A description of the error is attached.
const _workerFailed = 1;

/// The job was cancelled cooperatively.
const _workerCancelled = 2;

/// Entry point of the shared worker isolate.
///
/// Runs each job as it arrives and replies on the port that came with it. Errors
/// are reported as a value, never rethrown: an uncaught error here would take
/// the isolate down and strand every later job.
void _workerMain(SendPort ready) {
  final commands = ReceivePort();
  ready.send(commands.sendPort);

  commands.listen((message) {
    if (message is! (Function, Object?, SendPort)) return;
    final (job, input, reply) = message;

    try {
      reply.send((_workerOk, (job as dynamic)(input)));
    } on CancelledException {
      reply.send((_workerCancelled, null));
    } on Object catch (error) {
      // Stringified rather than sent as-is: an arbitrary error object may not
      // be sendable, and failing to send it would leave the caller waiting for
      // a reply that never comes.
      reply.send((_workerFailed, '$error'));
    }
  });
}
