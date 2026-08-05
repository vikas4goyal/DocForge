/// Deterministic layout policy for the adaptive library content grid.
library;

import 'dart:math' as math;

/// Computes stable library-grid geometry from width and text scale only.
abstract final class LibraryGridLayout {
  /// Horizontal content inset around the grid.
  static const horizontalPadding = 16.0;

  /// Gap between neighboring cards in both axes.
  static const spacing = 16.0;

  /// Minimum readable card width used at wide breakpoints.
  static const minimumWideTileWidth = 176.0;

  /// Width where a phone-style two-column grid becomes adaptive.
  static const wideBreakpoint = 600.0;

  /// Large-text threshold that can require the accessibility fallback.
  static const accessibilityTextScale = 2.0;

  /// Compact width below which two large-text cards cannot remain readable.
  static const accessibilitySingleColumnWidth = 480.0;

  /// Stable card height containing preview, two title lines, and metadata.
  static const tileExtent = 286.0;

  /// Returns the number of columns for [availableWidth] and [textScale].
  static int columnsFor({
    required double availableWidth,
    required double textScale,
  }) {
    if (textScale >= accessibilityTextScale &&
        availableWidth < accessibilitySingleColumnWidth) {
      return 1;
    }
    if (availableWidth < wideBreakpoint) return 2;
    final contentWidth = availableWidth - horizontalPadding * 2;
    return math.max(
      3,
      ((contentWidth + spacing) / (minimumWideTileWidth + spacing)).floor(),
    );
  }
}
