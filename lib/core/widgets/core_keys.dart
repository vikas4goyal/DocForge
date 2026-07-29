/// Widget keys for the shared state views and the router's own screens.
///
/// These belong to `core/` rather than to a feature because the widgets they
/// key are used by every feature. They are defaults: a feature that wants its
/// own key for a loading, empty or error control passes one from its own
/// registry, which is what lets a flow tell one feature's cancel control from
/// another's.
library;

import 'package:flutter/widgets.dart';

/// Keys used by widgets that no single feature owns.
abstract final class CoreKeys {
  /// The cancel control on a progress view, when the caller supplies no key.
  ///
  /// A default rather than the only option: every feature that can be cancelled
  /// shares this widget, so a single constant would give a flow one key
  /// matching five different controls.
  static const progressCancelButton = Key('app_progress_cancel_button');

  /// The call-to-action on an empty state, when the caller supplies no key.
  static const emptyStateActionButton = Key('app_empty_state_action_button');

  /// The recovery control on an error view, when the caller supplies no key.
  static const errorViewActionButton = Key('app_error_view_action_button');

  /// Root of the screen shown for a route that does not exist.
  static const routeNotFoundScreen = Key('route_not_found_screen');

  /// The message on the route-not-found screen.
  static const routeNotFoundState = Key('route_not_found_state');
}
