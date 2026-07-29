/// Flow — search.
///
/// Precondition: onboarding is complete and one document has been imported.
///
/// What it proves: a query narrows the library to what matches, and clearing it
/// brings everything back. The search a user performs is the dashboard's own
/// field, which filters in place; the `/search` route exists but nothing in the
/// shell navigates to it, so driving that screen would be testing something no
/// user can reach.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/fixtures.dart';
import '../support/robots/app_robots.dart';
import '../support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a query that matches nothing empties the library view', (
    tester,
  ) async {
    final staging = await Directory.systemTemp.createTemp('docforge_search_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    await bootDocForge(tester, pickedFiles: [importable]);
    await seedDocumentByImport(tester);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(
      dashboard.isEmpty,
      isFalse,
      reason: 'The seeded document must be visible before it is filtered out.',
    );

    await dashboard.search('zzz nothing matches this zzz');

    // An empty result is a valid answer the spec requires the screen to state.
    // A search that showed a spinner forever would be indistinguishable from a
    // broken index to the user, and to any test that only checked for results.
    expect(
      dashboard.isEmpty,
      isTrue,
      reason: 'A query matching nothing must say so, not show stale results.',
    );
  });

  testWidgets('clearing the query brings the library back', (tester) async {
    final staging = await Directory.systemTemp.createTemp('docforge_search2_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    await bootDocForge(tester, pickedFiles: [importable]);
    await seedDocumentByImport(tester);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();

    await dashboard.search('zzz nothing matches this zzz');
    expect(dashboard.isEmpty, isTrue);

    // Filtering must be reversible: a search that could not be undone would
    // leave the user looking at an empty library they cannot explain.
    await dashboard.clearSearch();
    expect(
      dashboard.isEmpty,
      isFalse,
      reason: 'Clearing the query must restore the documents it hid.',
    );
  });
}
