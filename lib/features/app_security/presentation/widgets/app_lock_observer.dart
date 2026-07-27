/// Bridges the lock gate into the widget layer.
library;

import 'dart:async';

import 'package:doc_forge/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:flutter/widgets.dart';

/// Notifies GoRouter when the lock state changes.
///
/// GoRouter re-evaluates its redirect only when told to. Without this the user
/// would authenticate successfully and then sit on the unlock screen, because
/// nothing would have asked the guard again.
class AppLockListenable extends ChangeNotifier {
  /// Creates a listenable over [gate].
  AppLockListenable(AppLockGateImpl gate) {
    _subscription = gate.lockChanges.listen((_) => notifyListeners());
  }

  StreamSubscription<bool>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}

/// Re-locks the application when it returns from the background.
///
/// The spec requires the unlock screen again on resume, which a launch-only
/// check would miss entirely — a backgrounded, unlocked session is exactly the
/// one someone else picks the phone up on.
///
/// Locks on **paused**, not on resumed: doing it as the app goes away means the
/// unlock screen is already in place before the first frame comes back, so
/// there is no window in which the previous screen is visible. It also means
/// the content is not in the app switcher's snapshot.
class AppLockObserver extends StatefulWidget {
  /// Creates the observer around [child].
  const AppLockObserver({required this.gate, required this.child, super.key});

  /// The gate to re-lock.
  final AppLockGateImpl gate;

  /// The subtree below the observer.
  final Widget child;

  @override
  State<AppLockObserver> createState() => _AppLockObserverState();
}

class _AppLockObserverState extends State<AppLockObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `paused` covers backgrounding on both platforms. `inactive` is not used:
    // it also fires for a notification shade pull or an incoming call banner,
    // and re-locking for those would make the app unusable.
    if (state == AppLifecycleState.paused) {
      unawaited(widget.gate.lock());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
