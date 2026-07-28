import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/features/document_creation/domain/creation_rules.dart';
import 'package:doc_forge/features/document_creation/domain/creation_session.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:flutter_test/flutter_test.dart';

PageDraft page(String id) =>
    PageDraft(id: PageId(id), originalImagePath: '/staging/$id.jpg');

List<PageDraft> pages(int count) => [
  for (var i = 0; i < count; i++) page('p$i'),
];

List<String> idsOf(List<PageDraft> list) => [for (final p in list) p.id.value];

void main() {
  group('reorder', () {
    test('moves a page earlier', () {
      expect(idsOf(CreationSession.reorder(pages(3), 2, 0)), [
        'p2',
        'p0',
        'p1',
      ]);
    });

    test('moves a page later', () {
      expect(idsOf(CreationSession.reorder(pages(3), 0, 2)), [
        'p1',
        'p2',
        'p0',
      ]);
    });

    test('a drag that ends where it began changes nothing', () {
      expect(idsOf(CreationSession.reorder(pages(3), 1, 1)), [
        'p0',
        'p1',
        'p2',
      ]);
    });

    test('a drag ending outside the list is not an error', () {
      // A gesture, not a fault: the list comes back unchanged.
      expect(CreationSession.reorder(pages(3), 0, 9), hasLength(3));
      expect(CreationSession.reorder(pages(3), -1, 0), hasLength(3));
    });

    test('does not mutate the list it was given', () {
      final original = pages(3);

      CreationSession.reorder(original, 0, 2);

      expect(idsOf(original), ['p0', 'p1', 'p2']);
    });
  });

  group('moveUp and moveDown', () {
    test('moveUp swaps with the previous page', () {
      expect(idsOf(CreationSession.moveUp(pages(3), 1)), ['p1', 'p0', 'p2']);
    });

    test('moveDown swaps with the next page', () {
      expect(idsOf(CreationSession.moveDown(pages(3), 1)), ['p0', 'p2', 'p1']);
    });

    test('moving the first page up does nothing', () {
      expect(idsOf(CreationSession.moveUp(pages(3), 0)), ['p0', 'p1', 'p2']);
    });

    test('moving the last page down does nothing', () {
      expect(idsOf(CreationSession.moveDown(pages(3), 2)), ['p0', 'p1', 'p2']);
    });
  });

  group('delete and restore', () {
    test('removes the page at the index', () {
      expect(idsOf(CreationSession.delete(pages(3), 1)), ['p0', 'p2']);
    });

    test('an out-of-range index changes nothing', () {
      expect(CreationSession.delete(pages(3), 7), hasLength(3));
    });

    test('restore puts the page back where it was', () {
      final remaining = CreationSession.delete(pages(3), 1);

      final restored = CreationSession.restore(remaining, page('p1'), 1);

      // Appending would put it at the end, which is not where the user had it.
      expect(idsOf(restored), ['p0', 'p1', 'p2']);
    });

    test('restore clamps an index the list can no longer hold', () {
      final restored = CreationSession.restore(pages(2), page('px'), 9);

      expect(idsOf(restored).last, 'px');
    });
  });

  group('replace', () {
    test('keeps the page in its position', () {
      final edited = page('p1').withEnhancement(
        const EnhancementSettings(filter: EnhancementFilter.grayscale),
      );

      final updated = CreationSession.replace(pages(3), 1, edited);

      // The user edited a page, not the order.
      expect(idsOf(updated), ['p0', 'p1', 'p2']);
      expect(updated[1].hasEnhancement, isTrue);
    });

    test('an out-of-range index changes nothing', () {
      expect(CreationSession.replace(pages(2), 5, page('px')), hasLength(2));
    });
  });

  group('canSave', () {
    test('an empty session cannot be saved', () {
      expect(CreationSession.canSave(const []), isFalse);
    });

    test('one page is enough', () {
      expect(CreationSession.canSave(pages(1)), isTrue);
    });
  });

  group('discard confirmation', () {
    test('is needed when there is something to lose', () {
      expect(CreationSession.needsDiscardConfirmation(pages(1)), isTrue);
    });

    test('is not needed for an empty session', () {
      // A confirmation over an empty table is a question with one answer.
      expect(CreationSession.needsDiscardConfirmation(const []), isFalse);
    });
  });

  group('page numbering', () {
    test('row 1 is page 1', () {
      expect(CreationSession.pageNumberAt(0), 1);
      expect(CreationSession.pageNumberAt(6), 7);
    });
  });

  group('toBundle', () {
    test('carries originals, not rendered results', () {
      final edited = page('p0').withEnhancement(
        const EnhancementSettings(filter: EnhancementFilter.blackAndWhite),
      );

      final bundle = CreationSession.toBundle([edited]);

      // Composition applies both layers itself; a rendered image would apply
      // the enhancement twice.
      expect(bundle.pages.single.imagePath, '/staging/p0.jpg');
      expect(
        bundle.pages.single.enhancement.filter,
        EnhancementFilter.blackAndWhite,
      );
    });

    test('preserves the order of the table', () {
      final bundle = CreationSession.toBundle(
        CreationSession.reorder(pages(3), 2, 0),
      );

      expect([for (final p in bundle.pages) p.id.value], ['p2', 'p0', 'p1']);
    });
  });

  group('CreationRules.validateName', () {
    test('accepts an ordinary name', () {
      expect(CreationRules.validateName('Invoice 2026'), isNull);
    });

    test('rejects an empty name', () {
      expect(CreationRules.validateName(''), ValidationIssue.emptyName);
      expect(CreationRules.validateName('   '), ValidationIssue.emptyName);
    });

    test('rejects a name that is illegal on disk', () {
      // The name becomes a file in a folder the user can also reach from their
      // file browser, so "not empty" is no longer enough.
      expect(CreationRules.validateName('Q1/Q2'), ValidationIssue.illegalName);
      expect(
        CreationRules.validateName('report:final'),
        ValidationIssue.illegalName,
      );
    });

    test('tolerates surrounding whitespace', () {
      expect(CreationRules.validateName('  Invoice  '), isNull);
    });
  });

  group('CreationRules.validatePassword', () {
    test('is satisfied when protection is off', () {
      expect(CreationRules.validatePassword('', '', enabled: false), isNull);
    });

    test('accepts a matching pair', () {
      expect(
        CreationRules.validatePassword('hunter2', 'hunter2', enabled: true),
        isNull,
      );
    });

    test('rejects a mismatch', () {
      // Never shown back, never recoverable: a typo would lock the user out of
      // their own document permanently.
      expect(
        CreationRules.validatePassword('hunter2', 'hunter3', enabled: true),
        ValidationIssue.passwordMismatch,
      );
    });

    test('rejects an empty field', () {
      expect(
        CreationRules.validatePassword('', '', enabled: true),
        ValidationIssue.emptyName,
      );
      expect(
        CreationRules.validatePassword('a', '', enabled: true),
        ValidationIssue.emptyName,
      );
    });
  });

  group('CreationRules.canSave', () {
    bool canSave({
      String name = 'Invoice',
      String password = '',
      String confirmation = '',
      bool passwordEnabled = false,
      bool hasPages = true,
      bool isSaving = false,
    }) => CreationRules.canSave(
      name: name,
      password: password,
      confirmation: confirmation,
      passwordEnabled: passwordEnabled,
      hasPages: hasPages,
      isSaving: isSaving,
    );

    test('a named session with pages can be saved', () {
      expect(canSave(), isTrue);
    });

    test('an empty session cannot', () {
      expect(canSave(hasPages: false), isFalse);
    });

    test('an empty name cannot', () {
      expect(canSave(name: ''), isFalse);
    });

    test('an illegal name cannot', () {
      expect(canSave(name: 'a/b'), isFalse);
    });

    test('a mismatched password cannot', () {
      expect(
        canSave(password: 'a', confirmation: 'b', passwordEnabled: true),
        isFalse,
      );
    });

    test('a matching password can', () {
      expect(
        canSave(password: 'a', confirmation: 'a', passwordEnabled: true),
        isTrue,
      );
    });

    test('a save already in flight cannot start another', () {
      expect(canSave(isSaving: true), isFalse);
    });
  });

  group('fileNameFor', () {
    test('appends the extension', () {
      expect(CreationRules.fileNameFor('Invoice'), 'Invoice.pdf');
    });

    test('does not double it', () {
      expect(CreationRules.fileNameFor('Invoice.pdf'), 'Invoice.pdf');
    });
  });
}
