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
