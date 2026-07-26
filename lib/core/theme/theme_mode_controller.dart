/// Holds the theme mode the whole application renders with.
library;

import 'package:flutter/material.dart';

/// The current theme mode, observable so a change re-renders the app.
///
/// A `ValueNotifier` rather than a plain field on the root widget because the
/// spec requires an explicit theme selection in settings to take effect without
/// a restart. Settings is several routes away from the root, and rebuilding the
/// root through the router is not something a leaf screen can do; publishing
/// the change here and listening at the root is.
///
/// This is the one mutable object above the router. It is still injected —
/// created in the composition root and passed down — so a test supplies its own
/// and no global is involved.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  /// Creates a controller starting at [initial].
  ///
  /// Defaults to following the system, which is the documented behaviour before
  /// the user has expressed a preference.
  ThemeModeController([super.initial = ThemeMode.system]);

  /// Applies [mode], notifying listeners when it actually changed.
  ///
  /// `ValueNotifier` already skips notifying on an identical value, so
  /// re-selecting the current theme costs nothing.
  void select(ThemeMode mode) => value = mode;
}
