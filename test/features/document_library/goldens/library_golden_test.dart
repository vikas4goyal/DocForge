/// Golden tests for the document list and the folder list.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
@Tags(['golden'])
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_state.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

/// A fixture document, fixed so every golden built on it is byte-stable.
Document _document(int index) => Document(
  id: DocumentId('golden-$index'),
  title: 'Invoice $index',
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 4,
  sizeInBytes: 184_320,
  filePath: '/golden/$index.pdf',
);

Folder _folder(int index) => Folder(
  id: FolderId('f$index'),
  name: 'Receipts $index',
  createdAt: DateTime.utc(2026),
  documentCount: index * 3,
);

/// Collaborators the seeded Cubits never reach.
///
/// Both screens load on their first frame; `load` is overridden below so the
/// seeded state survives, and these exist only to satisfy the constructors.
final _documents = FakeDocumentRepository();
final _folders = FakeFolderRepository();
final _pages = FakePageRepository();
final _files = FakeDocumentFileStore();
final _clock = FixedClock(DateTime.utc(2026, 3, 14));

/// A list Cubit frozen at a chosen state.
class _SeededListCubit extends DocumentListCubit {
  _SeededListCubit(this._seeded)
    : super(
        LoadDocuments(_documents),
        ToggleFavourite(_documents, _clock),
        ArchiveDocument(_documents, _clock),
        RestoreDocument(_documents, _clock),
      );

  final DocumentListState _seeded;

  @override
  DocumentListState get state => _seeded;

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async {}
}

/// A folder Cubit frozen at a chosen state.
class _SeededFolderCubit extends FolderCubit {
  _SeededFolderCubit(this._seeded)
    : super(
        LoadFolders(_folders),
        CreateFolder(_folders, _clock, SequentialIdGenerator()),
        RenameFolder(_folders),
        DeleteFolder(
          _folders,
          _documents,
          MoveDocument(_documents, _clock),
          PurgeDocument(_documents, _pages, _files, InMemorySecureStore()),
        ),
      );

  final FolderState _seeded;

  @override
  FolderState get state => _seeded;

  @override
  Future<void> load() async {}
}

void main() {
  Future<void> pumpList(
    WidgetTester tester,
    Size size,
    DocumentListState state, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _SeededListCubit(state);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<DocumentListCubit>.value(
          value: cubit,
          child: DocumentListScreen(title: 'Documents', onOpenDocument: (_) {}),
        ),
      ),
    );

    // Bounded rather than `pumpAndSettle`: the loading state shows an
    // indefinite progress indicator, which never settles.
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpFolders(
    WidgetTester tester,
    Size size,
    FolderState state, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _SeededFolderCubit(state);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<FolderCubit>.value(
          value: cubit,
          child: FolderListScreen(onOpenFolder: (_) {}),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
  }

  final documents = const DocumentListState.initial().copyWith(
    status: LoadStatus.ready,
    documents: [for (var i = 0; i < 6; i++) _document(i)],
  );

  final folders = const FolderState.initial().copyWith(
    status: LoadStatus.ready,
    folders: [for (var i = 1; i <= 4; i++) _folder(i)],
  );

  group('document list goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpList(tester, _phone, documents);

      await expectLater(
        find.byType(DocumentListScreen),
        matchesGoldenFile('document_list_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpList(tester, _phone, documents, brightness: Brightness.dark);

      await expectLater(
        find.byType(DocumentListScreen),
        matchesGoldenFile('document_list_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpList(tester, _tablet, documents);

      await expectLater(
        find.byType(DocumentListScreen),
        matchesGoldenFile('document_list_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpList(tester, _tablet, documents, brightness: Brightness.dark);

      await expectLater(
        find.byType(DocumentListScreen),
        matchesGoldenFile('document_list_tablet_dark.png'),
      );
    });

    testWidgets('empty, light', (tester) async {
      await pumpList(
        tester,
        _phone,
        const DocumentListState.initial().copyWith(status: LoadStatus.empty),
      );

      await expectLater(
        find.byType(DocumentListScreen),
        matchesGoldenFile('document_list_empty_light.png'),
      );
    });

    testWidgets('error, dark', (tester) async {
      await pumpList(
        tester,
        _phone,
        const DocumentListState.initial().copyWith(
          status: LoadStatus.failure,
          failure: const Failure.storage(),
        ),
        brightness: Brightness.dark,
      );

      await expectLater(
        find.byType(DocumentListScreen),
        matchesGoldenFile('document_list_error_dark.png'),
      );
    });
  });

  group('folder list goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpFolders(tester, _phone, folders);

      await expectLater(
        find.byType(FolderListScreen),
        matchesGoldenFile('folder_list_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpFolders(tester, _phone, folders, brightness: Brightness.dark);

      await expectLater(
        find.byType(FolderListScreen),
        matchesGoldenFile('folder_list_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpFolders(tester, _tablet, folders);

      await expectLater(
        find.byType(FolderListScreen),
        matchesGoldenFile('folder_list_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpFolders(tester, _tablet, folders, brightness: Brightness.dark);

      await expectLater(
        find.byType(FolderListScreen),
        matchesGoldenFile('folder_list_tablet_dark.png'),
      );
    });

    testWidgets('empty, light', (tester) async {
      await pumpFolders(
        tester,
        _phone,
        const FolderState.initial().copyWith(status: LoadStatus.empty),
      );

      await expectLater(
        find.byType(FolderListScreen),
        matchesGoldenFile('folder_list_empty_light.png'),
      );
    });
  });
}
