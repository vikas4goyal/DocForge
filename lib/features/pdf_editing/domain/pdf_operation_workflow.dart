/// Typed values shared by every PDF operation workflow.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_operation_workflow.freezed.dart';

/// Whether a successful operation preserves or replaces its source PDF.
enum PdfSourceEffect {
  /// A new document is created and the source stays unchanged.
  preserve,

  /// The current document is replaced atomically.
  replace,
}

/// Operation-specific input captured before a review is shown.
///
/// Password text is intentionally absent: credentials remain in the field that
/// submits them and never enter Cubit state, logs, previews, or value equality.
@freezed
sealed class PdfOperationDraft with _$PdfOperationDraft {
  /// Splits after [boundary] into two independently named outputs.
  const factory PdfOperationDraft.split({
    required int boundary,
    required String firstTitle,
    required String secondTitle,
  }) = PdfSplitDraft;

  /// Merges [documentIds] in their displayed order into [outputTitle].
  const factory PdfOperationDraft.merge({
    required List<DocumentId> documentIds,
    required String outputTitle,
  }) = PdfMergeDraft;

  /// Attempts to reduce size and replaces the source only when beneficial.
  const factory PdfOperationDraft.compress({
    @Default(PdfSourceEffect.replace) PdfSourceEffect sourceEffect,
  }) = PdfCompressDraft;

  /// Applies nonblank [text] to the current document.
  const factory PdfOperationDraft.watermark({required String text}) =
      PdfWatermarkDraft;

  /// Reviews adding or removing protection without retaining a password.
  const factory PdfOperationDraft.protection({
    required bool remove,
    @Default(PdfSourceEffect.replace) PdfSourceEffect sourceEffect,
  }) = PdfProtectionDraft;

  /// Applies [operation] to ordered zero-based [pageIndices].
  const factory PdfOperationDraft.pages({
    required PdfEditOperation operation,
    required List<int> pageIndices,
    required PdfSourceEffect sourceEffect,
  }) = PdfPagesDraft;
}

/// A validated effect presented immediately before mutation.
@freezed
sealed class PdfOperationReview with _$PdfOperationReview {
  /// Creates a review for [draft] using user-visible [summary].
  const factory PdfOperationReview({
    required PdfOperationDraft draft,
    required String title,
    required String summary,
    required String confirmLabel,
  }) = _PdfOperationReview;
}

/// Concrete output shown after a PDF operation completes.
@freezed
sealed class PdfOperationResult with _$PdfOperationResult {
  /// The current document was refreshed after an in-place operation.
  const factory PdfOperationResult.inPlace({
    required Document document,
    String? message,
  }) = PdfInPlaceOperationResult;

  /// One or more independent documents were created.
  const factory PdfOperationResult.derived({
    required List<Document> documents,
  }) = PdfDerivedOperationResult;
}

/// The common input-review-submit-result phase.
enum PdfOperationPhase {
  /// No workflow is active.
  idle,

  /// Operation-specific input is being collected.
  input,

  /// A validated effect is waiting for confirmation.
  review,

  /// Exactly one submitted operation is in flight.
  submitting,

  /// The concrete result is ready to consume.
  succeeded,

  /// Submission failed and can be reviewed or retried.
  failed,
}

/// Pure validation for operation drafts.
abstract final class PdfOperationValidation {
  /// Returns a user-facing validation message, or null when [draft] is valid.
  static String? messageFor(PdfOperationDraft draft, {required int pageCount}) {
    return switch (draft) {
      PdfSplitDraft(:final boundary, :final firstTitle, :final secondTitle) =>
        !PdfEditRules.canSplit(boundary, pageCount: pageCount)
            ? 'Choose a split point between the first and last page.'
            : firstTitle.trim().isEmpty || secondTitle.trim().isEmpty
            ? 'Enter a name for both split documents.'
            : firstTitle.trim() == secondTitle.trim()
            ? 'Use a different name for each split document.'
            : null,
      PdfMergeDraft(:final documentIds, :final outputTitle) =>
        documentIds.toSet().length < PdfEditRules.minimumMergeCount
            ? 'Choose at least two different documents.'
            : outputTitle.trim().isEmpty
            ? 'Enter a name for the merged document.'
            : null,
      PdfWatermarkDraft(:final text) =>
        PdfEditRules.isValidWatermark(text) ? null : 'Enter watermark text.',
      PdfPagesDraft(:final operation, :final pageIndices) =>
        operation.needsSelection && pageIndices.isEmpty
            ? 'Select at least one page.'
            : null,
      PdfCompressDraft() || PdfProtectionDraft() => null,
    };
  }
}
