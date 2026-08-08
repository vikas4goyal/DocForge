/// Percentage-based PDF raster quality shared by generation and editing.
///
/// The percentage describes output dimensions, not an expected byte saving.
/// Keeping this vocabulary in core lets Settings, PDF generation, and PDF
/// editing share it without importing one another.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_quality.freezed.dart';
part 'pdf_quality.g.dart';

/// A validated PDF raster-dimension percentage from 30 through 100.
///
/// Scaling applies the percentage independently to width and height, rounds to
/// the nearest pixel, clamps a positive source to at least one pixel, and never
/// enlarges it. The value deliberately makes no promise about encoded bytes.
@freezed
@JsonSerializable()
class PdfQualityPercent with _$PdfQualityPercent {
  /// Creates a validated quality percentage.
  PdfQualityPercent({required int value}) : value = _validate(value);

  /// Creates a quality percentage from JSON.
  factory PdfQualityPercent.fromJson(Map<String, dynamic> json) =>
      _$PdfQualityPercentFromJson(json);

  /// The validated integer percentage.
  @override
  final int value;

  /// Converts this percentage to generated JSON.
  Map<String, dynamic> toJson() => _$PdfQualityPercentToJson(this);

  /// The lowest supported quality percentage.
  static const minimum = 30;

  /// The highest supported quality percentage.
  static const maximum = 100;

  /// The default used when no valid persisted preference exists.
  static final defaultValue = PdfQualityPercent(value: 70);

  /// Scales one positive source dimension according to this percentage.
  ///
  /// A non-positive source is invalid because it cannot describe raster data.
  int scaleDimension(int originalDimension) {
    if (originalDimension <= 0) {
      throw RangeError.value(
        originalDimension,
        'originalDimension',
        'must be positive',
      );
    }
    final scaled = (originalDimension * value / 100).round();
    return scaled.clamp(1, originalDimension);
  }

  static int _validate(int value) {
    if (value < minimum || value > maximum) {
      throw RangeError.range(value, minimum, maximum, 'value');
    }
    return value;
  }
}

/// An immutable document quality plus explicit page-quality exceptions.
///
/// Page keys are stable identities supplied by the caller: creation uses a
/// page id, while editing uses the zero-based page index encoded as text. This
/// wire-safe representation allows one generated JSON contract to serve both
/// workflows without depending on either feature's domain types.
@freezed
abstract class PageQualityPlan with _$PageQualityPlan {
  /// Creates a plan with [documentQuality] as the value for every page that has
  /// no entry in [pageOverrides].
  const factory PageQualityPlan({
    required PdfQualityPercent documentQuality,
    @Default(<String, PdfQualityPercent>{})
    Map<String, PdfQualityPercent> pageOverrides,
  }) = _PageQualityPlan;

  /// Creates a page-quality plan from JSON.
  factory PageQualityPlan.fromJson(Map<String, dynamic> json) =>
      _$PageQualityPlanFromJson(json);

  const PageQualityPlan._();

  /// Returns the explicit page override, or [documentQuality] when absent.
  PdfQualityPercent effectiveFor(String pageKey) =>
      pageOverrides[pageKey] ?? documentQuality;

  /// Returns a plan with [quality] explicitly selected for [pageKey].
  PageQualityPlan withOverride(String pageKey, PdfQualityPercent quality) {
    _validatePageKey(pageKey);
    return copyWith(pageOverrides: {...pageOverrides, pageKey: quality});
  }

  /// Returns a plan in which [pageKey] follows [documentQuality].
  PageQualityPlan withoutOverride(String pageKey) {
    _validatePageKey(pageKey);
    if (!pageOverrides.containsKey(pageKey)) return this;
    final remaining = Map<String, PdfQualityPercent>.of(pageOverrides)
      ..remove(pageKey);
    return copyWith(pageOverrides: remaining);
  }

  /// Returns a plan with every page following [documentQuality].
  PageQualityPlan resetOverrides() => pageOverrides.isEmpty
      ? this
      : copyWith(pageOverrides: const <String, PdfQualityPercent>{});

  static void _validatePageKey(String pageKey) {
    if (pageKey.isEmpty) {
      throw ArgumentError.value(pageKey, 'pageKey', 'must not be empty');
    }
  }
}
