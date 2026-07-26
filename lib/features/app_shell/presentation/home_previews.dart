/// Widget previews for the Home screen and its widgets.
///
/// Each preview seeds a fake Cubit with fixtures, so nothing here reaches Isar,
/// the filesystem or a clock and a preview renders identically every time
/// (`design.md` §15).
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/previews/fakes/fake_cubit.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_cubit.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_state.dart';
import 'package:doc_forge/features/app_shell/presentation/screens/home_screen.dart';
import 'package:doc_forge/features/app_shell/presentation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Readers that answer instantly and hold nothing.
///
/// Present only to satisfy [LoadHomeData]'s constructor; the preview Cubit
/// overrides `load`, so none of these methods is ever reached. Three classes
/// rather than one because [DocumentReader] and [FolderReader] both declare a
/// `findById` and a single class cannot satisfy both signatures.
class _InertDocuments implements DocumentReader {
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
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);
}

/// A folder reader holding nothing.
class _InertFolders implements FolderReader {
  const _InertFolders();

  @override
  Future<Result<List<Folder>>> all() async =>
      const Result<List<Folder>>.success([]);

  @override
  Future<Result<Folder>> findById(FolderId id) async =>
      const Result<Folder>.failure(Failure.notFound());
}

/// A storage reader reporting nothing stored.
class _InertStorage implements StorageSummaryReader {
  const _InertStorage();

  @override
  Future<Result<StorageSummary>> summary() async =>
      const Result<StorageSummary>.success(StorageSummary.empty);
}

/// A [HomeCubit] frozen at a chosen state.
///
/// `load` is overridden to do nothing: Home loads on its first frame, which
/// would otherwise replace the seeded state and make every preview identical.
class _PreviewHomeCubit extends HomeCubit with SeededCubit<HomeState> {
  _PreviewHomeCubit(HomeState state)
    : super(
        const LoadHomeData(_InertDocuments(), _InertFolders(), _InertStorage()),
      ) {
    seed(state);
  }

  @override
  Future<void> load() async {}
}

/// Actions that record nothing, for previews.
final _noopActions = HomeActions(
  onScan: () {},
  onSearch: () {},
  onOpenDocument: (_) {},
  onOpenFolder: (_) {},
  onAllDocuments: () {},
  onFolders: () {},
  onFavourites: () {},
  onArchive: () {},
  onStorage: () {},
);

Widget _home(HomeState state) => BlocProvider<HomeCubit>(
  create: (_) => _PreviewHomeCubit(state),
  child: HomeScreen(actions: _noopActions),
);

/// A populated Home, the state most users see.
HomeState get _populated => HomeState.loaded(
  HomeData(
    recentDocuments: sampleDocuments(4),
    folders: sampleFolders(3),
    favouriteCount: 2,
    archivedCount: 1,
    storage: const StorageSummary(
      totalBytes: 42 * 1024 * 1024,
      documentCount: 18,
    ),
  ),
);

// ---------------------------------------------------------------------------
// Home screen
// ---------------------------------------------------------------------------

/// Home with documents, folders and a storage summary.
@Preview(name: 'Home — ready', group: 'Home', theme: appPreviewTheme)
Widget homeReady() => _home(_populated);

/// Home while its data loads.
@Preview(name: 'Home — loading', group: 'Home', theme: appPreviewTheme)
Widget homeLoading() => _home(const HomeState.loading());

/// Home before the first document is scanned.
@Preview(name: 'Home — empty', group: 'Home', theme: appPreviewTheme)
Widget homeEmpty() => _home(
  HomeState.loaded(
    const HomeData(
      recentDocuments: [],
      folders: [],
      favouriteCount: 0,
      archivedCount: 0,
      storage: StorageSummary.empty,
    ),
  ),
);

/// Home when its data could not be read.
@Preview(name: 'Home — error', group: 'Home', theme: appPreviewTheme)
Widget homeError() => _home(const HomeState.failed(Failure.storage()));

/// Home with documents whose titles are far too long for one line.
@Preview(name: 'Home — long titles', group: 'Home', theme: appPreviewTheme)
Widget homeLongTitles() => _home(
  HomeState.loaded(
    HomeData(
      recentDocuments: [for (var i = 0; i < 4; i++) longTitleDocument],
      folders: sampleFolders(2),
      favouriteCount: 0,
      archivedCount: 0,
      storage: const StorageSummary(totalBytes: 1024, documentCount: 4),
    ),
  ),
);

/// Home in dark mode.
@Preview(
  name: 'Home — dark',
  group: 'Home',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget homeDark() => _home(_populated);

/// Home on a tablet, where it uses the extra width.
@Preview(
  name: 'Home — tablet',
  group: 'Home',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget homeTablet() => _home(_populated);

/// Home on a tablet in dark mode.
@Preview(
  name: 'Home — tablet, dark',
  group: 'Home',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
)
Widget homeTabletDark() => _home(_populated);

/// Home at the largest supported text scale.
@Preview(
  name: 'Home — large text',
  group: 'Home',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget homeLargeText() => _home(_populated);

/// The empty state at the largest supported text scale.
@Preview(
  name: 'Home — empty, large text',
  group: 'Home',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget homeEmptyLargeText() => homeEmpty();

// ---------------------------------------------------------------------------
// Home widgets
// ---------------------------------------------------------------------------

/// The storage summary with a typical library.
@Preview(
  name: 'StorageSummaryCard — default',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget storageSummaryDefault() => previewSurface(
  StorageSummaryCard(
    summary: const StorageSummary(
      totalBytes: 42 * 1024 * 1024,
      documentCount: 18,
    ),
    onTap: () {},
  ),
);

/// The storage summary before anything is stored.
@Preview(
  name: 'StorageSummaryCard — empty',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget storageSummaryEmpty() =>
    previewSurface(const StorageSummaryCard(summary: StorageSummary.empty));

/// The storage summary with a library large enough to reach gigabytes.
@Preview(
  name: 'StorageSummaryCard — large',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget storageSummaryLarge() => previewSurface(
  StorageSummaryCard(
    summary: const StorageSummary(
      totalBytes: 3 * 1024 * 1024 * 1024,
      documentCount: 4213,
    ),
    onTap: () {},
  ),
);

/// The storage summary in dark mode.
@Preview(
  name: 'StorageSummaryCard — dark',
  group: 'Home widgets',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget storageSummaryDark() => previewSurface(
  StorageSummaryCard(
    summary: const StorageSummary(
      totalBytes: 5 * 1024 * 1024,
      documentCount: 9,
    ),
    onTap: () {},
  ),
);

/// A shortcut showing how many documents it leads to.
@Preview(
  name: 'HomeShortcut — with count',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget homeShortcutWithCount() => previewSurface(
  HomeShortcut(
    label: 'Favourites',
    icon: Icons.star_outline,
    count: 12,
    onTap: () {},
  ),
);

/// A shortcut with nothing behind it.
@Preview(
  name: 'HomeShortcut — zero',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget homeShortcutZero() => previewSurface(
  HomeShortcut(
    label: 'Archive',
    icon: Icons.inventory_2_outlined,
    count: 0,
    onTap: () {},
  ),
);

/// A shortcut at the largest supported text scale.
@Preview(
  name: 'HomeShortcut — large text',
  group: 'Home widgets',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget homeShortcutLargeText() => previewSurface(
  HomeShortcut(
    label: 'All documents',
    icon: Icons.folder_copy_outlined,
    count: 137,
    onTap: () {},
  ),
);

/// The recent documents section with a typical set.
@Preview(
  name: 'RecentDocumentsSection — default',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget recentDocumentsDefault() => previewSurface(
  RecentDocumentsSection(
    documents: sampleDocuments(4),
    onOpenDocument: (_) {},
    onSeeAll: () {},
  ),
);

/// The recent documents section with a single document.
@Preview(
  name: 'RecentDocumentsSection — one',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget recentDocumentsOne() => previewSurface(
  RecentDocumentsSection(documents: [sampleDocument], onOpenDocument: (_) {}),
);

/// The recent documents section with titles that must truncate.
@Preview(
  name: 'RecentDocumentsSection — long titles',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget recentDocumentsLongTitles() => previewSurface(
  RecentDocumentsSection(
    documents: [longTitleDocument, longTitleDocument],
    onOpenDocument: (_) {},
  ),
);

/// The recent documents section in dark mode.
@Preview(
  name: 'RecentDocumentsSection — dark',
  group: 'Home widgets',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget recentDocumentsDark() => previewSurface(
  RecentDocumentsSection(
    documents: sampleDocuments(3),
    onOpenDocument: (_) {},
    onSeeAll: () {},
  ),
);

/// The folders section with several folders.
@Preview(
  name: 'HomeFoldersSection — default',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget homeFoldersDefault() => previewSurface(
  HomeFoldersSection(
    folders: sampleFolders(4),
    onOpenFolder: (_) {},
    onSeeAll: () {},
  ),
);

/// The folders section before any folder exists.
@Preview(
  name: 'HomeFoldersSection — empty',
  group: 'Home widgets',
  theme: appPreviewTheme,
)
Widget homeFoldersEmpty() =>
    previewSurface(HomeFoldersSection(folders: const [], onOpenFolder: (_) {}));

/// The folders section in dark mode.
@Preview(
  name: 'HomeFoldersSection — dark',
  group: 'Home widgets',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget homeFoldersDark() => previewSurface(
  HomeFoldersSection(folders: sampleFolders(4), onOpenFolder: (_) {}),
);
