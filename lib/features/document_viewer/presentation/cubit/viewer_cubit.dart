/// The Cubit driving the document viewer.
///
/// Every method is emit / await a use case / emit. Page clamping, zoom limits
/// and what counts as a valid page number are rules in the domain layer and are
/// unit-tested there.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_scanly/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the document viewer.
class ViewerCubit extends Cubit<ViewerState> {
  /// Creates the Cubit for [_documentId] over its collaborators.
  ViewerCubit(
    this._documentId,
    this._open,
    this._rememberPassword,
    this._loadMetadata,
    this._toggleFavourite,
  ) : super(const ViewerState.initial());

  final DocumentId _documentId;
  final OpenDocumentForViewing _open;
  final RememberDocumentPassword _rememberPassword;
  final LoadViewerMetadata _loadMetadata;
  final ToggleViewerFavourite _toggleFavourite;

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

  /// Toggles favourite status while keeping the readable PDF in place.
  ///
  /// Repeated activation while persistence is in progress is ignored. A typed
  /// failure is exposed as [ViewerState.actionFailure] rather than replacing
  /// the open document with a fatal error view.
  Future<void> toggleFavourite() async {
    if (!state.isReady || state.isFavouriteWorking) return;

    emit(state.copyWith(isFavouriteWorking: true, clearActionFailure: true));
    final result = await _toggleFavourite(_documentId);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            document: value,
            isFavouriteWorking: false,
            clearActionFailure: true,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(isFavouriteWorking: false, actionFailure: failure));
    }
  }

  /// Refreshes document metadata after a secondary screen closes.
  ///
  /// The resolved PDF, password, page count and current page remain unchanged.
  /// A not-found result marks the document unavailable; other failures are
  /// nonfatal and leave reading available.
  Future<void> refreshMetadata() async {
    if (!state.isReady) return;

    final result = await _loadMetadata(_documentId);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            document: value,
            isUnavailable: false,
            clearActionFailure: true,
          ),
        );
      case Failed(:final failure) when failure is NotFoundFailure:
        emit(state.copyWith(isUnavailable: true, clearActionFailure: true));
      case Failed(:final failure):
        emit(state.copyWith(actionFailure: failure));
    }
  }

  /// Retries after a failure.
  Future<void> retry() => load();

  /// Emits the open document.
  Future<void> _showDocument(ViewableDocument viewable) async {
    emit(
      state.copyWith(
        status: ViewerStatus.ready,
        document: viewable.document,
        filePath: viewable.filePath,
        pageCount: viewable.pageCount,
        password: viewable.password,
        page: ViewerRules.clampPage(state.page, pageCount: viewable.pageCount),
        isUnavailable: false,
        isFavouriteWorking: false,
        clearActionFailure: true,
      ),
    );
  }
}
