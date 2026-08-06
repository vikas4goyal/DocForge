/// The business rules governing recognition.
///
/// Pure functions, so the Cubit driving the OCR view holds no logic of its own.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';

/// Rules for deciding what to recognise and how to present the result.
abstract final class OcrRules {
  /// Returns the pages of [pages] that still need recognising.
  ///
  /// [stored] is what has already been recognised. This is the rule behind "a
  /// page is recognised at most once": recognition is expensive in both time
  /// and battery, and re-running it on every open would make opening a
  /// fifty-page document cost as much as creating it.
  ///
  /// Set [force] when the user has explicitly asked for a re-run, which the
  /// spec requires to replace the stored text rather than skip the page.
  static List<PageRef> pagesNeedingRecognition(
    List<PageRef> pages,
    Map<PageId, RecognisedText> stored, {
    bool force = false,
  }) {
    if (force) return pages;
    return [
      for (final page in pages)
        if (!stored.containsKey(page.id)) page,
    ];
  }

  /// Whether recognition has been run against every page of [pages].
  static bool isFullyRecognised(
    List<PageRef> pages,
    Map<PageId, RecognisedText> stored,
  ) => pages.every((page) => stored.containsKey(page.id));

  /// Joins the recognised text of [pages] in page order.
  ///
  /// Pages are separated by a blank line so a copied or exported document reads
  /// as pages rather than as one run-on paragraph. Pages with no stored result,
  /// and pages where recognition found nothing, contribute nothing rather than
  /// an empty gap.
  static String combinedText(
    List<PageRef> pages,
    Map<PageId, RecognisedText> stored,
  ) => [
    for (final page in pages)
      if (stored[page.id] case final text? when !text.isEmpty) text.plainText,
  ].join('\n\n');

  /// Whether there is any recognised text at all across [stored].
  ///
  /// Drives whether copy and export are offered: a control that puts an empty
  /// string on the clipboard is worse than one that is visibly unavailable.
  static bool hasText(Map<PageId, RecognisedText> stored) =>
      stored.values.any((text) => !text.isEmpty);

  /// Returns the blocks of [text] that can be placed in a PDF text layer.
  ///
  /// Blocks with an invalid or zero-area box are dropped. A text layer entry
  /// with no position is worse than a missing one: it lands somewhere
  /// arbitrary, and selecting text in the reader then highlights the wrong part
  /// of the page.
  static List<TextBlock> placeableBlocks(RecognisedText text) => [
    for (final block in text.blocks)
      if (block.bounds.isValid && block.text.trim().isNotEmpty) block,
  ];

  /// The name of the text file recognised text is exported as.
  ///
  /// Derived from the document title so a user with several exports can tell
  /// them apart. Characters a filesystem or share sheet would reject are
  /// replaced rather than dropped, so two documents whose titles differ only in
  /// punctuation do not collide.
  static String exportFileName(String documentTitle) {
    final safe = documentTitle
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // A title made entirely of punctuation replaces to a run of underscores,
    // which is a legal filename and a useless one. Treated as no title at all,
    // so the user is offered something they can recognise in a file picker.
    final hasContent = RegExp('[a-zA-Z0-9]').hasMatch(safe);

    return '${hasContent ? safe : 'document'}.txt';
  }
}
