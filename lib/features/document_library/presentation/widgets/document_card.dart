/// A document row in a library list.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/formatting/display_formatting.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_thumbnail.dart';
import 'package:flutter/material.dart';

/// A single document in a list.
///
/// Renders metadata only — never a page image. The spec requires list rows not
/// to load full-resolution images, and the surest way to honour that is for the
/// row to have no way to reach one.
class DocumentCard extends StatelessWidget {
  /// Creates a card for [document].
  const DocumentCard({
    required this.document,
    super.key,
    this.onTap,
    this.onToggleFavourite,
    this.onRestore,
    this.loadThumbnail,
  });

  /// The document to present.
  final Document document;

  /// Called when the row is activated.
  final VoidCallback? onTap;

  /// Called when the favourite control is activated.
  final VoidCallback? onToggleFavourite;

  /// Restores this document when it is shown in the Archive list.
  final VoidCallback? onRestore;

  /// Lazily resolves the document's first-page preview.
  final DocumentThumbnailLoader? loadThumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The whole row is one semantics node: a screen reader announces the title,
    // page count, modified date and favourite status together, rather than
    // making the user swipe through four fragments to learn what the row is.
    return Semantics(
      button: true,
      label:
          document.contentAvailability ==
              DocumentContentAvailability.downloading
          ? 'Downloading ${document.title} from iCloud, '
                '${DisplayFormatting.documentSemanticsLabel(document)}'
          : DisplayFormatting.documentSemanticsLabel(document),
      child: ExcludeSemantics(
        child: ListTile(
          key: LibraryKeys.documentListItem(document.id.value),
          onTap: onTap,
          leading: DocumentThumbnail(
            document: document,
            loadThumbnail: loadThumbnail,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  document.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (document.isProtected)
                // Marked because the folder is visible to other applications:
                // the badge is what tells the user which of their documents
                // another app could actually read.
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Semantics(
                    label: LibrarySemantics.passwordProtected,
                    child: Icon(
                      key: LibraryKeys.documentProtectedBadge,
                      Icons.lock_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (document.contentAvailability !=
                  DocumentContentAvailability.local)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _CloudStatusIcon(document: document),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DisplayFormatting.documentSubtitle(document),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (document.contentAvailability ==
                  DocumentContentAvailability.downloading)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(
                    key: LibraryKeys.documentCloudDownload(document.id.value),
                  ),
                ),
            ],
          ),
          trailing: onRestore != null
              ? _RestoreButton(document: document, onPressed: onRestore!)
              : switch (onToggleFavourite) {
                  null => null,
                  final onPressed => _FavouriteButton(
                    isFavourite: document.isFavourite,
                    onPressed: onPressed,
                  ),
                },
        ),
      ),
    );
  }
}

/// Restores an archived document without opening it first.
class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.document, required this.onPressed});

  final Document document;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = 'Restore ${document.title} from Archive';
    return IconButton(
      key: LibraryKeys.documentListRestore(document.id.value),
      onPressed: onPressed,
      tooltip: label,
      icon: const Icon(Icons.unarchive_outlined, semanticLabel: 'Restore'),
    );
  }
}

class _CloudStatusIcon extends StatelessWidget {
  const _CloudStatusIcon({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (document.contentAvailability) {
      DocumentContentAvailability.remote => (
        Icons.cloud_outlined,
        'Stored in iCloud',
      ),
      DocumentContentAvailability.downloading => (
        Icons.cloud_download_outlined,
        'Downloading from iCloud',
      ),
      DocumentContentAvailability.failed => (
        Icons.cloud_off_outlined,
        'iCloud download failed',
      ),
      DocumentContentAvailability.available => (
        Icons.cloud_done_outlined,
        'Available from iCloud',
      ),
      DocumentContentAvailability.local => (
        Icons.description_outlined,
        'Stored on this device',
      ),
    };
    return Tooltip(
      message: label,
      child: Icon(
        key: LibraryKeys.documentCloudStatus(document.id.value),
        icon,
        size: 17,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The favourite toggle inside a document row.
///
/// Lifted out of the row's merged semantics so it stays independently
/// actionable: the row announces the favourite *status*, this control offers
/// the *action*.
class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.isFavourite, required this.onPressed});

  final bool isFavourite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isFavourite,
      label: isFavourite ? 'Remove from favourites' : 'Add to favourites',
      child: ExcludeSemantics(
        child: IconButton(
          key: LibraryKeys.documentFavouriteToggle,
          onPressed: onPressed,
          constraints: const BoxConstraints(
            minWidth: AppTheme.minimumTouchTarget,
            minHeight: AppTheme.minimumTouchTarget,
          ),
          icon: Icon(isFavourite ? Icons.star : Icons.star_border),
        ),
      ),
    );
  }
}
