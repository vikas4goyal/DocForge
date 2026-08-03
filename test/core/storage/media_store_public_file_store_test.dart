import 'dart:io';

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/storage/public_storage/media_store_channel.dart';
import 'package:doc_forge/core/storage/public_storage/media_store_public_file_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One call recorded as it crossed the channel.
class RecordedCall {
  RecordedCall(this.method, this.arguments);

  final String method;
  final Map<Object?, Object?> arguments;

  Object? operator [](String key) => arguments[key];
}

/// A [MethodChannel] whose handler is supplied by the test.
///
/// Substituted for the real channel so every MediaStore argument can be
/// asserted without a device, which is the whole reason the channel is injected
/// rather than constructed inside the store.
class FakeMediaStoreChannel extends MediaStoreChannel {
  FakeMediaStoreChannel() : super(const MethodChannel('fake'));

  final List<RecordedCall> calls = [];

  /// Rows the fake pretends MediaStore holds, keyed by relative path.
  final Map<String, List<MediaStoreItem>> items = {};

  /// Folder names the fake reports per relative path.
  final Map<String, List<String>> folders = {};

  /// Methods that should throw, and what they should throw.
  final Map<String, MediaStoreException> failures = {};

  void _record(String method, Map<String, Object?> arguments) {
    calls.add(RecordedCall(method, arguments));
    final failure = failures[method];
    if (failure != null) throw failure;
  }

  RecordedCall callTo(String method) =>
      calls.firstWhere((call) => call.method == method);

  bool hasCallTo(String method) => calls.any((call) => call.method == method);

  @override
  Future<void> createFolder(String relativePath) async =>
      _record('createFolder', {'relativePath': relativePath});

  @override
  Future<void> deleteFolder(String relativePath) async =>
      _record('deleteFolder', {'relativePath': relativePath});

  @override
  Future<void> renameFolder(String relativePath, String newName) async =>
      _record('renameFolder', {
        'relativePath': relativePath,
        'newName': newName,
      });

  @override
  Future<void> moveFolder(
    String fromRelativePath,
    String toRelativePath,
  ) async => _record('moveFolder', {
    'fromRelativePath': fromRelativePath,
    'toRelativePath': toRelativePath,
  });

  @override
  Future<List<MediaStoreItem>> list(
    String relativePath, {
    bool recursive = false,
  }) async {
    _record('list', {'relativePath': relativePath, 'recursive': recursive});
    if (!recursive) return items[relativePath] ?? const [];
    return [
      for (final entry in items.entries)
        if (entry.key.startsWith(relativePath)) ...entry.value,
    ];
  }

  @override
  Future<List<String>> listFolders(String relativePath) async {
    _record('listFolders', {'relativePath': relativePath});
    return folders[relativePath] ?? const [];
  }

  @override
  Future<void> writeFile({
    required String relativePath,
    required String displayName,
    required String sourcePath,
  }) async {
    _record('writeFile', {
      'relativePath': relativePath,
      'displayName': displayName,
      'sourcePath': sourcePath,
    });
    items
        .putIfAbsent(relativePath, () => [])
        .add(
          MediaStoreItem(
            relativePath: relativePath,
            displayName: displayName,
            sizeBytes: File(sourcePath).lengthSync(),
            modifiedAt: DateTime.utc(2026),
          ),
        );
  }

  @override
  Future<void> copyToCache({
    required String relativePath,
    required String displayName,
    required String destinationPath,
  }) async {
    _record('copyToCache', {
      'relativePath': relativePath,
      'displayName': displayName,
      'destinationPath': destinationPath,
    });
    final file = File(destinationPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('materialised:$relativePath$displayName');
  }

  @override
  Future<void> moveFile({
    required String fromRelativePath,
    required String fromDisplayName,
    required String toRelativePath,
    required String toDisplayName,
  }) async => _record('moveFile', {
    'fromRelativePath': fromRelativePath,
    'fromDisplayName': fromDisplayName,
    'toRelativePath': toRelativePath,
    'toDisplayName': toDisplayName,
  });

  @override
  Future<void> deleteFile({
    required String relativePath,
    required String displayName,
  }) async => _record('deleteFile', {
    'relativePath': relativePath,
    'displayName': displayName,
  });

  @override
  Future<bool> exists({
    required String relativePath,
    required String displayName,
  }) async {
    _record('exists', {
      'relativePath': relativePath,
      'displayName': displayName,
    });
    return (items[relativePath] ?? const []).any(
      (item) => item.displayName == displayName,
    );
  }
}

void main() {
  late FakeMediaStoreChannel channel;
  late Directory cache;
  late MediaStorePublicFileStore store;

  setUp(() async {
    channel = FakeMediaStoreChannel();
    cache = await Directory.systemTemp.createTemp('docforge_mediastore_');
    store = MediaStorePublicFileStore(channel: channel, cacheDirectory: cache);
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  Future<String> sourceFile(String name, {String contents = 'pdf'}) async {
    final file = File('${cache.path}/$name');
    await file.writeAsString(contents);
    return file.path;
  }

  group('relative paths', () {
    test('initialise creates the library collection folder', () async {
      await store.initialise();

      expect(
        channel.callTo('createFolder')['relativePath'],
        'Documents/DocForge/',
      );
    });

    test(
      'a nested folder becomes a trailing-separator RELATIVE_PATH',
      () async {
        await store.createFolder(const ['Invoices', '2026']);

        expect(
          channel.callTo('createFolder')['relativePath'],
          'Documents/DocForge/Invoices/2026/',
        );
      },
    );

    test('writeFile sends the folder and the display name apart', () async {
      await store.writeFile(
        LibraryPath.parse('Invoices/Receipt.pdf'),
        await sourceFile('in.pdf'),
      );

      final call = channel.callTo('writeFile');
      expect(call['relativePath'], 'Documents/DocForge/Invoices/');
      expect(call['displayName'], 'Receipt.pdf');
    });
  });

  group('createFolder', () {
    test('refuses an illegal segment without calling the platform', () async {
      final result = await store.createFolder(const ['..']);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(channel.hasCallTo('createFolder'), isFalse);
    });
  });

  group('nested-folder fallback', () {
    setUp(() {
      channel.failures['createFolder'] = const MediaStoreException(
        MediaStoreException.codeNestedUnsupported,
        'RELATIVE_PATH below the collection is not supported',
      );
    });

    test('a refused nested folder still succeeds', () async {
      final result = await store.createFolder(const ['Invoices']);

      expect(result.isSuccess, isTrue);
      expect(store.nestedFoldersUnsupported, isTrue);
    });

    test('later writes land flat in the library root', () async {
      await store.createFolder(const ['Invoices']);

      await store.writeFile(
        LibraryPath.parse('Invoices/Receipt.pdf'),
        await sourceFile('in.pdf'),
      );

      final call = channel.callTo('writeFile');
      expect(call['relativePath'], 'Documents/DocForge/');
      expect(call['displayName'], 'Receipt.pdf');
    });

    test('a refusal at the root is a real failure', () async {
      // Nothing to fall back to: the library folder itself could not be made.
      final result = await store.createFolder(const []);

      expect(result.failureOrNull, isA<StorageFailure>());
      expect(store.nestedFoldersUnsupported, isFalse);
    });
  });

  group('list', () {
    test('combines folders and files at one level', () async {
      channel.folders['Documents/DocForge/'] = ['Invoices'];
      await store.writeFile(
        LibraryPath.parse('Top.pdf'),
        await sourceFile('in.pdf', contents: '12345'),
      );

      final entries = (await store.list(const [])).valueOrNull!;

      expect(entries.map((e) => e.name).toSet(), {'Invoices', 'Top.pdf'});
      final file = entries.firstWhere((e) => !e.isFolder);
      expect(file.sizeBytes, 5);
      expect(file.modifiedAt, isNotNull);
    });

    test('skips dot-files', () async {
      channel.items['Documents/DocForge/'] = [
        const MediaStoreItem(
          relativePath: 'Documents/DocForge/',
          displayName: '.nomedia',
          sizeBytes: 0,
          modifiedAt: null,
        ),
      ];

      expect((await store.list(const [])).valueOrNull, isEmpty);
    });
  });

  group('listRecursive', () {
    test('infers folders from the paths of the files inside them', () async {
      channel.items['Documents/DocForge/Invoices/2026/'] = [
        const MediaStoreItem(
          relativePath: 'Documents/DocForge/Invoices/2026/',
          displayName: 'Receipt.pdf',
          sizeBytes: 10,
          modifiedAt: null,
        ),
      ];

      final entries = (await store.listRecursive(const [])).valueOrNull!;

      expect(
        entries.where((e) => !e.isFolder).single.path!.relative,
        'Invoices/2026/Receipt.pdf',
      );
      // MediaStore has no folder rows; both ancestors must still be reported.
      expect(entries.where((e) => e.isFolder).map((e) => e.name).toSet(), {
        'Invoices',
        '2026',
      });
    });

    test('excludes the reserved Trash namespace', () async {
      channel.items['Documents/DocForge/.docforge-trash/trash-1/payload/'] = [
        const MediaStoreItem(
          relativePath: 'Documents/DocForge/.docforge-trash/trash-1/payload/',
          displayName: 'Receipt.pdf',
          sizeBytes: 10,
          modifiedAt: null,
        ),
      ];
      channel.folders['Documents/DocForge/'] = ['.docforge-trash', 'Invoices'];

      expect((await store.listRecursive(const [])).valueOrNull, isEmpty);
      expect(
        (await store.list(const [])).valueOrNull!.map((entry) => entry.name),
        ['Invoices'],
      );
    });
  });

  group('Trash lifecycle', () {
    test('moves and restores a file through reserved RELATIVE_PATHs', () async {
      final path = LibraryPath.parse('Invoices/Receipt.pdf');

      await store.moveFileToTrash('trash-1', path);
      final moved = channel.calls.lastWhere(
        (call) => call.method == 'moveFile',
      );
      expect(moved['fromRelativePath'], 'Documents/DocForge/Invoices/');
      expect(
        moved['toRelativePath'],
        'Documents/DocForge/.docforge-trash/trash-1/payload/',
      );

      await store.restoreFileFromTrash(
        'trash-1',
        'Receipt.pdf',
        LibraryPath.parse('Invoices/Receipt (Recovered 1).pdf'),
      );
      final restored = channel.calls.lastWhere(
        (call) => call.method == 'moveFile',
      );
      expect(restored['toDisplayName'], 'Receipt (Recovered 1).pdf');
    });

    test('moves and restores a complete folder tree', () async {
      await store.moveFolderToTrash('trash-2', const ['Projects']);
      var call = channel.callTo('moveFolder');
      expect(call['fromRelativePath'], 'Documents/DocForge/Projects/');
      expect(
        call['toRelativePath'],
        'Documents/DocForge/.docforge-trash/trash-2/payload/Projects/',
      );

      await store.restoreFolderFromTrash('trash-2', 'Projects', const [
        'Recovered Projects',
      ]);
      call = channel.calls.lastWhere((value) => value.method == 'moveFolder');
      expect(call['toRelativePath'], 'Documents/DocForge/Recovered Projects/');
    });

    test('purge delegates to idempotent folder deletion', () async {
      await store.purgeTrashPayload('trash-1');
      expect(
        channel.callTo('deleteFolder')['relativePath'],
        'Documents/DocForge/.docforge-trash/trash-1/',
      );
    });
  });

  group('materialise', () {
    test('copies the item to the cache and returns that path', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      await store.writeFile(path, await sourceFile('in.pdf'));

      final result = await store.materialise(path);

      expect(result.valueOrNull, contains('materialised'));
      expect(File(result.valueOrNull!).existsSync(), isTrue);
    });

    test(
      'names the copy from the whole path so folders cannot collide',
      () async {
        await store.materialise(LibraryPath.parse('A/Receipt.pdf'));
        await store.materialise(LibraryPath.parse('B/Receipt.pdf'));

        final destinations = channel.calls
            .where((call) => call.method == 'copyToCache')
            .map((call) => call['destinationPath'])
            .toSet();

        expect(destinations.length, 2);
      },
    );

    test('evicts the oldest copy beyond the limit', () async {
      final small = MediaStorePublicFileStore(
        channel: channel,
        cacheDirectory: cache,
        materialisedCacheLimit: 2,
      );

      final first = await small.materialise(LibraryPath.parse('A.pdf'));
      await small.materialise(LibraryPath.parse('B.pdf'));
      await small.materialise(LibraryPath.parse('C.pdf'));

      expect(File(first.valueOrNull!).existsSync(), isFalse);
    });

    test(
      're-materialising refreshes recency rather than duplicating',
      () async {
        final small = MediaStorePublicFileStore(
          channel: channel,
          cacheDirectory: cache,
          materialisedCacheLimit: 2,
        );

        final a = await small.materialise(LibraryPath.parse('A.pdf'));
        await small.materialise(LibraryPath.parse('B.pdf'));
        // Touching A makes B the oldest, so C should evict B and spare A.
        await small.materialise(LibraryPath.parse('A.pdf'));
        await small.materialise(LibraryPath.parse('C.pdf'));

        expect(File(a.valueOrNull!).existsSync(), isTrue);
      },
    );

    test('releasing deletes the cached copy', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      final materialised = await store.materialise(path);

      await store.releaseMaterialised(path);

      expect(File(materialised.valueOrNull!).existsSync(), isFalse);
    });

    test('a missing item maps to notFound', () async {
      channel.failures['copyToCache'] = const MediaStoreException(
        MediaStoreException.codeNotFound,
        'absent',
      );

      final result = await store.materialise(LibraryPath.parse('Absent.pdf'));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('rename and delete', () {
    test('rename sends both halves of each path', () async {
      await store.rename(
        LibraryPath.parse('A/Receipt.pdf'),
        LibraryPath.parse('B/Invoice.pdf'),
      );

      final call = channel.callTo('moveFile');
      expect(call['fromRelativePath'], 'Documents/DocForge/A/');
      expect(call['fromDisplayName'], 'Receipt.pdf');
      expect(call['toRelativePath'], 'Documents/DocForge/B/');
      expect(call['toDisplayName'], 'Invoice.pdf');
    });

    test('rename drops the stale cached copy', () async {
      final from = LibraryPath.parse('Receipt.pdf');
      final materialised = await store.materialise(from);

      await store.rename(from, LibraryPath.parse('Invoice.pdf'));

      expect(File(materialised.valueOrNull!).existsSync(), isFalse);
    });

    test('delete removes the item and its cached copy', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      final materialised = await store.materialise(path);

      final result = await store.delete(path);

      expect(result.isSuccess, isTrue);
      expect(channel.callTo('deleteFile')['displayName'], 'Receipt.pdf');
      expect(File(materialised.valueOrNull!).existsSync(), isFalse);
    });
  });

  group('totalBytes', () {
    test('sums every item in the tree', () async {
      await store.writeFile(
        LibraryPath.parse('A.pdf'),
        await sourceFile('a', contents: '12345'),
      );
      await store.writeFile(
        LibraryPath.parse('Invoices/B.pdf'),
        await sourceFile('b', contents: '123'),
      );

      expect((await store.totalBytes()).valueOrNull, 8);
    });
  });

  group('failure mapping', () {
    test('a full disk maps to storageFull', () async {
      channel.failures['writeFile'] = const MediaStoreException(
        MediaStoreException.codeStorageFull,
        'ENOSPC',
      );

      final result = await store.writeFile(
        LibraryPath.parse('A.pdf'),
        await sourceFile('a'),
      );

      expect(result.failureOrNull, isA<StorageFullFailure>());
    });

    test('an unknown platform code maps to storage', () {
      expect(
        mapMediaStoreError(const MediaStoreException('io_error', 'x')),
        isA<StorageFailure>(),
      );
    });

    test('anything else maps to unexpected', () {
      expect(mapMediaStoreError(StateError('x')), isA<UnexpectedFailure>());
    });
  });

  group('MediaStoreItem.fromMap', () {
    test('reads the channel form', () {
      final item = MediaStoreItem.fromMap(const {
        'relativePath': 'Documents/DocForge/',
        'displayName': 'A.pdf',
        'size': 12,
        'modified': 1750000000,
      });

      expect(item.displayName, 'A.pdf');
      expect(item.sizeBytes, 12);
      // MediaStore reports seconds; a millisecond reading would land in 1970.
      expect(item.modifiedAt!.year, greaterThan(2020));
    });

    test('tolerates a missing size and timestamp', () {
      final item = MediaStoreItem.fromMap(const {'displayName': 'A.pdf'});

      expect(item.sizeBytes, 0);
      expect(item.modifiedAt, isNull);
    });
  });
}
