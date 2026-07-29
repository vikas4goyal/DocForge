/// Tier 2 — the page table over its real Cubit.
///
/// The page table is the screen the whole creation journey runs through, and
/// its state machine is where the rules live: a document with no pages cannot
/// be saved, a row's position *is* its page number, and a deletion is undoable
/// until the user leaves. A widget test that handed the screen a state could
/// render all of that correctly and prove none of it.
///
/// [PageTableCubit] owns no repository — it holds the session in memory and the
/// composition root does the saving — so this tier is the whole of it below the
/// device.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page_draft.dart';
import 'package:doc_forge/features/document_creation/presentation/creation_keys.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/page_table_cubit.dart';
import 'package:doc_forge/features/document_creation/presentation/screens/page_table_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';

/// A page draft standing in for a capture.
PageDraft draft(String id) =>
    PageDraft(id: PageId(id), originalImagePath: '/staging/$id.jpg');

void main() {
  late PageTableCubit cubit;

  Future<void> pumpTable(
    WidgetTester tester, {
    List<PageDraft> pages = const [],
  }) async {
    cubit = PageTableCubit(initialPages: pages);
    addTearDown(cubit.close);

    await pumpComponent(
      tester,
      PageTableScreen(
        actions: PageTableActions(
          onAddPage: () {},
          onCropPage: (_, _) {},
          onEnhancePage: (_, _) {},
          onSave: () {},
          onExit: () {},
          previewPathFor: (_) => null,
        ),
      ),
      providers: [BlocProvider.value(value: cubit)],
    );
    await settleComponent(tester);
  }

  group('PageTableScreen over its real Cubit', () {
    testWidgets('an empty session offers the empty state, not a list', (
      tester,
    ) async {
      await pumpTable(tester);

      expectVisible(CreationKeys.emptyState);
      expectNotVisible(CreationKeys.pageList);
    });

    testWidgets('a page per capture, each addressable by its own id', (
      tester,
    ) async {
      await pumpTable(tester, pages: [draft('a'), draft('b')]);

      // Rows are keyed by page rather than by position, because a test that
      // acted on "the second row" would break the moment a reorder landed.
      expectVisible(CreationKeys.row(const PageId('a')));
      expectVisible(CreationKeys.row(const PageId('b')));
      expectNotVisible(CreationKeys.emptyState);
    });

    testWidgets('saving is refused while the session has no pages', (
      tester,
    ) async {
      await pumpTable(tester);

      // The library forbids a document with no pages, so offering the control
      // would be offering a failure. Disabled rather than hidden: the user can
      // see that saving is where this ends up.
      final save = tester.widget<TextButton>(
        find.byKey(CreationKeys.saveButton),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('saving is offered once a page exists', (tester) async {
      await pumpTable(tester, pages: [draft('a')]);

      final save = tester.widget<TextButton>(
        find.byKey(CreationKeys.saveButton),
      );
      expect(save.onPressed, isNotNull);
    });

    testWidgets('removing a page removes its row', (tester) async {
      await pumpTable(tester, pages: [draft('a'), draft('b')]);

      cubit.delete(0);
      await settleComponent(tester);

      expectNotVisible(CreationKeys.row(const PageId('a')));
      expectVisible(CreationKeys.row(const PageId('b')));
    });

    testWidgets('an undone deletion puts the page back', (tester) async {
      await pumpTable(tester, pages: [draft('a'), draft('b')]);

      cubit.delete(0);
      await settleComponent(tester);
      expectNotVisible(CreationKeys.row(const PageId('a')));

      // Undo is what makes a delete safe to offer without a confirmation
      // dialog, so it has to work at the screen and not only in the Cubit.
      cubit.undoDelete();
      await settleComponent(tester);
      expectVisible(CreationKeys.row(const PageId('a')));
    });
  });
}
