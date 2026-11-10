// Tier 1 — the header-only size read the camera adapter reports after each
// capture. It is the ground truth the capture screen shows, so it must be
// right for a real image and must never throw for a broken one.
import 'dart:io';

import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;

  setUp(() => workspace = Directory.systemTemp.createTempSync('decoded_size'));
  tearDown(() => workspace.deleteSync(recursive: true));

  testWidgets('reads a JPEG\'s encoded width and height', (tester) async {
    final path = '${workspace.path}/capture.jpg';
    File(
      path,
    ).writeAsBytesSync(img.encodeJpg(img.Image(width: 64, height: 36)));

    final size = await tester.runAsync(() => decodedImageSize(path));

    expect(size, (64, 36));
  });

  testWidgets('an unreadable file reports no size instead of throwing', (
    tester,
  ) async {
    final path = '${workspace.path}/broken.jpg';
    File(path).writeAsBytesSync(const [0, 1, 2, 3]);

    final size = await tester.runAsync(() => decodedImageSize(path));

    expect(size, isNull);
  });
}
