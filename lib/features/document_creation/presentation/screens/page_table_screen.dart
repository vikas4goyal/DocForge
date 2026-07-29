/// The page table: creating a PDF is one screen.
library;

import 'package:doc_forge/core/contracts/models/page_draft.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_creation/domain/creation_session.dart';
import 'package:doc_forge/features/document_creation/presentation/creation_keys.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/page_table_cubit.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/page_table_state.dart';
import 'package:doc_forge/features/document_creation/presentation/widgets/page_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the page table can start.
///
/// Grouped into one object rather than six constructor parameters: the set
/// grows with every capability, and a positional list of that length is where
/// two callbacks quietly get swapped.
@immutable
class PageTableActions {
  /// Creates the action set.
  const PageTableActions({
    required this.onAddPage,
    required this.onCropPage,
    required this.onEnhancePage,
    required this.onSave,
    required this.onExit,
    this.previewPathFor,
  });

  /// Opens the sources a page can be added from.
  final VoidCallback onAddPage;

  /// Opens crop and rotate for the page at the given index.
  final void Function(int index, PageDraft page) onCropPage;

  /// Opens enhancement for the page at the given index.
  final void Function(int index, PageDraft page) onEnhancePage;

  /// Opens the save dialog.
  final VoidCallback onSave;

  /// Leaves the session.
  final VoidCallback onExit;

  /// Supplies a rendered image for a row, when one is ready.
  final String? Function(PageDraft page)? previewPathFor;
}

/// Creating a PDF, as one screen.
///
/// Row 1 is page 1, row 2 is page 2, and so on: the list order *is* the
/// document order (`design.md` D9). Every row acts on its own page, and each of
/// the two layers — crop and enhancement — is edited and reverted separately.
class PageTableScreen extends StatelessWidget {
  /// Creates the page table.
  const PageTableScreen({required this.actions, super.key});

  /// What each control does.
  final PageTableActions actions;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PageTableCubit, PageTableState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message ?? ''))),
      builder: (context, state) => Scaffold(
        key: CreationKeys.pageTableScreen,
        appBar: AppBar(
          title: const Text('New PDF'),
          leading: IconButton(
            tooltip: 'Cancel',
            onPressed: actions.onExit,
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              key: CreationKeys.saveButton,
              // Disabled until a page exists: the library forbids a document
              // with no pages, so offering it would be offering a failure.
              onPressed: state.canSave ? actions.onSave : null,
              child: const Text('Save'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: CreationKeys.addPageButton,
          onPressed: state.isAddingPage ? null : actions.onAddPage,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Add page'),
        ),
        body: switch (state.status) {
          PageTableStatus.failure when state.failure != null => AppErrorView(
            key: CreationKeys.errorView,
            failure: state.failure ?? const Failure.unexpected(),
            onRetry: actions.onAddPage,
          ),
          _ when state.isEmpty && !state.isAddingPage => AppEmptyState(
            key: CreationKeys.emptyState,
            icon: Icons.note_add_outlined,
            title: 'No pages yet',
            message:
                'Add a page from the camera or your photos. '
                'Each one is cropped and enhanced before it joins the list.',
            actionLabel: 'Add page',
            onAction: actions.onAddPage,
          ),
          _ => _PageList(state: state, actions: actions),
        },
      ),
    );
  }
}

/// The rows, and the progress shown while one is being added.
class _PageList extends StatelessWidget {
  const _PageList({required this.state, required this.actions});

  final PageTableState state;
  final PageTableActions actions;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PageTableCubit>();

    return Column(
      children: [
        if (state.isAddingPage)
          const LinearProgressIndicator(key: CreationKeys.loadingIndicator),
        Expanded(
          child: ResponsiveLayout(
            compact: (context) => _rows(cubit),
            // The extra width goes to a second column of pages rather than to
            // wider rows: a page is what the user is judging, and a row twice
            // as long shows no more of it.
            expanded: (context) => _rows(cubit, columns: 2),
          ),
        ),
      ],
    );
  }

  Widget _rows(PageTableCubit cubit, {int columns = 1}) {
    final list = ReorderableListView.builder(
      key: CreationKeys.pageList,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: state.pages.length,
      // `onReorderItem` rather than the deprecated `onReorder`: it hands back
      // the index already adjusted for the removed row, which is the
      // adjustment `onReorder` made every caller do by hand.
      onReorderItem: cubit.reorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final page = state.pages[index];
        final number = CreationSession.pageNumberAt(index);

        return PageRow(
          key: CreationKeys.row(page.id),
          page: page,
          pageNumber: number,
          pageCount: state.pageCount,
          previewPath: actions.previewPathFor?.call(page),
          onCrop: () => actions.onCropPage(index, page),
          onEnhance: () => actions.onEnhancePage(index, page),
          onDelete: () => _delete(context, cubit, index, number),
          onMoveUp: index == 0 ? null : () => cubit.moveUp(index),
          onMoveDown: index == state.pages.length - 1
              ? null
              : () => cubit.moveDown(index),
        );
      },
    );

    if (columns == 1) return list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: list,
      ),
    );
  }

  /// Removes a page, offering to put it back.
  ///
  /// Undo rather than a confirmation: deleting one page of many is a small,
  /// frequent action, and a dialog before each would cost more than the
  /// occasional mistake it prevents.
  void _delete(
    BuildContext context,
    PageTableCubit cubit,
    int index,
    int pageNumber,
  ) {
    cubit.delete(index);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Page $pageNumber deleted'),
          action: SnackBarAction(
            label: CreationSemantics.undoDelete,
            onPressed: cubit.undoDelete,
          ),
        ),
      );
  }
}
