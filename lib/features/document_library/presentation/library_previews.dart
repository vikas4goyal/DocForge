/// Widget previews for the document library.
///
/// Every reusable widget previews default, loading, empty, error and long
/// content; every screen adds phone, tablet, light and dark. Each preview is
/// fed by fixtures through a seeded Cubit, so nothing here reaches Isar, the
/// filesystem or a clock and a preview renders identically every time
/// (`design.md` §15).
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/previews/fakes/fake_cubit.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_forge/features/document_library/domain/repositories/document_file_store.dart';
import 'package:doc_forge/features/document_library/domain/repositories/library_repositories.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_state.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/document_card.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/folder_tile.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/page_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------------------------------------------------------------------------
// Inert collaborators
// ---------------------------------------------------------------------------

/// A repository that answers instantly and stores nothing.
///
/// Present only to satisfy the use-case constructors the real Cubits require.
/// The preview Cubits below never invoke a use case, so none of these methods
/// is ever reached — they exist so a preview cannot accidentally touch Isar.
class _InertDocuments implements DocumentRepository {
  const _InertDocuments();

  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      const Result<Document>.failure(Failure.notFound());

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => const Result<List<Document>>.success([]);

  @override
  Future<Result<Document>> save(Document document) async =>
      Result<Document>.success(document);

  @override
  Future<Result<void>> delete(DocumentId id) async =>
      const Result<void>.success(null);

  @override
  Future<Result<int>> count({
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) async => const Result<int>.success(0);

  @override
  Future<Result<int>> totalSizeInBytes() async => const Result<int>.success(0);
}

/// A folder repository that answers instantly and stores nothing.
class _InertFolders implements FolderRepository {
  const _InertFolders();

  @override
  Future<Result<List<Folder>>> all() async =>
      const Result<List<Folder>>.success([]);

  @override
  Future<Result<Folder>> findById(FolderId id) async =>
      const Result<Folder>.failure(Failure.notFound());

  @override
  Future<Result<Folder?>> findByName(String name) async =>
      const Result<Folder?>.success(null);

  @override
  Future<Result<Folder?>> findByRelativePath(String relativePath) async =>
      const Result<Folder?>.success(null);

  @override
  Future<Result<Folder>> save(Folder folder) async =>
      Result<Folder>.success(folder);

  @override
  Future<Result<void>> delete(FolderId id) async =>
      const Result<void>.success(null);
}

/// A page repository that answers instantly and stores nothing.
class _InertPages implements PageRepository {
  const _InertPages();

  @override
  Future<Result<List<DocumentPage>>> forDocument(DocumentId documentId) async =>
      const Result<List<DocumentPage>>.success([]);

  @override
  Future<Result<void>> replaceAll(
    DocumentId documentId,
    List<DocumentPage> pages,
  ) async => const Result<void>.success(null);

  @override
  Future<Result<void>> deleteForDocument(DocumentId documentId) async =>
      const Result<void>.success(null);
}

/// A file store that touches no filesystem.
class _InertFiles implements DocumentFileStore {
  const _InertFiles();

  @override
  Future<Result<Directory>> initialise() async =>
      Result<Directory>.success(Directory.systemTemp);

  @override
  Future<Result<Directory>> directoryFor(DocumentId id) async =>
      Result<Directory>.success(Directory.systemTemp);

  @override
  Future<Result<String>> pdfPathFor(DocumentId id) async =>
      const Result<String>.success('');

  @override
  Future<Result<String>> pagePathFor(
    DocumentId documentId,
    PageId pageId,
  ) async => const Result<String>.success('');

  @override
  Future<Result<String>> thumbnailPathFor(
    DocumentId documentId,
    PageId pageId,
  ) async => const Result<String>.success('');

  @override
  Future<Result<void>> deleteDocument(DocumentId id) async =>
      const Result<void>.success(null);

  @override
  Future<Result<void>> copyDocument(DocumentId from, DocumentId to) async =>
      const Result<void>.success(null);

  @override
  Future<Result<int>> totalBytes() async => const Result<int>.success(0);
}

final _clock = FixedClock(fixtureNow);
final _ids = SequentialIdGenerator(prefix: 'preview');
const _documents = _InertDocuments();
const _folders = _InertFolders();
const _pages = _InertPages();
const _files = _InertFiles();
final _store = InMemoryPublicFileStore();
final _secure = InMemorySecureStore();

// ---------------------------------------------------------------------------
// Preview Cubits
// ---------------------------------------------------------------------------

/// A [DocumentListCubit] frozen at a chosen state.
///
/// `load` is overridden to do nothing: the screens load on their first frame,
/// which would otherwise immediately replace the seeded state with an empty one
/// and every preview would look identical.
class _PreviewListCubit extends DocumentListCubit
    with SeededCubit<DocumentListState> {
  _PreviewListCubit(DocumentListState state)
    : super(
        const LoadDocuments(_documents),
        ToggleFavourite(_documents, _clock),
        ArchiveDocument(_documents, _clock),
        RestoreDocument(_documents, _clock),
      ) {
    seed(state);
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async {}
}

/// A [DocumentDetailCubit] frozen at a chosen state.
class _PreviewDetailCubit extends DocumentDetailCubit
    with SeededCubit<DocumentDetailState> {
  _PreviewDetailCubit(DocumentDetailState state)
    : super(
        sampleDocument.id,
        const LoadDocumentDetail(_documents, _pages),
        RenameDocument(_documents, _clock),
        MoveDocument(_documents, _clock),
        ToggleFavourite(_documents, _clock),
        ArchiveDocument(_documents, _clock),
        RestoreDocument(_documents, _clock),
        DuplicateDocument(_documents, _pages, _store, _clock, _ids),
        PurgeDocument(_documents, _pages, _store, _files, _secure),
      ) {
    seed(state);
  }

  @override
  Future<void> load() async {}
}

/// A [FolderCubit] frozen at a chosen state.
class _PreviewFolderCubit extends FolderCubit with SeededCubit<FolderState> {
  _PreviewFolderCubit(FolderState state)
    : super(
        const LoadFolders(_folders),
        CreateFolder(_folders, _clock, _ids),
        const RenameFolder(_folders),
        DeleteFolder(
          _folders,
          _documents,
          MoveDocument(_documents, _clock),
          PurgeDocument(_documents, _pages, _store, _files, _secure),
        ),
      ) {
    seed(state);
  }

  @override
  Future<void> load() async {}
}

Widget _list(DocumentListState state, {String title = 'Documents'}) =>
    BlocProvider<DocumentListCubit>(
      create: (_) => _PreviewListCubit(state),
      child: DocumentListScreen(
        title: title,
        onOpenDocument: (_) {},
        onScan: () {},
      ),
    );

Widget _detail(DocumentDetailState state) => BlocProvider<DocumentDetailCubit>(
  create: (_) => _PreviewDetailCubit(state),
  child: DocumentDetailScreen(onClose: () {}, onOpenViewer: () {}),
);

Widget _folderList(FolderState state) => BlocProvider<FolderCubit>(
  create: (_) => _PreviewFolderCubit(state),
  child: FolderListScreen(onOpenFolder: (_) {}),
);

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

/// A document row in its default state.
@Preview(
  name: 'DocumentCard — default',
  group: 'Library',
  theme: appPreviewTheme,
)
Widget documentCardDefault() => previewSurface(
  DocumentCard(
    document: sampleDocument,
    onTap: () {},
    onToggleFavourite: () {},
  ),
);

/// A document row marked as a favourite.
@Preview(
  name: 'DocumentCard — favourite',
  group: 'Library',
  theme: appPreviewTheme,
)
Widget documentCardFavourite() => previewSurface(
  DocumentCard(
    document: favouriteDocument,
    onTap: () {},
    onToggleFavourite: () {},
  ),
);

/// A document row whose title exceeds the available width.
@Preview(
  name: 'DocumentCard — long title',
  group: 'Library',
  theme: appPreviewTheme,
)
Widget documentCardLongTitle() =>
    previewSurface(DocumentCard(document: longTitleDocument, onTap: () {}));

/// A document row at the largest supported text scale.
@Preview(
  name: 'DocumentCard — large text',
  group: 'Library',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget documentCardLargeText() =>
    previewSurface(DocumentCard(document: sampleDocument, onTap: () {}));

/// A document row in dark mode.
@Preview(
  name: 'DocumentCard — dark',
  group: 'Library',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget documentCardDark() => previewSurface(
  DocumentCard(
    document: sampleDocument,
    onTap: () {},
    onToggleFavourite: () {},
  ),
);

/// A folder row with documents in it.
@Preview(name: 'FolderTile — default', group: 'Library', theme: appPreviewTheme)
Widget folderTileDefault() => previewSurface(
  FolderTile(
    folder: sampleFolder.copyWith(documentCount: 12),
    onTap: () {},
    onRename: () {},
    onDelete: () {},
  ),
);

/// An empty folder row.
@Preview(name: 'FolderTile — empty', group: 'Library', theme: appPreviewTheme)
Widget folderTileEmpty() =>
    previewSurface(FolderTile(folder: sampleFolder, onTap: () {}));

/// A folder row in dark mode.
@Preview(
  name: 'FolderTile — dark',
  group: 'Library',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget folderTileDark() => previewSurface(
  FolderTile(folder: sampleFolder.copyWith(documentCount: 3), onTap: () {}),
);

/// A page thumbnail with no cached image yet.
@Preview(
  name: 'PageThumbnail — placeholder',
  group: 'Library',
  theme: appPreviewTheme,
)
Widget pageThumbnailPlaceholder() =>
    previewSurface(PageThumbnail(page: samplePages(1).first, onTap: () {}));

/// A row of page thumbnails.
@Preview(
  name: 'PageThumbnail — strip',
  group: 'Library',
  theme: appPreviewTheme,
)
Widget pageThumbnailStrip() => previewSurface(
  SizedBox(
    height: 160,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final page in samplePages(5))
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PageThumbnail(page: page),
          ),
      ],
    ),
  ),
);

// ---------------------------------------------------------------------------
// Document list screen
// ---------------------------------------------------------------------------

/// A populated document list.
@Preview(
  name: 'DocumentList — ready',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentListReady() => _list(
  DocumentListState(status: LoadStatus.ready, documents: sampleDocuments(8)),
);

/// A document list still loading.
@Preview(
  name: 'DocumentList — loading',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentListLoading() =>
    _list(const DocumentListState(status: LoadStatus.loading));

/// A document list with nothing in it.
@Preview(
  name: 'DocumentList — empty',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentListEmpty() =>
    _list(const DocumentListState(status: LoadStatus.empty));

/// A document list that failed to load.
@Preview(
  name: 'DocumentList — error',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentListError() => _list(
  const DocumentListState(
    status: LoadStatus.failure,
    failure: Failure.storage(),
  ),
);

/// A document list of documents with very long titles.
@Preview(
  name: 'DocumentList — long titles',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentListLongTitles() => _list(
  DocumentListState(
    status: LoadStatus.ready,
    documents: [for (var i = 0; i < 6; i++) longTitleDocument],
  ),
);

/// A populated document list in dark mode.
@Preview(
  name: 'DocumentList — dark',
  group: 'Library screens',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget documentListDark() => _list(
  DocumentListState(status: LoadStatus.ready, documents: sampleDocuments(8)),
);

/// A populated document list on a tablet, where it uses multiple columns.
@Preview(
  name: 'DocumentList — tablet',
  group: 'Library screens',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget documentListTablet() => _list(
  DocumentListState(status: LoadStatus.ready, documents: sampleDocuments(12)),
);

/// The archive, which offers no scanning call to action.
@Preview(
  name: 'DocumentList — archive',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentListArchive() => BlocProvider<DocumentListCubit>(
  create: (_) => _PreviewListCubit(
    DocumentListState(
      status: LoadStatus.ready,
      filter: DocumentFilter.archived,
      documents: [archivedDocument],
    ),
  ),
  child: DocumentListScreen(title: 'Archive', onOpenDocument: (_) {}),
);

// ---------------------------------------------------------------------------
// Document detail screen
// ---------------------------------------------------------------------------

/// A loaded document with its pages.
@Preview(
  name: 'DocumentDetail — ready',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentDetailReady() => _detail(
  DocumentDetailState(
    status: LoadStatus.ready,
    document: sampleDocument,
    pages: samplePages(4),
  ),
);

/// A document detail screen still loading.
@Preview(
  name: 'DocumentDetail — loading',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentDetailLoading() =>
    _detail(const DocumentDetailState(status: LoadStatus.loading));

/// A document detail screen whose document could not be read.
@Preview(
  name: 'DocumentDetail — error',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentDetailError() => _detail(
  const DocumentDetailState(
    status: LoadStatus.failure,
    failure: Failure.notFound(),
  ),
);

/// A document whose page previews are unavailable.
@Preview(
  name: 'DocumentDetail — no thumbnails',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentDetailNoThumbnails() => _detail(
  // A document whose thumbnails have not been generated yet: the metadata is
  // fully readable and the page strip explains its own absence.
  DocumentDetailState(status: LoadStatus.ready, document: sampleDocument),
);

/// A document with a very long title.
@Preview(
  name: 'DocumentDetail — long title',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget documentDetailLongTitle() => _detail(
  DocumentDetailState(
    status: LoadStatus.ready,
    document: longTitleDocument,
    pages: samplePages(2),
  ),
);

/// A loaded document in dark mode.
@Preview(
  name: 'DocumentDetail — dark',
  group: 'Library screens',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget documentDetailDark() => _detail(
  DocumentDetailState(
    status: LoadStatus.ready,
    document: sampleDocument,
    pages: samplePages(4),
  ),
);

/// A loaded document on a tablet.
@Preview(
  name: 'DocumentDetail — tablet',
  group: 'Library screens',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget documentDetailTablet() => _detail(
  DocumentDetailState(
    status: LoadStatus.ready,
    document: sampleDocument,
    pages: samplePages(6),
  ),
);

// ---------------------------------------------------------------------------
// Folder list screen
// ---------------------------------------------------------------------------

/// A populated folder list.
@Preview(
  name: 'FolderList — ready',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget folderListReady() => _folderList(
  FolderState(status: LoadStatus.ready, folders: sampleFolders(5)),
);

/// A folder list still loading.
@Preview(
  name: 'FolderList — loading',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget folderListLoading() =>
    _folderList(const FolderState(status: LoadStatus.loading));

/// A folder list with no folders.
@Preview(
  name: 'FolderList — empty',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget folderListEmpty() =>
    _folderList(const FolderState(status: LoadStatus.empty));

/// A folder list that failed to load.
@Preview(
  name: 'FolderList — error',
  group: 'Library screens',
  theme: appPreviewTheme,
)
Widget folderListError() => _folderList(
  const FolderState(status: LoadStatus.failure, failure: Failure.storage()),
);

/// A populated folder list in dark mode.
@Preview(
  name: 'FolderList — dark',
  group: 'Library screens',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget folderListDark() => _folderList(
  FolderState(status: LoadStatus.ready, folders: sampleFolders(5)),
);

/// A populated folder list on a tablet.
@Preview(
  name: 'FolderList — tablet',
  group: 'Library screens',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget folderListTablet() => _folderList(
  FolderState(status: LoadStatus.ready, folders: sampleFolders(8)),
);
