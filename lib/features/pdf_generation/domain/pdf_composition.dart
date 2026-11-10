/// The value objects and rules behind PDF composition.
///
/// Pure Dart: no `pdf` package, no filesystem, no Flutter. Composition itself
/// lives in `infrastructure/`, which is what lets the rules that decide *what*
/// goes into a document — naming, quality, text-layer placement — be tested
/// without producing a PDF and reading it back.
library;

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/contracts/models/settings_values.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';

// Re-exported so every existing consumer of composition keeps one import. The
// types themselves moved to core/contracts because settings configures them and
// a feature may not import another feature (`design.md` §2).
export 'package:doc_scanly/core/contracts/models/settings_values.dart'
    show DocumentNaming, NamingPattern, PdfQuality;

/// One page as it will be composed into a PDF.
///
/// Carries a path and the transforms to apply — never decoded image data. This
/// is what crosses into the composition isolate (`design.md` §7).
class PdfPageSpec {
  /// Creates a specification for one page.
  const PdfPageSpec({required this.imagePath, required this.rotation});

  /// The image to draw, already enhanced.
  final String imagePath;

  /// Rotation to apply when the page is drawn.
  final PageRotation rotation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPageSpec &&
          other.imagePath == imagePath &&
          other.rotation == rotation;

  @override
  int get hashCode => Object.hash(imagePath, rotation);

  @override
  String toString() => 'PdfPageSpec($imagePath, $rotation)';
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

/// One generated-candidate page and its effective quality percentage.
class GeneratedPdfCandidatePage {
  /// Creates a candidate page specification.
  const GeneratedPdfCandidatePage({
    required this.stableId,
    required this.page,
    required this.quality,
  });

  /// Stable page identity used by quality overrides and fingerprints.
  final String stableId;

  /// Prepared page image and orientation.
  final PdfPageSpec page;

  /// Effective document-or-page quality for this page.
  final PdfQualityPercent quality;
}

/// Every input needed to build one exact generated-PDF candidate.
class GeneratedPdfCandidateRequest {
  /// Creates a validated candidate request.
  ///
  /// [password] is deliberately transient and is never serialized or included
  /// in value equality. The fingerprint records only whether protection is
  /// enabled, while the route-scoped secret boundary owns the actual text.
  GeneratedPdfCandidateRequest({
    required List<GeneratedPdfCandidatePage> pages,
    required this.fingerprint,
    this.password,
  }) : pages = List<GeneratedPdfCandidatePage>.unmodifiable(pages) {
    if (pages.isEmpty) {
      throw ArgumentError.value(pages, 'pages', 'must not be empty');
    }
    final qualities = <int>[for (final page in pages) page.quality.value];
    if (!_sameQualities(qualities, fingerprint.orderedPageQualities)) {
      throw ArgumentError.value(
        fingerprint,
        'fingerprint',
        'ordered qualities must describe every candidate page',
      );
    }
    if (fingerprint.isProtected != (password != null)) {
      throw ArgumentError.value(
        fingerprint,
        'fingerprint',
        'protection flag must match password presence',
      );
    }
  }

  /// Pages in final PDF order.
  final List<GeneratedPdfCandidatePage> pages;

  /// Stable identity of all non-secret output-affecting inputs.
  final PdfCandidateFingerprint fingerprint;

  /// Transient protection secret, or `null` for an unprotected PDF.
  final String? password;

  static bool _sameQualities(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}

/// Rules for assembling a build request from a session.
abstract final class PdfComposition {
  /// Builds the page specifications for [pages], in order.
  static List<PdfPageSpec> specsFor(List<PageRef> pages) => [
    for (final page in pages)
      PdfPageSpec(imagePath: page.imagePath, rotation: page.rotation),
  ];
}
