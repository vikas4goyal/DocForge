import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_status.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededCubit extends StorageLocationCubit {
  _SeededCubit(StorageLocationState seeded, {super.onMoveNow})
    : super(
        loadStatus: LoadStorageStatus(
          authority: StorageLocation.local,
          cloud: PlatformCloudContainerRepository(ScriptedICloudPlatform()),
        ),
      ) {
    emit(seeded);
  }

  int reloads = 0;

  @override
  Future<void> load() async => reloads++;
}

StorageLocationState _local(CloudAvailabilityStatus reason) =>
    StorageLocationState(
      status: StorageLocationStatus.localFallback,
      location: StorageLocation.local,
      cloudAvailability: CloudAvailability(reason),
    );

void main() {
  test('fixed key registry is unique and complete', () {
    expect(CloudStorageKeys.fixedValues, hasLength(14));
    expect(
      CloudStorageKeys.fixedValues,
      containsAll(<String>[
        'cloud_storage_status',
        'cloud_storage_move_now',
        'cloud_storage_migration_gate',
        'cloud_storage_continue_local',
        'cloud_storage_use_device',
        'cloud_storage_use_device_confirm',
      ]),
    );
    expect(
      CloudStorageKeys.fixedValues,
      isNot(
        anyOf(
          contains('cloud_storage_local_option'),
          contains('cloud_storage_icloud_option'),
          contains('cloud_storage_migration_confirm'),
          contains('cloud_storage_cancel'),
        ),
      ),
    );
  });

  test('every fallback reason has distinct user-facing copy', () {
    final reasons = CloudAvailabilityStatus.values
        .map(CloudStorageSemantics.fallbackReason)
        .toSet();
    expect(reasons, hasLength(CloudAvailabilityStatus.values.length));
    expect(
      CloudStorageSemantics.fallbackReason(CloudAvailabilityStatus.signedOut),
      'Sign in to iCloud in iOS Settings',
    );
  });

  Future<_SeededCubit> pump(
    WidgetTester tester,
    StorageLocationState state, {
    Future<void> Function()? onMoveNow,
  }) async {
    final cubit = _SeededCubit(state, onMoveNow: onMoveNow);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<StorageLocationCubit>.value(
          value: cubit,
          child: StorageLocationScreen(
            onBack: () {},
            onImportFolder: () async {},
          ),
        ),
      ),
    );
    await tester.pump();
    return cubit;
  }

  testWidgets('announces an active iCloud library without a chooser', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      const StorageLocationState(
        status: StorageLocationStatus.iCloudActive,
        location: StorageLocation.iCloud,
        cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
      ),
    );

    expect(find.byKey(CloudStorageKeys.screen), findsOneWidget);
    expect(find.byKey(CloudStorageKeys.status), findsOneWidget);
    expect(
      find.bySemanticsLabel(CloudStorageSemantics.storedInICloudDrive),
      findsOneWidget,
    );
    expect(find.byKey(CloudStorageKeys.moveNow), findsNothing);
    expect(find.byKey(CloudStorageKeys.importFolder), findsOneWidget);
    semantics.dispose();
  });

  for (final reason in [
    CloudAvailabilityStatus.signedOut,
    CloudAvailabilityStatus.disabled,
    CloudAvailabilityStatus.restricted,
    CloudAvailabilityStatus.unavailable,
  ]) {
    testWidgets('device fallback (${reason.name}) explains and disables '
        'move now', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, _local(reason));

      expect(
        find.bySemanticsLabel(
          '${CloudStorageSemantics.storedOnDevice}. '
          '${CloudStorageSemantics.fallbackReason(reason)}',
        ),
        findsOneWidget,
      );
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(CloudStorageKeys.moveNow),
      );
      expect(button.onPressed, isNull);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(CloudStorageSemantics.moveNow),
        ),
        isSemantics(label: CloudStorageSemantics.moveNow, isButton: true),
      );
      semantics.dispose();
    });
  }

  testWidgets('move now starts the move once iCloud is available', (
    tester,
  ) async {
    var moves = 0;
    await pump(
      tester,
      _local(CloudAvailabilityStatus.available),
      onMoveNow: () async => moves++,
    );

    await tester.tap(find.byKey(CloudStorageKeys.moveNow));
    await tester.pump();

    expect(moves, 1);
  });

  testWidgets('unavailable iCloud library offers a connection retry', (
    tester,
  ) async {
    final cubit = await pump(
      tester,
      const StorageLocationState(
        status: StorageLocationStatus.unavailable,
        location: StorageLocation.iCloud,
      ),
    );

    expect(find.byKey(CloudStorageKeys.unavailable), findsOneWidget);
    await tester.tap(find.byKey(CloudStorageKeys.retry));
    expect(cubit.reloads, 1);
  });

  testWidgets('a status failure offers retry', (tester) async {
    final cubit = await pump(
      tester,
      const StorageLocationState(
        status: StorageLocationStatus.failure,
        failure: Failure.storage(),
      ),
    );

    await tester.tap(find.byKey(CloudStorageKeys.retry));
    expect(cubit.reloads, 1);
  });

  testWidgets('loading shows progress only', (tester) async {
    await pump(tester, const StorageLocationState());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(CloudStorageKeys.status), findsNothing);
  });
}
