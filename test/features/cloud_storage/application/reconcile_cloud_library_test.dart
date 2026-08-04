import 'package:doc_scanly/app/cloud_library_reconciler.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../document_library/fakes.dart';

void main() {
  late ScriptedICloudPlatform platform;
  late FakeDocumentRepository documents;
  late FakeFolderRepository folders;
  late FakePageRepository pages;
  late ReconcileCloudLibrary reconcile;

  setUp(() {
    platform = ScriptedICloudPlatform();
    documents = FakeDocumentRepository();
    folders = FakeFolderRepository();
    pages = FakePageRepository();
    reconcile = ReconcileCloudLibrary(
      cloud: PlatformCloudContainerRepository(platform),
      documents: documents,
      folders: folders,
      pages: pages,
      clock: FixedClock(DateTime.utc(2026, 8, 4)),
      ids: SequentialIdGenerator(prefix: 'cloud'),
      batchSize: 2,
    );
  });

  tearDown(() => platform.dispose());

  test('indexes remote PDFs and folders without downloading bytes', () async {
    platform.replaceItems(const [
      ScriptedICloudItem(relativePath: 'Invoices', isDirectory: true),
      ScriptedICloudItem(
        relativePath: 'Invoices/A.pdf',
        availability: 'remote',
        resourceIdentifier: 'resource-a',
        sizeBytes: 42,
      ),
      ScriptedICloudItem(relativePath: '.docscanly-trash/Deleted.pdf'),
      ScriptedICloudItem(relativePath: '.docscanly-library.json'),
    ]);

    final outcome = (await reconcile()).valueOrNull!;
    final document = documents.documents.values.single;

    expect(outcome.added, 1);
    expect(outcome.foldersAdded, 1);
    expect(document.relativePath, 'Invoices/A.pdf');
    expect(document.cloudResourceIdentifier, 'resource-a');
    expect(document.contentAvailability, DocumentContentAvailability.remote);
    expect(platform.downloadRequests, isEmpty);
    expect(folders.folders.values.single.relativePath, 'Invoices');
  });

  test('stable resource identity preserves a record across rename', () async {
    documents = FakeDocumentRepository([
      _document(
        path: 'Old.pdf',
        resourceIdentifier: 'resource-a',
        availability: DocumentContentAvailability.available,
      ),
    ]);
    reconcile = ReconcileCloudLibrary(
      cloud: PlatformCloudContainerRepository(platform),
      documents: documents,
      folders: folders,
      pages: pages,
      clock: FixedClock(DateTime.utc(2026, 8, 4)),
      ids: SequentialIdGenerator(),
    );
    platform.replaceItems(const [
      ScriptedICloudItem(
        relativePath: 'Renamed.pdf',
        resourceIdentifier: 'resource-a',
      ),
    ]);

    final outcome = (await reconcile()).valueOrNull!;

    expect(outcome.updated, 1);
    expect(outcome.added, 0);
    expect(documents.documents.values.single.id, const DocumentId('doc-1'));
    expect(documents.documents.values.single.relativePath, 'Renamed.pdf');
  });

  test(
    'external deletion removes cloud metadata but preserves local rows',
    () async {
      documents = FakeDocumentRepository([
        _document(path: 'Cloud.pdf', resourceIdentifier: 'resource-a'),
        _document(path: 'Local.pdf', id: 'local-1'),
      ]);
      reconcile = ReconcileCloudLibrary(
        cloud: PlatformCloudContainerRepository(platform),
        documents: documents,
        folders: folders,
        pages: pages,
        clock: FixedClock(DateTime.utc(2026, 8, 4)),
        ids: SequentialIdGenerator(),
      );

      final outcome = (await reconcile()).valueOrNull!;

      expect(outcome.removed, 1);
      expect(documents.documents.keys, [const DocumentId('local-1')]);
    },
  );

  test(
    'thousands of entries are batched and duplicate triggers coalesce',
    () async {
      platform.replaceItems([
        for (var index = 0; index < 3001; index++)
          ScriptedICloudItem(
            relativePath: 'File $index.pdf',
            availability: 'remote',
            resourceIdentifier: 'resource-$index',
          ),
      ]);

      final outcomes = await Future.wait([reconcile(), reconcile()]);

      expect(outcomes.first.valueOrNull!.added, 3001);
      expect(outcomes.last.valueOrNull!.added, 3001);
      expect(platform.listRequests, 1);
      expect(documents.documents, hasLength(3001));
    },
  );

  test(
    'simultaneous same-path resources get stable non-overwriting names',
    () async {
      platform.replaceItems(const [
        ScriptedICloudItem(
          relativePath: 'Invoices/Quarterly.pdf',
          availability: 'remote',
          resourceIdentifier: 'resource-a',
          sizeBytes: 10,
        ),
        ScriptedICloudItem(
          relativePath: 'Invoices/Quarterly.pdf',
          availability: 'remote',
          resourceIdentifier: 'resource-b',
          sizeBytes: 20,
        ),
      ]);

      final first = (await reconcile()).valueOrNull!;
      final firstDocuments = documents.documents.values.toList()
        ..sort((a, b) => a.relativePath.compareTo(b.relativePath));

      expect(first.added, 2);
      expect(firstDocuments.map((document) => document.relativePath), [
        'Invoices/Quarterly (Conflict resource).pdf',
        'Invoices/Quarterly.pdf',
      ]);
      expect(
        firstDocuments.map((document) => document.cloudRelativePath).toSet(),
        {'Invoices/Quarterly.pdf'},
      );
      expect(
        firstDocuments.map((document) => document.cloudResourceIdentifier),
        ['resource-b', 'resource-a'],
      );

      final second = (await reconcile()).valueOrNull!;

      expect(second.added, 0);
      expect(second.updated, 0);
      expect(documents.documents, hasLength(2));
    },
  );
}

Document _document({
  required String path,
  String id = 'doc-1',
  String? resourceIdentifier,
  DocumentContentAvailability availability = DocumentContentAvailability.remote,
}) => Document(
  id: DocumentId(id),
  title: path,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  pageCount: 1,
  sizeInBytes: 1,
  libraryPath: LibraryPath.parse(path),
  cloudResourceIdentifier: resourceIdentifier,
  contentAvailability: availability,
);
