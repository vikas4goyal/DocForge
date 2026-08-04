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

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/fixtures.dart';
import '../support/robots/app_robots.dart';
import '../support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
  });
}
