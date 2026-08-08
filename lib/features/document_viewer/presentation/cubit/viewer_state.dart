/// State for the document viewer.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:equatable/equatable.dart';

/// Where the viewer is in its lifecycle.
enum ViewerStatus {
  /// The document is being opened.
  loading,

  /// The document is protected and needs a password.
  locked,

  /// The document is open and rendering.
  ready,

  /// The document could not be opened.
  failure,
}

/// Immutable state of the document viewer.
class ViewerState extends Equatable {
  const ViewerState._({
    required this.status,
    required this.page,
    this.document,
    this.filePath,
    this.pageCount = 0,
    this.password,
    this.passwordRemembered = false,
    this.failure,
    this.passwordRejected = false,
    this.isFavouriteWorking = false,
    this.actionFailure,
    this.isUnavailable = false,
  });

  /// Before the document has been opened.
  const ViewerState.initial() : this._(status: ViewerStatus.loading, page: 1);

  /// Where the viewer is in its lifecycle.
  final ViewerStatus status;

  /// The page currently in view, counting from one.
  final int page;

  /// The document's metadata, once it is open.
  final Document? document;

  /// A readable device path for the open file.
  ///
  /// Resolved when the document was opened rather than taken from the record:
  /// [Document.libraryPath] is an address, and on Android the readable path is
  /// a cache copy that exists only while the document is open.
  final String? filePath;

  /// How many pages the file contains.
  final int pageCount;

  /// The password the file was opened with, when it needed one.
  ///
  /// Held in memory for the life of this state only. Nothing in the
  /// presentation layer writes it anywhere.
  final String? password;

  /// Whether this document has an explicitly saved automatic-unlock password.
  final bool passwordRemembered;

  /// What went wrong, when something did.
  final Failure? failure;

  /// Whether the last password attempt was rejected.
  ///
  /// Distinct from [failure], because a wrong password is not an error state —
  /// the prompt stays up and simply says so.
  final bool passwordRejected;

  /// Whether a favourite mutation is currently being persisted.
  final bool isFavouriteWorking;

  /// A nonfatal failure from a metadata or favourite action.
  ///
  /// Unlike [failure], this never replaces a PDF that is already readable.
  final Failure? actionFailure;

  /// Whether the document record disappeared while Viewer was open.
  final bool isUnavailable;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// The user-facing message for a failed nonfatal action.
  String? get actionMessage => actionFailure?.presentation.message;

  /// The document's title, or an empty string before it is open.
  String get title => document?.title ?? '';

  /// Whether the document is open and can be read.
  bool get isReady => status == ViewerStatus.ready;

  /// Whether a password is being asked for.
  bool get isLocked => status == ViewerStatus.locked;

  /// The label the page indicator shows.
  String get pageLabel => ViewerRules.pageIndicatorLabel(page, pageCount);

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] and [passwordRejected] are cleared unless supplied, so a
  /// resolved error and a stale rejection cannot outlive their cause.
  ViewerState copyWith({
    ViewerStatus? status,
    int? page,
    Document? document,
    String? filePath,
    int? pageCount,
    String? password,
    bool? passwordRemembered,
    Failure? failure,
    bool passwordRejected = false,
    bool? isFavouriteWorking,
    Failure? actionFailure,
    bool clearActionFailure = false,
    bool? isUnavailable,
  }) => ViewerState._(
    status: status ?? this.status,
    page: page ?? this.page,
    document: document ?? this.document,
    filePath: filePath ?? this.filePath,
    pageCount: pageCount ?? this.pageCount,
    password: password ?? this.password,
    passwordRemembered: passwordRemembered ?? this.passwordRemembered,
    failure: failure,
    passwordRejected: passwordRejected,
    isFavouriteWorking: isFavouriteWorking ?? this.isFavouriteWorking,
    actionFailure: clearActionFailure
        ? null
        : actionFailure ?? this.actionFailure,
    isUnavailable: isUnavailable ?? this.isUnavailable,
  );

  @override
  List<Object?> get props => [
    status,
    page,
    document,
    filePath,
    pageCount,
    password,
    passwordRemembered,
    failure,
    passwordRejected,
    isFavouriteWorking,
    actionFailure,
    isUnavailable,
  ];
}
