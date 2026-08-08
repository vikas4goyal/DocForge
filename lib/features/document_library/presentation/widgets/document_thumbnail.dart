/// A bounded, lazily derived first-page preview for a document.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:flutter/material.dart';

/// Resolves a cached thumbnail-sized rendering of one document page.
typedef DocumentThumbnailLoader =
    Future<Result<String>> Function(Document document, int pageNumber);

/// Displays the first page of [document] without exposing its source PDF.
///
/// The widget uses [LibraryKeys.documentThumbnail] and announces
/// [LibrarySemantics.documentThumbnail]. If [loadThumbnail] is absent or
/// fails, a stable PDF placeholder is shown instead.
class DocumentThumbnail extends StatefulWidget {
  /// Creates a bounded preview for [document].
  const DocumentThumbnail({
    required this.document,
    super.key,
    this.loadThumbnail,
    this.width = 44,
    this.height = 56,
  });

  /// The document whose first page is represented.
  final Document document;

  /// Lazily resolves page 1 to a private cached image path.
  final DocumentThumbnailLoader? loadThumbnail;

  /// Width of the preview box in logical pixels.
  final double width;

  /// Height of the preview box in logical pixels.
  final double height;

  @override
  State<DocumentThumbnail> createState() => _DocumentThumbnailState();
}

class _DocumentThumbnailState extends State<DocumentThumbnail> {
  Future<Result<String>>? _request;

  @override
  void initState() {
    super.initState();
    _requestThumbnail();
  }

  @override
  void didUpdateWidget(covariant DocumentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id ||
        oldWidget.document.isProtected != widget.document.isProtected ||
        (oldWidget.loadThumbnail == null && widget.loadThumbnail != null)) {
      _requestThumbnail();
    }
  }

  void _requestThumbnail() {
    // Store the Future once so an unrelated parent rebuild cannot reopen and
    // rerender the same PDF while the row remains mounted.
    _request = widget.document.isProtected
        ? null
        : widget.loadThumbnail?.call(widget.document, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      image: true,
      label: LibrarySemantics.documentThumbnail(widget.document.title),
      child: ExcludeSemantics(
        child: SizedBox(
          key: LibraryKeys.documentThumbnail(widget.document.id.value),
          width: widget.width,
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: _content(context, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ThemeData theme) {
    if (widget.document.isProtected) return _protectedPlaceholder(theme);
    final request = _request;
    if (request == null) return _placeholder(theme);

    return FutureBuilder<Result<String>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: SizedBox.square(
              key: LibraryKeys.documentThumbnailLoading(
                widget.document.id.value,
              ),
              dimension: 18,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final path = snapshot.data?.valueOrNull;
        if (path == null) return _placeholder(theme);
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: (widget.width * pixelRatio).ceil(),
          cacheHeight: (widget.height * pixelRatio).ceil(),
          errorBuilder: (context, error, stackTrace) => _placeholder(theme),
        );
      },
    );
  }

  Widget _placeholder(ThemeData theme) => Center(
    child: Icon(
      Icons.picture_as_pdf_outlined,
      size: 24,
      color: theme.colorScheme.primary,
    ),
  );

  Widget _protectedPlaceholder(ThemeData theme) => Center(
    child: Icon(Icons.lock_outline, size: 24, color: theme.colorScheme.primary),
  );
}
