/// Widget previews for the scanning flow.
///
/// Every preview is fed by fixtures through a seeded Cubit, so nothing here
/// opens a camera, writes a file or spawns an isolate (`design.md` §15). The
/// live preview is replaced by a flat placeholder for the same reason: a real
/// `CameraPreview` needs a plugin controller that no preview can create.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fakes/fake_cubit.dart';
import 'package:doc_scanly/core/previews/fakes/fake_page_renderer.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/page_review_screen.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:doc_scanly/features/document_scanning/presentation/widgets/scan_error_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A scanner that opens nothing.
FakeScannerRepository _inertScanner() =>
    FakeScannerRepository(ids: SequentialIdGenerator(prefix: 'preview'));

/// A staging area that touches no filesystem.
class _InertStaging implements ScanStagingArea {
  const _InertStaging();

  @override
  Future<Result<Directory>> directory() async =>
      Result<Directory>.success(Directory.systemTemp);

  @override
  Future<Result<void>> clear() async => const Result<void>.success(null);
}

/// A [ScanCaptureCubit] frozen at a chosen state.
///
/// `start` is overridden to do nothing: the capture screen opens the camera on
/// its first frame, which would otherwise replace the seeded state and make
/// every preview identical.
class _PreviewCaptureCubit extends ScanCaptureCubit
    with SeededCubit<ScanCaptureState> {
  _PreviewCaptureCubit(ScanCaptureState state, FakeScannerRepository scanner)
    : super(
        scanner,
        CapturePage(scanner, const FullPageEdgeDetector()),
        DiscardScanSession(const _InertStaging(), scanner),
      ) {
    seed(state);
  }

  @override
  Future<void> start() async {}
}

/// Fixture captures for the review and crop previews.
List<CapturedPage> _capturedPages(int count) => List.generate(
  count,
  (index) => CapturedPage(
    id: PageId('preview-page-$index'),
    imagePath: '/preview/page-$index.jpg',
    quad: PageQuad.full,
    rotation: index.isOdd ? PageRotation.quarter : PageRotation.none,
  ),
);

/// A crop that is visibly not rectangular.
const _skewedQuad = PageQuad(
  topLeft: NormalisedPoint(x: 0.12, y: 0.09),
  topRight: NormalisedPoint(x: 0.88, y: 0.16),
  bottomRight: NormalisedPoint(x: 0.84, y: 0.91),
  bottomLeft: NormalisedPoint(x: 0.09, y: 0.85),
);

/// Stands in for the live camera preview.
Widget _previewPlaceholder(BuildContext context) => const ColoredBox(
  color: Color(0xFF202020),
  child: Center(
    child: Text('Camera preview', style: TextStyle(color: Colors.white54)),
  ),
);

Widget _capture(ScanCaptureState state) {
  final scanner = _inertScanner();

  return BlocProvider<ScanCaptureCubit>(
    create: (_) => _PreviewCaptureCubit(state, scanner),
    child: ScanCaptureScreen(
      previewBuilder: _previewPlaceholder,
      onFinished: () {},
      onPageCaptured: (_, _) async {},
      onCancelled: () {},
      onOpenSettings: () {},
      onImportInstead: () {},
    ),
  );
}

Widget _review(List<CapturedPage> pages) => BlocProvider<PageReviewCubit>(
  create: (_) => PageReviewCubit(pages),
  child: PageReviewScreen(
    onSave: () {},
    onAddPages: () {},
    onExit: () {},
    onCropPage: (_, _) {},
    onEnhancePage: (_, _) {},
  ),
);

Widget _crop(PageDraft page) => BlocProvider<CropCubit>(
  create: (_) => CropCubit(page, const FakePageRenderer()),
  child: CropScreen(onNext: (_) {}, onCancelled: () {}),
);

/// A correction job that does nothing, for previews.
String previewCorrectionJob(PageCorrectionRequest request) =>
    request.destinationPath;

// ---------------------------------------------------------------------------
// Capture screen
// ---------------------------------------------------------------------------

/// The camera ready to capture, with nothing captured yet.
@Preview(name: 'Capture — ready', group: 'Scanning', theme: appPreviewTheme)
Widget captureReady() => _capture(
  const ScanCaptureState.initial().copyWith(status: ScanCaptureStatus.ready),
);

/// Full-resolution capture with exact active-camera dimensions.
@Preview(
  name: 'Capture — Full resolution status',
  group: 'Scanning',
  theme: appPreviewTheme,
)
Widget captureFullResolution() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.ready,
    activeResolution: SupportedCameraResolutionPreview.full,
  ),
);

/// Lower tier capture in dark mode.
@Preview(
  name: 'Capture — lower resolution, dark',
  group: 'Scanning',
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget captureLowerResolution() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.ready,
    desiredResolution: SupportedCameraResolutionPreview.hdDesired,
    activeResolution: SupportedCameraResolutionPreview.hd,
  ),
);

/// Deterministic values used by capture previews without a capability query.
abstract final class SupportedCameraResolutionPreview {
  /// Full-resolution exact active-camera result.
  static final full = SupportedCameraResolution(
    tier: CameraResolutionTier.ultraHd4k,
    width: 4032,
    height: 3024,
  );

  /// Desired lower tier.
  static final hdDesired = DesiredCameraResolution.tier(
    CameraResolutionTier.hd720,
  );

  /// Exact lower-tier result.
  static final hd = SupportedCameraResolution(
    tier: CameraResolutionTier.hd720,
    width: 1280,
    height: 720,
  );
}

/// The camera part-way through a batch.
@Preview(name: 'Capture — batch', group: 'Scanning', theme: appPreviewTheme)
Widget captureBatch() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.ready,
    pageCount: 7,
    batchMode: true,
    torchOn: true,
  ),
);

/// The camera being opened.
@Preview(name: 'Capture — preparing', group: 'Scanning', theme: appPreviewTheme)
Widget capturePreparing() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.preparing,
  ),
);

/// Camera permission refused, but still askable.
@Preview(
  name: 'Capture — permission denied',
  group: 'Scanning',
  theme: appPreviewTheme,
)
Widget capturePermissionDenied() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.failure,
    failure: const Failure.permission(kind: PermissionKind.camera),
  ),
);

/// Camera permission refused for good, so only settings can resolve it.
@Preview(
  name: 'Capture — permission blocked',
  group: 'Scanning',
  theme: appPreviewTheme,
)
Widget capturePermissionBlocked() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.failure,
    failure: const Failure.permission(
      kind: PermissionKind.camera,
      permanentlyDenied: true,
    ),
  ),
);

/// The camera held by another application.
@Preview(
  name: 'Capture — camera error',
  group: 'Scanning',
  theme: appPreviewTheme,
)
Widget captureCameraError() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.failure,
    failure: const Failure.camera(inUseByAnotherApp: true),
  ),
);

/// The capture screen on a tablet.
@Preview(
  name: 'Capture — tablet',
  group: 'Scanning',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget captureTablet() => _capture(
  const ScanCaptureState.initial().copyWith(
    status: ScanCaptureStatus.ready,
    pageCount: 3,
  ),
);

// ---------------------------------------------------------------------------
// Error views in isolation
// ---------------------------------------------------------------------------

/// The permission view with the retry still worth offering.
@Preview(
  name: 'Permission view — askable',
  group: 'Scanning widgets',
  theme: appPreviewTheme,
)
Widget permissionViewAskable() => previewSurface(
  ScanPermissionDeniedView(
    permanentlyDenied: false,
    onOpenSettings: () {},
    onRetry: () {},
  ),
);

/// The permission view once only settings can resolve it.
@Preview(
  name: 'Permission view — blocked',
  group: 'Scanning widgets',
  theme: appPreviewTheme,
)
Widget permissionViewBlocked() => previewSurface(
  ScanPermissionDeniedView(permanentlyDenied: true, onOpenSettings: () {}),
);

/// The permission view at the largest supported text scale.
@Preview(
  name: 'Permission view — large text',
  group: 'Scanning widgets',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget permissionViewLargeText() => previewSurface(
  ScanPermissionDeniedView(permanentlyDenied: true, onOpenSettings: () {}),
);

/// The camera-error view.
@Preview(
  name: 'Camera error view',
  group: 'Scanning widgets',
  theme: appPreviewTheme,
)
Widget cameraErrorView() => previewSurface(
  ScanCameraErrorView(
    failure: const Failure.camera(inUseByAnotherApp: true),
    onRetry: () {},
    onImportInstead: () {},
  ),
);

/// The camera-error view in dark mode.
@Preview(
  name: 'Camera error view — dark',
  group: 'Scanning widgets',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget cameraErrorViewDark() => previewSurface(
  ScanCameraErrorView(
    failure: const Failure.camera(),
    onRetry: () {},
    onImportInstead: () {},
  ),
);

/// Progress while a batch of pages is straightened.
@Preview(
  name: 'Correction progress',
  group: 'Scanning widgets',
  theme: appPreviewTheme,
)
Widget correctionProgress() => previewSurface(
  ScanCorrectionProgress(completed: 3, total: 8, onCancel: () {}),
);

// ---------------------------------------------------------------------------
// Review screen
// ---------------------------------------------------------------------------

/// A review list with several pages.
@Preview(name: 'Review — pages', group: 'Scanning', theme: appPreviewTheme)
Widget reviewPages() => _review(_capturedPages(4));

/// A review list with a single page.
@Preview(name: 'Review — one page', group: 'Scanning', theme: appPreviewTheme)
Widget reviewOnePage() => _review(_capturedPages(1));

/// A review list with a long batch, to check scrolling.
@Preview(name: 'Review — long batch', group: 'Scanning', theme: appPreviewTheme)
Widget reviewLongBatch() => _review(_capturedPages(24));

/// The review screen after every page has been deleted.
@Preview(name: 'Review — empty', group: 'Scanning', theme: appPreviewTheme)
Widget reviewEmpty() => _review(const []);

/// The review screen in dark mode.
@Preview(
  name: 'Review — dark',
  group: 'Scanning',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget reviewDark() => _review(_capturedPages(4));

/// The review screen on a tablet.
@Preview(
  name: 'Review — tablet',
  group: 'Scanning',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget reviewTablet() => _review(_capturedPages(6));

/// The review screen at the largest supported text scale.
@Preview(
  name: 'Review — large text',
  group: 'Scanning',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget reviewLargeText() => _review(_capturedPages(3));

// ---------------------------------------------------------------------------
// Crop screen
// ---------------------------------------------------------------------------

/// A page with nothing applied to it yet.
PageDraft _draft() => const PageDraft(
  id: PageId('preview-page-0'),
  originalImagePath: '/preview/page-0.jpg',
);

/// A page that has already been cropped once, so Revert is live.
PageDraft _croppedDraft({int times = 1}) {
  var draft = _draft();
  for (var i = 0; i < times; i++) {
    draft = draft.withCrop(const CropOp(quad: _skewedQuad));
  }
  return draft;
}

/// The crop screen before anything has been applied.
@Preview(name: 'Crop — adjusting', group: 'Scanning', theme: appPreviewTheme)
Widget cropAdjusting() => _crop(_draft());

/// After one crop: the screen has stayed put, and Revert is now available.
@Preview(name: 'Crop — applied once', group: 'Scanning', theme: appPreviewTheme)
Widget cropAppliedOnce() => _crop(_croppedDraft());

/// After a second crop, which is the whole point of applying in place.
@Preview(
  name: 'Crop — applied twice',
  group: 'Scanning',
  theme: appPreviewTheme,
)
Widget cropAppliedTwice() => _crop(_croppedDraft(times: 2));

/// The crop screen in dark mode.
@Preview(
  name: 'Crop — dark',
  group: 'Scanning',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget cropDark() => _crop(_croppedDraft());

/// The crop screen on a tablet.
@Preview(
  name: 'Crop — tablet',
  group: 'Scanning',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget cropTablet() => _crop(_croppedDraft());
