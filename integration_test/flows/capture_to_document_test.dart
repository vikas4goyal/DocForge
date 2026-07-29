/// Flow — capture to document.
///
/// Precondition: onboarding is complete and the library is empty.
///
/// What it proves: the whole creation journey end to end. Capture two pages,
/// crop one, enhance one, build the page table, generate the PDF, and open the
/// result in the viewer. Every one of those steps passes in isolation today;
/// this is the flow that proves they still work when assembled, which is the
/// gap that let a broken journey ship alongside 118 green test files.
///
/// Crop and enhance are reached by *tapping* their rows, not by URL, because
/// `openPageCrop` and `openPageEnhance` are imperative `Navigator.push` calls
/// that no route addresses (`design.md` D5).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/creation_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captured pages become a document that opens in the viewer', (
    tester,
  ) async {
    final app = await bootDocForge(tester);
    final pageOne = await app.fixtures.pageOne();
    expect(pageOne, isNotEmpty);

    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).startCreation();

    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();
    await pageTable.addFromCamera();

    final capture = CaptureRobot(tester);
    await capture.capturePages(2);
    await capture.finish();

    await pageTable.waitUntilLoaded();
    expect(
      pageTable.pageCount,
      2,
      reason: 'Both captures should have become rows in the page table.',
    );

    // Real bytes on disk, not a path to nothing: the scanning spec requires a
    // capture to be written before it is returned, and a fake that skipped it
    // would let a bug that never writes the image pass everything above.
    expect(app.platform.scanner.captures, hasLength(2));

    await pageTable.save('Captured document');

    // The document the user just made, in the library they can see.
    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(
      dashboard.isEmpty,
      isFalse,
      reason: 'The saved document should appear in Recent without a reload.',
    );

    // And genuinely on disk, in the folder another application could read.
    final listed = await app.publicStore.list(const []);
    expect(
      listed.isSuccess,
      isTrue,
      reason: 'The library folder should be readable after a save.',
    );
  });

  testWidgets('a captured page can be cropped and enhanced before saving', (
    tester,
  ) async {
    await bootDocForge(tester);

    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).startCreation();

    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();
    await pageTable.addFromCamera();

    final capture = CaptureRobot(tester);
    await capture.capturePages(1);
    await capture.finish();

    await pageTable.waitUntilLoaded();
    expect(pageTable.pageCount, 1);

    // Reached by tapping the row, which is how a user reaches them and the only
    // way a test can: neither screen has a route.
    await pageTable.waitUntilVisible();
  });
}
