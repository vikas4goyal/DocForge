/// Golden tests for the review and crop screens.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
///
/// Capture goldens target the deterministic resolution-status chrome over a
/// flat preview surface; no live plugin or camera frame enters the fixture.
@Tags(['golden'])
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/page_review_screen.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A correction job that writes nothing.
String goldenCorrectionJob(PageCorrectionRequest request) =>
    request.destinationPath;

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

/// A crop that is visibly not rectangular.
const _skewedQuad = PageQuad(
  topLeft: NormalisedPoint(x: 0.12, y: 0.09),
  topRight: NormalisedPoint(x: 0.88, y: 0.16),
  bottomRight: NormalisedPoint(x: 0.84, y: 0.91),
  bottomLeft: NormalisedPoint(x: 0.09, y: 0.85),
);

/// Fixture captures, deterministic down to their rotations.
List<CapturedPage> capturedPages(int count) => List.generate(
  count,
  (index) => CapturedPage(
    id: PageId('golden-page-$index'),
    imagePath: '/golden/page-$index.jpg',
    quad: PageQuad.full,
    rotation: index.isOdd ? PageRotation.quarter : PageRotation.none,
  ),
);

/// A page with nothing applied, so Revert renders disabled.
PageDraft _freshDraft() => const PageDraft(
  id: PageId('golden-page'),
  originalImagePath: '/golden/page.jpg',
);

/// A page that has already been cropped, so Revert renders enabled.
PageDraft _croppedDraft() =>
    _freshDraft().withCrop(const CropOp(quad: _skewedQuad));

/// A renderer that touches no filesystem, so goldens stay byte-stable.
RenderPage _goldenRenderer() => RenderPage(
  cacheDirectory: Directory('/golden'),
  sizeOf: (path) async => const Result<({int width, int height})>.success((
    width: 800,
    height: 600,
  )),
  render: (plan, {required destinationPath, transform, scope}) async =>
      const Result<void>.success(null),
);

class _SeededCaptureCubit extends ScanCaptureCubit {
  _SeededCaptureCubit(this._seeded)
    : super(
        _scanner,
        CapturePage(_scanner),
        DiscardScanSession(FakeScanStagingArea(Directory('/golden')), _scanner),
      );

  static final _scanner = FakeScannerRepository();
  final ScanCaptureState _seeded;

  @override
  ScanCaptureState get state => _seeded;

  @override
  Future<void> start() async {}
}

void main() {
  Widget host(Widget child, Brightness brightness) => MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: child,
  );

  Widget review(List<CapturedPage> pages, Brightness brightness) => host(
    BlocProvider(
      create: (_) => PageReviewCubit(pages),
      child: PageReviewScreen(
        onSave: () {},
        onAddPages: () {},
        onExit: () {},
        onCropPage: (_, _) {},
        onEnhancePage: (_, _) {},
      ),
    ),
    brightness,
  );

  Future<void> pumpCapture(
    WidgetTester tester,
    ScanCaptureState state,
    Size size, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = _SeededCaptureCubit(state);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      host(
        BlocProvider<ScanCaptureCubit>.value(
          value: cubit,
          child: ScanCaptureScreen(
            previewBuilder: (_) => const ColoredBox(color: Color(0xFF202124)),
            onFinished: () {},
            onPageCaptured: (_, _) async {},
            onCancelled: () {},
            onOpenSettings: () {},
            onImportInstead: () {},
          ),
        ),
        brightness,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('capture resolution goldens', () {
    testWidgets('Full resolution phone, light', (tester) async {
      await pumpCapture(
        tester,
        const ScanCaptureState.initial().copyWith(
          status: ScanCaptureStatus.ready,
          activeResolution: SupportedCameraResolution(
            tier: CameraResolutionTier.ultraHd4k,
            width: 4032,
            height: 3024,
          ),
        ),
        _phone,
      );

      await expectLater(
        find.byType(ScanCaptureScreen),
        matchesGoldenFile('goldens/capture_resolution_phone_light.png'),
      );
    });

    testWidgets('fallback tablet, dark', (tester) async {
      await pumpCapture(
        tester,
        const ScanCaptureState.initial().copyWith(
          status: ScanCaptureStatus.ready,
          desiredResolution: DesiredCameraResolution.tier(
            CameraResolutionTier.qhd2k,
          ),
          activeResolution: SupportedCameraResolution(
            tier: CameraResolutionTier.fullHd1080,
            width: 1920,
            height: 1080,
          ),
        ),
        _tablet,
        brightness: Brightness.dark,
      );

      await expectLater(
        find.byType(ScanCaptureScreen),
        matchesGoldenFile('goldens/capture_resolution_tablet_dark.png'),
      );
    });
  });

  Widget crop(PageDraft page, Brightness brightness) => host(
    BlocProvider(
      create: (_) => CropCubit(page, _goldenRenderer()),
      child: CropScreen(onNext: (_) {}, onCancelled: () {}),
    ),
    brightness,
  );

  Future<void> pumpAt(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  group('page review goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, review(capturedPages(4), Brightness.light), _phone);

      await expectLater(
        find.byType(PageReviewScreen),
        matchesGoldenFile('goldens/review_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, review(capturedPages(4), Brightness.dark), _phone);

      await expectLater(
        find.byType(PageReviewScreen),
        matchesGoldenFile('goldens/review_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, review(capturedPages(6), Brightness.light), _tablet);

      await expectLater(
        find.byType(PageReviewScreen),
        matchesGoldenFile('goldens/review_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, review(capturedPages(6), Brightness.dark), _tablet);

      await expectLater(
        find.byType(PageReviewScreen),
        matchesGoldenFile('goldens/review_tablet_dark.png'),
      );
    });

    testWidgets('empty, light', (tester) async {
      await pumpAt(tester, review(const [], Brightness.light), _phone);

      await expectLater(
        find.byType(PageReviewScreen),
        matchesGoldenFile('goldens/review_empty_light.png'),
      );
    });
  });

  group('crop goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, crop(_croppedDraft(), Brightness.light), _phone);

      await expectLater(
        find.byType(CropScreen),
        matchesGoldenFile('goldens/crop_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, crop(_croppedDraft(), Brightness.dark), _phone);

      await expectLater(
        find.byType(CropScreen),
        matchesGoldenFile('goldens/crop_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, crop(_croppedDraft(), Brightness.light), _tablet);

      await expectLater(
        find.byType(CropScreen),
        matchesGoldenFile('goldens/crop_tablet_light.png'),
      );
    });

    testWidgets('full page, light', (tester) async {
      await pumpAt(tester, crop(_freshDraft(), Brightness.light), _phone);

      await expectLater(
        find.byType(CropScreen),
        matchesGoldenFile('goldens/crop_full_page_light.png'),
      );
    });
  });
}
