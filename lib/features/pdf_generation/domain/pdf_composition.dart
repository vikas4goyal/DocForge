/// The value objects and rules behind PDF composition.
///
/// Pure Dart: no `pdf` package, no filesystem, no Flutter. Composition itself
/// lives in `infrastructure/`, which is what lets the rules that decide *what*
/// goes into a document — naming, quality, text-layer placement — be tested
/// without producing a PDF and reading it back.
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/contracts/models/settings_values.dart';

// Re-exported so every existing consumer of composition keeps one import. The
// types themselves moved to core/contracts because settings configures them and
// a feature may not import another feature (`design.md` §2).
export 'package:doc_forge/core/contracts/models/settings_values.dart'
    show DocumentNaming, NamingPattern, PdfQuality;

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
