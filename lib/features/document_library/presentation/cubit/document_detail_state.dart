/// State for the document detail screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:equatable/equatable.dart';

/// Immutable state of the document detail screen.
class DocumentDetailState extends Equatable {
  /// Creates a detail state.
  const DocumentDetailState({
    required this.status,
    this.document,
    this.pages = const [],
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
    bool? isWorking,
    bool? isDeleted,
    Failure? failure,
  }) {
    return DocumentDetailState(
      status: status ?? this.status,
      document: document ?? this.document,
      pages: pages ?? this.pages,
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
    isWorking,
    isDeleted,
    failure,
  ];
}
