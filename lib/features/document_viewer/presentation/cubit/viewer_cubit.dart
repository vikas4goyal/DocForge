/// The Cubit driving the document viewer.
///
/// Every method is emit / await a use case / emit. Page clamping, zoom limits
/// and what counts as a valid page number are rules in the domain layer and are
/// unit-tested there.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_forge/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_forge/features/document_viewer/presentation/cubit/viewer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the document viewer.
class ViewerCubit extends Cubit<ViewerState> {
  /// Creates the Cubit for [_documentId] over its collaborators.
  ViewerCubit(
    this._documentId,
    this._open,
    this._rememberPassword,
    this._loadText,
  ) : super(const ViewerState.initial());

  final DocumentId _documentId;
  final OpenDocumentForViewing _open;
  final RememberDocumentPassword _rememberPassword;
  final LoadViewerText _loadText;

  /// Opens the document.
  Future<void> load() async {
    emit(state.copyWith(status: ViewerStatus.loading));

    final result = await _open(_documentId);

    switch (result) {
      case Success(:final value):
        await _showDocument(value);
      case Failed(:final failure):
        emit(
          state.copyWith(
            // A protected document is not an error: the prompt is the normal
            // path for one, and showing an error view would suggest something
            // had gone wrong.
            status: failure is AuthFailure
                ? ViewerStatus.locked
                : ViewerStatus.failure,
            failure: failure is AuthFailure ? null : failure,
          ),
        );
    }
  }

  /// Opens the document with the password the user has entered.
  Future<void> unlock(String password) async {
    emit(state.copyWith(status: ViewerStatus.loading));

    final result = await _open(_documentId, password: password);

    switch (result) {
      case Success(:final value):
        // Remembered only after it has actually worked, and only in secure
        // storage. A failure here is not fatal — the document is open, and the
        // only consequence is being asked again next time.
        await _rememberPassword(_documentId, password);
        await _showDocument(value);
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: failure is AuthFailure
                ? ViewerStatus.locked
                : ViewerStatus.failure,
            failure: failure is AuthFailure ? null : failure,
            // A wrong password is not an error state: the prompt stays up and
            // says so.
            passwordRejected: failure is AuthFailure,
          ),
        );
    }
  }

  /// Moves to [page], clamped into the document's range.
  ///
  /// Clamping rather than rejecting means a number beyond the end takes the
  /// user to the last page, which is what they were reaching for.
  void goToPage(int page) => emit(
    state.copyWith(
      page: ViewerRules.clampPage(page, pageCount: state.pageCount),
    ),
  );

  /// Records that the visible page changed as the user scrolled.
  void pageChanged(int page) => goToPage(page);

  /// Retries after a failure.
  Future<void> retry() => load();

  /// Emits the open document and loads its text.
  Future<void> _showDocument(ViewableDocument viewable) async {
    emit(
      state.copyWith(
        status: ViewerStatus.ready,
        document: viewable.document,
        filePath: viewable.filePath,
        pageCount: viewable.pageCount,
        password: viewable.password,
        page: ViewerRules.clampPage(state.page, pageCount: viewable.pageCount),
      ),
    );

    // Loaded after the document is on screen rather than before. Text is a
    // secondary panel, and making the first page wait for it would break the
    // "opens promptly" requirement for no benefit.
    final text = await _loadText(_documentId);
    if (isClosed) return;

    emit(state.copyWith(recognisedText: text));
  }
}
