/// Widget keys for the app shell.
///
/// The values are normative — they come from `specs/app-shell/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the tab scaffold that wraps every screen.
abstract final class ShellKeys {
  /// Root of the tab scaffold.
  static const tabScaffold = Key('app_tab_scaffold');

  /// The dashboard destination.
  static const dashboardTab = Key('app_tab_dashboard');

  /// The create-PDF control, in the middle.
  static const createTab = Key('app_tab_create');

  /// The settings destination.
  static const settingsTab = Key('app_tab_settings');
}

/// Semantics labels for the app shell.
///
/// Declared beside [ShellKeys] so a label an accessibility test or an
/// end-to-end flow asserts on has one definition. An inline literal is a
/// contract nothing can check: it can be reworded without anything failing
/// until a flow stops finding it.
abstract final class ShellSemantics {
  /// The dashboard destination.
  static const dashboardTab = 'Dashboard, tab';

  /// The settings destination.
  static const settingsTab = 'Settings, tab';

  /// The control that starts a new document.
  static const createButton = 'Create PDF';
}
