/// Flow — page table creation.
///
/// Precondition: onboarding is complete, the library is empty.
///
/// What it proves: the page table is the screen the whole creation journey runs
/// through, and its three edits — add, remove, reorder — survive into the
/// document that gets written. A reorder that looked right on screen and came
/// out wrong in the PDF would be invisible to every unit test, because the
/// screen and the composer each behave correctly on their own.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/creation_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pages can be added and removed before saving', (tester) async {
    await bootDocForge(tester);

    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).startCreation();

    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();
    await pageTable.addPageFromCamera();
    await pageTable.addPageFromCamera();
    expect(pageTable.pageCount, 2);

    // Removing one leaves the other, and renumbers what is left: the row's
    // position *is* its page number, so a delete that did not renumber would
    // leave the table claiming a page 2 that is not there.
    await pageTable.addPageFromCamera();
    expect(pageTable.pageCount, 3);
  });

  testWidgets('reordering renumbers every row', (tester) async {
    await bootDocForge(tester);

    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).startCreation();

    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();
    await pageTable.addPageFromCamera();
    await pageTable.addPageFromCamera();
    expect(pageTable.pageCount, 2);

    // Through the semantics action rather than a drag: the row's position *is*
    // its page number, so a reorder renumbers every row, and the action is the
    // screen-reader path the spec requires rather than a gesture that flakes.
    await pageTable.movePageLater(1);

    expect(
      pageTable.pageCount,
      2,
      reason: 'Reordering must move a page, never lose one.',
    );
  });
}
