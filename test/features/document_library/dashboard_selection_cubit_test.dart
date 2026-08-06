import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/features/document_library/application/usecases/bulk_document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late InMemoryPublicFileStore store;
  late FakeDocumentRepository repository;
  late Document first;
  late Document second;

  setUp(() {
    store = InMemoryPublicFileStore();
    repository = FakeDocumentRepository();
    first = _document('first', 'First.pdf');
    second = _document('second', 'Second.pdf');
    for (final document in [first, second]) {
      store.files[document.relativePath] = 'pdf';
      repository.documents[document.id] = document;
    }
  });

  DashboardCubit build({
    BulkArchiveDocuments? archive,
    BulkTrashDocuments? trash,
  }) => DashboardCubit(
    store: store,
    index: repository,
    bulkArchiveDocuments: archive,
    bulkTrashDocuments: trash,
  );

  blocTest<DashboardCubit, DashboardState>(
    'select control, toggle, select all, and cancel are fully equatable',
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.enterSelection();
      cubit.toggleSelection(first.id);
      cubit.selectAll();
      cubit.cancelSelection();
    },
    verify: (cubit) {
      expect(cubit.state.selectionMode, isFalse);
      expect(cubit.state.selectedDocumentIds, isEmpty);
    },
  );

  blocTest<DashboardCubit, DashboardState>(
    'long press entry selects the requested document only',
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.enterSelection(second.id);
    },
    verify: (cubit) {
      expect(cubit.state.selectionMode, isTrue);
      expect(cubit.state.selectedDocumentIds, [second.id]);
    },
  );

  blocTest<DashboardCubit, DashboardState>(
    'bulk archive removes successes and retains failures for retry',
    build: () => build(
      archive: BulkArchiveDocuments((id) async {
        if (id == second.id) {
          return const Result<Document>.failure(Failure.storage());
        }
        return Result<Document>.success(repository.documents[id]!);
      }),
    ),
    act: (cubit) async {
      await cubit.load();
      cubit.enterSelection();
      cubit.selectAll();
      await cubit.archiveSelected();
    },
    verify: (cubit) {
      expect(cubit.state.documents.map((item) => item.id), [second.id]);
      expect(cubit.state.selectedDocumentIds, [second.id]);
      expect(cubit.state.bulkStatus, DashboardBulkStatus.partialFailure);
      expect(cubit.state.bulkOutcome?.succeeded, [first.id]);
    },
  );

  blocTest<DashboardCubit, DashboardState>(
    'bulk Trash requires reviewed confirmation and exits after success',
    build: () => build(
      trash: BulkTrashDocuments(
        (id) async => Result<Document>.success(repository.documents[id]!),
      ),
    ),
    act: (cubit) async {
      await cubit.load();
      cubit.enterSelection(first.id);
      await cubit.trashSelected(confirmed: true);
    },
    verify: (cubit) {
      expect(cubit.state.documents.map((item) => item.id), [second.id]);
      expect(cubit.state.selectionMode, isFalse);
      expect(cubit.state.trashCount, 1);
    },
  );

  test('a repeated submit cannot start a second mutation', () async {
    final gate = Completer<Result<Document>>();
    var calls = 0;
    final cubit = build(
      archive: BulkArchiveDocuments((_) {
        calls++;
        return gate.future;
      }),
    );
    addTearDown(cubit.close);
    await cubit.load();
    cubit.enterSelection(first.id);

    final initial = cubit.archiveSelected();
    await Future<void>.delayed(Duration.zero);
    await cubit.archiveSelected();

    expect(calls, 1);
    gate.complete(Result<Document>.success(first));
    await initial;
  });

  blocTest<DashboardCubit, DashboardState>(
    'search refresh prunes invisible selections but preserves visible ones',
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.enterSelection();
      cubit.selectAll();
      await cubit.search('First');
    },
    verify: (cubit) => expect(cubit.state.selectedDocumentIds, [first.id]),
  );
}

Document _document(String id, String relativePath) => Document(
  id: DocumentId(id),
  title: LibraryPath.parse(relativePath).baseName,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  pageCount: 1,
  sizeInBytes: 1024,
  libraryPath: LibraryPath.parse(relativePath),
);
