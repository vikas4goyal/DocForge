/// The Cubit driving the page table.
///
/// Every method is emit / call a rule / emit. Ordering, undo positioning and
/// the "at least one page" rule live in [CreationSession] and are unit-tested
/// there; nothing in this class decides them.
library;

import 'package:doc_forge/features/document_creation/domain/creation_session.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/page_table_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the page table screen.
class PageTableCubit extends Cubit<PageTableState> {
  /// Creates the Cubit, optionally seeded with [initialPages].
  ///
  /// Pages arrive already seeded when the session began from a share or a
  /// multi-file import; a session started from the Create control begins empty.
  PageTableCubit({List<PageDraft> initialPages = const []})
    : super(
        initialPages.isEmpty
            ? const PageTableState.initial()
            : const PageTableState.initial().copyWith(pages: initialPages),
      );

  /// Appends [page] as the last row.
  ///
  /// Appending rather than inserting: the user just added it, and putting it
  /// anywhere else would be a position they did not choose.
  void addPage(PageDraft page) => emit(
    state.copyWith(
      status: PageTableStatus.ready,
      pages: [...state.pages, page],
    ),
  );

  /// Marks a page as being added, so the screen can show it is busy.
  void beginAddingPage() =>
      emit(state.copyWith(status: PageTableStatus.addingPage));

  /// Returns to the ready state without adding anything.
  ///
  /// The path taken when the user leaves crop or enhancement without
  /// finishing: the table is left exactly as it was.
  void cancelAddingPage() =>
      emit(state.copyWith(status: PageTableStatus.ready));

  /// Moves the page at [from] to [to].
  void reorder(int from, int to) => emit(
    state.copyWith(pages: CreationSession.reorder(state.pages, from, to)),
  );

  /// Moves the page at [index] one position earlier.
  void moveUp(int index) =>
      emit(state.copyWith(pages: CreationSession.moveUp(state.pages, index)));

  /// Moves the page at [index] one position later.
  void moveDown(int index) =>
      emit(state.copyWith(pages: CreationSession.moveDown(state.pages, index)));

  /// Removes the page at [index], keeping it available for undo.
  void delete(int index) {
    if (index < 0 || index >= state.pages.length) return;

    final removed = state.pages[index];
    emit(
      state.copyWith(
        pages: CreationSession.delete(state.pages, index),
        lastDeleted: DeletedDraft(removed, index),
      ),
    );
  }

  /// Puts the most recently deleted page back where it was.
  void undoDelete() {
    final deleted = state.lastDeleted;
    if (deleted == null) return;

    emit(
      state.copyWith(
        pages: CreationSession.restore(
          state.pages,
          deleted.page,
          deleted.index,
        ),
      ),
    );
  }

  /// Replaces the page at [index] after an editor returned.
  ///
  /// The row keeps its position: the user edited a page, not the order.
  void replace(int index, PageDraft page) => emit(
    state.copyWith(pages: CreationSession.replace(state.pages, index, page)),
  );

  /// Removes every page, after the session has been saved or discarded.
  void clear() => emit(const PageTableState.initial());
}
