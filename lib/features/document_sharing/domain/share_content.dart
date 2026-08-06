/// The rules governing what leaves the application and in what form.
///
/// Pure: no Flutter, no plugins, no file system. Everything here is a decision
/// — which pages, in what order, under what file name, and whether an option is
/// offered at all — and every one of those decisions is unit-tested without a
/// share sheet in sight.
///
/// The security requirement that shapes this file is that content leaves the
/// device *only* through an action the user took. Nothing here initiates a
/// share; it only describes one that has been asked for (`design.md` §27).
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';

/// The form in which a document's content is handed to the system.
enum ShareFormat {
  /// The document's PDF file, exactly as stored.
  pdf('PDF'),

  /// One image file per selected page.
  images('images');

  const ShareFormat(this.label);

  /// How this format is named to the user, mid-sentence.
  final String label;
}

/// What a share action is asking the system to do with the content.
enum ShareAction {
  /// Hand the content to the system share sheet.
  share,

  /// Open the system print dialogue.
  print,

  /// Write the content to a destination the user chooses.
  export,
}

/// Content prepared and ready to be handed to the system.
///
/// Either files, or text, or both — the system share sheet accepts a mixture,
/// and a page-image share carries no text while a text share carries no file.
class SharePayload {
  /// Creates a payload of [filePaths] and/or [text].
  const SharePayload({
    this.filePaths = const [],
    this.text = '',
    this.subject = '',
  });

  /// Absolute paths of the files to share, in the order they should appear.
  final List<String> filePaths;

  /// Plain text to share, empty when the payload is files only.
  final String text;

  /// The subject line offered to applications that use one, such as mail.
  final String subject;

  /// Whether there is anything at all to hand over.
  ///
  /// Guarded before invoking the share sheet: opening it with nothing attached
  /// is a confusing dead end rather than an error the system reports.
  bool get isEmpty => filePaths.isEmpty && text.trim().isEmpty;
}

/// A page selected for image sharing.
///
/// Carries only a path and the transforms to apply, never decoded pixels, so it
/// can cross into a worker isolate (`design.md` §7).
class SharePageRequest {
  /// Creates a request to render [page] into [destinationPath].
  const SharePageRequest({
    required this.page,
    required this.destinationPath,
    required this.quality,
  });

  /// The page to render.
  final PageRef page;

  /// Where the rendered image is written.
  final String destinationPath;

  /// JPEG quality, 0–100.
  final int quality;
}

/// Decisions about what may be shared and how it is named.
abstract final class ShareRules {
  /// Quality used for shared page images.
  ///
  /// Higher than a thumbnail and lower than the archival page: a shared image
  /// is looked at, not re-scanned, and a batch of them has to fit through a
  /// mail attachment limit.
  static const imageQuality = 88;

  /// The directory name, inside the cache, holding content staged for sharing.
  ///
  /// Staged in the *cache* rather than in documents storage because it is a
  /// copy the system may keep a handle on after we are done, and the operating
  /// system is free to reclaim it later. Nothing here is the document of
  /// record.
  static const stagingDirectoryName = 'share_staging';

  /// The pages of a document in the order they must be shared.
  ///
  /// The spec requires page order, and a selection arrives in the order the
  /// user tapped — which is not the same thing. Sorting here rather than
  /// relying on the caller is what makes "in page order" a property of the
  /// feature instead of an accident of the UI.
  static List<DocumentPage> inPageOrder(Iterable<DocumentPage> pages) =>
      [...pages]..sort((a, b) => a.order.compareTo(b.order));

  /// Strips characters that cannot appear in a file name on either platform.
  ///
  /// Applied to a user-entered title, which may contain anything at all.
  static String sanitise(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'Document' : cleaned;
  }

  /// The file name for a shared or exported PDF of [title].
  static String pdfFileName(String title) => '${sanitise(title)}.pdf';

  /// The file name for the image of page [pageNumber] of [title].
  ///
  /// Zero-padded so an application that sorts attachments alphabetically —
  /// which several mail clients do — still shows them in page order past page
  /// nine.
  static String imageFileName(String title, int pageNumber) =>
      '${sanitise(title)}_${'$pageNumber'.padLeft(3, '0')}.jpg';

  /// The subject offered alongside shared content for [document].
  static String subjectFor(Document document) => document.title;

  /// The label a screen reader reads for a share option.
  ///
  /// Names both what will be shared and in what format, which the accessibility
  /// scenario requires and a bare icon cannot convey.
  static String optionSemanticsLabel(
    ShareAction action,
    ShareFormat format, {
    required String title,
    int pageCount = 0,
  }) {
    final what = switch (format) {
      ShareFormat.pdf => 'the document "$title" as a PDF',
      ShareFormat.images =>
        pageCount == 1
            ? 'one page of "$title" as an image'
            : '$pageCount pages of "$title" as images',
    };

    return switch (action) {
      ShareAction.share => 'Share $what',
      ShareAction.print => 'Print $what',
      ShareAction.export => 'Export $what to device storage',
    };
  }

  /// The confirmation shown after a successful export to [destination].
  static String exportConfirmation(String destination) =>
      'Exported to $destination';

  /// The progress label shown while [total] pages are prepared.
  static String preparingLabel(int completed, int total) =>
      total <= 1 ? 'Preparing…' : 'Preparing page $completed of $total…';
}
