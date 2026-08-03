import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/trash.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/trash_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/trash_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeTrashRepository trash;
  late FakeDocumentRepository documents;
  late FakePageRepository pages;
  late FakeFolderRepository folders;
  late FakeDocumentFileStore derived;
  late InMemoryPublicFileStore store;
  late TrashEntry entry;

  setUp(() {
    trash = FakeTrashRepository();
    documents = FakeDocumentRepository();
    pages = FakePageRepository();
    folders = FakeFolderRepository();
    derived = FakeDocumentFileStore();
    store = InMemoryPublicFileStore();
    final deletedAt = DateTime.utc(2026, 8, 3);
    entry = TrashEntry(
      id: const TrashId('trash-1'),
      kind: TrashEntryKind.document,
      displayName: 'Receipt',
      originalRelativePath: 'Receipt.pdf',
      deletedAt: deletedAt,
      expiresAt: TrashEntry.expiryFor(deletedAt),
      inventory: const TrashInventory(documentCount: 1, sizeInBytes: 3),
    );
    trash.entries[entry.id] = entry;
    store.folderPaths.addAll({
      '.docforge-trash',
      '.docforge-trash/trash-1',
      '.docforge-trash/trash-1/payload',
    });
    store.files['.docforge-trash/trash-1/payload/Receipt.pdf'] = 'pdf';
  });

  TrashCubit build() {
    final purge = PurgeTrashEntry(
      trash,
      folders,
      store,
      PurgeDocument(documents, pages, store, derived, InMemorySecureStore()),
    );
    return TrashCubit(
      loadTrash: LoadTrash(trash),
      restoreTrash: RestoreTrashEntry(trash, documents, folders, store),
      purgeTrash: purge,
      emptyTrash: EmptyTrash(trash, purge),
    );
  }

  blocTest<TrashCubit, TrashState>(
    'loads through loading to newest-first ready state',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const TrashState(status: TrashStatus.loading),
      TrashState(status: TrashStatus.ready, entries: [entry]),
    ],
  );

  blocTest<TrashCubit, TrashState>(
    'load failure is retryable',
    setUp: () => trash.failure = const Failure.storage(),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, TrashStatus.failure);
      expect(cubit.state.failure, const Failure.storage());
    },
  );

  test('purge removes the row and reports an outcome', () async {
    final cubit = build();
    await cubit.load();
    await cubit.purge(entry.id);

    expect(cubit.state.entries, isEmpty);
    expect(cubit.state.message, 'Permanently deleted');
    expect(trash.entries, isEmpty);
    await cubit.close();
  });
}
