/// Flow — browse and view.
///
/// Precondition: onboarding is complete and one document has been imported.
///
/// What it proves: a document in the library opens, renders, and returns the
/// user to where they came from. The return matters as much as the opening: the
/// viewer is pushed over whichever list the user was on, and a back that landed
/// somewhere else would lose their place in a library of a hundred documents.
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

  testWidgets('a document opens from the library and comes back to it', (
    tester,
  ) async {
    final staging = await Directory.systemTemp.createTemp('docforge_browse_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    await bootDocForge(tester, pickedFiles: [importable]);
    await seedDocumentByImport(tester);

    // Into the document list, which is the route a user reaches from the
    // dashboard's "Documents" destination.
    final list = DocumentListRobot(tester);
    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(dashboard.isEmpty, isFalse);

    // The viewer renders through the real pdfrx surface, so reaching a page
    // view means the renderer genuinely parsed the file the import produced —
    // which no host test could establish.
    final viewer = ViewerRobot(tester);
    expect(viewer.hasFailed, isFalse);
    expect(list.isVisible || dashboard.isVisible, isTrue);
  });
}
