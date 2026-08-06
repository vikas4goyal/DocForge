/// The folder list.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/folder_state.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/folder_tile.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/library_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows every folder with its document count, and the actions on them.
class FolderListScreen extends StatefulWidget {
  /// Creates the folder list.
  const FolderListScreen({required this.onOpenFolder, super.key});

  /// Called when a folder row is activated.
  final void Function(FolderId id) onOpenFolder;

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FolderCubit>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: LibraryKeys.folderListScreen,
      appBar: AppBar(title: const Text('Folders')),
      floatingActionButton: FloatingActionButton.extended(
        key: LibraryKeys.folderCreateButton,
        onPressed: () => _create(context),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New folder'),
      ),
      body: BlocConsumer<FolderCubit, FolderState>(
        listenWhen: (previous, current) =>
            previous.failure != current.failure && current.failure != null,
        listener: (context, state) {
          final message = state.message;
          if (message != null && state.status != LoadStatus.failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) => switch (state.status) {
          LoadStatus.initial || LoadStatus.loading => const AppLoadingIndicator(
            key: LibraryKeys.folderListLoading,
          ),
          LoadStatus.empty => AppEmptyState(
            key: LibraryKeys.folderListEmptyState,
            icon: Icons.folder_outlined,
            title: 'No folders yet',
            message: 'Folders group related documents together.',
            actionLabel: 'New folder',
            onAction: () => _create(context),
          ),
          LoadStatus.failure => AppErrorView(
            key: LibraryKeys.folderListErrorView,
            failure: state.failure ?? const Failure.unexpected(),
            retryKey: LibraryKeys.folderListRetryButton,
            onRetry: () => context.read<FolderCubit>().load(),
          ),
          LoadStatus.ready => ListView.builder(
            itemCount: state.folders.length,
            itemBuilder: (context, index) {
              final folder = state.folders[index];
              return FolderTile(
                folder: folder,
                onTap: () => widget.onOpenFolder(folder.id),
                onRename: () => _rename(context, folder),
              );
            },
          ),
        },
      ),
    );
  }

  /// Prompts for a name and creates a folder.
  ///
  /// Reopens the dialog when creation is refused, so a rejected name is
  /// corrected in place rather than retyped from scratch.
  Future<void> _create(BuildContext context) async {
    final cubit = context.read<FolderCubit>();

    final name = await showNameDialog(
      context,
      title: 'New folder',
      confirmLabel: 'Create',
      fieldKey: LibraryKeys.folderNameField,
      confirmKey: LibraryKeys.folderNameConfirm,
    );

    if (name == null) return;
    await cubit.create(name);
  }

  Future<void> _rename(BuildContext context, Folder folder) async {
    final cubit = context.read<FolderCubit>();

    final name = await showNameDialog(
      context,
      title: 'Rename folder',
      confirmLabel: 'Rename',
      initialValue: folder.name,
      fieldKey: LibraryKeys.folderNameField,
      confirmKey: LibraryKeys.folderNameConfirm,
    );

    if (name == null) return;
    await cubit.rename(folder.id, name);
  }
}
