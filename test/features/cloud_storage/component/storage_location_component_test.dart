/// Tier 2 — the storage status screen with its real Cubit and real use case;
/// only the native iCloud edge is scripted.
library;

import 'dart:async';

import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_status.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ScriptedICloudPlatform platform;
  late int recompositions;

  setUp(() {
    platform = ScriptedICloudPlatform();
    recompositions = 0;
  });

  tearDown(() => platform.dispose());

  Future<void> pumpScreen(
    WidgetTester tester,
    StorageLocation authority,
  ) async {
    final cubit = StorageLocationCubit(
      loadStatus: LoadStorageStatus(
        authority: authority,
        cloud: PlatformCloudContainerRepository(platform),
      ),
      onMoveNow: () async => recompositions++,
    );
    addTearDown(cubit.close);
    unawaited(cubit.load());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: StorageLocationScreen(onBack: () {}),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a signed-out device explains why iCloud is not used', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    platform.availabilityValue = 'signedOut';
    await pumpScreen(tester, StorageLocation.local);

    expect(
      find.bySemanticsLabel(
        '${CloudStorageSemantics.storedOnDevice}. '
        '${CloudStorageSemantics.fallbackReason(CloudAvailabilityStatus.signedOut)}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(CloudStorageKeys.moveNow));
    expect(recompositions, 0);
    semantics.dispose();
  });

  testWidgets('iCloud appearing during the session enables move now', (
    tester,
  ) async {
    await pumpScreen(tester, StorageLocation.local);

    await tester.tap(find.byKey(CloudStorageKeys.moveNow));
    await tester.pump();

    expect(recompositions, 1);
  });

  testWidgets('an iCloud session reports iCloud Drive as active', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, StorageLocation.iCloud);

    expect(
      find.bySemanticsLabel(CloudStorageSemantics.storedInICloudDrive),
      findsOneWidget,
    );
    expect(find.byKey(CloudStorageKeys.moveNow), findsNothing);
    semantics.dispose();
  });

  testWidgets('an iCloud session that loses iCloud retries the connection', (
    tester,
  ) async {
    platform.availabilityValue = 'disabled';
    await pumpScreen(tester, StorageLocation.iCloud);
    expect(find.byKey(CloudStorageKeys.unavailable), findsOneWidget);

    platform.availabilityValue = 'available';
    await tester.tap(find.byKey(CloudStorageKeys.retry));
    await tester.pump();

    expect(find.byKey(CloudStorageKeys.unavailable), findsNothing);
    expect(find.byKey(CloudStorageKeys.status), findsOneWidget);
  });
}
