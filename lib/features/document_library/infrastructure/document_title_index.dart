/// The title-search index, exposed to `document-search`.
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:isar_community/isar.dart';

/// Finds documents by a prefix of a word in their title.
///
/// Lives here because this feature owns the document collection and its title
/// index. `document-search` consumes it through [DocumentTitleIndex] rather
/// than reading the collection itself, which is what keeps the two features
/// independent (`design.md` §2).
class IsarDocumentTitleIndex implements DocumentTitleIndex {
  /// Creates the index over an open [_isar].
  const IsarDocumentTitleIndex(this._isar);

  final Isar _isar;

  @override
  Future<Result<List<Document>>> documentsMatchingWord(
    String word, {
    int limit = 50,
  }) async {
    try {
      // An empty word matches everything unarchived, which is what makes a
      // filter-only search work. Isar has no "match all words" clause, so the
      // two shapes are separate queries rather than one with an optional term.
      final rows = word.isEmpty
          ? await _isar.documentEntitys
                .filter()
                .isArchivedEqualTo(false)
                .sortByUpdatedAtDesc()
                .limit(limit)
                .findAll()
          : await _isar.documentEntitys
                .filter()
                .isArchivedEqualTo(false)
                .titleWordsElementStartsWith(word)
                .sortByUpdatedAtDesc()
                .limit(limit)
                .findAll();

      return Result<List<Document>>.success([
        for (final row in rows) row.toDomain(),
      ]);
    } on Object catch (error) {
      return Result<List<Document>>.failure(
        Failure.storage(debugDetail: '$error'),
      );
    }
  }
}
