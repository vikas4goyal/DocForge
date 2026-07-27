/// Golden tests for the document preview and save screen.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
///
/// Page thumbnails render their placeholder rather than a photograph. A golden
/// of a real capture would be a golden of whatever image happened to be on the
/// machine, and would fail in CI where no such file exists.
@Tags(['golden'])
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_cubit.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_state.dart';
import 'package:doc_forge/features/pdf_generation/presentation/screens/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_support.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

void main() {
  List<PageRef> pages(int count) => [
    for (var index = 0; index < count; index++)
      PageRef(
        id: PageId('golden-page-$index'),
        imagePath: '/golden/$index.jpg',
      ),
  ];

  PdfGenerationCubit cubitFor(int pageCount) => PdfGenerationCubit(
    pages(pageCount),
    SaveDocument(
      BuildSearchablePdf(FakePdfComposer(), (_) async => const {}),
      RecordingDocumentWriter(),
      FixedClock(DateTime.utc(2026, 3, 14, 9, 30)),
      SequentialIdGenerator(prefix: 'doc'),
      (id) => '/documents/${id.value}.pdf',
      (path) async {},
    ),
    GenerateDocumentName(
      FixedClock(DateTime(2026, 3, 14, 9, 30)),
      StubDocumentReader(),
    ),
    source: PageSource.camera,
    pattern: NamingPattern.dateOnly,
  );

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    Brightness brightness = Brightness.light,
    int pageCount = 4,
    PdfGenerationState Function(PdfGenerationState state)? seed,
  }) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = cubitFor(pageCount);
    addTearDown(cubit.close);
    await cubit.load();
    if (seed != null) cubit.emit(seed(cubit.state));

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<PdfGenerationCubit>.value(
          value: cubit,
          child: PdfPreviewScreen(onSaved: (_) {}, onBack: () {}),
        ),
      ),
    );

    // Bounded rather than `pumpAndSettle`: the generating state shows an
    // indefinite progress bar, which never settles.
    await tester.pump();
    await tester.pump();
  }

  group('document preview goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, _phone);

      await expectLater(
        find.byType(PdfPreviewScreen),
        matchesGoldenFile('goldens/pdf_preview_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, _phone, brightness: Brightness.dark);

      await expectLater(
        find.byType(PdfPreviewScreen),
        matchesGoldenFile('goldens/pdf_preview_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, _tablet, pageCount: 9);

      await expectLater(
        find.byType(PdfPreviewScreen),
        matchesGoldenFile('goldens/pdf_preview_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, _tablet, brightness: Brightness.dark, pageCount: 9);

      await expectLater(
        find.byType(PdfPreviewScreen),
        matchesGoldenFile('goldens/pdf_preview_tablet_dark.png'),
      );
    });

    testWidgets('generating, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        seed: (state) => state.copyWith(status: PdfGenerationStatus.generating),
      );

      await expectLater(
        find.byType(PdfPreviewScreen),
        matchesGoldenFile('goldens/pdf_preview_generating_light.png'),
      );
    });

    testWidgets('error, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        seed: (state) => state.copyWith(
          status: PdfGenerationStatus.failure,
          failure: const Failure.storageFull(),
        ),
      );

      await expectLater(
        find.byType(PdfPreviewScreen),
        matchesGoldenFile('goldens/pdf_preview_error_light.png'),
      );
    });

    testWidgets('error, dark', (tester) async {
      await pumpAt(
        tester,
        _phone,
        brightness: Brightness.dark,
        seed: (state) => state.copyWith(
          status: PdfGenerationStatus.failure,
          failure: const Failure.storageFull(),
        ),
      );

      await expectLater(
        find.byType(PdfPreviewScreen),
        matchesGoldenFile('goldens/pdf_preview_error_dark.png'),
      );
    });
  });
}
