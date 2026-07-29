/// A page thumbnail on the document detail screen.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:flutter/material.dart';

/// A thumbnail for one page of a document.
///
/// Reads the cached thumbnail rather than the page image. A detail screen for a
/// fifty-page scan that decoded fifty full-resolution captures would exhaust
/// memory on a low-end device, so the full image is deliberately unreachable
/// from here.
class PageThumbnail extends StatelessWidget {
  /// Creates a thumbnail for [page].
  const PageThumbnail({
    required this.page,
    super.key,
    this.onTap,
    this.width = 96,
    this.height = 128,
  });

  /// The page to present.
  final DocumentPage page;

  /// Called when the thumbnail is activated.
  final VoidCallback? onTap;

  /// Width of the thumbnail box.
  final double width;

  /// Height of the thumbnail box.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: onTap != null,
      image: true,
      label: LibrarySemantics.pageThumbnail(page.pageNumber),
      child: ExcludeSemantics(
        child: InkWell(
          key: LibraryKeys.pageThumbnail(page.id.value),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _Image(page: page, theme: theme),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${page.pageNumber}', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// The thumbnail image, or a placeholder when none can be shown.
class _Image extends StatelessWidget {
  const _Image({required this.page, required this.theme});

  final DocumentPage page;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final path = page.thumbnailPath;

    // A missing thumbnail is normal — generation is asynchronous and a page can
    // be shown before its thumbnail lands — so it renders as a placeholder
    // rather than an error.
    if (path == null) return _placeholder;

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      // A deleted or unreadable file must not take the whole screen down; the
      // page still exists and its metadata is still correct.
      errorBuilder: (context, error, stackTrace) => _placeholder,
    );
  }

  Widget get _placeholder => Center(
    child: Icon(
      Icons.image_outlined,
      color: theme.colorScheme.outline,
      size: 32,
    ),
  );
}
