/// The Cubit driving the PDF editor.
///
/// Every method is emit / await a use case / emit. Which pages an operation
/// acts on, whether it is allowed, and what a size change means are rules in
/// the domain layer and are unit-tested there.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_forge/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The use cases the editor drives.
///
/// Grouped for the same reason [PdfEditContext] is: the Cubit needs all eleven,
/// and eleven positional constructor arguments is a wiring bug waiting to
/// happen.
class PdfEditUseCases {
  /// Creates the set.
  const PdfEditUseCases({
    required this.rotate,
    required this.delete,
    required this.duplicate,
    required this.extract,
    required this.merge,
    required this.split,
    required this.compress,
    required this.watermark,
    required this.protect,
    required this.removePassword,
    required this.metadata,
  });

  /// Rotates one page.
  final RotatePage rotate;

  /// Deletes selected pages.
  final DeletePages delete;

  /// Duplicates one page.
  final DuplicatePage duplicate;

  /// Extracts selected pages into a new document.
  final ExtractPages extract;

  /// Merges several documents.
  final MergeDocuments merge;

  /// Splits a document in two.
  final SplitDocument split;

  /// Compresses a document.
  final CompressDocument compress;

  /// Applies a watermark.
  final WatermarkDocument watermark;

  /// Protects a document with a password.
  final ProtectDocument protect;

  /// Removes a document's password.
  final RemoveDocumentPassword removePassword;

  /// Reads a document's metadata.
  final ReadPdfMetadata metadata;
}

/// Drives the PDF editor for one document.
class PdfEditCubit extends Cubit<PdfEditState> {
  /// Creates the Cubit for [_documentId] over [_useCases].
  PdfEditCubit(this._documentId, this._useCases, this._files)
    : super(const PdfEditState.initial());

  final DocumentId _documentId;
  final PdfEditUseCases _useCases;
  final DocumentFileResolver _files;

  /// Loads the document and its metadata.
  Future<void> load() async {
    emit(state.copyWith(status: PdfEditStatus.loading));

    final result = await _useCases.metadata(_documentId);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        await _refresh(metadata: value);
      case Failed(:final failure):
        emit(state.copyWith(status: PdfEditStatus.failure, failure: failure));
    }
  }

  /// Adds or removes [page] from the selection.
  void toggleSelection(int page) {
    final next = {...state.selection};
    if (!next.remove(page)) next.add(page);
    emit(state.copyWith(selection: next));
  }

  /// Clears the selection.
  void clearSelection() => emit(state.copyWith(selection: const {}));

  /// Rotates the selected page a quarter turn clockwise.
  Future<void> rotate() async {
    final page = state.selectedPage;
    if (page == null) return;

    await _inPlace(
      PdfEditOperation.rotate,
      () => _useCases.rotate(_documentId, page),
    );
  }

  /// Deletes the selected pages.
  Future<void> delete() async {
    await _inPlace(
      PdfEditOperation.delete,
      () => _useCases.delete(_documentId, state.selection),
      // The pages that were selected no longer exist, and a selection pointing
      // past the end of a shorter document would enable operations on pages
      // that are not there.
      clearSelectionAfter: true,
    );
  }

  /// Duplicates the selected page.
  Future<void> duplicate() async {
    final page = state.selectedPage;
    if (page == null) return;

    await _inPlace(
      PdfEditOperation.duplicate,
      () => _useCases.duplicate(_documentId, page),
      clearSelectionAfter: true,
    );
  }

  /// Compresses the document.
  Future<void> compress() async {
    emit(
      state.copyWith(
        status: PdfEditStatus.working,
        operation: PdfEditOperation.compress,
      ),
    );

    final result = await _useCases.compress(_documentId);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        await _refresh(
          compression: CompressionOutcomeView(
            message: value.message,
            wasKept: value.wasKept,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(status: PdfEditStatus.failure, failure: failure));
    }
  }

  /// Applies [text] as a watermark to every page.
  Future<void> watermark(String text) => _inPlace(
    PdfEditOperation.watermark,
    () => _useCases.watermark(_documentId, text),
  );

  /// Protects the document with [password].
  Future<void> protect(String password) => _inPlace(
    PdfEditOperation.protect,
    () => _useCases.protect(_documentId, password),
  );

  /// Removes the document's password.
  ///
  /// A wrong password is reported as a rejection rather than an error: the
  /// document is untouched and the user can try again, which an error view
  /// would make look like something broke.
  Future<void> removePassword(String currentPassword) async {
    emit(
      state.copyWith(
        status: PdfEditStatus.working,
        operation: PdfEditOperation.removePassword,
      ),
    );

    final result = await _useCases.removePassword(_documentId, currentPassword);
    if (isClosed) return;

    switch (result) {
      case Success():
        await _refresh();
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: failure is AuthFailure
                ? PdfEditStatus.ready
                : PdfEditStatus.failure,
            failure: failure is AuthFailure ? null : failure,
            passwordRejected: failure is AuthFailure,
          ),
        );
    }
  }

  /// Extracts the selected pages into a new document.
  Future<void> extract() => _derive(
    PdfEditOperation.extract,
    () => _useCases.extract(_documentId, state.selection),
  );

  /// Merges this document with [others], in the order given.
  Future<void> merge(List<DocumentId> others) => _derive(
    PdfEditOperation.merge,
    () => _useCases.merge([_documentId, ...others]),
  );

  /// Splits the document after one-based page [afterPage].
  Future<void> split(int afterPage) async {
    emit(
      state.copyWith(
        status: PdfEditStatus.working,
        operation: PdfEditOperation.split,
      ),
    );

    final result = await _useCases.split(_documentId, afterPage: afterPage);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        // The first half is what the user is shown; both exist in the library.
        emit(state.copyWith(status: PdfEditStatus.ready, derived: value.$1));
      case Failed(:final failure):
        emit(state.copyWith(status: PdfEditStatus.failure, failure: failure));
    }
  }

  /// Returns to the editor after a failure.
  void dismissError() => emit(state.copyWith(status: PdfEditStatus.ready));

  /// Runs an in-place operation and reloads what it changed.
  Future<void> _inPlace(
    PdfEditOperation operation,
    Future<Result<dynamic>> Function() run, {
    bool clearSelectionAfter = false,
  }) async {
    emit(state.copyWith(status: PdfEditStatus.working, operation: operation));

    final result = await run();
    if (isClosed) return;

    switch (result) {
      case Success():
        await _refresh(clearSelection: clearSelectionAfter);
      case Failed(:final failure):
        emit(state.copyWith(status: PdfEditStatus.failure, failure: failure));
    }
  }

  /// Runs an operation that produces a new document.
  Future<void> _derive(
    PdfEditOperation operation,
    Future<Result<dynamic>> Function() run,
  ) async {
    emit(state.copyWith(status: PdfEditStatus.working, operation: operation));

    final result = await run();
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: PdfEditStatus.ready,
            derived: value as dynamic,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(status: PdfEditStatus.failure, failure: failure));
    }
  }

  /// Re-reads the metadata so the editor reflects what just changed.
  ///
  /// Every in-place operation changes the page count, the size or the
  /// protection status, and re-reading is cheaper and less error-prone than
  /// each operation reporting its own delta.
  Future<void> _refresh({
    PdfMetadata? metadata,
    CompressionOutcomeView? compression,
    bool clearSelection = false,
  }) async {
    final read =
        metadata ?? (await _useCases.metadata(_documentId)).valueOrNull;
    if (isClosed) return;

    final document = (await _useCases.metadata.loadDocument(
      _documentId,
    )).valueOrNull;
    if (isClosed) return;

    // Re-resolved on every refresh, not only on load: an in-place edit replaces
    // the file, and on Android the previous cache copy is of the old bytes.
    final filePath = document == null
        ? null
        : (await _files.pathFor(document)).valueOrNull;
    if (isClosed) return;

    emit(
      state.copyWith(
        status: PdfEditStatus.ready,
        document: document,
        filePath: filePath,
        metadata: read,
        compression: compression,
        selection: clearSelection ? const {} : null,
      ),
    );
  }
}
