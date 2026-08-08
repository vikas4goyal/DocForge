/// The Cubits driving the scanning flow.
///
/// Each method is emit / await a use case / emit. Page ordering, undo
/// positioning, the "at least one page" rule and the perspective maths all live
/// in the domain and application layers and are unit-tested there.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/contracts/page_renderer.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the camera capture screen.
class ScanCaptureCubit extends Cubit<ScanCaptureState> {
  /// Creates the Cubit over its collaborators.
  ScanCaptureCubit(this._scanner, this._capturePage, this._discard)
    : super(const ScanCaptureState.initial());

  final ScannerRepository _scanner;
  final CapturePage _capturePage;
  final DiscardScanSession _discard;

  /// Pages captured in this session, in capture order.
  ///
  /// Held here rather than in the state because the state carries a count for
  /// the counter widget; the pages themselves are handed to the review screen
  /// when the user finishes.
  final List<CapturedPage> pages = [];

  /// Opens the camera.
  ///
  /// Also serves retry: both want the camera reopened from scratch, and a
  /// separate method would be the same three lines.
  Future<void> start() async {
    emit(state.copyWith(status: ScanCaptureStatus.preparing));

    final result = await _scanner.initialise();

    emit(switch (result) {
      Success() => state.copyWith(status: ScanCaptureStatus.ready),
      Failed(:final failure) => state.copyWith(
        status: ScanCaptureStatus.failure,
        failure: failure,
      ),
    });
  }

  /// Captures one page.
  ///
  /// Ignored while a capture is already running, so a double tap on the shutter
  /// cannot produce two pages from one intent.
  Future<void> capture() async {
    if (!state.canCapture) return;

    emit(state.copyWith(status: ScanCaptureStatus.capturing));

    final result = await _capturePage();

    switch (result) {
      case Success(:final value):
        pages.add(value);
        emit(
          state.copyWith(
            status: ScanCaptureStatus.ready,
            pageCount: pages.length,
          ),
        );
      case Failed(:final failure):
        // Back to ready, not to failure: the pages already captured are intact
        // and the user can try the shot again. The spec requires exactly that
        // for a storage-full capture.
        emit(state.copyWith(status: ScanCaptureStatus.ready, failure: failure));
    }
  }

  /// Turns batch mode on or off.
  ///
  /// Batch mode changes what the *screen* does after a capture — stay on the
  /// preview rather than move on — so the Cubit only records the flag.
  void setBatchMode({required bool enabled}) =>
      emit(state.copyWith(batchMode: enabled));

  /// Turns the torch on or off.
  Future<void> setTorch({required bool on}) async {
    final result = await _scanner.setTorch(on: on);

    emit(switch (result) {
      Success() => state.copyWith(torchOn: on),
      Failed(:final failure) => state.copyWith(failure: failure),
    });
  }

  /// Releases the camera without discarding the captured pages.
  ///
  /// The path taken when the user moves on to review: the camera must not stay
  /// held while another screen is showing, but the captures are still wanted.
  Future<void> release() async {
    await _scanner.dispose();
    emit(state.copyWith(status: ScanCaptureStatus.idle));
  }

  /// Releases the camera and deletes everything this session captured.
  ///
  /// The path taken when the user abandons the scan.
  Future<void> abandon() async {
    pages.clear();
    await _discard();
    emit(const ScanCaptureState.initial());
  }

  @override
  Future<void> close() async {
    // The last line of defence for "the camera is released on every exit path":
    // however the screen goes away, closing its Cubit gives the device back.
    await _scanner.dispose();
    return super.close();
  }
}

/// Drives the page review screen.
class PageReviewCubit extends Cubit<PageReviewState> {
  /// Creates the Cubit seeded with the pages captured so far.
  PageReviewCubit(List<CapturedPage> pages)
    : super(PageReviewState(pages: List.unmodifiable(pages)));

  /// Rotates the page at [index] one quarter clockwise.
  void rotate(int index) =>
      emit(state.copyWith(pages: ScanSessionRules.rotate(state.pages, index)));

  /// Moves the page at [from] to [to].
  void reorder(int from, int to) => emit(
    state.copyWith(pages: ScanSessionRules.reorder(state.pages, from, to)),
  );

  /// Removes the page at [index], keeping it available for undo.
  void delete(int index) {
    if (index < 0 || index >= state.pages.length) return;

    final removed = state.pages[index];
    emit(
      state.copyWith(
        pages: ScanSessionRules.delete(state.pages, index),
        lastDeleted: DeletedPage(removed, index),
      ),
    );
  }

  /// Puts the most recently deleted page back where it was.
  void undoDelete() {
    final deleted = state.lastDeleted;
    if (deleted == null) return;

    emit(
      PageReviewState(
        pages: ScanSessionRules.restore(
          state.pages,
          deleted.page,
          deleted.index,
        ),
      ),
    );
  }

  /// Replaces the page at [index], after a crop has been applied to it.
  void replace(int index, CapturedPage page) {
    if (index < 0 || index >= state.pages.length) return;

    final updated = [...state.pages];
    updated[index] = page;
    emit(PageReviewState(pages: updated));
  }

  /// Appends pages captured after returning to the camera.
  void addAll(List<CapturedPage> pages) =>
      emit(PageReviewState(pages: [...state.pages, ...pages]));
}

/// Drives the crop screen.
///
/// Edits the page's geometry layer and nothing else. Applying appends a
/// [CropOp] and re-renders; the enhancement is carried through untouched, which
/// is what lets the two layers be reverted independently (`design.md` D6).
class CropCubit extends Cubit<CropState> {
  /// Creates the Cubit for [page], rendering through [_render].
  // A named public `telemetry` parameter is clearer than exposing the private
  // field name solely to use an initializing formal.
  CropCubit(
    PageDraft page,
    this._render, {
    AppTelemetry telemetry = const NoopAppTelemetry(),
  }) : _telemetry = telemetry,
       super(CropState.adjusting(page)) {
    unawaited(_refresh());
  }

  final PageRenderer _render;
  final AppTelemetry _telemetry;

  /// Moves the selection to [quad] as the user drags a handle.
  ///
  /// Emits on every drag frame, which is cheap: the state holds four points
  /// and nothing is rendered until the crop is applied.
  void adjust(PageQuad quad) => emit(state.copyWith(quad: quad));

  /// Sets the pending rotation, in degrees.
  void rotate(double degrees) => emit(state.copyWith(rotationDegrees: degrees));

  /// Applies the pending selection and rotation to the page.
  ///
  /// Appends to the geometry rather than replacing the image, then re-renders
  /// and resets the pending state — so the screen stays put, showing the
  /// cropped result, ready to be cropped again. It deliberately does not
  /// navigate: continuing is the Next control's job.
  Future<void> apply() async {
    final pending = state.pendingOp;
    if (pending == null || state.isWorking) return;

    emit(state.copyWith(status: CropStatus.applying));

    final cropped = state.page.withCrop(pending);
    final trace = await _telemetry.startTrace('page_crop');
    trace.putAttribute('rotated', (pending.rotationDegrees != 0).toString());

    late final Result<String> rendered;
    try {
      rendered = await _render(PageRenderPlan.of(cropped));
      trace.putAttribute(
        'outcome',
        rendered is Success<String> ? 'success' : 'failure',
      );
    } on Object catch (error, stackTrace) {
      trace.putAttribute('outcome', 'exception');
      await _telemetry.recordError(
        error,
        stackTrace,
        reason: 'Page crop render',
      );
      rethrow;
    } finally {
      await trace.stop();
    }
    if (isClosed) return;

    switch (rendered) {
      case Success(:final value):
        await _telemetry.logEvent(
          'page_cropped',
          parameters: {
            'outcome': 'success',
            'rotated': pending.rotationDegrees != 0 ? 1 : 0,
          },
        );
        emit(
          state.copyWith(
            status: CropStatus.adjusting,
            page: cropped,
            // The view resets: the selection covers the whole of the new
            // image and the rotation returns to square, because the crop the
            // user just made is now part of the picture rather than pending.
            quad: PageQuad.full,
            rotationDegrees: 0,
            renderPath: value,
          ),
        );
      case Failed(:final failure):
        await _telemetry.logEvent(
          'page_cropped',
          parameters: {
            'outcome': 'failure',
            'rotated': pending.rotationDegrees != 0 ? 1 : 0,
          },
        );
        // The page is untouched — the crop was never appended — so the user
        // can adjust the selection and try again.
        emit(state.copyWith(status: CropStatus.adjusting, failure: failure));
    }
  }

  /// Discards every crop and rotation, returning to the full original frame.
  ///
  /// The enhancement is deliberately untouched: reverting the crop gives the
  /// user their whole page back, still enhanced. There is no undo stack —
  /// one that only ever unwinds to the bottom is a flag pretending to be a
  /// stack.
  Future<void> revertToOriginal() async {
    if (!state.page.hasGeometry || state.isWorking) return;

    final reverted = state.page.revertGeometry();
    emit(
      state.copyWith(page: reverted, quad: PageQuad.full, rotationDegrees: 0),
    );
    await _refresh();
  }

  /// The page as it now stands, for the caller to keep.
  PageDraft get page => state.page;

  /// Renders the page as it currently is and shows the result.
  ///
  /// A failed render leaves the previous image on screen rather than blanking
  /// it: the user is mid-edit, and an empty canvas would look like data loss.
  Future<void> _refresh() async {
    final rendered = await _render(PageRenderPlan.of(state.page));
    if (isClosed) return;

    if (rendered case Success(:final value)) {
      emit(state.copyWith(renderPath: value));
    }
  }
}

/// The failure shown when a scan is started without a usable camera.
///
/// Exposed so the capture screen and its previews agree on what "no camera"
/// looks like without either constructing it inline.
const cameraUnavailableFailure = Failure.camera();
