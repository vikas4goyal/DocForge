import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/page_table_cubit.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/page_table_state.dart';
import 'package:flutter_test/flutter_test.dart';

PageDraft page(String id) =>
    PageDraft(id: PageId(id), originalImagePath: '/staging/$id.jpg');

List<String> idsOf(PageTableCubit cubit) => [
  for (final p in cubit.state.pages) p.id.value,
];

void main() {
  PageTableCubit seeded(int count) => PageTableCubit(
    initialPages: [for (var i = 0; i < count; i++) page('p$i')],
  );

  group('initial state', () {
    test('a new session is empty and cannot be saved', () {
      final cubit = PageTableCubit();

      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.canSave, isFalse);
      expect(cubit.state.needsDiscardConfirmation, isFalse);
    });

    test('a shared selection seeds the table', () {
      // Import and share arrive with pages already chosen; a session started
      // from the Create control begins empty.
      expect(seeded(3).state.pageCount, 3);
    });
  });

  group('adding', () {
    blocTest<PageTableCubit, PageTableState>(
      'appends the page as the last row',
      build: PageTableCubit.new,
      act: (cubit) => cubit
        ..addPage(page('a'))
        ..addPage(page('b')),
      verify: (cubit) => expect(idsOf(cubit), ['a', 'b']),
    );

    blocTest<PageTableCubit, PageTableState>(
      'the table can be saved once a page exists',
      build: PageTableCubit.new,
      act: (cubit) => cubit.addPage(page('a')),
      verify: (cubit) => expect(cubit.state.canSave, isTrue),
    );

    blocTest<PageTableCubit, PageTableState>(
      'shows it is busy while a page is being added',
      build: PageTableCubit.new,
      act: (cubit) => cubit.beginAddingPage(),
      verify: (cubit) => expect(cubit.state.isAddingPage, isTrue),
    );

    blocTest<PageTableCubit, PageTableState>(
      'cancelling adds nothing and leaves the table as it was',
      build: () => seeded(2),
      act: (cubit) => cubit
        ..beginAddingPage()
        ..cancelAddingPage(),
      verify: (cubit) {
        expect(cubit.state.isAddingPage, isFalse);
        expect(cubit.state.pageCount, 2);
      },
    );
  });

  group('reordering', () {
    blocTest<PageTableCubit, PageTableState>(
      'a drag renumbers every row',
      build: () => seeded(3),
      act: (cubit) => cubit.reorder(2, 0),
      verify: (cubit) => expect(idsOf(cubit), ['p2', 'p0', 'p1']),
    );

    blocTest<PageTableCubit, PageTableState>(
      'move up and move down reorder without a drag',
      build: () => seeded(3),
      act: (cubit) => cubit
        ..moveUp(1)
        ..moveDown(0),
      verify: (cubit) => expect(idsOf(cubit), ['p0', 'p1', 'p2']),
    );

    blocTest<PageTableCubit, PageTableState>(
      'a drag that ends outside the list changes nothing',
      build: () => seeded(3),
      act: (cubit) => cubit.reorder(0, 9),
      verify: (cubit) => expect(idsOf(cubit), ['p0', 'p1', 'p2']),
    );
  });

  group('deleting', () {
    blocTest<PageTableCubit, PageTableState>(
      'removes the row and offers an undo',
      build: () => seeded(3),
      act: (cubit) => cubit.delete(1),
      verify: (cubit) {
        expect(idsOf(cubit), ['p0', 'p2']);
        expect(cubit.state.canUndo, isTrue);
      },
    );

    blocTest<PageTableCubit, PageTableState>(
      'undo puts the page back where it was',
      build: () => seeded(3),
      act: (cubit) => cubit
        ..delete(1)
        ..undoDelete(),
      verify: (cubit) => expect(idsOf(cubit), ['p0', 'p1', 'p2']),
    );

    blocTest<PageTableCubit, PageTableState>(
      'the undo lapses after another edit',
      build: () => seeded(3),
      act: (cubit) => cubit
        ..delete(1)
        ..reorder(0, 1),
      verify: (cubit) {
        // An undo offered after further changes would put a page back into a
        // list it no longer belongs to.
        expect(cubit.state.canUndo, isFalse);
      },
    );

    blocTest<PageTableCubit, PageTableState>(
      'deleting the last page empties the table',
      build: () => seeded(1),
      act: (cubit) => cubit.delete(0),
      verify: (cubit) {
        expect(cubit.state.isEmpty, isTrue);
        expect(cubit.state.canSave, isFalse);
      },
    );

    blocTest<PageTableCubit, PageTableState>(
      'an out-of-range delete does nothing',
      build: () => seeded(2),
      act: (cubit) => cubit.delete(9),
      verify: (cubit) {
        expect(cubit.state.pageCount, 2);
        expect(cubit.state.canUndo, isFalse);
      },
    );

    blocTest<PageTableCubit, PageTableState>(
      'undo with nothing deleted does nothing',
      build: () => seeded(2),
      act: (cubit) => cubit.undoDelete(),
      verify: (cubit) => expect(cubit.state.pageCount, 2),
    );
  });

  group('replacing', () {
    blocTest<PageTableCubit, PageTableState>(
      'an edited page keeps its position',
      build: () => seeded(3),
      act: (cubit) => cubit.replace(
        1,
        page('p1').withEnhancement(
          const EnhancementSettings(filter: EnhancementFilter.grayscale),
        ),
      ),
      verify: (cubit) {
        // The user edited a page, not the order.
        expect(idsOf(cubit), ['p0', 'p1', 'p2']);
        expect(cubit.state.pages[1].hasEnhancement, isTrue);
      },
    );
  });

  group('clearing', () {
    blocTest<PageTableCubit, PageTableState>(
      'empties the table after a save or a discard',
      build: () => seeded(3),
      act: (cubit) => cubit.clear(),
      verify: (cubit) {
        expect(cubit.state.isEmpty, isTrue);
        expect(cubit.state.canUndo, isFalse);
      },
    );
  });

  group('discard confirmation', () {
    blocTest<PageTableCubit, PageTableState>(
      'is needed once a page exists',
      build: PageTableCubit.new,
      act: (cubit) => cubit.addPage(page('a')),
      verify: (cubit) => expect(cubit.state.needsDiscardConfirmation, isTrue),
    );
  });
}
