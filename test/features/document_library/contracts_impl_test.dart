import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/infrastructure/library_contracts_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _now = DateTime.utc(2026, 8);

void main() {
  late FakeDocumentRepository documents;
  late FakeFolderRepository folders;
  late FakePageRepository pages;
  late Clock clock;

  setUp(() {
    documents = FakeDocumentRepository([sampleDocument]);
    folders = FakeFolderRepository([sampleFolder]);
    pages = FakePageRepository();
    clock = FixedClock(_now);
  });

  group('LibraryDocumentReader', () {
    DocumentReader build() => LibraryDocumentReader(documents, pages);

    test('finds a document by identifier', () async {
      final result = await build().findById(sampleDocument.id);

      expect(result.valueOrNull, sampleDocument);
    });

    test('a missing document fails rather than returning null', () async {
      final result = await build().findById(const DocumentId('absent'));

      expect(result.failureOrNull, const Failure.notFound());
    });

    test('applies the same visibility rule as the library itself', () async {
      documents.documents[archivedDocument.id] = archivedDocument;

      final visible = await build().query();

      // The archived document is excluded here exactly as it is in the
      // library's own lists — a consumer must not see a different library.
      expect(visible.valueOrNull?.map((d) => d.id), [sampleDocument.id]);
    });

    test('honours limit and offset for incremental loading', () async {
      documents.documents.addAll({
        for (final d in sampleDocuments(10)) d.id: d,
      });

      final firstPage = await build().query(limit: 4);
      final secondPage = await build().query(limit: 4, offset: 4);

      expect(firstPage.valueOrNull, hasLength(4));
      expect(secondPage.valueOrNull, hasLength(4));
      expect(
        firstPage.valueOrNull!
            .map((d) => d.id)
            .toSet()
            .intersection(secondPage.valueOrNull!.map((d) => d.id).toSet()),
        isEmpty,
      );
    });

    test('returns the pages of a document', () async {
      pages.pages[sampleDocument.id] = samplePages(3);

      final result = await build().pagesOf(sampleDocument.id);

      expect(result.valueOrNull, hasLength(3));
    });
  });

  group('LibraryDocumentWriter', () {
    DocumentWriter build() => LibraryDocumentWriter(documents, pages, clock);

    test('stores the document and its pages together', () async {
      final result = await build().save(sampleDocument, samplePages(2));

      expect(result.isSuccess, isTrue);
      expect(documents.documents[sampleDocument.id], isNotNull);
      expect(pages.pages[sampleDocument.id], hasLength(2));
    });

    test('takes the page count from the pages actually written', () async {
      // The caller's record claims a different count; the pages are the truth.
      final result = await build().save(
        sampleDocument.copyWith(pageCount: 99),
        samplePages(2),
      );

      expect(result.valueOrNull?.pageCount, 2);
    });

    test('refreshes the modified date but never the creation date', () async {
      final result = await build().save(sampleDocument, samplePages(1));

      expect(result.valueOrNull?.updatedAt, _now);
      expect(result.valueOrNull?.createdAt, sampleDocument.createdAt);
    });

    test('updateMetadata refreshes the modified date', () async {
      final result = await build().updateMetadata(
        sampleDocument.copyWith(title: 'Renamed'),
      );

      expect(result.valueOrNull?.title, 'Renamed');
      expect(result.valueOrNull?.updatedAt, _now);
      expect(result.valueOrNull?.createdAt, sampleDocument.createdAt);
    });

    test('a failed record write leaves no orphaned pages', () async {
      documents.failure = const Failure.storage();

      final result = await build().save(sampleDocument, samplePages(2));

      expect(result.isFailure, isTrue);
      // Pages belonging to a document that was never stored would be
      // unreachable and never cleaned up.
      expect(pages.pages, isEmpty);
    });
  });

  group('LibraryFolderReader', () {
    FolderReader build() => LibraryFolderReader(folders);

    test('returns every folder', () async {
      final result = await build().all();

      expect(result.valueOrNull, hasLength(1));
    });

    test('finds a folder by identifier', () async {
      final result = await build().findById(sampleFolder.id);

      expect(result.valueOrNull?.name, sampleFolder.name);
    });

    test('a missing folder fails', () async {
      final result = await build().findById(const FolderId('absent'));

      expect(result.failureOrNull, const Failure.notFound());
    });
  });

  group('LibraryStorageSummaryReader', () {
    late InMemoryPublicFileStore store;

    setUp(() => store = InMemoryPublicFileStore());

    StorageSummaryReader build() =>
        LibraryStorageSummaryReader(ComputeStorageSummary(documents, store));

    test('reports bytes from the library and the document count', () async {
      store.files['Big.pdf'] = 'x' * 4096;
      documents.documents[archivedDocument.id] = archivedDocument;

      final result = await build().summary();

      expect(result.valueOrNull?.totalBytes, 4096);
      // Archived documents still occupy storage, so they are counted.
      expect(result.valueOrNull?.documentCount, 2);
    });

    test('propagates a storage failure rather than reporting zero', () async {
      store.failures['totalBytes'] = const Failure.storage();

      final result = await build().summary();

      // Reporting zero would tell the user their documents take no space.
      expect(result.isFailure, isTrue);
    });
  });
}
