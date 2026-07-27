/// Tests for the PDF editing domain rules.
///
/// These carry more weight than usual: the PDF engine does not load in the host
/// test VM, so which pages an operation acts on and in what order is verified
/// here or nowhere until the app runs on a device.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Document doc(String id, {String title = 'Invoice', int pageCount = 4}) =>
    Document(
      id: DocumentId(id),
      title: title,
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 3, 14),
      pageCount: pageCount,
      sizeInBytes: 4096,
      libraryPath: LibraryPath.parse('$id.pdf'),
    );

void main() {
  group('canDelete', () {
    test('allows deleting when pages remain', () {
      expect(PdfEditRules.canDelete({0}, pageCount: 3), isTrue);
    });

    test('refuses deleting the only page', () {
      expect(PdfEditRules.canDelete({0}, pageCount: 1), isFalse);
    });

    test('refuses deleting every page of a longer document', () {
      // The rule is about what would remain, not about how many are selected.
      expect(PdfEditRules.canDelete({0, 1, 2}, pageCount: 3), isFalse);
    });

    test('refuses an empty selection', () {
      expect(PdfEditRules.canDelete(const {}, pageCount: 5), isFalse);
    });
  });

  group('pagesAfterDeleting', () {
    test('keeps the pages that were not selected, in order', () {
      expect(PdfEditRules.pagesAfterDeleting({1, 3}, pageCount: 5), [0, 2, 4]);
    });

    test('ignores a selection outside the document', () {
      expect(PdfEditRules.pagesAfterDeleting({9}, pageCount: 3), [0, 1, 2]);
    });
  });

  group('pagesAfterDuplicating', () {
    test('inserts the copy immediately after the original', () {
      // Immediately after, not appended: the spec requires it, and a copy at
      // the end of a fifty-page document is one the user has to hunt for.
      expect(PdfEditRules.pagesAfterDuplicating(1, pageCount: 4), [
        0,
        1,
        1,
        2,
        3,
      ]);
    });

    test('handles duplicating the first page', () {
      expect(PdfEditRules.pagesAfterDuplicating(0, pageCount: 2), [0, 0, 1]);
    });

    test('handles duplicating the last page', () {
      expect(PdfEditRules.pagesAfterDuplicating(1, pageCount: 2), [0, 1, 1]);
    });

    test('increases the page count by exactly one', () {
      expect(PdfEditRules.pagesAfterDuplicating(2, pageCount: 6), hasLength(7));
    });
  });

  group('canSplit', () {
    test('allows a split between two pages', () {
      expect(PdfEditRules.canSplit(1, pageCount: 3), isTrue);
    });

    test('refuses a split after the last page', () {
      // It would produce an empty second half, which is not a split.
      expect(PdfEditRules.canSplit(3, pageCount: 3), isFalse);
    });

    test('refuses a split before the first page', () {
      expect(PdfEditRules.canSplit(0, pageCount: 3), isFalse);
    });

    test('refuses splitting a single-page document', () {
      expect(PdfEditRules.canSplit(1, pageCount: 1), isFalse);
    });
  });

  group('splitRanges', () {
    test('the two halves are together the original, in order', () {
      // The property the split scenario states, asserted directly.
      final ranges = PdfEditRules.splitRanges(2, pageCount: 5);

      expect([...ranges.first, ...ranges.second], [0, 1, 2, 3, 4]);
    });

    test('the split point ends the first half', () {
      final ranges = PdfEditRules.splitRanges(2, pageCount: 5);

      expect(ranges.first, [0, 1]);
      expect(ranges.second, [2, 3, 4]);
    });
  });

  group('orderedSelection', () {
    test('sorts a tap-ordered selection into document order', () {
      // A selection made bottom-up would otherwise produce a document whose
      // pages run backwards.
      expect(PdfEditRules.orderedSelection([4, 1, 3]), [1, 3, 4]);
    });

    test('removes a page selected twice', () {
      expect(PdfEditRules.orderedSelection([2, 2, 1]), [1, 2]);
    });

    test('handles an empty selection', () {
      expect(PdfEditRules.orderedSelection(const []), isEmpty);
    });
  });

  group('canMerge', () {
    test('needs at least two documents', () {
      expect(PdfEditRules.canMerge([doc('a')]), isFalse);
      expect(PdfEditRules.canMerge([doc('a'), doc('b')]), isTrue);
    });

    test('refuses an empty list', () {
      expect(PdfEditRules.canMerge(const []), isFalse);
    });
  });

  group('compression', () {
    test('is worth keeping when the file got smaller', () {
      expect(
        PdfEditRules.compressionWorthKeeping(
          originalBytes: 1000,
          compressedBytes: 800,
        ),
        isTrue,
      );
    });

    test('is not worth keeping when the file got larger', () {
      // A rewrite can legitimately grow; the spec requires the original kept.
      expect(
        PdfEditRules.compressionWorthKeeping(
          originalBytes: 1000,
          compressedBytes: 1200,
        ),
        isFalse,
      );
    });

    test('is not worth keeping when the size is unchanged', () {
      expect(
        PdfEditRules.compressionWorthKeeping(
          originalBytes: 1000,
          compressedBytes: 1000,
        ),
        isFalse,
      );
    });

    test('reports the saving as a percentage and both sizes', () {
      final message = PdfEditRules.sizeChangeMessage(
        originalBytes: 2 * 1024 * 1024,
        newBytes: 1024 * 1024,
      );

      expect(message, contains('50%'));
      expect(message, contains('2.0 MB'));
      expect(message, contains('1.0 MB'));
    });

    test('says so when nothing could be saved', () {
      expect(
        PdfEditRules.sizeChangeMessage(originalBytes: 100, newBytes: 120),
        contains('already as small'),
      );
    });
  });

  group('validation', () {
    test('a blank watermark is rejected', () {
      expect(PdfEditRules.isValidWatermark('   '), isFalse);
      expect(PdfEditRules.isValidWatermark('DRAFT'), isTrue);
    });

    test('a blank password is rejected', () {
      // It would produce a file that prompts and then accepts nothing.
      expect(PdfEditRules.isValidPassword('  '), isFalse);
      expect(PdfEditRules.isValidPassword('hunter2'), isTrue);
    });
  });

  group('titles', () {
    test('an extracted document names how many pages it took', () {
      expect(PdfEditRules.extractedTitle('Invoice', 3), 'Invoice (3 pages)');
      expect(PdfEditRules.extractedTitle('Invoice', 1), 'Invoice (1 page)');
    });

    test('a merged document is named after the first source', () {
      expect(
        PdfEditRules.mergedTitle([doc('a', title: 'Q1'), doc('b')]),
        'Q1 (merged)',
      );
    });

    test('a merge of nothing still has a name', () {
      expect(PdfEditRules.mergedTitle(const []), isNotEmpty);
    });

    test('split halves are distinguishable', () {
      final titles = PdfEditRules.splitTitles('Invoice');

      expect(titles.first, isNot(titles.second));
    });
  });

  group('operations', () {
    test('page operations need a selection and document ones do not', () {
      expect(PdfEditOperation.rotate.needsSelection, isTrue);
      expect(PdfEditOperation.delete.needsSelection, isTrue);
      expect(PdfEditOperation.compress.needsSelection, isFalse);
      expect(PdfEditOperation.protect.needsSelection, isFalse);
    });

    test('deriving operations are marked as such', () {
      // Drives what happens afterwards: a new document is opened, an in-place
      // edit leaves the user where they were.
      expect(PdfEditOperation.extract.producesNewDocument, isTrue);
      expect(PdfEditOperation.merge.producesNewDocument, isTrue);
      expect(PdfEditOperation.split.producesNewDocument, isTrue);
      expect(PdfEditOperation.rotate.producesNewDocument, isFalse);
    });

    test('every operation has a label and a semantics label', () {
      for (final operation in PdfEditOperation.values) {
        expect(operation.label, isNotEmpty);
        expect(operation.semanticsLabel, isNotEmpty);
      }
    });
  });

  group('accessibility labels', () {
    test('a page thumbnail announces its number and selection state', () {
      // A thumbnail that only announced "page 3" would give a screen-reader
      // user no way to know what they have chosen.
      expect(
        PdfEditRules.pageSemanticsLabel(3, pageCount: 8, isSelected: true),
        'Page 3 of 8, selected',
      );
      expect(
        PdfEditRules.pageSemanticsLabel(3, pageCount: 8, isSelected: false),
        'Page 3 of 8, not selected',
      );
    });

    test('progress names the page for a multi-page operation', () {
      expect(PdfEditRules.progressLabel(2, 9), 'Page 2 of 9…');
      expect(PdfEditRules.progressLabel(1, 1), 'Working…');
    });
  });
}
