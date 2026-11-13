/// Walks the real app through its key screens for App Store screenshots.
///
/// Not part of the flow suite: it asserts nothing and is skipped unless
/// `STORE_SCREENSHOTS=true` is defined. Run it through
/// `tool/store_assets/capture_app_store_screenshots.sh`, which boots the
/// simulators, cleans up the status bar and takes a native screenshot each
/// time this test reaches a screen.
///
/// Handshake: at each screen the test prints `STORE_SCREENSHOT_READY:<name>`
/// and keeps rendering until the host script drops a `<name>.done` file into
/// the app's temporary directory. Waiting for the host, rather than sleeping a
/// fixed time, keeps a slow screenshot from catching the next screen.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:doc_scanly/features/document_scanning/presentation/scan_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_boot.dart';
import '../support/robots/app_robots.dart';
import '../support/robots/creation_robots.dart';
import '../support/robots/viewer_robots.dart';
import 'store_content.dart';

const _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store screenshots', skip: !_enabled, (tester) async {
    final staging = await Directory.systemTemp.createTemp('store_content_');
    final photoPaths = <String>[];
    late List<int> cameraPhoto;
    final scans = <Uint8List>[];
    await tester.runAsync(() async {
      for (final (index, photo) in samplePhotos.indexed) {
        final bytes = await renderPaperPhoto(photo);
        if (index == 0) cameraPhoto = bytes;
        scans.add(bytes);
        final file = File('${staging.path}/photo_$index.png');
        await file.writeAsBytes(bytes, flush: true);
        photoPaths.add(file.path);
      }
    });

    final pdfs = await writeSamplePdfs(staging, scans: scans);

    await bootDocScanly(
      tester,
      pickedFiles: pdfs,
      captureImageBytes: cameraPhoto,
      galleryImages: photoPaths.sublist(1),
    );

    final dashboard = DashboardRobot(tester);
    final shell = TabShellRobot(tester);
    final viewer = ViewerRobot(tester);
    await dashboard.waitUntilLoaded();

    // Library: imported documents in the compact grid.
    await dashboard.openImportSheet();
    await ImportRobot(tester).importFromFiles();
    await tester.pump(const Duration(milliseconds: 500));
    if (viewer.isVisible) await viewer.goBack();
    await dashboard.waitUntilLoaded();
    await dashboard.waitForDocuments();
    // Phones fit more of the library in the compact grid; tablets already
    // show plenty at the default size.
    final view = tester.view;
    if (view.physicalSize.shortestSide / view.devicePixelRatio < 600) {
      await dashboard.chooseDisplaySize(DashboardKeys.displaySizeSmall);
    }

    for (final id in dashboard.visibleDocumentIds) {
      await dashboard.waitForDocumentThumbnail(id);
    }
    await _waitForSnackBarToClear(tester);
    // Recent-strip previews render after the grid's.
    await _settle(tester, seconds: 4);
    await _capture(tester, '01-library');

    // Viewer on the invoice.
    await _openTitled(tester, 'Invoice INV-2048');
    await viewer.waitUntilOpen();
    await _settle(tester, seconds: 3);
    await _capture(tester, '02-viewer');

    // PDF tools: compression over the multi-page report, then a watermark.
    await viewer.goBack();
    await dashboard.waitUntilLoaded();
    await _openTitled(tester, 'Scanned Paperwork');
    await viewer.waitUntilOpen();
    await viewer.openCompress();
    await CompressPdfRobot(tester).waitUntilCalculated();
    await _settle(tester, seconds: 3);
    await _capture(tester, '03-compress');
    await PdfEditRobot(tester).close();
    await viewer.waitUntilOpen();
    await viewer.goBack();
    await dashboard.waitUntilLoaded();
    await _openTitled(tester, 'Apartment Lease Agreement');
    await viewer.waitUntilOpen();
    await viewer.openWatermark();
    await PdfEditRobot(tester).waitUntilFocused();
    await tester.enterText(
      find.byKey(PdfEditKeys.watermarkTextField),
      'CONFIDENTIAL',
    );
    await _settle(tester, seconds: 3);
    await _capture(tester, '04-watermark');
    await PdfEditRobot(tester).close();
    await viewer.waitUntilOpen();
    await viewer.goBack();
    await dashboard.waitUntilLoaded();

    // Scanning: crop and enhance a receipt "photographed" by the camera.
    await shell.startCreation();
    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();
    await pageTable.beginAddingPageFromCamera();
    await _cropToPaper(tester, samplePhotos[0]);
    await _settle(tester, seconds: 2);
    await _capture(tester, '05-crop');
    await _applyCropAndContinue(tester);
    final enhance = EnhanceRobot(tester);
    await enhance.waitUntilVisible();
    await enhance.selectFilter(EnhanceKeys.filterMagicColour);
    await _settle(tester, seconds: 3);
    await _capture(tester, '06-enhance');
    await enhance.done();
    await pageTable.waitUntilLoaded();

    // Two more pages from the photo library, so the page list has variety.
    await pageTable.addFromGallery();
    for (final photo in samplePhotos.skip(1)) {
      await CropRobot(tester).waitUntilVisible();
      await _cropToPaper(tester, photo);
      await _applyCropAndContinue(tester);
      await EnhanceRobot(tester).selectFilter(EnhanceKeys.filterAuto);
      await _settle(tester, seconds: 2);
      await EnhanceRobot(tester).done();
    }
    await pageTable.waitUntilLoaded();
    await _settle(tester, seconds: 3);
    await _capture(tester, '07-pages');

    await pageTable.openSavePdf();
    final save = SavePdfRobot(tester);
    await save.name('Grocery Receipt');
    await save.waitForExactSize();
    await _settle(tester, seconds: 2);
    await _capture(tester, '08-save-pdf');
    await save.commit();
    await viewer.waitUntilOpen();
    await viewer.goBack();
    await dashboard.waitUntilLoaded();

    // Search.
    await dashboard.search('receipt');
    await _settle(tester, seconds: 2);
    await _capture(tester, '09-search');
    // Sharing options on the receipt that was just scanned.
    await _openTitled(tester, 'Grocery Receipt');
    await viewer.waitUntilOpen();
    await viewer.openShare();
    await _settle(tester, seconds: 2);
    await _capture(tester, '10-share');
  });
}

/// Drags the crop corners onto the sheet of paper in [photo].
Future<void> _cropToPaper(WidgetTester tester, PaperPhoto photo) async {
  await _settle(tester);
  Offset centre(int corner) =>
      tester.getCenter(find.byKey(ScanKeys.cropHandle(corner)));
  // The handles start on the image corners, so they give its on-screen rect.
  final image = Rect.fromPoints(centre(0), centre(2));
  final targets = paperCorners(photo)
      .map(
        (corner) => Offset(
          image.left + corner.dx * image.width,
          image.top + corner.dy * image.height,
        ),
      )
      .toList();
  for (var corner = 0; corner < 4; corner++) {
    final from = centre(corner);
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 50));
    const steps = 12;
    for (var i = 1; i <= steps; i++) {
      await gesture.moveTo(Offset.lerp(from, targets[corner], i / steps)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Applies the pending crop, then continues to enhancement.
Future<void> _applyCropAndContinue(WidgetTester tester) async {
  await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
  await _settle(tester, seconds: 2);
  await tester.tap(find.byKey(ScanKeys.cropNextButton));
  await _settle(tester);
  final prompt = find.byKey(ScanKeys.cropPromptApply);
  if (prompt.evaluate().isNotEmpty) {
    await tester.tap(prompt);
    await _settle(tester);
  }
  await EnhanceRobot(tester).waitUntilVisible();
}

/// Opens the first visible library entry titled [title].
Future<void> _openTitled(WidgetTester tester, String title) async {
  final target = find.text(title).first;
  for (var i = 0; i < 100 && find.text(title).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

/// Waits until no snack bar is showing, so it does not cover the screenshot.
Future<void> _waitForSnackBarToClear(WidgetTester tester) async {
  for (var i = 0; i < 150; i++) {
    if (find.byType(SnackBar).evaluate().isEmpty) break;
    await tester.pump(const Duration(milliseconds: 100));
  }
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, {int seconds = 1}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Holds the current screen until the host script has captured it.
Future<void> _capture(WidgetTester tester, String name) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester);
  final done = File('${Directory.systemTemp.path}/$name.done');
  if (done.existsSync()) done.deleteSync();
  // ignore: avoid_print
  print('STORE_SCREENSHOT_READY:$name');
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (!done.existsSync()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'The host never captured $name. Run this test through '
        'tool/store_assets/capture_app_store_screenshots.sh.',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
  }
}
