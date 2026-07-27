/// The Bloc driving the search screen.
///
/// A Bloc rather than a Cubit — the one place in the application where that is
/// justified, per `design.md` §3. Search is the only feature whose *event
/// stream* needs transforming: keystrokes must be debounced so a five-letter
/// word runs one query rather than five, and each new query must cancel the one
/// before it so a slow result cannot land after a newer one. `restartable()`
/// expresses both; a Cubit has no event stream to transform and would need that
/// logic hand-rolled with timers and generation counters.
library;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_search/domain/repositories/search_repository.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// How long typing pauses before a search runs.
///
/// Long enough that a word typed at speed produces one query, short enough that
/// the results feel like they are following the user rather than lagging behind
/// them.
const searchDebounce = Duration(milliseconds: 250);

/// Something that happened on the search screen.
sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => const [];
}

/// The user changed what they typed.
class SearchTermChanged extends SearchEvent {
  /// Creates the event.
  const SearchTermChanged(this.term);

  /// What the field now contains.
  final String term;

  @override
  List<Object?> get props => [term];
}

/// The user chose a folder to search within, or cleared the choice.
class SearchFolderFilterChanged extends SearchEvent {
  /// Creates the event.
  const SearchFolderFilterChanged(this.folderId);

  /// The folder, or null to search everywhere.
  final FolderId? folderId;

  @override
  List<Object?> get props => [folderId];
}

/// The user changed a date filter.
class SearchDateFilterChanged extends SearchEvent {
  /// Creates the event.
  const SearchDateFilterChanged({this.created, this.modified});

  /// The creation-date range, or null to leave it unchanged.
  final DateRange? created;

  /// The modification-date range, or null to leave it unchanged.
  final DateRange? modified;

  @override
  List<Object?> get props => [created, modified];
}

/// The user cleared the search.
class SearchCleared extends SearchEvent {
  /// Creates the event.
  const SearchCleared();
}

/// Where the search screen is in its lifecycle.
enum SearchStatus {
  /// Nothing has been searched for yet.
  initial,

  /// A search is running.
  searching,

  /// Results are available.
  results,

  /// The search matched nothing.
  empty,

  /// The search failed.
  failure,
}

/// Immutable state of the search screen.
class SearchState extends Equatable {
  const SearchState._({
    required this.status,
    required this.query,
    this.results = const [],
    this.failure,
  });

  /// Before anything has been searched for.
  const SearchState.initial()
    : this._(status: SearchStatus.initial, query: const SearchQuery());

  /// Where the screen is in its lifecycle.
  final SearchStatus status;

  /// What is being searched for.
  final SearchQuery query;

  /// What matched.
  final List<SearchResult> results;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether a search is running.
  bool get isSearching => status == SearchStatus.searching;

  /// The announcement made when the result count changes.
  String get resultCountLabel => SearchRules.resultCountLabel(results.length);

  /// Whether the field has anything in it to clear.
  bool get canClear => query.term.isNotEmpty || query.hasFilters;

  /// Returns a copy with the given fields replaced.
  SearchState copyWith({
    SearchStatus? status,
    SearchQuery? query,
    List<SearchResult>? results,
    Failure? failure,
  }) => SearchState._(
    status: status ?? this.status,
    query: query ?? this.query,
    results: results ?? this.results,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, query, results, failure];
}

/// Drives the search screen.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  /// Creates the Bloc over its [_repository].
  SearchBloc(this._repository) : super(const SearchState.initial()) {
    // Debounced *and* restartable. Debouncing alone would still let two
    // in-flight queries race when one is slow; restartable alone would run a
    // query per keystroke. Together they give one query per pause, and only the
    // newest one can produce results.
    on<SearchTermChanged>(
      (event, emit) => _run(state.query.copyWith(term: event.term), emit),
      transformer: (events, mapper) => restartable<SearchTermChanged>()(
        events.debounce(searchDebounce),
        mapper,
      ),
    );

    // Filters are not debounced: a filter change is one deliberate action, not
    // a stream of them, and waiting a quarter of a second after a tap reads as
    // lag.
    on<SearchFolderFilterChanged>(
      (event, emit) => _run(
        event.folderId == null
            ? state.query.copyWith(clearFolder: true)
            : state.query.copyWith(folderId: event.folderId),
        emit,
      ),
      transformer: restartable(),
    );

    on<SearchDateFilterChanged>(
      (event, emit) => _run(
        state.query.copyWith(
          createdWithin: event.created,
          modifiedWithin: event.modified,
          clearCreated: event.created?.isUnbounded ?? false,
          clearModified: event.modified?.isUnbounded ?? false,
        ),
        emit,
      ),
      transformer: restartable(),
    );

    on<SearchCleared>(
      (event, emit) => emit(const SearchState.initial()),
      transformer: restartable(),
    );
  }

  final SearchRepository _repository;

  /// Runs [query] and emits its outcome.
  Future<void> _run(SearchQuery query, Emitter<SearchState> emit) async {
    if (query.isEmpty) {
      // Not a search but the state before one. Running it would return the
      // whole library with a spinner in front of it.
      emit(const SearchState.initial().copyWith(query: query));
      return;
    }

    emit(state.copyWith(status: SearchStatus.searching, query: query));

    final result = await _repository.search(query);

    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: value.isEmpty ? SearchStatus.empty : SearchStatus.results,
        query: query,
        results: value,
      ),
      Failed(:final failure) => state.copyWith(
        status: SearchStatus.failure,
        query: query,
        failure: failure,
      ),
    });
  }
}
