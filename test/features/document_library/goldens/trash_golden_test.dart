/// Golden coverage for recoverable Trash.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/trash.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/trash_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/trash_state.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/trash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

const _phone = Size(390, 844);

class _SeededTrashCubit extends TrashCubit {
  _SeededTrashCubit(this._seeded)
    : super(
        loadTrash: LoadTrash(FakeTrashRepository()),
        restoreTrash: RestoreTrashEntry(
          FakeTrashRepository(),
          FakeDocumentRepository(),
          FakeFolderRepository(),
          InMemoryPublicFileStore(),
        ),
        purgeTrash: PurgeTrashEntry(
          FakeTrashRepository(),
          FakeFolderRepository(),
          InMemoryPublicFileStore(),
          PurgeDocument(
            FakeDocumentRepository(),
            FakePageRepository(),
            InMemoryPublicFileStore(),
            FakeDocumentFileStore(),
            InMemorySecureStore(),
          ),
        ),
        emptyTrash: EmptyTrash(
          FakeTrashRepository(),
          PurgeTrashEntry(
            FakeTrashRepository(),
            FakeFolderRepository(),
            InMemoryPublicFileStore(),
            PurgeDocument(
              FakeDocumentRepository(),
              FakePageRepository(),
              InMemoryPublicFileStore(),
              FakeDocumentFileStore(),
              InMemorySecureStore(),
            ),
          ),
        ),
      );

  final TrashState _seeded;

  @override
  TrashState get state => _seeded;

  @override
  Future<void> load() async {}
}

void main() {
  final deletedAt = DateTime.utc(2026, 8, 3);
  final state = TrashState(
    status: TrashStatus.ready,
    entries: [
      TrashEntry(
        id: const TrashId('trash-folder'),
        kind: TrashEntryKind.folderTree,
        displayName: 'Invoices',
        originalRelativePath: 'Work/Invoices',
        deletedAt: deletedAt,
        expiresAt: TrashEntry.expiryFor(deletedAt),
        inventory: const TrashInventory(
          documentCount: 12,
          otherFileCount: 2,
          folderCount: 4,
          sizeInBytes: 8 * 1024 * 1024,
        ),
      ),
      TrashEntry(
        id: const TrashId('trash-document'),
        kind: TrashEntryKind.document,
        displayName: 'Receipt — Acme Ltd',
        originalRelativePath: 'Receipt — Acme Ltd.pdf',
        deletedAt: deletedAt.subtract(const Duration(days: 2)),
        expiresAt: TrashEntry.expiryFor(
          deletedAt.subtract(const Duration(days: 2)),
        ),
        inventory: const TrashInventory(
          documentCount: 1,
          sizeInBytes: 482 * 1024,
        ),
      ),
    ],
  );

  for (final brightness in Brightness.values) {
    testWidgets('phone ${brightness.name}', (tester) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = _SeededTrashCubit(state);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: BlocProvider<TrashCubit>.value(
            value: cubit,
            child: const TrashScreen(),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(TrashScreen),
        matchesGoldenFile('trash_phone_${brightness.name}.png'),
      );
    });
  }
}
