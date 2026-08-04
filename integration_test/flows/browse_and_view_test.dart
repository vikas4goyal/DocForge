/// Flow — browse and view.
///
/// Precondition: onboarding is complete and one document has been imported.
///
/// What it proves: a dashboard document opens its detail, the detail's explicit
/// Open control reaches the real PDF viewer, and Back returns through detail to
/// the same dashboard. This is the production route chain a user follows.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/fixtures.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/library_robots.dart';
import '../support/robots/viewer_robots.dart';
import '../support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a dashboard document opens through detail and comes back', (
    tester,
  ) async {
    final staging = await Directory.systemTemp.createTemp('docscanly_browse_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    await bootDocScanly(tester, pickedFiles: [importable]);
    await seedDocumentByImport(tester);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(dashboard.isEmpty, isFalse);

    // Read the stable row identifier from what the user can see, then drive the
    // same dashboard → detail → Open route that production composition owns.
    final visibleIds = DocumentListRobot(tester).visibleDocumentIds;
    expect(visibleIds, hasLength(1));
    await dashboard.waitForDocumentThumbnail(visibleIds.single);
    await dashboard.openDocument(visibleIds.single);

    final detail = DocumentDetailRobot(tester);
    await detail.waitUntilVisible();
    await detail.open();

    // The viewer renders through the real pdfrx surface, so reaching a page
    // view means the renderer genuinely parsed the file the import produced —
    // which no host test could establish.
    final viewer = ViewerRobot(tester);
    await viewer.waitUntilOpen();
    expect(viewer.hasFailed, isFalse);

    await viewer.goBack();
    await detail.waitUntilVisible();
    await tester.pageBack();
    await dashboard.waitUntilLoaded();
    expect(dashboard.isEmpty, isFalse);
  });
}
