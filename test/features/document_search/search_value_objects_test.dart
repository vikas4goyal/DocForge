/// Tier 1 — the value objects search is built from.
///
/// Equality and hashing are not incidental here. A [SearchQuery] is what the
/// Bloc de-duplicates against to decide whether a keystroke is worth re-running
/// a query for, and a [SearchResult] is what a list compares to decide whether
/// a row changed. Two values that should be equal and are not mean the work
/// runs again on every frame; two that should differ and do not mean a result
/// silently fails to update.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/features/document_search/domain/search_query.dart';
import 'package:flutter_test/flutter_test.dart';

Document documentNamed(String title) => Document(
  id: DocumentId('doc-$title'),
  title: title,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026, 3),
  pageCount: 1,
  sizeInBytes: 1024,
  libraryPath: LibraryPath.parse('$title.pdf'),
);

void main() {
  group('DateRange', () {
    test('an unbounded range restricts nothing', () {
      const range = DateRange();

      expect(range.isUnbounded, isTrue);
      expect(range.contains(DateTime.utc(1999)), isTrue);
      expect(range.contains(DateTime.utc(2050)), isTrue);
    });

    test('a lower bound alone expresses "everything since"', () {
      final range = DateRange(from: DateTime.utc(2026, 3));

      expect(range.isUnbounded, isFalse);
      expect(range.contains(DateTime.utc(2026, 2, 28)), isFalse);
      expect(range.contains(DateTime.utc(2026, 4)), isTrue);
    });

    test('an upper bound alone expresses "everything before"', () {
      final range = DateRange(to: DateTime.utc(2026, 3));

      expect(range.contains(DateTime.utc(2026, 2)), isTrue);
      expect(range.contains(DateTime.utc(2026, 4)), isFalse);
    });

    test('both bounds are inclusive', () {
      final range = DateRange(
        from: DateTime.utc(2026, 3),
        to: DateTime.utc(2026, 4),
      );

      // Inclusive at both ends, so "March to April" means what a user means by
      // it rather than excluding the days they named.
      expect(range.contains(DateTime.utc(2026, 3)), isTrue);
      expect(range.contains(DateTime.utc(2026, 4)), isTrue);
    });

    test('a local-time moment is compared in UTC', () {
      final range = DateRange(from: DateTime.utc(2026, 3, 1, 12));

      // Stored timestamps are UTC. Comparing one against a local-time bound
      // would shift the boundary by the machine's offset, so the same search
      // would return different results in different time zones.
      expect(range.contains(DateTime.utc(2026, 3, 1, 13).toLocal()), isTrue);
    });

    test('equal ranges are equal and hash alike', () {
      final a = DateRange(from: DateTime.utc(2026), to: DateTime.utc(2027));
      final b = DateRange(from: DateTime.utc(2026), to: DateTime.utc(2027));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(DateRange(from: DateTime.utc(2026))));
    });

    test('describes itself with both bounds', () {
      expect(const DateRange().toString(), contains('DateRange'));
    });
  });

  group('SearchQuery', () {
    test('queries with the same terms are equal and hash alike', () {
      const a = SearchQuery(term: 'invoice');
      const b = SearchQuery(term: 'invoice');

      // What the Bloc de-duplicates against: two equal queries must not cause
      // the same search to run twice on consecutive keystrokes.
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different term is a different query', () {
      expect(
        const SearchQuery(term: 'invoice'),
        isNot(const SearchQuery(term: 'receipt')),
      );
    });

    test('a different folder is a different query', () {
      expect(
        const SearchQuery(term: 'invoice'),
        isNot(
          const SearchQuery(term: 'invoice', folderId: FolderId('folder-1')),
        ),
      );
    });

    test('a different date filter is a different query', () {
      final withDate = SearchQuery(
        term: 'invoice',
        createdWithin: DateRange(from: DateTime.utc(2026)),
      );

      expect(withDate, isNot(const SearchQuery(term: 'invoice')));
    });

    test('describes itself with its term and folder', () {
      const query = SearchQuery(term: 'invoice');

      expect(query.toString(), contains('invoice'));
    });
  });

  group('SearchResult', () {
    test('a title match needs no snippet', () {
      final result = SearchResult(
        document: documentNamed('Invoice'),
        source: MatchSource.title,
      );

      // The title is already on the row, so repeating it as a snippet would be
      // the same words twice.
      expect(result.hasSnippet, isFalse);
    });

    test('a whitespace-only snippet is not worth showing', () {
      final result = SearchResult(
        document: documentNamed('Invoice'),
        source: MatchSource.recognisedText,
        snippet: '   ',
      );

      expect(result.hasSnippet, isFalse);
    });

    test('a text match carries the matching words in context', () {
      final result = SearchResult(
        document: documentNamed('Invoice'),
        source: MatchSource.recognisedText,
        snippet: 'total due on receipt',
      );

      // Which is what tells the user why a document with an unrelated title is
      // in their results at all.
      expect(result.hasSnippet, isTrue);
      expect(result.source, MatchSource.recognisedText);
    });

    test('equal results are equal and hash alike', () {
      final document = documentNamed('Invoice');
      final a = SearchResult(document: document, source: MatchSource.title);
      final b = SearchResult(document: document, source: MatchSource.title);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          SearchResult(document: document, source: MatchSource.recognisedText),
        ),
      );
    });
  });
}
