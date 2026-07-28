/// One page of the document being built.
library;

import 'dart:io';

import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/document_creation/presentation/creation_keys.dart';
import 'package:flutter/material.dart';

/// A row in the page table: one page, its number, and what can be done to it.
///
/// The row's position *is* the page number, so nothing here stores one — a
/// reorder renumbers every row for free.
class PageRow extends StatelessWidget {
  /// Creates a row for [page], showing it as page [pageNumber] of [pageCount].
  const PageRow({
    required this.page,
    required this.pageNumber,
    required this.pageCount,
    required this.onCrop,
    required this.onEnhance,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    this.previewPath,
    super.key,
  });

  /// The page this row shows.
  final PageDraft page;

  /// The one-based position this page occupies.
  final int pageNumber;

  /// How many pages the document has, for the announced position.
  final int pageCount;

  /// A rendered image of the page, when one is ready.
  ///
  /// Null while the render is in flight, when a neutral placeholder is shown
  /// rather than the raw original: a row flicking from unenhanced to enhanced
  /// as the user scrolls reads as the list correcting a mistake.
  final String? previewPath;

  /// Opens crop and rotate.
  final VoidCallback onCrop;

  /// Opens enhancement.
  final VoidCallback onEnhance;

  /// Removes this page.
  final VoidCallback onDelete;

  /// Moves this page one position earlier.
  final VoidCallback? onMoveUp;

  /// Moves this page one position later.
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      // Announced as a position rather than a name: a page of a scan has no
      // title, and "page 3 of 7" is what the user is actually tracking.
      label: 'Page $pageNumber of $pageCount',
      // The screen-reader path to reordering. A drag handle is unusable
      // without a pointer, and reordering is not an optional capability.
      //
      // `value` has to be present whenever increase or decrease is: the
      // framework asserts on a node that offers the action but has nothing for
      // the reader to announce moving between.
      value: 'Page $pageNumber',
      onIncrease: onMoveDown,
      onDecrease: onMoveUp,
      increasedValue: onMoveDown == null
          ? 'Page $pageNumber'
          : 'Page ${pageNumber + 1}',
      decreasedValue: onMoveUp == null
          ? 'Page $pageNumber'
          : 'Page ${pageNumber - 1}',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ReorderableDragStartListener(
                key: CreationKeys.dragHandle,
                index: pageNumber - 1,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.drag_handle),
                ),
              ),
              _Thumbnail(previewPath: previewPath, pageNumber: pageNumber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page $pageNumber',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(_describe(page), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              _RowAction(
                actionKey: CreationKeys.rowCropButton,
                icon: Icons.crop,
                label: 'Crop and rotate page $pageNumber',
                onPressed: onCrop,
              ),
              _RowAction(
                actionKey: CreationKeys.rowEnhanceButton,
                icon: Icons.auto_fix_high,
                label: 'Enhance page $pageNumber',
                onPressed: onEnhance,
              ),
              _RowAction(
                actionKey: CreationKeys.rowDeleteButton,
                icon: Icons.delete_outline,
                label: 'Delete page $pageNumber',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A short description of what has been done to [page].
  ///
  /// Named per layer, because each is reverted separately and the user needs to
  /// see which one is in play.
  static String _describe(PageDraft page) {
    final parts = [
      if (page.hasGeometry) 'cropped',
      if (page.hasEnhancement) 'enhanced',
    ];
    return parts.isEmpty ? 'Original' : parts.join(' · ');
  }
}

/// The page's picture, or a placeholder while it is being rendered.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.previewPath, required this.pageNumber});

  final String? previewPath;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final path = previewPath;

    return SizedBox(
      width: 48,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: path == null
            // A static placeholder rather than a spinner: a list of twenty
            // rows would otherwise animate twenty indicators at once, which
            // reads as the whole screen being stuck rather than as thumbnails
            // arriving.
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                // A render that has just been superseded can be deleted while
                // this frame is still painting; a broken-image icon is a better
                // outcome than an exception in the middle of a scroll.
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
      ),
    );
  }
}

/// One of a row's three actions.
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
      // The label names the action *and* the page: "Crop" alone tells a screen
      // reader user nothing about which of seven rows they are on.
      label: label,
      child: ExcludeSemantics(
        child: IconButton(
          key: actionKey,
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}
