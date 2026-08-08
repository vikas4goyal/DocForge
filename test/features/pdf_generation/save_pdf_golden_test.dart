@Tags(<String>['golden'])
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/save_pdf_previews.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/screens/save_pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _phone = Size(390, 844);
const _tablet = Size(1024, 1366);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = _phone,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        builder: (context, materialChild) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: materialChild!,
        ),
        home: child,
      ),
    );
    await tester.pump();
  }

  testWidgets('Save PDF phone light', (tester) async {
    await pump(tester, savePdfDefault());

    await expectLater(
      find.byType(SavePdfScreen),
      matchesGoldenFile('goldens/save_pdf_phone_light.png'),
    );
  });

  testWidgets('Save PDF tablet dark with overrides', (tester) async {
    await pump(
      tester,
      savePdfOverrides(),
      size: _tablet,
      brightness: Brightness.dark,
    );

    await expectLater(
      find.byType(SavePdfScreen),
      matchesGoldenFile('goldens/save_pdf_overrides_tablet_dark.png'),
    );
  });

  testWidgets('Save PDF protected', (tester) async {
    await pump(tester, savePdfProtected());

    await expectLater(
      find.byType(SavePdfScreen),
      matchesGoldenFile('goldens/save_pdf_protected_phone_light.png'),
    );
  });

  testWidgets('Save PDF calculating', (tester) async {
    await pump(tester, savePdfCalculating());

    await expectLater(
      find.byType(SavePdfScreen),
      matchesGoldenFile('goldens/save_pdf_calculating_phone_light.png'),
    );
  });

  testWidgets('Save PDF error at maximum text scale', (tester) async {
    await pump(tester, savePdfError(), textScale: 2);

    await expectLater(
      find.byType(SavePdfScreen),
      matchesGoldenFile('goldens/save_pdf_error_large_text.png'),
    );
  });

  testWidgets('temporary preview tablet dark', (tester) async {
    await pump(
      tester,
      temporaryPdfPreview(),
      size: _tablet,
      brightness: Brightness.dark,
    );

    await expectLater(
      find.byType(PdfTemporaryPreviewScreen),
      matchesGoldenFile('goldens/pdf_temporary_preview_tablet_dark.png'),
    );
  });
}
