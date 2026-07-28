/// The Cubit driving the save dialog.
///
/// Validation lives in `CreationRules` and is unit-tested there; this class
/// records what the user typed, reports whether it can be saved, and runs the
/// save.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/save_document_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Writes the document, returning the record it created.
///
/// A function rather than the use case itself: the creation feature has no
/// business depending on `pdf_generation`, and this is the whole of what it
/// needs from it.
typedef SaveDocumentRequest =
    Future<Result<Document>> Function(
      List<PageDraft> pages, {
      required String title,
      required List<String> folders,
      String? password,
      FolderId? folderId,
    });

/// Drives the save dialog.
class SaveDocumentCubit extends Cubit<SaveDocumentState> {
  /// Creates the Cubit for [pages], writing through [save].
  ///
  /// [suggestedName] is the name the dialog opens with, generated from the
  /// configured naming pattern by the caller — the Cubit does not know what
  /// patterns exist.
  SaveDocumentCubit({
    required List<PageDraft> pages,
    required this.save,
    required this.folders,
    String suggestedName = '',
    this.folderId,
  }) : _pages = pages,
       super(
         SaveDocumentState.initial(
           name: suggestedName,
           hasPages: pages.isNotEmpty,
         ),
       );

  final List<PageDraft> _pages;

  /// Writes the document.
  final SaveDocumentRequest save;

  /// The folder the document is written into, relative to the library root.
  final List<String> folders;

  /// The folder record the document belongs to, when it is in one.
  final FolderId? folderId;

  /// Records the name as the user types it.
  void nameChanged(String name) => emit(state.copyWith(name: name));

  /// Records the password as the user types it.
  void passwordChanged(String password) =>
      emit(state.copyWith(password: password));

  /// Records the confirmation as the user types it.
  void confirmationChanged(String confirmation) =>
      emit(state.copyWith(confirmation: confirmation));

  /// Turns password protection on or off.
  ///
  /// Turning it off clears both fields rather than keeping them hidden: a
  /// password the user has decided against must not be applied because they
  /// toggled the switch twice.
  void passwordEnabledChanged({required bool enabled}) => emit(
    enabled
        ? state.copyWith(passwordEnabled: true)
        : state.copyWith(
            passwordEnabled: false,
            password: '',
            confirmation: '',
          ),
  );

  /// Writes the document.
  ///
  /// Returns the saved record, or null when the write failed — the dialog stays
  /// open in that case, with the pages intact, so the user can retry.
  Future<Document?> submit() async {
    if (!state.canSave) return null;

    emit(state.copyWith(status: SaveStatus.saving));

    final result = await save(
      _pages,
      title: state.name.trim(),
      folders: folders,
      password: state.effectivePassword,
      folderId: folderId,
    );
    if (isClosed) return null;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: SaveStatus.editing));
        return value;
      case Failed(:final failure):
        // Back to editing rather than to a dead end: nothing was written, the
        // pages are intact, and the user can change the name and try again.
        emit(state.copyWith(status: SaveStatus.failure, failure: failure));
        return null;
    }
  }
}
