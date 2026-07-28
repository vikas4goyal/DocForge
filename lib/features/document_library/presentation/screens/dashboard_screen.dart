/// The dashboard: the library folder, as the user's own folder.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:doc_forge/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/document_card.dart';
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
  });

  /// Opens a document.
  final void Function(Document document) onOpenDocument;

  /// Creates a folder in the open folder.
  final void Function(String name) onCreateFolder;

  /// Brings an external PDF into the open folder.
  final VoidCallback onImportPdf;
}

/// Browses the library folder.
///
/// Only this folder and its descendants are reachable. That is the line between
/// a document application and a file manager, and it is drawn here as well as
/// in the path type: nothing on this screen can address anything outside it.
class DashboardScreen extends StatelessWidget {
  /// Creates the dashboard.
  const DashboardScreen({required this.actions, super.key});

  /// What each control does.
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final cubit = context.read<DashboardCubit>();

        return Scaffold(
          key: DashboardKeys.screen,
          appBar: AppBar(
            title: const Text('DocForge'),
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
            child: Column(
              children: [
                _SearchField(state: state, cubit: cubit),
                if (!state.isSearching) _Breadcrumb(state: state, cubit: cubit),
                Expanded(
                  child: _Body(state: state, actions: actions),
                ),
                if (!state.isSearching) _StorageSummary(state: state),
              ],
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

/// The folders and documents, or whatever stands in for them.
class _Body extends StatelessWidget {
  const _Body({required this.state, required this.actions});

  final DashboardState state;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();

    if (state.status == DashboardStatus.failure) {
      return AppErrorView(
        key: DashboardKeys.errorView,
        failure: state.failure ?? const Failure.unexpected(),
        retryKey: DashboardKeys.errorRetryButton,
        onRetry: cubit.load,
      );
    }

    if (state.isLoading) {
      return const AppLoadingIndicator(key: DashboardKeys.loadingIndicator);
    }

    if (state.isEmpty) {
      return AppEmptyState(
        key: DashboardKeys.emptyState,
        icon: state.isSearching ? Icons.search_off : Icons.folder_open_outlined,
        title: state.isSearching ? 'No matches' : 'Nothing here yet',
        message: state.isSearching
            ? 'No document matches what you typed.'
            : 'Create a PDF or import one to get started. '
                  'Everything you save lives in a folder you can also open '
                  'from your files app.',
      );
    }

    return RefreshIndicator(
      // Forced, because a pull-to-refresh is the user saying they know
      // something changed and the throttle should not swallow it.
      onRefresh: cubit.load,
      child: ListView.builder(
        key: DashboardKeys.contentList,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.folders.length + state.documents.length,
        itemBuilder: (context, index) {
          if (index < state.folders.length) {
            final folder = state.folders[index];
            return ListTile(
              key: DashboardKeys.folderRow(folder.name),
              leading: const Icon(Icons.folder_outlined),
              title: Text(folder.name),
              subtitle: Text(
                DisplayFormatting.documentCount(folder.documentCount),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => cubit.openFolder(folder.name),
            );
          }

          final document = state.documents[index - state.folders.length];
          return DocumentCard(
            document: document,
            onTap: () => actions.onOpenDocument(document),
          );
        },
      ),
    );
  }
}

/// How much space the library occupies.
class _StorageSummary extends StatelessWidget {
  const _StorageSummary({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Library uses ${DisplayFormatting.fileSize(state.storageBytes)}',
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
