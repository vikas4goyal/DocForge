import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/features/document_library/application/usecases/bulk_document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    first = _document('first', 'A very long policy document title.pdf');
    second = _document('second', 'Receipt.pdf');
    for (final document in [first, second]) {
      store.files[document.relativePath] = 'pdf';
      repository.documents[document.id] = document;
    }
    store.folderPaths.add('Policy folders');
  });

  Future<DashboardCubit> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    BulkArchiveDocuments? archive,
    BulkTrashDocuments? trash,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = DashboardCubit(
      store: store,
      index: repository,
      bulkArchiveDocuments: archive,
      bulkTrashDocuments: trash,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: DashboardScreen(
              actions: DashboardActions(
                onOpenDocument: (_) {},
                onCreateFolder: (_) {},
                onImportPdf: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('phone and iPad use deterministic adaptive grid columns', (
    tester,
  ) async {
    await pump(tester);
    expect(_columns(tester), 2);

    tester.view.physicalSize = const Size(1024, 900);
    await tester.pumpAndSettle();
    expect(_columns(tester), 5);
  });

  testWidgets('large text falls back to one column without clipping', (
    tester,
  ) async {
    await pump(tester, textScale: 2);
    expect(_columns(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rounded search returns folders and exposes a clear action', (
    tester,
  ) async {
    await pump(tester);
    final field = tester.widget<TextField>(
      find.byKey(DashboardKeys.searchField),
    );
    final border = field.decoration!.border! as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(13));

    await tester.enterText(find.byKey(DashboardKeys.searchField), 'policy');
    await tester.pumpAndSettle();

    expect(find.byKey(DashboardKeys.searchClear), findsOneWidget);
    expect(
      find.byKey(DashboardKeys.folderTile('Policy folders')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(DashboardKeys.searchClear));
    await tester.pumpAndSettle();
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('long press, select all, and archive submit once', (
    tester,
  ) async {
    var calls = 0;
    await pump(
      tester,
      archive: BulkArchiveDocuments((id) async {
        calls++;
        return Result<Document>.success(repository.documents[id]!);
      }),
    );

    await tester.longPress(
      find.byKey(DashboardKeys.documentTile(first.id.value)),
    );
    await tester.pump();
    expect(find.byKey(DashboardKeys.selectionToolbar), findsOneWidget);

    await tester.tap(find.byKey(DashboardKeys.selectAll));
    await tester.tap(find.byKey(DashboardKeys.bulkArchive));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.byKey(DashboardKeys.selectionToolbar), findsNothing);
  });

  testWidgets('bulk Trash names the count before the mutation', (tester) async {
    var calls = 0;
    await pump(
      tester,
      trash: BulkTrashDocuments((id) async {
        calls++;
        return Result<Document>.success(repository.documents[id]!);
      }),
    );
    await tester.longPress(
      find.byKey(DashboardKeys.documentTile(first.id.value)),
    );
    await tester.pump();
    await tester.tap(find.byKey(DashboardKeys.bulkTrash));
    await tester.pumpAndSettle();

    expect(find.text('Move 1 to Trash?'), findsOneWidget);
    expect(calls, 0);
    await tester.tap(find.byKey(DashboardKeys.bulkTrashConfirm));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}

int _columns(WidgetTester tester) {
  final grid = tester.widget<SliverGrid>(find.byKey(DashboardKeys.contentGrid));
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

Document _document(String id, String path) => Document(
  id: DocumentId(id),
  title: LibraryPath.parse(path).baseName,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026, 8, 4),
  pageCount: 2,
  sizeInBytes: 2048,
  libraryPath: LibraryPath.parse(path),
);
