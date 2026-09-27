import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_state.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/cloud_migration_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededGateCubit extends CloudMigrationGateCubit {
  _SeededGateCubit(CloudMigrationGateState seeded)
    : super(
        runMigration:
            ({
              required source,
              required destination,
              onProgress,
              shouldCancel,
            }) async => const Result<void>.success(null),
      ) {
    emit(seeded);
  }

  int retries = 0;

  @override
  Future<void> retry() async => retries++;
}

void main() {
  late int finished;
  late int continuedLocally;

  setUp(() {
    finished = 0;
    continuedLocally = 0;
  });

  Future<_SeededGateCubit> pump(
    WidgetTester tester,
    CloudMigrationGateState state, {
    double textScale = 1,
  }) async {
    final cubit = _SeededGateCubit(state);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: BlocProvider<CloudMigrationGateCubit>.value(
            value: cubit,
            child: CloudMigrationGateScreen(
              onFinished: () => finished++,
              onContinueLocal: () => continuedLocally++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    addTearDown(cubit.close);
    return cubit;
  }

  testWidgets('announces the gate and its progress while copying', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      const CloudMigrationGateState(
        status: CloudMigrationGateStatus.copying,
        completedFiles: 3,
        totalFiles: 12,
      ),
    );

    expect(find.byKey(CloudStorageKeys.migrationGate), findsOneWidget);
    expect(
      find.bySemanticsLabel(CloudStorageSemantics.migrationGate),
      findsOneWidget,
    );
    expect(find.byKey(CloudStorageKeys.migrationProgress), findsOneWidget);
    expect(
      find.bySemanticsLabel('Library migration 25 percent'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(CloudStorageSemantics.continueLocal),
      findsOneWidget,
    );
    expect(find.byKey(CloudStorageKeys.migrationDone), findsNothing);
    expect(find.byKey(CloudStorageKeys.retry), findsNothing);
    semantics.dispose();
  });

  testWidgets('completion discloses iCloud and continues into the app', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      const CloudMigrationGateState(
        status: CloudMigrationGateStatus.completed,
        completedFiles: 2,
        totalFiles: 2,
      ),
    );

    expect(find.byKey(CloudStorageKeys.migrationDone), findsOneWidget);
    expect(
      find.bySemanticsLabel(CloudStorageSemantics.migrationDone),
      findsOneWidget,
    );
    expect(find.byKey(CloudStorageKeys.continueLocal), findsNothing);

    await tester.ensureVisible(find.byKey(CloudStorageKeys.migrationContinue));
    await tester.tap(find.byKey(CloudStorageKeys.migrationContinue));
    expect(finished, 1);
    semantics.dispose();
  });

  testWidgets('failure explains the reason and offers retry or device', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final cubit = await pump(
      tester,
      const CloudMigrationGateState(
        status: CloudMigrationGateStatus.failed,
        completedFiles: 1,
        totalFiles: 2,
        failure: Failure.storageFull(),
      ),
    );

    expect(find.text('Your iCloud storage is full'), findsOneWidget);
    expect(
      find.bySemanticsLabel(CloudStorageSemantics.retryMigration),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(CloudStorageKeys.retry));
    await tester.tap(find.byKey(CloudStorageKeys.retry));
    expect(cubit.retries, 1);

    await tester.ensureVisible(find.byKey(CloudStorageKeys.continueLocal));
    await tester.tap(find.byKey(CloudStorageKeys.continueLocal));
    expect(continuedLocally, 1);
    semantics.dispose();
  });

  testWidgets('continuing while running leaves once the move is cancelled', (
    tester,
  ) async {
    await pump(
      tester,
      const CloudMigrationGateState(
        status: CloudMigrationGateStatus.verifying,
        completedFiles: 1,
        totalFiles: 2,
      ),
    );

    await tester.ensureVisible(find.byKey(CloudStorageKeys.continueLocal));
    await tester.tap(find.byKey(CloudStorageKeys.continueLocal));
    await tester.pump();

    expect(continuedLocally, 1);
  });

  for (final failure in <Failure?>[
    const Failure.corruptFile(),
    const Failure.cancelled(),
    const Failure.storage(debugDetail: 'icloud unavailable'),
    null,
  ]) {
    testWidgets('failure copy for ${failure.runtimeType}', (tester) async {
      await pump(
        tester,
        CloudMigrationGateState(
          status: CloudMigrationGateStatus.failed,
          failure: failure,
        ),
      );
      expect(find.byKey(CloudStorageKeys.retry), findsOneWidget);
    });
  }

  testWidgets('long content scrolls without overflow at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      const CloudMigrationGateState(
        status: CloudMigrationGateStatus.failed,
        failure: Failure.storageFull(),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(CloudStorageKeys.continueLocal),
      100,
    );
    expect(find.byKey(CloudStorageKeys.continueLocal), findsOneWidget);
  });
}
