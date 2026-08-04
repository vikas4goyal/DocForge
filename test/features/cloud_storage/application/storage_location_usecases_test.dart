import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/ensure_document_downloaded.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/import_existing_cloud_folder.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadStorageLocation', () {
    test('existing local selection remains local when marker exists', () async {
      final preferences = StorageLocationPreferences(
        InMemoryPreferenceStore({'settings.storage.location.v1': 'local'}),
      );
      final platform = _establishedPlatform();
      final useCase = LoadStorageLocation(
        locations: preferences,
        cloud: PlatformCloudContainerRepository(platform),
      );

      final loaded = (await useCase()).valueOrNull!;

      expect(loaded.location, StorageLocation.local);
      expect(loaded.discoveredEstablishedLibrary, isFalse);
      await platform.dispose();
    });

    test('new device adopts a valid established marker', () async {
      final store = InMemoryPreferenceStore();
      final platform = _establishedPlatform();
      final useCase = LoadStorageLocation(
        locations: StorageLocationPreferences(store),
        cloud: PlatformCloudContainerRepository(platform),
      );

      final loaded = (await useCase()).valueOrNull!;

      expect(loaded.location, StorageLocation.iCloud);
      expect(loaded.discoveredEstablishedLibrary, isTrue);
      expect(store.values['settings.storage.location.v1'], 'icloud');
      await platform.dispose();
    });

    test('fresh install without marker becomes local', () async {
      final store = InMemoryPreferenceStore();
      final platform = ScriptedICloudPlatform();

      final loaded = (await LoadStorageLocation(
        locations: StorageLocationPreferences(store),
        cloud: PlatformCloudContainerRepository(platform),
      )()).valueOrNull!;

      expect(loaded.location, StorageLocation.local);
      expect(store.values['settings.storage.location.v1'], 'local');
      await platform.dispose();
    });

    test('selected iCloud remains authoritative while signed out', () async {
      final preferences = StorageLocationPreferences(
        InMemoryPreferenceStore({'settings.storage.location.v1': 'icloud'}),
      );
      final platform = ScriptedICloudPlatform(availabilityValue: 'signedOut');

      final loaded = (await LoadStorageLocation(
        locations: preferences,
        cloud: PlatformCloudContainerRepository(platform),
      )()).valueOrNull!;

      expect(loaded.location, StorageLocation.iCloud);
      expect(loaded.isAuthoritativeRootAvailable, isFalse);
      await platform.dispose();
    });

    test('propagates a persisted-authority read failure', () async {
      final platform = ScriptedICloudPlatform();
      final result = await LoadStorageLocation(
        locations: StorageLocationPreferences(_FailingPreferenceStore()),
        cloud: PlatformCloudContainerRepository(platform),
      )();

      expect(result.failureOrNull, isA<StorageFailure>());
      await platform.dispose();
    });

    test('propagates an availability failure', () async {
      final platform = _FailingICloudPlatform(failAvailability: true);
      final result = await LoadStorageLocation(
        locations: StorageLocationPreferences(InMemoryPreferenceStore()),
        cloud: PlatformCloudContainerRepository(platform),
      )();

      expect(result.failureOrNull, isA<StorageFailure>());
      await platform.dispose();
    });

    test('propagates an invalid marker read', () async {
      final platform = ScriptedICloudPlatform(
        marker: const {
          'schemaVersion': 99,
          'libraryIdentifier': 'docscanly-library',
        },
      );
      final result = await LoadStorageLocation(
        locations: StorageLocationPreferences(InMemoryPreferenceStore()),
        cloud: PlatformCloudContainerRepository(platform),
      )();

      expect(result.failureOrNull, isA<CorruptFileFailure>());
      await platform.dispose();
    });

    test('propagates writes for discovered and local authority', () async {
      final localStore = InMemoryPreferenceStore()..failNextWrite = true;
      final localPlatform = ScriptedICloudPlatform();
      final local = await LoadStorageLocation(
        locations: StorageLocationPreferences(localStore),
        cloud: PlatformCloudContainerRepository(localPlatform),
      )();
      expect(local.failureOrNull, isA<StorageFailure>());

      final cloudStore = InMemoryPreferenceStore()..failNextWrite = true;
      final cloudPlatform = _establishedPlatform();
      final discovered = await LoadStorageLocation(
        locations: StorageLocationPreferences(cloudStore),
        cloud: PlatformCloudContainerRepository(cloudPlatform),
      )();
      expect(discovered.failureOrNull, isA<StorageFailure>());
      await localPlatform.dispose();
      await cloudPlatform.dispose();
    });
  });

  group('ChooseStorageLocation', () {
    test('requires available iCloud before returning a choice', () async {
      final platform = ScriptedICloudPlatform(availabilityValue: 'restricted');
      final result = await ChooseStorageLocation(
        PlatformCloudContainerRepository(platform),
      )(current: StorageLocation.local, destination: StorageLocation.iCloud);

      expect(result.isFailure, isTrue);
      await platform.dispose();
    });

    test('returns an explicit confirmable choice', () async {
      final platform = ScriptedICloudPlatform();
      final result = await ChooseStorageLocation(
        PlatformCloudContainerRepository(platform),
      )(current: StorageLocation.local, destination: StorageLocation.iCloud);

      expect(
        result.valueOrNull,
        const StorageLocationChoice(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        ),
      );
      expect(result.valueOrNull!.changesLocation, isTrue);
      await platform.dispose();
    });

    test('propagates an availability transport failure', () async {
      final platform = _FailingICloudPlatform(failAvailability: true);
      final result = await ChooseStorageLocation(
        PlatformCloudContainerRepository(platform),
      )(current: StorageLocation.local, destination: StorageLocation.iCloud);

      expect(result.failureOrNull, isA<StorageFailure>());
      await platform.dispose();
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

    test(
      'collision preserves both authorities and does not overwrite',
      () async {
        await _write(local, localContainer, 'a.pdf', 'source');
        await _write(cloudStore, cloudRoot, 'a.pdf', 'destination');

        final result = await migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        );

        expect(result.isFailure, isTrue);
        expect(
          File('${cloudRoot.path}/a.pdf').readAsStringSync(),
          'destination',
        );
        expect(
          File('${local.rootDirectory.path}/a.pdf').readAsStringSync(),
          'source',
        );
        expect(
          (await locations.readLocation()).valueOrNull,
          StorageLocation.local,
        );
      },
    );

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
