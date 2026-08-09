/// Golden tests for the enhancement screen.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
///
/// The page preview renders its placeholder rather than a photograph. A golden
/// of a real capture would be a golden of whatever image happened to be on the
/// machine, and would fail in CI where no such file exists.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/page_renderer.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/previews/fakes/fake_page_renderer.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/screens/enhancement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

/// Fixture pages, deterministic down to their identifiers.
/// The page every golden renders.
const _page = PageDraft(
  id: PageId('golden-page'),
  originalImagePath: '/golden/0.jpg',
);

/// A renderer that touches no filesystem, so goldens stay byte-stable.
PageRenderer _goldenRenderer() => const FakePageRenderer();

void main() {
  Widget host(EnhancementState state, Brightness brightness) {
    final cubit = EnhancementCubit(state.page, _goldenRenderer());
    addTearDown(cubit.close);

    return MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: BlocProvider<EnhancementCubit>.value(
        value: _seeded(cubit, state),
        child: EnhancementScreen(onDone: (_) {}),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  final base = EnhancementState.initial(_page);

  group('enhancement screen goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, host(base, Brightness.light), _phone);

      await expectLater(
        find.byType(EnhancementScreen),
        matchesGoldenFile('goldens/enhance_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, host(base, Brightness.dark), _phone);

      await expectLater(
        find.byType(EnhancementScreen),
        matchesGoldenFile('goldens/enhance_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, host(base, Brightness.light), _tablet);

      await expectLater(
        find.byType(EnhancementScreen),
        matchesGoldenFile('goldens/enhance_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, host(base, Brightness.dark), _tablet);

      await expectLater(
        find.byType(EnhancementScreen),
        matchesGoldenFile('goldens/enhance_tablet_dark.png'),
      );
    });

    testWidgets('adjustments applied, light', (tester) async {
      final adjusted = base.copyWith(
        settings: const EnhancementSettings(
          filter: EnhancementFilter.magicColour,
          brightness: 0.4,
          contrast: -0.25,
          sharpen: 0.6,
          shadowRemoval: true,
        ),
      );

      await pumpAt(tester, host(adjusted, Brightness.light), _phone);

      await expectLater(
        find.byType(EnhancementScreen),
        matchesGoldenFile('goldens/enhance_adjusted_light.png'),
      );
    });

    testWidgets('error, light', (tester) async {
      final failed = base.copyWith(
        status: EnhancementStatus.failure,
        failure: const Failure.storageFull(),
      );

      await pumpAt(tester, host(failed, Brightness.light), _phone);

      await expectLater(
        find.byType(EnhancementScreen),
        matchesGoldenFile('goldens/enhance_error_light.png'),
      );
    });

    testWidgets('error, dark', (tester) async {
      final failed = base.copyWith(
        status: EnhancementStatus.failure,
        failure: const Failure.storageFull(),
      );

      await pumpAt(tester, host(failed, Brightness.dark), _phone);

      await expectLater(
        find.byType(EnhancementScreen),
        matchesGoldenFile('goldens/enhance_error_dark.png'),
      );
    });
  });
}

/// Puts [cubit] into [state] without running any of its behaviour.
///
/// `emit` is protected, and the states these goldens need — a batch in flight,
/// a failure — cannot be reached through the public API inside a single frame,
/// because the inline worker completes before the tree rebuilds.
EnhancementCubit _seeded(EnhancementCubit cubit, EnhancementState state) {
  cubit.emit(state);
  return cubit;
}
