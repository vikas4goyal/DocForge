/// Deterministic layout policy for the adaptive library content grid.
library;

import 'dart:math' as math;

import 'package:doc_scanly/features/document_library/domain/library_display_density.dart';

/// Computes stable library-grid geometry from width and text scale only.
abstract final class LibraryGridLayout {
  /// Horizontal content inset around the grid.
  static const horizontalPadding = 16.0;

  /// Gap between neighboring cards in both axes.
  static const spacing = 16.0;

  /// Minimum readable card width used at wide breakpoints.
  static const minimumWideTileWidth = 176.0;

  /// Minimum readable Small card width at wide breakpoints.
  static const minimumSmallTileWidth = 112.0;

  /// Width where a phone-style two-column grid becomes adaptive.
  static const wideBreakpoint = 600.0;

  /// Large-text threshold that can require the accessibility fallback.
  static const accessibilityTextScale = 2.0;

  /// Compact width below which two large-text cards cannot remain readable.
  static const accessibilitySingleColumnWidth = 480.0;

  /// Stable card height containing preview, two title lines, and metadata.
  static const tileExtent = 286.0;

  /// Stable Small card height with a shorter preview and compact metadata.
  static const smallTileExtent = 218.0;

  /// Returns the number of columns for [availableWidth] and [textScale].
  static int columnsFor({
    required double availableWidth,
    required double textScale,
    LibraryDisplayDensity density = LibraryDisplayDensity.large,
  }) {
    if (textScale >= accessibilityTextScale &&
        availableWidth < accessibilitySingleColumnWidth) {
      return 1;
    }
    if (availableWidth < wideBreakpoint) {
      return density == LibraryDisplayDensity.small ? 3 : 2;
    }
    final contentWidth = availableWidth - horizontalPadding * 2;
    final minimumWidth = density == LibraryDisplayDensity.small
        ? minimumSmallTileWidth
        : minimumWideTileWidth;
    return math.max(
      density == LibraryDisplayDensity.small ? 4 : 3,
      ((contentWidth + spacing) / (minimumWidth + spacing)).floor(),
    );
  }

  /// Returns the stable tile height for [density].
  static double tileExtentFor(LibraryDisplayDensity density) =>
      density == LibraryDisplayDensity.small ? smallTileExtent : tileExtent;
}
