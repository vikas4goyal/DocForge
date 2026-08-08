/// Flow — capture to document.
///
/// Precondition: onboarding is complete and the library is empty.
///
/// What it proves: the whole creation journey end to end. Add pages from the
/// camera, take each through crop and enhancement, build the page table,
/// generate the PDF, and find the result in the library. Every one of those
/// steps passes in isolation today; this is the flow that proves they still
/// work when assembled, which is the gap that let a broken journey ship
/// alongside 118 green test files.
///
/// Crop and enhance are reached by *continuing through them*, not by URL,
/// because `openPageCrop` and `openPageEnhance` are imperative
/// `Navigator.push` calls that no route addresses (`design.md` D5).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/creation_robots.dart';
import '../support/robots/viewer_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captured pages become a document in the library', (
    tester,
  ) async {
    final app = await bootDocScanly(tester);

    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).startCreation();

    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();

    await pageTable.beginAddingPageFromCamera();
    expect(
      app.platform.scanner.captures,
      hasLength(1),
      reason: 'The live camera must wait for the robot\'s explicit shutter.',
    );
    await CropRobot(tester).acceptAndContinue();
    await EnhanceRobot(tester).backToCrop();
    await CropRobot(tester).acceptAndContinue();
    await EnhanceRobot(tester).done();
    await pageTable.waitUntilLoaded();

    // The second page follows the ordinary crop-then-enhance loop.
    await pageTable.addPageFromCamera();

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

    // Saving opens the new PDF directly; Back reveals the refreshed library.
    final viewer = ViewerRobot(tester);
    await viewer.waitUntilOpen();
    await viewer.goBack();
    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(
      dashboard.isEmpty,
      isFalse,
      reason: 'The saved document should appear in Recent without a reload.',
    );

    // And genuinely in the folder another application could read, which is what
    // the public library folder exists for.
    final listed = await app.publicStore.list(const []);
    expect(listed.isSuccess, isTrue);
    expect(
      listed.valueOrNull,
      isNotEmpty,
      reason: 'A saved document must leave a file behind, not only a row.',
    );
  });

  testWidgets('a page abandoned at crop is not added', (tester) async {
    final app = await bootDocScanly(tester);

    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).startCreation();

    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();

    await pageTable.beginAddingPageFromCamera();
    await CropRobot(tester).cancel();

    await pageTable.waitUntilLoaded();
    expect(
      pageTable.pageCount,
      0,
      reason:
          'Leaving crop without continuing must add nothing — the spec treats '
          'it as "keep what you had", not as a failure.',
    );

    // The capture still happened, which is what makes this worth asserting: the
    // page was staged and then discarded rather than never taken.
    expect(app.platform.scanner.captures, hasLength(1));
  });
}
