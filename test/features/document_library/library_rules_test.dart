import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/features/document_library/domain/library_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NameRules', () {
    test('accepts an ordinary name', () {
      expect(NameRules.isValid('Invoice'), isTrue);
      expect(NameRules.normalise('Invoice'), 'Invoice');
    });

    test('rejects an empty or whitespace-only name', () {
      expect(NameRules.isValid(''), isFalse);
      expect(NameRules.isValid('   '), isFalse);
      expect(NameRules.isValid('\t\n'), isFalse);
      expect(NameRules.normalise('   '), isNull);
    });

    test('trims incidental whitespace', () {
      expect(NameRules.normalise('  Invoice  '), 'Invoice');
    });

    test('truncates a name beyond the maximum length', () {
      final long = 'a' * (NameRules.maxLength + 50);

      expect(NameRules.normalise(long), hasLength(NameRules.maxLength));
    });

    test('keeps a name exactly at the maximum length', () {
      final exact = 'a' * NameRules.maxLength;

      expect(NameRules.normalise(exact), exact);
    });

    test('accepts punctuation and non-Latin characters', () {
      expect(NameRules.normalise('Facture — Été 2026'), 'Facture — Été 2026');
      expect(NameRules.isValid('請求書'), isTrue);
    });
  });

  group('DocumentRules.canHavePageCount', () {
    test('requires at least one page', () {
      // A document with no pages has nothing to render.
      expect(DocumentRules.canHavePageCount(0), isFalse);
      expect(DocumentRules.canHavePageCount(1), isTrue);
      expect(DocumentRules.canHavePageCount(10), isTrue);
    });

    test('rejects a negative count', () {
      expect(DocumentRules.canHavePageCount(-1), isFalse);
    });
  });

  group('DocumentRules.matchesFilter', () {
    final visible = sampleDocument;
    final archived = sampleDocument.copyWith(isArchived: true);
    final favourite = sampleDocument.copyWith(isFavourite: true);
    final archivedFavourite = sampleDocument.copyWith(
      isArchived: true,
      isFavourite: true,
    );

    test('all excludes archived documents', () {
      expect(DocumentRules.matchesFilter(visible, DocumentFilter.all), isTrue);
      expect(
        DocumentRules.matchesFilter(archived, DocumentFilter.all),
        isFalse,
      );
    });

    test('favourites excludes archived documents', () {
      // An archived favourite must not reappear in the favourites view.
      expect(
        DocumentRules.matchesFilter(favourite, DocumentFilter.favourites),
        isTrue,
      );
      expect(
        DocumentRules.matchesFilter(visible, DocumentFilter.favourites),
        isFalse,
      );
      expect(
        DocumentRules.matchesFilter(
          archivedFavourite,
          DocumentFilter.favourites,
        ),
        isFalse,
      );
    });

    test('archived returns only archived documents', () {
      expect(
        DocumentRules.matchesFilter(archived, DocumentFilter.archived),
        isTrue,
      );
      expect(
        DocumentRules.matchesFilter(visible, DocumentFilter.archived),
        isFalse,
      );
    });

    test('folder requires a matcher and excludes archived documents', () {
      final inFolder = sampleDocument.copyWith(
        folderId: const FolderId('folder-1'),
      );

      expect(
        DocumentRules.matchesFilter(
          inFolder,
          DocumentFilter.folder,
          folderMatcher: (d) => d.folderId == const FolderId('folder-1'),
        ),
        isTrue,
      );
      expect(
        DocumentRules.matchesFilter(
          inFolder.copyWith(isArchived: true),
          DocumentFilter.folder,
          folderMatcher: (d) => true,
        ),
        isFalse,
      );
    });

    test('folder without a matcher matches nothing', () {
      // Failing closed: a missing matcher must not silently return everything.
      expect(
        DocumentRules.matchesFilter(visible, DocumentFilter.folder),
        isFalse,
      );
    });
  });

  group('DocumentRules.sorted', () {
    final documents = [
      sampleDocument.copyWith(
        id: const DocumentId('b'),
        title: 'banana',
        createdAt: DateTime.utc(2026, 2),
        updatedAt: DateTime.utc(2026, 3),
      ),
      sampleDocument.copyWith(
        id: const DocumentId('a'),
        title: 'Apple',
        createdAt: DateTime.utc(2026, 3),
        updatedAt: DateTime.utc(2026, 3, 3),
      ),
      sampleDocument.copyWith(
        id: const DocumentId('c'),
        title: 'cherry',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 3, 2),
      ),
    ];

    List<String> idsAfter(DocumentSort sort) =>
        DocumentRules.sorted(documents, sort).map((d) => d.id.value).toList();

    test('orders by modified date descending by default', () {
      expect(idsAfter(DocumentSort.modifiedDescending), ['a', 'c', 'b']);
    });

    test('orders by modified date ascending', () {
      expect(idsAfter(DocumentSort.modifiedAscending), ['b', 'c', 'a']);
    });

    test('orders by creation date descending', () {
      expect(idsAfter(DocumentSort.createdDescending), ['a', 'b', 'c']);
    });

    test('orders by title case-insensitively', () {
      // A capitalised title must not sort ahead of every lower-case one.
      expect(idsAfter(DocumentSort.titleAscending), ['a', 'b', 'c']);
    });

    test('does not mutate the input', () {
      final original = documents.map((d) => d.id.value).toList();

      DocumentRules.sorted(documents, DocumentSort.titleAscending);

      expect(documents.map((d) => d.id.value).toList(), original);
    });

    test('handles an empty list', () {
      expect(
        DocumentRules.sorted(const [], DocumentSort.modifiedDescending),
        isEmpty,
      );
    });
  });

  group('DocumentRules.duplicateTitle', () {
    test('distinguishes a copy from its original', () {
      expect(DocumentRules.duplicateTitle('Invoice'), 'Invoice (copy)');
    });

    test('produces a different title from the original', () {
      const title = 'Invoice';

      expect(DocumentRules.duplicateTitle(title), isNot(title));
    });
  });

  group('FolderDeletionStrategy', () {
    test('offers both outcomes so no document is lost silently', () {
      expect(FolderDeletionStrategy.values, hasLength(2));
      expect(
        FolderDeletionStrategy.values,
        containsAll([
          FolderDeletionStrategy.moveDocumentsOut,
          FolderDeletionStrategy.deleteDocuments,
        ]),
      );
    });
  });
}
