/// The Cubit driving the sharing options.
///
/// Every method is emit / await a use case / emit. What may be shared, in what
/// order, under what name, and whether a control is offered at all are rules in
/// the domain layer and are unit-tested there.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_scanly/features/document_sharing/domain/share_content.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the sharing, printing and export options for one document.
class ShareCubit extends Cubit<ShareState> {
  /// Creates the Cubit for [_documentId] over its use cases.
  ShareCubit(
    this._documentId,
    this._sharePdf,
    this._shareImages,
    this._shareText,
    this._print,
    this._export, {
    ShareState initial = const ShareState.initial(),
  }) : super(initial);

  final DocumentId _documentId;
  final ShareDocumentPdf _sharePdf;
  final SharePageImages _shareImages;
  final ShareExtractedText _shareText;
  final PrintDocument _print;
  final ExportDocument _export;

  /// The token cancelling an in-flight page render.
  ///
  /// Held here rather than in the state because it is a handle on running work,
  /// not something the UI renders, and putting it in an Equatable state would
  /// make two otherwise identical states compare unequal.
  CancellationToken? _token;

  /// Shares the document's PDF.
  Future<void> sharePdf() async {
    emit(
      state.copyWith(
        status: ShareStatus.preparing,
        action: ShareAction.share,
        format: ShareFormat.pdf,
      ),
    );

    _settle(await _sharePdf(_documentId));
  }

  /// Renders [pageIds] as images and shares them.
  ///
  /// An empty [pageIds] shares every page.
  Future<void> shareImages({List<PageId> pageIds = const []}) async {
    final token = CancellationToken();
    _token = token;

    emit(
      state.copyWith(
        status: ShareStatus.preparing,
        action: ShareAction.share,
        format: ShareFormat.images,
      ),
    );

    await for (final event in _shareImages(
      _documentId,
      pageIds: pageIds,
      token: token,
    )) {
      if (isClosed) return;

      switch (event) {
        case SharePreparationProgress(:final progress):
          emit(state.copyWith(progress: progress));
        case SharePreparationReady():
          emit(state.copyWith(status: ShareStatus.done));
        case SharePreparationFailed(:final failure):
          emit(
            state.copyWith(
              // Cancellation is not an error: the sheet simply returns to its
              // options with nothing said.
              status: failure.isCancellation
                  ? ShareStatus.idle
                  : ShareStatus.failure,
              failure: failure.isCancellation ? null : failure,
            ),
          );
      }
    }

    _token = null;
  }

  /// Shares the document's recognised text.
  Future<void> shareText() async {
    emit(
      state.copyWith(
        status: ShareStatus.preparing,
        action: ShareAction.share,
        format: ShareFormat.text,
      ),
    );

    _settle(await _shareText(_documentId));
  }

  /// Prints the document.
  ///
  /// Named `printDocument` rather than `print`: a method called `print`
  /// shadows `dart:core`'s inside its own class, so every genuine log call in
  /// here would silently become a recursive Cubit call.
  Future<void> printDocument() async {
    emit(
      state.copyWith(
        status: ShareStatus.preparing,
        action: ShareAction.print,
        format: ShareFormat.pdf,
      ),
    );

    final result = await _print(_documentId);
    if (isClosed) return;

    switch (result) {
      // False means the dialogue was dismissed. Nothing changed and nothing is
      // said, so the sheet returns to its options rather than reporting done.
      case Success(:final value):
        emit(
          state.copyWith(status: value ? ShareStatus.done : ShareStatus.idle),
        );
      case Failed(:final failure):
        emit(state.copyWith(status: ShareStatus.failure, failure: failure));
    }
  }

  /// Exports the document to a destination the user picks.
  Future<void> export({String? initialDirectory}) async {
    emit(
      state.copyWith(
        status: ShareStatus.preparing,
        action: ShareAction.export,
        format: ShareFormat.pdf,
      ),
    );

    final result = await _export(
      _documentId,
      initialDirectory: initialDirectory,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            // A null destination means the picker was cancelled: nothing was
            // written, so there is nothing to confirm.
            status: value == null ? ShareStatus.idle : ShareStatus.done,
            exportedTo: value,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(status: ShareStatus.failure, failure: failure));
    }
  }

  /// Abandons an in-flight preparation.
  void cancel() {
    _token?.cancel();
    _token = null;
  }

  /// Returns to the options after a failure.
  void dismissError() => emit(state.copyWith(status: ShareStatus.idle));

  /// Emits the outcome of an operation that either worked or did not.
  void _settle(Result<void> result) {
    if (isClosed) return;

    switch (result) {
      case Success():
        emit(state.copyWith(status: ShareStatus.done));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: failure.isCancellation
                ? ShareStatus.idle
                : ShareStatus.failure,
            failure: failure.isCancellation ? null : failure,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _token?.cancel();
    return super.close();
  }
}
