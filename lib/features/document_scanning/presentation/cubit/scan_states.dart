/// States for the scanning flow.
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
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
  }) => ScanCaptureState._(
    status: status ?? this.status,
    pageCount: pageCount ?? this.pageCount,
    batchMode: batchMode ?? this.batchMode,
    torchOn: torchOn ?? this.torchOn,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, pageCount, batchMode, torchOn, failure];
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
  /// The user is adjusting the corners.
  adjusting,

  /// Perspective correction is running.
  correcting,

  /// The corrected page has been written.
  done,

  /// Correction failed.
  failure,
}

/// Immutable state of the crop screen.
class CropState extends Equatable {
  const CropState._({
    required this.status,
    required this.page,
    required this.quad,
    this.failure,
  });

  /// Starts adjusting [page], seeded with its current crop.
  CropState.adjusting(CapturedPage page)
    : this._(status: CropStatus.adjusting, page: page, quad: page.quad);

  /// Where the screen is in its lifecycle.
  final CropStatus status;

  /// The page being cropped.
  final CapturedPage page;

  /// The quadrilateral as the user has it now.
  ///
  /// Held separately from `page.quad` so abandoning the screen leaves the
  /// page's stored crop untouched — an adjustment is not applied until it is
  /// confirmed.
  final PageQuad quad;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether correction is currently running.
  bool get isWorking => status == CropStatus.correcting;

  /// Whether the crop differs from the page's stored one.
  bool get hasChanges => quad != page.quad;

  /// Returns a copy with the given fields replaced.
  CropState copyWith({
    CropStatus? status,
    CapturedPage? page,
    PageQuad? quad,
    Failure? failure,
  }) => CropState._(
    status: status ?? this.status,
    page: page ?? this.page,
    quad: quad ?? this.quad,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, page, quad, failure];
}
