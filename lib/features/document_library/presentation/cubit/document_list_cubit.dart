/// Drives a document list.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the state of one document list.
///
/// Holds no business logic: each method emits a state, awaits a use case and
/// emits the result. Which documents belong in a filter, how they are ordered
/// and what a duplicate is called are all decided in the domain and application
/// layers and unit-tested there.
class DocumentListCubit extends Cubit<DocumentListState> {
  /// Creates the Cubit over its use cases, scoped to [filter].
  DocumentListCubit(
    this._loadDocuments,
    this._toggleFavourite,
    this._archiveDocument,
    this._restoreDocument, {
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) : super(DocumentListState.initial(filter: filter, folderId: folderId));

  final LoadDocuments _loadDocuments;
  final ToggleFavourite _toggleFavourite;
  final ArchiveDocument _archiveDocument;
  final RestoreDocument _restoreDocument;

  /// Loads the first page of documents, replacing anything already shown.
  ///
  /// Also serves refresh and retry: both want the list rebuilt from offset
  /// zero, and a separate method would be the same three lines.
  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final result = await _loadDocuments(
      filter: state.filter,
      sort: state.sort,
      folderId: state.folderId,
    );

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: value.documents.isEmpty
                ? LoadStatus.empty
                : LoadStatus.ready,
            documents: value.documents,
            hasMore: value.hasMore,
            isLoadingMore: false,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(status: LoadStatus.failure, failure: failure));
    }
  }

  /// Appends the next page of documents.
  ///
  /// Ignored when a page is already in flight or none remain, so a scroll
  /// listener firing repeatedly at the bottom of the list cannot issue
  /// duplicate queries or append the same page twice.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final result = await _loadDocuments(
      filter: state.filter,
      sort: state.sort,
      folderId: state.folderId,
      offset: state.documents.length,
    );

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            documents: [...state.documents, ...value.documents],
            hasMore: value.hasMore,
            isLoadingMore: false,
          ),
        );
      case Failed(:final failure):
        // The existing rows are kept: a failed *additional* page is not a
        // reason to discard the documents already on screen.
        emit(state.copyWith(isLoadingMore: false, failure: failure));
    }
  }

  /// Changes the ordering and reloads from the first page.
  Future<void> changeSort(DocumentSort sort) async {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    await load();
  }

  /// Toggles whether [id] is a favourite.
  Future<void> toggleFavourite(DocumentId id) =>
      _applyAction(() => _toggleFavourite(id));

  /// Archives [id].
  Future<void> archive(DocumentId id) =>
      _applyAction(() => _archiveDocument(id));

  /// Restores archived document [id].
  Future<void> restore(DocumentId id) =>
      _applyAction(() => _restoreDocument(id));

  /// Runs a lifecycle action, then reloads so the list reflects the outcome.
  ///
  /// Reloading rather than patching the row in place: archiving and favouriting
  /// can both move a document out of the current filter, and reconstructing
  /// that decision here would duplicate the visibility rule the query already
  /// applies.
  Future<void> _applyAction(Future<Result<Document>> Function() action) async {
    final result = await action();

    if (result case Failed(:final failure)) {
      emit(state.copyWith(failure: failure));
      return;
    }

    await load();
  }
}
