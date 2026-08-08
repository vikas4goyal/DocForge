/// Putting a document in the library the way a user would.
///
/// Most flows are about what happens *to* a document, so they need one before
/// they start. They could be handed one by writing rows into Isar directly —
/// and that is exactly what would make them Tier 2 with extra steps, because a
/// document the application never created is a document whose creation was
/// never proved.
///
/// So a flow seeds by importing a fixture PDF through the real import path.
/// It is the shortest user-visible route into a populated library, it exercises
/// the writer the rest of the flow depends on, and it fails loudly if importing
/// itself is broken — which is far better than ten flows silently asserting
/// against an empty library.
library;

import 'package:flutter_test/flutter_test.dart';

import 'app_boot.dart';
import 'pump.dart';
import 'robots/app_robots.dart';
import 'robots/library_robots.dart';
import 'robots/viewer_robots.dart';

/// Imports the configured fixtures and returns to a loaded dashboard.
///
/// The flow must have been booted with the fixture path already supplied as
/// [bootDocScanly]'s `pickedFiles`, because the file browser answers with
/// whatever it was configured with at boot and cannot be reconfigured
/// afterwards.
Future<void> seedDocumentByImport(WidgetTester tester) =>
    step('seeding a document by import', () async {
      final dashboard = DashboardRobot(tester);
      await dashboard.waitUntilLoaded();
      await dashboard.openImportSheet();

      await ImportRobot(tester).importFromFiles();

      // A single successful import opens its Viewer directly; a multi-file
      // import stays on Dashboard so it does not pick an arbitrary document.
      // Let the route callback finish before distinguishing those outcomes.
      await tester.pump(const Duration(milliseconds: 500));
      final viewer = ViewerRobot(tester);
      if (viewer.isVisible) {
        await viewer.goBack();
      }

      // The dashboard reloads on navigation, so the imported document appears
      // without anything having to tell it to.
      await dashboard.waitUntilLoaded();
    });

/// The identifier of the only document showing in [list].
///
/// Read out of the row's own key rather than out of the database: a Tier-3 flow
/// asserts on what the user can see and never reaches past the widget tree, and
/// a document that exists in Isar but renders no row is precisely the kind of
/// failure this suite exists to catch.
///
/// Fails rather than guessing when the count is not one, because a flow acting
/// on the wrong document would assert successfully against the wrong thing.
String onlyDocumentId(DocumentListRobot list) {
  final ids = list.visibleDocumentIds;

  expect(
    ids,
    hasLength(1),
    reason:
        'Expected exactly one document on screen, found ${ids.length}. A flow '
        'addressing "the document" needs there to be one.',
  );

  return ids.single;
}
