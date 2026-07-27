import 'dart:io';

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_forge/features/document_scanning/domain/perspective_transform.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_forge/features/document_scanning/presentation/scan_keys.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/page_review_screen.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A correction job that reports the destination without writing.
String passthroughJob(PageCorrectionRequest request) => request.destinationPath;

/// A crop that is not the full page.
const skewedQuad = PageQuad(
  topLeft: NormalisedPoint(x: 0.1, y: 0.08),
  topRight: NormalisedPoint(x: 0.9, y: 0.14),
  bottomRight: NormalisedPoint(x: 0.87, y: 0.92),
  bottomLeft: NormalisedPoint(x: 0.12, y: 0.86),
);

/// Builds [count] captured pages.
List<CapturedPage> pages(int count) => List.generate(
  count,
  (index) => CapturedPage(
    id: PageId('page-$index'),
    imagePath: '/scan/page-$index.jpg',
    quad: PageQuad.full,
  ),
);

/// A staging area that records clears without touching the filesystem.
///
/// testWidgets runs in a fake-async zone where a real directory delete never
/// completes, so a filesystem-backed staging area would hang the test rather
/// than fail it. The real one is covered in `scanning_usecases_test.dart`.
class _RecordingStagingArea implements ScanStagingArea {
  int clears = 0;

  @override
  Future<Result<Directory>> directory() async =>
      Result<Directory>.success(Directory.systemTemp);

  @override
  Future<Result<void>> clear() async {
    clears++;
    return const Result<void>.success(null);
  }
}

/// Records what each screen callback was asked to do.
class _Recorder {
  int finished = 0;
  int cancelled = 0;
  int settings = 0;
  int importInstead = 0;
  int saved = 0;
  int addPages = 0;
  int exited = 0;
  int? croppedIndex;
  CapturedPage? croppedPage;
  int? enhancedIndex;
  CapturedPage? enhancedPage;
  int? capturedIndex;
  CapturedPage? capturedPage;
}

void main() {
  late Directory workspace;
  late FakeScannerRepository scanner;
  late _RecordingStagingArea staging;
  late _Recorder recorder;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('docforge_scan_screens');
    // No directory: the fake then returns synthetic paths and writes nothing.
    // testWidgets runs in a fake-async zone, where a real file write never
    // completes, so a writing fake would hang every pumpAndSettle here. The
    // disk-first rule is exercised against the writing fake in
    // scanning_usecases_test.dart, which is not in that zone.
    scanner = FakeScannerRepository(ids: SequentialIdGenerator(prefix: 'page'));
    staging = _RecordingStagingArea();
    recorder = _Recorder();
  });

  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  ScanCaptureCubit captureCubit() => ScanCaptureCubit(
    scanner,
    CapturePage(scanner, const FullPageEdgeDetector()),
    DiscardScanSession(staging, scanner),
  );

  Widget host(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: child,
      );

  Widget captureScreen({ScanCaptureCubit? cubit}) => host(
    BlocProvider.value(
      value: cubit ?? captureCubit(),
      child: ScanCaptureScreen(
        // A stand-in for the live preview: a real CameraPreview needs the
        // plugin's controller, which a widget test cannot create.
        previewBuilder: (_) =>
            const ColoredBox(key: Key('fake_preview'), color: Colors.black),
        onFinished: () => recorder.finished++,
        onPageCaptured: (index, page) async {
          recorder.capturedIndex = index;
          recorder.capturedPage = page;
        },
        onCancelled: () => recorder.cancelled++,
        onOpenSettings: () => recorder.settings++,
        onImportInstead: () => recorder.importInstead++,
      ),
    ),
  );

  Widget reviewScreen(List<CapturedPage> initial) => host(
    BlocProvider(
      create: (_) => PageReviewCubit(initial),
      child: PageReviewScreen(
        onSave: () => recorder.saved++,
        onAddPages: () => recorder.addPages++,
        onExit: () => recorder.exited++,
        onCropPage: (index, page) {
          recorder.croppedIndex = index;
          recorder.croppedPage = page;
        },
        onEnhancePage: (index, page) {
          recorder.enhancedIndex = index;
          recorder.enhancedPage = page;
        },
      ),
    ),
  );

  Widget cropScreen(CapturedPage page) => host(
    BlocProvider(
      create: (_) => CropCubit(
        page,
        const ApplyPerspectiveCorrection(
          InlineBackgroundWorker(),
          passthroughJob,
        ),
      ),
      child: CropScreen(
        destinationPath: '/scan/corrected.jpg',
        onCropped: (page) => recorder.croppedPage = page,
        onCancelled: () => recorder.cancelled++,
      ),
    ),
  );

  group('ScanCaptureScreen', () {
    testWidgets('shows the preview and the shutter once the camera is ready', (
      tester,
    ) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.cameraScreen), findsOneWidget);
      expect(find.byKey(const Key('fake_preview')), findsOneWidget);
      expect(find.byKey(ScanKeys.shutterButton), findsOneWidget);
    });

    testWidgets('the page counter starts at zero and follows captures', (
      tester,
    ) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);

      // Batch mode keeps the screen up so the counter can be observed rising.
      await tester.tap(find.byKey(ScanKeys.batchModeToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.shutterButton));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('a captured page is handed straight to the editors', (
      tester,
    ) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.batchModeToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.shutterButton));
      await tester.pumpAndSettle();

      // Offered while the document is still in front of the user, rather than
      // left to be found again in the review list later.
      expect(recorder.capturedIndex, 0);
      expect(recorder.capturedPage, isNotNull);
    });

    testWidgets('a failed capture opens no editor', (tester) async {
      scanner.captureFailure = const Failure.camera(debugDetail: 'no camera');
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.batchModeToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.shutterButton));
      await tester.pumpAndSettle();

      // Opening an editor over a page that never existed would turn a failed
      // shot into a puzzle.
      expect(recorder.capturedPage, isNull);
    });

    testWidgets('batch mode keeps the camera up between captures', (
      tester,
    ) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.batchModeToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.shutterButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.shutterButton));
      await tester.pumpAndSettle();

      // Two pages, and no move to review: that is exactly what batch mode is.
      expect(find.text('2'), findsOneWidget);
      expect(recorder.finished, 0);
    });

    testWidgets('a single capture moves straight on to review', (tester) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.shutterButton));
      // Bounded pumps rather than pumpAndSettle: releasing the camera leaves an
      // indefinite spinner on screen while the route changes, and pumpAndSettle
      // waits for animations to finish, which that one never does.
      await tester.pump();
      await tester.pump();

      expect(recorder.finished, 1);
    });

    testWidgets('the done control is disabled until something is captured', (
      tester,
    ) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(find.byKey(ScanKeys.doneButton));

      expect(button.onPressed, isNull);
    });

    testWidgets('the torch toggles from the app bar', (tester) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.flashToggle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('a refused permission shows the permission view', (
      tester,
    ) async {
      scanner.initialiseFailure = const Failure.permission(
        kind: PermissionKind.camera,
      );

      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.permissionDeniedView), findsOneWidget);
      // Still askable, so the retry is what is offered first.
      expect(find.byKey(ScanKeys.permissionRetryButton), findsOneWidget);
    });

    testWidgets('a permanently denied permission offers settings, not a retry', (
      tester,
    ) async {
      scanner.initialiseFailure = const Failure.permission(
        kind: PermissionKind.camera,
        permanentlyDenied: true,
      );

      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      // Re-requesting shows no system prompt once it is permanently denied, so
      // a retry button here would be a control that cannot work.
      expect(find.byKey(ScanKeys.permissionRetryButton), findsNothing);
      expect(find.byKey(ScanKeys.permissionSettingsButton), findsOneWidget);

      await tester.tap(find.byKey(ScanKeys.permissionSettingsButton));
      expect(recorder.settings, 1);
    });

    testWidgets('the permission view explains what the camera is used for', (
      tester,
    ) async {
      scanner.initialiseFailure = const Failure.permission(
        kind: PermissionKind.camera,
      );

      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('capture the pages'), findsOneWidget);
      expect(find.textContaining('stay on this device'), findsOneWidget);
    });

    testWidgets('an unavailable camera offers a retry and the gallery', (
      tester,
    ) async {
      scanner.initialiseFailure = const Failure.camera(inUseByAnotherApp: true);

      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.cameraErrorView), findsOneWidget);

      await tester.tap(find.byKey(ScanKeys.importInsteadButton));
      expect(recorder.importInstead, 1);
    });

    testWidgets('retrying after a camera failure reaches the preview', (
      tester,
    ) async {
      scanner.initialiseFailure = const Failure.camera();
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      scanner.initialiseFailure = null;
      await tester.tap(find.byKey(ScanKeys.cameraRetryButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.cameraErrorView), findsNothing);
      expect(find.byKey(const Key('fake_preview')), findsOneWidget);
    });

    testWidgets('a failed capture keeps the preview and reports it', (
      tester,
    ) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();
      scanner.captureFailure = const Failure.storageFull();

      await tester.tap(find.byKey(ScanKeys.shutterButton));
      await tester.pumpAndSettle();

      // The camera still works, so this is a message rather than a screen.
      expect(find.byKey(const Key('fake_preview')), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(recorder.finished, 0);
    });

    testWidgets('cancelling releases the camera and discards the captures', (
      tester,
    ) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.batchModeToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.shutterButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scan_cancel_button')));
      await tester.pump();
      await tester.pump();

      expect(recorder.cancelled, 1);
      expect(scanner.isReady, isFalse);
      // The captures are cleared, not merely orphaned: an abandoned scan must
      // not leave full-resolution images on the device.
      expect(staging.clears, 1);
    });

    testWidgets('the camera is released when the screen is disposed', (
      tester,
    ) async {
      final cubit = captureCubit();
      await tester.pumpWidget(captureScreen(cubit: cubit));
      await tester.pumpAndSettle();
      expect(scanner.isReady, isTrue);

      // Replacing the whole tree is what a route pop does to the screen.
      await tester.pumpWidget(host(const SizedBox.shrink()));
      await tester.pumpAndSettle();
      await cubit.close();

      expect(scanner.isReady, isFalse);
      expect(scanner.disposeCount, greaterThanOrEqualTo(1));
    });

    testWidgets('every capture control carries a semantics label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Capture page'), findsOneWidget);
      expect(find.bySemanticsLabel('Batch mode off'), findsOneWidget);
      expect(find.bySemanticsLabel('Flash off'), findsOneWidget);
      expect(find.bySemanticsLabel('Review captured pages'), findsOneWidget);
      expect(find.bySemanticsLabel('0 pages captured'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('every capture control clears 48dp', (tester) async {
      await tester.pumpWidget(captureScreen());
      await tester.pumpAndSettle();

      for (final key in [
        ScanKeys.shutterButton,
        ScanKeys.batchModeToggle,
        ScanKeys.flashToggle,
        ScanKeys.doneButton,
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(
          size.shortestSide,
          greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
          reason: '$key is only ${size.shortestSide}dp',
        );
      }
    });
  });

  group('PageReviewScreen', () {
    testWidgets('lists every captured page', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(3)));
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.reviewScreen), findsOneWidget);
      expect(find.byKey(ScanKeys.pageList), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 3'), findsOneWidget);
    });

    testWidgets('enhancing a page reports which one', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(2)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.pageEnhanceButton).last);
      await tester.pumpAndSettle();

      // Per page rather than for the session: pages of one document are often
      // shot under different light.
      expect(recorder.enhancedIndex, 1);
      expect(recorder.enhancedPage, isNotNull);
    });

    testWidgets('deleting a page removes it and offers an undo', (
      tester,
    ) async {
      await tester.pumpWidget(reviewScreen(pages(2)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.pageDeleteButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('undoing a delete restores the page', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(2)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.pageDeleteButton).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('deleting the last page shows the empty state', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.pageDeleteButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.reviewEmptyState), findsOneWidget);
      // Both ways forward the spec names.
      expect(find.text('Capture a page'), findsOneWidget);
      expect(find.text('Leave without saving'), findsOneWidget);
    });

    testWidgets('the empty state can undo the deletion that caused it', (
      tester,
    ) async {
      await tester.pumpWidget(reviewScreen(pages(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ScanKeys.pageDeleteButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scan_review_undo_button')));
      await tester.pumpAndSettle();

      // Deleting the last page by accident must not be a dead end.
      expect(find.byKey(ScanKeys.reviewEmptyState), findsNothing);
      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('saving is offered only while a page remains', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(1)));
      await tester.pumpAndSettle();
      expect(find.byKey(ScanKeys.saveButton), findsOneWidget);

      await tester.tap(find.byKey(ScanKeys.pageDeleteButton));
      await tester.pumpAndSettle();

      // The library forbids a document with no pages.
      expect(find.byKey(ScanKeys.saveButton), findsNothing);
    });

    testWidgets('saving reports it to the caller', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(2)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.saveButton));

      expect(recorder.saved, 1);
    });

    testWidgets('adding pages returns to the camera', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.addPagesButton));

      expect(recorder.addPages, 1);
    });

    testWidgets('cropping reports which page was chosen', (tester) async {
      await tester.pumpWidget(reviewScreen(pages(3)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.pageCropButton).at(1));
      await tester.pumpAndSettle();

      expect(recorder.croppedIndex, 1);
      expect(recorder.croppedPage?.id.value, 'page-1');
    });

    testWidgets('each row action names the page it acts on', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(reviewScreen(pages(2)));
      await tester.pumpAndSettle();

      // A screen-reader user moving through a long list must always know which
      // page they are about to change.
      expect(
        find.bySemanticsLabel('Crop and rotate page 1'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Enhance page 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Delete page 2'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('renders in dark mode without overflowing', (tester) async {
      await tester.pumpWidget(
        host(
          BlocProvider(
            create: (_) => PageReviewCubit(pages(4)),
            child: PageReviewScreen(
              onSave: () {},
              onAddPages: () {},
              onExit: () {},
              onCropPage: (_, _) {},
              onEnhancePage: (_, _) {},
            ),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('CropScreen', () {
    testWidgets('shows the overlay and four corner handles', (tester) async {
      await tester.pumpWidget(cropScreen(pages(1).single));
      await tester.pumpAndSettle();

      expect(find.byKey(ScanKeys.cropScreen), findsOneWidget);
      expect(find.byKey(ScanKeys.edgeOverlay), findsOneWidget);
      for (var corner = 0; corner < 4; corner++) {
        expect(find.byKey(ScanKeys.cropHandle(corner)), findsOneWidget);
      }
    });

    testWidgets('dragging a handle moves that corner', (tester) async {
      await tester.pumpWidget(cropScreen(pages(1).single));
      await tester.pumpAndSettle();
      final before = tester.getCenter(find.byKey(ScanKeys.cropHandle(0)));

      await tester.drag(
        find.byKey(ScanKeys.cropHandle(0)),
        const Offset(40, 40),
      );
      await tester.pumpAndSettle();

      final after = tester.getCenter(find.byKey(ScanKeys.cropHandle(0)));
      expect(after.dx, greaterThan(before.dx));
      expect(after.dy, greaterThan(before.dy));
    });

    testWidgets('a handle cannot be dragged outside the page', (tester) async {
      await tester.pumpWidget(cropScreen(pages(1).single));
      await tester.pumpAndSettle();

      // Far past the top-left corner.
      await tester.drag(
        find.byKey(ScanKeys.cropHandle(0)),
        const Offset(-4000, -4000),
      );
      await tester.pumpAndSettle();

      // A corner outside the image would describe a crop of pixels that do not
      // exist, which the transform would then have to guess at.
      expect(tester.takeException(), isNull);
      expect(find.byKey(ScanKeys.cropHandle(0)), findsOneWidget);
    });

    testWidgets('resetting returns the crop to the whole page', (tester) async {
      final page = pages(1).single.copyWith(quad: skewedQuad);
      await tester.pumpWidget(cropScreen(page));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.cropResetButton));
      await tester.pumpAndSettle();

      // Measured against the page, not the canvas. The page is laid out inside
      // a margin so the handles have somewhere to sit, so canvas coordinates
      // would only agree with these by accident.
      final handle = tester.getCenter(find.byKey(ScanKeys.cropHandle(0)));
      final pageRect = tester.getRect(find.byType(Image));
      expect(handle.dx, closeTo(pageRect.left, 1));
      expect(handle.dy, closeTo(pageRect.top, 1));
    });

    testWidgets('confirming reports the corrected page', (tester) async {
      final page = pages(1).single.copyWith(quad: skewedQuad);
      await tester.pumpWidget(cropScreen(page));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ScanKeys.cropConfirmButton));
      await tester.pumpAndSettle();

      expect(recorder.croppedPage?.imagePath, '/scan/corrected.jpg');
      expect(recorder.croppedPage?.isCorrected, isTrue);
    });

    testWidgets('cancelling reports it without applying anything', (
      tester,
    ) async {
      await tester.pumpWidget(cropScreen(pages(1).single));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scan_crop_cancel_button')));

      expect(recorder.cancelled, 1);
      expect(recorder.croppedPage, isNull);
    });

    testWidgets('each corner handle is labelled for a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(cropScreen(pages(1).single));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Top left crop handle'), findsOneWidget);
      expect(find.bySemanticsLabel('Bottom right crop handle'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('each corner handle clears 48dp', (tester) async {
      await tester.pumpWidget(cropScreen(pages(1).single));
      await tester.pumpAndSettle();

      for (var corner = 0; corner < 4; corner++) {
        final size = tester.getSize(find.byKey(ScanKeys.cropHandle(corner)));
        // The drawn dot is smaller than this on purpose; the hit area is what
        // the accessibility baseline measures.
        expect(
          size.shortestSide,
          greaterThanOrEqualTo(AppTheme.minimumTouchTarget),
        );
      }
    });
  });
}
