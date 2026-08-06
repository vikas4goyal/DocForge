/// Tier 2 — document detail over its real Cubit and real use cases.
///
/// Repositories and platform file/PDF edges are faked; loading, state
/// transitions, callback wiring and thumbnail orchestration are production
/// code. This closes the gap between isolated widget tests and the device flow.
library;

import 'dart:convert';
import 'dart:io';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_thumbnails.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:flutter/material.dart';
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
  late _ThumbnailCache thumbnails;
  late Directory directory;
  late File preview;

  setUp(() async {
    documents = FakeDocumentRepository([sampleDocument]);
    pages = FakePageRepository()..pages[sampleDocument.id] = samplePages(2);
    folders = FakeFolderRepository();
    derivedFiles = FakeDocumentFileStore();
    publicStore = InMemoryPublicFileStore()
      ..files[sampleDocument.relativePath] = 'pdf bytes';
    secrets = InMemorySecureStore();
    directory = await Directory.systemTemp.createTemp('detail_component_');
    preview = File('${directory.path}/preview.png');
    await preview.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
      ),
    );
    thumbnails = _ThumbnailCache(preview.path);
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    VoidCallback? onOpen,
    void Function(Document document)? onOpenDocument,
  }) async {
    final clock = FixedClock(DateTime.utc(2026, 8, 3));
    final loadThumbnail = LoadDocumentPageThumbnail(
      thumbnails,
      PublicStoreDocumentFileResolver(publicStore),
      secrets,
    );

    await pumpComponent(
      tester,
      DocumentDetailScreen(
        onClose: () {},
        onOpenViewer: onOpen,
        onOpenDocument: onOpenDocument,
        loadPageThumbnail: (document, page) =>
            loadThumbnail(document, page.pageNumber),
      ),
      providers: [
        BlocProvider(
          create: (_) => DocumentDetailCubit(
            sampleDocument.id,
            LoadDocumentDetail(documents, pages),
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

  testWidgets('ready detail exposes Open through the real load transition', (
    tester,
  ) async {
    var opened = false;

    await pumpDetail(tester, onOpen: () => opened = true);
    expectVisible(LibraryKeys.documentOpenButton);
    await tester.tap(find.byKey(LibraryKeys.documentOpenButton));

    expect(opened, isTrue);
  });

  testWidgets('visible pages derive previews through the real use case', (
    tester,
  ) async {
    await pumpDetail(tester, onOpen: () {});

    expect(thumbnails.requests, containsAll([1, 2]));
    expect(find.byType(Image), findsNWidgets(2));
    expect(publicStore.materialised, isEmpty);
    expect(tester.takeException(), isNull);
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

class _ThumbnailCache implements DocumentThumbnailCache {
  _ThumbnailCache(this.path);

  final String path;
  final List<int> requests = [];

  @override
  Future<Result<String>> thumbnailFor(
    Document document, {
    required String filePath,
    required int pageNumber,
    String? password,
  }) async {
    requests.add(pageNumber);
    return Result<String>.success(path);
  }

  @override
  Future<Result<void>> evict(DocumentId id) async =>
      const Result<void>.success(null);
}
