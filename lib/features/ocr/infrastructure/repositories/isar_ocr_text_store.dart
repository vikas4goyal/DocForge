/// Isar-backed storage for recognised text.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:isar_community/isar.dart';

/// Stores recognition results in Isar.
///
/// Each row records the document its page belongs to. Recognised text is
/// document content: when a document is permanently removed its text has to go
/// with it, and that has to be answerable without loading the document's pages
/// first, because by then the pages are gone.
class IsarOcrTextStore implements OcrTextStore {
  /// Creates the store over an open [_isar].
  const IsarOcrTextStore(this._isar);

  final Isar _isar;

  @override
  Future<Result<RecognisedText?>> find(PageId pageId) async {
    try {
      final row = await _isar.ocrTextEntitys
          .filter()
          .pageUuidEqualTo(pageId.value)
          .findFirst();

      // A page that has never been recognised is a normal state, not an error.
      return Result<RecognisedText?>.success(row?.toDomain());
    } on Object catch (error) {
      return Result<RecognisedText?>.failure(
        Failure.storage(debugDetail: '$error'),
      );
    }
  }

  @override
  Future<Result<Map<PageId, RecognisedText>>> findAll(
    List<PageId> pageIds,
  ) async {
    if (pageIds.isEmpty) {
      return const Result<Map<PageId, RecognisedText>>.success({});
    }

    try {
      final rows = await _isar.ocrTextEntitys
          .filter()
          .anyOf(pageIds, (query, id) => query.pageUuidEqualTo(id.value))
          .findAll();

      return Result<Map<PageId, RecognisedText>>.success({
        for (final row in rows) PageId(row.pageUuid): row.toDomain(),
      });
    } on Object catch (error) {
      return Result<Map<PageId, RecognisedText>>.failure(
        Failure.storage(debugDetail: '$error'),
      );
    }
  }

  @override
  Future<Result<void>> save(RecognisedText text, DocumentId documentId) async {
    try {
      await _isar.writeTxn(
        () => _isar.ocrTextEntitys.put(
          OcrTextEntity.fromDomain(text, documentId),
        ),
      );
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  @override
  Future<Result<void>> remove(PageId pageId) => removeAll([pageId]);

  @override
  Future<Result<void>> removeAll(List<PageId> pageIds) async {
    if (pageIds.isEmpty) return const Result<void>.success(null);

    try {
      await _isar.writeTxn(
        () => _isar.ocrTextEntitys
            .filter()
            .anyOf(pageIds, (query, id) => query.pageUuidEqualTo(id.value))
            .deleteAll(),
      );
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  @override
  Future<Result<void>> removeForDocument(DocumentId documentId) async {
    try {
      await _isar.writeTxn(
        () => _isar.ocrTextEntitys
            .filter()
            .documentUuidEqualTo(documentId.value)
            .deleteAll(),
      );
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }
}
