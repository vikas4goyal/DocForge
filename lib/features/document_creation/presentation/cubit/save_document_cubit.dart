/// The Cubit driving the save dialog.
///
/// Validation lives in `CreationRules` and is unit-tested there; this class
/// records what the user typed, reports whether it can be saved, and runs the
/// save.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_creation/domain/creation_rules.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/save_document_state.dart';
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

/// Whether a document of this name already exists in the target folder.
typedef NameTakenCheck =
    Future<bool> Function(String fileName, List<String> folders);

/// Asks the user whether to replace a document of the same name.
///
/// Returns true to replace, false to go back and choose another name. Asked
/// rather than decided: overwriting silently would destroy a document the user
/// still has, and suffixing silently would give them a name they did not
/// choose.
typedef ReplaceConfirmation = Future<bool> Function(String fileName);

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
    this.isNameTaken,
    this.confirmReplace,
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

  /// Whether the chosen name is already taken in the target folder.
  ///
  /// Optional: a caller with no way to look — a preview, a test that does not
  /// care — leaves it out and the check is skipped.
  final NameTakenCheck? isNameTaken;

  /// Asks whether to replace a document of the same name.
  final ReplaceConfirmation? confirmReplace;

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

    final fileName = CreationRules.fileNameFor(state.name);
    final check = isNameTaken;
    if (check != null && await check(fileName, folders)) {
      final replace = await confirmReplace?.call(fileName) ?? false;
      // Nothing is overwritten without the answer being yes, and the dialog
      // stays open so the user can type a different name.
      if (!replace) return null;
      if (isClosed) return null;
    }

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
