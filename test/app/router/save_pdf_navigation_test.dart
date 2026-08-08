import 'dart:async';

import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/app/router/route_gates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/marker_screens.dart';

void main() {
  late GoRouter router;

  Future<void> pump(WidgetTester tester) async {
    router = createAppRouter(
      guard: RouteGuard(
        lockGate: FakeAppLockGate(),
        onboardingGate: FakeOnboardingGate(),
      ),
      screens: markerScreens(
        savePdf: (_, handle) => _SaveMarker(sessionHandle: handle),
        pdfTemporaryPreview: (_, handle) =>
            _PreviewMarker(candidateHandle: handle),
      ),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  test('typed destinations validate handles and use stable locations', () {
    expect(
      SavePdfRoute(sessionHandle: 'session-7').location,
      AppRoutes.savePdf,
    );
    expect(
      PdfTemporaryPreviewRoute(candidateHandle: 'candidate-4').location,
      AppRoutes.pdfTemporaryPreview,
    );
    expect(() => SavePdfRoute(sessionHandle: ''), throwsArgumentError);
    expect(
      () => PdfTemporaryPreviewRoute(candidateHandle: ''),
      throwsArgumentError,
    );
  });

  testWidgets('Save entry receives its typed session handle', (tester) async {
    await pump(tester);
    final route = SavePdfRoute(sessionHandle: 'session-7');

    unawaited(router.push<void>(route.location, extra: route));
    await tester.pumpAndSettle();

    expect(find.text('save:session-7'), findsOneWidget);
  });

  testWidgets('temporary preview closes back to unchanged Save route', (
    tester,
  ) async {
    await pump(tester);
    final save = SavePdfRoute(sessionHandle: 'session-7');
    unawaited(router.push<void>(save.location, extra: save));
    await tester.pumpAndSettle();
    final preview = PdfTemporaryPreviewRoute(candidateHandle: 'candidate-4');

    unawaited(router.push<void>(preview.location, extra: preview));
    await tester.pumpAndSettle();
    expect(find.text('preview:candidate-4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('preview_close')));
    await tester.pumpAndSettle();
    expect(find.text('save:session-7'), findsOneWidget);
  });

  testWidgets('missing typed extras show an invalid-handle recovery state', (
    tester,
  ) async {
    await pump(tester);

    unawaited(router.push<void>(AppRoutes.pdfTemporaryPreview));
    await tester.pumpAndSettle();

    expect(find.text('That PDF is no longer available'), findsOneWidget);
  });

  testWidgets('cancelled work stays on Save and completion returns once', (
    tester,
  ) async {
    await pump(tester);
    final route = SavePdfRoute(sessionHandle: 'session-7');
    final result = router.push<String>(route.location, extra: route);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save_cancel_job')));
    await tester.pumpAndSettle();
    expect(find.text('save:session-7'), findsOneWidget);

    await tester.tap(find.byKey(const Key('save_complete')));
    await tester.pumpAndSettle();
    expect(await result, 'folder-2');
    expect(find.text('home'), findsOneWidget);
  });
}

class _SaveMarker extends StatelessWidget {
  const _SaveMarker({required this.sessionHandle});

  final String sessionHandle;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text('save:$sessionHandle'),
        TextButton(
          key: const Key('save_cancel_job'),
          onPressed: () {},
          child: const Text('Cancel job'),
        ),
        TextButton(
          key: const Key('save_complete'),
          onPressed: () => context.pop('folder-2'),
          child: const Text('Complete'),
        ),
      ],
    ),
  );
}

class _PreviewMarker extends StatelessWidget {
  const _PreviewMarker({required this.candidateHandle});

  final String candidateHandle;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text('preview:$candidateHandle'),
        TextButton(
          key: const Key('preview_close'),
          onPressed: context.pop,
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
