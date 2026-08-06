/// The rules governing what may be done to a PDF and what the result means.
///
/// Pure: no Flutter, no plugins, no file system. Which operations are allowed,
/// which pages they act on, what order a merge follows, where a split falls and
/// how a size change is reported are all decisions — and the PDF engine cannot
/// run in the host test VM, so every one of them is tested here rather than
/// through it (`design.md` §29).
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';

/// An editing operation the user can invoke.
enum PdfEditOperation {
  /// Turn one page a quarter turn clockwise.
  rotate('Rotate', 'Rotate the selected page 90 degrees clockwise'),

  /// Remove selected pages.
  delete('Delete', 'Delete the selected pages'),

  /// Copy selected pages into a new document.
  extract('Extract', 'Create a new document from the selected pages'),

  /// Insert a copy of a page after it.
  duplicate('Duplicate', 'Insert a copy of the selected page after it'),

  /// Join several documents into one.
  merge('Merge', 'Combine the selected documents into one'),

  /// Divide a document in two.
  split('Split', 'Divide this document into two at the chosen page'),

  /// Reduce the file size.
  compress('Compress', 'Reduce this document’s file size'),

  /// Stamp text across every page.
  watermark('Watermark', 'Add a text watermark to every page'),

  /// Require a password to open the file.
  protect('Protect', 'Require a password to open this document'),

  /// Remove an existing password.
  removePassword('Remove password', 'Remove this document’s password');

  const PdfEditOperation(this.label, this.semanticsLabel);

  /// The visible label of the control.
  final String label;

  /// What a screen reader announces for the control.
  final String semanticsLabel;

  /// Whether this operation needs at least one page selected.
  bool get needsSelection => switch (this) {
    PdfEditOperation.rotate ||
    PdfEditOperation.delete ||
    PdfEditOperation.extract ||
    PdfEditOperation.duplicate => true,
    _ => false,
  };

  /// Whether this operation produces a *new* document rather than changing one.
  ///
  /// Drives what happens afterwards: a new document is opened, whereas an
  /// in-place edit leaves the user looking at the document they were editing.
  bool get producesNewDocument => switch (this) {
    PdfEditOperation.extract ||
    PdfEditOperation.merge ||
    PdfEditOperation.split => true,
    _ => false,
  };
}

/// What an editing operation produced.
class EditedPdf {
  /// Creates a description of an edited file.
  const EditedPdf({
    required this.filePath,
    required this.pageCount,
    required this.sizeInBytes,
  });

  /// Where the result is on disk.
  final String filePath;

  /// How many pages it has.
  final int pageCount;

  /// Its size in bytes.
  final int sizeInBytes;
}

/// A PDF's metadata, as the metadata view shows it.
class PdfMetadata {
  /// Creates a metadata record.
  const PdfMetadata({
    required this.title,
    required this.pageCount,
    required this.sizeInBytes,
    required this.createdAt,
    required this.updatedAt,
    required this.isProtected,
  });

  /// The document's title.
  final String title;

  /// How many pages it has.
  final int pageCount;

  /// Its size in bytes.
  final int sizeInBytes;

  /// When it was created.
  final DateTime createdAt;

  /// When it was last modified.
  final DateTime updatedAt;

  /// Whether it needs a password to open.
  final bool isProtected;
}

/// Decisions about editing a PDF.
abstract final class PdfEditRules {
  /// The fewest pages a document may contain.
  ///
  /// A document with no pages is not a document; the library has no way to show
  /// one and the viewer has nothing to render.
  static const minimumPageCount = 1;

  /// The fewest documents a merge needs.
  static const minimumMergeCount = 2;

  /// Suffix used for the file an operation writes before it is put in place.
  ///
  /// Distinct from the `.partial` suffix used elsewhere so a stray file makes
  /// it obvious which subsystem left it.
  static const workingSuffix = '.editing';

  /// The quality preset used when compressing.
  ///
  /// Chosen to be visibly lossless on a scanned page at reading size while
  /// still recovering meaningful space from camera-resolution images.
  static const compressionImageQuality = 60;

  /// Whether [pages] may be deleted from a document of [pageCount].
  ///
  /// The rule the spec states directly: an operation that would empty a
  /// document is refused rather than attempted and rolled back.
  static bool canDelete(Set<int> pages, {required int pageCount}) =>
      pages.isNotEmpty && pageCount - pages.length >= minimumPageCount;

  /// The failure returned when [canDelete] is false.
  static const wouldEmptyDocument = Failure.validation(
    issue: ValidationIssue.documentWouldHaveNoPages,
  );

  /// The message shown when a delete is refused.
  static const wouldEmptyDocumentMessage =
      'A document must contain at least one page.';

  /// Whether [documents] can be merged.
  static bool canMerge(List<Document> documents) =>
      documents.length >= minimumMergeCount;

  /// Whether a split at [afterPage] is valid for a document of [pageCount].
  ///
  /// One-based and *exclusive of the last page*: splitting after the final page
  /// would produce an empty second document, which is not a split.
  static bool canSplit(int afterPage, {required int pageCount}) =>
      pageCount > 1 && afterPage >= 1 && afterPage < pageCount;

  /// The zero-based page indices remaining after [removed] are deleted.
  static List<int> pagesAfterDeleting(
    Set<int> removed, {
    required int pageCount,
  }) => [
    for (var index = 0; index < pageCount; index++)
      if (!removed.contains(index)) index,
  ];

  /// The zero-based page indices of a document with [page] duplicated.
  ///
  /// The copy goes immediately after the original, which is what the spec
  /// requires and what makes a duplicated page findable without scrolling.
  static List<int> pagesAfterDuplicating(int page, {required int pageCount}) =>
      [
        for (var index = 0; index < pageCount; index++) ...[
          index,
          if (index == page) index,
        ],
      ];

  /// The two page ranges a split at [afterPage] produces.
  ///
  /// Zero-based, and together they are exactly the original in order — which is
  /// the property the split scenario states and the test asserts.
  static ({List<int> first, List<int> second}) splitRanges(
    int afterPage, {
    required int pageCount,
  }) => (
    first: [for (var index = 0; index < afterPage; index++) index],
    second: [for (var index = afterPage; index < pageCount; index++) index],
  );

  /// [selected] as an ordered, de-duplicated list of zero-based indices.
  ///
  /// A selection arrives in tap order and may contain a page twice if the user
  /// double-tapped. Extraction has to produce pages in *document* order, which
  /// is what sorting here guarantees regardless of how the UI collected them.
  static List<int> orderedSelection(Iterable<int> selected) =>
      (selected.toSet().toList()..sort());

  /// Whether compression produced enough benefit to be worth keeping.
  ///
  /// A rewrite can legitimately come out *larger* — re-encoding already-optimal
  /// images adds overhead — and the spec requires the original to be kept and
  /// the user told, rather than a "compressed" file that is bigger.
  static bool compressionWorthKeeping({
    required int originalBytes,
    required int compressedBytes,
  }) => compressedBytes < originalBytes;

  /// How a size change from [originalBytes] to [newBytes] is reported.
  static String sizeChangeMessage({
    required int originalBytes,
    required int newBytes,
  }) {
    if (newBytes >= originalBytes) {
      return 'This document is already as small as it can be.';
    }

    final saved = originalBytes - newBytes;
    final percent = originalBytes == 0
        ? 0
        : (saved * 100 / originalBytes).round();

    return 'Reduced by $percent% — ${_bytes(originalBytes)} '
        'to ${_bytes(newBytes)}.';
  }

  /// Whether [text] can be used as a watermark.
  static bool isValidWatermark(String text) => text.trim().isNotEmpty;

  /// Whether [password] can be used to protect a document.
  ///
  /// A blank password produces a file that prompts and then accepts nothing,
  /// which is worse than no protection at all.
  static bool isValidPassword(String password) => password.trim().isNotEmpty;

  /// The title given to a document extracted from a document of that title.
  static String extractedTitle(String sourceTitle, int pageCount) =>
      pageCount == 1
      ? '$sourceTitle (1 page)'
      : '$sourceTitle ($pageCount pages)';

  /// The title given to the merged result of [documents].
  ///
  /// Named after the first document rather than joining every title: three
  /// merged statements would otherwise produce a name too long to read in a
  /// list, and the user can rename it.
  static String mergedTitle(List<Document> documents) => documents.isEmpty
      ? 'Merged document'
      : '${documents.first.title} (merged)';

  /// The titles given to the two halves of a split of [sourceTitle].
  static ({String first, String second}) splitTitles(String sourceTitle) =>
      (first: '$sourceTitle (1)', second: '$sourceTitle (2)');

  /// The label announced for the thumbnail of page [pageNumber].
  ///
  /// Names the page *and* whether it is selected, which the accessibility
  /// scenario requires — a thumbnail that only announces "page 3" gives a
  /// screen-reader user no way to know what they have chosen.
  static String pageSemanticsLabel(
    int pageNumber, {
    required int pageCount,
    required bool isSelected,
  }) =>
      'Page $pageNumber of $pageCount, '
      '${isSelected ? 'selected' : 'not selected'}';

  /// The label shown while an operation runs on [completed] of [total] pages.
  static String progressLabel(int completed, int total) =>
      total <= 1 ? 'Working…' : 'Page $completed of $total…';

  /// Formats [bytes] the way the metadata view and size reports show it.
  static String _bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
