/// A page thumbnail on the document detail screen.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:flutter/material.dart';

/// A thumbnail for one page of a document.
///
/// Reads the cached thumbnail rather than the page image. A detail screen for a
/// fifty-page scan that decoded fifty full-resolution captures would exhaust
/// memory on a low-end device, so the full image is deliberately unreachable
/// from here.
class PageThumbnail extends StatefulWidget {
  /// Creates a thumbnail for [page].
  const PageThumbnail({
    required this.page,
    super.key,
    this.onTap,
    this.loadThumbnail,
    this.width = 96,
    this.height = 128,
  });

  /// The page to present.
  final DocumentPage page;

  /// Called when the thumbnail is activated.
  final VoidCallback? onTap;

  /// Lazily resolves a derived thumbnail when [DocumentPage.thumbnailPath] is
  /// absent or no longer exists.
  final Future<Result<String>> Function()? loadThumbnail;

  /// Width of the thumbnail box.
  final double width;

  /// Height of the thumbnail box.
  final double height;

  @override
  State<PageThumbnail> createState() => _PageThumbnailState();
}

class _PageThumbnailState extends State<PageThumbnail> {
  Future<Result<String>>? _request;
  String? _storedPath;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant PageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id ||
        oldWidget.page.thumbnailPath != widget.page.thumbnailPath ||
        (oldWidget.loadThumbnail == null && widget.loadThumbnail != null)) {
      _prepare();
    }
  }

  void _prepare() {
    final path = widget.page.thumbnailPath;
    _storedPath = path != null && File(path).existsSync() ? path : null;
    _request = _storedPath == null ? widget.loadThumbnail?.call() : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = widget.page;

    return Semantics(
      button: widget.onTap != null,
      image: true,
      label: LibrarySemantics.pageThumbnail(page.pageNumber),
      child: ExcludeSemantics(
        child: InkWell(
          key: LibraryKeys.pageThumbnail(page.id.value),
          onTap: widget.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ThumbnailImage(
                      page: page,
                      theme: theme,
                      storedPath: _storedPath,
                      request: _request,
                    ),
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
class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({
    required this.page,
    required this.theme,
    required this.storedPath,
    required this.request,
  });

  final DocumentPage page;
  final ThemeData theme;
  final String? storedPath;
  final Future<Result<String>>? request;

  @override
  Widget build(BuildContext context) {
    if (storedPath case final String path) return _file(path);
    final pending = request;
    if (pending == null) return _placeholder;

    return FutureBuilder<Result<String>>(
      future: pending,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: SizedBox.square(
              key: LibraryKeys.pageThumbnailLoading(page.id.value),
              dimension: 24,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final path = snapshot.data?.valueOrNull;
        return path == null ? _placeholder : _file(path);
      },
    );
  }

  Widget _file(String path) => Image.file(
    File(path),
    fit: BoxFit.cover,
    // A deleted or unreadable file must not take the whole screen down; the
    // page still exists and its metadata is still correct.
    errorBuilder: (context, error, stackTrace) => _placeholder,
  );

  Widget get _placeholder => Center(
    child: Icon(
      Icons.image_outlined,
      color: theme.colorScheme.outline,
      size: 32,
    ),
  );
}
