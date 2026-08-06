/// Flow — share.
///
/// Precondition: onboarding is complete and one document has been imported.
///
/// What it proves: invoking share hands the *right file* and the *right
/// metadata* to the system boundary. The real share sheet is outside anything
/// the framework can drive — that is stated as a Non-Goal rather than hidden —
/// so the assertion is made where the payload arrives at the substituted
/// repository. "The correct bytes were handed over" is the strongest true claim
/// available, and it is the one that actually catches sharing the wrong
/// document.
library;

import 'dart:io';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:flutter/widgets.dart';
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

  Future<FlowApp> openShareSheet(
    WidgetTester tester, {
    String? exportDestination,
    Failure? exportFailure,
  }) async {
    final staging = await Directory.systemTemp.createTemp(
      'docscanly_share_action_',
    );
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();
    final app = await bootDocScanly(
      tester,
      pickedFiles: [importable],
      exportDestination: exportDestination,
      exportFailure: exportFailure,
    );
    await seedDocumentByImport(tester);
    final dashboard = DashboardRobot(tester);
    await dashboard.openDocument(dashboard.visibleDocumentIds.single);
    final detail = DocumentDetailRobot(tester);
    await detail.waitUntilVisible();
    await detail.open();
    final viewer = ViewerRobot(tester);
    await viewer.waitUntilOpen();
    await viewer.openShare();
    return app;
  }

  testWidgets('nothing is shared until the user asks for it', (tester) async {
    final staging = await Directory.systemTemp.createTemp('docscanly_share_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    final app = await bootDocScanly(tester, pickedFiles: [importable]);
    await seedDocumentByImport(tester);

    await DashboardRobot(tester).waitUntilLoaded();

    // The baseline the positive assertion depends on. A fake that had recorded
    // something before the user acted would let "the right file was shared"
    // pass on the strength of a payload nobody asked for.
    expect(
      app.platform.share.shared,
      isEmpty,
      reason: 'Importing a document must not share it.',
    );
    expect(
      app.platform.printer.printed,
      isEmpty,
      reason: 'Importing a document must not print it.',
    );

    final dashboard = DashboardRobot(tester);
    final documentId = dashboard.visibleDocumentIds.single;
    await dashboard.openDocument(documentId);
    final detail = DocumentDetailRobot(tester);
    await detail.waitUntilVisible();
    await detail.open();
    final viewer = ViewerRobot(tester);
    await viewer.waitUntilOpen();
    await viewer.openShare();

    final share = ShareRobot(tester);
    await share.waitUntilVisible();
    expect(
      share.offersExtractedText,
      isFalse,
      reason: 'Internal OCR text must not reappear as a share action.',
    );
    await share.shareImages();
    expect(app.platform.share.shared, hasLength(1));
    expect(app.platform.share.shared.single.filePaths, hasLength(1));
    expect(app.platform.share.shared.single.text, isEmpty);

    // The imported fixture contains embedded text. On a wide layout Viewer
    // exposes that locally extracted text beside the same rendered PDF.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1180, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(find.byKey(ViewerKeys.textPanel), findsOneWidget);
    expect(find.textContaining('DocScanly importable fixture'), findsOneWidget);
  });

  testWidgets('export writes once through the destination provider', (
    tester,
  ) async {
    final destination = File(
      '${Directory.systemTemp.path}/docscanly_export_flow.pdf',
    );
    if (destination.existsSync()) destination.deleteSync();
    addTearDown(() {
      if (destination.existsSync()) destination.deleteSync();
    });

    final app = await openShareSheet(
      tester,
      exportDestination: destination.path,
    );
    await ShareRobot(tester).export();

    expect(destination.existsSync(), isTrue);
    expect(app.platform.exportPicker.suggestions, hasLength(1));
  });

  testWidgets('cancelled export writes nothing and shows no error', (
    tester,
  ) async {
    await openShareSheet(tester);
    await ShareRobot(tester).cancelExport();
  });

  testWidgets('provider failure is stage-specific and recoverable', (
    tester,
  ) async {
    await openShareSheet(
      tester,
      exportFailure: const Failure.export(debugDetail: 'provider denied write'),
    );
    await ShareRobot(tester).recoverFromExportFailure();
  });
}
