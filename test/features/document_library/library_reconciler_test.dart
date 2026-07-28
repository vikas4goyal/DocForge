import 'package:doc_forge/features/document_library/presentation/widgets/library_reconciler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int runs;
  late int reconciled;

  Widget build() => MaterialApp(
    home: LibraryReconciler(
      reconcile: () async => runs++,
      onReconciled: () => reconciled++,
      child: const Text('library'),
    ),
  );

  setUp(() {
    runs = 0;
    reconciled = 0;
  });

  /// Delivers a lifecycle transition the way the framework does.
  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  testWidgets('reconciles once after the first frame', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(runs, 1);
    expect(reconciled, 1);
  });

  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(find.text('library'), findsOneWidget);
  });

  testWidgets('reconciles again when the application resumes', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    await resume(tester);

    // The user most often changes the folder by leaving DocForge to do it, so
    // resume is the moment the change has to be noticed.
    expect(runs, 2);
  });

  testWidgets('does not reconcile when merely paused', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(runs, 1);
  });

  testWidgets('stops observing once disposed', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: Text('gone')));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // A reconcile firing after disposal would write through a Cubit that is
    // no longer there.
    expect(runs, 1);
  });

  testWidgets('a reconcile that outlives the widget reports nothing', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryReconciler(
          reconcile: () async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            completed++;
          },
          onReconciled: () => reconciled++,
          child: const Text('library'),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: Text('gone')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(completed, 1);
    expect(reconciled, 0);
  });

  testWidgets('survives a reconcile with no callback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryReconciler(
          reconcile: () async => runs++,
          child: const Text('library'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(runs, 1);
  });
}
