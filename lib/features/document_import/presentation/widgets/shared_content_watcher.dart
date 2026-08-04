/// Listens for content another application shared with DocScanly.
library;

import 'dart:async';

import 'package:doc_scanly/features/document_import/application/usecases/import_usecases.dart';
import 'package:flutter/widgets.dart';

/// Delivers shared content to [onContent], from both routes it can arrive by.
///
/// The two cases the spec names are genuinely different mechanisms, and this
/// widget is where they are made to look the same to everything above it:
///
/// * **Cold launch.** The payload is already waiting when the application
///   starts, and is read once — after the first frame, so whatever handles it
///   has a mounted tree to present into.
/// * **Already running.** The payload arrives on a stream while the application
///   is in the foreground, and must not restart anything.
///
/// Wrap a long-lived screen with this. Placing it inside a route that comes and
/// goes would drop a share that arrived while that route was off-screen.
class SharedContentWatcher extends StatefulWidget {
  /// Creates the watcher.
  const SharedContentWatcher({
    required this.takePending,
    required this.watchShared,
    required this.onContent,
    required this.child,
    super.key,
  });

  /// Reads content that was waiting when the application launched.
  final TakePendingSharedContent takePending;

  /// Watches for content shared while the application runs.
  final WatchSharedContent watchShared;

  /// Invoked with each set of shared paths.
  ///
  /// Never invoked with an empty list: an ordinary launch has nothing waiting,
  /// and calling back with nothing would open an import for no content.
  final ValueChanged<List<String>> onContent;

  /// The subtree below the watcher.
  final Widget child;

  @override
  State<SharedContentWatcher> createState() => _SharedContentWatcherState();
}

class _SharedContentWatcherState extends State<SharedContentWatcher> {
  StreamSubscription<List<String>>? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = widget.watchShared().listen(_deliver);

    // After the first frame: a cold-launch share is read before anything is on
    // screen, and presenting into a tree that has not been laid out yet is how
    // a launch-time navigation ends up thrown away.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = await widget.takePending();
      if (mounted) _deliver(pending);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }

  void _deliver(List<String> paths) {
    if (paths.isEmpty) return;
    widget.onContent(paths);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
