/// Golden tests for the document list and the folder list.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_scanly/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_state.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/folder_state.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/folder_list_screen.dart';
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
  libraryPath: LibraryPath.parse('$index.pdf'),
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
          PurgeDocument(
            _documents,
            _pages,
            InMemoryPublicFileStore(),
            _files,
            InMemorySecureStore(),
          ),
        ),
      );

  final FolderState _seeded;

  @override
  FolderState get state => _seeded;

  @override
  Future<void> load() async {}
}

/// A detail Cubit frozen at a chosen ready state.
class _SeededDetailCubit extends DocumentDetailCubit {
  _SeededDetailCubit(this._seeded)
    : super(
        _seeded.document!.id,
        LoadDocumentDetail(_documents),
        RenameDocument(_documents, _clock, InMemoryPublicFileStore()),
        MoveDocument(_documents, _clock),
        ToggleFavourite(_documents, _clock),
        ArchiveDocument(_documents, _clock),
        RestoreDocument(_documents, _clock),
        DuplicateDocument(
          _documents,
          _pages,
          InMemoryPublicFileStore(),
          _clock,
          SequentialIdGenerator(),
        ),
        PurgeDocument(
          _documents,
          _pages,
          InMemoryPublicFileStore(),
          _files,
          InMemorySecureStore(),
        ),
      );

  final DocumentDetailState _seeded;

  @override
  DocumentDetailState get state => _seeded;

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

  Future<void> pumpDetail(
    WidgetTester tester,
    Size size,
    DocumentDetailState state, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _SeededDetailCubit(state);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<DocumentDetailCubit>.value(
          value: cubit,
          child: DocumentDetailScreen(onClose: () {}),
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

  final detail = const DocumentDetailState.initial().copyWith(
    status: LoadStatus.ready,
    document: _document(0),
  );

  group('document detail goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpDetail(tester, _phone, detail);

      await expectLater(
        find.byType(DocumentDetailScreen),
        matchesGoldenFile('document_detail_phone_light.png'),
      );
    });

    testWidgets('remote iCloud document', (tester) async {
      await pumpDetail(
        tester,
        _phone,
        detail.copyWith(
          document: _document(0).copyWith(
            cloudResourceIdentifier: 'golden-resource',
            contentAvailability: DocumentContentAvailability.remote,
          ),
        ),
      );

      await expectLater(
        find.byType(DocumentDetailScreen),
        matchesGoldenFile('document_detail_icloud_remote.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpDetail(tester, _phone, detail, brightness: Brightness.dark);

      await expectLater(
        find.byType(DocumentDetailScreen),
        matchesGoldenFile('document_detail_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpDetail(tester, _tablet, detail);

      await expectLater(
        find.byType(DocumentDetailScreen),
        matchesGoldenFile('document_detail_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpDetail(tester, _tablet, detail, brightness: Brightness.dark);

      await expectLater(
        find.byType(DocumentDetailScreen),
        matchesGoldenFile('document_detail_tablet_dark.png'),
      );
    });
  });

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

    testWidgets('mixed iCloud availability', (tester) async {
      final values = [
        DocumentContentAvailability.remote,
        DocumentContentAvailability.downloading,
        DocumentContentAvailability.available,
        DocumentContentAvailability.failed,
      ];
      await pumpList(
        tester,
        _phone,
        documents.copyWith(
          documents: [
            for (var index = 0; index < values.length; index++)
              _document(index).copyWith(
                cloudResourceIdentifier: 'resource-$index',
                contentAvailability: values[index],
              ),
          ],
        ),
      );

      await expectLater(
        find.byType(DocumentListScreen),
        matchesGoldenFile('document_list_icloud_statuses.png'),
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
