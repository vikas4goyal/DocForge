/// Widget tests for the page table.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_creation/presentation/creation_keys.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/page_table_cubit.dart';
import 'package:doc_scanly/features/document_creation/presentation/screens/page_table_screen.dart';
import 'package:doc_scanly/features/document_creation/presentation/widgets/page_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

PageDraft page(String id) =>
    PageDraft(id: PageId(id), originalImagePath: '/staging/$id.jpg');

void main() {
  late List<int> cropped;
  late List<int> enhanced;
  late int addPageTaps;
  late int saveTaps;
  late int exitTaps;

  setUp(() {
    cropped = [];
    enhanced = [];
    addPageTaps = 0;
    saveTaps = 0;
    exitTaps = 0;
  });

  Future<PageTableCubit> pumpTable(
    WidgetTester tester, {
    int pages = 0,
    Size? viewport,
  }) async {
    tester.view.physicalSize = viewport ?? const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = PageTableCubit(
      initialPages: [for (var i = 0; i < pages; i++) page('p$i')],
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<PageTableCubit>.value(
          value: cubit,
          child: PageTableScreen(
            actions: PageTableActions(
              onAddPage: () => addPageTaps++,
              onCropPage: (index, _) => cropped.add(index),
              onEnhancePage: (index, _) => enhanced.add(index),
              onSave: () => saveTaps++,
              onExit: () => exitTaps++,
              previewPathFor: (_) => null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  group('empty state', () {
    testWidgets('invites the user to add a page', (tester) async {
      await pumpTable(tester);

      expect(find.byKey(CreationKeys.emptyState), findsOneWidget);
      expect(find.byType(PageRow), findsNothing);
    });

    testWidgets('save is disabled', (tester) async {
      await pumpTable(tester);

      final save = tester.widget<TextButton>(
        find.byKey(CreationKeys.saveButton),
      );
      // The library forbids a document with no pages, so offering the control
      // would be offering a failure.
      expect(save.onPressed, isNull);
    });

    testWidgets('its call to action adds a page', (tester) async {
      await pumpTable(tester);

      await tester.tap(find.text('Add page').first);
      await tester.pumpAndSettle();

      expect(addPageTaps, greaterThan(0));
    });
  });

  group('rows', () {
    testWidgets('row 1 is page 1 and row n is page n', (tester) async {
      await pumpTable(tester, pages: 3);

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Page 3'), findsOneWidget);
    });

    testWidgets('every row offers crop, enhance and delete', (tester) async {
      await pumpTable(tester, pages: 2);

      expect(find.byKey(CreationKeys.rowCropButton), findsNWidgets(2));
      expect(find.byKey(CreationKeys.rowEnhanceButton), findsNWidgets(2));
      expect(find.byKey(CreationKeys.rowDeleteButton), findsNWidgets(2));
    });

    testWidgets('every row has a drag handle', (tester) async {
      await pumpTable(tester, pages: 2);

      expect(find.byKey(CreationKeys.dragHandle), findsNWidgets(2));
    });

    testWidgets('crop opens for the row that was tapped', (tester) async {
      await pumpTable(tester, pages: 3);

      await tester.tap(find.byKey(CreationKeys.rowCropButton).at(1));
      await tester.pumpAndSettle();

      expect(cropped, [1]);
    });

    testWidgets('enhance opens for the row that was tapped', (tester) async {
      await pumpTable(tester, pages: 3);

      await tester.tap(find.byKey(CreationKeys.rowEnhanceButton).at(2));
      await tester.pumpAndSettle();

      expect(enhanced, [2]);
    });

    testWidgets('a row says which layers have been applied', (tester) async {
      final cubit = await pumpTable(tester, pages: 1);

      cubit.replace(
        0,
        page('p0').withEnhancement(
          const EnhancementSettings(filter: EnhancementFilter.grayscale),
        ),
      );
      await tester.pumpAndSettle();

      // Named per layer, because each is reverted separately.
      expect(find.text('enhanced'), findsOneWidget);
    });
  });

  group('reordering', () {
    testWidgets('renumbers the rows immediately', (tester) async {
      final cubit = await pumpTable(tester, pages: 3);

      cubit.reorder(2, 0);
      await tester.pumpAndSettle();

      final rows = tester.widgetList<PageRow>(find.byType(PageRow)).toList();
      expect(rows.first.page.id, const PageId('p2'));
      expect(rows.first.pageNumber, 1);
    });

    testWidgets('exposes semantic move actions', (tester) async {
      await pumpTable(tester, pages: 3);

      final rows = tester.widgetList<PageRow>(find.byType(PageRow)).toList();
      // Reordering must not require a gesture only a pointer can perform.
      expect(rows.first.onMoveUp, isNull);
      expect(rows.first.onMoveDown, isNotNull);
      expect(rows.last.onMoveUp, isNotNull);
      expect(rows.last.onMoveDown, isNull);
    });
  });

  group('deleting', () {
    testWidgets('removes the row and offers an undo', (tester) async {
      final cubit = await pumpTable(tester, pages: 3);

      await tester.tap(find.byKey(CreationKeys.rowDeleteButton).first);
      await tester.pumpAndSettle();

      expect(cubit.state.pageCount, 2);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('undo puts the page back', (tester) async {
      final cubit = await pumpTable(tester, pages: 3);
      await tester.tap(find.byKey(CreationKeys.rowDeleteButton).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(cubit.state.pages.first.id, const PageId('p0'));
    });

    testWidgets('deleting the last page shows the empty state', (tester) async {
      await pumpTable(tester, pages: 1);

      await tester.tap(find.byKey(CreationKeys.rowDeleteButton));
      await tester.pumpAndSettle();

      expect(find.byKey(CreationKeys.emptyState), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('is enabled once a page exists', (tester) async {
      await pumpTable(tester, pages: 1);

      final save = tester.widget<TextButton>(
        find.byKey(CreationKeys.saveButton),
      );
      expect(save.onPressed, isNotNull);
    });

    testWidgets('opens the save flow', (tester) async {
      await pumpTable(tester, pages: 1);

      await tester.tap(find.byKey(CreationKeys.saveButton));
      await tester.pumpAndSettle();

      expect(saveTaps, 1);
    });

    testWidgets('sits in the navigation bar', (tester) async {
      await pumpTable(tester, pages: 1);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(CreationKeys.saveButton),
        ),
        findsOneWidget,
      );
    });
  });

  group('adding', () {
    testWidgets('the add control opens the sources', (tester) async {
      await pumpTable(tester, pages: 1);

      await tester.tap(find.byKey(CreationKeys.addPageButton));
      await tester.pumpAndSettle();

      expect(addPageTaps, 1);
    });

    testWidgets('shows progress while a page is being added', (tester) async {
      final cubit = await pumpTable(tester, pages: 1);

      cubit.beginAddingPage();
      // Two pumps rather than pumpAndSettle: the progress bar animates
      // indefinitely, which is the point of it.
      await tester.pump();
      await tester.pump();

      expect(find.byKey(CreationKeys.loadingIndicator), findsOneWidget);
    });
  });

  group('leaving', () {
    testWidgets('the close control exits', (tester) async {
      await pumpTable(tester, pages: 1);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(exitTaps, 1);
    });
  });

  group('accessibility', () {
    testWidgets('rows announce their position', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTable(tester, pages: 3);

      // A page of a scan has no title; "page 3 of 7" is what the user tracks.
      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('row actions name the page they act on', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTable(tester, pages: 2);

      expect(find.bySemanticsLabel('Crop and rotate page 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Delete page 2'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('survives the largest supported text scale', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = PageTableCubit(initialPages: [page('p0')]);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<PageTableCubit>.value(
            value: cubit,
            child: PageTableScreen(
              actions: PageTableActions(
                onAddPage: () {},
                onCropPage: (_, _) {},
                onEnhancePage: (_, _) {},
                onSave: () {},
                onExit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('layout', () {
    testWidgets('uses the extra width on a tablet', (tester) async {
      await pumpTable(tester, pages: 3, viewport: const Size(1600, 1200));

      // The extra width goes to a constrained column rather than to rows
      // stretched across the whole viewport.
      expect(find.byType(PageRow), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });
}
