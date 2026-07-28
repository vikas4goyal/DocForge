/// The ordering and membership rules of a creation session.
///
/// Pure functions over value objects: no filesystem, no Flutter, so every rule
/// here is directly unit-testable and none of it can leak into a Cubit.
///
/// Moved here from `document_scanning` because the page table serves every way
/// a page can arrive — camera, photo library, files, a share — and naming these
/// rules "scanning" would make the import feature depend on the scanning
/// feature to reach them (`design.md` D9).
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page_draft.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';

/// The rules the page table applies to its list.
abstract final class CreationSession {
  /// Returns [pages] with the page at [from] moved to [to].
  ///
  /// Out-of-range indices return the list unchanged rather than throwing: a
  /// drag that ends outside the list is a normal gesture, not an error.
  static List<PageDraft> reorder(List<PageDraft> pages, int from, int to) {
    if (from < 0 || from >= pages.length) return pages;
    if (to < 0 || to >= pages.length) return pages;
    if (from == to) return pages;

    final updated = [...pages];
    updated.insert(to, updated.removeAt(from));
    return updated;
  }

  /// Returns [pages] with the page at [index] moved one position earlier.
  ///
  /// The screen-reader counterpart of a drag: reordering must not require a
  /// gesture only a sighted user with a pointer can perform.
  static List<PageDraft> moveUp(List<PageDraft> pages, int index) =>
      reorder(pages, index, index - 1);

  /// Returns [pages] with the page at [index] moved one position later.
  static List<PageDraft> moveDown(List<PageDraft> pages, int index) =>
      reorder(pages, index, index + 1);

  /// Returns [pages] without the page at [index].
  static List<PageDraft> delete(List<PageDraft> pages, int index) {
    if (index < 0 || index >= pages.length) return pages;
    return [...pages]..removeAt(index);
  }

  /// Returns [pages] with [page] re-inserted at [index].
  ///
  /// The undo half of [delete]. Restoring by index rather than appending is
  /// what makes an undo put the page back where it was rather than at the end.
  static List<PageDraft> restore(
    List<PageDraft> pages,
    PageDraft page,
    int index,
  ) {
    final updated = [...pages];
    updated.insert(index.clamp(0, updated.length), page);
    return updated;
  }

  /// Returns [pages] with the page at [index] replaced by [page].
  ///
  /// Used after an editor returns: the row keeps its position, because the user
  /// edited a page rather than reordering the document.
  static List<PageDraft> replace(
    List<PageDraft> pages,
    int index,
    PageDraft page,
  ) {
    if (index < 0 || index >= pages.length) return pages;
    return [...pages]..[index] = page;
  }

  /// Whether the session can be turned into a document.
  ///
  /// The library forbids a document with no pages, so the save action stays
  /// disabled until at least one page survives.
  static bool canSave(List<PageDraft> pages) => pages.isNotEmpty;

  /// Whether leaving the session should ask for confirmation first.
  ///
  /// Only when there is something to lose: a confirmation over an empty table
  /// is a question with one sensible answer.
  static bool needsDiscardConfirmation(List<PageDraft> pages) =>
      pages.isNotEmpty;

  /// The one-based page number shown on the row at [index].
  static int pageNumberAt(int index) => index + 1;

  /// Converts the session into the bundle PDF generation consumes.
  ///
  /// Each page contributes its *original* and its settings, because composition
  /// applies the geometry and the enhancement itself — handing it a rendered
  /// image would apply both layers twice.
  static ScannedPageBundle toBundle(
    List<PageDraft> pages, {
    PageSource source = PageSource.camera,
    String? suggestedTitle,
  }) => ScannedPageBundle(
    pages: [for (final page in pages) page.toPageRef()],
    source: source,
    suggestedTitle: suggestedTitle,
  );

  /// The identifiers of every page in [pages], for cleaning up their files.
  static Set<PageId> idsOf(List<PageDraft> pages) => {
    for (final page in pages) page.id,
  };
}
