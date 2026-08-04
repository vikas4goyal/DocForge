/// State for the page table screen.
library;

import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/document_creation/domain/creation_session.dart';
import 'package:equatable/equatable.dart';

/// A page removed from the table, retained so the removal can be undone.
class DeletedDraft extends Equatable {
  /// Creates a record of a deletion.
  const DeletedDraft(this.page, this.index);

  /// The page that was removed.
  final PageDraft page;

  /// Where it was, so undo puts it back rather than appending it.
  final int index;

  @override
  List<Object?> get props => [page, index];
}

/// Where the page table is in its lifecycle.
enum PageTableStatus {
  /// The table is showing its rows and the controls are live.
  ready,

  /// A page is being added — captured, picked, cropped or enhanced.
  addingPage,

  /// Something went wrong.
  failure,
}

/// Immutable state of the page table screen.
///
/// Row 1 is page 1, row 2 is page 2, and so on through row n: the list order
/// *is* the document order, which is why reordering needs no separate model.
class PageTableState extends Equatable {
  const PageTableState._({
    required this.status,
    required this.pages,
    this.lastDeleted,
    this.failure,
  });

  /// An empty session, before any page has been added.
  const PageTableState.initial()
    : this._(status: PageTableStatus.ready, pages: const []);

  /// Where the screen is in its lifecycle.
  final PageTableStatus status;

  /// The pages, in the order they will appear in the PDF.
  final List<PageDraft> pages;

  /// The most recent deletion, while it can still be undone.
  ///
  /// Cleared by the next edit: an undo offered after three further changes
  /// would put a page back into a list it no longer belongs to.
  final DeletedDraft? lastDeleted;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether the table has no pages.
  bool get isEmpty => pages.isEmpty;

  /// Whether the session can be saved.
  bool get canSave => CreationSession.canSave(pages);

  /// Whether an undo is currently on offer.
  bool get canUndo => lastDeleted != null;

  /// Whether a page is being added.
  bool get isAddingPage => status == PageTableStatus.addingPage;

  /// Whether leaving should ask for confirmation first.
  bool get needsDiscardConfirmation =>
      CreationSession.needsDiscardConfirmation(pages);

  /// How many pages the document will have.
  int get pageCount => pages.length;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] and [lastDeleted] are cleared unless supplied, so a resolved
  /// error and a stale undo cannot outlive the conditions that produced them.
  PageTableState copyWith({
    PageTableStatus? status,
    List<PageDraft>? pages,
    DeletedDraft? lastDeleted,
    Failure? failure,
  }) => PageTableState._(
    status: status ?? this.status,
    pages: pages ?? this.pages,
    lastDeleted: lastDeleted,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, pages, lastDeleted, failure];
}
