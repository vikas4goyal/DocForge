/// Tier 2 — document detail over its real Cubit and real use cases.
///
/// Repositories and platform file/PDF edges are faked; loading, state
/// transitions and callback wiring are production
/// code. This closes the gap between isolated widget tests and the device flow.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';
import '../fakes.dart';

void main() {
  late FakeDocumentRepository documents;
  late FakePageRepository pages;
  late FakeFolderRepository folders;
  late FakeDocumentFileStore derivedFiles;
  late InMemoryPublicFileStore publicStore;
  late InMemorySecureStore secrets;

  setUp(() async {
    documents = FakeDocumentRepository([
      sampleDocument.copyWith(pageCount: 500),
    ]);
    pages = FakePageRepository();
    folders = FakeFolderRepository();
    derivedFiles = FakeDocumentFileStore();
    publicStore = InMemoryPublicFileStore()
      ..files[sampleDocument.relativePath] = 'pdf bytes';
    secrets = InMemorySecureStore();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    void Function(Document document)? onOpenDocument,
  }) async {
    final clock = FixedClock(DateTime.utc(2026, 8, 3));

    await pumpComponent(
      tester,
      DocumentDetailScreen(onClose: () {}, onOpenDocument: onOpenDocument),
      providers: [
        BlocProvider(
          create: (_) => DocumentDetailCubit(
            sampleDocument.id,
            LoadDocumentDetail(documents),
            RenameDocument(documents, clock, publicStore),
            MoveDocument(documents, clock),
            ToggleFavourite(documents, clock),
            ArchiveDocument(documents, clock),
            RestoreDocument(documents, clock),
            DuplicateDocument(
              documents,
              pages,
              publicStore,
              clock,
              SequentialIdGenerator(),
            ),
            PurgeDocument(documents, pages, publicStore, derivedFiles, secrets),
            loadFolderOptions: LoadFolderOptions(folders),
          ),
        ),
      ],
    );
    await settleComponent(tester);
  }

  testWidgets('ready detail loads metadata without requesting pages', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text(sampleDocument.title), findsWidgets);
    expect(pages.forDocumentCalls, isEmpty);
    expect(find.text('Open'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('favourite persists through the real detail state machine', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.tap(find.byKey(LibraryKeys.documentFavouriteToggle));
    await settleComponent(tester);

    expect(documents.documents[sampleDocument.id]?.isFavourite, isTrue);
    expect(pages.forDocumentCalls, isEmpty);
  });

  testWidgets('move picker loads a newly created folder and moves once', (
    tester,
  ) async {
    final destination = sampleFolder.copyWith(
      id: const FolderId('created-folder'),
      name: 'Created folder',
      relativePath: 'Created folder',
    );
    folders.folders[destination.id] = destination;
    await pumpDetail(tester);

    await tester.tap(find.byKey(LibraryKeys.documentDetailMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryKeys.documentMoveButton));
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryKeys.documentMovePicker), findsOneWidget);
    expect(
      find.byKey(LibraryKeys.documentMoveFolder(destination.id.value)),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(LibraryKeys.documentMoveFolder(destination.id.value)),
    );
    await tester.pump();
    await tester.tap(find.byKey(LibraryKeys.documentMoveConfirm));
    await tester.pumpAndSettle();

    expect(documents.documents[sampleDocument.id]?.folderId, destination.id);
  });

  testWidgets('duplicate requires review and navigates exactly once', (
    tester,
  ) async {
    final opened = <Document>[];
    await pumpDetail(tester, onOpenDocument: opened.add);

    await tester.tap(find.byKey(LibraryKeys.documentDetailMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryKeys.documentDuplicateButton));
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryKeys.documentDuplicateDialog), findsOneWidget);
    await tester.enterText(
      find.byKey(LibraryKeys.documentDuplicateName),
      'Reviewed policy copy',
    );
    await tester.tap(find.byKey(LibraryKeys.documentDuplicateConfirm));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.title, 'Reviewed policy copy');
    expect(documents.documents, hasLength(2));
  });
}
