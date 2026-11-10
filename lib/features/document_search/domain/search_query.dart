/// The value objects and rules behind search.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';

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
  /// Tokenised the same way titles are on write, so a term
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

/// One document that matched the search term in its title.
class SearchResult {
  /// Creates a result.
  const SearchResult({required this.document});

  /// The document that matched.
  final Document document;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult && other.document == document;

  @override
  int get hashCode => document.hashCode;
}

/// Rules for matching and presenting search results.
abstract final class SearchRules {
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
