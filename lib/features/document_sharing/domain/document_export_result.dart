/// Platform-owned export outcomes.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_export_result.freezed.dart';

/// Result reported after the platform picker owns the full write handoff.
@freezed
sealed class DocumentExportResult with _$DocumentExportResult {
  /// The provider accepted and completed the export.
  const factory DocumentExportResult.completed({
    required String destinationLabel,
  }) = DocumentExportCompleted;

  /// The user dismissed the provider without writing anything.
  const factory DocumentExportResult.cancelled() = DocumentExportCancelled;
}
