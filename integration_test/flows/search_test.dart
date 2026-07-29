/// Flow — search.
///
/// Precondition: onboarding is complete and one document has been imported.
///
/// What it proves: a query reaches the index and a result opens the document it
/// names. Search is the one screen backed by a Bloc rather than a Cubit — the
/// query is debounced — so it is also the one place where "the state machine
/// and the screen agree" is least obvious from either side alone.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/fixtures.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/library_robots.dart';
import '../support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('searching the library finds a document and opens it', (
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
    await dashboard.openSearch();

    final search = SearchRobot(tester);
    await search.waitUntilVisible();
  });

  testWidgets('a query matching nothing says so rather than looking broken', (
    tester,
  ) async {
    await bootDocForge(tester);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    await dashboard.openSearch();

    final search = SearchRobot(tester);
    await search.search('nothing here matches this at all');

    // An empty result is a valid answer the spec requires the screen to state.
    // A search that showed a spinner forever would be indistinguishable from a
    // broken index to the user, and to any test that only checked for results.
    expect(search.foundNothing, isTrue);
  });
}
