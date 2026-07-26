/// Material 3 light and dark themes for DocForge.
///
/// Dark mode is mandatory, not optional, and every screen must meet WCAG AA
/// contrast in both themes while remaining usable at the maximum system text
/// scale. Centralising the themes here means those guarantees are made once
/// rather than re-derived per screen, and the golden tests exercise both.
library;

import 'package:flutter/material.dart';

/// Builds the application's themes.
///
/// Stateless and deterministic: the same inputs always produce the same
/// [ThemeData], which is what keeps golden tests byte-stable.
abstract final class AppTheme {
  /// Seed colour the Material 3 palettes are generated from.
  ///
  /// A deep indigo: it yields a usable tonal range in both light and dark, and
  /// stays legible behind the page thumbnails that dominate most screens.
  static const seedColour = Color(0xFF3F51B5);

  /// Minimum interactive target size, in logical pixels.
  ///
  /// The accessibility requirements mandate at least 48dp on both axes for
  /// every control; applying it through the theme means individual widgets
  /// cannot silently fall below it.
  static const minimumTouchTarget = 48.0;

  /// The light theme.
  static ThemeData get light => _build(Brightness.light);

  /// The dark theme.
  static ThemeData get dark => _build(Brightness.dark);

  /// Builds a theme for [brightness].
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColour,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      // Material 3 is required by the project context; Cupertino affordances
      // are applied per-widget where platform-appropriate rather than by
      // swapping the whole theme.
      useMaterial3: true,
      visualDensity: VisualDensity.standard,

      // Enforces the 48dp floor for every Material tap target rather than
      // relying on each widget to remember.
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minimumTouchTarget, minimumTouchTarget),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        // Keeps a row tappable at the required size even when its text is
        // short enough to render smaller.
        minTileHeight: minimumTouchTarget,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Layout breakpoints used to adapt screens across form factors.
///
/// Every screen must adapt to phone and tablet in both orientations without
/// clipping or horizontal overflow, so the thresholds are defined once here
/// rather than as magic numbers scattered through the widget tree.
abstract final class Breakpoints {
  /// Width below which the compact, single-column phone layout applies.
  static const compact = 600.0;

  /// Width at or above which the expanded tablet layout applies.
  static const expanded = 840.0;

  /// Whether [width] should use the compact phone layout.
  static bool isCompact(double width) => width < compact;

  /// Whether [width] should use the expanded tablet layout.
  static bool isExpanded(double width) => width >= expanded;

  /// Number of grid columns appropriate for [width].
  ///
  /// Used by document and folder grids so a tablet uses its extra width rather
  /// than stretching phone-width rows across it.
  static int gridColumnsFor(double width) {
    if (width >= expanded) return 3;
    if (width >= compact) return 2;
    return 1;
  }
}
