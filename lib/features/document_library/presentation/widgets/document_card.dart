/// A document row in a library list.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
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
  });

  /// The document to present.
  final Document document;

  /// Called when the row is activated.
  final VoidCallback? onTap;

  /// Called when the favourite control is activated.
  final VoidCallback? onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The whole row is one semantics node: a screen reader announces the title,
    // page count, modified date and favourite status together, rather than
    // making the user swipe through four fragments to learn what the row is.
    return Semantics(
      button: true,
      label: DisplayFormatting.documentSemanticsLabel(document),
      child: ExcludeSemantics(
        child: ListTile(
          key: LibraryKeys.documentListItem(document.id.value),
          onTap: onTap,
          leading: Icon(
            Icons.description_outlined,
            color: theme.colorScheme.primary,
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
                    label: 'Password protected',
                    child: Icon(
                      key: LibraryKeys.documentProtectedBadge,
                      Icons.lock_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            DisplayFormatting.documentSubtitle(document),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: switch (onToggleFavourite) {
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
