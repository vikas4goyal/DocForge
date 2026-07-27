/// The value objects and rules behind PDF composition.
///
/// Pure Dart: no `pdf` package, no filesystem, no Flutter. Composition itself
/// lives in `infrastructure/`, which is what lets the rules that decide *what*
/// goes into a document — naming, quality, text-layer placement — be tested
/// without producing a PDF and reading it back.
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';

/// How much fidelity a generated PDF keeps.
///
/// A single setting rather than separate resolution and compression knobs: the
/// two only make sense together, and offering both invites combinations that
/// are strictly worse than one of the presets.
enum PdfQuality {
  /// Smallest file. Readable, but visibly soft on fine print.
  low(imageQuality: 55, maxDimension: 1240, label: 'Small file'),

  /// The default. Indistinguishable from the capture at reading distance.
  balanced(imageQuality: 80, maxDimension: 2000, label: 'Balanced'),

  /// Largest file. Preserves detail for reprinting or archiving.
  high(imageQuality: 95, maxDimension: 3500, label: 'Best quality');

  const PdfQuality({
    required this.imageQuality,
    required this.maxDimension,
    required this.label,
  });

  /// JPEG quality each page image is encoded at.
  final int imageQuality;

  /// Longest edge, in pixels, a page image is scaled to.
  ///
  /// Bounded even at the highest setting: a modern camera produces more pixels
  /// than any printer resolves from a sheet of paper, and carrying them makes a
  /// fifty-page scan unshareable.
  final int maxDimension;

  /// The name shown in settings.
  final String label;

  /// The quality used when the user has chosen nothing.
  static const defaultQuality = PdfQuality.balanced;

  /// The quality named [name], or the default when none matches.
  ///
  /// Falls back rather than throwing so a settings value written by an older
  /// release degrades to a working default instead of an error.
  static PdfQuality fromName(String? name) => values.firstWhere(
    (quality) => quality.name == name,
    orElse: () => defaultQuality,
  );
}

/// A pattern for naming a new document.
enum NamingPattern {
  /// `Scan 2026-03-14 09.30`.
  dateAndTime('dateAndTime', 'Date and time'),

  /// `Scan 2026-03-14`.
  dateOnly('dateOnly', 'Date only'),

  /// `Scan 1`, `Scan 2`, … counting from the documents already stored.
  sequential('sequential', 'Sequential number'),

  /// `Document` every time, leaving the user to rename.
  plain('plain', 'Just "Document"');

  const NamingPattern(this.id, this.label);

  /// Stable identifier written to settings.
  ///
  /// Separate from [name] so renaming the enum constant does not silently
  /// invalidate every user's stored preference.
  final String id;

  /// The name shown in settings.
  final String label;

  /// The pattern used when the user has chosen nothing.
  static const defaultPattern = NamingPattern.dateAndTime;

  /// The pattern with [id], or the default when none matches.
  static NamingPattern fromId(String? id) => values.firstWhere(
    (pattern) => pattern.id == id,
    orElse: () => defaultPattern,
  );
}

/// Rules for naming a document.
abstract final class DocumentNaming {
  /// The prefix every generated name starts with.
  static const prefix = 'Scan';

  /// The name a document with no title falls back to.
  static const fallback = 'Document';

  /// Expands [pattern] for a document created at [now].
  ///
  /// [existingCount] is how many documents the library already holds, used only
  /// by [NamingPattern.sequential].
  ///
  /// [now] is passed in rather than read from a clock here because this is a
  /// pure function: the same inputs must always give the same name, which is
  /// what makes the expansion testable and every golden stable.
  ///
  /// The date is formatted manually rather than through `intl` because the
  /// result is a *file name*, not a display string. A locale-dependent name
  /// would sort differently on different devices and could contain a slash.
  static String expand(
    NamingPattern pattern, {
    required DateTime now,
    int existingCount = 0,
  }) {
    final local = now.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';

    return switch (pattern) {
      // Dots rather than colons between hours and minutes: a colon is illegal
      // in a file name on several platforms and confusing in a share sheet.
      NamingPattern.dateAndTime =>
        '$prefix $date '
            '${local.hour.toString().padLeft(2, '0')}.'
            '${local.minute.toString().padLeft(2, '0')}',
      NamingPattern.dateOnly => '$prefix $date',
      NamingPattern.sequential => '$prefix ${existingCount + 1}',
      NamingPattern.plain => fallback,
    };
  }

  /// Returns the title to store, given what the user typed.
  ///
  /// A blank field means "use the default", not "a document with no name": an
  /// untitled document is unfindable, and the library forbids an empty title.
  static String resolve(String? entered, String generated) {
    final trimmed = entered?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return generated.trim().isEmpty ? fallback : generated.trim();
  }

  /// Returns the file name for a document titled [title].
  ///
  /// Derived from the title so the file a user shares is recognisable, with
  /// characters a filesystem would reject replaced rather than dropped — two
  /// titles differing only in punctuation must not collide.
  static String fileNameFor(String title) {
    final safe = title
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final hasContent = RegExp('[a-zA-Z0-9]').hasMatch(safe);
    return '${hasContent ? safe : fallback}.pdf';
  }
}

/// One page as it will be composed into a PDF.
///
/// Carries a path and the transforms to apply — never decoded image data. This
/// is what crosses into the composition isolate (`design.md` §7).
class PdfPageSpec {
  /// Creates a specification for one page.
  const PdfPageSpec({
    required this.imagePath,
    required this.rotation,
    this.textBlocks = const [],
  });

  /// The image to draw, already enhanced.
  final String imagePath;

  /// Rotation to apply when the page is drawn.
  final PageRotation rotation;

  /// Recognised text to place invisibly over the image.
  ///
  /// Empty when the page has not been recognised, or when recognition found
  /// nothing. A page without a text layer is still a valid page — the spec
  /// requires the PDF to be produced either way.
  final List<TextBlock> textBlocks;

  /// Whether this page carries a searchable text layer.
  bool get hasTextLayer => textBlocks.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPageSpec &&
          other.imagePath == imagePath &&
          other.rotation == rotation &&
          _sameBlocks(other.textBlocks, textBlocks);

  @override
  int get hashCode => Object.hash(imagePath, rotation, textBlocks.length);

  static bool _sameBlocks(List<TextBlock> a, List<TextBlock> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'PdfPageSpec($imagePath, $rotation, ${textBlocks.length} blocks)';
}

/// Everything the composer needs to build one PDF.
class PdfBuildRequest {
  /// Creates a build request.
  const PdfBuildRequest({
    required this.pages,
    required this.destinationPath,
    this.quality = PdfQuality.defaultQuality,
  });

  /// The pages, in the order they will appear.
  final List<PdfPageSpec> pages;

  /// Where the finished PDF is written.
  final String destinationPath;

  /// How much fidelity to keep.
  final PdfQuality quality;

  /// Whether any page carries a text layer.
  bool get isSearchable => pages.any((page) => page.hasTextLayer);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfBuildRequest &&
          other.destinationPath == destinationPath &&
          other.quality == quality &&
          other.pages.length == pages.length;

  @override
  int get hashCode => Object.hash(destinationPath, quality, pages.length);
}

/// Rules for assembling a build request from a session.
abstract final class PdfComposition {
  /// Builds the page specifications for [pages], attaching any recognised text.
  ///
  /// A page with no recognition result, or one whose blocks are all
  /// unplaceable, simply gets no text layer. Recognition failure must never
  /// prevent a document being created — a PDF without a searchable layer is
  /// still a valid document, which the spec states outright.
  static List<PdfPageSpec> specsFor(
    List<PageRef> pages,
    Map<String, RecognisedText> textByPageId,
  ) => [
    for (final page in pages)
      PdfPageSpec(
        imagePath: page.imagePath,
        rotation: page.rotation,
        textBlocks: _placeable(textByPageId[page.id.value]),
      ),
  ];

  /// The blocks of [text] that can be positioned, or none.
  ///
  /// A block with an invalid or zero-area box is dropped rather than placed at
  /// a guess: a text-layer entry with no position lands somewhere arbitrary,
  /// and selecting text in a reader then highlights the wrong part of the page.
  static List<TextBlock> _placeable(RecognisedText? text) {
    if (text == null) return const [];

    return [
      for (final block in text.blocks)
        if (block.bounds.isValid && block.text.trim().isNotEmpty) block,
    ];
  }
}
