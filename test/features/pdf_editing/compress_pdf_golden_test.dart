@Tags(<String>['golden'])
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/compress_pdf_previews.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/screens/compress_pdf_screen.dart';
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

  testWidgets('Compress PDF phone light', (tester) async {
    await pump(tester, compressPdfDefault());
    await expectLater(
      find.byType(CompressPdfScreen),
      matchesGoldenFile('goldens/compress_pdf_phone_light.png'),
    );
  });

  testWidgets('Compress PDF mixed overrides tablet dark', (tester) async {
    await pump(
      tester,
      compressPdfMixed(),
      size: _tablet,
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(CompressPdfScreen),
      matchesGoldenFile('goldens/compress_pdf_mixed_tablet_dark.png'),
    );
  });

  testWidgets('Compress PDF all 100', (tester) async {
    await pump(tester, compressPdfFull());
    await expectLater(
      find.byType(CompressPdfScreen),
      matchesGoldenFile('goldens/compress_pdf_all_100_phone_light.png'),
    );
  });

  testWidgets('Compress PDF calculating', (tester) async {
    await pump(tester, compressPdfCalculating());
    await expectLater(
      find.byType(CompressPdfScreen),
      matchesGoldenFile('goldens/compress_pdf_calculating_phone_light.png'),
    );
  });

  testWidgets('Compress PDF failure at maximum text scale', (tester) async {
    await pump(tester, compressPdfError(), textScale: 2);
    await expectLater(
      find.byType(CompressPdfScreen),
      matchesGoldenFile('goldens/compress_pdf_error_large_text.png'),
    );
  });

  testWidgets('Compress PDF 100 warning dialog', (tester) async {
    await pump(tester, compressPassThroughDialog());
    await expectLater(
      find.byType(CompressionDialogPreview),
      matchesGoldenFile('goldens/compress_pdf_pass_through_dialog.png'),
    );
  });

  testWidgets('Compress PDF destination dialog tablet dark', (tester) async {
    await pump(
      tester,
      compressDestinationDialog(),
      size: _tablet,
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(CompressionDialogPreview),
      matchesGoldenFile('goldens/compress_pdf_destination_dialog_dark.png'),
    );
  });

  testWidgets('Compress PDF no-benefit dialog', (tester) async {
    await pump(tester, compressNoBenefitDialog());
    await expectLater(
      find.byType(CompressionDialogPreview),
      matchesGoldenFile('goldens/compress_pdf_no_benefit_dialog.png'),
    );
  });
}
