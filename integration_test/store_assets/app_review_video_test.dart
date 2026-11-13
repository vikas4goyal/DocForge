/// Walks the real app through a typical user session for an App Review
/// screen recording.
///
/// Not part of the flow suite: it asserts nothing and is skipped unless
/// `STORE_VIDEO=true` is defined. Run it through
/// `tool/store_assets/record_app_review_video.sh`, which boots the simulator,
/// records the screen and stops when this test says it has finished.
///
/// Handshake: the test prints `STORE_VIDEO_READY` and waits for the host to
/// drop `video.started` into the app's temporary directory before it composes
/// the app, so the recording opens on launch. It prints `STORE_VIDEO_DONE`
/// once the last screen has been held.
///
/// The simulator has no camera, so "camera" captures come from a rendered
/// paper photo, the same way the App Store screenshots are produced.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:doc_scanly/features/onboarding/presentation/onboarding_keys.dart';
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

const _enabled = bool.fromEnvironment('STORE_VIDEO');

void main() {
  _NoTouchIndicatorBinding().shouldPropagateDevicePointerEvents = true;

  testWidgets(
    'App Review video',
    skip: !_enabled,
    timeout: const Timeout(Duration(minutes: 10)),
    (tester) async {
      final staging = await Directory.systemTemp.createTemp('store_video_');
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

      await _waitForRecording(tester);

      await bootDocScanly(
        tester,
        onboardingComplete: false,
        pickedFiles: pdfs,
        captureImageBytes: cameraPhoto,
        galleryImages: photoPaths.sublist(1),
      );

      // 1. First launch: onboarding.
      await _onboarding(tester);

      final dashboard = DashboardRobot(tester);
      final shell = TabShellRobot(tester);
      final viewer = ViewerRobot(tester);
      await dashboard.waitUntilLoaded();
      await _hold(tester, 2);

      // 2. Import existing PDFs from Files.
      await dashboard.openImportSheet();
      await _hold(tester, 2);
      await ImportRobot(tester).importFromFiles();
      await tester.pump(const Duration(milliseconds: 500));
      if (viewer.isVisible) await viewer.goBack();
      await dashboard.waitUntilLoaded();
      await dashboard.waitForDocuments();
      for (final id in dashboard.visibleDocumentIds) {
        await dashboard.waitForDocumentThumbnail(id);
      }
      await _waitForSnackBarToClear(tester);
      await _hold(tester, 3);

      // 3. Scan a new document: capture, crop, enhance, add pages, save.
      await shell.startCreation();
      final pageTable = PageTableRobot(tester);
      await pageTable.waitUntilLoaded();
      await _hold(tester, 2);
      await pageTable.beginAddingPageFromCamera();
      await _cropToPaper(tester, samplePhotos[0]);
      await _hold(tester, 2);
      await _applyCropAndContinue(tester);
      final enhance = EnhanceRobot(tester);
      await enhance.waitUntilVisible();
      await _hold(tester, 1);
      await enhance.selectFilter(EnhanceKeys.filterMagicColour);
      await _hold(tester, 3);
      await enhance.done();
      await pageTable.waitUntilLoaded();
      await _hold(tester, 1);

      // Two more pages from the photo library.
      await pageTable.addFromGallery();
      for (final photo in samplePhotos.skip(1)) {
        await CropRobot(tester).waitUntilVisible();
        await _cropToPaper(tester, photo);
        await _hold(tester, 1);
        await _applyCropAndContinue(tester);
        await EnhanceRobot(tester).selectFilter(EnhanceKeys.filterAuto);
        await _hold(tester, 2);
        await EnhanceRobot(tester).done();
      }
      await pageTable.waitUntilLoaded();
      await _hold(tester, 3);

      await pageTable.openSavePdf();
      final save = SavePdfRobot(tester);
      await save.name('Grocery Receipt');
      await save.waitForExactSize();
      await _hold(tester, 3);
      await save.commit();

      // 4. View the new PDF.
      await viewer.waitUntilOpen();
      await _hold(tester, 4);
      await viewer.goBack();
      await dashboard.waitUntilLoaded();
      await _hold(tester, 2);

      // 5. PDF tools: compress, watermark, password.
      await _openTitled(tester, 'Scanned Paperwork');
      await viewer.waitUntilOpen();
      await _hold(tester, 2);
      await viewer.openCompress();
      await CompressPdfRobot(tester).waitUntilCalculated();
      await _hold(tester, 4);
      await PdfEditRobot(tester).close();
      await viewer.waitUntilOpen();
      await viewer.goBack();
      await dashboard.waitUntilLoaded();

      await _openTitled(tester, 'Apartment Lease Agreement');
      await viewer.waitUntilOpen();
      await _hold(tester, 2);
      await viewer.openWatermark();
      final editor = PdfEditRobot(tester);
      await editor.waitUntilFocused();
      await _hold(tester, 1);
      await tester.enterText(
        find.byKey(PdfEditKeys.watermarkTextField),
        'CONFIDENTIAL',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await _hold(tester, 3);
      await editor.close();
      await viewer.waitUntilOpen();
      await _hold(tester, 1);

      await viewer.openPassword();
      await editor.waitUntilFocused();
      await _hold(tester, 1);
      await editor.protectWith('demo1234');
      await _hold(tester, 3);
      await editor.finishResult();
      await dashboard.waitUntilLoaded();
      await _waitForSnackBarToClear(tester);
      await _hold(tester, 2);

      // 6. Search. Opening a document lower in the grid can leave the library
      // scrolled past the search field, so scroll back up as a user would.
      for (
        var i = 0;
        i < 5 && find.byKey(DashboardKeys.searchField).evaluate().isEmpty;
        i++
      ) {
        await tester.fling(
          find.byType(Scrollable).first,
          const Offset(0, 600),
          1500,
        );
        await _hold(tester, 1);
      }
      await dashboard.search('receipt');
      FocusManager.instance.primaryFocus?.unfocus();
      await _hold(tester, 3);

      // 7. Share options.
      await _openTitled(tester, 'Grocery Receipt');
      await viewer.waitUntilOpen();
      await _hold(tester, 1);
      await viewer.openShare();
      await _hold(tester, 4);
      await tester.binding.handlePopRoute();
      await _hold(tester, 1);
      await viewer.goBack();
      await dashboard.waitUntilLoaded();

      // 8. Settings: app lock and storage.
      await shell.openSettings();
      final settings = SettingsRobot(tester);
      await settings.waitUntilVisible();
      await _hold(tester, 2);
      await settings.toggleAppLock();
      await _hold(tester, 3);
      await settings.openStorageDetails();
      await _hold(tester, 4);
      await settings.closeDetails();
      await _hold(tester, 2);

      // ignore: avoid_print
      print('STORE_VIDEO_DONE');
      await _hold(tester, 2);
    },
  );
}

/// Hides the live-test touch crosshairs, so the recording looks like a person
/// using the app rather than a test driving it.
///
/// The binding only draws crosshairs for events whose source is the test, so
/// every scripted event is dispatched as a device event instead, which goes to
/// the framework unchanged once [shouldPropagateDevicePointerEvents] is set.
class _NoTouchIndicatorBinding extends IntegrationTestWidgetsFlutterBinding {
  @override
  void handlePointerEventForSource(
    PointerEvent event, {
    TestBindingEventSource source = TestBindingEventSource.device,
  }) {
    super.handlePointerEventForSource(event);
  }
}

/// Shows each onboarding step long enough to read.
Future<void> _onboarding(WidgetTester tester) async {
  await _waitForKey(tester, OnboardingKeys.welcomeScreen);
  await _hold(tester, 3);
  await tester.tap(find.byKey(OnboardingKeys.welcomeContinueButton));
  await _waitForKey(tester, OnboardingKeys.privacyScreen);
  await _hold(tester, 4);
  await tester.tap(find.byKey(OnboardingKeys.privacyContinueButton));
  await _waitForKey(tester, OnboardingKeys.permissionScreen);
  await _hold(tester, 3);
  await tester.tap(find.byKey(OnboardingKeys.permissionSkipButton));
  await _hold(tester, 1);
}

Future<void> _waitForKey(WidgetTester tester, Key key) async {
  for (var i = 0; i < 300 && find.byKey(key).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Drags the crop corners onto the sheet of paper in [photo].
Future<void> _cropToPaper(WidgetTester tester, PaperPhoto photo) async {
  await _hold(tester, 1);
  Offset centre(int corner) =>
      tester.getCenter(find.byKey(ScanKeys.cropHandle(corner)));
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
    await _pumpReal(tester, 80);
    const steps = 20;
    for (var i = 1; i <= steps; i++) {
      await gesture.moveTo(Offset.lerp(from, targets[corner], i / steps)!);
      await _pumpReal(tester, 25);
    }
    await gesture.up();
    await _pumpReal(tester, 200);
  }
}

/// Applies the pending crop, then continues to enhancement.
Future<void> _applyCropAndContinue(WidgetTester tester) async {
  await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
  await _hold(tester, 2);
  await tester.tap(find.byKey(ScanKeys.cropNextButton));
  await _hold(tester, 1);
  final prompt = find.byKey(ScanKeys.cropPromptApply);
  if (prompt.evaluate().isNotEmpty) {
    await tester.tap(prompt);
    await _hold(tester, 1);
  }
  await EnhanceRobot(tester).waitUntilVisible();
}

/// Opens the first visible library entry titled [title].
Future<void> _openTitled(WidgetTester tester, String title) async {
  for (var i = 0; i < 100 && find.text(title).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final target = find.text(title).first;
  await tester.ensureVisible(target);
  await _hold(tester, 1);
  await tester.tap(target);
  await tester.pump();
}

/// Waits until no snack bar is showing.
Future<void> _waitForSnackBarToClear(WidgetTester tester) async {
  for (var i = 0; i < 150; i++) {
    if (find.byType(SnackBar).evaluate().isEmpty) break;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Keeps rendering for [seconds] of wall-clock time, so a viewer can follow.
Future<void> _hold(WidgetTester tester, int seconds) =>
    _pumpReal(tester, seconds * 1000);

Future<void> _pumpReal(WidgetTester tester, int milliseconds) async {
  final end = DateTime.now().add(Duration(milliseconds: milliseconds));
  do {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 16)),
    );
  } while (DateTime.now().isBefore(end));
}

/// Announces that the test is ready and waits for the host to start recording.
Future<void> _waitForRecording(WidgetTester tester) async {
  final started = File('${Directory.systemTemp.path}/video.started');
  if (started.existsSync()) started.deleteSync();
  // ignore: avoid_print
  print('STORE_VIDEO_READY');
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (!started.existsSync()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'The host never started recording. Run this test through '
        'tool/store_assets/record_app_review_video.sh.',
      );
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
  }
}
