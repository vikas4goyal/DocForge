/// State for the document detail screen.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/document_page_handle.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/document_library/domain/document_duplicate.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:equatable/equatable.dart';

/// Loading phase for real move destinations.
enum FolderOptionsStatus {
  /// The picker has not requested destinations yet.
  idle,

  /// Folder destinations are loading.
  loading,

  /// One or more eligible destinations are ready.
  ready,

  /// No eligible folder destination exists.
  empty,

  /// Folder destinations could not be loaded.
  failure,
}

/// Phase of the reviewed duplicate workflow.
enum DuplicateStatus {
  /// No duplicate review is active.
  idle,

  /// Inputs are visible for review.
  reviewing,

  /// Exactly one duplicate request is being submitted.
  submitting,

  /// A copy was created.
  succeeded,

  /// The latest duplicate request failed and can be corrected or retried.
  failure,
}

/// Immutable state of the document detail screen.
class DocumentDetailState extends Equatable {
  /// Creates a detail state.
  const DocumentDetailState({
    required this.status,
    this.document,
    this.pages = const [],
    this.pageHandles = const [],
    this.folderOptionsStatus = FolderOptionsStatus.idle,
    this.folderOptions = const [],
    this.duplicateStatus = DuplicateStatus.idle,
    this.duplicateRequest,
    this.duplicateOutcome,
    this.isWorking = false,
    this.isDeleted = false,
    this.failure,
  });

  /// The state before the document is requested.
  const DocumentDetailState.initial() : this(status: LoadStatus.initial);

  /// Where the screen is in its load cycle.
  final LoadStatus status;

  /// The loaded document, or null before it arrives.
  final Document? document;

  /// The document's pages, in page order.
  final List<DocumentPage> pages;

  /// Unified pages shown by Detail, including virtual imported-PDF pages.
  final List<DocumentPageHandle> pageHandles;

  /// Current phase of loading destinations for Move and Duplicate.
  final FolderOptionsStatus folderOptionsStatus;

  /// Eligible active folders in deterministic display order.
  final List<Folder> folderOptions;

  /// Current phase of the reviewed duplicate workflow.
  final DuplicateStatus duplicateStatus;

  /// Inputs currently displayed in the duplicate review.
  final DuplicateDocumentRequest? duplicateRequest;

  /// Successful duplicate result retained for announcement/navigation.
  final DuplicateDocumentOutcome? duplicateOutcome;

  /// Whether a lifecycle action is in flight.
  ///
  /// Separate from [status] so an action does not blank the metadata the user
  /// is reading; it only disables the controls that would conflict with it.
  final bool isWorking;

  /// Whether the document has been permanently removed.
  ///
  /// The screen watches this to pop itself: once the record is gone there is
  /// nothing left to render, and staying would show stale metadata for a
  /// document that no longer exists.
  final bool isDeleted;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure], or null when there is none.
  String? get message => failure?.presentation.message;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so an error shown for one action
  /// does not persist into the next.
  DocumentDetailState copyWith({
    LoadStatus? status,
    Document? document,
    List<DocumentPage>? pages,
    List<DocumentPageHandle>? pageHandles,
    FolderOptionsStatus? folderOptionsStatus,
    List<Folder>? folderOptions,
    DuplicateStatus? duplicateStatus,
    DuplicateDocumentRequest? duplicateRequest,
    DuplicateDocumentOutcome? duplicateOutcome,
    bool? isWorking,
    bool? isDeleted,
    Failure? failure,
  }) {
    return DocumentDetailState(
      status: status ?? this.status,
      document: document ?? this.document,
      pages: pages ?? this.pages,
      pageHandles: pageHandles ?? this.pageHandles,
      folderOptionsStatus: folderOptionsStatus ?? this.folderOptionsStatus,
      folderOptions: folderOptions ?? this.folderOptions,
      duplicateStatus: duplicateStatus ?? this.duplicateStatus,
      duplicateRequest: duplicateRequest ?? this.duplicateRequest,
      duplicateOutcome: duplicateOutcome,
      isWorking: isWorking ?? this.isWorking,
      isDeleted: isDeleted ?? this.isDeleted,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    document,
    pages,
    pageHandles,
    folderOptionsStatus,
    folderOptions,
    duplicateStatus,
    duplicateRequest,
    duplicateOutcome,
    isWorking,
    isDeleted,
    failure,
  ];
}
