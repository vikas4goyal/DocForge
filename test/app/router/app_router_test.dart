import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A placeholder screen that announces which route rendered it.
Widget marker(String name) => Scaffold(body: Center(child: Text(name)));

/// Screens that render their own route name, so a test can assert on it.
final testScreens = AppScreens(
  onboarding: (_) => marker('onboarding'),
  unlock: (_) => marker('unlock'),
  home: (_) => marker('home'),
  scan: (_) => marker('scan'),
  scanReview: (_) => marker('scanReview'),
  scanEnhance: (_) => marker('scanEnhance'),
  scanPreview: (_) => marker('scanPreview'),
  documents: (_) => marker('documents'),
  documentDetail: (_, id) => marker('documentDetail:${id.value}'),
  viewer: (_, id) => marker('viewer:${id.value}'),
  documentEdit: (_, id) => marker('documentEdit:${id.value}'),
  folders: (_) => marker('folders'),
  folderDetail: (_, id) => marker('folderDetail:${id.value}'),
  search: (_) => marker('search'),
  favourites: (_) => marker('favourites'),
  archive: (_) => marker('archive'),
  settings: (_) => marker('settings'),
  about: (_) => marker('about'),
  privacy: (_) => marker('privacy'),
);

/// Pumps the router at [location] with the given gate states.
Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  String location = AppRoutes.home,
  bool locked = false,
  bool needsOnboarding = false,
}) async {
  final router = createAppRouter(
    guard: RouteGuard(
      lockGate: FakeAppLockGate(isLocked: locked),
      onboardingGate: FakeOnboardingGate(needsOnboarding: needsOnboarding),
    ),
    screens: testScreens,
    initialLocation: location,
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('every route resolves', () {
    final expected = <String, String>{
      AppRoutes.home: 'home',
      AppRoutes.scan: 'scan',
      AppRoutes.scanReview: 'scanReview',
      AppRoutes.scanEnhance: 'scanEnhance',
      AppRoutes.scanPreview: 'scanPreview',
      AppRoutes.documents: 'documents',
      AppRoutes.folders: 'folders',
      AppRoutes.search: 'search',
      AppRoutes.favourites: 'favourites',
      AppRoutes.archive: 'archive',
      AppRoutes.settings: 'settings',
      AppRoutes.about: 'about',
      AppRoutes.privacy: 'privacy',
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key} renders ${entry.value}', (tester) async {
        await pumpRouter(tester, location: entry.key);

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('every declared route is covered by this test', (tester) async {
      // Guards against a route being added to AppRoutes.all without a test.
      final untested = AppRoutes.all
          .where((r) => r != AppRoutes.unlock && r != AppRoutes.onboarding)
          .where((r) => !expected.containsKey(r))
          .toList();

      expect(untested, isEmpty, reason: 'untested routes: $untested');
    });
  });

  group('parameterised routes', () {
    testWidgets('document detail receives its typed id', (tester) async {
      await pumpRouter(
        tester,
        location: AppRoutes.documentDetail(const DocumentId('doc-42')),
      );

      expect(find.text('documentDetail:doc-42'), findsOneWidget);
    });

    testWidgets('document edit receives its typed id', (tester) async {
      await pumpRouter(
        tester,
        location: AppRoutes.documentEdit(const DocumentId('doc-7')),
      );

      expect(find.text('documentEdit:doc-7'), findsOneWidget);
    });

    testWidgets('folder detail receives its typed id', (tester) async {
      await pumpRouter(
        tester,
        location: AppRoutes.folderDetail(const FolderId('folder-3')),
      );

      expect(find.text('folderDetail:folder-3'), findsOneWidget);
    });

    test('location builders produce the documented paths', () {
      expect(AppRoutes.documentDetail(const DocumentId('a')), '/documents/a');
      expect(
        AppRoutes.documentEdit(const DocumentId('a')),
        '/documents/a/edit',
      );
      expect(AppRoutes.folderDetail(const FolderId('b')), '/folders/b');
    });
  });

  group('unknown routes', () {
    testWidgets('show a not-found state with a way back to Home', (
      tester,
    ) async {
      await pumpRouter(tester, location: '/does/not/exist');

      expect(find.byKey(const Key('route_not_found_screen')), findsOneWidget);
      expect(find.text('That page does not exist'), findsOneWidget);
    });

    testWidgets('do not crash the application', (tester) async {
      await pumpRouter(tester, location: '/nonsense');

      expect(tester.takeException(), isNull);
    });

    testWidgets('the way back actually returns to Home', (tester) async {
      await pumpRouter(tester, location: '/nope');

      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });
  });

  group('lock gate', () {
    testWidgets('a locked app shows the unlock screen instead of Home', (
      tester,
    ) async {
      await pumpRouter(tester, locked: true);

      expect(find.text('unlock'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });

    testWidgets('a locked app cannot reach a document', (tester) async {
      await pumpRouter(
        tester,
        location: AppRoutes.documentDetail(const DocumentId('doc-1')),
        locked: true,
      );

      // No document title, thumbnail or content may render behind the lock.
      expect(find.text('unlock'), findsOneWidget);
      expect(find.textContaining('documentDetail'), findsNothing);
    });

    testWidgets('an unlocked app does not show the unlock screen', (
      tester,
    ) async {
      await pumpRouter(tester, location: AppRoutes.unlock);

      expect(find.text('unlock'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('onboarding gate', () {
    testWidgets('a first launch shows onboarding', (tester) async {
      await pumpRouter(tester, needsOnboarding: true);

      expect(find.text('onboarding'), findsOneWidget);
    });

    testWidgets('a first launch cannot reach any other route', (tester) async {
      await pumpRouter(
        tester,
        location: AppRoutes.settings,
        needsOnboarding: true,
      );

      expect(find.text('onboarding'), findsOneWidget);
      expect(find.text('settings'), findsNothing);
    });

    testWidgets('a returning user goes straight to Home', (tester) async {
      await pumpRouter(tester);

      expect(find.text('home'), findsOneWidget);
      expect(find.text('onboarding'), findsNothing);
    });

    testWidgets('onboarding is unreachable once complete', (tester) async {
      await pumpRouter(tester, location: AppRoutes.onboarding);

      expect(find.text('onboarding'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('gate ordering', () {
    testWidgets('the lock is evaluated before onboarding', (tester) async {
      // Both gates active. The lock must win, so nothing renders before
      // authentication — including onboarding.
      await pumpRouter(tester, locked: true, needsOnboarding: true);

      expect(find.text('unlock'), findsOneWidget);
      expect(find.text('onboarding'), findsNothing);
    });

    testWidgets('onboarding follows once the app is unlocked', (tester) async {
      await pumpRouter(
        tester,
        location: AppRoutes.unlock,
        needsOnboarding: true,
      );

      expect(find.text('onboarding'), findsOneWidget);
    });
  });

  group('RouteGuard', () {
    RouteGuard guard({bool locked = false, bool needsOnboarding = false}) =>
        RouteGuard(
          lockGate: FakeAppLockGate(isLocked: locked),
          onboardingGate: FakeOnboardingGate(needsOnboarding: needsOnboarding),
        );

    test('allows any route when both gates are open', () {
      expect(guard().redirectFor(AppRoutes.home), isNull);
      expect(guard().redirectFor(AppRoutes.settings), isNull);
    });

    test('redirects everything to unlock while locked', () {
      final g = guard(locked: true);

      expect(g.redirectFor(AppRoutes.home), AppRoutes.unlock);
      expect(g.redirectFor(AppRoutes.settings), AppRoutes.unlock);
      expect(g.redirectFor('/documents/x'), AppRoutes.unlock);
    });

    test('does not redirect the unlock route to itself', () {
      // Redirecting a location to itself is an infinite loop, not a screen.
      expect(guard(locked: true).redirectFor(AppRoutes.unlock), isNull);
    });

    test('does not redirect the onboarding route to itself', () {
      expect(
        guard(needsOnboarding: true).redirectFor(AppRoutes.onboarding),
        isNull,
      );
    });

    test('sends an unlocked user away from the unlock screen', () {
      expect(guard().redirectFor(AppRoutes.unlock), AppRoutes.home);
    });

    test('sends an unlocked first-time user from unlock to onboarding', () {
      expect(
        guard(needsOnboarding: true).redirectFor(AppRoutes.unlock),
        AppRoutes.onboarding,
      );
    });

    test('sends a returning user away from onboarding', () {
      expect(guard().redirectFor(AppRoutes.onboarding), AppRoutes.home);
    });

    test('lock takes precedence over onboarding', () {
      expect(
        guard(locked: true, needsOnboarding: true).redirectFor(AppRoutes.home),
        AppRoutes.unlock,
      );
    });

    test('no route redirects to itself, for any gate combination', () {
      // A self-redirect is the classic router hang; this asserts the whole
      // matrix rather than the cases that happened to come to mind.
      for (final locked in [true, false]) {
        for (final onboarding in [true, false]) {
          final g = guard(locked: locked, needsOnboarding: onboarding);
          for (final route in AppRoutes.all) {
            expect(
              g.redirectFor(route),
              isNot(route),
              reason:
                  '$route redirects to itself '
                  '(locked: $locked, onboarding: $onboarding)',
            );
          }
        }
      }
    });

    test('redirects always converge within one further step', () {
      // Following a redirect must land somewhere allowed, or the router loops.
      for (final locked in [true, false]) {
        for (final onboarding in [true, false]) {
          final g = guard(locked: locked, needsOnboarding: onboarding);
          for (final route in AppRoutes.all) {
            final first = g.redirectFor(route);
            if (first == null) continue;

            expect(
              g.redirectFor(first),
              isNull,
              reason:
                  '$route -> $first still redirects '
                  '(locked: $locked, onboarding: $onboarding)',
            );
          }
        }
      }
    });
  });
}
