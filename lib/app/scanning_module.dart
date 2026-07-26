/// Constructs the scanning object graph and hosts the scanning flow.
library;

import 'dart:io';

import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/page_correction_job.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/page_review_screen.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Everything the scanning feature needs, built once.
class ScanningModule {
  /// Creates the module.
  const ScanningModule({
    required this.scanner,
    required this.staging,
    required this.capturePage,
    required this.applyCorrection,
    required this.discardSession,
    required this.buildPreview,
  });

  /// Drives the camera.
  final ScannerRepository scanner;

  /// Where captures are written before the document exists.
  final ScanStagingArea staging;

  /// Captures one page.
  final CapturePage capturePage;

  /// Straightens cropped pages off the UI thread.
  final ApplyPerspectiveCorrection applyCorrection;

  /// Releases the camera and clears an abandoned session.
  final DiscardScanSession discardSession;

  /// Builds the live camera preview.
  ///
  /// Supplied by the composition root because the preview is a Flutter widget
  /// tied to the plugin's controller: the screen takes it as a parameter so it
  /// stays testable and previewable without a camera.
  final CameraPreviewBuilder buildPreview;
}

/// Builds the scanning graph over an already-resolved cache [directory].
///
/// The staging area lives in the cache directory rather than in documents, so
/// captures from an abandoned scan can be reclaimed by the operating system
/// under storage pressure instead of counting as user data.
ScanningModule buildScanningModule({
  required Directory directory,
  required PermissionService permissions,
  required IdGenerator ids,
  required BackgroundWorker worker,
}) {
  final staging = LocalScanStagingArea(directory);
  final scanner = CameraScannerRepository(permissions, staging, ids);

  return ScanningModule(
    scanner: scanner,
    staging: staging,
    // The fallback detector until automatic detection lands: the full page
    // becomes the default crop and the user adjusts the corners by hand, which
    // is exactly what the spec requires when edges cannot be found.
    capturePage: CapturePage(scanner, const FullPageEdgeDetector()),
    applyCorrection: ApplyPerspectiveCorrection(worker, correctPageJob),
    discardSession: DiscardScanSession(staging, scanner),
    buildPreview: scanner.buildPreview,
  );
}

/// Which step of the scanning flow is showing.
enum _ScanStep {
  /// The live camera.
  capture,

  /// The captured-page review list.
  review,
}

/// Hosts the whole scanning flow behind one route.
///
/// Capture, review and crop share one session: the pages captured on the first
/// screen are what the second edits and the third corrects. Modelling them as
/// three sibling routes would mean lifting that session above the router into
/// ambient state, which the architecture forbids — and would let a deep link
/// drop the user into a review screen for a session that does not exist.
///
/// A nested [Navigator] gives each step its own back behaviour while the
/// session stays owned here, the same shape the onboarding flow uses.
class ScanFlow extends StatefulWidget {
  /// Creates the scanning flow.
  const ScanFlow({
    required this.module,
    required this.onExit,
    required this.onSave,
    required this.onImportInstead,
    required this.onOpenSettings,
    super.key,
  });

  /// The scanning object graph.
  final ScanningModule module;

  /// Called when the flow ends without a document.
  final VoidCallback onExit;

  /// Called with the finished pages when the user saves.
  final void Function(List<CapturedPage> pages) onSave;

  /// Offers the photo library instead of the camera.
  final VoidCallback onImportInstead;

  /// Opens the system settings so camera access can be granted.
  final VoidCallback onOpenSettings;

  @override
  State<ScanFlow> createState() => _ScanFlowState();
}

class _ScanFlowState extends State<ScanFlow> {
  late final ScanCaptureCubit _capture = ScanCaptureCubit(
    widget.module.scanner,
    widget.module.capturePage,
    widget.module.discardSession,
  );
  late final PageReviewCubit _review = PageReviewCubit(const []);

  _ScanStep _step = _ScanStep.capture;

  @override
  void dispose() {
    // Closing the capture Cubit releases the camera, which is the backstop for
    // "released on every exit path" however this route goes away.
    _capture
      ..close()
      ..pages.clear();
    _review.close();
    super.dispose();
  }

  /// Moves the pages captured so far into the review list.
  void _finishCapturing() {
    _review.addAll(_capture.pages);
    _capture.pages.clear();
    setState(() => _step = _ScanStep.review);
  }

  Future<void> _cropPage(int index, CapturedPage page) async {
    final corrected = await Navigator.of(context).push<CapturedPage>(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => CropCubit(page, widget.module.applyCorrection),
          child: CropScreen(
            // Written beside the capture rather than over it: keeping the
            // original means a crop the user dislikes can be redone from the
            // full page rather than from an already-cropped one.
            destinationPath: '${page.imagePath}.cropped.jpg',
            onCropped: (page) => Navigator.of(context).pop(page),
            onCancelled: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );

    if (corrected != null) _review.replace(index, corrected);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _ScanStep.capture => BlocProvider.value(
        value: _capture,
        child: ScanCaptureScreen(
          previewBuilder: widget.module.buildPreview,
          onFinished: _finishCapturing,
          onCancelled: widget.onExit,
          onOpenSettings: widget.onOpenSettings,
          onImportInstead: widget.onImportInstead,
        ),
      ),
      _ScanStep.review => BlocProvider.value(
        value: _review,
        child: PageReviewScreen(
          onSave: () => widget.onSave(_review.state.pages),
          onAddPages: () => setState(() => _step = _ScanStep.capture),
          onExit: widget.onExit,
          onCropPage: _cropPage,
        ),
      ),
    };
  }
}
