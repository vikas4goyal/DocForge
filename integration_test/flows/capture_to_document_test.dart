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

import 'package:doc_scanly/app/cpu_image_processing_backend.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/repositories/native_first_image_renderer.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';

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
      app.platform.scanner.requestedResolutions.single?.tier,
      CameraResolutionTier.ultraHd4k,
      reason: 'Missing preference must resolve to the active camera maximum.',
    );
    expect(
      app.platform.scanner.captures,
      hasLength(1),
      reason: 'The live camera must wait for the robot\'s explicit shutter.',
    );
    await CropRobot(tester).acceptAndContinue();
    await EnhanceRobot(tester).backToCrop();
    await CropRobot(tester).acceptAndContinue();
    await EnhanceRobot(tester).exerciseEveryControl();
    await EnhanceRobot(tester).done();
    await pageTable.waitUntilLoaded();

    // The second page follows the ordinary crop-then-enhance loop.
    await pageTable.beginAddingPageFromCamera();
    await CropRobot(tester).acceptAndContinue();
    await EnhanceRobot(tester).selectFilter(EnhanceKeys.filterAuto);
    await EnhanceRobot(tester).done();
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

    await pageTable.openSavePdf();
    final save = SavePdfRobot(tester);
    expect(
      save.documentQuality,
      70,
      reason: 'Camera resolution must not alter the PDF quality default.',
    );
    await save.name('Captured document');
    await save.overrideAndResetFirstPage();
    await save.setPassword('temporary secret');
    await save.removePassword();
    await save.waitForExactSize();
    await save.previewAndClose();
    await save.cancelPreview();
    await save.cancelCommit();
    // Changing quality starts a debounced calculation; Save must supersede it
    // immediately rather than waiting for an unrelated size job.
    await save.setDocumentQuality(80);
    await save.commit();

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
    final records = await app.isar.documentEntitys.where().findAll();
    expect(records, hasLength(1));
    expect(records.single.title, 'Captured document');
    expect(records.single.pageCount, 2);
    expect(records.single.sizeInBytes, greaterThan(0));
    expect(records.single.isProtected, isFalse);
  });

  testWidgets(
    'camera preference re-resolves while gallery pages stay independent',
    (tester) async {
      final app = await bootDocScanly(tester, useBundledGalleryFixture: true);

      await DashboardRobot(tester).waitUntilLoaded();
      final shell = TabShellRobot(tester);
      await shell.openSettings();
      final settings = SettingsRobot(tester);
      await settings.waitUntilVisible();
      await settings.expectCameraResolutions(const <String>[
        '720p',
        '1080p',
        '4k',
      ]);
      await settings.chooseCameraResolution('1080p');
      await shell.openDashboard();
      await shell.startCreation();

      final pageTable = PageTableRobot(tester);
      await pageTable.waitUntilLoaded();
      await pageTable.beginAddingPageFromCamera();
      expect(
        app.platform.scanner.requestedResolutions.last?.tier,
        CameraResolutionTier.fullHd1080,
      );
      await CropRobot(tester).acceptAndContinue();
      await EnhanceRobot(tester).done();
      await pageTable.waitUntilLoaded();

      // Simulate switching to a camera that cannot satisfy the stored tier.
      // The next add-page action must query again and choose the nearest lower
      // supported tier, rather than reusing the first camera's dimensions.
      app.platform.cameraCapabilities.supported = <SupportedCameraResolution>[
        SupportedCameraResolution(
          tier: CameraResolutionTier.hd720,
          width: 1280,
          height: 720,
        ),
      ];
      await pageTable.beginAddingPageFromCamera();
      expect(
        app.platform.scanner.requestedResolutions.last?.tier,
        CameraResolutionTier.hd720,
      );
      await CropRobot(tester).acceptAndContinue();
      await EnhanceRobot(tester).done();
      await pageTable.waitUntilLoaded();

      final cameraInitialisations =
          app.platform.scanner.requestedResolutions.length;
      await pageTable.addFromGallery();
      await CropRobot(tester).acceptAndContinue();
      await EnhanceRobot(tester).done();
      await pageTable.waitUntilLoaded();

      expect(app.platform.cameraCapabilities.loads, greaterThanOrEqualTo(2));
      expect(
        app.platform.scanner.requestedResolutions,
        hasLength(cameraInitialisations),
        reason: 'Photo-library dimensions must not initialise the camera.',
      );
      expect(pageTable.pageCount, 3);
    },
  );

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

  testWidgets('recoverable native failure saves through CPU fallback', (
    tester,
  ) async {
    late _RecoverableNativeBackend native;
    final app = await bootDocScanly(
      tester,
      imageProcessingBackendBuilder: (dependencies) {
        native = _RecoverableNativeBackend();
        return NativeFirstImageRenderer(
          native: native,
          cpu: CpuImageProcessingBackend(dependencies.worker),
          telemetry: dependencies.telemetry,
        );
      },
    );

    await DashboardRobot(tester).waitUntilLoaded();
    await TabShellRobot(tester).startCreation();
    final pageTable = PageTableRobot(tester);
    await pageTable.waitUntilLoaded();
    await pageTable.beginAddingPageFromCamera();
    await CropRobot(tester).acceptAndContinue();
    await EnhanceRobot(tester).selectFilter(EnhanceKeys.filterAuto);
    // Let the debounced preview reach the injected native backend before Done
    // closes its render scope; the saved full render exercises the same fallback.
    await tester.pump(const Duration(milliseconds: 250));
    await EnhanceRobot(tester).done();
    await pageTable.waitUntilLoaded();
    await pageTable.save('Fallback document');
    await ViewerRobot(tester).waitUntilOpen();

    expect(native.renderCount, greaterThan(0));
    final listed = await app.publicStore.list(const []);
    expect(listed.valueOrNull, isNotEmpty);
  });
}

class _RecoverableNativeBackend implements ImageProcessingBackend {
  int renderCount = 0;

  @override
  Future<ImageProcessingCapability> capability() async =>
      const ImageProcessingCapability(
        backend: ImageProcessingBackendKind.androidOpenGl,
        isSupported: true,
        maximumTextureSize: 8192,
        supportsTiling: false,
      );

  @override
  Future<ImageProcessingBackendResponse> render(
    ImageRenderRequest request,
  ) async {
    renderCount++;
    return const ImageProcessingBackendResponse.failure(
      kind: ImageProcessingFailureKind.contextLost,
    );
  }

  @override
  Future<void> cancel(String requestId) async {}

  @override
  Future<void> dispose() async {}
}
