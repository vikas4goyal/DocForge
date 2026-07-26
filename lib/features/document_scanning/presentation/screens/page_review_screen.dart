/// The captured-page review screen.
library;

import 'dart:io';

import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:doc_forge/features/document_scanning/presentation/scan_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lets the user rotate, reorder, crop and delete pages before saving.
class PageReviewScreen extends StatelessWidget {
  /// Creates the review screen.
  const PageReviewScreen({
    required this.onSave,
    required this.onAddPages,
    required this.onExit,
    required this.onCropPage,
    super.key,
  });

  /// Called when the user saves the session as a document.
  final VoidCallback onSave;

  /// Called when the user returns to the camera for more pages.
  final VoidCallback onAddPages;

  /// Called when the user leaves the flow with nothing.
  final VoidCallback onExit;

  /// Called to open the crop screen for the page at an index.
  final void Function(int index, CapturedPage page) onCropPage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageReviewCubit, PageReviewState>(
      builder: (context, state) => Scaffold(
        key: ScanKeys.reviewScreen,
        appBar: AppBar(
          title: Text(
            state.pages.length == 1 ? '1 page' : '${state.pages.length} pages',
          ),
          actions: [
            if (state.canSave)
              TextButton(
                key: ScanKeys.saveButton,
                onPressed: onSave,
                child: const Text('Save'),
              ),
          ],
        ),
        floatingActionButton: state.isEmpty
            ? null
            : FloatingActionButton.extended(
                key: ScanKeys.addPagesButton,
                onPressed: onAddPages,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add pages'),
              ),
        body: state.isEmpty
            ? _EmptyState(onAddPages: onAddPages, onExit: onExit)
            : _PageList(state: state, onCropPage: onCropPage),
      ),
    );
  }
}

/// Shown when every page has been deleted.
///
/// Offers both ways forward the spec names — capture again, or leave — plus the
/// undo, which is what makes an accidental deletion of the last page
/// recoverable rather than a dead end.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPages, required this.onExit});

  final VoidCallback onAddPages;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageReviewCubit, PageReviewState>(
      builder: (context, state) => Center(
        key: ScanKeys.reviewEmptyState,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.photo_library_outlined, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'No pages left',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Capture a new page, or leave without saving.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (state.canUndo) ...[
                FilledButton.tonal(
                  key: const Key('scan_review_undo_button'),
                  onPressed: context.read<PageReviewCubit>().undoDelete,
                  child: const Text('Undo delete'),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                key: ScanKeys.addPagesButton,
                onPressed: onAddPages,
                child: const Text('Capture a page'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('scan_review_exit_button'),
                onPressed: onExit,
                child: const Text('Leave without saving'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The reorderable list of captured pages.
class _PageList extends StatelessWidget {
  const _PageList({required this.state, required this.onCropPage});

  final PageReviewState state;
  final void Function(int index, CapturedPage page) onCropPage;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      key: ScanKeys.pageList,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: state.pages.length,
      // onReorderItem rather than the deprecated onReorder: the older callback
      // reports the destination as an insertion point in the *pre-removal*
      // list, so every downward drag lands one place short unless the caller
      // adjusts for it. This one has already adjusted.
      onReorderItem: (from, to) =>
          context.read<PageReviewCubit>().reorder(from, to),
      itemBuilder: (context, index) => _PageRow(
        // Keyed by page identity, not by position: a ReorderableListView keyed
        // by index cannot animate a move, because every row's key changes.
        key: ValueKey(state.pages[index].id.value),
        page: state.pages[index],
        index: index,
        onCrop: () => onCropPage(index, state.pages[index]),
      ),
    );
  }
}

/// One captured page, with its rotate, crop and delete controls.
class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.page,
    required this.index,
    required this.onCrop,
    super.key,
  });

  final CapturedPage page;
  final int index;
  final VoidCallback onCrop;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PageReviewCubit>();

    return ListTile(
      key: ScanKeys.pageItem(page.id.value),
      leading: _Thumbnail(page: page),
      title: Text('Page ${index + 1}'),
      subtitle: page.rotation.degrees == 0
          ? null
          : Text('Rotated ${page.rotation.degrees}°'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RowAction(
            actionKey: ScanKeys.pageRotateButton,
            icon: Icons.rotate_90_degrees_cw_outlined,
            label: 'Rotate page ${index + 1}',
            onPressed: () => cubit.rotate(index),
          ),
          _RowAction(
            actionKey: ScanKeys.pageCropButton,
            icon: Icons.crop,
            label: 'Crop page ${index + 1}',
            onPressed: onCrop,
          ),
          _RowAction(
            actionKey: ScanKeys.pageDeleteButton,
            icon: Icons.delete_outline,
            label: 'Delete page ${index + 1}',
            onPressed: () => _deleteWithUndo(context, cubit, index),
          ),
        ],
      ),
    );
  }

  /// Deletes the page and offers an undo alongside the confirmation.
  ///
  /// The spec requires the deletion to be undoable from the confirmation
  /// affordance, so the snackbar is the affordance rather than a separate
  /// dialog the user has to dismiss before continuing.
  void _deleteWithUndo(BuildContext context, PageReviewCubit cubit, int index) {
    cubit.delete(index);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Page ${index + 1} deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: cubit.undoDelete),
        ),
      );
  }
}

/// One action on a page row.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key actionKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // Names the page as well as the action, so a screen-reader user moving
      // through a long list always knows which page they are about to change.
      label: label,
      child: ExcludeSemantics(
        child: IconButton(
          key: actionKey,
          onPressed: onPressed,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(
            minWidth: AppTheme.minimumTouchTarget,
            minHeight: AppTheme.minimumTouchTarget,
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}

/// A page's thumbnail, or a placeholder when none can be shown.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.page});

  final CapturedPage page;

  @override
  Widget build(BuildContext context) {
    final path = page.thumbnailPath ?? page.imagePath;

    return SizedBox(
      width: 48,
      height: 64,
      child: RotatedBox(
        // Rotation is applied at render time rather than by rewriting the file,
        // so the thumbnail updates immediately and four rotations cost nothing.
        quarterTurns: page.rotation.degrees ~/ 90,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          // A capture that cannot be decoded still has a row the user can
          // delete; a thrown error here would take the whole screen down.
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: Colors.black12),
        ),
      ),
    );
  }
}

/// Progress shown while a batch of pages is being corrected.
///
/// Exposed so the crop flow and its previews render the same thing.
class ScanCorrectionProgress extends StatelessWidget {
  /// Creates a progress view for [completed] of [total] pages.
  const ScanCorrectionProgress({
    required this.completed,
    required this.total,
    super.key,
    this.onCancel,
  });

  /// Pages finished so far.
  final int completed;

  /// Total pages to correct.
  final int total;

  /// Cancels the run. Finished pages are kept.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => AppProgressIndicator(
    completed: completed,
    total: total,
    label: 'Straightening pages',
    onCancel: onCancel,
  );
}
