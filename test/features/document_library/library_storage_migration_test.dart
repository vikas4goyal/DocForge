@Tags(['isar'])
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_forge/features/document_library/infrastructure/library_storage_migration.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  late Directory databaseDirectory;
  late Directory legacyContainer;
  late Directory publicContainer;
  late Isar isar;
  late FilesystemPublicFileStore store;
  late LibraryStorageMigration migration;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    databaseDirectory = await Directory.systemTemp.createTemp('docforge_db_');
    legacyContainer = await Directory.systemTemp.createTemp('docforge_old_');
    publicContainer = await Directory.systemTemp.createTemp('docforge_pub_');

    isar = await Isar.open([
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      OcrTextEntitySchema,
    ], directory: databaseDirectory.path);

    store = FilesystemPublicFileStore(publicContainer);
    await store.initialise();

    migration = LibraryStorageMigration(
      isar: isar,
      store: store,
      legacyDocumentsDirectory: legacyContainer,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    for (final directory in [
      databaseDirectory,
      legacyContainer,
      publicContainer,
    ]) {
      if (directory.existsSync()) await directory.delete(recursive: true);
    }
  });

  Directory legacyRoot() => Directory('${legacyContainer.path}/documents');
  Directory libraryRoot() => Directory('${publicContainer.path}/DocForge');

  /// Writes a layout-1 document: a record with no library path, and a private
  /// directory holding the PDF, a page image and a thumbnail.
  Future<DocumentEntity> seedLegacyDocument({
    required String uuid,
    required String title,
    String? folderUuid,
    bool withFile = true,
  }) async {
    if (withFile) {
      final directory = Directory('${legacyRoot().path}/$uuid')
        ..createSync(recursive: true);
      File('${directory.path}/document.pdf').writeAsStringSync('pdf:$uuid');
      Directory('${directory.path}/pages').createSync();
      File('${directory.path}/pages/p1.jpg').writeAsStringSync('page-bytes');
      Directory('${directory.path}/thumbnails').createSync();
      File('${directory.path}/thumbnails/p1.jpg').writeAsStringSync('thumb');
    }

    final entity = DocumentEntity()
      ..uuid = uuid
      ..title = title
      ..titleWords = DocumentEntity.titleWordsOf(title)
      ..createdAt = DateTime.utc(2026)
      ..updatedAt = DateTime.utc(2026)
      ..pageCount = 1
      ..sizeInBytes = 10
      ..folderPath = ''
      ..fileName = ''
      ..folderUuid = folderUuid
      ..isFavourite = true
      ..isArchived = false
      ..isProtected = false
      ..hasRecognisedText = false
      ..schemaVersion = 1;

    await isar.writeTxn(() => isar.documentEntitys.put(entity));
    return entity;
  }

  Future<void> seedLegacyFolder(String uuid, String name) async {
    final folder = FolderEntity()
      ..uuid = uuid
      ..name = name
      ..relativePath = ''
      ..createdAt = DateTime.utc(2026)
      ..schemaVersion = 1;
    await isar.writeTxn(() => isar.folderEntitys.put(folder));
  }

  Future<DocumentEntity?> reload(String uuid) =>
      isar.documentEntitys.filter().uuidEqualTo(uuid).findFirst();

  group('happy path', () {
    test('publishes the PDF into the library folder', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Invoice 2026');

      final report = await migration.run();

      expect(report.migrated, 1);
      expect(
        File('${libraryRoot().path}/Invoice 2026.pdf').readAsStringSync(),
        'pdf:a',
      );
    });

    test('rewrites the record with the library path', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Invoice 2026');

      await migration.run();

      final entity = await reload('a');
      expect(entity!.fileName, 'Invoice 2026.pdf');
      expect(entity.folderPath, '');
      expect(entity.schemaVersion, librarySchemaVersion);
    });

    test('preserves metadata the file cannot carry', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Invoice 2026');

      await migration.run();

      // Favourite status has nowhere to live in a PDF, so losing it here would
      // lose it permanently.
      expect((await reload('a'))!.isFavourite, isTrue);
    });

    test('deletes the private directory and its page images', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Invoice 2026');

      await migration.run();

      expect(Directory('${legacyRoot().path}/a').existsSync(), isFalse);
    });

    test('migrates several documents', () async {
      await seedLegacyDocument(uuid: 'a', title: 'One');
      await seedLegacyDocument(uuid: 'b', title: 'Two');
      await seedLegacyDocument(uuid: 'c', title: 'Three');

      final report = await migration.run();

      expect(report.migrated, 3);
      expect(libraryRoot().listSync().whereType<File>().length, 3);
    });
  });

  group('folders', () {
    test('creates a real directory per folder record', () async {
      await seedLegacyFolder('f1', 'Invoices');
      await seedLegacyDocument(uuid: 'a', title: 'One', folderUuid: 'f1');

      await migration.run();

      expect(Directory('${libraryRoot().path}/Invoices').existsSync(), isTrue);
      expect(
        File('${libraryRoot().path}/Invoices/One.pdf').existsSync(),
        isTrue,
      );
    });

    test('records the folder path on the document', () async {
      await seedLegacyFolder('f1', 'Invoices');
      await seedLegacyDocument(uuid: 'a', title: 'One', folderUuid: 'f1');

      await migration.run();

      expect((await reload('a'))!.folderPath, 'Invoices');
    });

    test('sanitises a folder name that is illegal on disk', () async {
      // Layout-1 folder names were never constrained to filesystem-safe
      // characters, so a legacy name can contain a separator.
      await seedLegacyFolder('f1', 'Invoices/2026');
      await seedLegacyDocument(uuid: 'a', title: 'One', folderUuid: 'f1');

      await migration.run();

      final folder = await isar.folderEntitys
          .filter()
          .uuidEqualTo('f1')
          .findFirst();
      expect(folder!.relativePath, 'Invoices_2026');
      // The name the user chose is kept; only the directory takes the safe one.
      expect(folder.name, 'Invoices/2026');
    });

    test(
      'de-duplicates folder names that sanitise to the same thing',
      () async {
        await seedLegacyFolder('f1', 'A/B');
        await seedLegacyFolder('f2', 'A:B');

        await migration.run();

        final paths = (await isar.folderEntitys.where().findAll())
            .map((folder) => folder.relativePath)
            .toSet();
        expect(paths, {'A_B', 'A_B (2)'});
      },
    );
  });

  group('name collisions', () {
    test('two documents with the same title get distinct files', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Invoice');
      await seedLegacyDocument(uuid: 'b', title: 'Invoice');

      await migration.run();

      final names = libraryRoot()
          .listSync()
          .whereType<File>()
          .map((file) => file.path.split('/').last)
          .toSet();
      expect(names, {'Invoice.pdf', 'Invoice (2).pdf'});
    });

    test('a title that is illegal on disk is sanitised', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Q1/Q2 report');

      await migration.run();

      expect((await reload('a'))!.fileName, 'Q1_Q2 report.pdf');
    });
  });

  group('missing source', () {
    test('drops the record and continues', () async {
      await seedLegacyDocument(uuid: 'gone', title: 'Absent', withFile: false);
      await seedLegacyDocument(uuid: 'a', title: 'Present');

      final report = await migration.run();

      expect(report.dropped, 1);
      expect(report.migrated, 1);
      expect(await reload('gone'), isNull);
      expect(await reload('a'), isNotNull);
    });
  });

  group('runs once', () {
    test('a second run does nothing', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Invoice');
      await migration.run();

      final second = await migration.run();

      expect(second.ranMigration, isFalse);
      expect(libraryRoot().listSync().whereType<File>().length, 1);
    });

    test(
      'a fresh install completes immediately and marks the layout',
      () async {
        final report = await migration.run();

        // It still *runs* — there is simply nothing to move — and writes the
        // marker so no later launch walks the tree again.
        expect(report.migrated, 0);
        expect(report.dropped, 0);
        expect(
          File('${legacyContainer.path}/.layout-version').existsSync(),
          isTrue,
        );
      },
    );

    test('the marker records the completed layout', () async {
      await seedLegacyDocument(uuid: 'a', title: 'Invoice');

      await migration.run();

      final marker = File('${legacyContainer.path}/.layout-version');
      expect(marker.readAsStringSync(), '2');
    });
  });

  group('interruption', () {
    test('resumes without duplicating what was already published', () async {
      await seedLegacyDocument(uuid: 'a', title: 'One');
      await seedLegacyDocument(uuid: 'b', title: 'Two');

      // Simulate a run that published 'a' and died before the marker: its
      // record already carries a library path, the other's does not.
      await store.writeFile(
        LibraryPath.parse('One.pdf'),
        '${legacyRoot().path}/a/document.pdf',
      );
      await isar.writeTxn(() async {
        final entity = await reload('a');
        entity!
          ..folderPath = ''
          ..fileName = 'One.pdf';
        await isar.documentEntitys.put(entity);
      });

      final report = await migration.run();

      expect(report.alreadyMigrated, 1);
      expect(report.migrated, 1);
      // Not 'One (2).pdf': the already-published document must not be copied
      // a second time under a suffixed name.
      final names = libraryRoot()
          .listSync()
          .whereType<File>()
          .map((file) => file.path.split('/').last)
          .toSet();
      expect(names, {'One.pdf', 'Two.pdf'});
    });

    test('a partial run leaves no marker, so it runs again', () async {
      await seedLegacyDocument(uuid: 'a', title: 'One');
      // The library root is removed, so publishing fails for every document.
      await libraryRoot().delete(recursive: true);
      File('${publicContainer.path}/DocForge').writeAsStringSync('not a dir');

      final report = await migration.run();

      expect(report.failed, 1);
      expect(
        File('${legacyRoot().path}/.layout-version').existsSync(),
        isFalse,
      );
      // The source is untouched, so the next launch can try again.
      expect(File('${legacyRoot().path}/a/document.pdf').existsSync(), isTrue);
    });
  });
}
