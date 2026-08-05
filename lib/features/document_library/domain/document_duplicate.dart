/// Reviewed inputs and outcomes for creating an independent document copy.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_duplicate.freezed.dart';

/// User-reviewed duplicate inputs.
@freezed
abstract class DuplicateDocumentRequest with _$DuplicateDocumentRequest {
  /// Creates a request for a named copy in a library destination.
  const factory DuplicateDocumentRequest({
    required DocumentId sourceDocumentId,
    required String title,
    required List<String> destinationFolders,
    FolderId? destinationFolderId,
  }) = _DuplicateDocumentRequest;
}

/// The independent document created from a reviewed request.
@freezed
abstract class DuplicateDocumentOutcome with _$DuplicateDocumentOutcome {
  /// Creates a successful duplicate outcome.
  const factory DuplicateDocumentOutcome({required Document document}) =
      _DuplicateDocumentOutcome;
}
