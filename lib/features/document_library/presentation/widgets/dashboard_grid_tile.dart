/// Files-inspired document and folder cards used by the library grid.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/formatting/display_formatting.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_thumbnail.dart';
import 'package:flutter/material.dart';

/// Presents one document with a prominent preview and quiet metadata.
class DashboardDocumentGridTile extends StatelessWidget {
  /// Creates a document card with stable selected and unselected geometry.
  const DashboardDocumentGridTile({
    required this.document,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
    this.loadThumbnail,
  });

  /// Document represented by the card.
  final Document document;

  /// Whether selection mode currently includes [document].
  final bool selected;

  /// Opens or toggles the document according to the surrounding mode.
  final VoidCallback onTap;

  /// Enters selection mode with this document selected.
  final VoidCallback onLongPress;

  /// Lazily resolves the bounded first-page preview.
  final DocumentThumbnailLoader? loadThumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics =
        '${DisplayFormatting.documentSemanticsLabel(document)}, '
        '${DisplayFormatting.fileSize(document.sizeInBytes)}, '
        '${selected ? 'selected' : 'not selected'}';

    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.34)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: DashboardKeys.documentTile(document.id.value),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => DocumentThumbnail(
                        document: document,
                        loadThumbnail: loadThumbnail,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DisplayFormatting.date(document.updatedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metadata(theme),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DisplayFormatting.fileSize(document.sizeInBytes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metadata(theme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents one folder in the same geometry as a document card.
class DashboardFolderGridTile extends StatelessWidget {
  /// Creates a folder card.
  const DashboardFolderGridTile({
    required this.folder,
    required this.onTap,
    required this.onRename,
    required this.onTrash,
    super.key,
  });

  /// Folder represented by the card.
  final DashboardFolder folder;

  /// Opens the folder.
  final VoidCallback onTap;

  /// Opens its rename flow.
  final VoidCallback onRename;

  /// Opens its reviewed Trash flow.
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modified = folder.modifiedAt == null
        ? 'Modified date unavailable'
        : DisplayFormatting.date(folder.modifiedAt!);
    return Semantics(
      button: true,
      label:
          '${folder.name}, $modified, '
          '${DisplayFormatting.documentCount(folder.documentCount)}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: DashboardKeys.folderTile(folder.name),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            size: 72,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.82,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: PopupMenuButton<_FolderGridAction>(
                            key: DashboardKeys.folderMenu(folder.name),
                            tooltip: 'Actions for ${folder.name}',
                            onSelected: (action) => switch (action) {
                              _FolderGridAction.rename => onRename(),
                              _FolderGridAction.trash => onTrash(),
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                key: DashboardKeys.folderRename,
                                value: _FolderGridAction.rename,
                                child: Text('Rename'),
                              ),
                              PopupMenuItem(
                                key: DashboardKeys.folderTrash,
                                value: _FolderGridAction.trash,
                                child: Text('Move to Trash'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    folder.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    modified,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metadata(theme),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DisplayFormatting.documentCount(folder.documentCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metadata(theme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle? _metadata(ThemeData theme) => theme.textTheme.labelSmall?.copyWith(
  color: theme.colorScheme.onSurfaceVariant,
  height: 1.15,
);

enum _FolderGridAction { rename, trash }
