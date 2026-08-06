import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/features/document_library/domain/library_reconciliation.dart';
import 'package:flutter_test/flutter_test.dart';

Document indexed(
  String id,
  String relative, {
  int sizeBytes = 1024,
  bool isFavourite = false,
  bool isArchived = false,
  bool hasRecognisedText = false,
}) => Document(
  id: DocumentId(id),
  title: LibraryPath.parse(relative).baseName,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  pageCount: 3,
  sizeInBytes: sizeBytes,
  libraryPath: LibraryPath.parse(relative),
  isFavourite: isFavourite,
  isArchived: isArchived,
  hasRecognisedText: hasRecognisedText,
);

LibraryFile found(
  String relative, {
  int sizeBytes = 1024,
  DateTime? modified,
}) => LibraryFile(
  path: LibraryPath.parse(relative),
  sizeBytes: sizeBytes,
  modifiedAt: modified,
);

void main() {
  group('unchanged', () {
    test('a file the index already describes is not a change', () {
      final diff = LibraryReconciliation.diff(
        indexed: [indexed('a', 'Invoice.pdf')],
        found: [found('Invoice.pdf')],
      );

      expect(diff.isEmpty, isTrue);
      expect(diff.changeCount, 0);
    });

    test('an empty library on both sides is empty', () {
      final diff = LibraryReconciliation.diff(
        indexed: const [],
        found: const [],
      );

      expect(diff.isEmpty, isTrue);
    });
  });

  group('added', () {
    test('a file the index has never seen', () {
      final diff = LibraryReconciliation.diff(
        indexed: const [],
        found: [found('Statement.pdf')],
      );

      expect(diff.added.single.path.relative, 'Statement.pdf');
      expect(diff.removed, isEmpty);
    });

    test('a file in a nested folder', () {
      final diff = LibraryReconciliation.diff(
        indexed: const [],
        found: [found('Invoices/2026/Receipt.pdf')],
      );

      expect(diff.added.single.path.folders, ['Invoices', '2026']);
    });
  });

  group('removed', () {
    test('a document whose file is gone', () {
      final diff = LibraryReconciliation.diff(
        indexed: [indexed('a', 'Invoice.pdf')],
        found: const [],
      );

      expect(diff.removed.single.id, const DocumentId('a'));
      expect(diff.added, isEmpty);
    });
  });

  group('modified', () {
    test('a file edited in place is a modification, not a replacement', () {
      final diff = LibraryReconciliation.diff(
        indexed: [indexed('a', 'Invoice.pdf')],
        found: [found('Invoice.pdf', sizeBytes: 2048)],
      );

      expect(diff.modified.single.document.id, const DocumentId('a'));
      expect(diff.modified.single.file.sizeBytes, 2048);
      expect(diff.added, isEmpty);
      expect(diff.removed, isEmpty);
    });

    test('applying it refreshes size and modified date', () {
      final change = ModifiedDocument(
        document: indexed('a', 'Invoice.pdf'),
        file: found(
          'Invoice.pdf',
          sizeBytes: 2048,
          modified: DateTime.utc(2026, 5),
        ),
      );

      final updated = LibraryReconciliation.applyModification(
        change,
        DateTime.utc(2026, 9),
      );

      expect(updated.sizeInBytes, 2048);
      expect(updated.updatedAt, DateTime.utc(2026, 5));
    });

    test('falls back to now when the platform reports no mtime', () {
      final change = ModifiedDocument(
        document: indexed('a', 'Invoice.pdf'),
        file: found('Invoice.pdf', sizeBytes: 2048),
      );

      final updated = LibraryReconciliation.applyModification(
        change,
        DateTime.utc(2026, 9),
      );

      expect(updated.updatedAt, DateTime.utc(2026, 9));
    });
  });

  group('renamed', () {
    test('a rename is a rename, not a delete and an add', () {
      final diff = LibraryReconciliation.diff(
        indexed: [indexed('a', 'Invoice.pdf')],
        found: [found('Renamed.pdf')],
      );

      expect(diff.renamed.single.document.id, const DocumentId('a'));
      expect(diff.renamed.single.file.path.relative, 'Renamed.pdf');
      expect(diff.added, isEmpty);
      expect(diff.removed, isEmpty);
    });

    test('a move between folders is also a rename', () {
      final diff = LibraryReconciliation.diff(
        indexed: [indexed('a', 'Invoice.pdf')],
        found: [found('Archive/Invoice.pdf')],
      );

      expect(diff.renamed.single.file.path.relative, 'Archive/Invoice.pdf');
    });

    test('the metadata a PDF cannot carry survives', () {
      final rename = RenamedDocument(
        document: indexed(
          'a',
          'Invoice.pdf',
          isFavourite: true,
          isArchived: true,
          hasRecognisedText: true,
        ),
        file: found('Renamed.pdf'),
      );

      final updated = LibraryReconciliation.applyRename(rename);

      // Losing these on a rename would lose them permanently: nothing in a PDF
      // records that the user starred it.
      expect(updated.isFavourite, isTrue);
      expect(updated.isArchived, isTrue);
      expect(updated.hasRecognisedText, isTrue);
      expect(updated.id, const DocumentId('a'));
    });

    test('the title follows the new file name', () {
      final rename = RenamedDocument(
        document: indexed('a', 'Invoice.pdf'),
        file: found('Statement 2026.pdf'),
      );

      final updated = LibraryReconciliation.applyRename(rename);

      // The user renamed the file; a list still showing "Invoice" would be
      // showing a name that exists nowhere.
      expect(updated.title, 'Statement 2026');
      expect(updated.relativePath, 'Statement 2026.pdf');
    });
  });

  group('ambiguity', () {
    test('two same-sized renames are not paired by guesswork', () {
      // Pairing these would be a coin toss whose loser silently inherits the
      // other document's favourite status and recognised text.
      final diff = LibraryReconciliation.diff(
        indexed: [
          indexed('a', 'One.pdf', sizeBytes: 100),
          indexed('b', 'Two.pdf', sizeBytes: 100),
        ],
        found: [
          found('Renamed1.pdf', sizeBytes: 100),
          found('Renamed2.pdf', sizeBytes: 100),
        ],
      );

      expect(diff.renamed, isEmpty);
      expect(diff.removed, hasLength(2));
      expect(diff.added, hasLength(2));
    });

    test('a unique rename beside an ambiguous pair still resolves', () {
      final diff = LibraryReconciliation.diff(
        indexed: [
          indexed('a', 'One.pdf', sizeBytes: 100),
          indexed('b', 'Two.pdf', sizeBytes: 100),
          indexed('c', 'Three.pdf', sizeBytes: 999),
        ],
        found: [
          found('R1.pdf', sizeBytes: 100),
          found('R2.pdf', sizeBytes: 100),
          found('Renamed3.pdf', sizeBytes: 999),
        ],
      );

      expect(diff.renamed.single.document.id, const DocumentId('c'));
    });

    test('a rename and an unrelated arrival of the same size do not pair', () {
      final diff = LibraryReconciliation.diff(
        indexed: [indexed('a', 'One.pdf', sizeBytes: 100)],
        found: [
          found('One.pdf', sizeBytes: 100),
          found('New.pdf', sizeBytes: 100),
        ],
      );

      // The path matched first, so nothing is left to mistake for a rename.
      expect(diff.renamed, isEmpty);
      expect(diff.added.single.path.relative, 'New.pdf');
    });
  });

  group('combinations', () {
    test('an add, a removal, a modification and a rename in one pass', () {
      final diff = LibraryReconciliation.diff(
        indexed: [
          indexed('keep', 'Keep.pdf', sizeBytes: 10),
          indexed('gone', 'Gone.pdf', sizeBytes: 20),
          indexed('edited', 'Edited.pdf', sizeBytes: 30),
          indexed('moved', 'Moved.pdf', sizeBytes: 40),
        ],
        found: [
          found('Keep.pdf', sizeBytes: 10),
          found('Edited.pdf', sizeBytes: 31),
          found('Archive/Moved.pdf', sizeBytes: 40),
          found('Brand New.pdf', sizeBytes: 50),
        ],
      );

      expect(diff.added.single.path.relative, 'Brand New.pdf');
      expect(diff.removed.single.id, const DocumentId('gone'));
      expect(diff.modified.single.document.id, const DocumentId('edited'));
      expect(diff.renamed.single.document.id, const DocumentId('moved'));
      expect(diff.changeCount, 4);
    });
  });

  group('folders', () {
    test('folder paths are carried through', () {
      final diff = LibraryReconciliation.diff(
        indexed: const [],
        found: const [],
        folders: ['Invoices', 'Invoices/2026'],
      );

      expect(diff.folders, ['Invoices', 'Invoices/2026']);
    });
  });

  group('determinism', () {
    test('the same inputs produce the same diff', () {
      List<Document> index() => [
        indexed('a', 'One.pdf', sizeBytes: 1),
        indexed('b', 'Two.pdf', sizeBytes: 2),
      ];
      List<LibraryFile> files() => [
        found('One.pdf', sizeBytes: 1),
        found('Renamed.pdf', sizeBytes: 2),
      ];

      final first = LibraryReconciliation.diff(
        indexed: index(),
        found: files(),
      );
      final second = LibraryReconciliation.diff(
        indexed: index(),
        found: files(),
      );

      expect(first.renamed, second.renamed);
      expect(first.added, second.added);
      expect(first.removed, second.removed);
    });
  });
}
