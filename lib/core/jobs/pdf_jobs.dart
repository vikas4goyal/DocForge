/// Shared route-scoped PDF candidate and asynchronous-job primitives.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_jobs.freezed.dart';
part 'pdf_jobs.g.dart';

/// Stable identity of every input that can affect candidate bytes.
@freezed
abstract class PdfCandidateFingerprint with _$PdfCandidateFingerprint {
  /// Creates a fingerprint.
  const factory PdfCandidateFingerprint({
    required String sourceIdentity,
    required String configurationIdentity,
    required List<int> orderedPageQualities,
    required bool isProtected,
  }) = _PdfCandidateFingerprint;

  /// Creates a fingerprint from JSON.
  factory PdfCandidateFingerprint.fromJson(Map<String, dynamic> json) =>
      _$PdfCandidateFingerprintFromJson(json);
}

/// One verified, private temporary PDF candidate.
@freezed
@JsonSerializable()
class PdfCandidate with _$PdfCandidate {
  /// Creates a validated candidate.
  PdfCandidate({
    required this.handle,
    required int exactBytes,
    required int pageCount,
    required this.fingerprint,
  }) : exactBytes = _nonNegative(exactBytes, 'exactBytes'),
       pageCount = _positive(pageCount, 'pageCount') {
    if (handle.isEmpty) {
      throw ArgumentError.value(handle, 'handle', 'must not be empty');
    }
  }

  /// Creates a candidate from JSON.
  factory PdfCandidate.fromJson(Map<String, dynamic> json) =>
      _$PdfCandidateFromJson(json);

  /// App-private temporary path or opaque candidate handle.
  @override
  final String handle;

  /// Exact verified candidate size in bytes.
  @override
  final int exactBytes;

  /// Verified page count.
  @override
  final int pageCount;

  /// Inputs that produced these exact bytes.
  @override
  final PdfCandidateFingerprint fingerprint;

  /// Whether protection was applied to this candidate.
  bool get isProtected => fingerprint.isProtected;

  /// Converts this candidate to generated JSON.
  Map<String, dynamic> toJson() => _$PdfCandidateToJson(this);

  static int _nonNegative(int value, String name) {
    if (value < 0) {
      throw RangeError.value(value, name, 'must not be negative');
    }
    return value;
  }

  static int _positive(int value, String name) {
    if (value <= 0) {
      throw RangeError.value(value, name, 'must be positive');
    }
    return value;
  }
}

/// Validated progress from 0 through 100 percent.
@freezed
@JsonSerializable()
class JobProgress with _$JobProgress {
  /// Creates bounded progress.
  JobProgress({required int percent}) : percent = _validate(percent);

  /// Creates progress from JSON.
  factory JobProgress.fromJson(Map<String, dynamic> json) =>
      _$JobProgressFromJson(json);

  /// Whole percentage from zero through one hundred.
  @override
  final int percent;

  /// Converts progress to generated JSON.
  Map<String, dynamic> toJson() => _$JobProgressToJson(this);

  static int _validate(int value) {
    if (value < 0 || value > 100) {
      throw RangeError.range(value, 0, 100, 'percent');
    }
    return value;
  }
}

/// Small non-secret result exposed by a succeeded job state.
@freezed
abstract class JobResultSummary with _$JobResultSummary {
  /// Creates a summary.
  const factory JobResultSummary({
    required int exactBytes,
    required int pageCount,
    String? candidateHandle,
  }) = _JobResultSummary;
}

/// Immutable presentation view of one independent asynchronous job.
@freezed
sealed class AsyncJobView with _$AsyncJobView {
  /// No job has started.
  const factory AsyncJobView.idle() = AsyncJobIdle;

  /// A debounced job is waiting to start.
  const factory AsyncJobView.queued({required int generation}) = AsyncJobQueued;

  /// Work is running with determinate [progress].
  const factory AsyncJobView.running({
    required int generation,
    required JobProgress progress,
  }) = AsyncJobRunning;

  /// Work completed with a non-secret [summary].
  const factory AsyncJobView.succeeded({
    required int generation,
    required JobResultSummary summary,
  }) = AsyncJobSucceeded;

  /// Work was cooperatively cancelled.
  const factory AsyncJobView.cancelled({required int generation}) =
      AsyncJobCancelled;

  /// Work failed with a typed [failure].
  const factory AsyncJobView.failed({
    required int generation,
    required Failure failure,
  }) = AsyncJobFailed;
}

/// One route-local generation and its cooperative cancellation token.
class RouteJobTicket {
  /// Creates a ticket. Instances are issued only by [RouteJobController].
  const RouteJobTicket({required this.generation, required this.token});

  /// Monotonically increasing route-local generation.
  final int generation;

  /// Token cancelled when a newer generation supersedes this ticket.
  final CancellationToken token;
}

/// Owns one in-flight generation for the lifetime of a route.
class RouteJobController {
  /// Creates an idle route-local controller.
  RouteJobController();

  int _generation = 0;
  RouteJobTicket? _current;

  /// Begins a new generation and cancels the prior ticket.
  RouteJobTicket begin() {
    _current?.token.cancel();
    final ticket = RouteJobTicket(
      generation: ++_generation,
      token: CancellationToken(),
    );
    _current = ticket;
    return ticket;
  }

  /// Whether [generation] is still allowed to publish completion.
  bool isCurrent(int generation) =>
      _current?.generation == generation && !_current!.token.isCancelled;

  /// Whether [generation] is latest, including its own cancelled completion.
  ///
  /// Progress requires [isCurrent], while a cancellation result may use this
  /// predicate so the latest job can become visibly cancelled without allowing
  /// an older superseded generation to publish.
  bool isLatest(int generation) => _current?.generation == generation;

  /// Cancels the current generation without creating another.
  void cancel() => _current?.token.cancel();

  /// Cancels work and releases token resources on route disposal.
  void dispose() {
    final current = _current;
    _current = null;
    final token = current?.token;
    if (token != null) {
      token
        ..cancel()
        ..dispose();
    }
  }
}

/// Owns at most one verified candidate and discards replaced values once.
class SingleCandidateOwner {
  /// Creates an empty owner.
  SingleCandidateOwner();

  PdfCandidate? _candidate;

  /// The retained candidate, when one exists.
  PdfCandidate? get candidate => _candidate;

  /// Replaces the retained candidate, discarding the previous value first.
  Future<void> replace(
    PdfCandidate next, {
    required Future<void> Function(PdfCandidate candidate) discard,
  }) async {
    final previous = _candidate;
    if (previous == next) {
      return;
    }
    _candidate = next;
    if (previous != null) {
      await discard(previous);
    }
  }

  /// Transfers ownership of a candidate matching [fingerprint] to the caller.
  PdfCandidate? takeMatching(PdfCandidateFingerprint fingerprint) {
    final retained = _candidate;
    if (retained == null || retained.fingerprint != fingerprint) {
      return null;
    }
    _candidate = null;
    return retained;
  }

  /// Discards and forgets the retained candidate, if any.
  Future<void> clear({
    required Future<void> Function(PdfCandidate candidate) discard,
  }) async {
    final retained = _candidate;
    _candidate = null;
    if (retained != null) {
      await discard(retained);
    }
  }
}
