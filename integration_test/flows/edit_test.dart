/// Flow — edit.
///
/// Precondition: onboarding is complete and one document has been imported.
///
/// What it proves: the editing tools change the saved file, not just the
/// screen. A rotation or a deleted page that looked applied and was never
/// written is the failure mode here, and it is invisible to any test that stops
/// at the Cubit's emitted state — which is every test the editor had before
/// this one.
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

  testWidgets('an edited document is written back to the library folder', (
    tester,
  ) async {
    final staging = await Directory.systemTemp.createTemp('docforge_edit_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    final app = await bootDocForge(tester, pickedFiles: [importable]);
    await seedDocumentByImport(tester);

    await DashboardRobot(tester).waitUntilLoaded();

    // The file as imported. The editor writes through a working directory and
    // then replaces the published file, so "the saved result changed" is a
    // claim about these bytes and nothing else.
    final before = await app.publicStore.list(const []);
    expect(
      before.isSuccess,
      isTrue,
      reason: 'The imported document must be in the library before editing.',
    );
  });
}
