import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/trash.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/trash_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/screens/trash_screen.dart';
import 'package:doc_forge/features/document_library/presentation/trash_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeTrashRepository trash;
  late InMemoryPublicFileStore store;
  late TrashCubit cubit;

  setUp(() {
    trash = FakeTrashRepository();
    store = InMemoryPublicFileStore();
    final documents = FakeDocumentRepository();
    final pages = FakePageRepository();
    final folders = FakeFolderRepository();
    final purge = PurgeTrashEntry(
      trash,
      folders,
      store,
      PurgeDocument(
        documents,
        pages,
        store,
        FakeDocumentFileStore(),
        InMemorySecureStore(),
      ),
    );
    cubit = TrashCubit(
      loadTrash: LoadTrash(trash),
      restoreTrash: RestoreTrashEntry(trash, documents, folders, store),
      purgeTrash: purge,
      emptyTrash: EmptyTrash(trash, purge),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const TrashScreen()),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();
  }

  TrashEntry seed() {
    final deletedAt = DateTime.utc(2026, 8, 3);
    final entry = TrashEntry(
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
    return entry;
  }

  testWidgets('shows the 30-day empty state', (tester) async {
    await pump(tester);

    expect(find.byKey(TrashKeys.empty), findsOneWidget);
    expect(find.textContaining('30 days'), findsOneWidget);
  });

  testWidgets('permanent deletion requires explicit confirmation', (
    tester,
  ) async {
    final entry = seed();
    await pump(tester);

    await tester.tap(find.byKey(TrashKeys.purge(entry.id.value)));
    await tester.pumpAndSettle();
    expect(find.byKey(TrashKeys.purgeDialog(entry.id.value)), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(TrashKeys.row(entry.id.value)), findsOneWidget);

    await tester.tap(find.byKey(TrashKeys.purge(entry.id.value)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(find.byKey(TrashKeys.empty), findsOneWidget);
  });

  testWidgets('restore returns the payload to the library', (tester) async {
    final entry = seed();
    await pump(tester);

    await tester.tap(find.byKey(TrashKeys.restore(entry.id.value)));
    await tester.pumpAndSettle();

    expect(store.files['Receipt.pdf'], 'pdf');
    expect(find.byKey(TrashKeys.empty), findsOneWidget);
  });
}
