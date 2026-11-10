/// Tier 2 — the migration gate with its real Cubit and the real migration use
/// case over real temporary folders; only the native iCloud edge is scripted.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/cloud_migration_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// An iCloud store that reports a full quota while [full] is set.
class _QuotaStore extends FilesystemPublicFileStore {
  _QuotaStore(super.rootDirectory) : super.atRoot();

  bool full = true;

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) async =>
      full
      ? const Result<String>.failure(Failure.storageFull(debugDetail: 'quota'))
      : super.writeFile(path, sourcePath);
}

void main() {
  late Directory scratch;
  late FilesystemPublicFileStore local;
  late _QuotaStore iCloud;
  late ScriptedICloudPlatform platform;
  late InMemoryPreferenceStore preferences;
  late int finished;
  late int continuedLocally;

  setUp(() async {
    scratch = await Directory.systemTemp.createTemp('docscanly_gate_');
    local = FilesystemPublicFileStore.atRoot(
      Directory('${scratch.path}/local'),
    );
    iCloud = _QuotaStore(Directory('${scratch.path}/cloud'))..full = false;
    await local.initialise();
    await iCloud.initialise();
    platform = ScriptedICloudPlatform(rootPath: iCloud.rootDirectory.path);
    preferences = InMemoryPreferenceStore({
      'settings.storage.location.v1': 'local',
    });
    finished = 0;
    continuedLocally = 0;
  });

  tearDown(() async {
    await platform.dispose();
    await scratch.delete(recursive: true);
  });

  Future<void> seed(
    PublicFileStoreWriter store,
    String relative,
    String text,
  ) => store(relative, text);

  PublicFileStoreWriter writerFor(FilesystemPublicFileStore store) =>
      (relative, text) async {
        final source = File('${scratch.path}/seed-${relative.hashCode}')
          ..writeAsStringSync(text);
        await store.writeFile(LibraryPath.parse(relative), source.path);
        source.deleteSync();
      };

  Future<CloudMigrationGateCubit> pumpGate(WidgetTester tester) async {
    final migrate = MigrateLibraryLocation(
      locations: StorageLocationPreferences(preferences),
      stores: FixedLibraryStoreResolver(local: local, iCloud: iCloud),
      cloud: PlatformCloudContainerRepository(platform),
    );
    final cubit = CloudMigrationGateCubit(runMigration: migrate.call);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: CloudMigrationGateScreen(
            onFinished: () => finished++,
            onContinueLocal: () => continuedLocally++,
          ),
        ),
      ),
    );
    return cubit;
  }

  File cloudFile(String relative) =>
      File('${iCloud.rootDirectory.path}/$relative');
  File localFile(String relative) =>
      File('${local.rootDirectory.path}/$relative');

  testWidgets('moves the device library and continues into iCloud', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seed(writerFor(local), 'Tax/2026.pdf', 'tax');
      await seed(writerFor(local), 'Receipt.pdf', 'receipt');
    });
    final cubit = await pumpGate(tester);

    await tester.runAsync(cubit.start);
    await tester.pump();

    expect(find.byKey(CloudStorageKeys.migrationDone), findsOneWidget);
    expect(preferences.values['settings.storage.location.v1'], 'icloud');
    expect(cloudFile('Tax/2026.pdf').readAsStringSync(), 'tax');
    expect(localFile('Receipt.pdf').existsSync(), isFalse);
    expect(platform.marker, isNotNull);

    await tester.ensureVisible(find.byKey(CloudStorageKeys.migrationContinue));
    await tester.tap(find.byKey(CloudStorageKeys.migrationContinue));
    expect(finished, 1);
  });

  testWidgets('a full iCloud keeps the device, then retry succeeds', (
    tester,
  ) async {
    await tester.runAsync(
      () => seed(writerFor(local), 'Receipt.pdf', 'receipt'),
    );
    iCloud.full = true;
    final cubit = await pumpGate(tester);

    await tester.runAsync(cubit.start);
    await tester.pump();

    expect(find.text('Your iCloud storage is full'), findsOneWidget);
    expect(preferences.values['settings.storage.location.v1'], 'local');
    expect(localFile('Receipt.pdf').existsSync(), isTrue);

    expect(find.byKey(CloudStorageKeys.retry), findsOneWidget);
    iCloud.full = false;
    // The button's wiring is covered in Tier 1; the retry itself performs
    // real file I/O, so it runs outside the widget test's fake clock.
    await tester.runAsync(cubit.retry);
    await tester.pump();

    expect(find.byKey(CloudStorageKeys.migrationDone), findsOneWidget);
    expect(preferences.values['settings.storage.location.v1'], 'icloud');
  });

  testWidgets('a failed move can continue on this device', (tester) async {
    await tester.runAsync(
      () => seed(writerFor(local), 'Receipt.pdf', 'receipt'),
    );
    iCloud.full = true;
    final cubit = await pumpGate(tester);

    await tester.runAsync(cubit.start);
    await tester.pump();
    await tester.ensureVisible(find.byKey(CloudStorageKeys.continueLocal));
    await tester.tap(find.byKey(CloudStorageKeys.continueLocal));

    expect(continuedLocally, 1);
    expect(preferences.values['settings.storage.location.v1'], 'local');
  });

  testWidgets('merging keeps a differing iCloud file beside the device one', (
    tester,
  ) async {
    platform.marker = const {
      'schemaVersion': 1,
      'libraryIdentifier': 'docscanly-library',
    };
    await tester.runAsync(() async {
      await seed(writerFor(iCloud), 'Scan.pdf', 'from another iPhone');
      await seed(writerFor(local), 'Scan.pdf', 'from this iPhone');
    });
    final cubit = await pumpGate(tester);

    await tester.runAsync(cubit.start);
    await tester.pump();

    expect(find.byKey(CloudStorageKeys.migrationDone), findsOneWidget);
    expect(cloudFile('Scan.pdf').readAsStringSync(), 'from another iPhone');
    expect(
      cloudFile('Scan (Conflict device).pdf').readAsStringSync(),
      'from this iPhone',
    );
  });
}

/// Writes [text] at [relative] into a store under test.
typedef PublicFileStoreWriter =
    Future<void> Function(String relative, String text);
