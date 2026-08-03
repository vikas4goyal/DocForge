/// Drives the document detail screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the state of one document's detail screen.
///
/// Every method is emit / await a use case / emit. The rules — that a rename
/// refuses an empty title, that a duplicate gets its own files, that permanent
/// removal deletes the password before the record — live in the use cases.
class DocumentDetailCubit extends Cubit<DocumentDetailState> {
  /// Creates the Cubit over its use cases, for the document [documentId].
  DocumentDetailCubit(
    this.documentId,
    this._loadDetail,
    this._rename,
    this._move,
    this._toggleFavourite,
    this._archive,
    this._restore,
    this._duplicate,
    this._purge, {
    this.moveToTrash,
  }) : super(const DocumentDetailState.initial());

  /// The document this screen shows.
  final DocumentId documentId;

  final LoadDocumentDetail _loadDetail;
  final RenameDocument _rename;
  final MoveDocument _move;
  final ToggleFavourite _toggleFavourite;
  final ArchiveDocument _archive;
  final RestoreDocument _restore;
  final DuplicateDocument _duplicate;
  final PurgeDocument _purge;

  /// Recoverable deletion used by production; null only in legacy unit fakes.
  final MoveDocumentToTrash? moveToTrash;

  /// Loads the document and its pages.
  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final result = await _loadDetail(documentId);

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            document: value.document,
            pages: value.pages,
            isWorking: false,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.failure,
            isWorking: false,
            failure: failure,
          ),
        );
    }
  }

  /// Renames the document to [title].
  ///
  /// An empty title is refused by the use case and surfaces here as a message
  /// beside the field; the existing title is untouched.
  Future<void> rename(String title) =>
      _mutate(() => _rename(documentId, title));

  /// Moves the document into [folderId], or unfiles it when null.
  Future<void> move(FolderId? folderId) =>
      _mutate(() => _move(documentId, folderId));

  /// Toggles the document's favourite status.
  Future<void> toggleFavourite() => _mutate(() => _toggleFavourite(documentId));

  /// Archives the document.
  Future<void> archive() => _mutate(() => _archive(documentId));

  /// Restores the document from the archive.
  Future<void> restore() => _mutate(() => _restore(documentId));

  /// Creates an independent copy of the document.
  ///
  /// Returns the copy so the caller can navigate to it. The current screen
  /// keeps showing the original, which is what the user still has open.
  Future<Document?> duplicate() async {
    emit(state.copyWith(isWorking: true));

    final result = await _duplicate(documentId);

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(isWorking: false));
        return value;
      case Failed(:final failure):
        emit(state.copyWith(isWorking: false, failure: failure));
        return null;
    }
  }

  /// Moves the document to recoverable Trash.
  ///
  /// The caller confirms first — this method does not ask. On success it sets
  /// `isDeleted` rather than reloading, because there is nothing left to load
  /// and the screen must leave rather than render a missing document.
  Future<void> delete() async {
    emit(state.copyWith(isWorking: true));

    final result = moveToTrash == null
        ? await _purge(documentId)
        : await moveToTrash!(documentId);

    switch (result) {
      case Success():
        emit(state.copyWith(isWorking: false, isDeleted: true));
      case Failed(:final failure):
        emit(state.copyWith(isWorking: false, failure: failure));
    }
  }

  /// Runs a metadata mutation, then reloads so the screen shows what was saved.
  ///
  /// Reloading rather than emitting the returned document: the modified date
  /// and the page list both come from storage, and showing an optimistic value
  /// that storage later disagrees with is worse than a brief spinner.
  Future<void> _mutate(Future<Result<Document>> Function() action) async {
    emit(state.copyWith(isWorking: true));

    final result = await action();

    if (result case Failed(:final failure)) {
      emit(state.copyWith(isWorking: false, failure: failure));
      return;
    }

    await load();
  }
}
