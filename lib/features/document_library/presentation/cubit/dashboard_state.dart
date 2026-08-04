/// State for the dashboard.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:equatable/equatable.dart';

/// A folder as the dashboard lists it.
class DashboardFolder extends Equatable {
  /// Creates a folder entry.
  const DashboardFolder({required this.name, required this.documentCount});

  /// The folder's own name.
  final String name;

  /// How many non-archived documents it holds, counted recursively.
  final int documentCount;

  @override
  List<Object?> get props => [name, documentCount];
}

/// Where the dashboard is in its lifecycle.
enum DashboardStatus {
  /// Nothing has been loaded yet.
  initial,

  /// The folder's contents are being read.
  loading,

  /// The contents are on screen.
  ready,

  /// The contents could not be read.
  failure,
}

/// Immutable state of the dashboard.
///
/// The dashboard browses the library folder and nothing else: only folders
/// inside it are reachable, which is what stops the application becoming a
/// general-purpose file browser it has no business being.
class DashboardState extends Equatable {
  const DashboardState._({
    required this.status,
    required this.path,
    required this.folders,
    required this.documents,
    required this.query,
    this.recents = const [],
    this.storageBytes = 0,
    this.favouritesCount = 0,
    this.archiveCount = 0,
    this.trashCount = 0,
    this.failure,
  });

  /// Before anything has been loaded.
  const DashboardState.initial()
    : this._(
        status: DashboardStatus.initial,
        path: const [],
        folders: const [],
        documents: const [],
        query: '',
      );

  /// Where the dashboard is in its lifecycle.
  final DashboardStatus status;

  /// The folder currently open, relative to the library root.
  ///
  /// Empty means the root, which is where the dashboard opens.
  final List<String> path;

  /// The child folders of the open folder.
  final List<DashboardFolder> folders;

  /// The documents in the open folder, or the search results when searching.
  final List<Document> documents;

  /// What the user has typed into the search field.
  final String query;

  /// The most recently modified documents, from anywhere in the library.
  ///
  /// Shown at the root only. Inside a folder the user has already said which
  /// documents they are interested in, and a recents strip would be answering
  /// a question they did not ask.
  final List<Document> recents;

  /// How much space the library occupies.
  final int storageBytes;

  /// Number of active favourites.
  final int favouritesCount;

  /// Number of archived documents.
  final int archiveCount;

  /// Number of recoverable Trash entries.
  final int trashCount;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether the open folder is the library root.
  bool get isAtRoot => path.isEmpty;

  /// Whether the user is searching.
  ///
  /// A search spans the whole library rather than the open folder: a user who
  /// remembers a document's name rarely remembers which folder they filed it
  /// in, which is the reason they are searching.
  bool get isSearching => query.trim().isNotEmpty;

  /// Whether the contents are being read.
  bool get isLoading =>
      status == DashboardStatus.loading || status == DashboardStatus.initial;

  /// Whether the open folder holds nothing at all.
  bool get isEmpty => folders.isEmpty && documents.isEmpty;

  /// Whether the recents strip should be shown.
  bool get showsRecents => isAtRoot && !isSearching && recents.isNotEmpty;

  /// The breadcrumb from the library root to the open folder.
  List<String> get breadcrumb => ['DocScanly', ...path];

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// the condition that produced it.
  DashboardState copyWith({
    DashboardStatus? status,
    List<String>? path,
    List<DashboardFolder>? folders,
    List<Document>? documents,
    String? query,
    List<Document>? recents,
    int? storageBytes,
    int? favouritesCount,
    int? archiveCount,
    int? trashCount,
    Failure? failure,
  }) => DashboardState._(
    status: status ?? this.status,
    path: path ?? this.path,
    folders: folders ?? this.folders,
    documents: documents ?? this.documents,
    query: query ?? this.query,
    recents: recents ?? this.recents,
    storageBytes: storageBytes ?? this.storageBytes,
    favouritesCount: favouritesCount ?? this.favouritesCount,
    archiveCount: archiveCount ?? this.archiveCount,
    trashCount: trashCount ?? this.trashCount,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    path,
    folders,
    documents,
    query,
    recents,
    storageBytes,
    favouritesCount,
    archiveCount,
    trashCount,
    failure,
  ];
}
