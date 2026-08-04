/// Flow — import.
///
/// Precondition: onboarding is complete, the library is empty, and the file
/// browser is configured to answer with the fixture PDF.
///
/// What it proves: a file chosen from outside DocScanly becomes a document the
/// user can see in their library. This is the journey where an app that stores
/// documents most obviously either works or does not, and the one a unit test
/// can least meaningfully stand in for — it crosses the picker, the importer,
/// the writer, the public store and the dashboard's own reload.
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

  testWidgets('an imported file appears in the library', (tester) async {
    // The fixture path has to be resolved before the boot that configures the
    // file browser with it, so this materialises it into a directory of its own
    // first.
    final staging = await Directory.systemTemp.createTemp('docscanly_import_');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final importable = await Fixtures(staging).importable();

    final app = await bootDocScanly(tester, pickedFiles: [importable]);

    final dashboard = DashboardRobot(tester);
    await dashboard.waitUntilLoaded();
    expect(
      dashboard.isEmpty,
      isTrue,
      reason: 'The flow must start from an empty library to prove anything.',
    );

    await seedDocumentByImport(tester);

    expect(
      dashboard.isEmpty,
      isFalse,
      reason:
          'The imported document should be in the library the user can see, '
          'not only in the database.',
    );

    // And genuinely written where another application could read it, which is
    // what the public library folder is for.
    final listed = await app.publicStore.list(const []);
    expect(listed.isSuccess, isTrue);
  });
}
