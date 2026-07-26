/// State for the Home screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:equatable/equatable.dart';

/// Where the Home screen is in its load cycle.
enum HomeStatus {
  /// Nothing has been requested yet.
  initial,

  /// A load is in flight.
  loading,

  /// Data arrived and the library holds documents.
  ready,

  /// Data arrived and the library is empty.
  empty,

  /// The load failed.
  failure,
}

/// Immutable state of the Home screen.
///
/// The named factories below are the only intended construction path, so a
/// caller cannot assemble a state that claims to be ready while holding no
/// data, or one that reports a failure with nothing to show for it.
class HomeState extends Equatable {
  const HomeState._({
    required this.status,
    this.recentDocuments = const [],
    this.folders = const [],
    this.favouriteCount = 0,
    this.archivedCount = 0,
    this.storage = StorageSummary.empty,
    this.failure,
  });

  /// The state before anything is requested.
  const HomeState.initial() : this._(status: HomeStatus.initial);

  /// A load is in flight.
  const HomeState.loading() : this._(status: HomeStatus.loading);

  /// The load succeeded; [data] is what Home shows.
  ///
  /// Chooses [HomeStatus.empty] over [HomeStatus.ready] from the data itself,
  /// so the two can never disagree about whether the library is empty.
  factory HomeState.loaded(HomeData data) => HomeState._(
    status: data.isEmpty ? HomeStatus.empty : HomeStatus.ready,
    recentDocuments: data.recentDocuments,
    folders: data.folders,
    favouriteCount: data.favouriteCount,
    archivedCount: data.archivedCount,
    storage: data.storage,
  );

  /// The load failed with [failure].
  const HomeState.failed(Failure failure)
    : this._(status: HomeStatus.failure, failure: failure);

  /// Where the screen is in its load cycle.
  final HomeStatus status;

  /// The most recently modified documents, newest first.
  final List<Document> recentDocuments;

  /// Every folder with its current document count.
  final List<Folder> folders;

  /// How many non-archived favourites exist.
  final int favouriteCount;

  /// How many archived documents exist.
  final int archivedCount;

  /// Storage consumed by stored documents.
  final StorageSummary storage;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure], or null when there is none.
  String? get message => failure?.presentation.message;

  /// Whether the recent documents section should render at all.
  ///
  /// The spec requires the recents list *not* to be rendered on an empty
  /// library — an empty section header above an empty state reads as a bug.
  bool get showsRecentDocuments =>
      status == HomeStatus.ready && recentDocuments.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    recentDocuments,
    folders,
    favouriteCount,
    archivedCount,
    storage,
    failure,
  ];
}
