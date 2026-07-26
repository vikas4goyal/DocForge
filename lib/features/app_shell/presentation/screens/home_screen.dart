/// The Home screen — the application's primary screen.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_cubit.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_state.dart';
import 'package:doc_forge/features/app_shell/presentation/home_keys.dart';
import 'package:doc_forge/features/app_shell/presentation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The actions Home can start.
///
/// Grouped into one object rather than a dozen constructor parameters: the set
/// grows with every capability, and a positional list of that length is where
/// two callbacks quietly get swapped.
@immutable
class HomeActions {
  /// Creates the action set.
  const HomeActions({
    required this.onScan,
    required this.onSearch,
    required this.onOpenDocument,
    required this.onOpenFolder,
    required this.onAllDocuments,
    required this.onFolders,
    required this.onFavourites,
    required this.onArchive,
    this.onStorage,
  });

  /// Starts the scanning flow.
  final VoidCallback onScan;

  /// Opens search.
  final VoidCallback onSearch;

  /// Opens a document.
  final void Function(DocumentId id) onOpenDocument;

  /// Opens a folder.
  final void Function(FolderId id) onOpenFolder;

  /// Opens the full document list.
  final VoidCallback onAllDocuments;

  /// Opens the folder list.
  final VoidCallback onFolders;

  /// Opens favourites.
  final VoidCallback onFavourites;

  /// Opens the archive.
  final VoidCallback onArchive;

  /// Opens storage details. When null the summary is not tappable.
  final VoidCallback? onStorage;
}

/// The application's primary screen.
///
/// Reloads whenever it becomes visible rather than caching its first result:
/// the spec requires a newly saved document to appear in recents, and the
/// storage summary to shrink after a deletion, without an app restart.
class HomeScreen extends StatefulWidget {
  /// Creates the Home screen.
  const HomeScreen({required this.actions, super.key});

  /// What each control on Home does.
  final HomeActions actions;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<HomeCubit>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: HomeKeys.screen,
      appBar: AppBar(
        title: const Text('DocForge'),
        actions: [
          Semantics(
            button: true,
            label: 'Search documents',
            child: ExcludeSemantics(
              child: IconButton(
                key: HomeKeys.searchBar,
                onPressed: widget.actions.onSearch,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: HomeKeys.scanButton,
        onPressed: widget.actions.onScan,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan document'),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => switch (state.status) {
          HomeStatus.initial || HomeStatus.loading => const AppLoadingIndicator(
            key: HomeKeys.loadingIndicator,
          ),
          HomeStatus.failure => AppErrorView(
            key: HomeKeys.errorView,
            failure: state.failure ?? const Failure.unexpected(),
            retryKey: HomeKeys.errorRetryButton,
            onRetry: () => context.read<HomeCubit>().load(),
          ),
          HomeStatus.empty => AppEmptyState(
            key: HomeKeys.emptyState,
            icon: Icons.document_scanner_outlined,
            title: 'No documents yet',
            message:
                'Scan your first document to get started. '
                'Everything stays on this device.',
            actionLabel: 'Scan a document',
            // Identical to the Scan Document action, as the spec requires:
            // the same callback, not a second path that could diverge.
            onAction: widget.actions.onScan,
          ),
          HomeStatus.ready => _HomeBody(
            state: state,
            actions: widget.actions,
            onRefresh: context.read<HomeCubit>().load,
          ),
        },
      ),
    );
  }
}

/// The populated Home layout.
class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.state,
    required this.actions,
    required this.onRefresh,
  });

  final HomeState state;
  final HomeActions actions;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ResponsiveLayout(compact: _singleColumn, expanded: _twoColumn),
    );
  }

  /// Phone layout: one column, everything stacked.
  Widget _singleColumn(BuildContext context) {
    return ListView(
      // Always scrollable so pull-to-refresh works even when the content fits,
      // and so every section stays reachable at the maximum text scale.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        StorageSummaryCard(summary: state.storage, onTap: actions.onStorage),
        const SizedBox(height: 16),
        ..._shortcuts(),
        const SizedBox(height: 24),
        if (state.showsRecentDocuments) ...[
          RecentDocumentsSection(
            documents: state.recentDocuments,
            onOpenDocument: actions.onOpenDocument,
            onSeeAll: actions.onAllDocuments,
          ),
          const SizedBox(height: 24),
        ],
        HomeFoldersSection(
          folders: state.folders,
          onOpenFolder: actions.onOpenFolder,
          onSeeAll: actions.onFolders,
        ),
      ],
    );
  }

  /// Tablet layout: shortcuts and storage beside the content.
  ///
  /// Uses the extra width rather than stretching phone-width content across it,
  /// which the spec calls out explicitly.
  Widget _twoColumn(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StorageSummaryCard(
                    summary: state.storage,
                    onTap: actions.onStorage,
                  ),
                  const SizedBox(height: 16),
                  ..._shortcuts(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.showsRecentDocuments) ...[
                    RecentDocumentsSection(
                      documents: state.recentDocuments,
                      onOpenDocument: actions.onOpenDocument,
                      onSeeAll: actions.onAllDocuments,
                    ),
                    const SizedBox(height: 24),
                  ],
                  HomeFoldersSection(
                    folders: state.folders,
                    onOpenFolder: actions.onOpenFolder,
                    onSeeAll: actions.onFolders,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The four library shortcuts, in one place so both layouts stay in step.
  List<Widget> _shortcuts() => [
    HomeShortcut(
      key: HomeKeys.allDocumentsShortcut,
      label: 'All documents',
      icon: Icons.folder_copy_outlined,
      count: state.storage.documentCount,
      onTap: actions.onAllDocuments,
    ),
    const SizedBox(height: 8),
    HomeShortcut(
      key: HomeKeys.favouritesShortcut,
      label: 'Favourites',
      icon: Icons.star_outline,
      count: state.favouriteCount,
      onTap: actions.onFavourites,
    ),
    const SizedBox(height: 8),
    HomeShortcut(
      key: HomeKeys.archiveShortcut,
      label: 'Archive',
      icon: Icons.inventory_2_outlined,
      count: state.archivedCount,
      onTap: actions.onArchive,
    ),
  ];
}
