/// The recognised-text search index, exposed to `document-search`.
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:isar_community/isar.dart';

/// Finds documents by a prefix of a word in their recognised text.
///
/// Lives here because this feature owns the text collection and its word index.
/// `document-search` consumes it through [OcrSearchIndex] rather than reading
/// the collection itself (`design.md` §2).
class IsarOcrSearchIndex implements OcrSearchIndex {
  /// Creates the index over an open [_isar].
  const IsarOcrSearchIndex(this._isar);

  final Isar _isar;

  @override
  Future<Result<List<OcrIndexHit>>> documentsMatchingWord(
    String word, {
    int limit = 50,
  }) async {
    if (word.isEmpty) return const Result<List<OcrIndexHit>>.success([]);

    try {
      final rows = await _isar.ocrTextEntitys
          .filter()
          .wordsElementStartsWith(word)
          .limit(limit)
          .findAll();

      // Grouped by document: a fifty-page document whose every page matched is
      // one result, not fifty. The first matching page supplies the text the
      // snippet is built from, which is the one the user will see cited.
      final byDocument = <String, OcrTextEntity>{};
      for (final row in rows) {
        byDocument.putIfAbsent(row.documentUuid, () => row);
      }

      return Result<List<OcrIndexHit>>.success([
        for (final entry in byDocument.entries)
          OcrIndexHit(
            documentId: DocumentId(entry.key),
            // Rebuilt from the blocks rather than taken from `searchableText`:
            // that column is lower-cased for matching, and a snippet quoted
            // back to the user in lower case looks like a different document.
            text: entry.value.toDomain().plainText,
          ),
      ]);
    } on Object catch (error) {
      return Result<List<OcrIndexHit>>.failure(
        Failure.storage(debugDetail: '$error'),
      );
    }
  }
}
