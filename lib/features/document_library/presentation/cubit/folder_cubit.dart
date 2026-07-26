/// Drives the folder list.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_forge/features/document_library/domain/library_rules.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the folder list and the create, rename and delete actions on it.
///
/// Duplicate-name rejection and the folder-deletion strategy are decided in the
/// use cases; this Cubit only routes the outcome to the right surface — a
/// validation message beside the text field, or a screen-level error.
class FolderCubit extends Cubit<FolderState> {
  /// Creates the Cubit over its use cases.
  FolderCubit(
    this._loadFolders,
    this._createFolder,
    this._renameFolder,
    this._deleteFolder,
  ) : super(const FolderState.initial());

  final LoadFolders _loadFolders;
  final CreateFolder _createFolder;
  final RenameFolder _renameFolder;
  final DeleteFolder _deleteFolder;

  /// Loads every folder with its current document count.
  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final result = await _loadFolders();

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: value.isEmpty ? LoadStatus.empty : LoadStatus.ready,
            folders: value,
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

  /// Creates a folder named [name].
  ///
  /// Returns whether it was created, so a dialog knows whether to close or to
  /// stay open showing the validation message.
  Future<bool> create(String name) => _mutate(() => _createFolder(name));

  /// Renames [id] to [name].
  Future<bool> rename(FolderId id, String name) =>
      _mutate(() => _renameFolder(id, name));

  /// Deletes [id], applying [strategy] to the documents it contains.
  ///
  /// The strategy is chosen by the user before this is called; there is no
  /// default, because a folder deletion must never silently decide the fate of
  /// the documents inside it.
  Future<bool> delete(FolderId id, FolderDeletionStrategy strategy) =>
      _mutate(() => _deleteFolder(id, strategy));

  /// Clears the validation message, e.g. once the user edits the name.
  void clearValidation() => emit(state.copyWith(status: state.status));

  /// Runs a folder mutation and reloads, routing failures to the right surface.
  Future<bool> _mutate(Future<Result<Object?>> Function() action) async {
    emit(state.copyWith(isWorking: true));

    final result = await action();

    if (result case Failed(:final failure)) {
      // A rejected name belongs beside the field the user is still editing; a
      // storage error belongs in the screen-level error surface. Splitting them
      // here is what keeps a correctable mistake from looking like a crash.
      emit(
        state.copyWith(
          isWorking: false,
          validationFailure: failure is ValidationFailure ? failure : null,
          failure: failure is ValidationFailure ? null : failure,
        ),
      );
      return false;
    }

    await load();
    return true;
  }
}
