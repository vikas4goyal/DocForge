import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_forge/features/document_library/domain/library_rules.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _now = DateTime.utc(2026, 8);
const _storageFailure = Failure.storage();
final _storageMessage = _storageFailure.presentation.message;

void main() {
  late FakeDocumentRepository documents;
  late FakeFolderRepository folders;
  late FakePageRepository pages;
  late FakeDocumentFileStore files;
  late InMemorySecureStore secure;
  late Clock clock;
  late IdGenerator ids;

  setUp(() {
    documents = FakeDocumentRepository();
    folders = FakeFolderRepository();
    pages = FakePageRepository();
    files = FakeDocumentFileStore();
    secure = InMemorySecureStore();
    clock = FixedClock(_now);
    ids = SequentialIdGenerator(prefix: 'new');
  });

  DocumentListCubit buildList({
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) => DocumentListCubit(
    LoadDocuments(documents),
    ToggleFavourite(documents, clock),
    ArchiveDocument(documents, clock),
    RestoreDocument(documents, clock),
    filter: filter,
    folderId: folderId,
  );

  DocumentDetailCubit buildDetail(DocumentId id) => DocumentDetailCubit(
    id,
    LoadDocumentDetail(documents, pages),
    RenameDocument(documents, clock),
    MoveDocument(documents, clock),
    ToggleFavourite(documents, clock),
    ArchiveDocument(documents, clock),
    RestoreDocument(documents, clock),
    DuplicateDocument(documents, pages, files, clock, ids),
    PurgeDocument(documents, pages, files, secure),
  );

  FolderCubit buildFolders() {
    final move = MoveDocument(documents, clock);
    final purge = PurgeDocument(documents, pages, files, secure);

    return FolderCubit(
      LoadFolders(folders),
      CreateFolder(folders, clock, ids),
      RenameFolder(folders),
      DeleteFolder(folders, documents, move, purge),
    );
  }

  group('DocumentListCubit', () {
    test('starts in the initial status with the filter it was given', () {
      final cubit = buildList(filter: DocumentFilter.favourites);

      expect(cubit.state.status, LoadStatus.initial);
      expect(cubit.state.filter, DocumentFilter.favourites);
      expect(cubit.state.documents, isEmpty);
    });

    blocTest<DocumentListCubit, DocumentListState>(
      'loads through loading into ready',
      setUp: () => documents.documents.addAll({
        for (final d in sampleDocuments(3)) d.id: d,
      }),
      build: buildList,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DocumentListState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentListState>()
            .having((s) => s.status, 'status', LoadStatus.ready)
            .having((s) => s.documents, 'documents', hasLength(3))
            .having((s) => s.hasMore, 'hasMore', isFalse),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'reports empty rather than ready when nothing matches',
      build: buildList,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DocumentListState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentListState>()
            .having((s) => s.status, 'status', LoadStatus.empty)
            .having((s) => s.documents, 'documents', isEmpty),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'surfaces a load failure as a message with a retry offered',
      setUp: () => documents.failure = _storageFailure,
      build: buildList,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DocumentListState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentListState>()
            .having((s) => s.status, 'status', LoadStatus.failure)
            .having((s) => s.message, 'message', _storageMessage)
            .having((s) => s.canRetry, 'canRetry', isTrue),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'a retry after a failure recovers to ready',
      setUp: () {
        documents.failure = _storageFailure;
        documents.documents.addAll({
          for (final d in sampleDocuments(2)) d.id: d,
        });
      },
      build: buildList,
      act: (cubit) async {
        await cubit.load();
        documents.failure = null;
        await cubit.load();
      },
      skip: 2,
      expect: () => [
        isA<DocumentListState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentListState>()
            .having((s) => s.status, 'status', LoadStatus.ready)
            .having((s) => s.documents, 'documents', hasLength(2))
            // The stale error message is gone, not carried into the new state.
            .having((s) => s.message, 'message', isNull),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'reports more pages remaining when the library exceeds one page',
      setUp: () => documents.documents.addAll({
        for (final d in sampleDocuments(LoadDocuments.pageSize + 5)) d.id: d,
      }),
      build: buildList,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DocumentListState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentListState>()
            .having(
              (s) => s.documents,
              'documents',
              hasLength(LoadDocuments.pageSize),
            )
            .having((s) => s.hasMore, 'hasMore', isTrue),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'loadMore appends the next page without discarding the first',
      setUp: () => documents.documents.addAll({
        for (final d in sampleDocuments(LoadDocuments.pageSize + 5)) d.id: d,
      }),
      build: buildList,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 2,
      expect: () => [
        isA<DocumentListState>().having(
          (s) => s.isLoadingMore,
          'isLoadingMore',
          isTrue,
        ),
        isA<DocumentListState>()
            .having(
              (s) => s.documents,
              'documents',
              hasLength(LoadDocuments.pageSize + 5),
            )
            .having((s) => s.hasMore, 'hasMore', isFalse)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'loadMore does nothing when no further page exists',
      setUp: () => documents.documents.addAll({
        for (final d in sampleDocuments(2)) d.id: d,
      }),
      build: buildList,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 2,
      expect: () => <DocumentListState>[],
    );

    test('loadMore is ignored while a page is already in flight', () async {
      documents.documents.addAll({
        for (final d in sampleDocuments(LoadDocuments.pageSize + 5)) d.id: d,
      });
      final cubit = buildList();
      await cubit.load();

      // Both calls are issued before either completes, which is what a scroll
      // listener firing repeatedly at the bottom of the list does. Only one
      // page may be appended, or rows appear twice.
      await Future.wait([cubit.loadMore(), cubit.loadMore()]);

      expect(cubit.state.documents, hasLength(LoadDocuments.pageSize + 5));
      await cubit.close();
    });

    blocTest<DocumentListCubit, DocumentListState>(
      'a failed extra page keeps the rows already on screen',
      setUp: () => documents.documents.addAll({
        for (final d in sampleDocuments(LoadDocuments.pageSize + 5)) d.id: d,
      }),
      build: buildList,
      act: (cubit) async {
        await cubit.load();
        documents.failure = _storageFailure;
        await cubit.loadMore();
      },
      skip: 3,
      expect: () => [
        isA<DocumentListState>()
            .having(
              (s) => s.documents,
              'documents',
              hasLength(LoadDocuments.pageSize),
            )
            .having((s) => s.message, 'message', _storageMessage)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'changing the sort reloads from the first page',
      setUp: () => documents.documents.addAll({
        for (final d in sampleDocuments(3)) d.id: d,
      }),
      build: buildList,
      act: (cubit) => cubit.changeSort(DocumentSort.titleAscending),
      expect: () => [
        isA<DocumentListState>().having(
          (s) => s.sort,
          'sort',
          DocumentSort.titleAscending,
        ),
        isA<DocumentListState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentListState>()
            .having((s) => s.status, 'status', LoadStatus.ready)
            .having((s) => s.sort, 'sort', DocumentSort.titleAscending),
      ],
    );

    blocTest<DocumentListCubit, DocumentListState>(
      'selecting the sort already in use does nothing',
      build: buildList,
      act: (cubit) => cubit.changeSort(DocumentSort.modifiedDescending),
      expect: () => <DocumentListState>[],
    );

    test('favouriting persists and the list reflects it', () async {
      documents.documents[sampleDocument.id] = sampleDocument;
      final cubit = buildList();
      await cubit.load();

      await cubit.toggleFavourite(sampleDocument.id);

      expect(cubit.state.documents.single.isFavourite, isTrue);
      await cubit.close();
    });

    test('archiving removes the document from the default list', () async {
      documents.documents[sampleDocument.id] = sampleDocument;
      final cubit = buildList();
      await cubit.load();

      await cubit.archive(sampleDocument.id);

      // Not merely absent from the list — the reload applied the visibility
      // rule, so the list is empty rather than showing a stale row.
      expect(cubit.state.documents, isEmpty);
      expect(cubit.state.status, LoadStatus.empty);
      await cubit.close();
    });

    test('restoring returns the document to the main list', () async {
      documents.documents[archivedDocument.id] = archivedDocument;
      final cubit = buildList(filter: DocumentFilter.archived);
      await cubit.load();

      await cubit.restore(archivedDocument.id);

      expect(cubit.state.documents, isEmpty);

      final main = buildList();
      await main.load();
      expect(main.state.documents, hasLength(1));

      await cubit.close();
      await main.close();
    });

    test(
      'a failed action surfaces a message and leaves the list alone',
      () async {
        documents.documents[sampleDocument.id] = sampleDocument;
        final cubit = buildList();
        await cubit.load();
        documents.failure = _storageFailure;

        await cubit.toggleFavourite(sampleDocument.id);

        expect(cubit.state.message, _storageMessage);
        expect(cubit.state.documents, hasLength(1));
        await cubit.close();
      },
    );

    test('the favourites filter shows only unarchived favourites', () async {
      documents.documents.addAll({
        sampleDocument.id: sampleDocument,
        favouriteDocument.id: favouriteDocument,
        archivedDocument.id: archivedDocument,
      });
      final cubit = buildList(filter: DocumentFilter.favourites);

      await cubit.load();

      expect(cubit.state.documents.map((d) => d.id), [favouriteDocument.id]);
      await cubit.close();
    });
  });

  group('DocumentDetailCubit', () {
    setUp(() {
      documents.documents[sampleDocument.id] = sampleDocument;
      pages.pages[sampleDocument.id] = samplePages(2);
    });

    blocTest<DocumentDetailCubit, DocumentDetailState>(
      'loads the document with its pages',
      build: () => buildDetail(sampleDocument.id),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DocumentDetailState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentDetailState>()
            .having((s) => s.status, 'status', LoadStatus.ready)
            .having((s) => s.document, 'document', sampleDocument)
            .having((s) => s.pages, 'pages', hasLength(2)),
      ],
    );

    blocTest<DocumentDetailCubit, DocumentDetailState>(
      'a missing document fails rather than rendering nothing',
      build: () => buildDetail(const DocumentId('absent')),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DocumentDetailState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<DocumentDetailState>()
            .having((s) => s.status, 'status', LoadStatus.failure)
            .having((s) => s.message, 'message', isNotEmpty),
      ],
    );

    test('renaming updates the title and the modified date', () async {
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();

      await cubit.rename('Renamed');

      expect(cubit.state.document?.title, 'Renamed');
      expect(cubit.state.document?.updatedAt, _now);
      expect(cubit.state.document?.createdAt, sampleDocument.createdAt);
      await cubit.close();
    });

    test('an empty rename is refused and the title is retained', () async {
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();

      await cubit.rename('   ');

      expect(cubit.state.document?.title, sampleDocument.title);
      expect(
        cubit.state.message,
        const Failure.validation(
          issue: ValidationIssue.emptyName,
        ).presentation.message,
      );
      await cubit.close();
    });

    test('moving changes the folder assignment', () async {
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();

      await cubit.move(sampleFolder.id);

      expect(cubit.state.document?.folderId, sampleFolder.id);
      await cubit.close();
    });

    test('moving to no folder unfiles the document', () async {
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        folderId: sampleFolder.id,
      );
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();

      await cubit.move(null);

      expect(cubit.state.document?.folderId, isNull);
      await cubit.close();
    });

    test('archiving then restoring round-trips the flag', () async {
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();

      await cubit.archive();
      expect(cubit.state.document?.isArchived, isTrue);

      await cubit.restore();
      expect(cubit.state.document?.isArchived, isFalse);
      await cubit.close();
    });

    test('duplicating returns an independent copy', () async {
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();

      final copy = await cubit.duplicate();

      expect(copy, isNotNull);
      expect(copy!.id, isNot(sampleDocument.id));
      expect(copy.title, isNot(sampleDocument.title));
      // The screen still shows the original, which is what the user has open.
      expect(cubit.state.document?.id, sampleDocument.id);
      await cubit.close();
    });

    test('deleting marks the screen as gone rather than reloading', () async {
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();

      await cubit.delete();

      expect(cubit.state.isDeleted, isTrue);
      expect(cubit.state.isWorking, isFalse);
      expect(documents.documents, isEmpty);
      await cubit.close();
    });

    test('a failed delete leaves the screen in place with a message', () async {
      final cubit = buildDetail(sampleDocument.id);
      await cubit.load();
      files.failure = _storageFailure;

      await cubit.delete();

      expect(cubit.state.isDeleted, isFalse);
      expect(cubit.state.message, _storageMessage);
      // The record survives: nothing was half-removed.
      expect(documents.documents, hasLength(1));
      await cubit.close();
    });

    test('a page-read failure still shows the metadata', () async {
      pages.pages.remove(sampleDocument.id);
      final cubit = buildDetail(sampleDocument.id);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.document, sampleDocument);
      expect(cubit.state.pages, isEmpty);
      await cubit.close();
    });
  });

  group('FolderCubit', () {
    blocTest<FolderCubit, FolderState>(
      'reports empty when no folder exists',
      build: buildFolders,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<FolderState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<FolderState>()
            .having((s) => s.status, 'status', LoadStatus.empty)
            .having((s) => s.folders, 'folders', isEmpty),
      ],
    );

    blocTest<FolderCubit, FolderState>(
      'loads folders into ready',
      setUp: () =>
          folders.folders.addAll({for (final f in sampleFolders(2)) f.id: f}),
      build: buildFolders,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<FolderState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<FolderState>()
            .having((s) => s.status, 'status', LoadStatus.ready)
            .having((s) => s.folders, 'folders', hasLength(2)),
      ],
    );

    blocTest<FolderCubit, FolderState>(
      'surfaces a load failure',
      setUp: () => folders.failure = _storageFailure,
      build: buildFolders,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<FolderState>().having(
          (s) => s.status,
          'status',
          LoadStatus.loading,
        ),
        isA<FolderState>()
            .having((s) => s.status, 'status', LoadStatus.failure)
            .having((s) => s.message, 'message', _storageMessage),
      ],
    );

    test('creating a folder adds it with a zero document count', () async {
      final cubit = buildFolders();

      final created = await cubit.create('Receipts');

      expect(created, isTrue);
      expect(cubit.state.folders.single.name, 'Receipts');
      expect(cubit.state.folders.single.documentCount, 0);
      await cubit.close();
    });

    test(
      'a duplicate name is refused beside the field, not as an error',
      () async {
        final cubit = buildFolders();
        await cubit.create('Receipts');

        final created = await cubit.create('receipts');

        expect(created, isFalse);
        expect(
          cubit.state.validationMessage,
          const Failure.validation(
            issue: ValidationIssue.duplicateFolderName,
          ).presentation.message,
        );
        // A correctable name must not look like a failed screen.
        expect(cubit.state.message, isNull);
        expect(cubit.state.status, isNot(LoadStatus.failure));
        await cubit.close();
      },
    );

    test('an empty name is refused with a validation message', () async {
      final cubit = buildFolders();

      final created = await cubit.create('  ');

      expect(created, isFalse);
      expect(cubit.state.validationMessage, isNotNull);
      await cubit.close();
    });

    test(
      'a storage failure surfaces as a screen error, not a field error',
      () async {
        folders.failure = _storageFailure;
        final cubit = buildFolders();

        await cubit.create('Receipts');

        expect(cubit.state.message, _storageMessage);
        expect(cubit.state.validationMessage, isNull);
        await cubit.close();
      },
    );

    test('renaming a folder changes the name everywhere', () async {
      final cubit = buildFolders();
      await cubit.create('Receipts');
      final id = cubit.state.folders.single.id;

      final renamed = await cubit.rename(id, 'Invoices');

      expect(renamed, isTrue);
      expect(cubit.state.folders.single.name, 'Invoices');
      await cubit.close();
    });

    test(
      'renaming to a name another folder already holds is refused',
      () async {
        final cubit = buildFolders();
        await cubit.create('Receipts');
        await cubit.create('Invoices');
        final id = cubit.state.folders
            .firstWhere((f) => f.name == 'Invoices')
            .id;

        final renamed = await cubit.rename(id, 'Receipts');

        expect(renamed, isFalse);
        expect(cubit.state.validationMessage, isNotNull);
        await cubit.close();
      },
    );

    test('deleting with moveDocumentsOut keeps the documents', () async {
      final cubit = buildFolders();
      await cubit.create('Receipts');
      final id = cubit.state.folders.single.id;
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        folderId: id,
      );

      final deleted = await cubit.delete(
        id,
        FolderDeletionStrategy.moveDocumentsOut,
      );

      expect(deleted, isTrue);
      expect(cubit.state.folders, isEmpty);
      expect(documents.documents[sampleDocument.id]?.folderId, isNull);
      await cubit.close();
    });

    test('deleting with deleteDocuments removes them too', () async {
      final cubit = buildFolders();
      await cubit.create('Receipts');
      final id = cubit.state.folders.single.id;
      documents.documents[sampleDocument.id] = sampleDocument.copyWith(
        folderId: id,
      );

      final deleted = await cubit.delete(
        id,
        FolderDeletionStrategy.deleteDocuments,
      );

      expect(deleted, isTrue);
      expect(documents.documents, isEmpty);
      await cubit.close();
    });

    test('clearing validation removes the stale complaint', () async {
      final cubit = buildFolders();
      await cubit.create('  ');
      expect(cubit.state.validationMessage, isNotNull);

      cubit.clearValidation();

      expect(cubit.state.validationMessage, isNull);
      await cubit.close();
    });
  });
}
