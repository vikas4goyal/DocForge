import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_scanly/features/document_library/domain/document_duplicate.dart';
import 'package:doc_scanly/features/document_library/domain/library_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _now = DateTime.utc(2026, 8);

void main() {
  late FakeDocumentRepository documents;
  late FakeFolderRepository folders;
  late FakePageRepository pages;
  late FakeDocumentFileStore files;
  late InMemoryPublicFileStore store;
  late InMemorySecureStore secure;
  late Clock clock;
  late IdGenerator ids;

  setUp(() {
    documents = FakeDocumentRepository([sampleDocument]);
    folders = FakeFolderRepository();
    pages = FakePageRepository();
    files = FakeDocumentFileStore();
    store = InMemoryPublicFileStore();
    // Every operation that copies or reads a document needs its file to exist:
    // the record is an index entry, and the library folder is the truth.
    store.files[sampleDocument.relativePath] = 'pdf-bytes';
    secure = InMemorySecureStore();
    clock = FixedClock(_now);
    ids = SequentialIdGenerator(prefix: 'new');
  });

  group('RenameDocument', () {
    test('renames and refreshes the modified date', () async {
      final result = await RenameDocument(documents, clock, store)(
        sampleDocument.id,
        'Renamed',
      );

      expect(result.valueOrNull?.title, 'Renamed');
      expect(result.valueOrNull?.updatedAt, _now);
    });

    test('never changes the creation date', () async {
      final result = await RenameDocument(documents, clock, store)(
        sampleDocument.id,
        'Renamed',
      );

      expect(result.valueOrNull?.createdAt, sampleDocument.createdAt);
    });

    test('trims incidental whitespace', () async {
      final result = await RenameDocument(documents, clock, store)(
        sampleDocument.id,
        '  Spaced  ',
      );

      expect(result.valueOrNull?.title, 'Spaced');
    });

    test('rejects an empty name and keeps the existing title', () async {
      final result = await RenameDocument(documents, clock, store)(
        sampleDocument.id,
        '   ',
      );

      expect(result.isFailure, isTrue);
      expect(
        documents.documents[sampleDocument.id]!.title,
        sampleDocument.title,
      );
    });

    test('reports not found for an unknown document', () async {
      final result = await RenameDocument(documents, clock, store)(
        const DocumentId('nope'),
        'x',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('MoveDocument', () {
    test('moves the authoritative PDF into the selected real folder', () async {
      final destination = sampleFolder.copyWith(relativePath: 'Filed/Policies');
      folders.folders[destination.id] = destination;
      store.folderPaths.addAll(['Filed', 'Filed/Policies']);

      final result = await MoveDocument(documents, clock, store, folders)(
        sampleDocument.id,
        destination.id,
      );

      expect(
        result.valueOrNull?.relativePath,
        'Filed/Policies/Invoice — Acme Ltd.pdf',
      );
      expect(store.files.containsKey(sampleDocument.relativePath), isFalse);
      expect(store.files.containsKey(result.valueOrNull!.relativePath), isTrue);
    });

    test('refuses a destination collision without moving the source', () async {
      final destination = sampleFolder.copyWith(relativePath: 'Filed');
      folders.folders[destination.id] = destination;
      store.folderPaths.add('Filed');
      store.files['Filed/${sampleDocument.fileName}'] = 'occupied';

      final result = await MoveDocument(documents, clock, store, folders)(
        sampleDocument.id,
        destination.id,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(store.files.containsKey(sampleDocument.relativePath), isTrue);
    });

    test('moves a document into a folder', () async {
      final result = await MoveDocument(documents, clock)(
        sampleDocument.id,
        const FolderId('folder-1'),
      );

      expect(result.valueOrNull?.folderId, const FolderId('folder-1'));
      expect(result.valueOrNull?.updatedAt, _now);
    });

    test('unfiles a document when given no folder', () async {
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        folderId: const FolderId('folder-1'),
      );

      final result = await MoveDocument(documents, clock)(
        sampleDocument.id,
        null,
      );

      // copyWith cannot clear a nullable field, so this guards the rebuild.
      expect(result.valueOrNull?.folderId, isNull);
      expect(result.valueOrNull?.isUnfiled, isTrue);
    });

    test('preserves every other field', () async {
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        isFavourite: true,
        isProtected: true,
        hasRecognisedText: true,
      );

      final moved = (await MoveDocument(documents, clock)(
        sampleDocument.id,
        const FolderId('f'),
      )).valueOrNull!;

      expect(moved.isFavourite, isTrue);
      expect(moved.isProtected, isTrue);
      expect(moved.hasRecognisedText, isTrue);
      expect(moved.pageCount, sampleDocument.pageCount);
    });
  });

  group('ToggleFavourite', () {
    test('marks and unmarks', () async {
      final marked = await ToggleFavourite(documents, clock)(sampleDocument.id);
      expect(marked.valueOrNull?.isFavourite, isTrue);

      final unmarked = await ToggleFavourite(documents, clock)(
        sampleDocument.id,
      );
      expect(unmarked.valueOrNull?.isFavourite, isFalse);
    });
  });

  group('ArchiveDocument and RestoreDocument', () {
    test('archiving hides a document from the default list', () async {
      await ArchiveDocument(documents, clock)(sampleDocument.id);

      expect((await documents.query()).valueOrNull, isEmpty);
    });

    test('restoring returns it to its previous folder', () async {
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        folderId: const FolderId('folder-1'),
      );
      await ArchiveDocument(documents, clock)(sampleDocument.id);

      final restored = await RestoreDocument(documents, clock)(
        sampleDocument.id,
      );

      expect(restored.valueOrNull?.isArchived, isFalse);
      // Archiving never cleared the folder, so it reappears where it was.
      expect(restored.valueOrNull?.folderId, const FolderId('folder-1'));
    });
  });

  group('DuplicateDocument', () {
    test('proposes a collision-safe name without mutating storage', () async {
      store.files['Invoice — Acme Ltd (copy).pdf'] = 'existing';
      final useCase = DuplicateDocument(documents, pages, store, clock, ids);

      final proposed = await useCase.propose(sampleDocument.id);

      expect(proposed.valueOrNull?.title, 'Invoice — Acme Ltd (copy) (2)');
      expect(documents.documents, hasLength(1));
    });

    test('uses the reviewed edited name and destination', () async {
      store.folderPaths.add('Reviewed');
      final request = DuplicateDocumentRequest(
        sourceDocumentId: sampleDocument.id,
        title: 'Policy copy',
        destinationFolders: const ['Reviewed'],
        destinationFolderId: const FolderId('reviewed'),
      );

      final result = await DuplicateDocument(
        documents,
        pages,
        store,
        clock,
        ids,
      ).execute(request);

      expect(result.valueOrNull?.title, 'Policy copy');
      expect(result.valueOrNull?.folderId, const FolderId('reviewed'));
      expect(result.valueOrNull?.relativePath, 'Reviewed/Policy copy.pdf');
    });

    test('refuses a reviewed collision without creating a record', () async {
      store.files['Taken.pdf'] = 'existing';
      final request = DuplicateDocumentRequest(
        sourceDocumentId: sampleDocument.id,
        title: 'Taken',
        destinationFolders: const [],
      );

      final result = await DuplicateDocument(
        documents,
        pages,
        store,
        clock,
        ids,
      ).execute(request);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(documents.documents, hasLength(1));
      expect(store.files, hasLength(2));
    });

    test('a repeated reviewed request creates exactly one copy', () async {
      final useCase = DuplicateDocument(documents, pages, store, clock, ids);
      final request = DuplicateDocumentRequest(
        sourceDocumentId: sampleDocument.id,
        title: 'Only once',
        destinationFolders: const [],
      );

      final first = await useCase.execute(request);
      final second = await useCase.execute(request);

      expect(first.isSuccess, isTrue);
      expect(second.isFailure, isTrue);
      expect(documents.documents, hasLength(2));
    });

    test('creates an independent copy', () async {
      final result = await DuplicateDocument(
        documents,
        pages,
        store,
        clock,
        ids,
      )(sampleDocument.id);

      final copy = result.valueOrNull!;
      expect(copy.id, isNot(sampleDocument.id));
      expect(copy.libraryPath, isNot(sampleDocument.libraryPath));
      expect(copy.title, 'Invoice — Acme Ltd (copy)');
      expect(documents.documents, hasLength(2));
    });

    test('copies the file rather than sharing it', () async {
      final copy = await DuplicateDocument(documents, pages, store, clock, ids)(
        sampleDocument.id,
      );

      // Two distinct files, not two records pointing at one: editing or
      // deleting either must not touch the other.
      expect(store.files, hasLength(2));
      expect(store.files.containsKey(copy.valueOrNull!.relativePath), isTrue);
      expect(store.files.containsKey(sampleDocument.relativePath), isTrue);
    });

    test('gives the copied pages fresh identifiers', () async {
      await pages.replaceAll(sampleDocument.id, samplePages(2));

      final copy = (await DuplicateDocument(
        documents,
        pages,
        store,
        clock,
        ids,
      )(sampleDocument.id)).valueOrNull!;

      final copiedPages = (await pages.forDocument(copy.id)).valueOrNull!;
      final originalIds = samplePages(2).map((p) => p.id).toSet();

      expect(copiedPages, hasLength(2));
      // Sharing a page row would let editing one document change the other.
      expect(
        copiedPages.map((p) => p.id).toSet().intersection(originalIds),
        isEmpty,
      );
      expect(copiedPages.every((p) => p.documentId == copy.id), isTrue);
    });

    test('does not create a record when copying the file fails', () async {
      store.failures['writeFile'] = const Failure.storageFull();

      final result = await DuplicateDocument(
        documents,
        pages,
        store,
        clock,
        ids,
      )(sampleDocument.id);

      expect(result.failureOrNull, isA<StorageFullFailure>());
      expect(documents.documents, hasLength(1));
    });
  });

  group('PurgeDocument', () {
    test('removes the record, pages, files and password', () async {
      await pages.replaceAll(sampleDocument.id, samplePages(2));
      await secure.write(
        SecureStorageKeys.pdfPassword(sampleDocument.id.value),
        'hunter2',
      );

      final result = await PurgeDocument(
        documents,
        pages,
        store,
        files,
        secure,
      )(sampleDocument.id);

      expect(result.isSuccess, isTrue);
      expect(documents.documents, isEmpty);
      expect((await pages.forDocument(sampleDocument.id)).valueOrNull, isEmpty);
      expect(files.deleted, contains(sampleDocument.id));
      // A password must never outlive the document it protected.
      expect(secure.values, isEmpty);
    });

    test('keeps the record when file removal fails', () async {
      files.failure = const Failure.storage();

      final result = await PurgeDocument(
        documents,
        pages,
        store,
        files,
        secure,
      )(sampleDocument.id);

      expect(result.isFailure, isTrue);
      // An orphaned file is recoverable; a record pointing at deleted files
      // renders as a broken document the user cannot fix.
      expect(documents.documents, hasLength(1));
    });

    test('stops when the password cannot be removed', () async {
      secure.failNextOperation = true;

      final result = await PurgeDocument(
        documents,
        pages,
        store,
        files,
        secure,
      )(sampleDocument.id);

      expect(result.failureOrNull, isA<SecureStorageFailure>());
      expect(documents.documents, hasLength(1));
    });
  });

  group('ComputeStorageSummary', () {
    test('reports bytes from the library and counts every document', () async {
      store.files.clear();
      store.files['Big.pdf'] = 'x' * 4096;
      documents.documents[archivedDocument.id] = archivedDocument;

      final summary = await ComputeStorageSummary(documents, store)();

      expect(summary.valueOrNull?.totalBytes, 4096);
      // Archived documents still occupy storage, so they are counted.
      expect(summary.valueOrNull?.documentCount, 2);
    });

    test('reports an empty library as zero', () async {
      final summary = await ComputeStorageSummary(
        FakeDocumentRepository(),
        InMemoryPublicFileStore(),
      )();

      expect(summary.valueOrNull?.totalBytes, 0);
      expect(summary.valueOrNull?.documentCount, 0);
    });

    test('fails when the library folder cannot be read', () async {
      store.failures['totalBytes'] = const Failure.storage();

      expect(
        (await ComputeStorageSummary(documents, store)()).isFailure,
        isTrue,
      );
    });
  });

  group('CreateFolder', () {
    test('creates a folder', () async {
      final result = await CreateFolder(folders, clock, ids)('Receipts');

      expect(result.valueOrNull?.name, 'Receipts');
      expect(result.valueOrNull?.createdAt, _now);
      expect(result.valueOrNull?.documentCount, 0);
    });

    test('rejects an empty name', () async {
      expect((await CreateFolder(folders, clock, ids)('  ')).isFailure, isTrue);
      expect(folders.folders, isEmpty);
    });

    test('rejects a duplicate name', () async {
      await CreateFolder(folders, clock, ids)('Receipts');

      final second = await CreateFolder(folders, clock, ids)('Receipts');

      expect(second.isFailure, isTrue);
      expect(folders.folders, hasLength(1));
    });

    test('treats names as case-insensitive for duplicates', () async {
      await CreateFolder(folders, clock, ids)('Receipts');

      // Two folders differing only in case are indistinguishable in a list.
      expect(
        (await CreateFolder(folders, clock, ids)('receipts')).isFailure,
        isTrue,
      );
    });
  });

  group('RenameFolder', () {
    test('renames a folder', () async {
      final created = (await CreateFolder(folders, clock, ids)(
        'Receipts',
      )).valueOrNull!;

      final renamed = await RenameFolder(folders)(created.id, 'Invoices');

      expect(renamed.valueOrNull?.name, 'Invoices');
    });

    test('allows renaming a folder to its own current name', () async {
      final created = (await CreateFolder(folders, clock, ids)(
        'Receipts',
      )).valueOrNull!;

      expect(
        (await RenameFolder(folders)(created.id, 'Receipts')).isSuccess,
        isTrue,
      );
    });

    test('rejects a name belonging to another folder', () async {
      await CreateFolder(folders, clock, ids)('Receipts');
      final second = (await CreateFolder(folders, clock, ids)(
        'Invoices',
      )).valueOrNull!;

      expect(
        (await RenameFolder(folders)(second.id, 'Receipts')).isFailure,
        isTrue,
      );
    });

    test('rejects an empty name', () async {
      final created = (await CreateFolder(folders, clock, ids)(
        'Receipts',
      )).valueOrNull!;

      expect((await RenameFolder(folders)(created.id, ' ')).isFailure, isTrue);
    });

    test('propagates a duplicate-name lookup failure', () async {
      folders.failure = const Failure.storage();

      expect(
        (await RenameFolder(folders)(
          const FolderId('folder'),
          'Receipts',
        )).failureOrNull,
        isA<StorageFailure>(),
      );
    });
  });

  group('DeleteFolder', () {
    late DeleteFolder deleteFolder;
    late FolderId folderId;

    setUp(() async {
      folderId = (await CreateFolder(folders, clock, ids)(
        'Receipts',
      )).valueOrNull!.id;

      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        folderId: folderId,
      );

      deleteFolder = DeleteFolder(
        folders,
        documents,
        MoveDocument(documents, clock),
        PurgeDocument(documents, pages, store, files, secure),
      );
    });

    test('moving documents out keeps every document', () async {
      final result = await deleteFolder(
        folderId,
        FolderDeletionStrategy.moveDocumentsOut,
      );

      expect(result.isSuccess, isTrue);
      expect(folders.folders, isEmpty);
      // Tidying folders must never destroy work.
      expect(documents.documents, hasLength(1));
      expect(documents.documents.values.single.isUnfiled, isTrue);
    });

    test('deleting documents removes them with the folder', () async {
      final result = await deleteFolder(
        folderId,
        FolderDeletionStrategy.deleteDocuments,
      );

      expect(result.isSuccess, isTrue);
      expect(folders.folders, isEmpty);
      expect(documents.documents, isEmpty);
    });

    test('deletes an empty folder', () async {
      final empty = (await CreateFolder(folders, clock, ids)(
        'Empty',
      )).valueOrNull!;

      final result = await deleteFolder(
        empty.id,
        FolderDeletionStrategy.moveDocumentsOut,
      );

      expect(result.isSuccess, isTrue);
      expect(folders.folders.containsKey(empty.id), isFalse);
    });

    test(
      'stops and keeps the folder when a document cannot be moved',
      () async {
        documents.failure = const Failure.storage();

        final result = await deleteFolder(
          folderId,
          FolderDeletionStrategy.moveDocumentsOut,
        );

        expect(result.isFailure, isTrue);
        // A partial delete leaves the user unable to tell what survived.
        expect(folders.folders, hasLength(1));
      },
    );
  });

  group('LoadFolders', () {
    test('returns every folder', () async {
      await CreateFolder(folders, clock, ids)('A');
      await CreateFolder(folders, clock, ids)('B');

      expect((await LoadFolders(folders)()).valueOrNull, hasLength(2));
    });

    test('propagates a read failure', () async {
      folders.failure = const Failure.storage();

      expect((await LoadFolders(folders)()).isFailure, isTrue);
    });
  });
}
