import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/reconcile_library.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// A clock the test moves forward, so throttling can be exercised without
/// waiting a real minute.
class _MovableClock implements Clock {
  _MovableClock(this._now);

  DateTime _now;

  void advance(Duration by) => _now = _now.add(by);

  @override
  DateTime now() => _now;
}

void main() {
  late InMemoryPublicFileStore store;
  late FakeDocumentRepository documents;
  late FakePageRepository pages;
  late InMemoryPreferenceStore preferences;
  late _MovableClock clock;
  late List<String> countedPaths;
  late Failure? countFailure;

  Document indexed(String id, String relative, {int sizeBytes = 9}) => Document(
    id: DocumentId(id),
    title: LibraryPath.parse(relative).baseName,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    pageCount: 3,
    sizeInBytes: sizeBytes,
    libraryPath: LibraryPath.parse(relative),
  );

  ReconcileLibrary build({Duration? throttle}) => ReconcileLibrary(
    store: store,
    documents: documents,
    pages: pages,
    preferences: preferences,
    clock: clock,
    ids: SequentialIdGenerator(prefix: 'found'),
    throttle: throttle ?? ReconcileLibrary.defaultThrottle,
    pageCountOf: (path, {String? password}) async {
      countedPaths.add(path);
      final configured = countFailure;
      return configured == null
          ? const Result<int>.success(7)
          : Result<int>.failure(configured);
    },
  );

  setUp(() {
    store = InMemoryPublicFileStore();
    documents = FakeDocumentRepository();
    pages = FakePageRepository();
    preferences = InMemoryPreferenceStore();
    clock = _MovableClock(DateTime.utc(2026, 7, 28, 12));
    countedPaths = [];
    countFailure = null;
  });

  group('added', () {
    test('indexes a file that appeared from outside the application', () async {
      store.files['Statement.pdf'] = 'pdf-bytes';

      final result = await build()();

      expect(result.valueOrNull!.diff.added, hasLength(1));
      final saved = documents.documents.values.single;
      expect(saved.relativePath, 'Statement.pdf');
      expect(saved.title, 'Statement');
      expect(saved.pageCount, 7);
      expect(saved.sizeInBytes, 'pdf-bytes'.length);
    });

    test('reads the page count from the file itself', () async {
      store.files['Statement.pdf'] = 'pdf-bytes';

      await build()();

      expect(countedPaths, hasLength(1));
    });

    test('releases the materialised copy after counting', () async {
      store.files['Statement.pdf'] = 'pdf-bytes';

      await build()();

      // Left materialised, every reconcile of a large library would fill the
      // cache with a copy of the whole library.
      expect(store.materialised, isEmpty);
    });

    test('a file that will not open is left for the next run', () async {
      store.files['Broken.pdf'] = 'not-a-pdf';
      countFailure = const Failure.corruptFile();

      await build()();

      // Recorded as a zero-page document it would be a row the user cannot
      // open; left alone, the next run tries again.
      expect(documents.documents, isEmpty);
    });

    test('ignores files that are not PDFs', () async {
      store.files['notes.txt'] = 'text';

      final result = await build()();

      expect(result.valueOrNull!.diff.added, isEmpty);
      expect(documents.documents, isEmpty);
    });
  });

  group('removed', () {
    test('drops a document whose file is gone', () async {
      documents.documents[const DocumentId('a')] = indexed('a', 'Invoice.pdf');

      final result = await build()();

      expect(result.valueOrNull!.diff.removed, hasLength(1));
      expect(documents.documents, isEmpty);
    });

    test('drops its page rows too', () async {
      documents.documents[const DocumentId('a')] = indexed('a', 'Invoice.pdf');
      await pages.replaceAll(const DocumentId('a'), samplePages(2));

      await build()();

      expect(
        (await pages.forDocument(const DocumentId('a'))).valueOrNull,
        isEmpty,
      );
    });
  });

  group('renamed', () {
    test('re-paths the document and keeps its identity', () async {
      documents.documents[const DocumentId('a')] = indexed('a', 'Invoice.pdf');
      store.files['Renamed.pdf'] = 'pdf-bytes';

      await build()();

      expect(documents.documents, hasLength(1));
      final saved = documents.documents.values.single;
      expect(saved.id, const DocumentId('a'));
      expect(saved.relativePath, 'Renamed.pdf');
    });

    test('does not re-count the pages of a file that only moved', () async {
      documents.documents[const DocumentId('a')] = indexed('a', 'Invoice.pdf');
      store.files['Renamed.pdf'] = 'pdf-bytes';

      await build()();

      // A rename changes no bytes, so opening the file to count them again
      // would be work with a known answer.
      expect(countedPaths, isEmpty);
    });
  });

  group('modified', () {
    test('refreshes the size of a file edited in place', () async {
      documents.documents[const DocumentId('a')] = indexed(
        'a',
        'Invoice.pdf',
        sizeBytes: 4,
      );
      store.files['Invoice.pdf'] = 'much-longer-contents';

      await build()();

      expect(
        documents.documents.values.single.sizeInBytes,
        'much-longer-contents'.length,
      );
    });
  });

  group('throttling', () {
    test('a second run inside the window does not walk the tree', () async {
      final reconcile = build();
      await reconcile();
      store.files['Late.pdf'] = 'pdf-bytes';

      final second = await reconcile();

      expect(second.valueOrNull!.skipped, isTrue);
      expect(documents.documents, isEmpty);
    });

    test('a run after the window walks again', () async {
      final reconcile = build(throttle: const Duration(seconds: 60));
      await reconcile();
      store.files['Late.pdf'] = 'pdf-bytes';

      clock.advance(const Duration(seconds: 61));
      final second = await reconcile();

      expect(second.valueOrNull!.skipped, isFalse);
      expect(documents.documents, hasLength(1));
    });

    test('force ignores the window', () async {
      final reconcile = build();
      await reconcile();
      store.files['Late.pdf'] = 'pdf-bytes';

      final second = await reconcile(force: true);

      expect(second.valueOrNull!.skipped, isFalse);
      expect(documents.documents, hasLength(1));
    });

    test('the first run is never throttled', () async {
      final result = await build()();

      expect(result.valueOrNull!.skipped, isFalse);
    });

    test('an unreadable timestamp is treated as never having run', () async {
      await preferences.writeString(ReconcileLibrary.lastRunKey, 'nonsense');

      final result = await build()();

      expect(result.valueOrNull!.skipped, isFalse);
    });
  });

  group('failures', () {
    test('a failed walk is reported rather than treated as empty', () async {
      documents.documents[const DocumentId('a')] = indexed('a', 'Invoice.pdf');
      store.failures['listRecursive'] = const Failure.storage();

      final result = await build()();

      // Treating an unreadable folder as "everything was deleted" would empty
      // the user's library.
      expect(result.isFailure, isTrue);
      expect(documents.documents, hasLength(1));
    });

    test('a failed index read is reported', () async {
      documents.failure = const Failure.storage();

      expect((await build()()).isFailure, isTrue);
    });

    test('a failed run does not record a timestamp', () async {
      store.failures['listRecursive'] = const Failure.storage();
      await build()();

      store.failures.clear();
      store.files['Statement.pdf'] = 'pdf-bytes';
      final second = await build()();

      // Recording a run that failed would suppress the retry for a minute.
      expect(second.valueOrNull!.skipped, isFalse);
    });
  });

  group('no changes', () {
    test('a folder matching the index reports nothing', () async {
      documents.documents[const DocumentId('a')] = indexed('a', 'Invoice.pdf');
      store.files['Invoice.pdf'] = 'pdf-bytes';

      final result = await build()();

      expect(result.valueOrNull!.diff.isEmpty, isTrue);
      expect(result.valueOrNull!.changedAnything, isFalse);
    });
  });
}
