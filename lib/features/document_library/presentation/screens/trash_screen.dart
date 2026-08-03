/// Recoverable Trash screen.
library;

import 'package:doc_forge/core/contracts/models/trash.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/trash_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/trash_state.dart';
import 'package:doc_forge/features/document_library/presentation/trash_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lists items kept for 30 days with restore and permanent-delete actions.
class TrashScreen extends StatelessWidget {
  /// Creates the screen.
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrashCubit, TrashState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        if (state.message case final message?) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<TrashCubit>();
        return Scaffold(
          key: TrashKeys.screen,
          appBar: AppBar(
            title: const Text('Trash'),
            actions: [
              if (state.entries.isNotEmpty)
                TextButton(
                  key: TrashKeys.emptyButton,
                  onPressed: state.mutating.isEmpty
                      ? () => _confirmEmpty(context, cubit)
                      : null,
                  child: const Text('Empty'),
                ),
            ],
          ),
          body: switch (state.status) {
            TrashStatus.initial || TrashStatus.loading =>
              const AppLoadingIndicator(key: TrashKeys.loading),
            TrashStatus.failure => AppErrorView(
              key: TrashKeys.error,
              failure: state.failure!,
              retryKey: TrashKeys.retry,
              onRetry: cubit.load,
            ),
            TrashStatus.ready when state.entries.isEmpty => const AppEmptyState(
              key: TrashKeys.empty,
              icon: Icons.delete_outline,
              title: 'Trash is empty',
              message: 'Items moved to Trash stay recoverable for 30 days.',
            ),
            TrashStatus.ready => ListView.builder(
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                final busy = state.mutating.contains(entry.id);
                return _TrashRow(entry: entry, busy: busy);
              },
            ),
          },
        );
      },
    );
  }

  Future<void> _confirmEmpty(BuildContext context, TrashCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: TrashKeys.emptyDialog,
        title: const Text('Empty Trash?'),
        content: const Text(
          'Every item will be permanently deleted and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: TrashKeys.emptyConfirm,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.empty();
  }
}

class _TrashRow extends StatelessWidget {
  const _TrashRow({required this.entry, required this.busy});

  final TrashEntry entry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrashCubit>();
    return ListTile(
      key: TrashKeys.row(entry.id.value),
      leading: Icon(
        entry.kind == TrashEntryKind.folderTree
            ? Icons.folder_delete_outlined
            : Icons.description_outlined,
      ),
      title: Text(entry.displayName),
      subtitle: Text(
        '${entry.inventory.fileCount} files • '
        '${DisplayFormatting.fileSize(entry.inventory.sizeInBytes)} • kept 30 days',
      ),
      trailing: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Wrap(
              children: [
                IconButton(
                  key: TrashKeys.restore(entry.id.value),
                  tooltip: 'Restore ${entry.displayName}',
                  onPressed: () => cubit.restore(entry.id),
                  icon: const Icon(Icons.restore),
                ),
                IconButton(
                  key: TrashKeys.purge(entry.id.value),
                  tooltip: 'Delete ${entry.displayName} permanently',
                  onPressed: () => _confirmPurge(context, cubit),
                  icon: const Icon(Icons.delete_forever_outlined),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmPurge(BuildContext context, TrashCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: TrashKeys.purgeDialog(entry.id.value),
        title: Text('Delete ${entry.displayName} permanently?'),
        content: const Text('This cannot be undone or recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: TrashKeys.purgeConfirm,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.purge(entry.id);
  }
}
