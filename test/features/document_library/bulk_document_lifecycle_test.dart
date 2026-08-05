import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/features/document_library/application/usecases/bulk_document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/domain/bulk_document_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ids = [
    const DocumentId('one'),
    const DocumentId('two'),
    const DocumentId('three'),
  ];

  test(
    'bulk Archive preserves request order and reports all successes',
    () async {
      final visited = <DocumentId>[];
      final outcome = await BulkArchiveDocuments((id) async {
        visited.add(id);
        return Result<Document>.success(sampleDocument.copyWith(id: id));
      })(BulkDocumentRequest(documentIds: ids));

      expect(visited, ids);
      expect(outcome.succeeded, ids);
      expect(outcome.failed, isEmpty);
      expect(outcome.isComplete, isTrue);
    },
  );

  test('partial failure does not stop later selected documents', () async {
    final visited = <DocumentId>[];
    final outcome = await BulkArchiveDocuments((id) async {
      visited.add(id);
      return id == ids[1]
          ? const Result<Document>.failure(Failure.storage())
          : Result<Document>.success(sampleDocument.copyWith(id: id));
    })(BulkDocumentRequest(documentIds: ids));

    expect(visited, ids);
    expect(outcome.succeeded, [ids[0], ids[2]]);
    expect(outcome.failed.single.documentId, ids[1]);
  });

  test('bulk Trash refuses every item before confirmation', () async {
    var calls = 0;
    final outcome = await BulkTrashDocuments((id) async {
      calls += 1;
      return Result<Document>.success(sampleDocument.copyWith(id: id));
    })(BulkDocumentRequest(documentIds: ids));

    expect(calls, 0);
    expect(outcome.failed, hasLength(3));
    expect(
      outcome.failed.first.failure,
      isA<ValidationFailure>().having(
        (failure) => failure.issue,
        'issue',
        ValidationIssue.bulkActionNotConfirmed,
      ),
    );
  });

  test('confirmed bulk Trash mutates each item once', () async {
    final visited = <DocumentId>[];
    final outcome = await BulkTrashDocuments((id) async {
      visited.add(id);
      return Result<Document>.success(sampleDocument.copyWith(id: id));
    })(BulkDocumentRequest(documentIds: ids, destructiveActionConfirmed: true));

    expect(visited, ids);
    expect(outcome.succeeded, ids);
  });

  test('retrying only failed IDs does not repeat successful items', () async {
    final calls = <DocumentId>[];
    final archive = BulkArchiveDocuments((id) async {
      calls.add(id);
      return Result<Document>.success(sampleDocument.copyWith(id: id));
    });

    await archive(BulkDocumentRequest(documentIds: [ids[1]]));

    expect(calls, [ids[1]]);
  });
}
