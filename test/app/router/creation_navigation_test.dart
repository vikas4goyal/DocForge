/// Navigation tests for the routes this change altered.
library;

import 'dart:async';

import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/marker_screens.dart';

/// Gates that let everything through, so a routing test tests routing.
class _OpenGate implements OnboardingGate {
  @override
  bool get needsOnboarding => false;

  @override
  Stream<bool> get onboardingChanges => const Stream<bool>.empty();
}

class _UnlockedGate implements AppLockGate {
  @override
  bool get isLocked => false;

  @override
  Stream<bool> get lockChanges => const Stream<bool>.empty();
}

void main() {
  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = createAppRouter(
      guard: RouteGuard(lockGate: _UnlockedGate(), onboardingGate: _OpenGate()),
      screens: markerScreens(),
      initialLocation: location,
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  group('the creation route', () {
    testWidgets('resolves', (tester) async {
      await pumpAt(tester, AppRoutes.scan);

      expect(find.text('scan'), findsOneWidget);
    });

    testWidgets('is reachable from the root', (tester) async {
      final router = await pumpAt(tester, AppRoutes.home);

      unawaited(router.push(AppRoutes.scan));
      await tester.pumpAndSettle();

      expect(find.text('scan'), findsOneWidget);
    });

    testWidgets('backing out returns to where the user was', (tester) async {
      final router = await pumpAt(tester, AppRoutes.home);
      unawaited(router.push(AppRoutes.scan));
      await tester.pumpAndSettle();

      router.pop();
      await tester.pumpAndSettle();

      // The destination the user was on is still underneath, which is why
      // Create is an action rather than a tab.
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('the retired wizard routes', () {
    testWidgets('resolve to not-found rather than a blank screen', (
      tester,
    ) async {
      for (final gone in const [
        '/scan/review',
        '/scan/enhance',
        '/scan/preview',
      ]) {
        await pumpAt(tester, gone);

        expect(
          find.byKey(const Key('route_not_found_screen')),
          findsOneWidget,
          reason: '$gone should not resolve',
        );
      }
    });

    testWidgets('a stale link offers a way back', (tester) async {
      await pumpAt(tester, '/scan/review');

      expect(find.text('Go to Home'), findsOneWidget);
    });
  });

  group('every remaining route', () {
    testWidgets('resolves to its own screen', (tester) async {
      for (final route in AppRoutes.all) {
        await pumpAt(tester, route);

        expect(
          find.byKey(const Key('route_not_found_screen')),
          findsNothing,
          reason: '$route should resolve',
        );
      }
    });

    testWidgets('the dashboard is the root', (tester) async {
      await pumpAt(tester, AppRoutes.dashboard);

      // One place for a deep link, a share and a cold start to land.
      expect(find.text('home'), findsOneWidget);
      expect(AppRoutes.dashboard, AppRoutes.home);
    });
  });

  group('settings', () {
    testWidgets('is reachable directly', (tester) async {
      await pumpAt(tester, AppRoutes.settings);

      expect(find.text('settings'), findsOneWidget);
    });
  });
}
