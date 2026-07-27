/// The contract behind searching stored documents.
library;

import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';

/// Searches the library.
///
/// One method rather than separate title and text searches: merging the two is
/// a rule the caller must not be able to get wrong, and the implementation is
/// what knows how to run both against one database efficiently.
abstract interface class SearchRepository {
  /// Returns the documents matching [query].
  ///
  /// Archived documents are excluded: the archive is where a user puts things
  /// they have finished with, and surfacing them in every search would defeat
  /// the point of putting them there.
  ///
  /// [limit] bounds the result set. Search is incremental — it runs on every
  /// keystroke — and an unbounded query against a library of several thousand
  /// documents would block the database for the length of each one.
  Future<Result<List<SearchResult>>> search(
    SearchQuery query, {
    int limit = defaultLimit,
  });

  /// The largest number of results a search returns by default.
  static const defaultLimit = 50;
}
