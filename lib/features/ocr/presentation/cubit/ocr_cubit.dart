/// The Cubit driving the extracted-text view.
///
/// Every method is emit / await a use case / emit. Which pages still need
/// recognising, how page text is joined, and what counts as "has text" are all
/// rules in the domain layer and are unit-tested there.
library;

import 'dart:async';

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/ocr/application/usecases/ocr_usecases.dart';
import 'package:doc_forge/features/ocr/domain/ocr_rules.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_forge/features/ocr/presentation/cubit/ocr_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Puts text on the system clipboard.
///
/// Injected rather than called directly so the Cubit stays free of Flutter, and
/// so a test can assert what was copied without a platform channel.
typedef ClipboardWriter = Future<void> Function(String text);

/// Exports text as a file through the system share or save flow.
typedef TextExporter =
    Future<Result<void>> Function(String text, {required String fileName});

/// Drives the extracted-text view.
class OcrCubit extends Cubit<OcrState> {
  /// Creates the Cubit for a document over its collaborators.
  OcrCubit(
    this._documentId,
    this._documentTitle,
    OcrState initial,
    this._recognise,
    this._load,
    this._copyToClipboard,
    this._export, {
    this._script = OcrScript.defaultScript,
  }) : super(initial);

  final DocumentId _documentId;
  final String _documentTitle;
  final RecogniseText _recognise;
  final LoadRecognisedText _load;
  final ClipboardWriter _copyToClipboard;
  final TextExporter _export;
  final OcrScript _script;

  CancellationToken? _token;
  StreamSubscription<RecognitionEvent>? _subscription;

  /// Loads whatever has already been recognised.
  ///
  /// Never starts recognition itself. Opening a document must not silently cost
  /// the user a full recognition pass — the spec requires stored text to be
  /// used, and the run to be something they ask for.
  Future<void> load() async {
    emit(state.copyWith(status: OcrStatus.loading));

    final result = await _load(state.pages);

    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: _statusFor(value),
        texts: value,
      ),
      Failed(:final failure) => state.copyWith(
        status: OcrStatus.failure,
        failure: failure,
      ),
    });
  }

  /// Runs recognition over the pages that still need it.
  Future<void> recognise({bool force = false}) async {
    final token = CancellationToken();
    _token = token;

    emit(
      state.copyWith(
        status: OcrStatus.running,
        progress: Progress(completed: 0, total: state.pages.length),
      ),
    );

    final texts = <PageId, RecognisedText>{...state.texts};
    Failure? lastFailure;

    final done = Completer<void>();
    await _subscription?.cancel();

    _subscription =
        _recognise(
          state.pages,
          documentId: _documentId,
          script: _script,
          force: force,
          token: token,
        ).listen(
          (event) {
            if (event.text case final text?) {
              texts[event.pageId] = text;
            } else if (event.failure case final Failure failure) {
              // Recorded but not fatal. One unreadable page says nothing about
              // the next, and the spec requires the document to stay usable
              // without recognised text.
              lastFailure = failure;
            }

            emit(
              state.copyWith(
                status: OcrStatus.running,
                texts: {...texts},
                progress: event.progress,
              ),
            );
          },
          onDone: () {
            emit(
              state.copyWith(
                // A run that recognised nothing at all and hit a failure is an
                // error; one that produced text despite a bad page is not.
                status: texts.isEmpty && lastFailure != null
                    ? OcrStatus.failure
                    : _statusFor(texts),
                texts: {...texts},
                failure: texts.isEmpty ? lastFailure : null,
              ),
            );
            if (!done.isCompleted) done.complete();
          },
        );

    await done.future;
    _token = null;
  }

  /// Runs recognition again, replacing what is stored.
  Future<void> rerun() => recognise(force: true);

  /// Stops a running recognition at the next page boundary.
  ///
  /// Pages already recognised keep their results, which the spec requires.
  void cancel() => _token?.cancel();

  /// Copies the recognised text to the clipboard.
  Future<void> copy() async {
    if (!state.hasText) return;

    await _copyToClipboard(state.combinedText);
    emit(state.copyWith(copied: true));
  }

  /// Exports the recognised text as a plain-text file.
  Future<void> export() async {
    if (!state.hasText) return;

    final result = await _export(
      state.combinedText,
      fileName: OcrRules.exportFileName(_documentTitle),
    );

    if (result case Failed(:final failure)) {
      emit(state.copyWith(status: OcrStatus.failure, failure: failure));
    }
  }

  /// The status implied by [texts].
  OcrStatus _statusFor(Map<PageId, RecognisedText> texts) {
    if (texts.isEmpty) return OcrStatus.notRecognised;
    // Every page read and nothing found is a distinct outcome from "not read
    // yet", and the spec requires it to be shown as such rather than as an
    // error or as an invitation to try again.
    return texts.values.any((text) => !text.isEmpty)
        ? OcrStatus.ready
        : OcrStatus.empty;
  }

  @override
  Future<void> close() async {
    // Cancelled rather than left running: a recognition that outlives its
    // screen has nowhere to report to and keeps the recogniser busy.
    _token?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}
