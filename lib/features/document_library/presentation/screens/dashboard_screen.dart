/// The dashboard: the library folder, as the user's own folder.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/formatting/display_formatting.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_card.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the dashboard can start.
@immutable
class DashboardActions {
  /// Creates the action set.
  const DashboardActions({
    required this.onOpenDocument,
    required this.onCreateFolder,
    required this.onImportPdf,
    this.onOpenFavourites,
    this.onOpenArchive,
    this.onOpenTrash,
  });

  /// Opens a document.
  final void Function(Document document) onOpenDocument;

  /// Creates a folder in the open folder.
  final void Function(String name) onCreateFolder;

  /// Brings an external PDF into the open folder.
  final VoidCallback onImportPdf;

  /// Opens favourites.
  final VoidCallback? onOpenFavourites;

  /// Opens Archive.
  final VoidCallback? onOpenArchive;

  /// Opens recoverable Trash.
  final VoidCallback? onOpenTrash;
}

/// Browses the library folder.
///
/// Only this folder and its descendants are reachable. That is the line between
/// a document application and a file manager, and it is drawn here as well as
/// in the path type: nothing on this screen can address anything outside it.
class DashboardScreen extends StatelessWidget {
  /// Creates the dashboard.
  const DashboardScreen({
    required this.actions,
    super.key,
    this.loadThumbnail,
    this.onLibraryRefresh,
    this.libraryRefreshKey,
  });

  /// What each control does.
  final DashboardActions actions;

  /// Lazily resolves bounded first-page previews for visible documents.
  final DocumentThumbnailLoader? loadThumbnail;

  /// Reconciles externally changed storage before the Cubit reloads its index.
  final Future<void> Function()? onLibraryRefresh;

  /// Optional platform-specific key for the pull-to-refresh control.
  final Key? libraryRefreshKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final cubit = context.read<DashboardCubit>();

        return Scaffold(
          key: DashboardKeys.screen,
          appBar: AppBar(
            title: const Text('DocScanly'),
            actions: [
              IconButton(
                key: DashboardKeys.createFolderButton,
                tooltip: 'New folder',
                onPressed: () => _promptForFolder(context, cubit),
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
              IconButton(
                key: DashboardKeys.importPdfButton,
                tooltip: 'Import PDF',
                onPressed: actions.onImportPdf,
                icon: const Icon(Icons.file_open_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              key: libraryRefreshKey,
              onRefresh: () async {
                await onLibraryRefresh?.call();
                await cubit.load();
              },
              child: CustomScrollView(
                key: DashboardKeys.scrollView,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _SearchField(state: state, cubit: cubit),
                  ),
                  if (!state.isSearching && !state.isAtRoot)
                    SliverToBoxAdapter(
                      child: _Breadcrumb(state: state, cubit: cubit),
                    ),
                  if (state.isAtRoot && !state.isSearching)
                    SliverToBoxAdapter(
                      child: _Collections(state: state, actions: actions),
                    ),
                  if (state.showsRecents)
                    SliverToBoxAdapter(
                      child: _Recents(
                        state: state,
                        actions: actions,
                        loadThumbnail: loadThumbnail,
                      ),
                    ),
                  _Body(
                    state: state,
                    actions: actions,
                    loadThumbnail: loadThumbnail,
                  ),
                  if (!state.isSearching)
                    SliverToBoxAdapter(child: _StorageSummary(state: state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Asks for a folder name and creates it.
  Future<void> _promptForFolder(
    BuildContext context,
    DashboardCubit cubit,
  ) async {
    var name = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: DashboardKeys.createFolderDialog,
        title: const Text('New folder'),
        content: TextField(
          key: DashboardKeys.createFolderField,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (value) => name = value,
          onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: DashboardKeys.createFolderConfirm,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    // Validation is the use case's, not the dialog's: a name the filesystem
    // will refuse has to be refused the same way wherever it is entered.
    if (confirmed ?? false) actions.onCreateFolder(name);
  }
}

class _Collections extends StatelessWidget {
  const _Collections({required this.state, required this.actions});

  final DashboardState state;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Collections',
      child: SizedBox(
        key: DashboardKeys.collections,
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _CollectionChip(
              key: DashboardKeys.favouritesCollection,
              icon: Icons.star_outline,
              label: 'Favourites',
              count: state.favouritesCount,
              onTap: actions.onOpenFavourites,
            ),
            _CollectionChip(
              key: DashboardKeys.archiveCollection,
              icon: Icons.archive_outlined,
              label: 'Archive',
              count: state.archiveCount,
              onTap: actions.onOpenArchive,
            ),
            _CollectionChip(
              key: DashboardKeys.trashCollection,
              icon: Icons.delete_outline,
              label: 'Trash',
              count: state.trashCount,
              onTap: actions.onOpenTrash,
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  const _CollectionChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text('$label ($count)'),
        onPressed: onTap,
      ),
    );
  }
}

/// Searches across the whole library.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.state, required this.cubit});

  final DashboardState state;
  final DashboardCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        key: DashboardKeys.searchField,
        decoration: InputDecoration(
          hintText: 'Search all documents',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: state.isSearching
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: cubit.clearSearch,
                  icon: const Icon(Icons.close),
                )
              : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: cubit.search,
      ),
    );
  }
}

/// The path from the library root to the open folder.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.state, required this.cubit});

  final DashboardState state;
  final DashboardCubit cubit;

  @override
  Widget build(BuildContext context) {
    final crumbs = state.breadcrumb;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        key: DashboardKeys.breadcrumb,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: crumbs.length,
        separatorBuilder: (_, _) => const Icon(Icons.chevron_right, size: 16),
        itemBuilder: (context, index) {
          final isLast = index == crumbs.length - 1;

          return Center(
            child: TextButton(
              key: index == 0 ? DashboardKeys.breadcrumbRoot : null,
              // The root crumb is index 0 and names the library itself, so a
              // path of n segments is the crumb list minus that one.
              onPressed: isLast
                  ? null
                  : () => cubit.openPath(state.path.sublist(0, index)),
              child: Text(crumbs[index]),
            ),
          );
        },
      ),
    );
  }
}

/// The most recently modified documents, from anywhere in the library.
class _Recents extends StatelessWidget {
  const _Recents({
    required this.state,
    required this.actions,
    required this.loadThumbnail,
  });

  final DashboardState state;
  final DashboardActions actions;
  final DocumentThumbnailLoader? loadThumbnail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Text(
              'Recent',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Recently modified documents',
              child: ListView.separated(
                key: DashboardKeys.recents,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                itemCount: state.recents.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final document = state.recents[index];
                  return _RecentDocument(
                    document: document,
                    loadThumbnail: loadThumbnail,
                    onTap: () => actions.onOpenDocument(document),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentDocument extends StatelessWidget {
  const _RecentDocument({
    required this.document,
    required this.onTap,
    required this.loadThumbnail,
  });

  final Document document;
  final VoidCallback onTap;
  final DocumentThumbnailLoader? loadThumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: DisplayFormatting.documentSemanticsLabel(document),
      child: ExcludeSemantics(
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            key: DashboardKeys.recentDocument(document.id.value),
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(
              width: 156,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    DocumentThumbnail(
                      document: document,
                      loadThumbnail: loadThumbnail,
                      width: 34,
                      height: 44,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        document.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The folders and documents, or whatever stands in for them.
class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.actions,
    required this.loadThumbnail,
  });

  final DashboardState state;
  final DashboardActions actions;
  final DocumentThumbnailLoader? loadThumbnail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();

    if (state.status == DashboardStatus.failure) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorView(
          key: DashboardKeys.errorView,
          failure: state.failure ?? const Failure.unexpected(),
          retryKey: DashboardKeys.errorRetryButton,
          onRetry: cubit.load,
        ),
      );
    }

    if (state.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppLoadingIndicator(key: DashboardKeys.loadingIndicator),
      );
    }

    if (state.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          key: DashboardKeys.emptyState,
          icon: state.isSearching
              ? Icons.search_off
              : Icons.folder_open_outlined,
          title: state.isSearching ? 'No matches' : 'Nothing here yet',
          message: state.isSearching
              ? 'No document matches what you typed.'
              : 'Create a PDF or import one to get started. '
                    'Everything you save lives in a folder you can also open '
                    'from your files app.',
        ),
      );
    }

    return SliverList(
      key: DashboardKeys.contentList,
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < state.folders.length) {
          final folder = state.folders[index];
          return ListTile(
            key: DashboardKeys.folderRow(folder.name),
            leading: const Icon(Icons.folder_outlined),
            title: Text(folder.name),
            subtitle: Text(
              DisplayFormatting.documentCount(folder.documentCount),
            ),
            trailing: PopupMenuButton<_FolderAction>(
              key: DashboardKeys.folderMenu(folder.name),
              tooltip: 'Actions for ${folder.name}',
              onSelected: (action) => switch (action) {
                _FolderAction.rename => _renameFolder(
                  context,
                  cubit,
                  folder.name,
                ),
                _FolderAction.trash => _moveFolderToTrash(
                  context,
                  cubit,
                  folder.name,
                ),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  key: DashboardKeys.folderRename,
                  value: _FolderAction.rename,
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  key: DashboardKeys.folderTrash,
                  value: _FolderAction.trash,
                  child: Text('Move to Trash'),
                ),
              ],
            ),
            onTap: () => cubit.openFolder(folder.name),
          );
        }

        final document = state.documents[index - state.folders.length];
        return DocumentCard(
          document: document,
          loadThumbnail: loadThumbnail,
          onTap: () => actions.onOpenDocument(document),
        );
      }, childCount: state.folders.length + state.documents.length),
    );
  }

  Future<void> _renameFolder(
    BuildContext context,
    DashboardCubit cubit,
    String name,
  ) async {
    var newName = name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename $name'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: name),
          onChanged: (value) => newName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    final result = await cubit.renameFolder(name, newName);
    if (!context.mounted || result.isSuccess) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.failureOrNull!.presentation.message)),
    );
  }

  Future<void> _moveFolderToTrash(
    BuildContext context,
    DashboardCubit cubit,
    String name,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final inspected = cubit.inspectFolder(name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: DashboardKeys.trashConfirmDialog,
        title: Text('Move $name to Trash?'),
        content: FutureBuilder(
          future: inspected,
          builder: (context, snapshot) {
            final result = snapshot.data;
            if (result == null) {
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Flexible(child: Text('Checking folder contents…')),
                ],
              );
            }
            if (result.isFailure) {
              return Text(result.failureOrNull!.presentation.message);
            }
            final inventory = result.valueOrNull!;
            return Text(
              '${inventory.fileCount} files and '
              '${inventory.folderCount} subfolders will move together. '
              'You can restore them for 30 days; after that they are '
              'permanently deleted.',
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FutureBuilder(
            future: inspected,
            builder: (context, snapshot) {
              final result = snapshot.data;
              if (result == null || result.isFailure) {
                return const FilledButton(
                  onPressed: null,
                  child: Text('Move to Trash'),
                );
              }
              return FilledButton(
                key: DashboardKeys.trashConfirm,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Move to Trash'),
              );
            },
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    final moved = await cubit.trashFolder(name);
    if (!messenger.mounted) return;
    if (moved.isFailure) {
      messenger.showSnackBar(
        SnackBar(
          key: DashboardKeys.trashMoveFailure,
          content: Text(moved.failureOrNull!.presentation.message),
        ),
      );
      return;
    }
    final entry = moved.valueOrNull!;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Moved to Trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => cubit.undoTrash(entry.id),
        ),
      ),
    );
  }
}

enum _FolderAction { rename, trash }

/// How much space the library occupies.
class _StorageSummary extends StatelessWidget {
  const _StorageSummary({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: LibrarySemantics.storageUsage(
        DisplayFormatting.fileSize(state.storageBytes),
      ),
      child: ExcludeSemantics(
        child: Padding(
          key: DashboardKeys.storageSummary,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.sd_storage_outlined, size: 16),
              const SizedBox(width: 8),
              Text(
                DisplayFormatting.fileSize(state.storageBytes),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
