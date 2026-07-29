/// Telling Home that something above it has gone away.
///
/// Home is built once and kept alive: the tab shell holds both destinations in
/// an IndexedStack so switching away and back returns the user to the folder
/// they were in, and GoRouter reuses the page rather than rebuilding it. That is
/// the behaviour the design asks for, and its cost is that nothing reloads the
/// dashboard when a route pushed over it goes away.
///
/// Which meant every path that added a document from somewhere other than the
/// dashboard itself — saving a scan, reviewing imported pages — wrote the
/// document to disk and left the user looking at a library that still said
/// "Nothing here yet". Each of those paths could have been patched
/// individually; this fixes the shape of the problem instead, so the next one
/// added does not have to remember.
///
/// A pop is not enough to observe. The creation flow leaves with `go`, which
/// *removes* the route rather than popping it — deliberately, so the flow can be
/// entered from several places without Back returning to whichever one it
/// happened to be. So both are watched.
library;

import 'package:flutter/material.dart';

/// Notifies its listeners whenever a route is popped or removed.
///
/// Installed on the router as an observer and handed to Home, which reloads on
/// every notification. Reloading slightly more often than strictly necessary is
/// deliberate: the query is local and cheap, and the alternative — deciding
/// which removals matter — is the kind of cleverness that goes quietly wrong the
/// next time a route is added.
class HomeRefreshObserver extends NavigatorObserver with ChangeNotifier {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    notifyListeners();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    notifyListeners();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    notifyListeners();
  }
}

/// Calls [onRefresh] whenever [observer] reports a route going away.
///
/// Wrap a screen that lists something the rest of the application can add to.
/// Deliberately does *not* fire on first build: the screen it wraps loads itself
/// when it is created, and doing it here as well would run every query twice on
/// launch.
class HomeRefreshListener extends StatefulWidget {
  /// Creates a listener around [child].
  const HomeRefreshListener({
    required this.observer,
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// The observer the router publishes route changes through.
  final HomeRefreshObserver observer;

  /// Called when a route above this screen has gone away.
  final VoidCallback onRefresh;

  /// The screen being kept current.
  final Widget child;

  @override
  State<HomeRefreshListener> createState() => _HomeRefreshListenerState();
}

class _HomeRefreshListenerState extends State<HomeRefreshListener> {
  @override
  void initState() {
    super.initState();
    widget.observer.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.observer.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    // The notification can arrive while the route is still animating out, when
    // this screen is mounted but not yet the one on screen. Reloading then is
    // harmless — the result lands before the user sees anything.
    if (mounted) widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
