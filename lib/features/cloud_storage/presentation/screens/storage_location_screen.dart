/// Accessible iOS-only storage-location settings screen.
library;

import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An asynchronous storage-screen action.
typedef CloudStorageAction = Future<void> Function();

/// Lets iOS users choose the one authoritative library location.
class StorageLocationScreen extends StatelessWidget {
  /// Creates the screen.
  const StorageLocationScreen({
    required this.onBack,
    super.key,
    this.onImportFolder,
  });

  /// Leaves the screen.
  final VoidCallback onBack;

  /// Explicitly imports an external folder through the normal import rules.
  final CloudStorageAction? onImportFolder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorageLocationCubit, StorageLocationState>(
      builder: (context, state) {
        final cubit = context.read<StorageLocationCubit>();
        return Scaffold(
          key: CloudStorageKeys.screen,
          appBar: AppBar(
            title: const Text('Storage location'),
            leading: BackButton(onPressed: onBack),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Choose where DocScanly keeps PDFs. Thumbnails, recognised '
                  'text, settings, and passwords stay only on this device.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _LocationOption(
                  key: CloudStorageKeys.localOption,
                  title: 'On this device',
                  subtitle: 'Available offline only on this device',
                  semanticsLabel: CloudStorageSemantics.useLocal,
                  selected: state.location == StorageLocation.local,
                  enabled: !_isBusy(state),
                  onTap: () => cubit.choose(StorageLocation.local),
                ),
                _LocationOption(
                  key: CloudStorageKeys.iCloudOption,
                  title: 'iCloud Drive',
                  subtitle: state.cloudAvailability.isAvailable
                      ? 'Sync PDFs and folders between your Apple devices'
                      : 'Not currently available',
                  semanticsLabel: CloudStorageSemantics.useICloud,
                  selected: state.location == StorageLocation.iCloud,
                  enabled: !_isBusy(state),
                  onTap: () => cubit.choose(StorageLocation.iCloud),
                ),
                const SizedBox(height: 16),
                if (state.status == StorageLocationStatus.loading)
                  const Center(child: CircularProgressIndicator()),
                if (state.status == StorageLocationStatus.confirmationRequired)
                  _Confirmation(state: state, onConfirm: cubit.confirm),
                if (_isBusy(state) ||
                    state.status == StorageLocationStatus.completed)
                  _MigrationProgress(state: state, onCancel: cubit.cancel),
                if (state.status == StorageLocationStatus.unavailable)
                  _Unavailable(onRetry: cubit.retry),
                if (state.status == StorageLocationStatus.failure)
                  _Failure(
                    onRetry: cubit.retry,
                    onCancel: state.canCancel ? cubit.cancel : null,
                  ),
                if (onImportFolder != null) ...[
                  const Divider(height: 32),
                  Semantics(
                    label: CloudStorageSemantics.importFolder,
                    button: true,
                    child: ListTile(
                      key: CloudStorageKeys.importFolder,
                      leading: const Icon(Icons.drive_folder_upload_outlined),
                      title: const Text('Import an existing folder'),
                      subtitle: const Text(
                        'Select an external iCloud Drive folder to copy its '
                        'supported PDFs into DocScanly.',
                      ),
                      onTap: () => onImportFolder!(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isBusy(StorageLocationState state) =>
      state.status == StorageLocationStatus.migrating ||
      state.status == StorageLocationStatus.verifying;
}

class _LocationOption extends StatelessWidget {
  const _LocationOption({
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String semanticsLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$semanticsLabel, ${selected ? 'selected' : 'not selected'}',
    selected: selected,
    button: true,
    child: Card(
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: enabled ? onTap : null,
      ),
    ),
  );
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.state, required this.onConfirm});

  final StorageLocationState state;
  final CloudStorageAction onConfirm;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move your library?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'DocScanly will copy active documents and Trash, verify every file, '
            'then switch storage and remove the old copies. Do not close the app.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: CloudStorageKeys.migrationConfirm,
            onPressed: onConfirm,
            child: const Text('Copy and move library'),
          ),
        ],
      ),
    ),
  );
}

class _MigrationProgress extends StatelessWidget {
  const _MigrationProgress({required this.state, required this.onCancel});

  final StorageLocationState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Library migration ${(state.progress * 100).round()} percent',
    child: Card(
      key: CloudStorageKeys.migrationProgress,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.status == StorageLocationStatus.verifying
                  ? 'Verifying documents'
                  : state.status == StorageLocationStatus.completed
                  ? 'Migration complete'
                  : 'Moving documents',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: state.progress),
            const SizedBox(height: 8),
            Text(
              '${state.completedFiles} of ${state.totalFiles} files verified',
            ),
            if (state.canCancel)
              Semantics(
                label: CloudStorageSemantics.cancelMigration,
                button: true,
                child: TextButton(
                  key: CloudStorageKeys.cancel,
                  onPressed: onCancel,
                  child: const Text('Cancel migration'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final CloudStorageAction onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    label: CloudStorageSemantics.unavailable,
    child: Card(
      key: CloudStorageKeys.unavailable,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 8),
            const Text(
              'The selected iCloud library is unavailable. DocScanly will not '
              'switch to local storage or create a second library.',
            ),
            Semantics(
              label: CloudStorageSemantics.retryConnection,
              button: true,
              child: FilledButton.tonal(
                key: CloudStorageKeys.retry,
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry, this.onCancel});

  final CloudStorageAction onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'The storage operation could not finish. Your source library is safe.',
          ),
          FilledButton.tonal(
            key: CloudStorageKeys.retry,
            onPressed: onRetry,
            child: const Text('Retry migration'),
          ),
          if (onCancel != null)
            TextButton(
              key: CloudStorageKeys.cancel,
              onPressed: onCancel,
              child: const Text('Cancel migration'),
            ),
        ],
      ),
    ),
  );
}
