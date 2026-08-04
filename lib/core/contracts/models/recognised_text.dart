/// The OCR vocabulary shared between recognition, search, sharing and PDF
/// generation.
///
/// Bounding boxes are carried alongside the text because the searchable-PDF
/// requirement needs them: the invisible text layer has to sit over the region
/// of the page image the text was read from, or selection in a PDF reader lands
/// in the wrong place.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recognised_text.freezed.dart';
part 'recognised_text.g.dart';

/// A rectangle in normalised page space, each axis running from 0.0 to 1.0.
///
/// Normalised so the box stays valid whatever resolution the page is rendered
/// at — recognition may run on a downscaled copy while the PDF is composed at
/// full size.
@freezed
abstract class NormalisedRect with _$NormalisedRect {
  /// Creates a rectangle from its edges.
  const factory NormalisedRect({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) = _NormalisedRect;

  /// Creates a rectangle from JSON.
  factory NormalisedRect.fromJson(Map<String, dynamic> json) =>
      _$NormalisedRectFromJson(json);

  const NormalisedRect._();

  /// Width of the rectangle.
  double get width => right - left;

  /// Height of the rectangle.
  double get height => bottom - top;

  /// Whether the rectangle has a positive area and lies within the page.
  bool get isValid =>
      width > 0 &&
      height > 0 &&
      left >= 0 &&
      top >= 0 &&
      right <= 1 &&
      bottom <= 1;
}

/// A contiguous run of recognised text and where it sits on the page.
@freezed
abstract class TextBlock with _$TextBlock {
  /// Creates a recognised text block.
  const factory TextBlock({
    required String text,
    required NormalisedRect bounds,
  }) = _TextBlock;

  /// Creates a text block from JSON.
  factory TextBlock.fromJson(Map<String, dynamic> json) =>
      _$TextBlockFromJson(json);

  const TextBlock._();
}

/// The full recognition result for one page.
@freezed
abstract class RecognisedText with _$RecognisedText {
  /// Creates a recognition result.
  const factory RecognisedText({
    required PageId pageId,
    @Default(<TextBlock>[]) List<TextBlock> blocks,

    /// BCP-47 tag of the language recognition ran with.
    required String languageTag,

    /// When recognition ran, so a re-run can be distinguished from a cached
    /// result.
    required DateTime recognisedAt,
  }) = _RecognisedText;

  /// Creates a recognition result from JSON.
  factory RecognisedText.fromJson(Map<String, dynamic> json) =>
      _$RecognisedTextFromJson(json);

  const RecognisedText._();

  /// An empty result for [pageId], recognised at [recognisedAt].
  ///
  /// A page with no legible text is a valid outcome, not a failure, so this is
  /// stored rather than treated as an error.
  factory RecognisedText.empty({
    required PageId pageId,
    required String languageTag,
    required DateTime recognisedAt,
  }) => RecognisedText(
    pageId: pageId,
    languageTag: languageTag,
    recognisedAt: recognisedAt,
  );

  /// Whether recognition found nothing.
  bool get isEmpty => blocks.isEmpty;

  /// All recognised text joined into a single readable string.
  ///
  /// This is what the extracted-text view shows and what copy and export use.
  String get plainText => blocks.map((b) => b.text).join('\n');
}
