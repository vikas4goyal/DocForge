/// Cubit orchestration for exact calculation, preview, and compression commit.
library;

import 'dart:async';

import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/features/pdf_editing/application/usecases/compression_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Builds current compression inputs without importing infrastructure.
typedef CompressionRequestFactory =
    CompressionWorkflowRequest Function({
      required PageQualityPlan qualityPlan,
      required CompressionDestination? destination,
    });

/// Drives one route-scoped Compress PDF screen.
class CompressPdfCubit extends Cubit<CompressPdfState> {
  /// Creates the Cubit with the specified 80% document default.
  factory CompressPdfCubit({
    required String title,
    required int pageCount,
    required int originalBytes,
    required CalculateCompressedSize calculate,
    required PrepareCompressionPreview preparePreview,
    required SaveCompressedPdf save,
    required CompressionRequestFactory requestFactory,
  }) => CompressPdfCubit._(
    CompressPdfState(
      title: title,
      pageCount: pageCount,
      originalBytes: originalBytes,
      qualityPlan: PageQualityPlan(
        documentQuality: PdfQualityPercent(value: 80),
      ),
    ),
    calculate,
    preparePreview,
    save,
    requestFactory,
  );

  /// Creates a deterministic Cubit frozen at [state] for previews and goldens.
  factory CompressPdfCubit.forPreview({
    required CompressPdfState state,
    required CalculateCompressedSize calculate,
    required PrepareCompressionPreview preparePreview,
    required SaveCompressedPdf save,
    required CompressionRequestFactory requestFactory,
  }) => CompressPdfCubit._(
    state,
    calculate,
    preparePreview,
    save,
    requestFactory,
  );

  CompressPdfCubit._(
    super.initialState,
    this._calculate,
    this._preparePreview,
    this._save,
    this._requestFactory,
  );

  final CalculateCompressedSize _calculate;
  final PrepareCompressionPreview _preparePreview;
  final SaveCompressedPdf _save;
  final CompressionRequestFactory _requestFactory;
  final RouteJobController _calculationJob = RouteJobController();
  final RouteJobController _previewJob = RouteJobController();
  final RouteJobController _commitJob = RouteJobController();

  /// Starts initial exact-size calculation.
  Future<void> load() => recalculate();

  /// Updates document quality while retaining explicit page exceptions.
  void documentQualityChanged(int percent) {
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.copyWith(
          documentQuality: PdfQualityPercent(value: percent),
        ),
        clearCalculatedBytes: true,
        showAllPassThroughReview: false,
        showNoBenefitReview: false,
        clearPendingDestination: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Sets one zero-based page's explicit quality.
  void pageQualityChanged(int pageIndex, int percent) {
    _checkPage(pageIndex);
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.withOverride(
          '$pageIndex',
          PdfQualityPercent(value: percent),
        ),
        clearCalculatedBytes: true,
        showAllPassThroughReview: false,
        showNoBenefitReview: false,
        clearPendingDestination: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Makes one page follow document quality again.
  void useDocumentQuality(int pageIndex) {
    _checkPage(pageIndex);
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.withoutOverride('$pageIndex'),
        clearCalculatedBytes: true,
        showAllPassThroughReview: false,
        showNoBenefitReview: false,
        clearPendingDestination: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Removes every page exception.
  void resetPageQualities() {
    emit(
      state.copyWith(
        qualityPlan: state.qualityPlan.resetOverrides(),
        clearCalculatedBytes: true,
        showAllPassThroughReview: false,
        showNoBenefitReview: false,
        clearPendingDestination: true,
      ),
    );
    unawaited(recalculate());
  }

  /// Supersedes and recalculates exact output bytes.
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
    if (isClosed || !_calculationJob.isLatest(ticket.generation)) return;
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

  /// Prepares a temporary candidate and returns its private handle.
  Future<String?> previewPdf() async {
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
      onProgress: (progress) => _emitProgress(
        controller: _previewJob,
        generation: ticket.generation,
        progress: progress,
        preview: true,
      ),
    );
    if (isClosed || !_previewJob.isLatest(ticket.generation)) return null;
    return switch (result) {
      Success(:final value) => _previewSucceeded(ticket.generation, value),
      Failed(:final failure) => _previewFailed(ticket.generation, failure),
    };
  }

  /// Cancels preview preparation without changing configuration.
  void cancelPreview() => _previewJob.cancel();

  /// Requests destination selection, first surfacing the all-100 review.
  bool beginDestinationSelection() {
    if (state.isAllPagesPassThrough) {
      emit(state.copyWith(showAllPassThroughReview: true));
      return false;
    }
    return true;
  }

  /// Accepts the all-100 warning so destination selection can continue.
  void acknowledgeAllPassThrough() {
    emit(state.copyWith(showAllPassThroughReview: false));
  }

  /// Closes either review and keeps the current configuration editable.
  void dismissReview() {
    emit(
      state.copyWith(
        showAllPassThroughReview: false,
        showNoBenefitReview: false,
        clearPendingDestination: true,
      ),
    );
  }

  /// Commits to [destination], retaining it if no-benefit review is required.
  Future<CompressionCommitResult?> saveTo(
    CompressionDestination destination, {
    bool allowNoBenefit = false,
  }) async {
    if (!state.canSave) return null;
    _calculationJob.cancel();
    final ticket = _commitJob.begin();
    emit(
      state.copyWith(
        pendingDestination: destination,
        showNoBenefitReview: false,
        commit: AsyncJobView.running(
          generation: ticket.generation,
          progress: JobProgress(percent: 0),
        ),
      ),
    );
    final result = await _save(
      _request(destination: destination),
      token: ticket.token,
      onProgress: (progress) => _emitProgress(
        controller: _commitJob,
        generation: ticket.generation,
        progress: progress,
        preview: false,
      ),
      allowNoBenefit: allowNoBenefit,
    );
    if (isClosed || !_commitJob.isLatest(ticket.generation)) return null;
    return switch (result) {
      Success(:final value) => _saveSucceeded(ticket.generation, value),
      Failed(:final failure) => _saveFailed(ticket.generation, failure),
    };
  }

  /// Continues the retained destination after explicit no-benefit review.
  Future<CompressionCommitResult?> continueWithoutBenefit() {
    final destination = state.pendingDestination;
    if (destination == null) return Future.value();
    return saveTo(destination, allowNoBenefit: true);
  }

  /// Cancels the authoritative commit before verified completion.
  void cancelSave() => _commitJob.cancel();

  CompressionWorkflowRequest _request({CompressionDestination? destination}) =>
      _requestFactory(qualityPlan: state.qualityPlan, destination: destination);

  void _emitProgress({
    required RouteJobController controller,
    required int generation,
    required JobProgress progress,
    required bool preview,
  }) {
    if (isClosed || !controller.isCurrent(generation)) return;
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

  CompressionCommitResult _saveSucceeded(
    int generation,
    CompressionCommitResult result,
  ) {
    emit(
      state.copyWith(
        commit: AsyncJobView.succeeded(
          generation: generation,
          summary: JobResultSummary(
            exactBytes: result.resultBytes,
            pageCount: state.pageCount,
          ),
        ),
        calculatedBytes: result.resultBytes,
        result: result,
        showNoBenefitReview: false,
      ),
    );
    return result;
  }

  CompressionCommitResult? _saveFailed(int generation, Failure failure) {
    final needsReview =
        failure is ValidationFailure &&
        failure.debugDetail == 'compressed candidate has no byte-size benefit';
    emit(
      state.copyWith(
        commit: needsReview
            ? const AsyncJobView.idle()
            : failure.isCancellation
            ? AsyncJobView.cancelled(generation: generation)
            : AsyncJobView.failed(generation: generation, failure: failure),
        showNoBenefitReview: needsReview,
      ),
    );
    return null;
  }

  JobResultSummary _summary(PdfCandidate candidate) => JobResultSummary(
    exactBytes: candidate.exactBytes,
    pageCount: candidate.pageCount,
    candidateHandle: candidate.handle,
  );

  void _checkPage(int index) {
    if (index < 0 || index >= state.pageCount) {
      throw RangeError.range(index, 0, state.pageCount - 1, 'pageIndex');
    }
  }

  @override
  Future<void> close() async {
    _calculationJob.dispose();
    _previewJob.dispose();
    _commitJob.dispose();
    await super.close();
  }
}
