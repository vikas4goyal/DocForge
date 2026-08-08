import 'dart:async';

import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/app/router/route_gates.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
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
        viewer: (_, id) => _ViewerMarker(id: id),
        compressPdf: (_, id) => _CompressMarker(id: id),
      ),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  test('typed entry and completion values retain document identity', () {
    const id = DocumentId('invoice-7');
    const route = CompressPdfRoute(documentId: id);
    const completion = CompressPdfCompletion(
      kind: CompressPdfCompletionKind.openCopy,
      documentId: DocumentId('copy-8'),
    );

    expect(route.location, '/documents/invoice-7/compress');
    expect(completion.kind, CompressPdfCompletionKind.openCopy);
    expect(completion.documentId, const DocumentId('copy-8'));
  });

  testWidgets('Viewer opens Compress directly with its document id', (
    tester,
  ) async {
    await pump(tester);
    unawaited(router.push<void>(AppRoutes.documentView(const DocumentId('a'))));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('viewer_open_compress')));
    await tester.pumpAndSettle();

    expect(find.text('compress:a'), findsOneWidget);
  });

  testWidgets('100% warning can adjust without leaving Compress', (
    tester,
  ) async {
    await pump(tester);
    unawaited(
      router.push<void>(
        const CompressPdfRoute(documentId: DocumentId('a')).location,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compress_all_100')));
    await tester.pumpAndSettle();
    expect(find.text('100% warning'), findsOneWidget);

    await tester.tap(find.byKey(const Key('compress_adjust')));
    await tester.pumpAndSettle();
    expect(find.text('compress:a'), findsOneWidget);
    expect(find.text('100% warning'), findsNothing);
  });

  testWidgets('destination dismissal and job cancellation stay on Compress', (
    tester,
  ) async {
    await pump(tester);
    unawaited(
      router.push<void>(
        const CompressPdfRoute(documentId: DocumentId('a')).location,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compress_choose_destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('compress_destination_dismiss')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('compress_cancel_job')));
    await tester.pumpAndSettle();

    expect(find.text('compress:a'), findsOneWidget);
  });

  testWidgets('copy completion opens the copy and returns only once', (
    tester,
  ) async {
    await pump(tester);
    const route = CompressPdfRoute(documentId: DocumentId('a'));
    final pending = router.push<CompressPdfCompletion>(route.location);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compress_complete_copy')));
    await tester.pumpAndSettle();
    final completion = await pending;
    expect(completion?.kind, CompressPdfCompletionKind.openCopy);
    expect(completion?.documentId, const DocumentId('copy-a'));

    unawaited(
      router.push<void>(AppRoutes.documentView(completion!.documentId)),
    );
    await tester.pumpAndSettle();
    expect(find.text('viewer:copy-a'), findsOneWidget);
  });

  testWidgets('overwrite completion tells Viewer to refresh original', (
    tester,
  ) async {
    await pump(tester);
    const route = CompressPdfRoute(documentId: DocumentId('a'));
    final pending = router.push<CompressPdfCompletion>(route.location);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compress_complete_overwrite')));
    await tester.pumpAndSettle();

    final completion = await pending;
    expect(completion?.kind, CompressPdfCompletionKind.refreshOriginal);
    expect(completion?.documentId, const DocumentId('a'));
    expect(find.text('home'), findsOneWidget);
  });
}

class _ViewerMarker extends StatelessWidget {
  const _ViewerMarker({required this.id});

  final DocumentId id;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text('viewer:${id.value}'),
        TextButton(
          key: const Key('viewer_open_compress'),
          onPressed: () {
            final route = CompressPdfRoute(documentId: id);
            context.push<void>(route.location);
          },
          child: const Text('Compress'),
        ),
      ],
    ),
  );
}

class _CompressMarker extends StatelessWidget {
  const _CompressMarker({required this.id});

  final DocumentId id;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text('compress:${id.value}'),
        TextButton(
          key: const Key('compress_all_100'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('100% warning'),
              actions: <Widget>[
                TextButton(
                  key: const Key('compress_adjust'),
                  onPressed: dialogContext.pop,
                  child: const Text('Adjust'),
                ),
                TextButton(
                  key: const Key('compress_continue_100'),
                  onPressed: dialogContext.pop,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
          child: const Text('Save at 100%'),
        ),
        TextButton(
          key: const Key('compress_choose_destination'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Choose destination'),
              actions: <Widget>[
                TextButton(
                  key: const Key('compress_destination_dismiss'),
                  onPressed: dialogContext.pop,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
          child: const Text('Choose destination'),
        ),
        TextButton(
          key: const Key('compress_cancel_job'),
          onPressed: () {},
          child: const Text('Cancel job'),
        ),
        TextButton(
          key: const Key('compress_complete_copy'),
          onPressed: () => context.pop(
            const CompressPdfCompletion(
              kind: CompressPdfCompletionKind.openCopy,
              documentId: DocumentId('copy-a'),
            ),
          ),
          child: const Text('Complete copy'),
        ),
        TextButton(
          key: const Key('compress_complete_overwrite'),
          onPressed: () => context.pop(
            CompressPdfCompletion(
              kind: CompressPdfCompletionKind.refreshOriginal,
              documentId: id,
            ),
          ),
          child: const Text('Complete overwrite'),
        ),
      ],
    ),
  );
}
