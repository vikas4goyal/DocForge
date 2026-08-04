/// Scaffolding shared by every `@Preview()` entry.
///
/// The framework's `@Preview` annotation already handles size, brightness, text
/// scale and theming, so this file deliberately does **not** re-implement them.
/// It supplies only the two things the annotation cannot: the project's themes,
/// and the Scaffold a bare widget needs in order to render.
///
/// Usage:
///
/// ```dart
/// @Preview(name: 'DocCard — default', theme: appPreviewTheme, wrapper: previewSurface)
/// Widget docCardDefault() => DocumentCard(document: sampleDocument);
/// ```
///
/// Pass `size: PreviewSize.tablet` and `brightness: Brightness.dark` on the
/// annotation for the form-factor and theme variants the specs require.
///
/// Nothing here reaches a repository, camera, OCR engine, network or database:
/// previews are fed by fixtures alone (`design.md` §15).
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Viewport sizes for the form-factor variants every screen must preview.
///
/// Fixed rather than device-derived so a preview renders identically on any
/// machine, and so the tablet variant genuinely crosses the expanded
/// breakpoint rather than merely being "a bit wider".
abstract final class PreviewSize {
  /// A typical phone viewport.
  static const phone = Size(390, 844);

  /// A typical tablet viewport, wide enough to trigger the expanded layout.
  static const tablet = Size(1024, 768);
}

/// The project's light and dark themes, for a preview's `theme:` argument.
///
/// Without this a preview renders in Flutter's default theme, which would make
/// it a poor guide to how the widget actually looks in the app.
PreviewThemeData appPreviewTheme() => PreviewThemeData(
  materialLight: AppTheme.light,
  materialDark: AppTheme.dark,
);

/// Wraps a reusable widget in a Scaffold with comfortable insets.
///
/// For a widget that is not itself a full page. Pass as `wrapper:`.
Widget previewSurface(Widget child) => Scaffold(
  body: SafeArea(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

/// Wraps a widget in a bare Scaffold with no insets.
///
/// For full screens, which supply their own Scaffold and padding. Pass as
/// `wrapper:`.
Widget previewScreen(Widget child) => child;

/// Wraps a widget in a centred, width-constrained Scaffold.
///
/// For list rows and cards, which look misleading stretched across a tablet
/// preview at full width.
Widget previewNarrow(Widget child) => Scaffold(
  body: SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);
