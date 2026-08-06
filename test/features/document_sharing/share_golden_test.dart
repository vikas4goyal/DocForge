/// Golden coverage for the platform-adaptive sharing workflow.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_sharing/presentation/share_keys.dart';
import 'package:doc_scanly/features/document_sharing/presentation/share_previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _phone = Size(390, 844);
const _tablet = Size(1024, 768);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = _phone,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> match(
    WidgetTester tester,
    Widget child,
    String fileName, {
    Size size = _phone,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pump(
      tester,
      child,
      size: size,
      brightness: brightness,
      textScale: textScale,
    );
    await expectLater(
      find.byKey(ShareKeys.sheet),
      matchesGoldenFile('goldens/$fileName'),
    );
  }

  testWidgets('phone options, light', (tester) async {
    await match(tester, sharePhoneLight(), 'share_phone_light.png');
  });

  testWidgets('tablet options, dark', (tester) async {
    await match(
      tester,
      shareTabletDark(),
      'share_tablet_dark.png',
      size: _tablet,
      brightness: Brightness.dark,
    );
  });

  testWidgets('long content at large text', (tester) async {
    await match(
      tester,
      shareLongContent(),
      'share_long_large_text.png',
      textScale: 2,
    );
  });

  testWidgets('content preparation', (tester) async {
    await match(tester, shareLoading(), 'share_preparing.png');
  });

  testWidgets('export completion and cancellation', (tester) async {
    await match(tester, shareExportDone(), 'share_export_done.png');
    await match(tester, shareCancelled(), 'share_export_cancelled.png');
  });

  testWidgets('provider and receiver failures', (tester) async {
    await match(tester, shareError(), 'share_error.png');
    await match(tester, shareNoReceivingApp(), 'share_no_receiving_app.png');
  });
}
