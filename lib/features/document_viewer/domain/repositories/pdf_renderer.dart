/// The contract behind PDF rendering, and the rules governing the viewer.
library;

import 'package:doc_scanly/core/failures/result.dart';

/// What a PDF file turned out to be when it was opened.
class OpenedDocument {
  /// Creates a description of an opened file.
  const OpenedDocument({required this.pageCount, required this.isProtected});

  /// How many pages it contains.
  final int pageCount;

  /// Whether it needed a password.
  final bool isProtected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenedDocument &&
          other.pageCount == pageCount &&
          other.isProtected == isProtected;

  @override
  int get hashCode => Object.hash(pageCount, isProtected);

  @override
  String toString() =>
      'OpenedDocument($pageCount pages, protected: $isProtected)';
}

/// Opens PDFs for viewing.
///
/// Deliberately narrow: it reports what a file *is*, and nothing more. Actually
/// drawing pages is the viewer widget's job, because on-demand rendering with
/// bounded memory is a property of the rendering surface rather than of a
/// repository call — pulling every page through this interface would mean
/// holding rendered bitmaps somewhere, which is exactly what the memory
/// requirement forbids.
abstract interface class PdfRenderer {
  /// Opens the PDF at [filePath].
  ///
  /// Fails with a corrupt-file failure when the file cannot be parsed, and with
  /// a not-found failure when it does not exist. A password-protected file that
  /// no [password] unlocks fails with an authentication failure, which is what
  /// the viewer turns into its password prompt.
  Future<Result<OpenedDocument>> open(String filePath, {String? password});
}

/// Rules for navigating a document in the viewer.
abstract final class ViewerRules {
  /// Returns [page] clamped into the document's range.
  ///
  /// One-based, because every number the user sees and types is. Clamping
  /// rather than rejecting means a typed number beyond the end takes them to
  /// the last page, which is what they were reaching for.
  static int clampPage(int page, {required int pageCount}) {
    if (pageCount <= 0) return 1;
    return page.clamp(1, pageCount);
  }

  /// Whether [page] is a valid page number for a document of [pageCount].
  static bool isValidPage(int page, {required int pageCount}) =>
      pageCount > 0 && page >= 1 && page <= pageCount;

  /// Parses [input] as a page number, or null when it is not one.
  ///
  /// Whitespace is tolerated and anything else rejected. Returning null rather
  /// than a guess is what lets the field tell the user their entry was not a
  /// page rather than silently jumping somewhere arbitrary.
  static int? parsePage(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  /// The label shown by the page indicator.
  static String pageIndicatorLabel(int page, int pageCount) =>
      '$page of $pageCount';

  /// The zoom level a document opens at.
  static const defaultZoom = 1.0;

  /// The closest a user can zoom in.
  ///
  /// Four times is enough to read the small print on a receipt scanned at the
  /// balanced quality; beyond it the page image itself has no more detail to
  /// show and the result is just larger pixels.
  static const maxZoom = 4.0;

  /// The furthest a user can zoom out.
  ///
  /// Below the fit-to-width default, so a user can see a whole page of a
  /// landscape document at once.
  static const minZoom = 0.5;

  /// Returns [zoom] clamped into the allowed range.
  static double clampZoom(double zoom) => zoom.clamp(minZoom, maxZoom);

  /// The zoom a double tap moves to from [current].
  ///
  /// Toggles rather than steps: a double tap on an already-zoomed page means
  /// "put it back", which is the gesture's established meaning everywhere else.
  static double toggleZoom(double current) =>
      current > defaultZoom ? defaultZoom : doubleTapZoom;

  /// The zoom a double tap zooms in to.
  static const doubleTapZoom = 2.5;
}
