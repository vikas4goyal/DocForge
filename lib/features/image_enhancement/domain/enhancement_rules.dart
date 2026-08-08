/// The business rules governing enhancement settings.
///
/// Every rule here is a pure function of its arguments, so the Cubit that
/// drives the enhancement screen holds no logic of its own — it emits, awaits a
/// use case, and emits again.
library;

import 'package:doc_scanly/core/contracts/models/page.dart';

/// Rules for building and combining [EnhancementSettings].
abstract final class EnhancementRules {
  /// The lowest value a brightness or contrast adjustment may take.
  static const minAdjustment = -1.0;

  /// The highest value a brightness or contrast adjustment may take.
  static const maxAdjustment = 1.0;

  /// The longest edge, in pixels, of the image the preview is computed from.
  ///
  /// The preview exists to be judged, not to be saved: at this size the result
  /// of every filter is clearly visible on any phone screen, while the pixel
  /// count is roughly a twentieth of a modern capture. That ratio is what keeps
  /// dragging a slider interactive, and the saved page is always recomputed at
  /// full resolution so nothing is lost by previewing small.
  static const previewMaxDimension = 1080;

  /// Converts a measured preview view to its physical-pixel longest edge.
  ///
  /// [logicalLongestEdge] is the preview panel's longest logical edge and
  /// [devicePixelRatio] converts it to physical screen pixels. The result is
  /// rounded upward only; it is deliberately not quantised into fixed buckets.
  static int previewDimensionFor({
    required double logicalLongestEdge,
    required double devicePixelRatio,
  }) {
    if (!logicalLongestEdge.isFinite ||
        !devicePixelRatio.isFinite ||
        logicalLongestEdge <= 0 ||
        devicePixelRatio <= 0) {
      return previewMaxDimension;
    }

    return (logicalLongestEdge * devicePixelRatio).ceil();
  }

  /// Returns [settings] with every adjustment forced into its valid range.
  ///
  /// Applied on the way in rather than trusted from the caller, so a slider
  /// that overshoots by a rounding error cannot reach the maths and produce a
  /// value the filters were never designed for.
  static EnhancementSettings clamp(EnhancementSettings settings) =>
      settings.copyWith(
        brightness: settings.brightness.clamp(minAdjustment, maxAdjustment),
        contrast: settings.contrast.clamp(minAdjustment, maxAdjustment),
        sharpen: settings.sharpen.clamp(0.0, maxAdjustment),
      );

  /// Whether [settings] would change the image at all.
  ///
  /// A page whose settings change nothing is copied rather than re-encoded,
  /// which avoids a needless generation of JPEG loss on every page the user
  /// looked at but chose not to enhance.
  static bool requiresProcessing(EnhancementSettings settings) =>
      !clamp(settings).isIdentity;

  /// Returns [pages] with [settings] applied to every one of them.
  ///
  /// The "apply to all" action. Returns a new list rather than mutating, so the
  /// previous settings survive in the caller's state and the action stays
  /// undoable.
  static List<PageRef> applyToAll(
    List<PageRef> pages,
    EnhancementSettings settings,
  ) {
    final clamped = clamp(settings);
    return [for (final page in pages) page.copyWith(enhancement: clamped)];
  }

  /// Returns [pages] with [settings] applied only at [index].
  ///
  /// Enhancing one page of a multi-page session must leave the others on their
  /// own settings, which the spec requires explicitly.
  static List<PageRef> applyToPage(
    List<PageRef> pages,
    int index,
    EnhancementSettings settings,
  ) {
    if (index < 0 || index >= pages.length) return pages;

    final updated = [...pages];
    updated[index] = pages[index].copyWith(enhancement: clamp(settings));
    return updated;
  }
}

/// One page's enhancement work, as it crosses into a background isolate.
///
/// Carries paths and a small value object only — never a decoded image. A
/// full-resolution bitmap sent to an isolate is copied, and a fifty-page batch
/// would exhaust memory on a low-end device long before it finished
/// (`design.md` §7).
class EnhancementRequest {
  /// Creates a request to enhance [sourcePath] into [destinationPath].
  const EnhancementRequest({
    required this.sourcePath,
    required this.destinationPath,
    required this.settings,
    this.maxDimension,
  });

  /// Creates a request for the interactive preview.
  ///
  /// Downscales to [EnhancementRules.previewMaxDimension] so the result arrives
  /// fast enough to keep slider dragging responsive.
  const EnhancementRequest.preview({
    required String sourcePath,
    required String destinationPath,
    required EnhancementSettings settings,
  }) : this(
         sourcePath: sourcePath,
         destinationPath: destinationPath,
         settings: settings,
         maxDimension: EnhancementRules.previewMaxDimension,
       );

  /// The image to read.
  final String sourcePath;

  /// Where the enhanced image is written.
  final String destinationPath;

  /// What to apply.
  final EnhancementSettings settings;

  /// The longest edge to downscale to, or null to work at full resolution.
  final int? maxDimension;

  /// Whether this request is for a downscaled preview.
  bool get isPreview => maxDimension != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancementRequest &&
          other.sourcePath == sourcePath &&
          other.destinationPath == destinationPath &&
          other.settings == settings &&
          other.maxDimension == maxDimension;

  @override
  int get hashCode =>
      Object.hash(sourcePath, destinationPath, settings, maxDimension);

  @override
  String toString() =>
      'EnhancementRequest($sourcePath -> $destinationPath, $settings)';
}
