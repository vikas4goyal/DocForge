/// The reusable pieces of the Home screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/app_shell/presentation/home_keys.dart';
import 'package:flutter/material.dart';

/// Shows how much storage the stored documents consume.
class StorageSummaryCard extends StatelessWidget {
  /// Creates a storage summary card.
  const StorageSummaryCard({required this.summary, super.key, this.onTap});

  /// The summary to present.
  final StorageSummary summary;

  /// Called when the card is activated.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = DisplayFormatting.fileSize(summary.totalBytes);
    final count = DisplayFormatting.documentCount(summary.documentCount);

    return Card(
      key: HomeKeys.storageSummary,
      margin: EdgeInsets.zero,
      child: Semantics(
        button: onTap != null,
        // The spec requires the summary to state its value to a screen reader,
        // not merely to be labelled "storage".
        label: 'Storage used: $size across $count',
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.storage_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Storage used', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          '$size · $count',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled shortcut to another part of the library.
class HomeShortcut extends StatelessWidget {
  /// Creates a shortcut.
  const HomeShortcut({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
    this.count,
  });

  /// The shortcut's visible label.
  final String label;

  /// The icon shown alongside the label. Decorative; the label carries meaning.
  final IconData icon;

  /// Called when the shortcut is activated.
  final VoidCallback onTap;

  /// Optional count shown beside the label, e.g. how many favourites exist.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticsLabel = count == null
        ? label
        : '$label, ${DisplayFormatting.documentCount(count!)}';

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              // The whole card is the touch target, so it must clear 48dp even
              // when its text is short.
              constraints: const BoxConstraints(
                minHeight: AppTheme.minimumTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count != null)
                      Text('$count', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The recent documents section.
///
/// Renders nothing when there is nothing recent: the caller decides whether the
/// section belongs on screen, because an empty section header above an empty
/// state reads as a bug.
class RecentDocumentsSection extends StatelessWidget {
  /// Creates the section.
  const RecentDocumentsSection({
    required this.documents,
    required this.onOpenDocument,
    super.key,
    this.onSeeAll,
  });

  /// The recent documents, newest first.
  final List<Document> documents;

  /// Called when a document is activated.
  final void Function(DocumentId id) onOpenDocument;

  /// Called when the "see all" control is activated.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: HomeKeys.recentDocuments,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Recent', style: theme.textTheme.titleMedium)),
            if (onSeeAll != null)
              TextButton(
                key: const Key('home_recent_see_all'),
                onPressed: onSeeAll,
                child: const Text('See all'),
              ),
          ],
        ),
        for (final document in documents)
          _RecentRow(
            document: document,
            onTap: () => onOpenDocument(document.id),
          ),
      ],
    );
  }
}

/// A single recent-document row.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.document, required this.onTap});

  final Document document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: DisplayFormatting.documentSemanticsLabel(document),
      child: ExcludeSemantics(
        child: ListTile(
          key: HomeKeys.recentDocument(document.id.value),
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: Icon(
            Icons.description_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            document.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            DisplayFormatting.documentSubtitle(document),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// The folders section, shown as a horizontal strip of chips.
class HomeFoldersSection extends StatelessWidget {
  /// Creates the folders section.
  const HomeFoldersSection({
    required this.folders,
    required this.onOpenFolder,
    super.key,
    this.onSeeAll,
  });

  /// The folders to show.
  final List<Folder> folders;

  /// Called when a folder is activated.
  final void Function(FolderId id) onOpenFolder;

  /// Called when the "see all" control is activated.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: HomeKeys.foldersSection,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Folders', style: theme.textTheme.titleMedium),
            ),
            if (onSeeAll != null)
              TextButton(
                key: const Key('home_folders_see_all'),
                onPressed: onSeeAll,
                child: const Text('See all'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (folders.isEmpty)
          Text(
            'No folders yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final folder in folders)
                Semantics(
                  button: true,
                  label: DisplayFormatting.folderSemanticsLabel(folder),
                  child: ExcludeSemantics(
                    child: ActionChip(
                      key: HomeKeys.folderChip(folder.id.value),
                      avatar: const Icon(Icons.folder_outlined, size: 18),
                      label: Text('${folder.name} (${folder.documentCount})'),
                      onPressed: () => onOpenFolder(folder.id),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
