/// The building blocks of the PDF editor.
library;

import 'package:doc_scanly/core/formatting/display_formatting.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:flutter/material.dart';

/// Builds the thumbnail image for a page.
///
/// Injected from the composition root because rendering a PDF page is
/// plugin-backed and cannot happen in a test or a preview — the same reason the
/// viewer's page surface is injected. The editor stays previewable and
/// golden-testable with a coloured placeholder.
typedef PageThumbnailBuilder =
    Widget Function(BuildContext context, int pageIndex);

/// One selectable page in the editor's grid.
///
/// Announces its page number *and* its selection state, which the
/// accessibility scenario requires — a thumbnail that only said "page 3" would
/// give a screen-reader user no way to know what they had chosen.
class PdfPageTile extends StatelessWidget {
  /// Creates a tile for the page at [index].
  const PdfPageTile({
    required this.index,
    required this.pageCount,
    required this.isSelected,
    required this.thumbnailBuilder,
    super.key,
    this.onTap,
  });

  /// Zero-based position of the page.
  final int index;

  /// How many pages the document has.
  final int pageCount;

  /// Whether this page is selected.
  final bool isSelected;

  /// Builds the page image.
  final PageThumbnailBuilder thumbnailBuilder;

  /// Invoked when the page is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: PdfEditRules.pageSemanticsLabel(
        index + 1,
        pageCount: pageCount,
        isSelected: isSelected,
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: thumbnailBuilder(context, index),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 4,
                top: 4,
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One editing action in the editor's toolbar.
class PdfEditActionButton extends StatelessWidget {
  /// Creates a button for [operation].
  const PdfEditActionButton({
    required this.operation,
    required this.icon,
    super.key,
    this.onPressed,
  });

  /// The operation this button invokes.
  final PdfEditOperation operation;

  /// The icon shown.
  final IconData icon;

  /// Invoked when pressed. A null handler disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      // The semantics label goes on the Icon, not in `tooltip`: a tooltip is
      // announced as a tooltip, which leaves an icon-only button with nothing
      // actionable to say.
      icon: Icon(icon, semanticLabel: operation.semanticsLabel),
      tooltip: operation.label,
    );
  }
}

/// The preview of how a watermark will look.
///
/// Required by the spec before the watermark is applied: a user who cannot see
/// what "DRAFT" will look like across their document has to apply it to find
/// out, and applying it rewrites the file.
class WatermarkPreview extends StatelessWidget {
  /// Creates a preview of [text].
  const WatermarkPreview({required this.text, super.key});

  /// The watermark text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: PdfEditKeys.watermarkPreview,
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: -0.4,
        child: Text(
          text.trim().isEmpty ? 'DRAFT' : text.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            // Faint enough to read as a watermark, but no fainter: at 0.28 —
            // which is what a real watermark looks like — it fails the WCAG
            // contrast guideline the project treats as mandatory. The preview
            // exists to be *read* before the watermark is applied, so
            // legibility wins over fidelity here.
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// The document's metadata, as the metadata view shows it.
class PdfMetadataView extends StatelessWidget {
  /// Creates the view over [metadata].
  const PdfMetadataView({required this.metadata, super.key});

  /// What to display.
  final PdfMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Title', metadata.title),
      ('Pages', '${metadata.pageCount}'),
      ('Size', DisplayFormatting.fileSize(metadata.sizeInBytes)),
      ('Created', DisplayFormatting.date(metadata.createdAt)),
      ('Modified', DisplayFormatting.date(metadata.updatedAt)),
      ('Protected', metadata.isProtected ? 'Yes' : 'No'),
    ];

    return Column(
      key: PdfEditKeys.metadataView,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, value) in rows)
          Semantics(
            // Name and value together, so a screen reader announces "Pages, 7"
            // rather than reading a label and a number as separate items the
            // user has to associate themselves.
            label: PdfEditSemantics.metadataRow(label, value),
            excludeSemantics: true,
            child: ListTile(
              dense: true,
              title: Text(label),
              // A bare Text rather than a Flexible one: a ListTile's trailing
              // slot is not a Flex, so a Flexible there is a parent-data error
              // at runtime. The width bound comes from the ConstrainedBox.
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The list of documents being merged, in the order chosen.
///
/// Reorderable, because "merge order is user-controlled" is a requirement in
/// its own right and a fixed list would satisfy neither half of it.
class MergeOrderList extends StatelessWidget {
  /// Creates the list over [titles], in their current order.
  const MergeOrderList({
    required this.titles,
    required this.onReorder,
    super.key,
  });

  /// The document titles, in merge order.
  final List<String> titles;

  /// Invoked with the old and new index when the user reorders.
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      key: PdfEditKeys.mergeOrderList,
      shrinkWrap: true,
      itemCount: titles.length,
      // `onReorderItem` rather than the deprecated `onReorder`: it adjusts the
      // new index for the removed item, which `onReorder` left to every caller
      // to get right.
      onReorderItem: onReorder,
      itemBuilder: (context, index) => ListTile(
        key: ValueKey('merge_item_$index'),
        leading: Text('${index + 1}'),
        title: Text(
          titles[index],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.drag_handle,
          semanticLabel: 'Drag to reorder',
        ),
      ),
    );
  }
}
