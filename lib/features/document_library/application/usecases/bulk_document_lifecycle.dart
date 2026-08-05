/// Deterministic orchestration for bulk Archive and Trash actions.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/domain/bulk_document_action.dart';

/// One existing single-document lifecycle mutation.
typedef DocumentMutation = Future<Result<dynamic>> Function(DocumentId id);

/// Archives selected documents sequentially and reports every item outcome.
class BulkArchiveDocuments {
  /// Creates the use case over the existing single-document [archive].
  const BulkArchiveDocuments(this.archive);

  /// The source-preserving single-document Archive rule.
  final DocumentMutation archive;

  /// Archives [request] in its supplied visible order.
  Future<BulkDocumentOutcome> call(BulkDocumentRequest request) =>
      _run(request.documentIds, archive);
}

/// Moves selected documents to recoverable Trash after explicit confirmation.
class BulkTrashDocuments {
  /// Creates the use case over the existing single-document [trash].
  const BulkTrashDocuments(this.trash);

  /// The recoverable single-document Trash rule.
  final DocumentMutation trash;

  /// Moves [request] to Trash in supplied order.
  Future<BulkDocumentOutcome> call(BulkDocumentRequest request) async {
    if (!request.destructiveActionConfirmed) {
      return BulkDocumentOutcome(
        failed: [
          for (final id in request.documentIds)
            BulkDocumentFailure(
              documentId: id,
              failure: const Failure.validation(
                issue: ValidationIssue.bulkActionNotConfirmed,
                debugDetail: 'Bulk Trash requires explicit confirmation.',
              ),
            ),
        ],
      );
    }
    return _run(request.documentIds, trash);
  }
}

Future<BulkDocumentOutcome> _run(
  List<DocumentId> documentIds,
  DocumentMutation mutate,
) async {
  final succeeded = <DocumentId>[];
  final failed = <BulkDocumentFailure>[];
  for (final id in documentIds) {
    final result = await mutate(id);
    switch (result) {
      case Success():
        succeeded.add(id);
      case Failed(:final failure):
        failed.add(BulkDocumentFailure(documentId: id, failure: failure));
    }
  }
  return BulkDocumentOutcome(succeeded: succeeded, failed: failed);
}
