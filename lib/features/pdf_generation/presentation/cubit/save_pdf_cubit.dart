/// Cubit orchestration for exact calculation, preview, and Save jobs.
library;

import 'dart:async';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/security/pdf_password_draft.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/save_pdf_workflow.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Builds current workflow inputs without letting presentation import storage.
typedef SavePdfRequestFactory =
    SavePdfWorkflowRequest Function({
      required String name,
      required PageQualityPlan qualityPlan,
      required String? password,
    });

/// Drives a route-scoped Save PDF screen.
class SavePdfCubit extends Cubit<SavePdfState> {
  /// Creates the Cubit and its three independent generation counters.
  factory SavePdfCubit({
    required List<PageRef> pages,
    required String initialName,
    required PdfQualityPercent initialQuality,
    required CalculateSavePdfSize calculate,
    required PrepareSavePdfPreview preparePreview,
    required SaveGeneratedPdf save,
    required SavePdfRequestFactory requestFactory,
    PdfPasswordDraft? passwordDraft,
  }) => SavePdfCubit._(
    pages,
    initialName,
    initialQuality,
    calculate,
    preparePreview,
    save,
    requestFactory,
    passwordDraft ?? PdfPasswordDraft(),
  );

  /// Creates a deterministic Cubit frozen at [state] for previews and goldens.
  ///
  /// Collaborators remain explicit so this constructor introduces no ambient
  /// fake or global mutable state; preview actions simply never invoke them.
  factory SavePdfCubit.forPreview({
    required SavePdfState state,
    required CalculateSavePdfSize calculate,
    required PrepareSavePdfPreview preparePreview,
    required SaveGeneratedPdf save,
    required SavePdfRequestFactory requestFactory,
  }) => SavePdfCubit._seeded(
    state,
    calculate,
    preparePreview,
    save,
    requestFactory,
    PdfPasswordDraft(),
  );

  SavePdfCubit._(
    List<PageRef> pages,
    String initialName,
    PdfQualityPercent initialQuality,
    this._calculate,
    this._preparePreview,
    this._save,
    this._requestFactory,
    this._passwordDraft,
  ) : super(
        SavePdfState(
          pages: pages,
          name: initialName,
          qualityPlan: PageQualityPlan(documentQuality: initialQuality),
        ),
      );

  SavePdfCubit._seeded(
    super.initialState,
    this._calculate,
    this._preparePreview,
    this._save,
    this._requestFactory,
    this._passwordDraft,
  );

  final CalculateSavePdfSize _calculate;
  final PrepareSavePdfPreview _preparePreview;
  final SaveGeneratedPdf _save;
  final SavePdfRequestFactory _requestFactory;
  final PdfPasswordDraft _passwordDraft;
  final RouteJobController _calculationJob = RouteJobController();
  final RouteJobController _previewJob = RouteJobController();
  final RouteJobController _commitJob = RouteJobController();

  /// Starts initial exact-size calculation.
  Future<void> load() => recalculate();

  /// Updates the name and supersedes size work.
  void nameChanged(String name) {
    emit(state.copyWith(name: name, clearCalculatedBytes: true));
    unawaited(recalculate());
  }

  /// Updates document quality while retaining explicit page exceptions.
  void documentQualityChanged(int percent) {
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.copyWith(
          documentQuality: PdfQualityPercent(value: percent),
        ),
        clearCalculatedBytes: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Sets one stable page's explicit quality.
  void pageQualityChanged(String pageId, int percent) {
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.withOverride(
          pageId,
          PdfQualityPercent(value: percent),
        ),
        clearCalculatedBytes: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Makes one page follow the document percentage again.
  void useDocumentQuality(String pageId) {
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.withoutOverride(pageId),
        clearCalculatedBytes: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Removes every explicit page exception.
  void resetPageQualities() {
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.resetOverrides(),
        clearCalculatedBytes: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Validates and retains a password only inside the route secret boundary.
  void setPassword(String password, String confirmation) {
    final problem = _passwordDraft.replace(
      password: password,
      confirmation: confirmation,
    );
    emit(
      state.copyWith(
        passwordEnabled: problem == null,
        passwordProblem: problem,
        clearPasswordProblem: problem == null,
        clearCalculatedBytes: true,
      ),
    );
    if (problem == null) {
      unawaited(recalculate());
    }
  }

  /// Removes password protection and clears the secret immediately.
  void removePassword() {
    _passwordDraft.clear();
    emit(
      state.copyWith(
        passwordEnabled: false,
        clearPasswordProblem: true,
        clearCalculatedBytes: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Supersedes and recalculates exact output bytes after the use-case debounce.
  Future<void> recalculate() async {
    final ticket = _calculationJob.begin();
    emit(
      state.copyWith(
        calculation: AsyncJobView.queued(generation: ticket.generation),
        clearCalculatedBytes: true,
      ),
    );
    final result = await _calculate(
      _request(),
      token: ticket.token,
      onProgress: (progress) {
        if (!isClosed && _calculationJob.isCurrent(ticket.generation)) {
          emit(
            state.copyWith(
              calculation: AsyncJobView.running(
                generation: ticket.generation,
                progress: progress,
              ),
            ),
          );
        }
      },
    );
    if (isClosed || !_calculationJob.isLatest(ticket.generation)) {
      return;
    }
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        calculation: AsyncJobView.succeeded(
          generation: ticket.generation,
          summary: _summary(value),
        ),
        calculatedBytes: value.exactBytes,
      ),
      Failed(:final failure) when failure.isCancellation => state.copyWith(
        calculation: AsyncJobView.cancelled(generation: ticket.generation),
      ),
      Failed(:final failure) => state.copyWith(
        calculation: AsyncJobView.failed(
          generation: ticket.generation,
          failure: failure,
        ),
      ),
    });
  }

  /// Prepares a temporary candidate and returns its handle for typed navigation.
  Future<String?> preview() async {
    final ticket = _previewJob.begin();
    emit(
      state.copyWith(
        preview: AsyncJobView.running(
          generation: ticket.generation,
          progress: JobProgress(percent: 0),
        ),
      ),
    );
    final result = await _preparePreview(
      _request(),
      token: ticket.token,
      onProgress: (progress) => _emitModalProgress(
        controller: _previewJob,
        generation: ticket.generation,
        progress: progress,
        preview: true,
      ),
    );
    if (isClosed || !_previewJob.isLatest(ticket.generation)) {
      return null;
    }
    return switch (result) {
      Success(:final value) => _previewSucceeded(ticket.generation, value),
      Failed(:final failure) => _previewFailed(ticket.generation, failure),
    };
  }

  /// Cancels preview preparation without changing configuration.
  void cancelPreview() => _previewJob.cancel();

  /// Commits immediately, superseding any unrelated size calculation.
  Future<Document?> save() async {
    if (!state.canSave) {
      return null;
    }
    _calculationJob.cancel();
    final ticket = _commitJob.begin();
    emit(
      state.copyWith(
        commit: AsyncJobView.running(
          generation: ticket.generation,
          progress: JobProgress(percent: 0),
        ),
      ),
    );
    final result = await _save(
      _request(),
      token: ticket.token,
      onProgress: (progress) => _emitModalProgress(
        controller: _commitJob,
        generation: ticket.generation,
        progress: progress,
        preview: false,
      ),
    );
    if (isClosed || !_commitJob.isLatest(ticket.generation)) {
      return null;
    }
    return switch (result) {
      Success(:final value) => _saveSucceeded(ticket.generation, value),
      Failed(:final failure) => _saveFailed(ticket.generation, failure),
    };
  }

  /// Cancels authoritative commit before its verified completion.
  void cancelSave() => _commitJob.cancel();

  SavePdfWorkflowRequest _request() => _requestFactory(
    name: state.name,
    qualityPlan: state.qualityPlan,
    password: state.passwordEnabled ? _passwordDraft.readForOperation() : null,
  );

  void _emitModalProgress({
    required RouteJobController controller,
    required int generation,
    required JobProgress progress,
    required bool preview,
  }) {
    if (isClosed || !controller.isCurrent(generation)) {
      return;
    }
    final job = AsyncJobView.running(
      generation: generation,
      progress: progress,
    );
    emit(preview ? state.copyWith(preview: job) : state.copyWith(commit: job));
  }

  String _previewSucceeded(int generation, PdfCandidate candidate) {
    emit(
      state.copyWith(
        preview: AsyncJobView.succeeded(
          generation: generation,
          summary: _summary(candidate),
        ),
      ),
    );
    return candidate.handle;
  }

  String? _previewFailed(int generation, Failure failure) {
    emit(
      state.copyWith(
        preview: failure.isCancellation
            ? AsyncJobView.cancelled(generation: generation)
            : AsyncJobView.failed(generation: generation, failure: failure),
      ),
    );
    return null;
  }

  Document _saveSucceeded(int generation, Document document) {
    emit(
      state.copyWith(
        commit: AsyncJobView.succeeded(
          generation: generation,
          summary: JobResultSummary(
            exactBytes: document.sizeInBytes,
            pageCount: document.pageCount,
          ),
        ),
        document: document,
      ),
    );
    _passwordDraft.clear();
    return document;
  }

  Document? _saveFailed(int generation, Failure failure) {
    emit(
      state.copyWith(
        commit: failure.isCancellation
            ? AsyncJobView.cancelled(generation: generation)
            : AsyncJobView.failed(generation: generation, failure: failure),
      ),
    );
    return null;
  }

  JobResultSummary _summary(PdfCandidate candidate) => JobResultSummary(
    exactBytes: candidate.exactBytes,
    pageCount: candidate.pageCount,
    candidateHandle: candidate.handle,
  );

  @override
  Future<void> close() {
    _passwordDraft.dispose();
    _calculationJob.dispose();
    _previewJob.dispose();
    _commitJob.dispose();
    return super.close();
  }
}
