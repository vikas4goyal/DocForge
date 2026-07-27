/// The Cubit driving the import flow.
///
/// Every method is emit / await a use case / emit. Which file types are
/// accepted, which permission a source needs and what a rejection says are
/// rules in the domain layer and are unit-tested there.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_forge/features/document_import/domain/import_rules.dart';
import 'package:doc_forge/features/document_import/domain/repositories/import_repository.dart';
import 'package:doc_forge/features/document_import/presentation/cubit/import_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives importing from the gallery, device files and the share sheet.
class ImportCubit extends Cubit<ImportState> {
  /// Creates the Cubit over its pickers and use cases.
  ImportCubit(this._gallery, this._files, this._import)
    : super(const ImportState.initial());

  final GalleryPicker _gallery;
  final FileBrowser _files;
  final ImportFiles _import;

  /// The token cancelling an in-flight import.
  ///
  /// Held here rather than in the state because it is a handle on running work,
  /// not something the UI renders.
  CancellationToken? _token;

  /// The paths being imported, kept so a password retry can resume them.
  List<String> _pending = const [];

  /// Imports images chosen from the photo library.
  Future<void> fromGallery() async {
    emit(
      state.copyWith(
        status: ImportStatus.choosing,
        source: ImportSource.gallery,
      ),
    );

    await _pick(_gallery.pickImages(), ImportSource.gallery);
  }

  /// Imports PDFs or images chosen from device files.
  Future<void> fromFiles() async {
    emit(
      state.copyWith(status: ImportStatus.choosing, source: ImportSource.files),
    );

    await _pick(_files.pickFiles(), ImportSource.files);
  }

  /// Imports [paths] handed over by another application.
  Future<void> fromShareSheet(List<String> paths) =>
      _run(paths, ImportSource.shareSheet);

  /// Retries a protected PDF with the password the user entered.
  Future<void> submitPassword(String password) async {
    if (_pending.isEmpty) return;
    await _run(
      _pending,
      state.source ?? ImportSource.files,
      password: password,
    );
  }

  /// Abandons a protected import without creating a document.
  void cancelPassword() {
    _pending = const [];
    emit(const ImportState.initial());
  }

  /// Abandons an in-flight import.
  void cancel() {
    _token?.cancel();
    _token = null;
  }

  /// Returns to the sources after a failure.
  void dismissError() => emit(const ImportState.initial());

  /// Opens a picker and imports whatever it returns.
  Future<void> _pick(
    Future<Result<List<String>>> picking,
    ImportSource source,
  ) async {
    final picked = await picking;
    if (isClosed) return;

    switch (picked) {
      case Success(:final value):
        if (value.isEmpty) {
          // A cancelled picker. Nothing was selected, so the sheet returns to
          // its sources with nothing said.
          emit(const ImportState.initial());
          return;
        }
        await _run(value, source);
      case Failed(:final failure):
        emit(
          state.copyWith(
            // A refused permission has its own view, the only one offering a
            // route to system settings.
            status: failure is PermissionFailure
                ? ImportStatus.permissionDenied
                : ImportStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  /// Runs the import of [paths] and folds its events into state.
  Future<void> _run(
    List<String> paths,
    ImportSource source, {
    String? password,
  }) async {
    _pending = paths;

    final token = CancellationToken();
    _token = token;

    emit(
      state.copyWith(
        status: ImportStatus.importing,
        source: source,
        imported: const [],
      ),
    );

    await for (final event in _import(
      paths,
      source: source,
      token: token,
      password: password,
    )) {
      if (isClosed) return;

      switch (event) {
        case ImportProgressed(:final progress):
          emit(state.copyWith(progress: progress));
        case ImportedDocument(:final document):
          emit(state.copyWith(imported: [...state.imported, document]));
        case ImportReadyForReview(:final bundle):
          emit(
            state.copyWith(status: ImportStatus.readyForReview, bundle: bundle),
          );
        case ImportNeedsPassword(:final sourcePath):
          emit(
            state.copyWith(
              status: ImportStatus.awaitingPassword,
              protectedFilePath: sourcePath,
              // Only a *second* prompt means the entry was wrong; the first is
              // simply the file asking.
              passwordRejected: password != null,
            ),
          );
          return;
        case ImportFailed(:final failure):
          emit(
            state.copyWith(
              // Cancellation is not an error: the sheet returns to its sources
              // with nothing said.
              status: failure.isCancellation
                  ? ImportStatus.idle
                  : ImportStatus.failure,
              failure: failure.isCancellation ? null : failure,
            ),
          );
          return;
      }
    }

    if (isClosed) return;
    _token = null;

    // Reached only when the stream ended without a review bundle or a failure,
    // which is the PDF-only path: every file became a document.
    if (state.status == ImportStatus.importing) {
      emit(state.copyWith(status: ImportStatus.done));
    }
  }

  @override
  Future<void> close() {
    _token?.cancel();
    return super.close();
  }
}
