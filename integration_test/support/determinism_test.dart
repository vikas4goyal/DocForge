/// Tier 3 — the harness's own guarantee.
///
/// Every flow above this file assumes two things: that booting twice produces
/// the same state, and that nothing substituted at the platform edge can vary
/// between runs. Neither is self-evidently true, and if either quietly stops
/// holding, the symptom is not a failing determinism test — it is ten flows
/// that fail one run in twenty for reasons nobody can reproduce.
///
/// So the harness proves it about itself, first, before any flow relies on it.
library;

import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_boot.dart';
import 'robots/app_robots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('the harness is deterministic', () {
    testWidgets('two consecutive boots produce identical state', (
      tester,
    ) async {
      // The clock and the id generator are what every piece of derived state in
      // the application is stamped with: a document's created-at, its
      // identifier, a page's identifier. If those two agree across boots, no
      // flow's assertions can depend on which run they are in.
      final first = await bootDocScanly(tester);
      await DashboardRobot(tester).waitUntilLoaded();

      final firstNow = first.dependencies.clock.now();
      final firstIds = [
        first.dependencies.idGenerator.generate(),
        first.dependencies.idGenerator.generate(),
        first.dependencies.idGenerator.generate(),
      ];

      final second = await bootDocScanly(tester);
      await DashboardRobot(tester).waitUntilLoaded();

      final secondNow = second.dependencies.clock.now();
      final secondIds = [
        second.dependencies.idGenerator.generate(),
        second.dependencies.idGenerator.generate(),
        second.dependencies.idGenerator.generate(),
      ];

      expect(
        secondNow,
        firstNow,
        reason:
            'The clock moved between boots. A fixed clock is what makes a '
            'document created in one run comparable with the next.',
      );
      expect(
        secondIds,
        firstIds,
        reason:
            'Identifiers differed between boots. A flow that names a document '
            'by id would then pass or fail depending on boot order.',
      );
    });

    testWidgets('each boot starts from an empty library of its own', (
      tester,
    ) async {
      // The property that lets flows run in any order. If a boot could see what
      // an earlier one wrote, a flow asserting "the document appears" would
      // pass on the strength of some other flow's document.
      final first = await bootDocScanly(tester);
      final dashboard = DashboardRobot(tester);
      await dashboard.waitUntilLoaded();
      expect(dashboard.isEmpty, isTrue);

      final second = await bootDocScanly(tester);
      await DashboardRobot(tester).waitUntilLoaded();

      expect(
        second.libraryFolder.path,
        isNot(first.libraryFolder.path),
        reason:
            'Two boots shared a library folder, so they can see each '
            'other\'s documents.',
      );
      expect(DashboardRobot(tester).isEmpty, isTrue);
    });

    testWidgets('the substituted platform starts from a clean slate', (
      tester,
    ) async {
      final app = await bootDocScanly(tester);
      await DashboardRobot(tester).waitUntilLoaded();

      // Nothing has been shared, printed or captured before the flow acts. A
      // fake carrying state from a previous boot would let a flow's "the right
      // file was shared" assertion pass on someone else's file.
      expect(app.platform.share.shared, isEmpty);
      expect(app.platform.printer.printed, isEmpty);
      expect(app.platform.scanner.captures, isEmpty);
      expect(app.platform.recogniser.requested, isEmpty);
    });

    testWidgets('the dashboard renders the same way on both boots', (
      tester,
    ) async {
      // The end-to-end version of the same claim: not just that the seeds
      // match, but that the application built from them looks the same.
      await bootDocScanly(tester);
      final firstRun = DashboardRobot(tester);
      await firstRun.waitUntilLoaded();
      final firstEmpty = firstRun.isEmpty;
      expect(find.byKey(DashboardKeys.screen), findsOneWidget);

      await bootDocScanly(tester);
      final secondRun = DashboardRobot(tester);
      await secondRun.waitUntilLoaded();

      expect(secondRun.isEmpty, firstEmpty);
      expect(find.byKey(DashboardKeys.screen), findsOneWidget);
    });
  });
}
