/// The Cubit driving the enhancement screen.
///
/// Every method is emit / await a use case / emit. Clamping, which settings
/// count as a change, which pages a bulk apply touches and all of the pixel
/// arithmetic live in the domain and application layers and are unit-tested
/// there.
library;

import 'dart:async';

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Names the file an enhancement result is written to.
///
/// Injected rather than computed here because where a file may be written is a
/// property of the running application — a cache directory on a device, a
/// temporary directory in a test — and the Cubit must not know which.
typedef EnhancementDestination =
    String Function(PageRef page, {required bool isPreview});

/// Drives the enhancement screen.
class EnhancementCubit extends Cubit<EnhancementState> {
  /// Creates the Cubit over the session's [pages] and its collaborators.
  EnhancementCubit(
    List<PageRef> pages,
    this._apply,
    this._plan,
    this._destinationFor, {
    int index = 0,
  }) : super(EnhancementState.initial(pages, index: index));

  final ApplyEnhancement _apply;
  final PlanSessionEnhancement _plan;
  final EnhancementDestination _destinationFor;

  CancellationToken? _batchToken;
  StreamSubscription<BatchEvent<String>>? _batchSubscription;

  /// Counts preview requests so a slow one cannot overwrite a newer result.
  ///
  /// Dragging a slider starts a preview per frame, and they do not necessarily
  /// finish in the order they began. Without this, releasing the slider can
  /// leave the screen showing the preview for a value the user passed through
  /// on the way, which reads as the control being broken.
  int _previewGeneration = 0;

  /// Selects [filter] and re-renders the preview.
  Future<void> selectFilter(EnhancementFilter filter) =>
      _updateSettings(state.settings.copyWith(filter: filter));

  /// Sets the brightness offset and re-renders the preview.
  Future<void> setBrightness(double value) =>
      _updateSettings(state.settings.copyWith(brightness: value));

  /// Sets the contrast offset and re-renders the preview.
  Future<void> setContrast(double value) =>
      _updateSettings(state.settings.copyWith(contrast: value));

  /// Sets the sharpening amount and re-renders the preview.
  Future<void> setSharpen(double value) =>
      _updateSettings(state.settings.copyWith(sharpen: value));

  /// Turns shadow removal on or off and re-renders the preview.
  Future<void> setShadowRemoval({required bool enabled}) =>
      _updateSettings(state.settings.copyWith(shadowRemoval: enabled));

  /// Returns every setting to its default and shows the unmodified page.
  ///
  /// No preview is rendered: the default settings are the captured page, and
  /// the file for it already exists.
  void reset() => emit(
    state.copyWith(
      status: EnhancementStatus.ready,
      settings: EnhancementSettings.none,
      previewPath: state.page?.imagePath,
    ),
  );

  /// Re-renders the preview after a failure.
  Future<void> retry() => _renderPreview(state.settings);

  /// Stores the current settings against the page being enhanced.
  ///
  /// This is what "save" means on this screen: the settings are recorded, and
  /// the full-resolution image is produced later, when the document is built.
  /// Nothing on disk changes until then, which is what makes leaving without
  /// saving leave the stored page untouched.
  void commit() => emit(
    state.copyWith(
      pages: EnhancementRules.applyToPage(
        state.pages,
        state.index,
        state.settings,
      ),
    ),
  );

  /// Applies the current settings to every page of the session.
  ///
  /// Progress is reported per page and the operation can be cancelled, which
  /// the spec requires for a large session.
  Future<void> applyToAll() async {
    final pages = EnhancementRules.applyToAll(state.pages, state.settings);
    final requests = _plan(
      pages,
      destinationFor: (page) => _destinationFor(page, isPreview: false),
    );

    final token = CancellationToken();
    _batchToken = token;

    emit(
      state.copyWith(
        status: EnhancementStatus.applyingToAll,
        pages: pages,
        progress: Progress(completed: 0, total: requests.length),
      ),
    );

    final done = Completer<void>();
    await _batchSubscription?.cancel();

    _batchSubscription = _apply
        .batch(requests, token: token)
        .listen(
          (event) {
            switch (event) {
              case BatchItemCompleted(:final progress):
                emit(
                  state.copyWith(
                    status: EnhancementStatus.applyingToAll,
                    progress: progress,
                  ),
                );
              case BatchItemFailed(:final failure):
                emit(
                  state.copyWith(
                    status: EnhancementStatus.failure,
                    failure: failure,
                  ),
                );
              case BatchCancelled():
                // Back to ready rather than to a failure: cancelling is a choice,
                // not an error, and every page finished before the stop keeps its
                // result.
                emit(state.copyWith(status: EnhancementStatus.ready));
            }
          },
          onDone: () {
            if (state.status == EnhancementStatus.applyingToAll) {
              emit(state.copyWith(status: EnhancementStatus.ready));
            }
            if (!done.isCompleted) done.complete();
          },
        );

    await done.future;
    _batchToken = null;
  }

  /// Stops a running bulk enhancement at the next page boundary.
  void cancelApplyToAll() => _batchToken?.cancel();

  /// Applies [settings] and renders a preview of them.
  Future<void> _updateSettings(EnhancementSettings settings) async {
    emit(state.copyWith(settings: settings));
    await _renderPreview(settings);
  }

  /// Renders a downscaled preview of [settings].
  Future<void> _renderPreview(EnhancementSettings settings) async {
    final page = state.page;
    if (page == null) return;

    final generation = ++_previewGeneration;
    emit(state.copyWith(status: EnhancementStatus.previewing));

    final result = await _apply.preview(
      sourcePath: page.imagePath,
      destinationPath: _destinationFor(page, isPreview: true),
      settings: settings,
    );

    // A superseded preview is dropped rather than emitted. Its result describes
    // settings the user has already moved past.
    if (generation != _previewGeneration || isClosed) return;

    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: EnhancementStatus.ready,
        previewPath: value,
      ),
      Failed(:final failure) => state.copyWith(
        status: EnhancementStatus.failure,
        failure: failure,
      ),
    });
  }

  @override
  Future<void> close() async {
    // Cancelled rather than left running: a batch that outlives its screen has
    // nowhere to report to, and would keep writing files for a session the user
    // has already left.
    _batchToken?.cancel();
    await _batchSubscription?.cancel();
    return super.close();
  }
}
