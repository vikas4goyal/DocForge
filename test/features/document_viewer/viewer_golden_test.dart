/// Golden tests for the document viewer.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
///
/// The page surface is a flat placeholder. A golden of a real rendered page
/// would be a golden of PDFium's output, which is not this project's code and
/// which no CI machine has a file to produce.
@Tags(['golden'])
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

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

/// Stands in for the page-rendering surface.
Widget goldenSurface(
  BuildContext context, {
  required String filePath,
  required String? password,
  required int page,
  required ValueChanged<int> onPageChanged,
}) => ColoredBox(
  key: ViewerKeys.pageView,
  color: const Color(0xFFE8E8E8),
  child: Center(
    child: Text(
      'Page $page',
      style: const TextStyle(color: Color(0xFF303030), fontSize: 24),
    ),
  ),
);

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    Brightness brightness = Brightness.light,
    ViewerHarness? harness,
    ViewerState Function(ViewerState state)? seed,
    bool load = true,
  }) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = (harness ?? ViewerHarness()).cubit();
    addTearDown(cubit.close);
    if (load) await cubit.load();
    if (seed != null) cubit.emit(seed(cubit.state));

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<ViewerCubit>.value(
          value: cubit,
          child: ViewerScreen(
            surfaceBuilder: goldenSurface,
            onBack: () {},
            onShare: () {},
            onPrint: () {},
            onEdit: () {},
          ),
        ),
      ),
    );

    // Bounded rather than `pumpAndSettle`: the loading state shows an
    // indefinite progress indicator, which never settles.
    await tester.pump();
    await tester.pump();
  }

  group('viewer goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, _phone);

      await expectLater(
        find.byType(ViewerScreen),
        matchesGoldenFile('goldens/viewer_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, _phone, brightness: Brightness.dark);

      await expectLater(
        find.byType(ViewerScreen),
        matchesGoldenFile('goldens/viewer_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(
        tester,
        _tablet,
        harness: ViewerHarness(
          recognisedText: 'INVOICE\nAcme Limited\nTotal due: 240.00',
        ),
      );

      await expectLater(
        find.byType(ViewerScreen),
        matchesGoldenFile('goldens/viewer_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(
        tester,
        _tablet,
        brightness: Brightness.dark,
        harness: ViewerHarness(
          recognisedText: 'INVOICE\nAcme Limited\nTotal due: 240.00',
        ),
      );

      await expectLater(
        find.byType(ViewerScreen),
        matchesGoldenFile('goldens/viewer_tablet_dark.png'),
      );
    });

    testWidgets('locked, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        harness: ViewerHarness(
          renderer: FakePdfRenderer(requiredPassword: 'secret'),
        ),
      );

      await expectLater(
        find.byType(ViewerScreen),
        matchesGoldenFile('goldens/viewer_locked_light.png'),
      );
    });

    testWidgets('locked, dark', (tester) async {
      await pumpAt(
        tester,
        _phone,
        brightness: Brightness.dark,
        harness: ViewerHarness(
          renderer: FakePdfRenderer(requiredPassword: 'secret'),
        ),
      );

      await expectLater(
        find.byType(ViewerScreen),
        matchesGoldenFile('goldens/viewer_locked_dark.png'),
      );
    });

    testWidgets('error, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        harness: ViewerHarness(
          renderer: FakePdfRenderer(failure: const Failure.corruptFile()),
        ),
      );

      await expectLater(
        find.byType(ViewerScreen),
        matchesGoldenFile('goldens/viewer_error_light.png'),
      );
    });
  });
}
