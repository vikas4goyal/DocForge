/// Immutable presentation state for recoverable Trash.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/trash.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:equatable/equatable.dart';

/// Trash screen lifecycle.
enum TrashStatus {
  /// Nothing requested yet.
  initial,

  /// Entries are loading.
  loading,

  /// Entries or the empty state are ready.
  ready,

  /// Loading failed.
  failure,
}

/// State emitted by `TrashCubit`.
class TrashState extends Equatable {
  /// Creates state.
  const TrashState({
    this.status = TrashStatus.initial,
    this.entries = const [],
    this.mutating = const {},
    this.failure,
    this.message,
  });

  /// Load status.
  final TrashStatus status;

  /// Recoverable entries, newest first.
  final List<TrashEntry> entries;

  /// Entries currently being restored or purged.
  final Set<TrashId> mutating;

  /// Last failure.
  final Failure? failure;

  /// One-shot outcome text for the UI.
  final String? message;

  /// Whether the first load is in flight.
  bool get isLoading =>
      status == TrashStatus.initial || status == TrashStatus.loading;

  /// Returns a changed copy, clearing stale failure/message by default.
  TrashState copyWith({
    TrashStatus? status,
    List<TrashEntry>? entries,
    Set<TrashId>? mutating,
    Failure? failure,
    String? message,
  }) => TrashState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    mutating: mutating ?? this.mutating,
    failure: failure,
    message: message,
  );

  @override
  List<Object?> get props => [status, entries, mutating, failure, message];
}
