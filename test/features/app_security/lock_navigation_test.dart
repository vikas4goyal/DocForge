/// Navigation tests for the application lock.
///
/// The property under test is the one the spec states most strongly: with the
/// lock enabled, **no document title, thumbnail or content renders before
/// authentication succeeds** — on launch and on resume alike. It is asserted at
/// the router, because that is where it is actually enforced: every route is
/// redirected while the gate reports locked, so no screen has to remember to
/// check.
library;

import 'dart:async';

import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_forge/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for a screen that would show document content.
///
/// Every non-exempt route renders one of these, carrying a title no locked
/// launch may reveal.
Widget _documentContent(String label) => Scaffold(
  body: Column(
    children: [Text('Invoice 2026 — $label'), const Text('4 pages')],
  ),
);

AppScreens _screens() => AppScreens(
  onboarding: (_) => _documentContent('onboarding'),
  unlock: (_) => const Scaffold(body: Text('Locked')),
  home: (_) => _documentContent('home'),
  scan: (_) => _documentContent('scan'),
  documents: (_) => _documentContent('documents'),
  viewer: (_, _) => _documentContent('viewer'),
  documentDetail: (_, _) => _documentContent('detail'),
  documentEdit: (_, _) => _documentContent('edit'),
  folders: (_) => _documentContent('folders'),
  folderDetail: (_, _) => _documentContent('folder'),
  favourites: (_) => _documentContent('favourites'),
  archive: (_) => _documentContent('archive'),
  trash: (_) => _documentContent('trash'),
  search: (_) => _documentContent('search'),
  settings: (_) => _documentContent('settings'),
  about: (_) => _documentContent('about'),
  privacy: (_) => _documentContent('privacy'),
);

void main() {
  Future<AppLockGateImpl> pumpAt(
    WidgetTester tester,
    String location, {
    bool lockEnabled = true,
    bool onboardingComplete = true,
  }) async {
    final configuration = InMemoryAppLockConfiguration(enabled: lockEnabled);
    final gate = AppLockGateImpl(IsAppLockEnabled(configuration));
    addTearDown(gate.dispose);

    // Loaded before the router is built, exactly as `main` does it: the router
    // must never have to guess.
    await gate.load();

    final router = createAppRouter(
      guard: RouteGuard(
        lockGate: gate,
        onboardingGate: FakeOnboardingGate(
          needsOnboarding: !onboardingComplete,
        ),
      ),
      screens: _screens(),
      initialLocation: location,
      // Without this, unlocking would leave the user sitting on the unlock
      // screen with no redirect re-evaluation.
      refreshListenable: _GateListenable(gate),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    return gate;
  }

  group('a locked launch', () {
    testWidgets('shows the unlock screen instead of Home', (tester) async {
      await pumpAt(tester, AppRoutes.home);

      expect(find.text('Locked'), findsOneWidget);
      expect(find.textContaining('Invoice 2026'), findsNothing);
    });

    testWidgets('reveals nothing from any deep link', (tester) async {
      // A shared link, a notification tap or a restored route must not be a way
      // round the lock.
      for (final location in [
        AppRoutes.home,
        AppRoutes.documents,
        AppRoutes.favourites,
        AppRoutes.archive,
        AppRoutes.folders,
        AppRoutes.search,
        AppRoutes.settings,
        AppRoutes.scan,
      ]) {
        await pumpAt(tester, location);

        expect(
          find.textContaining('Invoice 2026'),
          findsNothing,
          reason: '$location leaked document content behind the lock',
        );
        expect(find.text('Locked'), findsOneWidget);
      }
    });

    testWidgets('takes precedence over onboarding', (tester) async {
      // Lock first, unconditionally: onboarding is a screen, and a screen shown
      // behind an enabled lock is still a screen shown behind an enabled lock.
      await pumpAt(tester, AppRoutes.home, onboardingComplete: false);

      expect(find.text('Locked'), findsOneWidget);
    });
  });

  group('after authenticating', () {
    testWidgets('the destination appears', (tester) async {
      final gate = await pumpAt(tester, AppRoutes.documents);

      expect(find.text('Locked'), findsOneWidget);

      gate.markUnlocked();
      await tester.pumpAndSettle();

      expect(find.textContaining('Invoice 2026'), findsOneWidget);
    });

    testWidgets('the unlock screen is no longer reachable', (tester) async {
      final gate = await pumpAt(tester, AppRoutes.home);

      gate.markUnlocked();
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsNothing);
    });
  });

  group('returning from the background', () {
    testWidgets('content is hidden again before anything is shown', (
      tester,
    ) async {
      // A launch-only check would let a backgrounded, unlocked session be
      // resumed by whoever picks the phone up.
      final gate = await pumpAt(tester, AppRoutes.documents);

      gate.markUnlocked();
      await tester.pumpAndSettle();
      expect(find.textContaining('Invoice 2026'), findsOneWidget);

      await gate.lock();
      await tester.pumpAndSettle();

      expect(find.textContaining('Invoice 2026'), findsNothing);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('a disabled lock does not re-lock on resume', (tester) async {
      final gate = await pumpAt(tester, AppRoutes.home, lockEnabled: false);

      await gate.lock();
      await tester.pumpAndSettle();

      expect(find.textContaining('Invoice 2026'), findsOneWidget);
    });
  });

  group('with the lock disabled', () {
    testWidgets('the destination is shown immediately', (tester) async {
      await pumpAt(tester, AppRoutes.home, lockEnabled: false);

      expect(find.textContaining('Invoice 2026'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);
    });
  });
}

/// Bridges the gate's change stream onto a [Listenable] for GoRouter.
class _GateListenable extends ChangeNotifier {
  _GateListenable(AppLockGateImpl gate) {
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
