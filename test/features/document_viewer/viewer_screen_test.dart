/// Widget tests for the document viewer screen.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_state.dart';
import 'package:doc_scanly/features/document_viewer/presentation/screens/viewer_screen.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'viewer_test_support.dart';

/// Stands in for the plugin-backed page surface.
///
/// A real one needs PDFium and a file on disk, neither of which exists in a
/// widget test — which is exactly why the surface is injected rather than built
/// by the screen.
Widget fakeSurface(
  BuildContext context, {
  required String filePath,
  required String? password,
  required int page,
  required ValueChanged<int> onPageChanged,
}) => const ColoredBox(
  key: ViewerKeys.pageView,
  // Black on white, like a page: a mid-grey placeholder fails the contrast
  // guideline, and the failure would be the test harness's rather than the
  // screen's.
  color: Color(0xFFFFFFFF),
  child: Center(
    child: Text('Page', style: TextStyle(color: Color(0xFF000000))),
  ),
);

void main() {
  late int backCount;
  late int shareCount;
  late int printCount;
  late List<ViewerDocumentAction> actions;

  setUp(() {
    backCount = 0;
    shareCount = 0;
    printCount = 0;
    actions = [];
  });

  Future<ViewerCubit> pump(
    WidgetTester tester, {
    ViewerHarness? harness,
    Size viewport = const Size(600, 1000),
    Brightness brightness = Brightness.light,
    bool load = true,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = (harness ?? ViewerHarness()).cubit();
    addTearDown(cubit.close);
    if (load) await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<ViewerCubit>.value(
          value: cubit,
          child: ViewerScreen(
            surfaceBuilder: fakeSurface,
            onBack: () => backCount++,
            onShare: () => shareCount++,
            onAction: (action) {
              actions.add(action);
              if (action == ViewerDocumentAction.print) printCount++;
            },
          ),
        ),
      ),
    );
    // Bounded rather than `pumpAndSettle`: the loading state shows an
    // indefinite progress indicator, which never settles.
    await tester.pump();
    await tester.pump();

    return cubit;
  }

  group('composition', () {
    testWidgets('renders the document and its page indicator', (tester) async {
      await pump(tester);

      expect(find.byKey(ViewerKeys.screen), findsOneWidget);
      expect(find.byKey(ViewerKeys.pageView), findsOneWidget);
      expect(find.byKey(ViewerKeys.pageIndicator), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
    });

    testWidgets('offers share and focused PDF actions once open', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(ViewerKeys.shareButton), findsOneWidget);
      expect(find.byKey(ViewerKeys.actionsMenu), findsOneWidget);

      await tester.tap(find.byKey(ViewerKeys.actionsMenu));
      await tester.pumpAndSettle();
      for (final key in [
        ViewerKeys.printButton,
        ViewerKeys.compressButton,
        ViewerKeys.splitButton,
        ViewerKeys.watermarkButton,
        ViewerKeys.passwordButton,
      ]) {
        expect(find.byKey(key), findsOneWidget);
      }
    });

    testWidgets('shows a loading indicator while opening', (tester) async {
      await pump(tester, load: false);

      expect(find.byKey(ViewerKeys.loadingIndicator), findsOneWidget);
    });

    testWidgets('hides the actions while loading', (tester) async {
      // Sharing a document that could not be read would produce a file the
      // recipient cannot open either.
      await pump(tester, load: false);

      expect(find.byKey(ViewerKeys.shareButton), findsNothing);
    });
  });

  group('actions', () {
    testWidgets('each action calls back exactly once', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(ViewerKeys.shareButton));
      await tester.tap(find.byKey(ViewerKeys.actionsMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.printButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.actionsMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.compressButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.actionsMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.managePagesButton));
      await tester.pump();

      expect(shareCount, 1);
      expect(printCount, 1);
      expect(actions, [
        ViewerDocumentAction.print,
        ViewerDocumentAction.compress,
        ViewerDocumentAction.pageManagement,
      ]);
    });

    testWidgets('compact width keeps secondary actions in a reachable menu', (
      tester,
    ) async {
      await pump(tester, viewport: const Size(390, 844));

      expect(find.byKey(ViewerKeys.shareButton), findsOneWidget);
      expect(find.byKey(ViewerKeys.actionsMenu), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(ViewerKeys.actionsMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.printButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.actionsMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ViewerKeys.splitButton));
      await tester.pumpAndSettle();

      expect(printCount, 1);
      expect(actions.last, ViewerDocumentAction.split);
    });

    testWidgets('back leaves the viewer', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pump();

      expect(backCount, 1);
    });
  });

  group('jump to page', () {
    Future<void> openJump(WidgetTester tester) async {
      await tester.tap(find.byKey(ViewerKeys.pageJumpButton));
      await tester.pumpAndSettle();
    }

    testWidgets('a valid number moves to that page', (tester) async {
      final cubit = await pump(tester);

      await openJump(tester);
      await tester.enterText(find.byKey(ViewerKeys.jumpToPageField), '3');
      await tester.tap(find.byKey(ViewerKeys.pageJumpConfirm));
      await tester.pumpAndSettle();

      expect(cubit.state.page, 3);
      expect(find.text('3 of 3'), findsOneWidget);
    });

    testWidgets('a number past the end stays visible with validation', (
      tester,
    ) async {
      final cubit = await pump(tester);

      await openJump(tester);
      await tester.enterText(find.byKey(ViewerKeys.jumpToPageField), '99');
      await tester.tap(find.byKey(ViewerKeys.pageJumpConfirm));
      await tester.pumpAndSettle();

      expect(cubit.state.page, 1);
      expect(find.text('Enter a page from 1 to 3.'), findsOneWidget);
      expect(find.byKey(ViewerKeys.pageJumpDialog), findsOneWidget);
    });

    testWidgets('cancel leaves the current page unchanged', (tester) async {
      final cubit = await pump(tester);
      cubit.goToPage(2);
      await tester.pump();

      await openJump(tester);
      await tester.enterText(find.byKey(ViewerKeys.jumpToPageField), '3');
      await tester.tap(find.byKey(ViewerKeys.pageJumpCancel));
      await tester.pumpAndSettle();

      expect(cubit.state.page, 2);
    });

    testWidgets('a non-numeric entry does nothing rather than guessing', (
      tester,
    ) async {
      final cubit = await pump(tester);
      cubit.goToPage(2);
      await tester.pumpAndSettle();

      await openJump(tester);
      await tester.enterText(find.byKey(ViewerKeys.jumpToPageField), 'seven');
      await tester.tap(find.byKey(ViewerKeys.pageJumpConfirm));
      await tester.pumpAndSettle();

      expect(cubit.state.page, 2);
      expect(find.text('Enter a page from 1 to 3.'), findsOneWidget);
    });
  });

  group('protected documents', () {
    Future<ViewerCubit> pumpLocked(WidgetTester tester) => pump(
      tester,
      harness: ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
      ),
    );

    testWidgets('prompts for a password', (tester) async {
      await pumpLocked(tester);

      expect(find.byKey(ViewerKeys.passwordField), findsOneWidget);
      expect(find.byKey(ViewerKeys.unlockButton), findsOneWidget);
    });

    testWidgets('renders no document content before it is unlocked', (
      tester,
    ) async {
      // The spec requires that nothing of a locked document is shown.
      await pumpLocked(tester);

      expect(find.byKey(ViewerKeys.pageView), findsNothing);
      expect(find.byKey(ViewerKeys.pageIndicator), findsNothing);
      expect(find.text('Invoice 2026'), findsNothing);
      expect(find.byKey(ViewerKeys.shareButton), findsNothing);
    });

    testWidgets('the correct password reveals the document', (tester) async {
      await pumpLocked(tester);

      await tester.enterText(find.byKey(ViewerKeys.passwordField), 'secret');
      await tester.tap(find.byKey(ViewerKeys.unlockButton));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(ViewerKeys.pageView), findsOneWidget);
      expect(find.text('Invoice 2026'), findsOneWidget);
    });

    testWidgets('an incorrect password keeps it locked and says so', (
      tester,
    ) async {
      await pumpLocked(tester);

      await tester.enterText(find.byKey(ViewerKeys.passwordField), 'wrong');
      await tester.tap(find.byKey(ViewerKeys.unlockButton));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(ViewerKeys.pageView), findsNothing);
      expect(find.text('That password did not work'), findsOneWidget);
    });

    testWidgets('an empty password does nothing', (tester) async {
      await pumpLocked(tester);

      await tester.tap(find.byKey(ViewerKeys.unlockButton));
      await tester.pump();

      expect(find.byKey(ViewerKeys.passwordField), findsOneWidget);
      expect(find.text('That password did not work'), findsNothing);
    });
  });

  group('failure', () {
    testWidgets('a corrupt file shows an error view and does not crash', (
      tester,
    ) async {
      await pump(
        tester,
        harness: ViewerHarness(
          renderer: FakePdfRenderer(failure: const Failure.corruptFile()),
        ),
      );

      expect(find.byKey(ViewerKeys.errorView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a missing file shows an error view', (tester) async {
      await pump(tester, harness: ViewerHarness(documentFound: false));

      expect(find.byKey(ViewerKeys.errorView), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('a phone viewport shows only the page', (tester) async {
      await pump(
        tester,
        harness: ViewerHarness(),
        viewport: const Size(390, 844),
      );

      expect(find.byKey(ViewerKeys.pageView), findsOneWidget);
      expect(find.byKey(ViewerKeys.textPanel), findsNothing);
    });

    testWidgets('a tablet with no recognised text shows only the page', (
      tester,
    ) async {
      await pump(tester, viewport: const Size(1280, 900));

      expect(find.byKey(ViewerKeys.textPanel), findsNothing);
    });

    testWidgets('neither viewport overflows', (tester) async {
      for (final size in [const Size(390, 844), const Size(1280, 900)]) {
        await pump(tester, viewport: size);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('accessibility', () {
    testWidgets('the page indicator announces itself as a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(
        find.bySemanticsLabel('Page 1 of 3, jump to page'),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('each action control is labelled', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(
        find.bySemanticsLabel(RegExp('Share document')),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.bySemanticsLabel(RegExp('More document actions')),
        findsAtLeastNWidgets(1),
      );

      await tester.tap(find.byKey(ViewerKeys.actionsMenu));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Print')), findsAtLeastNWidgets(1));
      expect(
        find.bySemanticsLabel(RegExp('Compress')),
        findsAtLeastNWidgets(1),
      );

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, brightness: Brightness.dark);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives the largest supported text scale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = ViewerHarness().cubit();
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<ViewerCubit>.value(
            value: cubit,
            child: ViewerScreen(
              surfaceBuilder: fakeSurface,
              onBack: () {},
              onShare: () {},
              onAction: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('state', () {
    test('an initial state exposes no document', () {
      const state = ViewerState.initial();

      expect(state.document, isNull);
      expect(state.isReady, isFalse);
      expect(state.title, isEmpty);
    });
  });
}
