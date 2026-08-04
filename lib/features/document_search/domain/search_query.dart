/// The value objects and rules behind search.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';

/// Where a search result matched.
///
/// Shown beside the snippet so the user understands *why* a document is in the
/// list — a match on recognised text is not obvious from a title that does not
/// contain the term.
enum MatchSource {
  /// The document's title contained the term.
  title,

  /// The document's recognised text contained the term.
  recognisedText,
}

/// A date range a search is restricted to.
///
/// Both bounds are inclusive and either may be absent, so "everything since
/// March" and "everything before March" are both expressible without a sentinel
/// date.
class DateRange {
  /// Creates a range from [from] to [to], inclusive.
  const DateRange({this.from, this.to});

  /// The earliest date included, or null for no lower bound.
  final DateTime? from;

  /// The latest date included, or null for no upper bound.
  final DateTime? to;

  /// Whether this range restricts anything at all.
  bool get isUnbounded => from == null && to == null;

  /// Whether [moment] falls inside the range.
  ///
  /// Compared in UTC, because stored timestamps are UTC and comparing one
  /// against a local-time bound would shift the boundary by the offset.
  bool contains(DateTime moment) {
    final at = moment.toUtc();
    if (from != null && at.isBefore(from!.toUtc())) return false;
    if (to != null && at.isAfter(to!.toUtc())) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'DateRange($from – $to)';
}

/// Everything a search is looking for.
class SearchQuery {
  /// Creates a query.
  const SearchQuery({
    this.term = '',
    this.folderId,
    this.createdWithin,
    this.modifiedWithin,
  });

  /// What the user typed.
  final String term;

  /// The folder results are restricted to, when one is chosen.
  final FolderId? folderId;

  /// The creation-date range results are restricted to.
  final DateRange? createdWithin;

  /// The modification-date range results are restricted to.
  final DateRange? modifiedWithin;

  /// The term, trimmed and lower-cased, as matching uses it.
  String get normalisedTerm => term.trim().toLowerCase();

  /// Whether this query would return anything meaningful.
  ///
  /// A blank term with no filters is not a search — it is the state before one,
  /// and running it would return the whole library with a spinner in front of
  /// it.
  bool get isEmpty => normalisedTerm.isEmpty && !hasFilters;

  /// Whether any filter is applied.
  bool get hasFilters =>
      folderId != null ||
      (createdWithin?.isUnbounded == false) ||
      (modifiedWithin?.isUnbounded == false);

  /// The term split into the words the index is queried with.
  ///
  /// Tokenised the same way titles and recognised text are on write, so a term
  /// that indexes one way cannot fail to match itself.
  List<String> get words => normalisedTerm
      .split(RegExp('[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();

  /// Returns a copy with the given fields replaced.
  ///
  /// Filters are cleared by passing [clearFolder], [clearCreated] or
  /// [clearModified] — a null argument means "unchanged", which is what makes
  /// changing the term alone leave the filters in place.
  SearchQuery copyWith({
    String? term,
    FolderId? folderId,
    DateRange? createdWithin,
    DateRange? modifiedWithin,
    bool clearFolder = false,
    bool clearCreated = false,
    bool clearModified = false,
  }) => SearchQuery(
    term: term ?? this.term,
    folderId: clearFolder ? null : (folderId ?? this.folderId),
    createdWithin: clearCreated ? null : (createdWithin ?? this.createdWithin),
    modifiedWithin: clearModified
        ? null
        : (modifiedWithin ?? this.modifiedWithin),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          other.term == term &&
          other.folderId == folderId &&
          other.createdWithin == createdWithin &&
          other.modifiedWithin == modifiedWithin;

  @override
  int get hashCode =>
      Object.hash(term, folderId, createdWithin, modifiedWithin);

  @override
  String toString() => 'SearchQuery("$term", folder: $folderId)';
}

/// One document that matched, and why.
class SearchResult {
  /// Creates a result.
  const SearchResult({
    required this.document,
    required this.source,
    this.snippet = '',
  });

  /// The document that matched.
  final Document document;

  /// Where the match was found.
  final MatchSource source;

  /// The matching text in context.
  ///
  /// Empty for a title match, where the title itself is already shown.
  final String snippet;

  /// Whether this result has a snippet worth showing.
  bool get hasSnippet => snippet.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          other.document == document &&
          other.source == source &&
          other.snippet == snippet;

  @override
  int get hashCode => Object.hash(document, source, snippet);
}

/// Rules for matching and presenting search results.
abstract final class SearchRules {
  /// How much context a snippet shows either side of the match.
  ///
  /// Enough to read the phrase the term appears in, short enough that a result
  /// row stays one or two lines and the list is still scannable.
  static const snippetPadding = 40;

  /// Builds a snippet of [text] around the first occurrence of [term].
  ///
  /// Returns an empty string when the term does not appear. Ellipses mark where
  /// the snippet was cut, so a user can tell a fragment from a whole line.
  static String snippet(String text, String term) {
    if (term.isEmpty || text.isEmpty) return '';

    final haystack = text.toLowerCase();
    final index = haystack.indexOf(term.toLowerCase());
    if (index < 0) return '';

    final start = (index - snippetPadding).clamp(0, text.length);
    final end = (index + term.length + snippetPadding).clamp(0, text.length);

    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';

    // Collapsed to one line: recognised text is full of line breaks, and a
    // result row that grows to five lines makes the list unscannable.
    final body = text
        .substring(start, end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return '$prefix$body$suffix';
  }

  /// Whether [document] satisfies the non-text parts of [query].
  ///
  /// Applied after the indexed lookup rather than instead of it: the index
  /// narrows the candidates, and this decides the ones it returned.
  static bool matchesFilters(Document document, SearchQuery query) {
    if (query.folderId != null && document.folderId != query.folderId) {
      return false;
    }

    final created = query.createdWithin;
    if (created != null && !created.contains(document.createdAt)) return false;

    final modified = query.modifiedWithin;
    if (modified != null && !modified.contains(document.updatedAt)) {
      return false;
    }

    return true;
  }

  /// Merges title and text matches into one ordered result list.
  ///
  /// A document matching both ways appears once, attributed to its title: the
  /// title is what the user sees in the row, so claiming the match came from
  /// the recognised text would send them looking for something already in front
  /// of them.
  ///
  /// Order follows [titleMatches] then [textMatches], each of which arrives
  /// already sorted by the query that produced it.
  static List<SearchResult> merge(
    List<SearchResult> titleMatches,
    List<SearchResult> textMatches,
  ) {
    final seen = <DocumentId>{};
    final merged = <SearchResult>[];

    for (final result in [...titleMatches, ...textMatches]) {
      if (seen.add(result.document.id)) merged.add(result);
    }

    return merged;
  }

  /// The message announced when the result count changes.
  ///
  /// Announced rather than only rendered, because a list that silently changes
  /// length tells a screen-reader user nothing.
  static String resultCountLabel(int count) => switch (count) {
    0 => 'No results',
    1 => '1 result',
    _ => '$count results',
  };
}
