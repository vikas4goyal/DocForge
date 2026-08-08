/// Tier 2 — Viewer over its real Cubit and viewer use cases.
library;

import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_scanly/features/document_viewer/presentation/screens/viewer_screen.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';
import '../viewer_test_support.dart';

Widget _surface(
  BuildContext context, {
  required String filePath,
  required String? password,
  required int page,
  required ValueChanged<int> onPageChanged,
}) => const ColoredBox(key: ViewerKeys.pageView, color: Colors.white);

void main() {
  late ViewerHarness harness;
  late ViewerCubit cubit;
  late int details;
  late int backs;

  setUp(() {
    harness = ViewerHarness();
    cubit = harness.cubit();
    details = 0;
    backs = 0;
  });

  tearDown(() => cubit.close());

  Future<void> pumpViewer(
    WidgetTester tester, {
    Future<void> Function()? onShowDetails,
  }) async {
    await pumpComponent(
      tester,
      ViewerScreen(
        surfaceBuilder: _surface,
        onBack: () => backs++,
        onShare: () {},
        onShowDetails: onShowDetails ?? () async => details++,
        onAction: (_) {},
      ),
      providers: [BlocProvider<ViewerCubit>.value(value: cubit)],
    );
    await cubit.load();
    await settleComponent(tester);
  }

  testWidgets('opens and persists favourite through the real state machine', (
    tester,
  ) async {
    await pumpViewer(tester);

    await tester.tap(find.byKey(ViewerKeys.favouriteButton));
    await settleComponent(tester);

    expect(harness.documents.document?.isFavourite, isTrue);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expectVisible(ViewerKeys.pageView);
  });

  testWidgets('Details callback refreshes metadata without reopening PDF', (
    tester,
  ) async {
    await pumpViewer(
      tester,
      onShowDetails: () async {
        details++;
        harness.documents.document = harness.documents.document!.copyWith(
          title: 'Renamed in details',
        );
        await cubit.refreshMetadata();
      },
    );
    cubit.goToPage(2);

    await tester.tap(find.byKey(ViewerKeys.actionsMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ViewerKeys.documentDetailsButton));
    await settleComponent(tester);

    expect(details, 1);
    expect(find.text('Renamed in details'), findsOneWidget);
    expect(cubit.state.page, 2);
    expect(harness.renderer.opened, hasLength(1));
  });

  testWidgets('a document deleted in Details closes Viewer once', (
    tester,
  ) async {
    await pumpViewer(
      tester,
      onShowDetails: () async {
        harness.documents.document = null;
        await cubit.refreshMetadata();
      },
    );

    await tester.tap(find.byKey(ViewerKeys.actionsMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ViewerKeys.documentDetailsButton));
    await settleComponent(tester);

    expect(backs, 1);
  });
}
