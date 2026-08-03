import 'dart:io';

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory container;
  late FilesystemPublicFileStore store;

  setUp(() async {
    container = await Directory.systemTemp.createTemp('docforge_public_');
    store = FilesystemPublicFileStore(container);
    await store.initialise();
  });

  tearDown(() async {
    if (container.existsSync()) await container.delete(recursive: true);
  });

  Directory root() => Directory('${container.path}/DocForge');

  /// Writes a throwaway source file the store can copy in.
  Future<String> sourceFile(
    String name, {
    String contents = 'pdf-bytes',
  }) async {
    final file = File('${container.path}/$name');
    await file.writeAsString(contents);
    return file.path;
  }

  group('initialise', () {
    test('creates the library folder', () {
      expect(root().existsSync(), isTrue);
    });

    test('succeeds when the folder already exists', () async {
      final result = await store.initialise();

      expect(result.isSuccess, isTrue);
      expect(root().existsSync(), isTrue);
    });
  });

  group('writeFile', () {
    test('copies the source into the library root', () async {
      final path = LibraryPath.parse('Receipt.pdf');

      final result = await store.writeFile(path, await sourceFile('in.pdf'));

      expect(result.isSuccess, isTrue);
      expect(
        File('${root().path}/Receipt.pdf').readAsStringSync(),
        'pdf-bytes',
      );
    });

    test('creates missing parent folders', () async {
      final path = LibraryPath.parse('Invoices/2026/Receipt.pdf');

      await store.writeFile(path, await sourceFile('in.pdf'));

      expect(
        File('${root().path}/Invoices/2026/Receipt.pdf').existsSync(),
        isTrue,
      );
    });

    test('leaves the source untouched', () async {
      final source = await sourceFile('in.pdf');

      await store.writeFile(LibraryPath.parse('Receipt.pdf'), source);

      expect(File(source).existsSync(), isTrue);
    });

    test('returns notFound when the source is missing', () async {
      final result = await store.writeFile(
        LibraryPath.parse('Receipt.pdf'),
        '${container.path}/absent.pdf',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('overwrites an existing file', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      await store.writeFile(path, await sourceFile('a.pdf', contents: 'first'));

      await store.writeFile(
        path,
        await sourceFile('b.pdf', contents: 'second'),
      );

      expect(File('${root().path}/Receipt.pdf').readAsStringSync(), 'second');
    });
  });

  group('list', () {
    test('returns files and folders of one level only', () async {
      await store.createFolder(const ['Invoices']);
      await store.writeFile(
        LibraryPath.parse('Top.pdf'),
        await sourceFile('in.pdf'),
      );
      await store.writeFile(
        LibraryPath.parse('Invoices/Nested.pdf'),
        await sourceFile('in2.pdf'),
      );

      final entries = (await store.list(const [])).valueOrNull!;

      expect(entries.map((e) => e.name).toSet(), {'Invoices', 'Top.pdf'});
      expect(
        entries.firstWhere((e) => e.name == 'Invoices').kind,
        PublicEntryKind.folder,
      );
    });

    test('reports size and modified time for files', () async {
      await store.writeFile(
        LibraryPath.parse('Receipt.pdf'),
        await sourceFile('in.pdf', contents: '12345'),
      );

      final entry = (await store.list(const [])).valueOrNull!.single;

      expect(entry.sizeBytes, 5);
      expect(entry.modifiedAt, isNotNull);
    });

    test('carries the folder segments on nested entries', () async {
      await store.writeFile(
        LibraryPath.parse('Invoices/2026/Receipt.pdf'),
        await sourceFile('in.pdf'),
      );

      final entry = (await store.list(const [
        'Invoices',
        '2026',
      ])).valueOrNull!.single;

      expect(entry.folders, ['Invoices', '2026']);
      expect(entry.path!.relative, 'Invoices/2026/Receipt.pdf');
    });

    test('skips dot-files the platform leaves behind', () async {
      File('${root().path}/.DS_Store').writeAsStringSync('junk');

      expect((await store.list(const [])).valueOrNull, isEmpty);
    });

    test('returns notFound for a folder that does not exist', () async {
      final result = await store.list(const ['Absent']);

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('returns an empty list for an existing empty folder', () async {
      await store.createFolder(const ['Empty']);

      expect((await store.list(const ['Empty'])).valueOrNull, isEmpty);
    });
  });

  group('listRecursive', () {
    test('walks the whole tree with correct segments', () async {
      await store.writeFile(
        LibraryPath.parse('Top.pdf'),
        await sourceFile('a.pdf'),
      );
      await store.writeFile(
        LibraryPath.parse('Invoices/2026/Receipt.pdf'),
        await sourceFile('b.pdf'),
      );

      final entries = (await store.listRecursive(const [])).valueOrNull!;
      final files = entries.where((e) => !e.isFolder).toList();

      expect(files.map((e) => e.path!.relative).toSet(), {
        'Top.pdf',
        'Invoices/2026/Receipt.pdf',
      });
      expect(entries.where((e) => e.isFolder).map((e) => e.name).toSet(), {
        'Invoices',
        '2026',
      });
    });

    test('never exposes reserved Trash payloads', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      await store.writeFile(path, await sourceFile('trash.pdf'));
      await store.moveFileToTrash('trash-1', path);

      expect((await store.list(const [])).valueOrNull, isEmpty);
      expect((await store.listRecursive(const [])).valueOrNull, isEmpty);
      expect((await store.totalBytes()).valueOrNull, greaterThan(0));
    });
  });

  group('Trash lifecycle', () {
    test(
      'inventories and restores a recursive tree including unknown files',
      () async {
        await store.createFolder(const ['Projects', 'Empty']);
        await store.writeFile(
          LibraryPath.parse('Projects/Scan.pdf'),
          await sourceFile('scan.pdf', contents: '123'),
        );
        File('${root().path}/Projects/readme.txt').writeAsStringSync('abcd');

        final inventory = await store.inventory(folder: const ['Projects']);
        expect(inventory.valueOrNull!.documentCount, 1);
        expect(inventory.valueOrNull!.otherFileCount, 1);
        expect(inventory.valueOrNull!.folderCount, 1);
        expect(inventory.valueOrNull!.sizeInBytes, 7);

        await store.moveFolderToTrash('tree-1', const ['Projects']);
        expect(Directory('${root().path}/Projects').existsSync(), isFalse);
        expect((await store.trashPayloadExists('tree-1')).valueOrNull, isTrue);

        await store.restoreFolderFromTrash('tree-1', 'Projects', const [
          'Recovered Projects',
        ]);
        expect(
          File('${root().path}/Recovered Projects/readme.txt').existsSync(),
          isTrue,
        );
        expect(
          Directory('${root().path}/Recovered Projects/Empty').existsSync(),
          isTrue,
        );
      },
    );

    test('purge is idempotent', () async {
      await store.purgeTrashPayload('absent');
      expect((await store.purgeTrashPayload('absent')).isSuccess, isTrue);
    });
  });

  group('createFolder', () {
    test('creates nested folders', () async {
      final result = await store.createFolder(const ['Invoices', '2026']);

      expect(result.isSuccess, isTrue);
      expect(Directory('${root().path}/Invoices/2026').existsSync(), isTrue);
    });

    test('succeeds when the folder already exists', () async {
      await store.createFolder(const ['Invoices']);

      expect((await store.createFolder(const ['Invoices'])).isSuccess, isTrue);
    });

    test('refuses a segment that would escape the library', () async {
      final result = await store.createFolder(const ['..']);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(Directory('${container.path}/..').listSync(), isNotEmpty);
    });

    test('refuses a segment containing a separator', () async {
      expect(
        (await store.createFolder(const ['a/b'])).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });

  group('renameFolder', () {
    test('renames and keeps the contents', () async {
      await store.writeFile(
        LibraryPath.parse('Invoices/Receipt.pdf'),
        await sourceFile('in.pdf'),
      );

      final result = await store.renameFolder(const ['Invoices'], 'Bills');

      expect(result.isSuccess, isTrue);
      expect(File('${root().path}/Bills/Receipt.pdf').existsSync(), isTrue);
      expect(Directory('${root().path}/Invoices').existsSync(), isFalse);
    });

    test('refuses an illegal new name', () async {
      await store.createFolder(const ['Invoices']);

      expect(
        (await store.renameFolder(const ['Invoices'], '..')).failureOrNull,
        isA<ValidationFailure>(),
      );
    });

    test('refuses to rename the library root', () async {
      expect(
        (await store.renameFolder(const [], 'Other')).failureOrNull,
        isA<ValidationFailure>(),
      );
    });

    test('returns notFound for a missing folder', () async {
      expect(
        (await store.renameFolder(const ['Absent'], 'Other')).failureOrNull,
        isA<NotFoundFailure>(),
      );
    });
  });

  group('deleteFolder', () {
    test('removes the folder and its contents', () async {
      await store.writeFile(
        LibraryPath.parse('Invoices/Receipt.pdf'),
        await sourceFile('in.pdf'),
      );

      final result = await store.deleteFolder(const ['Invoices']);

      expect(result.isSuccess, isTrue);
      expect(Directory('${root().path}/Invoices').existsSync(), isFalse);
    });

    test('succeeds when already absent', () async {
      expect((await store.deleteFolder(const ['Absent'])).isSuccess, isTrue);
    });
  });

  group('materialise', () {
    test('returns the real path', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      await store.writeFile(path, await sourceFile('in.pdf'));

      final result = await store.materialise(path);

      expect(result.valueOrNull, '${root().path}/Receipt.pdf');
      expect(File(result.valueOrNull!).readAsStringSync(), 'pdf-bytes');
    });

    test('returns notFound for a missing file', () async {
      final result = await store.materialise(LibraryPath.parse('Absent.pdf'));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('releasing is a no-op that leaves the file in place', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      await store.writeFile(path, await sourceFile('in.pdf'));

      expect((await store.releaseMaterialised(path)).isSuccess, isTrue);
      expect(File('${root().path}/Receipt.pdf').existsSync(), isTrue);
    });
  });

  group('rename', () {
    test('moves a file between folders', () async {
      final from = LibraryPath.parse('Receipt.pdf');
      await store.writeFile(from, await sourceFile('in.pdf'));

      final result = await store.rename(
        from,
        LibraryPath.parse('Invoices/2026/Receipt.pdf'),
      );

      expect(result.isSuccess, isTrue);
      expect(
        File('${root().path}/Invoices/2026/Receipt.pdf').existsSync(),
        isTrue,
      );
      expect(File('${root().path}/Receipt.pdf').existsSync(), isFalse);
    });

    test('returns notFound for a missing source', () async {
      final result = await store.rename(
        LibraryPath.parse('Absent.pdf'),
        LibraryPath.parse('Other.pdf'),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('delete and exists', () {
    test('deletes a file', () async {
      final path = LibraryPath.parse('Receipt.pdf');
      await store.writeFile(path, await sourceFile('in.pdf'));

      expect((await store.exists(path)).valueOrNull, isTrue);
      expect((await store.delete(path)).isSuccess, isTrue);
      expect((await store.exists(path)).valueOrNull, isFalse);
    });

    test('deleting an absent file succeeds', () async {
      expect(
        (await store.delete(LibraryPath.parse('Absent.pdf'))).isSuccess,
        isTrue,
      );
    });
  });

  group('totalBytes', () {
    test('sums every file in the tree', () async {
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

    test('is zero before anything is written', () async {
      expect((await store.totalBytes()).valueOrNull, 0);
    });

    test('is zero when the root does not exist', () async {
      await root().delete(recursive: true);

      expect((await store.totalBytes()).valueOrNull, 0);
    });
  });

  group('mapFileSystemError', () {
    test('maps a full disk to storageFull', () {
      final failure = mapFileSystemError(
        const FileSystemException('write', '/x', OSError('ENOSPC', 28)),
      );

      expect(failure, isA<StorageFullFailure>());
    });

    test('maps a missing file to notFound', () {
      final failure = mapFileSystemError(
        const FileSystemException('read', '/x', OSError('ENOENT', 2)),
      );

      expect(failure, isA<NotFoundFailure>());
    });

    test('maps other I/O faults to storage', () {
      final failure = mapFileSystemError(
        const FileSystemException('read', '/x', OSError('EACCES', 13)),
      );

      expect(failure, isA<StorageFailure>());
    });

    test('maps an illegal path to validation', () {
      final failure = mapFileSystemError(
        const InvalidLibraryPath('..', 'traversal'),
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('maps anything else to unexpected', () {
      expect(mapFileSystemError(StateError('x')), isA<UnexpectedFailure>());
    });
  });
}
