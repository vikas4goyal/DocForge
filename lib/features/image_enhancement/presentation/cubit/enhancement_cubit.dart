/// The Cubit driving the enhancement screen.
///
/// Every method is emit / await a use case / emit. Clamping, which settings
/// count as a change, which pages a bulk apply touches and all of the pixel
/// arithmetic live in the domain and application layers and are unit-tested
/// there.
library;

import 'dart:async';
import 'dart:io';

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

  /// The preview file currently on screen, so the next render can remove it.
  String? _lastPreviewPath;

  /// Deletes a superseded preview, ignoring a file that has already gone.
  ///
  /// Derived data: failing to remove one is untidy, never a reason to interrupt
  /// what the user is doing.
  Future<void> _discard(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object {
      // Nothing to report: the preview it describes is no longer on screen.
    }
  }

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
  static const _previewDebounceDelay = Duration(milliseconds: 120);

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
  );

  /// Sets the contrast offset and re-renders the preview.
  Future<void> setContrast(double value) => _updateSettings(
    state.settings.copyWith(contrast: value),
    adjustment: #contrast,
  );

  /// Sets the sharpening amount and re-renders the preview.
  Future<void> setSharpen(double value) => _updateSettings(
    state.settings.copyWith(sharpen: value),
    adjustment: #sharpen,
  );

  /// Turns shadow removal on or off and re-renders the preview.
  Future<void> setShadowRemoval({required bool enabled}) => _updateSettings(
    state.settings.copyWith(shadowRemoval: enabled),
    adjustment: (#shadowRemoval, enabled),
  );

  /// Steps back through one adjustment.
  ///
  /// Distinct from [reset], which returns to the defaults in one go. Undo walks
  /// the decisions the user actually made — auto enhance, then black and white,
  /// then a brightness change — one click at a time.
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

  /// Returns every setting to its default and shows the unmodified page.
  ///
  /// No preview is rendered: the default settings are the captured page, and
  /// the file for it already exists.
  void reset() {
    // Recorded like any other adjustment, so a reset pressed by mistake does
    // not cost the user everything they had set up.
    final history = state.hasChanges
        ? [...state.history, state.settings]
        : state.history;
    _openAdjustment = null;

    emit(
      state.copyWith(
        status: EnhancementStatus.ready,
        settings: EnhancementSettings.none,
        history: history,
        previewPath: state.page?.imagePath,
      ),
    );
  }

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
  Future<void> _updateSettings(
    EnhancementSettings settings, {
    required Object adjustment,
  }) async {
    // A new step records where it started; continuing an open one does not, so
    // a drag leaves a single entry rather than one per frame.
    final startsNewStep = adjustment != _openAdjustment;
    _openAdjustment = adjustment;

    final history = startsNewStep
        ? [...state.history, state.settings]
        : state.history;

    // The settings themselves are emitted at once, so every control stays
    // attached to the finger; only the expensive render is deferred.
    emit(state.copyWith(settings: settings, history: history));

    _previewDebounce?.cancel();
    _previewDebounce = Timer(_previewDebounceDelay, () {
      if (isClosed) return;
      unawaited(_renderPreview(settings));
    });
  }

  /// Renders a downscaled preview of [settings].
  Future<void> _renderPreview(EnhancementSettings settings) async {
    final page = state.page;
    if (page == null) return;

    final generation = ++_previewGeneration;
    emit(state.copyWith(status: EnhancementStatus.previewing));

    final result = await _apply.preview(
      sourcePath: page.imagePath,
      // A fresh path per render. Writing every preview to the same name meant
      // the widget kept an already-resolved stream for an unchanged FileImage —
      // equal by path and scale — so the picture never changed however many
      // times the bytes did. Evicting the cache is not enough on its own,
      // because an attached stream is not re-resolved for an equal provider.
      destinationPath: '${_destinationFor(page, isPreview: true)}.$generation',
      settings: settings,
    );

    // A superseded preview is dropped rather than emitted. Its result describes
    // settings the user has already moved past.
    if (generation != _previewGeneration || isClosed) return;

    // Each render leaves its own file, so the one it replaces is removed rather
    // than left to accumulate for the length of the session — a slider drag
    // would otherwise strew a preview per pause across the staging area.
    if (result case Success(:final value)) {
      final superseded = _lastPreviewPath;
      _lastPreviewPath = value;
      if (superseded != null && superseded != value) {
        unawaited(_discard(superseded));
      }
    }

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
    // A pending debounce would otherwise fire into a closed Cubit.
    _previewDebounce?.cancel();
    await _batchSubscription?.cancel();
    return super.close();
  }
}
