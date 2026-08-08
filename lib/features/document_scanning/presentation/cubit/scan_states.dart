/// States for the scanning flow.
library;

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:equatable/equatable.dart';

/// Where the camera capture screen is in its lifecycle.
enum ScanCaptureStatus {
  /// The camera has not been opened yet.
  idle,

  /// The camera is being prepared.
  preparing,

  /// The live preview is running and the shutter is available.
  ready,

  /// A capture is being taken and written.
  capturing,

  /// The camera could not be opened or used.
  failure,
}

/// Immutable state of the camera capture screen.
class ScanCaptureState extends Equatable {
  const ScanCaptureState._({
    required this.status,
    this.pageCount = 0,
    this.batchMode = false,
    this.torchOn = false,
    this.failure,
    this.desiredResolution = const DesiredCameraResolution.fullResolution(),
    this.activeResolution,
  });

  /// Before the camera is opened.
  const ScanCaptureState.initial() : this._(status: ScanCaptureStatus.idle);

  /// Where the screen is in its lifecycle.
  final ScanCaptureStatus status;

  /// How many pages have been captured in this session.
  final int pageCount;

  /// Whether consecutive captures return straight to the preview.
  final bool batchMode;

  /// Whether the torch is lit.
  final bool torchOn;

  /// What went wrong, when something did.
  final Failure? failure;

  /// Stable preference used to initialise the active camera.
  final DesiredCameraResolution desiredResolution;

  /// Exact active-camera dimensions selected, or null for plugin maximum.
  final SupportedCameraResolution? activeResolution;

  /// Accessible text describing the current source capture resolution.
  String get resolutionLabel => desiredResolution.when(
    fullResolution: () => activeResolution == null
        ? 'Full resolution, camera maximum'
        : 'Full resolution, ${activeResolution!.width} by '
              '${activeResolution!.height}',
    tier: (_) => activeResolution == null
        ? 'Camera maximum'
        : activeResolution!.tier ==
              desiredResolution.when(
                fullResolution: () => activeResolution!.tier,
                tier: (tier) => tier,
              )
        ? '${activeResolution!.tier.label}, ${activeResolution!.width} by '
              '${activeResolution!.height}'
        : '${desiredResolution.when(fullResolution: () => 'Full resolution', tier: (tier) => tier.label)} unavailable, using '
              '${activeResolution!.tier.label}, ${activeResolution!.width} by '
              '${activeResolution!.height}',
  );

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether the shutter can be pressed.
  ///
  /// False while a capture is in flight, so a double tap cannot produce two
  /// captures from one intent.
  bool get canCapture => status == ScanCaptureStatus.ready;

  /// Whether camera permission was refused for good.
  ///
  /// Decides between offering a retry and offering the system settings, which
  /// is the difference between a control that can work and one that cannot.
  bool get isPermanentlyDenied =>
      failure is PermissionFailure &&
      (failure! as PermissionFailure).permanentlyDenied;

  /// Whether the failure is a refused permission rather than a camera fault.
  bool get isPermissionDenied => failure is PermissionFailure;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// the condition that caused it.
  ScanCaptureState copyWith({
    ScanCaptureStatus? status,
    int? pageCount,
    bool? batchMode,
    bool? torchOn,
    Failure? failure,
    DesiredCameraResolution? desiredResolution,
    SupportedCameraResolution? activeResolution,
    bool clearActiveResolution = false,
  }) => ScanCaptureState._(
    status: status ?? this.status,
    pageCount: pageCount ?? this.pageCount,
    batchMode: batchMode ?? this.batchMode,
    torchOn: torchOn ?? this.torchOn,
    failure: failure,
    desiredResolution: desiredResolution ?? this.desiredResolution,
    activeResolution: clearActiveResolution
        ? null
        : (activeResolution ?? this.activeResolution),
  );

  @override
  List<Object?> get props => [
    status,
    pageCount,
    batchMode,
    torchOn,
    failure,
    desiredResolution,
    activeResolution,
  ];
}

/// A page removed from the session, retained so the removal can be undone.
class DeletedPage extends Equatable {
  /// Creates a record of a deletion.
  const DeletedPage(this.page, this.index);

  /// The page that was removed.
  final CapturedPage page;

  /// Where it was, so undo puts it back rather than appending it.
  final int index;

  @override
  List<Object?> get props => [page, index];
}

/// Immutable state of the page review screen.
class PageReviewState extends Equatable {
  /// Creates a review state.
  const PageReviewState({this.pages = const [], this.lastDeleted});

  /// The pages captured so far, in document order.
  final List<CapturedPage> pages;

  /// The most recent deletion, while it can still be undone.
  ///
  /// Cleared by the next edit: an undo offered after three further changes
  /// would put a page back into a list it no longer belongs to.
  final DeletedPage? lastDeleted;

  /// Whether every page has been deleted.
  bool get isEmpty => pages.isEmpty;

  /// Whether the session can be saved as a document.
  bool get canSave => ScanSessionRules.canSave(pages);

  /// Whether an undo is currently on offer.
  bool get canUndo => lastDeleted != null;

  /// Returns a copy with the given fields replaced.
  PageReviewState copyWith({
    List<CapturedPage>? pages,
    DeletedPage? lastDeleted,
  }) => PageReviewState(pages: pages ?? this.pages, lastDeleted: lastDeleted);

  @override
  List<Object?> get props => [pages, lastDeleted];
}

/// Where the crop screen is in its lifecycle.
enum CropStatus {
  /// The user is adjusting the selection.
  adjusting,

  /// A crop is being applied.
  applying,

  /// Applying failed.
  failure,
}

/// Immutable state of the crop screen.
///
/// The screen edits a page's *geometry layer* — the ordered crops and rotations
/// applied over an untouched original. Applying appends to that list and
/// re-renders; it does not replace the original, which is what makes reverting
/// possible and what keeps the enhancement layer out of this screen's business
/// entirely (`design.md` D6).
class CropState extends Equatable {
  const CropState._({
    required this.status,
    required this.page,
    required this.quad,
    required this.rotationDegrees,
    this.renderPath,
    this.failure,
  });

  /// Starts adjusting [page], with nothing pending.
  ///
  /// The selection begins as the whole of whatever the page currently shows —
  /// not as the page's stored crop, because that crop has already been applied
  /// and offering it again would ask the user to re-confirm work they did.
  const CropState.adjusting(PageDraft page)
    : this._(
        status: CropStatus.adjusting,
        page: page,
        quad: PageQuad.full,
        rotationDegrees: 0,
      );

  /// Where the screen is in its lifecycle.
  final CropStatus status;

  /// The page being cropped, carrying its original and both layers.
  final PageDraft page;

  /// The selection as the user has it now, against the current render.
  ///
  /// Pending, not applied: leaving the screen without applying leaves the
  /// page's geometry untouched.
  final PageQuad quad;

  /// The rotation the user has dialled in but not yet applied.
  final double rotationDegrees;

  /// The rendered image the screen is showing, once one exists.
  ///
  /// Carries the page's enhancement as well as its geometry: the row thumbnail
  /// is enhanced, so a crop screen showing raw pixels would read as though the
  /// enhancement had been lost.
  final String? renderPath;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether a crop is being applied.
  bool get isWorking => status == CropStatus.applying;

  /// Whether the selection or the rotation has been changed but not applied.
  ///
  /// Drives the prompt shown when the user continues to enhancement: applying
  /// silently would be a change they did not ask for, and discarding silently
  /// would lose one they did.
  bool get hasUnappliedChanges => !quad.isFullPage || rotationDegrees != 0;

  /// Whether the apply control does anything.
  bool get canApply => hasUnappliedChanges && !isWorking;

  /// Whether any crop or rotation has been applied to this page.
  ///
  /// Drives the revert control, which is disabled when there is nothing of its
  /// own layer to revert — rather than when nothing at all has been done.
  bool get canRevert => page.hasGeometry && !isWorking;

  /// The pending operation, or null when nothing is pending.
  CropOp? get pendingOp => hasUnappliedChanges
      ? CropOp(quad: quad, rotationDegrees: rotationDegrees)
      : null;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// the condition that caused it.
  CropState copyWith({
    CropStatus? status,
    PageDraft? page,
    PageQuad? quad,
    double? rotationDegrees,
    String? renderPath,
    Failure? failure,
  }) => CropState._(
    status: status ?? this.status,
    page: page ?? this.page,
    quad: quad ?? this.quad,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    renderPath: renderPath ?? this.renderPath,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    page,
    quad,
    rotationDegrees,
    renderPath,
    failure,
  ];
}
