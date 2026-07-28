/// Constructs the scanning object graph and hosts the scanning flow.
library;

import 'dart:io';

import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_forge/features/document_scanning/domain/page_geometry.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/opencv_edge_detector.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/page_correction_job.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/crop_screen.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/page_review_screen.dart';
import 'package:doc_forge/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:doc_forge/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_forge/features/image_enhancement/infrastructure/enhancement_job.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_forge/features/image_enhancement/presentation/screens/enhancement_screen.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_cubit.dart';
import 'package:doc_forge/features/pdf_generation/presentation/screens/pdf_preview_screen.dart';
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
    required this.applyEnhancement,
    required this.renderPage,
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

  /// Applies enhancement settings, off the UI thread.
  final ApplyEnhancement applyEnhancement;

  /// Renders a page from its original and its layers, caching by plan.
  final RenderPage renderPage;

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
///
/// [detector] defaults to the OpenCV detector. It is injectable because the
/// OpenCV binding needs a native library that exists on Android and iOS but not
/// in the host test VM, so tests and previews substitute
/// [FullPageEdgeDetector] — which is also the behaviour the spec requires when
/// no edges can be found.
ScanningModule buildScanningModule({
  required Directory directory,
  required PermissionService permissions,
  required IdGenerator ids,
  required BackgroundWorker worker,
  required RenderPage renderPage,
  EdgeDetector detector = const OpenCvEdgeDetector(),
}) {
  final staging = LocalScanStagingArea(directory);
  final scanner = CameraScannerRepository(permissions, staging, ids);

  return ScanningModule(
    scanner: scanner,
    staging: staging,
    // OpenCV finds the outline; `FullPageEdgeDetector` remains the specified
    // behaviour for a capture whose edges cannot be found, and the detector
    // falls back to exactly that rather than failing.
    capturePage: CapturePage(scanner, detector),
    applyCorrection: ApplyPerspectiveCorrection(worker, correctPageJob),
    discardSession: DiscardScanSession(staging, scanner),
    applyEnhancement: ApplyEnhancement(worker, enhancePageJob),
    renderPage: renderPage,
    buildPreview: scanner.buildPreview,
  );
}

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
      create: (_) => CropCubit(page, module.renderPage),
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

/// Which step of the scanning flow is showing.
enum _ScanStep {
  /// The live camera.
  capture,

  /// The captured-page review list.
  review,

  /// The document preview, where the PDF is named and saved.
  save,
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
    required this.creation,
    required this.onExit,
    required this.onSaved,
    required this.onImportInstead,
    required this.onOpenSettings,
    super.key,
    this.initialPages,
  });

  /// The scanning object graph.
  final ScanningModule module;

  /// The OCR and PDF-generation object graph.
  final DocumentCreationModule creation;

  /// Called when the flow ends without a document.
  final VoidCallback onExit;

  /// Called with the document once it has been saved.
  final void Function(Document document) onSaved;

  /// Offers the photo library instead of the camera.
  final VoidCallback onImportInstead;

  /// Opens the system settings so camera access can be granted.
  final VoidCallback onOpenSettings;

  /// Pages the flow starts with, when they came from somewhere other than the
  /// camera.
  ///
  /// Supplied by the import feature. When set the flow opens at the *review*
  /// step rather than the camera, which is what makes cropping, rotation,
  /// reordering and enhancement available to imported images — the scanning
  /// flow already does all of that, and the alternative would be a second
  /// review screen that drifts from this one.
  final ScannedPageBundle? initialPages;

  @override
  State<ScanFlow> createState() => _ScanFlowState();
}

class _ScanFlowState extends State<ScanFlow> {
  late final ScanCaptureCubit _capture = ScanCaptureCubit(
    widget.module.scanner,
    widget.module.capturePage,
    widget.module.discardSession,
  );
  late final PageReviewCubit _review = PageReviewCubit([
    for (final page in widget.initialPages?.pages ?? const <PageRef>[])
      CapturedPage(
        id: page.id,
        imagePath: page.imagePath,
        // Imported images have no detected edges: they are already whatever
        // the user chose to photograph or save. The full page is the honest
        // starting point, and the crop screen is there if they want one.
        quad: PageQuad.full,
        rotation: page.rotation,
        // Nothing has been perspective-corrected, and marking them corrected
        // would silently disable the crop step for imported pages.
      ),
  ]);

  late _ScanStep _step = widget.initialPages == null
      ? _ScanStep.capture
      : _ScanStep.review;

  /// The session's pages once review is finished, carrying their enhancement.
  ///
  /// Held here rather than in a Cubit because three later steps share it, and
  /// the flow — not any one screen — owns the session.
  List<PageRef> _pages = const [];

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

  /// Settings chosen for individual pages before the session-wide step.
  ///
  /// Keyed by page rather than by position, so reordering or deleting a page
  /// cannot hand its settings to a different one.
  final Map<PageId, EnhancementSettings> _enhancements = {};

  /// Geometry applied per page, keyed the same way and for the same reason.
  final Map<PageId, List<CropOp>> _geometry = {};

  /// Moves from review into the save step.
  ///
  /// No session-wide enhancement step: enhancement is per page, chosen from a
  /// row while the page is in front of the user (`design.md` D7a).
  void _finishReview() {
    _pages = [for (final page in _review.state.pages) _pageRefFor(page)];
    setState(() => _step = _ScanStep.save);
  }

  /// Bridges a capture into the layered page the editors work on.
  ///
  /// Temporary: this flow is being replaced by the page table, which holds
  /// [PageDraft] throughout. Until then the two representations meet here.
  PageDraft _draftFor(CapturedPage page) => PageDraft(
    id: page.id,
    originalImagePath: page.imagePath,
    enhancement: _enhancements[page.id] ?? EnhancementSettings.none,
  );

  Future<void> _cropPage(int index, CapturedPage page) async {
    final edited = await openPageCrop(
      context,
      module: widget.module,
      page: _draftFor(page),
    );

    if (edited == null || !mounted) return;
    setState(() => _geometry[page.id] = edited.geometry);
  }

  /// Opens the enhancement editor for one page of the review list.
  ///
  /// Per page rather than only for the whole session: pages of one document are
  /// often shot under different light, and settings that suit one can be wrong
  /// for the next.
  Future<void> _enhancePage(int index, CapturedPage page) async {
    final enhanced = await openPageEnhance(
      context,
      module: widget.module,
      page: _draftFor(page),
    );

    if (enhanced == null || !mounted) return;
    setState(() => _enhancements[page.id] = enhanced.enhancement);
  }

  /// Takes a freshly captured page through the crop and enhance editors.
  ///
  /// Offered immediately rather than left for the review list: the page is
  /// still in front of the user, and both steps are skippable, so this adds a
  /// step to accept rather than one to undo. Declining either leaves the
  /// capture exactly as it was.
  Future<void> _editCapturedPage(int index, CapturedPage page) async {
    final cropped = await openPageCrop(
      context,
      module: widget.module,
      page: _draftFor(page),
    );

    if (cropped != null) _geometry[page.id] = cropped.geometry;
    if (!mounted) return;

    final enhanced = await openPageEnhance(
      context,
      module: widget.module,
      page: _draftFor(page),
    );

    if (enhanced == null || !mounted) return;
    setState(() => _enhancements[page.id] = enhanced.enhancement);
  }

  /// The review page as a [PageRef], carrying any settings already chosen.
  ///
  /// `CapturedPage` has nowhere to hold them — it describes what came off the
  /// camera — so they are kept beside the list until the pages are built.
  PageRef _pageRefFor(CapturedPage page) {
    final settings = _enhancements[page.id];
    final reference = page.toPageRef();
    return settings == null
        ? reference
        : reference.copyWith(enhancement: settings);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _ScanStep.capture => BlocProvider.value(
        value: _capture,
        child: ScanCaptureScreen(
          previewBuilder: widget.module.buildPreview,
          onFinished: _finishCapturing,
          onPageCaptured: _editCapturedPage,
          onCancelled: widget.onExit,
          onOpenSettings: widget.onOpenSettings,
          onImportInstead: widget.onImportInstead,
        ),
      ),
      _ScanStep.review => BlocProvider.value(
        value: _review,
        child: PageReviewScreen(
          onSave: _finishReview,
          onAddPages: () => setState(() => _step = _ScanStep.capture),
          onExit: widget.onExit,
          onCropPage: _cropPage,
          onEnhancePage: _enhancePage,
        ),
      ),
      _ScanStep.save => BlocProvider<PdfGenerationCubit>(
        create: (_) => PdfGenerationCubit(
          _pages,
          widget.creation.saveDocument,
          widget.creation.generateName,
          source: widget.initialPages?.source ?? PageSource.camera,
          suggestedTitle: widget.initialPages?.suggestedTitle,
        )..load(),
        child: PdfPreviewScreen(
          onSaved: widget.onSaved,
          // Back to review rather than out of the flow: the pages are intact
          // and nothing has been written, so the user can change their mind
          // about the result without rescanning.
          onBack: () => setState(() => _step = _ScanStep.review),
        ),
      ),
    };
  }
}
