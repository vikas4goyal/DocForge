/// Immutable inputs and outcomes for deterministic bulk document mutations.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bulk_document_action.freezed.dart';

/// An ordered request to mutate selected documents.
@freezed
abstract class BulkDocumentRequest with _$BulkDocumentRequest {
  /// Creates a request over [documentIds] in visible list order.
  const factory BulkDocumentRequest({
    required List<DocumentId> documentIds,
    @Default(false) bool destructiveActionConfirmed,
  }) = _BulkDocumentRequest;
}

/// One selected document that could not be mutated.
@freezed
abstract class BulkDocumentFailure with _$BulkDocumentFailure {
  /// Creates a failed item outcome.
  const factory BulkDocumentFailure({
    required DocumentId documentId,
    required Failure failure,
  }) = _BulkDocumentFailure;
}

/// Ordered per-item results of a bulk document mutation.
@freezed
abstract class BulkDocumentOutcome with _$BulkDocumentOutcome {
  /// Creates a bulk result.
  const factory BulkDocumentOutcome({
    @Default(<DocumentId>[]) List<DocumentId> succeeded,
    @Default(<BulkDocumentFailure>[]) List<BulkDocumentFailure> failed,
  }) = _BulkDocumentOutcome;

  const BulkDocumentOutcome._();

  /// Whether every requested document was mutated successfully.
  bool get isComplete => failed.isEmpty;
}
