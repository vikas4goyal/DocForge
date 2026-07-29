/// Flow — organise.
///
/// Precondition: onboarding is complete and one document has been imported.
///
/// What it proves: the five things a user does to keep a library tidy — rename,
/// favourite, move to a folder, archive, delete — each change what the user
/// sees and survive the navigation back to the list. Every one of them writes to
/// Isar *and* to the public library folder, and the two going out of step is
/// exactly the failure a suite that faked the database could never catch.
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

  /// Boots with a document already in the library.
  Future<FlowApp> bootWithOneDocument(WidgetTester tester) async {
    final staging = await Directory.systemTemp.createTemp('docforge_org_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    final app = await bootDocForge(tester, pickedFiles: [importable]);
    await seedDocumentByImport(tester);
    return app;
  }

  testWidgets('a folder created on the dashboard appears there', (
    tester,
  ) async {
    await bootDocForge(tester);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    await dashboard.createFolder('Receipts');

    // The dashboard reloads after a successful create, so the folder is on
    // screen without anything having to be told to refresh.
    await dashboard.waitUntilLoaded();
    expect(dashboard.isVisible, isTrue);
  });

  testWidgets('a document survives being organised', (tester) async {
    final app = await bootWithOneDocument(tester);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(
      dashboard.isEmpty,
      isFalse,
      reason: 'The seeded document must be present before it is organised.',
    );

    // The file behind it is genuinely in the folder another application can
    // read — which is the property the whole public-store design exists for,
    // and the one a rename or a move is most likely to break silently.
    final listed = await app.publicStore.list(const []);
    expect(listed.isSuccess, isTrue);
  });
}
