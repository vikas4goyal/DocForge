/// Page-level value objects shared across capabilities.
///
/// Scanning produces pages, enhancement transforms them, PDF generation
/// consumes them and the viewer displays them — so the page vocabulary lives in
/// `core/contracts/` rather than inside any one feature.
///
/// Note what a [DocumentPage] deliberately does not contain: image bytes. Only
/// a path. Full-resolution images stay on disk and are read by whichever
/// isolate needs them, which is what keeps a large batch scan from exhausting
/// memory on a low-end device (`design.md` §7).
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'page.freezed.dart';
part 'page.g.dart';

/// Clockwise rotation applied to a page when rendered.
enum PageRotation {
  /// No rotation.
  none(0),

  /// Quarter turn clockwise.
  quarter(90),

  /// Half turn.
  half(180),

  /// Three-quarter turn clockwise.
  threeQuarter(270);

  const PageRotation(this.degrees);

  /// Clockwise rotation in degrees.
  final int degrees;

  /// The rotation reached by turning one further quarter turn clockwise.
  PageRotation get rotatedClockwise => switch (this) {
    PageRotation.none => PageRotation.quarter,
    PageRotation.quarter => PageRotation.half,
    PageRotation.half => PageRotation.threeQuarter,
    PageRotation.threeQuarter => PageRotation.none,
  };
}

/// The enhancement filter applied to a page.
enum EnhancementFilter {
  /// The page exactly as captured.
  original,

  /// Automatic contrast and white-balance correction.
  autoEnhance,

  /// Saturated colour profile tuned for printed documents.
  magicColour,

  /// High-contrast two-tone output.
  blackAndWhite,

  /// Desaturated output retaining tonal detail.
  grayscale,
}

/// A normalised point in page space, where each axis runs from 0.0 to 1.0.
///
/// Normalised rather than pixel coordinates so a crop selected on a downscaled
/// preview applies unchanged to the full-resolution image.
@freezed
abstract class NormalisedPoint with _$NormalisedPoint {
  /// Creates a point at [x], [y], each in the range 0.0 to 1.0.
  const factory NormalisedPoint({required double x, required double y}) =
      _NormalisedPoint;

  /// Creates a point from JSON.
  factory NormalisedPoint.fromJson(Map<String, dynamic> json) =>
      _$NormalisedPointFromJson(json);

  const NormalisedPoint._();

  /// Whether both axes lie within the valid 0.0–1.0 range.
  bool get isWithinBounds => x >= 0 && x <= 1 && y >= 0 && y <= 1;
}

/// The four corners of a detected or user-adjusted document edge.
///
/// Corners are stored in a fixed order so perspective correction knows which
/// corner maps to which output corner without having to infer it.
@freezed
abstract class PageQuad with _$PageQuad {
  /// Creates a quadrilateral from its four corners.
  const factory PageQuad({
    required NormalisedPoint topLeft,
    required NormalisedPoint topRight,
    required NormalisedPoint bottomRight,
    required NormalisedPoint bottomLeft,
  }) = _PageQuad;

  /// Creates a quadrilateral from JSON.
  factory PageQuad.fromJson(Map<String, dynamic> json) =>
      _$PageQuadFromJson(json);

  const PageQuad._();

  /// The quadrilateral covering the whole page.
  ///
  /// Used as the default when automatic edge detection finds nothing, which the
  /// scanning spec requires to keep the capture rather than reject it.
  static const full = PageQuad(
    topLeft: NormalisedPoint(x: 0, y: 0),
    topRight: NormalisedPoint(x: 1, y: 0),
    bottomRight: NormalisedPoint(x: 1, y: 1),
    bottomLeft: NormalisedPoint(x: 0, y: 1),
  );

  /// The corners in their canonical order.
  List<NormalisedPoint> get corners => [
    topLeft,
    topRight,
    bottomRight,
    bottomLeft,
  ];

  /// Whether every corner lies within the page.
  bool get isWithinBounds => corners.every((c) => c.isWithinBounds);

  /// Whether this quadrilateral covers the entire page.
  bool get isFullPage => this == full;
}

/// The enhancement settings applied to a page.
///
/// Adjustments are stored as offsets around zero so "no change" is the zero
/// value and a reset is simply the default instance.
@freezed
abstract class EnhancementSettings with _$EnhancementSettings {
  /// Creates enhancement settings.
  const factory EnhancementSettings({
    @Default(EnhancementFilter.original) EnhancementFilter filter,

    /// Brightness offset in the range -1.0 to 1.0, where 0.0 is unchanged.
    @Default(0.0) double brightness,

    /// Contrast offset in the range -1.0 to 1.0, where 0.0 is unchanged.
    @Default(0.0) double contrast,

    /// Sharpening amount in the range 0.0 to 1.0, where 0.0 is unchanged.
    @Default(0.0) double sharpen,

    /// Whether uneven shadowing is removed.
    @Default(false) bool shadowRemoval,
  }) = _EnhancementSettings;

  /// Creates enhancement settings from JSON.
  factory EnhancementSettings.fromJson(Map<String, dynamic> json) =>
      _$EnhancementSettingsFromJson(json);

  const EnhancementSettings._();

  /// Settings that leave the captured image untouched.
  static const none = EnhancementSettings();

  /// Whether these settings would change the image at all.
  ///
  /// Lets the enhancement pipeline skip work entirely for an untouched page.
  bool get isIdentity => this == none;
}

/// A single page of a stored document.
@freezed
abstract class DocumentPage with _$DocumentPage {
  /// Creates a page.
  const factory DocumentPage({
    required PageId id,
    required DocumentId documentId,

    /// Zero-based position of this page within its document.
    required int order,

    /// Path to the page image on disk, inside app-private storage.
    required String imagePath,
    @Default(PageRotation.none) PageRotation rotation,
    @Default(EnhancementSettings()) EnhancementSettings enhancement,

    /// Path to a cached display-resolution thumbnail, when one exists.
    String? thumbnailPath,
  }) = _DocumentPage;

  /// Creates a page from JSON.
  factory DocumentPage.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageFromJson(json);

  const DocumentPage._();

  /// Human-facing page number, counting from one.
  int get pageNumber => order + 1;
}

/// A lightweight reference to a page, for use across isolate boundaries.
///
/// Only a path and the transforms to apply — never decoded image data. This is
/// the type that crosses into a worker isolate (`design.md` §7).
@freezed
abstract class PageRef with _$PageRef {
  /// Creates a page reference.
  const factory PageRef({
    required PageId id,
    required String imagePath,
    @Default(PageRotation.none) PageRotation rotation,
    @Default(EnhancementSettings()) EnhancementSettings enhancement,
  }) = _PageRef;

  /// Creates a page reference from JSON.
  factory PageRef.fromJson(Map<String, dynamic> json) =>
      _$PageRefFromJson(json);

  const PageRef._();
}
