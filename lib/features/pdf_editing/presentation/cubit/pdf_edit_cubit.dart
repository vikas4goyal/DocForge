/// The Cubit driving the PDF editor.
///
/// Every method is emit / await a use case / emit. Which pages an operation
/// acts on, whether it is allowed, and what a size change means are rules in
/// the domain layer and are unit-tested there.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_operation_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
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
    required this.reorder,
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

  /// Moves one page within the current PDF.
  final ReorderPage reorder;

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
  var _nextOperationToken = 0;

  /// Stores a validated review before the UI asks for confirmation.
  void reviewOperation(PdfOperationReview review) {
    if (state.isWorking) return;
    emit(
      state.copyWith(
        workflowPhase: PdfOperationPhase.review,
        draft: review.draft,
        review: review,
        clearWorkflow: true,
      ),
    );
  }

  /// Cancels a review without mutating the source document.
  void cancelReview() => emit(
    state.copyWith(workflowPhase: PdfOperationPhase.idle, clearWorkflow: true),
  );

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
    if (state.isWorking) return;
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

  /// Moves the selected page by one position when that destination exists.
  Future<void> moveSelectedPage(int offset) async {
    final page = state.selectedPage;
    if (page == null) return;
    final destination = page + offset;
    if (destination < 0 || destination >= state.pageCount) return;
    await _inPlace(
      offset < 0 ? PdfEditOperation.moveEarlier : PdfEditOperation.moveLater,
      () => _useCases.reorder(_documentId, page, destination),
      clearSelectionAfter: true,
    );
  }

  /// Compresses the document.
  Future<void> compress({bool saveAsCopy = false}) async {
    if (!_beginSubmission(PdfEditOperation.compress)) return;

    final result = await _useCases.compress(
      _documentId,
      saveAsCopy: saveAsCopy,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        if (value.document.id != _documentId) {
          emit(
            state.copyWith(
              status: PdfEditStatus.ready,
              derived: value.document,
              derivedDocuments: [value.document],
              compression: CompressionOutcomeView(
                message: value.message,
                wasKept: value.wasKept,
              ),
              workflowPhase: PdfOperationPhase.succeeded,
              result: PdfOperationResult.derived(documents: [value.document]),
              clearWorkflow: true,
            ),
          );
          return;
        }
        await _refresh(
          compression: CompressionOutcomeView(
            message: value.message,
            wasKept: value.wasKept,
          ),
          completedMessage: value.message,
        );
      case Failed(:final failure):
        _emitOperationFailure(failure);
    }
  }

  /// Applies [text] as a watermark to every page.
  Future<void> watermark(String text, {bool saveAsCopy = false}) => saveAsCopy
      ? _derive(
          PdfEditOperation.watermark,
          () => _useCases.watermark(_documentId, text, saveAsCopy: true),
        )
      : _inPlace(
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
    if (!_beginSubmission(PdfEditOperation.removePassword)) return;

    final result = await _useCases.removePassword(_documentId, currentPassword);
    if (isClosed) return;

    switch (result) {
      case Success():
        await _refresh(completedMessage: 'PDF protection removed.');
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: failure is AuthFailure
                ? PdfEditStatus.ready
                : PdfEditStatus.failure,
            failure: failure is AuthFailure ? null : failure,
            passwordRejected: failure is AuthFailure,
            workflowPhase: failure is AuthFailure
                ? PdfOperationPhase.review
                : PdfOperationPhase.failed,
            clearWorkflow: true,
          ),
        );
    }
  }

  /// Extracts the selected pages into a new document.
  Future<void> extract() => _derive(
    PdfEditOperation.extract,
    () => _useCases.extract(_documentId, state.selection),
  );

  /// Merges [orderedIds] into [outputTitle], preserving the reviewed order.
  Future<void> merge(List<DocumentId> orderedIds, {String? outputTitle}) =>
      _derive(
        PdfEditOperation.merge,
        () => _useCases.merge(orderedIds, outputTitle: outputTitle),
      );

  /// Splits the document after one-based page [afterPage].
  Future<void> split(
    int afterPage, {
    ({String first, String second})? outputTitles,
  }) async {
    if (!_beginSubmission(PdfEditOperation.split)) return;

    final result = await _useCases.split(
      _documentId,
      afterPage: afterPage,
      outputTitles: outputTitles,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: PdfEditStatus.ready,
            derived: value.$1,
            derivedDocuments: [value.$1, value.$2],
            workflowPhase: PdfOperationPhase.succeeded,
            result: PdfOperationResult.derived(documents: [value.$1, value.$2]),
            clearWorkflow: true,
          ),
        );
      case Failed(:final failure):
        _emitOperationFailure(failure);
    }
  }

  /// Returns to the editor after a failure.
  void dismissError() => emit(
    state.copyWith(
      status: PdfEditStatus.ready,
      workflowPhase: PdfOperationPhase.idle,
      clearWorkflow: true,
    ),
  );

  /// Runs an in-place operation and reloads what it changed.
  Future<void> _inPlace(
    PdfEditOperation operation,
    Future<Result<dynamic>> Function() run, {
    bool clearSelectionAfter = false,
  }) async {
    if (!_beginSubmission(operation)) return;

    final result = await run();
    if (isClosed) return;

    switch (result) {
      case Success():
        await _refresh(
          clearSelection: clearSelectionAfter,
          completedMessage: '${operation.label} completed.',
        );
      case Failed(:final failure):
        _emitOperationFailure(failure);
    }
  }

  /// Runs an operation that produces a new document.
  Future<void> _derive(
    PdfEditOperation operation,
    Future<Result<dynamic>> Function() run,
  ) async {
    if (!_beginSubmission(operation)) return;

    final result = await run();
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        final document = value as Document;
        emit(
          state.copyWith(
            status: PdfEditStatus.ready,
            derived: document,
            derivedDocuments: [document],
            workflowPhase: PdfOperationPhase.succeeded,
            result: PdfOperationResult.derived(documents: [document]),
            clearWorkflow: true,
          ),
        );
      case Failed(:final failure):
        _emitOperationFailure(failure);
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
    String? completedMessage,
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
        workflowPhase: completedMessage == null
            ? PdfOperationPhase.idle
            : PdfOperationPhase.succeeded,
        result: completedMessage == null || document == null
            ? null
            : PdfOperationResult.inPlace(
                document: document,
                message: completedMessage,
              ),
        clearWorkflow: true,
      ),
    );
  }

  /// Starts one submission and makes repeated confirmation taps no-ops.
  bool _beginSubmission(PdfEditOperation operation) {
    if (state.isWorking || state.operationToken != null) return false;
    final token = ++_nextOperationToken;
    emit(
      state.copyWith(
        status: PdfEditStatus.working,
        operation: operation,
        workflowPhase: PdfOperationPhase.submitting,
        operationToken: token,
        clearWorkflow: true,
      ),
    );
    return true;
  }

  /// Clears the one-shot token before exposing a retryable failure.
  void _emitOperationFailure(Failure failure) {
    emit(
      state.copyWith(
        status: PdfEditStatus.failure,
        failure: failure,
        workflowPhase: PdfOperationPhase.failed,
        clearWorkflow: true,
      ),
    );
  }
}
