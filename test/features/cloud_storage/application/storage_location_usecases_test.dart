import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/adopt_device_library.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/ensure_document_downloaded.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/import_existing_cloud_folder.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadStorageLocation', () {
    late Directory scratch;
    late FilesystemPublicFileStore localStore;

    setUp(() async {
      scratch = await Directory.systemTemp.createTemp('load_location');
      localStore = FilesystemPublicFileStore.atRoot(
        Directory('${scratch.path}/local'),
      );
    });

    tearDown(() => scratch.delete(recursive: true));

    LoadStorageLocation load(
      PreferenceStore store,
      ScriptedICloudPlatform platform,
    ) => LoadStorageLocation(
      locations: StorageLocationPreferences(store),
      cloud: PlatformCloudContainerRepository(platform),
      localStore: localStore,
    );

    test('fresh install with iCloud adopts it and writes the marker', () async {
      final store = InMemoryPreferenceStore();
      final platform = ScriptedICloudPlatform();

      final loaded = (await load(store, platform)()).valueOrNull!;

      expect(
        loaded.decision,
        const StorageDecision.useICloud(writeMarker: true),
      );
      expect(loaded.location, StorageLocation.iCloud);
      expect(store.values['settings.storage.location.v1'], 'icloud');
      expect(platform.marker, isNotNull);
      await platform.dispose();
    });

    test(
      'stored local with an empty device switches straight to iCloud',
      () async {
        final store = InMemoryPreferenceStore({
          'settings.storage.location.v1': 'local',
        });
        final platform = _establishedPlatform();

        final loaded = (await load(store, platform)()).valueOrNull!;

        expect(loaded.decision, const StorageDecision.useICloud());
        expect(store.values['settings.storage.location.v1'], 'icloud');
        await platform.dispose();
      },
    );

    test('stored local with documents needs the migration gate', () async {
      await localStore.initialise();
      await _write(localStore, scratch, 'Tax.pdf', 'tax');
      final store = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'local',
      });
      final platform = _establishedPlatform();

      final loaded = (await load(store, platform)()).valueOrNull!;

      expect(loaded.decision, const StorageDecision.migrateToICloud());
      expect(loaded.location, StorageLocation.local);
      // Authority only moves at the migration's verified switch.
      expect(store.values['settings.storage.location.v1'], 'local');
      await platform.dispose();
    });

    test('an empty folder counts as device content', () async {
      await localStore.initialise();
      await localStore.createFolder(const ['Receipts']);
      final platform = ScriptedICloudPlatform();

      final loaded = (await load(
        InMemoryPreferenceStore(),
        platform,
      )()).valueOrNull!;

      expect(loaded.decision, const StorageDecision.migrateToICloud());
      await platform.dispose();
    });

    test('continuing locally keeps the device for the session only', () async {
      await localStore.initialise();
      await _write(localStore, scratch, 'Tax.pdf', 'tax');
      final store = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'local',
      });
      final platform = ScriptedICloudPlatform();

      final loaded = (await load(store, platform)(
        continueLocalThisSession: true,
      )).valueOrNull!;

      expect(
        loaded.decision,
        const StorageDecision.useLocal(
          reason: CloudAvailabilityStatus.available,
        ),
      );
      expect(store.values['settings.storage.location.v1'], 'local');
      await platform.dispose();
    });

    test('signed-out fresh install falls back to the device', () async {
      final store = InMemoryPreferenceStore();
      final platform = ScriptedICloudPlatform(availabilityValue: 'signedOut');

      final loaded = (await load(store, platform)()).valueOrNull!;

      expect(
        loaded.decision,
        const StorageDecision.useLocal(
          reason: CloudAvailabilityStatus.signedOut,
        ),
      );
      expect(store.values['settings.storage.location.v1'], 'local');
      expect(platform.marker, isNull);
      await platform.dispose();
    });

    test('selected iCloud remains authoritative while signed out', () async {
      final platform = ScriptedICloudPlatform(availabilityValue: 'signedOut');

      final loaded = (await load(
        InMemoryPreferenceStore({'settings.storage.location.v1': 'icloud'}),
        platform,
      )()).valueOrNull!;

      expect(loaded.location, StorageLocation.iCloud);
      expect(
        loaded.decision,
        const StorageDecision.iCloudUnavailable(
          reason: CloudAvailabilityStatus.signedOut,
        ),
      );
      await platform.dispose();
    });

    test(
      'an unreadable newer marker is neither adopted nor overwritten',
      () async {
        final platform = ScriptedICloudPlatform(
          marker: const {
            'schemaVersion': 99,
            'libraryIdentifier': 'docscanly-library',
          },
        );
        final loaded = (await load(
          InMemoryPreferenceStore(),
          platform,
        )()).valueOrNull!;

        expect(
          loaded.decision,
          const StorageDecision.useLocal(
            reason: CloudAvailabilityStatus.unavailable,
          ),
        );
        expect(platform.marker!['schemaVersion'], 99);
        await platform.dispose();
      },
    );

    test('an interrupted move to iCloud is resumed', () async {
      await localStore.initialise();
      await _write(localStore, scratch, 'Tax.pdf', 'tax');
      final store = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'local',
      });
      const checkpoint = StorageMigrationCheckpoint(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        phase: StorageMigrationPhase.verifying,
        verifiedRelativePaths: ['Tax.pdf'],
      );
      await StorageLocationPreferences(store).writeCheckpoint(checkpoint);
      final platform = ScriptedICloudPlatform();

      final loaded = (await load(store, platform)()).valueOrNull!;

      expect(
        loaded.decision,
        const StorageDecision.migrateToICloud(resume: checkpoint),
      );
      await platform.dispose();
    });

    test('a legacy move to the device is discarded', () async {
      final store = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'icloud',
      });
      final locations = StorageLocationPreferences(store);
      await locations.writeCheckpoint(
        const StorageMigrationCheckpoint(
          source: StorageLocation.iCloud,
          destination: StorageLocation.local,
          phase: StorageMigrationPhase.copying,
        ),
      );
      final platform = _establishedPlatform();

      final loaded = (await load(store, platform)()).valueOrNull!;

      expect(loaded.decision, const StorageDecision.useICloud());
      expect((await locations.readCheckpoint()).valueOrNull, isNull);
      await platform.dispose();
    });

    test('propagates a persisted-authority read failure', () async {
      final platform = ScriptedICloudPlatform();
      final result = await load(_FailingPreferenceStore(), platform)();

      expect(result.failureOrNull, isA<StorageFailure>());
      await platform.dispose();
    });

    test('propagates an availability failure', () async {
      final platform = _FailingICloudPlatform(failAvailability: true);
      final result = await load(InMemoryPreferenceStore(), platform)();

      expect(result.failureOrNull, isA<StorageFailure>());
      await platform.dispose();
    });

    test('propagates a device listing failure', () async {
      final platform = ScriptedICloudPlatform();
      final result = await LoadStorageLocation(
        locations: StorageLocationPreferences(InMemoryPreferenceStore()),
        cloud: PlatformCloudContainerRepository(platform),
        localStore: _FailingListStore(),
      )();

      expect(result.failureOrNull, isA<StorageFailure>());
      await platform.dispose();
    });

    test('propagates writes for adopted and local authority', () async {
      final localPrefs = InMemoryPreferenceStore()..failNextWrite = true;
      final localPlatform = ScriptedICloudPlatform(
        availabilityValue: 'disabled',
      );
      final local = await load(localPrefs, localPlatform)();
      expect(local.failureOrNull, isA<StorageFailure>());

      final cloudPrefs = InMemoryPreferenceStore()..failNextWrite = true;
      final cloudPlatform = _establishedPlatform();
      final adopted = await load(cloudPrefs, cloudPlatform)();
      expect(adopted.failureOrNull, isA<StorageFailure>());
      await localPlatform.dispose();
      await cloudPlatform.dispose();
    });
  });

  group('AdoptDeviceLibrary', () {
    test('selects the device and leaves iCloud untouched', () async {
      final scratch = await Directory.systemTemp.createTemp('adopt_device');
      addTearDown(() => scratch.delete(recursive: true));
      final cloudRoot = Directory('${scratch.path}/cloud')..createSync();
      File('${cloudRoot.path}/Kept.pdf').writeAsStringSync('cloud');
      final store = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'icloud',
      });
      final locations = StorageLocationPreferences(store);
      await locations.writeCheckpoint(
        const StorageMigrationCheckpoint(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
          phase: StorageMigrationPhase.cleaning,
        ),
      );
      final platform = ScriptedICloudPlatform(
        availabilityValue: 'signedOut',
        rootPath: cloudRoot.path,
        marker: const {
          'schemaVersion': 1,
          'libraryIdentifier': 'docscanly-library',
        },
      );

      final result = await AdoptDeviceLibrary(locations)();

      expect(result.isSuccess, isTrue);
      expect(store.values['settings.storage.location.v1'], 'local');
      expect(platform.marker, isNotNull);
      expect(File('${cloudRoot.path}/Kept.pdf').readAsStringSync(), 'cloud');
      final loaded = await LoadStorageLocation(
        locations: locations,
        cloud: PlatformCloudContainerRepository(platform),
        localStore: FilesystemPublicFileStore.atRoot(
          Directory('${scratch.path}/local'),
        ),
      )();
      expect(
        loaded.valueOrNull!.decision,
        const StorageDecision.useLocal(
          reason: CloudAvailabilityStatus.signedOut,
        ),
      );
      await platform.dispose();
    });

    test('propagates a failed authority write', () async {
      final store = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'icloud',
      });
      final locations = StorageLocationPreferences(store);
      await locations.clearCheckpoint();
      store.failNextWrite = true;

      final result = await AdoptDeviceLibrary(locations)();

      expect(result.failureOrNull, isA<StorageFailure>());
      expect(store.values['settings.storage.location.v1'], 'icloud');
    });
  });

  group('EnsureDocumentDownloaded', () {
    test('already available content does not request a download', () async {
      final platform = ScriptedICloudPlatform(
        items: const [ScriptedICloudItem(relativePath: 'a.pdf')],
      );
      final progress = <double>[];

      final result = await EnsureDocumentDownloaded(
        PlatformCloudContainerRepository(platform),
      )('a.pdf', onProgress: progress.add);

      expect(result.isSuccess, isTrue);
      expect(progress, [1]);
      expect(platform.downloadRequests, isEmpty);
      await platform.dispose();
    });

    test('remote content requests download and reports progress', () async {
      final platform = ScriptedICloudPlatform(
        items: const [
          ScriptedICloudItem(relativePath: 'a.pdf', availability: 'remote'),
        ],
      );
      final progress = <double>[];

      final result = await EnsureDocumentDownloaded(
        PlatformCloudContainerRepository(platform),
      )('a.pdf', onProgress: progress.add);

      expect(result.isSuccess, isTrue);
      expect(platform.downloadRequests, ['a.pdf']);
      expect(progress, [0, 1]);
      await platform.dispose();
    });

    test('offline remote content remains indexed and is retryable', () async {
      final platform = ScriptedICloudPlatform(
        items: const [
          ScriptedICloudItem(relativePath: 'a.pdf', availability: 'remote'),
        ],
      )..nextDownloadFailure = PlatformException(code: 'offline');

      final result = await EnsureDocumentDownloaded(
        PlatformCloudContainerRepository(platform),
      )('a.pdf');

      expect(result.failureOrNull, isA<StorageFailure>());
      expect(
        (await platform.listItems()).single.values['relativePath'],
        'a.pdf',
      );
      await platform.dispose();
    });

    test('cancellation prevents a remote download', () async {
      final platform = ScriptedICloudPlatform(
        items: const [
          ScriptedICloudItem(relativePath: 'a.pdf', availability: 'remote'),
        ],
      );

      final result = await EnsureDocumentDownloaded(
        PlatformCloudContainerRepository(platform),
      )('a.pdf', shouldCancel: () => true);

      expect(result.failureOrNull?.isCancellation, isTrue);
      expect(platform.downloadRequests, isEmpty);
      await platform.dispose();
    });

    test('missing metadata fails before requesting bytes', () async {
      final platform = ScriptedICloudPlatform();

      final result = await EnsureDocumentDownloaded(
        PlatformCloudContainerRepository(platform),
      )('missing.pdf');

      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(platform.downloadRequests, isEmpty);
      await platform.dispose();
    });

    test('list failure and post-download cancellation remain typed', () async {
      final listing = _FailingICloudPlatform(failList: true);
      final failed = await EnsureDocumentDownloaded(
        PlatformCloudContainerRepository(listing),
      )('a.pdf');
      expect(failed.failureOrNull, isA<StorageFailure>());
      await listing.dispose();

      final downloading = ScriptedICloudPlatform(
        items: const [
          ScriptedICloudItem(relativePath: 'a.pdf', availability: 'remote'),
        ],
      );
      var checks = 0;
      final cancelled = await EnsureDocumentDownloaded(
        PlatformCloudContainerRepository(downloading),
      )('a.pdf', shouldCancel: () => checks++ > 0);
      expect(cancelled.failureOrNull?.isCancellation, isTrue);
      expect(downloading.downloadRequests, ['a.pdf']);
      await downloading.dispose();
    });

    test('remote validation runs after a successful download', () async {
      final platform = ScriptedICloudPlatform(
        items: const [
          ScriptedICloudItem(relativePath: 'a.pdf', availability: 'remote'),
        ],
      );
      final validated = <String>[];

      final result =
          await EnsureDocumentDownloaded(
            PlatformCloudContainerRepository(platform),
          )(
            'a.pdf',
            validateReadable: (path) async {
              validated.add(path);
              return const Result<void>.success(null);
            },
          );

      expect(result.isSuccess, isTrue);
      expect(validated, ['a.pdf']);
      await platform.dispose();
    });

    test(
      'corrupt downloaded payload is reported by the injected validator',
      () async {
        final platform = ScriptedICloudPlatform(
          items: const [ScriptedICloudItem(relativePath: 'a.pdf')],
        );

        final result =
            await EnsureDocumentDownloaded(
              PlatformCloudContainerRepository(platform),
            )(
              'a.pdf',
              validateReadable: (_) async => const Result<void>.failure(
                Failure.corruptFile(debugDetail: 'invalid pdf'),
              ),
            );

        expect(result.failureOrNull, isA<CorruptFileFailure>());
        await platform.dispose();
      },
    );

    test(
      'protected PDF without a device password remains an auth failure',
      () async {
        final platform = ScriptedICloudPlatform(
          items: const [ScriptedICloudItem(relativePath: 'protected.pdf')],
        );

        final result =
            await EnsureDocumentDownloaded(
              PlatformCloudContainerRepository(platform),
            )(
              'protected.pdf',
              validateReadable: (_) async => const Result<void>.failure(
                Failure.auth(debugDetail: 'password_required'),
              ),
            );

        expect(result.failureOrNull, isA<AuthFailure>());
        await platform.dispose();
      },
    );
  });

  test('explicit folder import always releases scoped access', () async {
    final platform = ScriptedICloudPlatform(
      pickedPaths: const ['/fixture/good', '/fixture/bad'],
    );
    final imported = <String>[];
    final result = await ImportExistingCloudFolder(
      cloud: PlatformCloudContainerRepository(platform),
      importPath: (path) async {
        imported.add(path);
        return path.endsWith('bad')
            ? const Result<void>.failure(Failure.import(unsupportedType: true))
            : const Result<void>.success(null);
      },
    )();

    expect(result.isFailure, isTrue);
    expect(imported, ['/fixture/good', '/fixture/bad']);
    expect(platform.releasedPaths, ['/fixture/good', '/fixture/bad']);
    await platform.dispose();
  });

  test('folder picker and scoped-release failures are propagated', () async {
    final picker = _FailingICloudPlatform(failPick: true);
    final pickResult = await ImportExistingCloudFolder(
      cloud: PlatformCloudContainerRepository(picker),
      importPath: (_) async => const Result<void>.success(null),
    )();
    expect(pickResult.failureOrNull, isA<StorageFailure>());
    await picker.dispose();

    final release = _FailingICloudPlatform(
      failRelease: true,
      pickedPaths: const ['/fixture/a.pdf'],
    );
    final releaseResult = await ImportExistingCloudFolder(
      cloud: PlatformCloudContainerRepository(release),
      importPath: (_) async => const Result<void>.success(null),
    )();
    expect(releaseResult.failureOrNull, isA<StorageFailure>());
    await release.dispose();
  });

  test(
    'same-named external folder is enumerated, never adopted as authority',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'docscanly_external_',
      );
      addTearDown(() => parent.delete(recursive: true));
      final external = Directory('${parent.path}/DocScanly')..createSync();
      File('${external.path}/A.pdf').writeAsStringSync('pdf');
      File('${external.path}/ignore.txt').writeAsStringSync('unsupported');
      final platform = ScriptedICloudPlatform(pickedPaths: [external.path]);
      final imported = <String>[];

      final result = await ImportExistingCloudFolder(
        cloud: PlatformCloudContainerRepository(platform),
        importPath: (path) async {
          imported.add(path);
          return const Result<void>.success(null);
        },
      )();

      expect(result.valueOrNull, 1);
      expect(imported, ['${external.path}/A.pdf']);
      expect(platform.releasedPaths, [external.path]);
      expect(platform.marker, isNull);
      await platform.dispose();
    },
  );

  group('MigrateLibraryLocation', () {
    late Directory localContainer;
    late Directory cloudRoot;
    late FilesystemPublicFileStore local;
    late FilesystemPublicFileStore cloudStore;
    late InMemoryPreferenceStore preferenceStore;
    late StorageLocationPreferences locations;
    late ScriptedICloudPlatform platform;
    late MigrateLibraryLocation migrate;

    setUp(() async {
      localContainer = await Directory.systemTemp.createTemp(
        'docscanly_local_',
      );
      cloudRoot = await Directory.systemTemp.createTemp('docscanly_cloud_');
      local = FilesystemPublicFileStore(localContainer);
      cloudStore = FilesystemPublicFileStore.atRoot(cloudRoot);
      await local.initialise();
      await cloudStore.initialise();
      preferenceStore = InMemoryPreferenceStore({
        'settings.storage.location.v1': 'local',
      });
      locations = StorageLocationPreferences(preferenceStore);
      platform = ScriptedICloudPlatform();
      migrate = MigrateLibraryLocation(
        locations: locations,
        stores: FixedLibraryStoreResolver(local: local, iCloud: cloudStore),
        cloud: PlatformCloudContainerRepository(platform),
      );
    });

    tearDown(() async {
      await platform.dispose();
      if (localContainer.existsSync()) {
        await localContainer.delete(recursive: true);
      }
      if (cloudRoot.existsSync()) await cloudRoot.delete(recursive: true);
    });

    test('copy-verifies active and Trash payloads before switching', () async {
      await _write(local, localContainer, 'Folder/a.pdf', 'active');
      await _write(
        local,
        localContainer,
        '$publicTrashFolderName/trash-1/a.pdf',
        'trash',
      );
      final progress = <StorageMigrationProgress>[];

      final result = await migrate(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        onProgress: progress.add,
      );

      expect(result.isSuccess, isTrue);
      expect(
        (await locations.readLocation()).valueOrNull,
        StorageLocation.iCloud,
      );
      expect(
        File('${cloudRoot.path}/Folder/a.pdf').readAsStringSync(),
        'active',
      );
      expect(
        File(
          '${cloudRoot.path}/$publicTrashFolderName/trash-1/a.pdf',
        ).readAsStringSync(),
        'trash',
      );
      expect(
        File('${local.rootDirectory.path}/Folder/a.pdf').existsSync(),
        isFalse,
      );
      expect(platform.marker, isNotNull);
      expect(progress.last.phase, StorageMigrationPhase.completed);
      expect((await locations.readCheckpoint()).valueOrNull, isNull);
    });

    test(
      'same authority is a no-op and progress values compare by value',
      () async {
        final phase = StorageMigrationPhase.values.first;
        final progress = StorageMigrationProgress(
          phase: phase,
          completedFiles: int.parse('1'),
          totalFiles: int.parse('2'),
        );
        expect(
          progress,
          StorageMigrationProgress(
            phase: phase,
            completedFiles: int.parse('1'),
            totalFiles: int.parse('2'),
          ),
        );
        expect(progress.fraction, .5);

        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.local,
        );
        expect(result.isSuccess, isTrue);
      },
    );

    test('availability transport failure stops before inventory', () async {
      final failing = _FailingICloudPlatform(failAvailability: true);
      final result = await MigrateLibraryLocation(
        locations: locations,
        stores: FixedLibraryStoreResolver(local: local, iCloud: cloudStore),
        cloud: PlatformCloudContainerRepository(failing),
      )(source: StorageLocation.local, destination: StorageLocation.iCloud);

      expect(result.failureOrNull, isA<StorageFailure>());
      await failing.dispose();
    });

    test(
      'empty library still writes marker and becomes discoverable',
      () async {
        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.isSuccess, isTrue);
        expect(platform.marker, isNotNull);
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.iCloud,
        );
      },
    );

    test(
      'moves an iCloud library back to local and removes its marker',
      () async {
        await locations.writeLocation(StorageLocation.iCloud);
        await platform.writeMarker(const {
          'schemaVersion': 1,
          'libraryIdentifier': 'docscanly-library',
        });
        await _write(cloudStore, cloudRoot, 'Archive/a.pdf', 'cloud-bytes');

        final result = await migrate(
          source: StorageLocation.iCloud,
          destination: StorageLocation.local,
        );

        expect(result.isSuccess, isTrue);
        expect(
          File('${local.rootDirectory.path}/Archive/a.pdf').readAsStringSync(),
          'cloud-bytes',
        );
        expect(File('${cloudRoot.path}/Archive/a.pdf').existsSync(), isFalse);
        expect(platform.marker, isNull);
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.local,
        );
      },
    );

    test(
      'insufficient destination space keeps the source authoritative',
      () async {
        await _write(local, localContainer, 'a.pdf', 'source');
        final destination = _FaultInjectingStore(cloudStore)
          ..nextWriteFailure = const Failure.storageFull();
        final useCase = MigrateLibraryLocation(
          locations: locations,
          stores: FixedLibraryStoreResolver(local: local, iCloud: destination),
          cloud: PlatformCloudContainerRepository(platform),
        );

        final result = await useCase(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.failureOrNull, isA<StorageFullFailure>());
        expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isTrue);
        expect(File('${cloudRoot.path}/a.pdf').existsSync(), isFalse);
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.local,
        );
      },
    );

    test(
      'identity loss before authority switch retains local authority',
      () async {
        await _write(local, localContainer, 'a.pdf', 'source');
        final destination = _FaultInjectingStore(cloudStore)
          ..afterSuccessfulWrite = () {
            platform.availabilityValue = 'signedOut';
          };
        final useCase = MigrateLibraryLocation(
          locations: locations,
          stores: FixedLibraryStoreResolver(local: local, iCloud: destination),
          cloud: PlatformCloudContainerRepository(platform),
        );

        final result = await useCase(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.failureOrNull, isA<StorageFailure>());
        expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isTrue);
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.local,
        );
        expect((await locations.readCheckpoint()).valueOrNull, isNotNull);
      },
    );

    test(
      'digest mismatch removes only the partial copy and retry succeeds',
      () async {
        await _write(local, localContainer, 'a.pdf', 'source');
        final destination = _FaultInjectingStore(cloudStore)
          ..corruptNextWrite = true;
        final useCase = MigrateLibraryLocation(
          locations: locations,
          stores: FixedLibraryStoreResolver(local: local, iCloud: destination),
          cloud: PlatformCloudContainerRepository(platform),
        );

        final first = await useCase(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(first.failureOrNull, isA<CorruptFileFailure>());
        expect(File('${cloudRoot.path}/a.pdf').existsSync(), isFalse);
        expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isTrue);

        final retry = await useCase(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(retry.isSuccess, isTrue);
        expect(File('${cloudRoot.path}/a.pdf').readAsStringSync(), 'source');
        expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isFalse);
      },
    );

    test(
      'post-switch cleanup failure resumes forward without rollback',
      () async {
        await _write(local, localContainer, 'a.pdf', 'source');
        final source = _FaultInjectingStore(local)
          ..nextDeleteFailure = const Failure.storage(
            debugDetail: 'interrupted cleanup',
          );
        final useCase = MigrateLibraryLocation(
          locations: locations,
          stores: FixedLibraryStoreResolver(local: source, iCloud: cloudStore),
          cloud: PlatformCloudContainerRepository(platform),
        );

        final first = await useCase(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(first.isFailure, isTrue);
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.iCloud,
        );
        expect(
          (await locations.readCheckpoint()).valueOrNull?.phase,
          StorageMigrationPhase.cleaning,
        );
        expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isTrue);

        final retry = await useCase(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(retry.isSuccess, isTrue);
        expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isFalse);
        expect(File('${cloudRoot.path}/a.pdf').readAsStringSync(), 'source');
        expect((await locations.readCheckpoint()).valueOrNull, isNull);
      },
    );

    test('collision moving to the device still refuses to overwrite', () async {
      await locations.writeLocation(StorageLocation.iCloud);
      await _write(cloudStore, cloudRoot, 'a.pdf', 'cloud');
      await _write(local, localContainer, 'a.pdf', 'device');

      final result = await migrate(
        source: StorageLocation.iCloud,
        destination: StorageLocation.local,
      );

      expect(result.failureOrNull, isA<StorageFailure>());
      expect(
        File('${local.rootDirectory.path}/a.pdf').readAsStringSync(),
        'device',
      );
      expect(
        (await locations.readLocation()).valueOrNull,
        StorageLocation.iCloud,
      );
    });

    group('merging into an established iCloud library', () {
      setUp(() {
        platform.marker = const {
          'schemaVersion': 1,
          'libraryIdentifier': 'docscanly-library',
        };
      });

      test('identical payloads are verified without a copy', () async {
        await _write(local, localContainer, 'a.pdf', 'same');
        await _write(cloudStore, cloudRoot, 'a.pdf', 'same');

        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.isSuccess, isTrue);
        expect(
          cloudRoot.listSync().whereType<File>().map(
            (f) => f.uri.pathSegments.last,
          ),
          isNot(contains('a (Conflict device).pdf')),
        );
        expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isFalse);
      });

      test('a differing payload is kept beside the original', () async {
        await _write(local, localContainer, 'Tax/a.pdf', 'device');
        await _write(cloudStore, cloudRoot, 'Tax/a.pdf', 'cloud');
        await _write(cloudStore, cloudRoot, 'Tax/a (Conflict device).pdf', 'x');

        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.isSuccess, isTrue);
        expect(File('${cloudRoot.path}/Tax/a.pdf').readAsStringSync(), 'cloud');
        expect(
          File(
            '${cloudRoot.path}/Tax/a (Conflict device).pdf',
          ).readAsStringSync(),
          'x',
        );
        expect(
          File(
            '${cloudRoot.path}/Tax/a (Conflict device 2).pdf',
          ).readAsStringSync(),
          'device',
        );
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.iCloud,
        );
      });

      test('a resumed merge accepts its earlier conflict copy', () async {
        await _write(local, localContainer, 'a.pdf', 'device');
        await _write(cloudStore, cloudRoot, 'a.pdf', 'cloud');
        // What an interrupted earlier run left behind before its checkpoint.
        await _write(
          cloudStore,
          cloudRoot,
          'a (Conflict device).pdf',
          'device',
        );

        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.isSuccess, isTrue);
        expect(
          File('${cloudRoot.path}/a (Conflict device 2).pdf').existsSync(),
          isFalse,
        );
      });

      test('a reserved Trash collision is never renamed', () async {
        const trashPath = '$publicTrashFolderName/t-1/payload/a.pdf';
        await _write(local, localContainer, trashPath, 'device');
        await _write(cloudStore, cloudRoot, trashPath, 'cloud');

        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.failureOrNull, isA<StorageFailure>());
        expect(
          File('${cloudRoot.path}/$trashPath').readAsStringSync(),
          'cloud',
        );
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.local,
        );
      });

      test('the established marker is not rewritten', () async {
        final counting = _MarkerCountingPlatform();
        await _write(local, localContainer, 'a.pdf', 'a');

        final result = await MigrateLibraryLocation(
          locations: locations,
          stores: FixedLibraryStoreResolver(local: local, iCloud: cloudStore),
          cloud: PlatformCloudContainerRepository(counting),
        )(source: StorageLocation.local, destination: StorageLocation.iCloud);

        expect(result.isSuccess, isTrue);
        expect(counting.markerWrites, 0);
        await counting.dispose();
      });

      test('cancellation removes only what this run wrote', () async {
        await _write(cloudStore, cloudRoot, 'Shared/kept.pdf', 'other device');
        await _write(cloudStore, cloudRoot, 'same.pdf', 'same');
        await _write(local, localContainer, 'same.pdf', 'same');
        await _write(local, localContainer, 'Shared/new.pdf', 'new');
        await _write(local, localContainer, 'z.pdf', 'z');
        var checks = 0;

        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
          shouldCancel: () => checks++ > 1,
        );

        expect(result.failureOrNull, isA<CancelledFailure>());
        expect(File('${cloudRoot.path}/Shared/new.pdf').existsSync(), isFalse);
        expect(
          File('${cloudRoot.path}/Shared/kept.pdf').readAsStringSync(),
          'other device',
        );
        expect(File('${cloudRoot.path}/same.pdf').readAsStringSync(), 'same');
        expect(File('${local.rootDirectory.path}/z.pdf').existsSync(), isTrue);
      });
    });

    test('conflict names are ordinal, foldered and length-safe', () {
      final path = LibraryPath.parse('Tax/2026/Receipt.pdf');
      expect(
        conflictCopyPath(path, 1).relative,
        'Tax/2026/Receipt (Conflict device).pdf',
      );
      expect(
        conflictCopyPath(path, 3).relative,
        'Tax/2026/Receipt (Conflict device 3).pdf',
      );
      final long = LibraryPath.parse('${'x' * 251}.pdf');
      final renamed = conflictCopyPath(long, 12).fileName;
      expect(renamed.length, lessThanOrEqualTo(LibraryPath.maxNameLength));
      expect(renamed, endsWith(' (Conflict device 12).pdf'));
    });

    test('safe cancellation rolls back verified destination copies', () async {
      await _write(local, localContainer, 'a.pdf', 'a');
      await _write(local, localContainer, 'b.pdf', 'b');
      var checks = 0;

      final result = await migrate(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        shouldCancel: () => checks++ > 0,
      );

      expect(result.failureOrNull, isA<CancelledFailure>());
      expect(File('${cloudRoot.path}/a.pdf').existsSync(), isFalse);
      expect(File('${local.rootDirectory.path}/a.pdf').existsSync(), isTrue);
      expect(
        (await locations.readLocation()).valueOrNull,
        StorageLocation.local,
      );
      expect((await locations.readCheckpoint()).valueOrNull, isNull);
    });
  });
}

ScriptedICloudPlatform _establishedPlatform() => ScriptedICloudPlatform(
  marker: const {'schemaVersion': 1, 'libraryIdentifier': 'docscanly-library'},
);

Future<void> _write(
  PublicFileStore store,
  Directory scratch,
  String relative,
  String contents,
) async {
  final source = File('${scratch.path}/source-${relative.hashCode}.pdf')
    ..writeAsStringSync(contents);
  final result = await store.writeFile(
    LibraryPath.parse(relative),
    source.path,
  );
  source.deleteSync();
  expect(result.isSuccess, isTrue);
}

class _FaultInjectingStore implements PublicFileStore {
  _FaultInjectingStore(this.delegate);

  final PublicFileStore delegate;
  Failure? nextWriteFailure;
  Failure? nextDeleteFailure;
  bool corruptNextWrite = false;
  void Function()? afterSuccessfulWrite;

  @override
  Future<Result<void>> initialise() => delegate.initialise();

  @override
  Future<Result<List<PublicEntry>>> listRecursive(List<String> folders) =>
      delegate.listRecursive(folders);

  @override
  Future<Result<void>> createFolder(List<String> folders) =>
      delegate.createFolder(folders);

  @override
  Future<Result<bool>> exists(LibraryPath path) => delegate.exists(path);

  @override
  Future<Result<String>> materialise(LibraryPath path) =>
      delegate.materialise(path);

  @override
  Future<Result<void>> releaseMaterialised(LibraryPath path) =>
      delegate.releaseMaterialised(path);

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) async {
    final failure = nextWriteFailure;
    nextWriteFailure = null;
    if (failure != null) return Result<String>.failure(failure);
    final result = await delegate.writeFile(path, sourcePath);
    if (result case Success(:final value)) {
      if (corruptNextWrite) {
        corruptNextWrite = false;
        await File(value).writeAsString('corrupted');
      }
      afterSuccessfulWrite?.call();
      afterSuccessfulWrite = null;
    }
    return result;
  }

  @override
  Future<Result<void>> delete(LibraryPath path) async {
    final failure = nextDeleteFailure;
    nextDeleteFailure = null;
    return failure == null
        ? delegate.delete(path)
        : Result<void>.failure(failure);
  }

  @override
  Future<Result<void>> deleteFolder(List<String> folders) =>
      delegate.deleteFolder(folders);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingPreferenceStore extends InMemoryPreferenceStore {
  @override
  Future<Result<String?>> readString(String key) async =>
      const Result<String?>.failure(Failure.storage(debugDetail: 'read'));
}

class _FailingICloudPlatform extends ScriptedICloudPlatform {
  _FailingICloudPlatform({
    this.failAvailability = false,
    this.failList = false,
    this.failPick = false,
    this.failRelease = false,
    super.pickedPaths,
  });

  final bool failAvailability;
  final bool failList;
  final bool failPick;
  final bool failRelease;

  @override
  Future<String> availability() {
    if (failAvailability) {
      throw PlatformException(code: 'unavailable');
    }
    return super.availability();
  }

  @override
  Future<List<ICloudItemData>> listItems() {
    if (failList) throw PlatformException(code: 'offline');
    return super.listItems();
  }

  @override
  Future<List<String>> pickImportFolder() {
    if (failPick) throw PlatformException(code: 'picker_failed');
    return super.pickImportFolder();
  }

  @override
  Future<void> releaseImportFolder(List<String> paths) {
    if (failRelease) throw PlatformException(code: 'release_failed');
    return super.releaseImportFolder(paths);
  }
}

class _FailingListStore implements PublicFileStore {
  @override
  Future<Result<List<PublicEntry>>> listRecursive(List<String> folders) async =>
      const Result<List<PublicEntry>>.failure(
        Failure.storage(debugDetail: 'list'),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MarkerCountingPlatform extends ScriptedICloudPlatform {
  _MarkerCountingPlatform()
    : super(
        marker: const {
          'schemaVersion': 1,
          'libraryIdentifier': 'docscanly-library',
        },
      );

  int markerWrites = 0;

  @override
  Future<void> writeMarker(Map<String, Object?> marker) {
    markerWrites++;
    return super.writeMarker(marker);
  }
}
