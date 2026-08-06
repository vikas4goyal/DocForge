/// Runs reconciliation when the application comes back to the foreground.
///
/// The library folder is the user's: they can add, rename and delete files in
/// it from their file browser, and the most common way that happens is that
/// they leave DocScanly to do it. Reconciling on resume is what makes the change
/// appear when they come back, rather than on the next cold start
/// (`design.md` D5).
///
/// A widget rather than a listener wired up in `main`, so it participates in
/// the tree's lifecycle: it stops observing when it is disposed, and a test can
/// pump it without standing up an application.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// What to run when the application resumes.
typedef ReconcileRequest = Future<void> Function();

/// Reconciles the library on launch and on every resume.
class LibraryReconciler extends StatefulWidget {
  /// Wraps [child], reconciling through [reconcile].
  const LibraryReconciler({
    required this.reconcile,
    required this.child,
    super.key,
    this.onReconciled,
    this.externalTriggers,
  });

  /// Runs a reconcile pass. Throttling is the use case's concern, not this
  /// widget's: resume fires often, and deciding how often to act on it is a
  /// rule that belongs where it can be tested without a lifecycle.
  final ReconcileRequest reconcile;

  /// Called after each pass, so a list can reload when something changed.
  final VoidCallback? onReconciled;

  /// Additional platform events that require reconciliation, such as an
  /// iCloud identity change. Android composition leaves this null.
  final Stream<void>? externalTriggers;

  /// The application beneath.
  final Widget child;

  @override
  State<LibraryReconciler> createState() => _LibraryReconcilerState();
}

class _LibraryReconcilerState extends State<LibraryReconciler>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _externalSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After the first frame rather than during initState: reconciliation
    // writes to the index, and a rebuild triggered mid-build would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    _subscribeToExternalTriggers();
  }

  @override
  void didUpdateWidget(covariant LibraryReconciler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.externalTriggers, widget.externalTriggers)) {
      unawaited(_externalSubscription?.cancel());
      _subscribeToExternalTriggers();
    }
  }

  @override
  void dispose() {
    unawaited(_externalSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _subscribeToExternalTriggers() {
    _externalSubscription = widget.externalTriggers?.listen((_) => _run());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run();
  }

  Future<void> _run() async {
    await widget.reconcile();
    if (!mounted) return;
    widget.onReconciled?.call();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
