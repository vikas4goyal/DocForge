/// Constructs the scanning object graph and hosts the scanning flow.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/page_renderer.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/camera_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_plugin_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/opencv_edge_detector.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/screens/enhancement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Everything the scanning feature needs, built once.
class ScanningModule {
  /// Creates the module.
  const ScanningModule({
    required this.scanner,
    required this.cameraCapabilities,
    required this.loadCameraResolutions,
    required this.resolveCaptureResolution,
    required this.staging,
    required this.capturePage,
    required this.discardSession,
    required this.renderPage,
    required this.buildPreview,
    required this.openSettings,
    required this.telemetry,
  });

  /// Drives the camera.
  final ScannerRepository scanner;

  /// Reports supported resolutions for the active camera.
  final CameraCapabilityRepository cameraCapabilities;

  /// Loads active-camera resolution choices for Settings and capture.
  final LoadCameraResolutions loadCameraResolutions;

  /// Resolves the persisted desired tier before each camera capture.
  final ResolveCaptureResolution resolveCaptureResolution;

  /// Where captures are written before the document exists.
  final ScanStagingArea staging;

  /// Captures one page.
  final CapturePage capturePage;

  /// Releases the camera and clears an abandoned session.
  final DiscardScanSession discardSession;

  /// Renders a page from its original and its layers, caching by plan.
  final PageRenderer renderPage;

  /// Builds the live camera preview.
  ///
  /// Supplied by the composition root because the preview is a Flutter widget
  /// tied to the plugin's controller: the screen takes it as a parameter so it
  /// stays testable and previewable without a camera.
  final CameraPreviewBuilder buildPreview;

  /// Opens this application's system settings after permanent denial.
  final Future<bool> Function() openSettings;

  /// Operational telemetry shared by the page editors.
  final AppTelemetry telemetry;
}

/// Builds the scanning graph over an already-resolved cache [directory].
///
/// The staging area lives in the cache directory rather than in documents, so
/// captures from an abandoned scan can be reclaimed by the operating system
/// under storage pressure instead of counting as user data.
///
/// [detector] defaults to the OpenCV detector. It is injectable because the
/// OpenCV binding needs a native library that exists on Android and iOS but not
/// in the host test VM, so tests and previews substitute
/// [FullPageEdgeDetector] — which is also the behaviour the spec requires when
/// no edges can be found.
///
/// [scanner] defaults to [CameraScannerRepository] over the staging area built
/// here. It is injectable for the same reason as [detector]: the camera is a
/// platform edge with no host-VM implementation, so an end-to-end flow
/// substitutes `FakeScannerRepository` to capture fixture images deterministically.
/// A caller that supplies its own scanner is responsible for its staging
/// behaviour; the staging area passed to the module is still the local one, so
/// captures land where the rest of the flow expects to find them.
///
/// [buildPreview] defaults to the live camera preview when the default scanner
/// is used. A substituted scanner has no camera to preview, so it falls back to
/// an inert surface rather than reaching for a controller that does not exist.
ScanningModule buildScanningModule({
  required Directory directory,
  required PermissionService permissions,
  required IdGenerator ids,
  required PageRenderer renderPage,
  EdgeDetector detector = const OpenCvEdgeDetector(),
  ScannerRepository? scanner,
  CameraCapabilityRepository? cameraCapabilities,
  CameraPreviewBuilder? buildPreview,
  AppTelemetry telemetry = const NoopAppTelemetry(),
}) {
  final staging = LocalScanStagingArea(directory);
  final resolvedScanner =
      scanner ?? CameraScannerRepository(permissions, staging, ids);
  final resolvedCapabilities =
      cameraCapabilities ??
      (scanner == null
          ? const CameraPluginCapabilityRepository(FlutterCameraPresetProbe())
          : const _UnavailableCameraCapabilities());
  final loadCameraResolutions = LoadCameraResolutions(resolvedCapabilities);

  return ScanningModule(
    scanner: resolvedScanner,
    cameraCapabilities: resolvedCapabilities,
    loadCameraResolutions: loadCameraResolutions,
    resolveCaptureResolution: ResolveCaptureResolution(loadCameraResolutions),
    staging: staging,
    // OpenCV finds the outline; `FullPageEdgeDetector` remains the specified
    // behaviour for a capture whose edges cannot be found, and the detector
    // falls back to exactly that rather than failing.
    capturePage: CapturePage(
      resolvedScanner,
      detector,
      resolveCaptureResolution: ResolveCaptureResolution(loadCameraResolutions),
    ),
    discardSession: DiscardScanSession(staging, resolvedScanner),
    renderPage: renderPage,
    buildPreview:
        buildPreview ??
        (resolvedScanner is CameraScannerRepository
            ? resolvedScanner.buildPreview
            : _unavailableCameraPreview),
    openSettings: permissions.openSettings,
    telemetry: telemetry,
  );
}

/// Host-test fallback when a fake scanner has no capability probe attached.
class _UnavailableCameraCapabilities implements CameraCapabilityRepository {
  const _UnavailableCameraCapabilities();

  @override
  Future<Result<List<SupportedCameraResolution>>>
  loadActiveResolutions() async =>
      const Result<List<SupportedCameraResolution>>.success([]);
}

/// The preview surface for a scanner that has no camera behind it.
///
/// A plain dark surface rather than a message: the capture screen already
/// renders its own state, and a substituted scanner is only ever in play in a
/// test, a preview or a golden, where the preview area's contents are not what
/// is being asserted.
Widget _unavailableCameraPreview(BuildContext context) =>
    const ColoredBox(color: Color(0xFF101010));

// ── Reusable page editors ────────────────────────────────────────
//
// Crop and enhance are pushed as routes rather than being steps of the scan
// flow, so the same screens serve every way a page can be reached: straight
// after a capture, from a row in the review list, and from a page of a document
// that was saved long ago. A second implementation for any of those would be a
// second set of behaviours to keep in step, and the one the user reached would
// decide which fixes they got.

/// Opens the crop and rotate editor for [page].
///
/// Returns the page carrying whatever geometry the user applied, or null when
/// they left without continuing — which callers must treat as "keep what you
/// had" rather than as a failure.
///
/// The editor works on a [PageDraft]: an untouched original plus the layers
/// applied over it. Applying a crop appends to the geometry rather than
/// replacing the image, which is what lets it be reverted later.
Future<PageDraft?> openPageCrop(
  BuildContext context, {
  required ScanningModule module,
  required PageDraft page,
}) => Navigator.of(context).push<PageDraft>(
  MaterialPageRoute(
    builder: (routeContext) => BlocProvider(
      create: (_) =>
          CropCubit(page, module.renderPage, telemetry: module.telemetry),
      child: CropScreen(
        onNext: (edited) => Navigator.of(routeContext).pop(edited),
        onCancelled: () => Navigator.of(routeContext).pop(),
      ),
    ),
  ),
);

/// Opens the enhancement editor for a single [page].
///
/// Returns the page carrying whatever settings were chosen, or null when the
/// screen was left without finishing.
Future<PageDraft?> openPageEnhance(
  BuildContext context, {
  required ScanningModule module,
  required PageDraft page,
}) => Navigator.of(context).push<PageDraft>(
  MaterialPageRoute(
    builder: (routeContext) => BlocProvider<EnhancementCubit>(
      create: (_) => EnhancementCubit(page, module.renderPage),
      child: EnhancementScreen(
        onDone: (edited) => Navigator.of(routeContext).pop(edited),
      ),
    ),
  ),
);
