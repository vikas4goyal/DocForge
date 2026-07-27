/// Shared fakes for the enhancement tests.
///
/// Every job here is a top-level function, because the real worker sends its
/// job to an isolate and a closure cannot cross that boundary. Substituting one
/// for the other has to work without changing the signature.
library;

import 'dart:async';

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';

/// Requests seen by the fake jobs, in order.
final recordedRequests = <EnhancementRequest>[];

/// Called with the batch's token after the first page, when set.
void Function(CancellationToken token)? cancelAfterFirstPage;

/// The token of the batch currently running, so a job can cancel it.
CancellationToken? activeToken;

/// Clears the recording between tests.
void resetJobRecording() {
  recordedRequests.clear();
  cancelAfterFirstPage = null;
  activeToken = null;
}

/// Names the file an enhancement result would be written to.
///
/// No file is ever created: these tests are about state transitions, and real
/// I/O inside a `blocTest` would be slow and would need a temporary directory
/// per case for nothing.
String destinationFor(PageRef page, {required bool isPreview}) =>
    '${page.imagePath}.${isPreview ? 'preview' : 'enhanced'}.jpg';

/// Records the request and returns its destination.
String recordingJob(EnhancementRequest request) {
  recordedRequests.add(request);
  return request.destinationPath;
}

/// Fails on any request whose source path contains `fail`.
String failingJob(EnhancementRequest request) {
  recordedRequests.add(request);
  if (request.sourcePath.contains('fail')) {
    throw const FormatException('the page image could not be decoded');
  }
  return request.destinationPath;
}

/// Records the request, then cancels the running batch.
///
/// Cancels from inside the batch, which is the only way to exercise the check
/// the worker makes between items rather than before the first one.
String cancellingJob(EnhancementRequest request) {
  recordedRequests.add(request);
  if (!request.isPreview) {
    final token = activeToken;
    if (token != null) cancelAfterFirstPage?.call(token);
  }
  return request.destinationPath;
}

/// An [ApplyEnhancement] that runs [recordingJob] inline.
ApplyEnhancement inlineApply() =>
    const ApplyEnhancement(InlineBackgroundWorker(), recordingJob);

/// An [ApplyEnhancement] that runs [failingJob] inline.
ApplyEnhancement failingApply() =>
    const ApplyEnhancement(InlineBackgroundWorker(), failingJob);

/// An [ApplyEnhancement] whose batch cancels itself after the first page.
ApplyEnhancement cancellingApply() =>
    const ApplyEnhancement(_TokenCapturingWorker(), cancellingJob);

/// A worker that publishes the batch's token so a job can cancel it.
class _TokenCapturingWorker with BatchRunner implements BackgroundWorker {
  const _TokenCapturingWorker();

  @override
  Future<Result<R>> run<T, R>(IsolateJob<T, R> job, T input) async {
    try {
      return Result<R>.success(job(input));
    } on Object catch (error) {
      return Result<R>.failure(_failureFor(error));
    }
  }

  @override
  Stream<BatchEvent<R>> runBatch<T, R>(
    IsolateJob<T, R> job,
    List<T> inputs, {
    CancellationToken? token,
  }) {
    activeToken = token;
    return super.runBatch(job, inputs, token: token);
  }
}

/// Converts a thrown error into the failure the real worker would produce.
Failure _failureFor(Object error) => error is CancelledException
    ? const Failure.cancelled()
    : Failure.unexpected(debugDetail: '$error');

/// An [ApplyEnhancement] whose previews complete only when released.
///
/// Lets a test hold two renders in flight at once, which is the situation a
/// dragged slider creates and the one the generation counter exists to survive.
class PreviewGate {
  final _pending = <Completer<Result<String>>>[];

  /// The use case to hand to the Cubit.
  ApplyEnhancement get apply => _GatedApply(this);

  /// Completes every render currently in flight, oldest first.
  void completeAll() {
    // Oldest first, so the *first* request finishes last is not what happens —
    // this deliberately completes them in request order, and the newest
    // settings must still win because generation, not arrival, decides.
    for (final completer in _pending) {
      completer.complete(const Result.success('/preview.jpg'));
    }
    _pending.clear();
  }

  Future<Result<String>> _enqueue() {
    final completer = Completer<Result<String>>();
    _pending.add(completer);
    return completer.future;
  }
}

/// An [ApplyEnhancement] backed by a [PreviewGate].
class _GatedApply implements ApplyEnhancement {
  const _GatedApply(this._gate);

  final PreviewGate _gate;

  @override
  Future<Result<String>> preview({
    required String sourcePath,
    required String destinationPath,
    required EnhancementSettings settings,
  }) => _gate._enqueue();

  @override
  Future<Result<String>> single({
    required String sourcePath,
    required String destinationPath,
    required EnhancementSettings settings,
    int? maxDimension,
  }) => _gate._enqueue();

  @override
  Stream<BatchEvent<String>> batch(
    List<EnhancementRequest> requests, {
    CancellationToken? token,
  }) => const Stream.empty();
}
