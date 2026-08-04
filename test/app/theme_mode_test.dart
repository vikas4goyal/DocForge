import 'package:doc_scanly/app/app.dart';
import 'package:doc_scanly/app/fake_dependencies.dart';
import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/app/router/route_gates.dart';
import 'package:doc_scanly/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A minimal screen set, so this exercises theming rather than any feature.
AppScreens _screens() {
  Widget page(String label) =>
      Scaffold(key: Key('screen_$label'), body: Text(label));

  return AppScreens(
    onboarding: (_) => page('onboarding'),
    unlock: (_) => page('unlock'),
    home: (_) => page('home'),
    scan: (_) => page('scan'),
    documents: (_) => page('documents'),
    documentDetail: (_, _) => page('documentDetail'),
    viewer: (_, _) => page('viewer'),
    documentEdit: (_, _) => page('documentEdit'),
    folders: (_) => page('folders'),
    folderDetail: (_, _) => page('folderDetail'),
    search: (_) => page('search'),
    favourites: (_) => page('favourites'),
    archive: (_) => page('archive'),
    trash: (_) => page('trash'),
    settings: (_) => page('settings'),
    about: (_) => page('about'),
    privacy: (_) => page('privacy'),
  );
}

void main() {
  late ThemeModeController themeMode;
  late GoRouter router;

  setUp(() {
    themeMode = ThemeModeController();
    router = createAppRouter(
      guard: RouteGuard(
        lockGate: FakeAppLockGate(),
        onboardingGate: FakeOnboardingGate(),
      ),
      screens: _screens(),
    );
  });

  tearDown(() {
    router.dispose();
    themeMode.dispose();
  });

  Widget build({Brightness platformBrightness = Brightness.light}) =>
      MediaQuery(
        data: MediaQueryData(platformBrightness: platformBrightness),
        child: DocScanlyApp(
          dependencies: buildFakeAppDependencies(),
          router: router,
          themeMode: themeMode,
        ),
      );

  /// The brightness the application actually rendered with.
  Brightness renderedBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byKey(const Key('screen_home')))).brightness;

  group('ThemeModeController', () {
    test('follows the system until a choice is made', () {
      expect(ThemeModeController().value, ThemeMode.system);
    });

    test('notifies listeners when the mode changes', () {
      var notifications = 0;
      themeMode.addListener(() => notifications++);

      themeMode.select(ThemeMode.dark);

      expect(themeMode.value, ThemeMode.dark);
      expect(notifications, 1);
    });

    test('re-selecting the current mode notifies nobody', () {
      var notifications = 0;
      themeMode.addListener(() => notifications++);

      themeMode.select(ThemeMode.system);

      // Rebuilding the whole application for a no-op selection would be a
      // visible stutter for no reason.
      expect(notifications, 0);
    });
  });

  group('following the system theme', () {
    testWidgets('renders light when the system is light', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(renderedBrightness(tester), Brightness.light);
    });

    testWidgets('renders dark when the system is dark', (tester) async {
      await tester.pumpWidget(build(platformBrightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(renderedBrightness(tester), Brightness.dark);
    });

    testWidgets('a system switch re-renders without a restart', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      expect(renderedBrightness(tester), Brightness.light);

      // The same widget tree, only the platform brightness changed — which is
      // what actually happens when the device switches to dark mode.
      await tester.pumpWidget(build(platformBrightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(renderedBrightness(tester), Brightness.dark);
    });
  });

  group('explicit theme selection', () {
    testWidgets('overrides a light system setting', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      themeMode.select(ThemeMode.dark);
      await tester.pumpAndSettle();

      // No rebuild of the root widget, no restart: the notifier alone did it.
      expect(renderedBrightness(tester), Brightness.dark);
    });

    testWidgets('overrides a dark system setting', (tester) async {
      await tester.pumpWidget(build(platformBrightness: Brightness.dark));
      await tester.pumpAndSettle();

      themeMode.select(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(renderedBrightness(tester), Brightness.light);
    });

    testWidgets('returning to system restores the device setting', (
      tester,
    ) async {
      await tester.pumpWidget(build(platformBrightness: Brightness.dark));
      await tester.pumpAndSettle();

      themeMode.select(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(renderedBrightness(tester), Brightness.light);

      themeMode.select(ThemeMode.system);
      await tester.pumpAndSettle();

      expect(renderedBrightness(tester), Brightness.dark);
    });

    testWidgets('an explicit choice survives navigation', (tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      themeMode.select(ThemeMode.dark);
      await tester.pumpAndSettle();

      router.go(AppRoutes.documents);
      await tester.pumpAndSettle();

      expect(
        Theme.of(
          tester.element(find.byKey(const Key('screen_documents'))),
        ).brightness,
        Brightness.dark,
      );
    });
  });
}
