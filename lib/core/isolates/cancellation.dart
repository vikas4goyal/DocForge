/// Cooperative cancellation for long-running work.
///
/// Dart isolates cannot be interrupted from outside without killing them
/// outright, which would leave half-written files behind. Cancellation is
/// therefore cooperative: the worker checks its token between units of work and
/// returns cleanly, so completed pages survive and partial output is removed —
/// exactly what the scanning, enhancement, OCR and PDF specs require.
library;

import 'dart:async';

/// Signals that in-flight work should stop at the next safe point.
///
/// A token is one-shot: once cancelled it stays cancelled, so a worker that
/// checks late still sees the request.
class CancellationToken {
  /// Creates a token that has not been cancelled.
  CancellationToken();

  final _controller = StreamController<void>.broadcast();
  bool _isCancelled = false;

  /// Whether cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Emits once when cancellation is requested.
  ///
  /// Useful for aborting an await that would otherwise outlive the request.
  Stream<void> get onCancel => _controller.stream;

  /// Requests cancellation.
  ///
  /// Safe to call more than once; subsequent calls do nothing.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    if (!_controller.isClosed) {
      _controller
        ..add(null)
        ..close();
    }
  }

  /// Throws [CancelledException] when cancellation has been requested.
  ///
  /// Call between units of work — after each page, not inside a pixel loop —
  /// so the cost is negligible and the work left behind is always consistent.
  void throwIfCancelled() {
    if (_isCancelled) throw const CancelledException();
  }

  /// Releases the token's resources.
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}

/// Thrown inside a worker when its [CancellationToken] has been cancelled.
///
/// Callers convert this into `Failure.cancelled()` rather than letting it
/// escape, so cancellation stays a normal outcome rather than a crash.
class CancelledException implements Exception {
  /// Creates a cancellation signal.
  const CancelledException();

  @override
  String toString() => 'CancelledException: the operation was cancelled';
}

/// How far a long-running operation has progressed.
///
/// Reported in whole units — pages completed out of pages total — because that
/// is what the specs require the UI to show, and it stays meaningful when an
/// operation is cancelled part-way.
class Progress {
  /// Creates a progress report of [completed] out of [total] units.
  const Progress({required this.completed, required this.total})
    : assert(completed >= 0, 'completed cannot be negative'),
      assert(total >= 0, 'total cannot be negative');

  /// Units finished so far.
  final int completed;

  /// Total units of work.
  final int total;

  /// Completion as a fraction from 0.0 to 1.0.
  ///
  /// An empty operation counts as complete, so a progress bar for zero work
  /// does not sit at zero forever.
  double get fraction => total == 0 ? 1.0 : completed / total;

  /// Whether every unit has finished.
  bool get isComplete => completed >= total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Progress && other.completed == completed && other.total == total;

  @override
  int get hashCode => Object.hash(completed, total);

  @override
  String toString() => 'Progress($completed/$total)';
}
