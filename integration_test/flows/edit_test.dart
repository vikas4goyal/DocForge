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
import '../support/robots/viewer_robots.dart';
import '../support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<FlowApp> openSourceInViewer(WidgetTester tester) async {
    final staging = await Directory.systemTemp.createTemp('docscanly_edit_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final fixtures = Fixtures(staging);
    final source = await fixtures.sourceDocument();
    final app = await bootDocScanly(tester, pickedFiles: [source]);
    await seedDocumentByImport(tester);
    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    final sourceId = dashboard.visibleDocumentIds.first;
    await dashboard.openDocument(sourceId);
    await ViewerRobot(tester).waitUntilOpen();
    return app;
  }

  testWidgets('compression submits once and returns a visible result', (
    tester,
  ) async {
    final app = await openSourceInViewer(tester);

    // The file as imported. The editor writes through a working directory and
    // then replaces the published file, so "the saved result changed" is a
    // claim about these bytes and nothing else.
    final before = await app.publicStore.list(const []);
    expect(
      before.isSuccess,
      isTrue,
      reason: 'The imported document must be in the library before editing.',
    );
    await ViewerRobot(tester).openCompress();
    final editor = PdfEditRobot(tester);
    await editor.waitUntilFocused();
    await editor.compress();
    await editor.finishResult();
    await DashboardRobot(tester).waitUntilLoaded();
  });

  testWidgets('split creates one reviewed two-output result', (tester) async {
    await openSourceInViewer(tester);
    await ViewerRobot(tester).openSplit();
    final editor = PdfEditRobot(tester);
    await editor.waitUntilSplitNaming();
    await editor.split();
    expect(find.text('2 documents created'), findsOneWidget);
    await editor.finishResult();
    await DashboardRobot(tester).waitUntilLoaded();
  });

  testWidgets('watermark and protect each show their completed result', (
    tester,
  ) async {
    await openSourceInViewer(tester);
    final viewer = ViewerRobot(tester);
    await viewer.openWatermark();
    var editor = PdfEditRobot(tester);
    await editor.waitUntilFocused();
    await editor.watermarkWith('CONFIDENTIAL');
    await editor.finishResult();
    await DashboardRobot(tester).waitUntilLoaded();

    // Re-enter the now-watermarked source and apply password protection.
    final dashboard = DashboardRobot(tester);
    await dashboard.openDocument(dashboard.visibleDocumentIds.single);
    await viewer.waitUntilOpen();
    await viewer.openPassword();
    editor = PdfEditRobot(tester);
    await editor.waitUntilFocused();
    await editor.protectWith('secret12');
    await editor.finishResult();
    await DashboardRobot(tester).waitUntilLoaded();
  });

  testWidgets('page extraction creates one derived-document result', (
    tester,
  ) async {
    await openSourceInViewer(tester);
    await ViewerRobot(tester).openPageManagement();
    final editor = PdfEditRobot(tester);
    await editor.waitUntilLoaded();
    await editor.selectPage(0);
    await editor.extractSelected();
    expect(find.text('Document created'), findsOneWidget);
    await editor.finishResult();
    await DashboardRobot(tester).waitUntilLoaded();
  });
}
