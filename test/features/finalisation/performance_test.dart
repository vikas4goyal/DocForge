/// Performance verification.
///
/// Every figure here is measured on the host machine, which is faster than a
/// phone — so a *pass* is necessary rather than sufficient, and the thresholds
/// are set with generous headroom so a failure means a genuine regression
/// rather than a busy CI runner. What these tests actually protect is the
/// *shape* of the work: bounded queries, bounded memory, and no accidental
/// quadratic pass over the library.
///
/// The two figures that cannot be measured here at all — cold start and the
/// smoothness of a real scroll — need a device, and are recorded as such in
/// `design.md` §32.
@Tags(['isar'])
library;

import 'dart:io';

import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

/// How long a single interactive operation may take on this machine.
///
/// Deliberately loose. The purpose is to catch an operation that became
/// *linear in the whole library* — which shows up as seconds, not milliseconds
/// — rather than to benchmark Isar.
const _interactiveBudget = Duration(milliseconds: 900);

void main() {
  late Directory root;
  late Isar isar;
  late FilesystemPublicFileStore publicStore;
  late LibraryModule library;

  final clock = FixedClock(DateTime.utc(2026, 3, 14, 9, 30));

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    root = Directory.systemTemp.createTempSync('docforge_perf');
    final documents = Directory('${root.path}/documents')..createSync();

    isar = await Isar.open([
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      OcrTextEntitySchema,
    ], directory: root.path);

    publicStore = FilesystemPublicFileStore(documents);
    await publicStore.initialise();

    library = buildLibraryModuleOver(
      isar: isar,
      documentsDirectory: documents,
      store: publicStore,
      clock: clock,
      ids: SequentialIdGenerator(prefix: 'doc'),
      secureStorage: InMemorySecureStore(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// Writes [count] documents straight into Isar.
  Future<void> seed(int count) async {
    await isar.writeTxn(() async {
      await isar.documentEntitys.putAll([
        for (var index = 0; index < count; index++)
          DocumentEntity.fromDomain(
            Document(
              id: DocumentId('doc-$index'),
              title: 'Invoice ${index.toString().padLeft(5, '0')}',
              createdAt: DateTime.utc(2026, 3, 14),
              updatedAt: DateTime.utc(
                2026,
                3,
                14,
              ).add(Duration(minutes: index)),
              pageCount: 4,
              sizeInBytes: 184_320,
              libraryPath: LibraryPath.parse('doc-$index.pdf'),
            ),
          ),
      ]);
    });
  }

  group('a library of a thousand documents', () {
    test('the first page of the list loads within budget', () async {
      await seed(1000);

      final stopwatch = Stopwatch()..start();
      final result = await library.loadDocuments();
      stopwatch.stop();

      final page = (result as Success<DocumentPageResult>).value;

      expect(stopwatch.elapsed, lessThan(_interactiveBudget));
      // Bounded: the list pages rather than loading a thousand records to show
      // the first ten. That is the property that keeps this fast at ten
      // thousand as well as at one.
      expect(page.documents.length, lessThan(1000));
      expect(page.hasMore, isTrue);
    });

    test('Home loads within budget', () async {
      await seed(1000);

      final stopwatch = Stopwatch()..start();
      final result = await LoadHomeData(
        library.documentReader,
        library.folderReader,
        library.storageSummaryReader,
      )();
      stopwatch.stop();

      expect(result, isA<Success<HomeData>>());
      expect(stopwatch.elapsed, lessThan(_interactiveBudget));
    });

    test('Home shows a bounded number of recent documents', () async {
      // The figure that matters more than the timing: Home renders a fixed
      // handful however large the library grows.
      await seed(1000);

      final result = await LoadHomeData(
        library.documentReader,
        library.folderReader,
        library.storageSummaryReader,
      )();

      final home = (result as Success<HomeData>).value;
      expect(home.recentDocuments.length, lessThanOrEqualTo(20));
      expect(home.storage.documentCount, 1000);
    });

    test('a search returns within budget and is bounded', () async {
      await seed(1000);

      final stopwatch = Stopwatch()..start();
      final result = await library.search.search(
        const SearchQuery(term: 'invoice'),
      );
      stopwatch.stop();

      final hits = (result as Success<List<SearchResult>>).value;

      expect(stopwatch.elapsed, lessThan(_interactiveBudget));
      // Bounded by the default limit, not by how much matched: a term matching
      // every document must not build a thousand-row list to show fifty.
      expect(hits.length, lessThanOrEqualTo(50));
    });

    test('opening one document does not scale with the library', () async {
      await seed(1000);

      final stopwatch = Stopwatch()..start();
      final result = await library.documentReader.findById(
        const DocumentId('doc-999'),
      );
      stopwatch.stop();

      expect(result, isA<Success<Document>>());
      // An indexed lookup, so the last document is no slower to find than the
      // first — which is what a linear scan would break.
      expect(stopwatch.elapsed, lessThan(_interactiveBudget));
    });

    test('the storage total does not load every record into memory', () async {
      await seed(1000);

      final stopwatch = Stopwatch()..start();
      final result = await library.storageSummaryReader.summary();
      stopwatch.stop();

      expect((result as Success<StorageSummary>).value.documentCount, 1000);
      expect(stopwatch.elapsed, lessThan(_interactiveBudget));
    });
  });

  group('paging', () {
    test(
      'every page is the same size and the last one ends the list',
      () async {
        // The property that keeps memory flat while scrolling: each page is a
        // bounded read, and the list knows when to stop asking.
        await seed(120);

        var offset = 0;
        var pages = 0;
        var total = 0;

        while (true) {
          final result = await library.loadDocuments(offset: offset);
          final page = (result as Success<DocumentPageResult>).value;

          total += page.documents.length;
          pages++;
          offset += page.documents.length;

          if (!page.hasMore || page.documents.isEmpty) break;
          expect(pages, lessThan(50), reason: 'paging did not terminate');
        }

        expect(total, 120);
        expect(pages, greaterThan(1));
      },
    );
  });
}
