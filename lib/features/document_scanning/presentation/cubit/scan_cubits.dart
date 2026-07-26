/// The Cubits driving the scanning flow.
///
/// Each method is emit / await a use case / emit. Page ordering, undo
/// positioning, the "at least one page" rule and the perspective maths all live
/// in the domain and application layers and are unit-tested there.
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_forge/features/document_scanning/domain/perspective_transform.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_states.dart';
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
class CropCubit extends Cubit<CropState> {
  /// Creates the Cubit for [page].
  CropCubit(CapturedPage page, this._correct)
    : super(CropState.adjusting(page));

  final ApplyPerspectiveCorrection _correct;

  /// Moves the crop to [quad] as the user drags a handle.
  ///
  /// Emits on every drag frame, which is cheap: the state holds four points,
  /// and nothing is written until the crop is confirmed.
  void adjust(PageQuad quad) => emit(state.copyWith(quad: quad));

  /// Resets the crop to the whole page.
  void reset() => emit(state.copyWith(quad: PageQuad.full));

  /// Applies the crop, straightening the page off the UI thread.
  ///
  /// Returns the corrected page, or null when correction failed. A full-page
  /// crop skips the work entirely — there is nothing to straighten, and running
  /// the transform anyway would re-encode the capture for no benefit.
  Future<CapturedPage?> confirm({required String destinationPath}) async {
    if (state.quad.isFullPage) {
      final unchanged = state.page.copyWith(quad: PageQuad.full);
      emit(state.copyWith(status: CropStatus.done, page: unchanged));
      return unchanged;
    }

    emit(state.copyWith(status: CropStatus.correcting));

    final result = await _correct.single(
      PageCorrectionRequest.forQuad(
        sourcePath: state.page.imagePath,
        destinationPath: destinationPath,
        quad: state.quad,
      ),
    );

    switch (result) {
      case Success(:final value):
        final corrected = state.page.copyWith(
          imagePath: value,
          quad: state.quad,
          isCorrected: true,
        );
        emit(state.copyWith(status: CropStatus.done, page: corrected));
        return corrected;
      case Failed(:final failure):
        // Back to adjusting rather than to a dead end: the original capture is
        // untouched, so the user can change the crop and try again.
        emit(state.copyWith(status: CropStatus.adjusting, failure: failure));
        return null;
    }
  }
}

/// The failure shown when a scan is started without a usable camera.
///
/// Exposed so the capture screen and its previews agree on what "no camera"
/// looks like without either constructing it inline.
const cameraUnavailableFailure = Failure.camera();
