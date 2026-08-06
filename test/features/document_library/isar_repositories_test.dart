@Tags(['isar'])
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/trash.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_scanly/features/document_library/infrastructure/repositories/isar_library_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  late Directory directory;
  late Isar isar;
  late IsarDocumentRepository documents;
  late IsarFolderRepository folders;
  late IsarPageRepository pages;
  late IsarTrashRepository trash;

  setUpAll(() async {
    // Isar needs its native binaries; on a test VM they are downloaded once to
    // a temp location rather than bundled with the app.
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('docscanly_isar');
    isar = await Isar.open([
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      TrashEntitySchema,
    ], directory: directory.path);
    documents = IsarDocumentRepository(isar);
    folders = IsarFolderRepository(isar);
    pages = IsarPageRepository(isar);
    trash = IsarTrashRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  group('DocumentRepository', () {
    test('saves and reads back a document', () async {
      await documents.save(sampleDocument);

      final found = await documents.findById(sampleDocument.id);

      expect(found.valueOrNull, sampleDocument);
    });

    test(
      'round-trips cloud identity and remote content availability',
      () async {
        final remote = sampleDocument.copyWith(
          cloudResourceIdentifier: 'resource-sample',
          contentAvailability: DocumentContentAvailability.remote,
        );
        await documents.save(remote);

        final found = await documents.findById(remote.id);

        expect(found.valueOrNull, remote);
      },
    );

    test('reports not found for an unknown id', () async {
      final found = await documents.findById(const DocumentId('nope'));

      expect(found.failureOrNull, isA<NotFoundFailure>());
    });

    test('updates rather than duplicating on re-save', () async {
      await documents.save(sampleDocument);
      await documents.save(sampleDocument.copyWith(title: 'Renamed'));

      final all = await documents.query();

      expect(all.valueOrNull, hasLength(1));
      expect(all.valueOrNull!.single.title, 'Renamed');
    });

    test('deletes a document', () async {
      await documents.save(sampleDocument);

      await documents.delete(sampleDocument.id);

      expect((await documents.query()).valueOrNull, isEmpty);
    });

    test('excludes archived documents from the default query', () async {
      await documents.save(sampleDocument);
      await documents.save(archivedDocument);

      final visible = await documents.query();

      expect(visible.valueOrNull, hasLength(1));
      expect(visible.valueOrNull!.single.id, sampleDocument.id);
    });

    test(
      'excludes trashed documents from every active filter and folder count',
      () async {
        await folders.save(sampleFolder);
        await documents.save(
          sampleDocument.copyWith(
            folderId: sampleFolder.id,
            trashId: const TrashId('trash-1'),
            trashedAt: DateTime.utc(2026),
          ),
        );

        expect((await documents.query()).valueOrNull, isEmpty);
        expect(
          (await documents.query(filter: DocumentFilter.archived)).valueOrNull,
          isEmpty,
        );
        expect((await folders.all()).valueOrNull!.single.documentCount, 0);
      },
    );

    test('returns only archived documents for the archive filter', () async {
      await documents.save(sampleDocument);
      await documents.save(archivedDocument);

      final archived = await documents.query(filter: DocumentFilter.archived);

      expect(archived.valueOrNull!.single.id, archivedDocument.id);
    });

    test('returns only non-archived favourites', () async {
      await documents.save(sampleDocument);
      await documents.save(favouriteDocument);
      await documents.save(
        favouriteDocument.copyWith(
          id: const DocumentId('doc-archived-fav'),
          isArchived: true,
        ),
      );

      final result = await documents.query(filter: DocumentFilter.favourites);

      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.single.id, favouriteDocument.id);
    });

    test('filters by folder', () async {
      await documents.save(sampleDocument);
      await documents.save(favouriteDocument);

      final result = await documents.query(
        filter: DocumentFilter.folder,
        folderId: const FolderId('folder-1'),
      );

      expect(result.valueOrNull!.single.id, favouriteDocument.id);
    });

    test('orders by modified date descending by default', () async {
      for (final document in sampleDocuments(3)) {
        await documents.save(document);
      }

      final result = await documents.query();

      final dates = result.valueOrNull!.map((d) => d.updatedAt).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
    });

    test('orders by title ascending', () async {
      await documents.save(sampleDocument.copyWith(title: 'Zebra'));
      await documents.save(
        sampleDocument.copyWith(id: const DocumentId('d2'), title: 'Alpha'),
      );

      final result = await documents.query(sort: DocumentSort.titleAscending);

      expect(result.valueOrNull!.map((d) => d.title), ['Alpha', 'Zebra']);
    });

    test('paginates with limit and offset', () async {
      for (final document in sampleDocuments(10)) {
        await documents.save(document);
      }

      final firstPage = await documents.query(limit: 4);
      final secondPage = await documents.query(limit: 4, offset: 4);

      expect(firstPage.valueOrNull, hasLength(4));
      expect(secondPage.valueOrNull, hasLength(4));
      // Pages must not overlap or the list would repeat rows as it scrolls.
      expect(
        firstPage.valueOrNull!
            .map((d) => d.id)
            .toSet()
            .intersection(secondPage.valueOrNull!.map((d) => d.id).toSet()),
        isEmpty,
      );
    });

    test('counts documents matching a filter', () async {
      await documents.save(sampleDocument);
      await documents.save(archivedDocument);

      expect((await documents.count()).valueOrNull, 1);
      expect(
        (await documents.count(filter: DocumentFilter.archived)).valueOrNull,
        1,
      );
    });

    test('totals stored size across every document', () async {
      await documents.save(sampleDocument.copyWith(sizeInBytes: 100));
      await documents.save(
        sampleDocument.copyWith(id: const DocumentId('d2'), sizeInBytes: 250),
      );

      expect((await documents.totalSizeInBytes()).valueOrNull, 350);
    });

    test('round-trips every field including the optional ones', () async {
      final full = sampleDocument.copyWith(
        folderId: const FolderId('folder-9'),
        isFavourite: true,
        isProtected: true,
        hasRecognisedText: true,
      );

      await documents.save(full);

      expect((await documents.findById(full.id)).valueOrNull, full);
    });

    test('indexes title words for search', () async {
      // Search depends on the tokenised list, so verify it is derived on write
      // rather than left empty.
      await documents.save(sampleDocument.copyWith(title: 'Invoice — Acme'));

      final entity = await isar.documentEntitys
          .filter()
          .uuidEqualTo(sampleDocument.id.value)
          .findFirst();

      expect(entity!.titleWords, ['invoice', 'acme']);
    });
  });

  group('TrashRepository', () {
    final deletedAt = DateTime.utc(2026, 8, 3);
    late TrashEntry entry;

    setUp(() {
      entry = TrashEntry(
        id: const TrashId('trash-1'),
        kind: TrashEntryKind.document,
        displayName: 'Receipt',
        originalRelativePath: 'Receipt.pdf',
        deletedAt: deletedAt,
        expiresAt: TrashEntry.expiryFor(deletedAt),
        inventory: const TrashInventory(documentCount: 1, sizeInBytes: 12),
        documentIds: const [DocumentId('doc-1')],
      );
    });

    test('round-trips, replaces by uuid and deletes idempotently', () async {
      await trash.save(entry);
      await trash.save(entry.copyWith(displayName: 'Renamed'));
      expect((await trash.all()).valueOrNull, hasLength(1));
      expect(
        (await trash.findById(entry.id)).valueOrNull!.displayName,
        'Renamed',
      );
      await trash.delete(entry.id);
      expect((await trash.delete(entry.id)).isSuccess, isTrue);
    });

    test('orders newest first and expires inclusively', () async {
      await trash.save(entry);
      await trash.save(
        entry.copyWith(
          id: const TrashId('trash-2'),
          deletedAt: deletedAt.add(const Duration(hours: 1)),
          expiresAt: entry.expiresAt.add(const Duration(hours: 1)),
        ),
      );
      expect(
        (await trash.all()).valueOrNull!.first.id,
        const TrashId('trash-2'),
      );
      expect((await trash.expiredAt(entry.expiresAt)).valueOrNull, [entry]);
      expect((await trash.count()).valueOrNull, 2);
    });
  });

  group('FolderRepository', () {
    test('saves and reads back a folder', () async {
      await folders.save(sampleFolder);

      final found = await folders.findById(sampleFolder.id);

      expect(found.valueOrNull?.name, sampleFolder.name);
    });

    test('reports not found for an unknown id', () async {
      expect(
        (await folders.findById(const FolderId('nope'))).failureOrNull,
        isA<NotFoundFailure>(),
      );
    });

    test('finds a folder by name for duplicate checking', () async {
      await folders.save(sampleFolder);

      final found = await folders.findByName(sampleFolder.name);

      expect(found.valueOrNull?.id, sampleFolder.id);
    });

    test('returns null when no folder has that name', () async {
      expect((await folders.findByName('Nothing')).valueOrNull, isNull);
    });

    test('computes document counts rather than storing them', () async {
      await folders.save(sampleFolder);
      await documents.save(sampleDocument.copyWith(folderId: sampleFolder.id));
      await documents.save(
        sampleDocument.copyWith(
          id: const DocumentId('d2'),
          folderId: sampleFolder.id,
        ),
      );

      final all = await folders.all();

      expect(all.valueOrNull!.single.documentCount, 2);
    });

    test('excludes archived documents from folder counts', () async {
      await folders.save(sampleFolder);
      await documents.save(sampleDocument.copyWith(folderId: sampleFolder.id));
      await documents.save(
        sampleDocument.copyWith(
          id: const DocumentId('d2'),
          folderId: sampleFolder.id,
          isArchived: true,
        ),
      );

      final all = await folders.all();

      expect(all.valueOrNull!.single.documentCount, 1);
    });

    test('excludes trashed folders from lists and duplicate checks', () async {
      await folders.save(
        sampleFolder.copyWith(
          trashId: const TrashId('trash-1'),
          trashedAt: DateTime.utc(2026),
        ),
      );

      expect((await folders.all()).valueOrNull, isEmpty);
      expect((await folders.findByName(sampleFolder.name)).valueOrNull, isNull);
      expect(
        (await folders.findByRelativePath(
          sampleFolder.relativePath,
        )).valueOrNull,
        isNull,
      );
    });

    test('reports a count that updates as documents move', () async {
      await folders.save(sampleFolder);
      final document = sampleDocument.copyWith(folderId: sampleFolder.id);
      await documents.save(document);

      await documents.save(document.copyWith(folderId: null));

      expect((await folders.all()).valueOrNull!.single.documentCount, 0);
    });

    test('deletes a folder', () async {
      await folders.save(sampleFolder);

      await folders.delete(sampleFolder.id);

      expect((await folders.all()).valueOrNull, isEmpty);
    });
  });

  group('PageRepository', () {
    test('stores pages in order', () async {
      await pages.replaceAll(const DocumentId('doc-1'), samplePages(3));

      final stored = await pages.forDocument(const DocumentId('doc-1'));

      expect(stored.valueOrNull!.map((p) => p.order), [0, 1, 2]);
    });

    test('replaces rather than appending', () async {
      await pages.replaceAll(const DocumentId('doc-1'), samplePages(5));

      await pages.replaceAll(const DocumentId('doc-1'), samplePages(2));

      // Replacing wholesale is what keeps ordering unambiguous after a reorder.
      expect(
        (await pages.forDocument(const DocumentId('doc-1'))).valueOrNull,
        hasLength(2),
      );
    });

    test('keeps pages of different documents separate', () async {
      await pages.replaceAll(const DocumentId('doc-1'), samplePages(2));
      await pages.replaceAll(const DocumentId('doc-2'), [
        const DocumentPage(
          id: PageId('other-page'),
          documentId: DocumentId('doc-2'),
          order: 0,
          imagePath: '/documents/doc-2/page-0.jpg',
        ),
      ]);

      expect(
        (await pages.forDocument(const DocumentId('doc-1'))).valueOrNull,
        hasLength(2),
      );
      expect(
        (await pages.forDocument(const DocumentId('doc-2'))).valueOrNull,
        hasLength(1),
      );
    });

    test('round-trips rotation and enhancement settings', () async {
      const page = DocumentPage(
        id: PageId('p1'),
        documentId: DocumentId('doc-1'),
        order: 0,
        imagePath: '/p1.jpg',
        rotation: PageRotation.threeQuarter,
        enhancement: EnhancementSettings(
          filter: EnhancementFilter.magicColour,
          brightness: 0.25,
          contrast: -0.1,
          sharpen: 0.5,
          shadowRemoval: true,
        ),
      );

      await pages.replaceAll(const DocumentId('doc-1'), [page]);

      final stored = (await pages.forDocument(
        const DocumentId('doc-1'),
      )).valueOrNull!;
      expect(stored.single, page);
    });

    test('deletes every page of a document', () async {
      await pages.replaceAll(const DocumentId('doc-1'), samplePages(3));

      await pages.deleteForDocument(const DocumentId('doc-1'));

      expect(
        (await pages.forDocument(const DocumentId('doc-1'))).valueOrNull,
        isEmpty,
      );
    });

    test('returns an empty list for a document with no pages', () async {
      expect(
        (await pages.forDocument(const DocumentId('unknown'))).valueOrNull,
        isEmpty,
      );
    });
  });

  group('offline behaviour', () {
    test('every operation completes without a network connection', () async {
      // Nothing here can reach the network; the test documents that the library
      // is fully local, which the offline-first requirement depends on.
      await documents.save(sampleDocument);
      await folders.save(sampleFolder);
      await pages.replaceAll(sampleDocument.id, samplePages(2));

      expect((await documents.query()).isSuccess, isTrue);
      expect((await folders.all()).isSuccess, isTrue);
      expect((await pages.forDocument(sampleDocument.id)).isSuccess, isTrue);
    });
  });
}
