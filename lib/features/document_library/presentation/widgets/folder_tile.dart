/// A folder row in the folder list.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:flutter/material.dart';

/// A single folder in a list, showing its current document count.
class FolderTile extends StatelessWidget {
  /// Creates a tile for [folder].
  const FolderTile({
    required this.folder,
    super.key,
    this.onTap,
    this.onRename,
    this.onDelete,
  });

  /// The folder to present.
  final Folder folder;

  /// Called when the row is activated.
  final VoidCallback? onTap;

  /// Called when the rename action is chosen.
  final VoidCallback? onRename;

  /// Called when the delete action is chosen.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMenu = onRename != null || onDelete != null;

    return Semantics(
      button: true,
      label: DisplayFormatting.folderSemanticsLabel(folder),
      child: ExcludeSemantics(
        child: ListTile(
          key: LibraryKeys.folderListItem(folder.id.value),
          onTap: onTap,
          leading: Icon(
            Icons.folder_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(DisplayFormatting.documentCount(folder.documentCount)),
          trailing: hasMenu ? _FolderMenu(this) : null,
        ),
      ),
    );
  }
}

/// The per-folder action menu.
class _FolderMenu extends StatelessWidget {
  const _FolderMenu(this.tile);

  final FolderTile tile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LibrarySemantics.folderActions(tile.folder.name),
      child: ExcludeSemantics(
        child: PopupMenuButton<void>(
          key: LibraryKeys.folderMenuButton(tile.folder.id.value),
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            if (tile.onRename != null)
              PopupMenuItem<void>(
                key: LibraryKeys.folderMenuRename,
                onTap: tile.onRename,
                child: const Text('Rename'),
              ),
            if (tile.onDelete != null)
              PopupMenuItem<void>(
                key: LibraryKeys.folderMenuDelete,
                onTap: tile.onDelete,
                child: const Text('Delete'),
              ),
          ],
        ),
      ),
    );
  }
}
