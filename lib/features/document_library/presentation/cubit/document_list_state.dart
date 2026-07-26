/// State for a document list.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:equatable/equatable.dart';

/// The lifecycle position of a loaded screen.
///
/// Shared by every library state so "loading", "empty" and "failure" mean the
/// same thing on each screen and a widget can switch on one vocabulary.
enum LoadStatus {
  /// Nothing has been requested yet.
  initial,

  /// A load is in flight.
  loading,

  /// Data arrived and is non-empty.
  ready,

  /// The load succeeded but produced nothing.
  empty,

  /// The load failed.
  failure,
}

/// Immutable state of a document list.
///
/// Modelled as a status enum plus data fields rather than a sealed hierarchy so
/// the current list survives a refresh: `loadMore` and a lifecycle action both
/// re-enter loading without blanking the screen the user is looking at
/// (`design.md` §3).
class DocumentListState extends Equatable {
  /// Creates a document list state.
  ///
  /// Private in effect — the named factories below are the intended
  /// construction path, and `copyWith` covers every transition.
  const DocumentListState({
    required this.status,
    this.documents = const [],
    this.filter = DocumentFilter.all,
    this.sort = DocumentSort.modifiedDescending,
    this.folderId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
  });

  /// The state before anything is requested.
  const DocumentListState.initial({
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) : this(status: LoadStatus.initial, filter: filter, folderId: folderId);

  /// Where this list is in its load cycle.
  final LoadStatus status;

  /// The documents currently shown, already ordered.
  final List<Document> documents;

  /// Which subset of the library this list shows.
  final DocumentFilter filter;

  /// The order documents are shown in.
  final DocumentSort sort;

  /// The folder this list is scoped to, when [filter] is a folder filter.
  final FolderId? folderId;

  /// Whether at least one further page of documents exists.
  final bool hasMore;

  /// Whether the next page is currently being fetched.
  ///
  /// Distinct from `status == loading`: appending a page shows a footer
  /// spinner, whereas a first load or a refresh replaces the whole list.
  final bool isLoadingMore;

  /// What went wrong, when something did.
  ///
  /// The failure itself rather than a rendered string, so the error view can
  /// offer the recovery action that matches it — a retry, a settings link or a
  /// way back — instead of every failure getting the same button.
  final Failure? failure;

  /// The user-facing message for [failure], or null when there is none.
  String? get message => failure?.presentation.message;

  /// Whether a retry control should be offered.
  bool get canRetry => status == LoadStatus.failure;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared on every transition rather than being carried
  /// forward, so a stale error cannot outlive the failure that caused it; pass
  /// [failure] explicitly to set a new one.
  DocumentListState copyWith({
    LoadStatus? status,
    List<Document>? documents,
    DocumentFilter? filter,
    DocumentSort? sort,
    FolderId? folderId,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
  }) {
    return DocumentListState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      folderId: folderId ?? this.folderId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    documents,
    filter,
    sort,
    folderId,
    hasMore,
    isLoadingMore,
    failure,
  ];
}
