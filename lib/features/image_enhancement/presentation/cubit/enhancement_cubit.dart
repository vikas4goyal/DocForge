/// The Cubit driving the enhancement screen.
///
/// Every method is emit / await a render / emit. Clamping and which settings
/// count as a change live in the domain layer and are unit-tested there.
///
/// Enhancement is *settings over the page's current geometry*, never pixels
/// baked into it: the preview and the final result are both produced by the
/// shared render pipeline from the untouched original, which is what stops the
/// enhancement compounding and what lets it follow a later crop
/// (`design.md` D6, D7a).
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/contracts/page_renderer.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the enhancement screen for one page.
class EnhancementCubit extends Cubit<EnhancementState> {
  /// Creates the Cubit for [page], rendering through [_render].
  EnhancementCubit(PageDraft page, this._render)
    : super(EnhancementState.initial(page));

  final PageRenderer _render;

  int? _previewMaximumDimension;

  String get _renderScope => 'enhancement:${state.page.id.value}';

  /// Counts preview requests so a slow one cannot overwrite a newer result.
  ///
  /// Dragging a slider starts a preview per frame, and they do not necessarily
  /// finish in the order they began. Without this, releasing the slider can
  /// leave the screen showing the preview for a value the user passed through
  /// on the way, which reads as the control being broken.
  int _previewGeneration = 0;

  /// Coalesces slider movement into one render per pause.
  ///
  /// [_previewGeneration] already discards *results* the user has moved past,
  /// but the work still ran: a drag across a slider queued a full render per
  /// frame, each spawning an isolate, and the screen stayed busy long after the
  /// finger stopped. Waiting for a short gap means only the value the user
  /// actually settled on is ever rendered.
  Timer? _previewDebounce;

  /// How long settings must stay unchanged before the preview is rendered.
  ///
  /// Long enough to swallow a drag, short enough that a deliberate single
  /// adjustment still feels immediate.
  static const _previewDebounceDelay = Duration(seconds: 1);

  /// Which control produced the most recent adjustment.
  ///
  /// Consecutive changes from the same control are one undo step: dragging the
  /// brightness slider is a single decision, however many values it passed
  /// through on the way. Moving to a different control ends the step.
  Object? _openAdjustment;

  /// Selects [filter] and re-renders the preview.
  Future<void> selectFilter(EnhancementFilter filter) => _updateSettings(
    state.settings.copyWith(filter: filter),
    // Keyed by the chosen filter, not by "the filter control": picking
    // grayscale after black and white is two decisions, and undo has to step
    // back through both.
    adjustment: (#filter, filter),
  );

  /// Sets the brightness offset and re-renders the preview.
  Future<void> setBrightness(double value) => _updateSettings(
    state.settings.copyWith(brightness: value),
    adjustment: #brightness,
    debouncePreview: true,
  );

  /// Sets the contrast offset and re-renders the preview.
  Future<void> setContrast(double value) => _updateSettings(
    state.settings.copyWith(contrast: value),
    adjustment: #contrast,
    debouncePreview: true,
  );

  /// Sets the sharpening amount and re-renders the preview.
  Future<void> setSharpen(double value) => _updateSettings(
    state.settings.copyWith(sharpen: value),
    adjustment: #sharpen,
    debouncePreview: true,
  );

  /// Turns shadow removal on or off and re-renders the preview.
  Future<void> setShadowRemoval({required bool enabled}) => _updateSettings(
    state.settings.copyWith(shadowRemoval: enabled),
    adjustment: (#shadowRemoval, enabled),
  );

  /// Uses the exact rounded physical-pixel size measured by the preview view.
  ///
  /// Orientation and layout changes report a new value. Because the dimension
  /// is part of the render plan, differently sized previews cannot share a
  /// stale cached file.
  Future<void> updatePreviewDimension(int dimension) async {
    if (dimension <= 0 || _previewMaximumDimension == dimension) return;
    _previewMaximumDimension = dimension;
    _previewDebounce?.cancel();
    await _renderPreview(state.settings);
  }

  /// Steps back through one adjustment.
  ///
  /// Distinct from [revertEnhancement], which returns to the defaults in one
  /// go. Undo walks the decisions the user actually made — auto enhance, then
  /// black and white, then a brightness change — one click at a time.
  Future<void> undo() async {
    if (!state.canUndo) return;

    final history = [...state.history];
    final previous = history.removeLast();

    // The step is closed, so the next adjustment starts a new one rather than
    // coalescing into the one just undone.
    _openAdjustment = null;

    emit(state.copyWith(settings: previous, history: history));
    await _renderPreview(previous);
  }

  /// Returns every setting to its default, keeping the page's crop.
  ///
  /// Named for the layer it affects. The geometry is deliberately untouched:
  /// the page stays cropped, at its cropped size, which is the counterpart of
  /// the crop screen's revert keeping the enhancement.
  Future<void> revertEnhancement() async {
    if (!state.hasChanges) return;

    // Recorded like any other adjustment, so a revert pressed by mistake does
    // not cost the user everything they had set up.
    _openAdjustment = null;

    emit(
      state.copyWith(
        status: EnhancementStatus.ready,
        settings: EnhancementSettings.none,
        history: [...state.history, state.settings],
      ),
    );
    await _renderPreview(EnhancementSettings.none);
  }

  /// Re-renders the preview after a failure.
  Future<void> retry() => _renderPreview(state.settings);

  /// The page carrying the settings as they now stand.
  ///
  /// What the screen hands back when the user finishes. Nothing on disk has
  /// changed: the settings travel with the page and the full-resolution result
  /// is produced when the document is built.
  PageDraft get edited => state.edited;

  /// Applies [settings] and renders a preview of them.
  Future<void> _updateSettings(
    EnhancementSettings settings, {
    required Object adjustment,
    bool debouncePreview = false,
  }) async {
    // A new step records where it started; continuing an open one does not, so
    // a drag leaves a single entry rather than one per frame.
    final startsNewStep = adjustment != _openAdjustment;
    _openAdjustment = adjustment;

    emit(
      state.copyWith(
        settings: settings,
        history: startsNewStep
            ? [...state.history, state.settings]
            : state.history,
      ),
    );

    _previewDebounce?.cancel();
    if (!debouncePreview) {
      await _renderPreview(settings);
      return;
    }

    _previewDebounce = Timer(
      _previewDebounceDelay,
      () => unawaited(_renderPreview(settings)),
    );
  }

  /// Renders the page at [settings] and shows the result.
  Future<void> _renderPreview(EnhancementSettings settings) async {
    final generation = ++_previewGeneration;
    final previous = state.previewPath;

    emit(state.copyWith(status: EnhancementStatus.previewing));

    final rendered = await _render(
      PageRenderPlan.of(
        state.page.withEnhancement(settings),
        maximumPreviewDimension: _previewMaximumDimension,
      ),
      scope: _renderScope,
    );
    if (isClosed || generation != _previewGeneration) return;

    switch (rendered) {
      case Success(:final value):
        emit(
          state.copyWith(status: EnhancementStatus.ready, previewPath: value),
        );
        // The superseded render is only worth removing once its replacement is
        // on screen; doing it earlier would blank the preview mid-adjustment.
        if (previous != null && previous != value) await _discard(previous);
      case Failed(:final failure):
        emit(
          state.copyWith(status: EnhancementStatus.failure, failure: failure),
        );
    }
  }

  /// Deletes a superseded preview, ignoring a file that has already gone.
  ///
  /// Derived data: failing to remove one is untidy, never a reason to interrupt
  /// what the user is doing. Never deletes the original, which is the fallback
  /// the screen shows before the first render lands.
  Future<void> _discard(String path) async {
    if (path == state.page.originalImagePath) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object {
      // Nothing to report: the preview it describes is no longer on screen.
    }
  }

  @override
  Future<void> close() async {
    _previewDebounce?.cancel();
    ++_previewGeneration;
    await _render.cancel(_renderScope);
    await super.close();
  }
}
