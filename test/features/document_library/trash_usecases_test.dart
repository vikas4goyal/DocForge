import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/trash_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeDocumentRepository documents;
  late FakeTrashRepository trash;
  late FakeFolderRepository folders;
  late InMemoryPublicFileStore store;
  late FixedClock clock;
  late SequentialIdGenerator ids;

  setUp(() {
    documents = FakeDocumentRepository([sampleDocument]);
    trash = FakeTrashRepository();
    folders = FakeFolderRepository();
    store = InMemoryPublicFileStore();
    store.files[sampleDocument.relativePath] = 'pdf';
    clock = FixedClock(DateTime.utc(2026, 8, 3));
    ids = SequentialIdGenerator(prefix: 'trash');
  });

  test(
    'moves a document out of active queries and keeps it recoverable',
    () async {
      final result = await MoveDocumentToTrash(
        documents,
        trash,
        store,
        clock,
        ids,
      )(sampleDocument.id);

      expect(result.isSuccess, isTrue);
      expect((await documents.query()).valueOrNull, isEmpty);
      expect(
        documents.documents[sampleDocument.id]!.trashId,
        const TrashId('trash-1'),
      );
      expect((await store.list(const [])).valueOrNull, isEmpty);
      expect((await store.trashPayloadExists('trash-1')).valueOrNull, isTrue);
    },
  );

  test(
    'moves unknown files and nested empty folders with a folder tree',
    () async {
      store.folderPaths.addAll({
        'Projects',
        'Projects/Nested',
        'Projects/Empty',
      });
      store.files['Projects/Nested/readme.txt'] = 'unknown';
      await folders.save(
        Folder(
          id: const FolderId('projects'),
          name: 'Projects',
          relativePath: 'Projects',
          createdAt: DateTime.utc(2026),
        ),
      );
      await folders.save(
        Folder(
          id: const FolderId('nested-folder'),
          name: 'Nested',
          relativePath: 'Projects/Nested',
          createdAt: DateTime.utc(2026),
        ),
      );
      final nestedDocument = sampleDocument.copyWith(
        id: const DocumentId('nested'),
        libraryPath: LibraryPath.parse('Projects/Nested/Scan.pdf'),
      );
      documents.documents[nestedDocument.id] = nestedDocument;
      store.files[nestedDocument.relativePath] = 'pdf';

      final result = await MoveFolderTreeToTrash(
        documents,
        folders,
        trash,
        store,
        clock,
        ids,
      )(const ['Projects']);

      expect(result.valueOrNull!.inventory.documentCount, 1);
      expect(result.valueOrNull!.inventory.otherFileCount, 1);
      expect(result.valueOrNull!.inventory.folderCount, 2);
      expect(result.valueOrNull!.folderIds, hasLength(2));
      expect((await folders.all()).valueOrNull, isEmpty);
      expect(
        (await store.list(const [])).valueOrNull!.map((entry) => entry.name),
        [sampleDocument.fileName],
      );
      expect(documents.documents[nestedDocument.id]!.trashId, isNotNull);

      await RestoreTrashEntry(trash, documents, folders, store)(
        result.valueOrNull!.id,
      );
      expect((await folders.all()).valueOrNull, hasLength(2));
      expect(
        (await folders.findByRelativePath('Projects/Nested')).valueOrNull,
        isNotNull,
      );
    },
  );

  test(
    'restore uses a recovered suffix on conflict and preserves metadata',
    () async {
      final moved = await MoveDocumentToTrash(
        documents,
        trash,
        store,
        clock,
        ids,
      )(sampleDocument.id);
      store.files[sampleDocument.relativePath] = 'replacement';

      final restored = await RestoreTrashEntry(
        trash,
        documents,
        folders,
        store,
      )(moved.valueOrNull!.id);

      expect(restored.valueOrNull, 'Invoice — Acme Ltd (Recovered 1).pdf');
      final document = documents.documents[sampleDocument.id]!;
      expect(document.trashId, isNull);
      expect(document.isFavourite, sampleDocument.isFavourite);
      expect(document.isArchived, sampleDocument.isArchived);
      expect(
        document.libraryPath.fileName,
        'Invoice — Acme Ltd (Recovered 1).pdf',
      );
      expect(trash.entries, isEmpty);
    },
  );

  test('expiry includes the exact thirty-day boundary', () async {
    final moved = await MoveDocumentToTrash(
      documents,
      trash,
      store,
      clock,
      ids,
    )(sampleDocument.id);
    final expired = await trash.expiredAt(moved.valueOrNull!.expiresAt);
    expect(expired.valueOrNull, [moved.valueOrNull]);
  });

  test(
    'document move refuses read, inventory and storage failures safely',
    () async {
      final move = MoveDocumentToTrash(documents, trash, store, clock, ids);

      documents.failure = const Failure.storage();
      expect(
        (await move(sampleDocument.id)).failureOrNull,
        const Failure.storage(),
      );
      documents.failure = null;

      store.failures['inventory'] = const Failure.storage();
      expect(
        (await move(sampleDocument.id)).failureOrNull,
        const Failure.storage(),
      );
      store.failures.remove('inventory');

      store.failures['moveFileToTrash'] = const Failure.storage();
      expect(
        (await move(sampleDocument.id)).failureOrNull,
        const Failure.storage(),
      );
      expect(documents.documents[sampleDocument.id]!.trashId, isNull);
    },
  );

  test(
    'moving an already trashed document returns its existing entry',
    () async {
      final move = MoveDocumentToTrash(documents, trash, store, clock, ids);
      final first = await move(sampleDocument.id);

      final second = await move(sampleDocument.id);

      expect(second.valueOrNull, first.valueOrNull);
      expect(trash.entries, hasLength(1));
    },
  );

  test('empty Trash permanently removes every payload and record', () async {
    final secondDocument = sampleDocument.copyWith(
      id: const DocumentId('second'),
      libraryPath: LibraryPath.parse('Second.pdf'),
    );
    documents.documents[secondDocument.id] = secondDocument;
    store.files[secondDocument.relativePath] = 'second-pdf';
    final move = MoveDocumentToTrash(documents, trash, store, clock, ids);
    await move(sampleDocument.id);
    await move(secondDocument.id);
    final purge = PurgeTrashEntry(
      trash,
      folders,
      store,
      PurgeDocument(
        documents,
        FakePageRepository(),
        store,
        FakeDocumentFileStore(),
        InMemorySecureStore(),
      ),
    );

    final result = await EmptyTrash(trash, purge)();

    expect(result.isSuccess, isTrue);
    expect(trash.entries, isEmpty);
    expect(documents.documents, isEmpty);
    expect((await store.totalBytes()).valueOrNull, 0);
  });

  test('expiry purges an entry at the boundary and is idempotent', () async {
    final moved = await MoveDocumentToTrash(
      documents,
      trash,
      store,
      clock,
      ids,
    )(sampleDocument.id);
    final purge = PurgeTrashEntry(
      trash,
      folders,
      store,
      PurgeDocument(
        documents,
        FakePageRepository(),
        store,
        FakeDocumentFileStore(),
        InMemorySecureStore(),
      ),
    );
    final expire = ExpireTrash(
      trash,
      purge,
      FixedClock(moved.valueOrNull!.expiresAt),
    );

    expect((await expire()).isSuccess, isTrue);
    expect((await expire()).isSuccess, isTrue);
    expect(trash.entries, isEmpty);
  });

  test('bulk cleanup propagates a Trash repository read failure', () async {
    final purge = PurgeTrashEntry(
      trash,
      folders,
      store,
      PurgeDocument(
        documents,
        FakePageRepository(),
        store,
        FakeDocumentFileStore(),
        InMemorySecureStore(),
      ),
    );
    expect((await purge(const TrashId('already-removed'))).isSuccess, isTrue);
    trash.failure = const Failure.storage();

    expect(
      (await EmptyTrash(trash, purge)()).failureOrNull,
      const Failure.storage(),
    );
    expect(
      (await ExpireTrash(trash, purge, clock)()).failureOrNull,
      const Failure.storage(),
    );
  });
}
