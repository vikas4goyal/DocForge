import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Document doc(
  String id,
  String relative, {
  bool isArchived = false,
  DateTime? updatedAt,
}) => Document(
  id: DocumentId(id),
  title: LibraryPath.parse(relative).baseName,
  createdAt: DateTime.utc(2026),
  updatedAt: updatedAt ?? DateTime.utc(2026),
  pageCount: 1,
  sizeInBytes: 10,
  libraryPath: LibraryPath.parse(relative),
  isArchived: isArchived,
);

void main() {
  late InMemoryPublicFileStore store;
  late FakeDocumentRepository documents;

  setUp(() {
    store = InMemoryPublicFileStore();
    documents = FakeDocumentRepository();
  });

  DashboardCubit build() => DashboardCubit(store: store, index: documents);

  /// Puts a document in both the folder and the index.
  void given(String relative, {bool isArchived = false, DateTime? updatedAt}) {
    final document = doc(
      relative,
      relative,
      isArchived: isArchived,
      updatedAt: updatedAt,
    );
    store.files[relative] = 'pdf';
    // Every ancestor, as writing through the store would have registered.
    final folders = document.libraryPath.folders;
    for (var depth = 1; depth <= folders.length; depth++) {
      store.folderPaths.add(folders.sublist(0, depth).join('/'));
    }
    documents.documents[document.id] = document;
  }

  group('loading the root', () {
    blocTest<DashboardCubit, DashboardState>(
      'lists the documents it holds',
      build: build,
      setUp: () => given('Invoice.pdf'),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.documents.single.title, 'Invoice');
        expect(cubit.state.isAtRoot, isTrue);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'lists child folders',
      build: build,
      setUp: () => store.folderPaths.add('Invoices'),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.folders.single.name, 'Invoices'),
    );

    blocTest<DashboardCubit, DashboardState>(
      'reports an empty library',
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
    );

    blocTest<DashboardCubit, DashboardState>(
      'excludes archived documents',
      build: build,
      setUp: () {
        given('Kept.pdf');
        given('Archived.pdf', isArchived: true);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.documents.single.title, 'Kept'),
    );

    blocTest<DashboardCubit, DashboardState>(
      'orders documents by modified date, newest first',
      build: build,
      setUp: () {
        given('Older.pdf', updatedAt: DateTime.utc(2026));
        given('Newer.pdf', updatedAt: DateTime.utc(2026, 6));
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(
        [for (final d in cubit.state.documents) d.title],
        ['Newer', 'Older'],
      ),
    );

    blocTest<DashboardCubit, DashboardState>(
      'reports how much space the library uses',
      build: build,
      setUp: () => given('Invoice.pdf'),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.storageBytes, greaterThan(0)),
    );
  });

  group('a file the index has not caught up with', () {
    blocTest<DashboardCubit, DashboardState>(
      'is not shown as a row with no metadata',
      build: build,
      setUp: () => store.files['Unindexed.pdf'] = 'pdf',
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        // Reconciliation will index it; a half-described document is worse
        // than one that appears a moment later.
        expect(cubit.state.documents, isEmpty);
      },
    );
  });

  group('navigating', () {
    blocTest<DashboardCubit, DashboardState>(
      'opening a folder shows its contents',
      build: build,
      setUp: () => given('Invoices/Receipt.pdf'),
      act: (cubit) async {
        await cubit.load();
        await cubit.openFolder('Invoices');
      },
      verify: (cubit) {
        expect(cubit.state.path, ['Invoices']);
        expect(cubit.state.documents.single.title, 'Receipt');
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'going up returns to the parent',
      build: build,
      setUp: () => given('Invoices/Receipt.pdf'),
      act: (cubit) async {
        await cubit.openFolder('Invoices');
        await cubit.goUp();
      },
      verify: (cubit) => expect(cubit.state.isAtRoot, isTrue),
    );

    blocTest<DashboardCubit, DashboardState>(
      'going up at the root does nothing',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.goUp();
      },
      verify: (cubit) => expect(cubit.state.path, isEmpty),
    );

    blocTest<DashboardCubit, DashboardState>(
      'the breadcrumb names the path from the library root',
      build: build,
      setUp: () => given('Invoices/2026/Receipt.pdf'),
      act: (cubit) => cubit.openPath(['Invoices', '2026']),
      verify: (cubit) =>
          expect(cubit.state.breadcrumb, ['DocScanly', 'Invoices', '2026']),
    );

    blocTest<DashboardCubit, DashboardState>(
      'a folder counts the documents beneath it',
      build: build,
      setUp: () {
        given('Invoices/2026/A.pdf');
        given('Invoices/2026/B.pdf');
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        // Counted recursively: a folder showing zero while holding a subfolder
        // full of documents would read as empty.
        expect(cubit.state.folders.single.documentCount, 2);
      },
    );
  });

  group('searching', () {
    blocTest<DashboardCubit, DashboardState>(
      'spans the whole library, not the open folder',
      build: build,
      setUp: () {
        given('Invoices/Receipt.pdf');
        given('Statement.pdf');
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.search('receipt');
      },
      verify: (cubit) {
        // Someone who remembers a name rarely remembers the folder, which is
        // why they are searching.
        expect(cubit.state.documents.single.title, 'Receipt');
        expect(cubit.state.isSearching, isTrue);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'is case-insensitive',
      build: build,
      setUp: () => given('Invoice.pdf'),
      act: (cubit) => cubit.search('INVOICE'),
      verify: (cubit) => expect(cubit.state.documents, hasLength(1)),
    );

    blocTest<DashboardCubit, DashboardState>(
      'excludes archived documents',
      build: build,
      setUp: () => given('Invoice.pdf', isArchived: true),
      act: (cubit) => cubit.search('invoice'),
      verify: (cubit) => expect(cubit.state.documents, isEmpty),
    );

    blocTest<DashboardCubit, DashboardState>(
      'clearing returns to the open folder',
      build: build,
      setUp: () {
        given('Invoices/Receipt.pdf');
        given('Statement.pdf');
      },
      act: (cubit) async {
        await cubit.openFolder('Invoices');
        await cubit.search('statement');
        await cubit.clearSearch();
      },
      verify: (cubit) {
        expect(cubit.state.isSearching, isFalse);
        expect(cubit.state.documents.single.title, 'Receipt');
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'hides folders while searching',
      build: build,
      setUp: () {
        store.folderPaths.add('Invoices');
        given('Statement.pdf');
      },
      act: (cubit) => cubit.search('statement'),
      verify: (cubit) => expect(cubit.state.folders, isEmpty),
    );
  });

  group('failure', () {
    blocTest<DashboardCubit, DashboardState>(
      'an unreadable folder is reported rather than shown as empty',
      build: build,
      setUp: () => store.failures['list'] = const Failure.storage(),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        // Showing an empty folder would tell the user their documents are gone.
        expect(cubit.state.status, DashboardStatus.failure);
        expect(cubit.state.failure, isNotNull);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'retrying after a failure recovers',
      build: build,
      setUp: () => given('Invoice.pdf'),
      act: (cubit) async {
        store.failures['list'] = const Failure.storage();
        await cubit.load();
        store.failures.clear();
        await cubit.load();
      },
      verify: (cubit) {
        expect(cubit.state.status, DashboardStatus.ready);
        expect(cubit.state.failure, isNull);
      },
    );
  });
}
