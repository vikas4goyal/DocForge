/// Accessible iOS-only storage-location status screen.
library;

import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An asynchronous storage-screen action.
typedef CloudStorageAction = Future<void> Function();

/// Shows where DocScanly keeps documents and, on the device, why.
///
/// Reads [StorageLocationCubit]. There is no location chooser: iCloud is used
/// automatically whenever it is available.
///
/// Keys: `cloud_storage_screen`, `cloud_storage_status`,
/// `cloud_storage_move_now` (“Move documents to iCloud now”),
/// `cloud_storage_unavailable`, `cloud_storage_retry` and
/// `cloud_storage_import_folder`.
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
                  'DocScanly keeps your PDFs in iCloud Drive whenever iCloud '
                  'is available. Thumbnails, recognised text, settings, and '
                  'passwords stay only on this device.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                switch (state.status) {
                  StorageLocationStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  StorageLocationStatus.iCloudActive => const _StatusCard(
                    icon: Icons.cloud_done_outlined,
                    title: 'iCloud Drive',
                    body:
                        'Your PDFs and folders are in iCloud Drive → '
                        'DocScanly and appear on your other Apple devices.',
                    semanticsLabel: CloudStorageSemantics.storedInICloudDrive,
                  ),
                  StorageLocationStatus.localFallback => _LocalFallback(
                    state: state,
                    onMoveNow: cubit.moveNow,
                  ),
                  StorageLocationStatus.unavailable => _Unavailable(
                    onRetry: cubit.retry,
                  ),
                  StorageLocationStatus.failure => _Failure(
                    onRetry: cubit.retry,
                  ),
                },
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
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    container: true,
    child: ExcludeSemantics(
      child: Card(
        key: CloudStorageKeys.status,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(body),
        ),
      ),
    ),
  );
}

class _LocalFallback extends StatelessWidget {
  const _LocalFallback({required this.state, required this.onMoveNow});

  final StorageLocationState state;
  final CloudStorageAction onMoveNow;

  @override
  Widget build(BuildContext context) {
    final reason = CloudStorageSemantics.fallbackReason(
      state.cloudAvailability.status,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCard(
          icon: Icons.phone_iphone_outlined,
          title: 'On this device',
          body:
              '$reason. When iCloud is available, DocScanly moves your '
              'documents there automatically.',
          semanticsLabel: '${CloudStorageSemantics.storedOnDevice}. $reason',
        ),
        const SizedBox(height: 12),
        Semantics(
          label: CloudStorageSemantics.moveNow,
          button: true,
          enabled: state.canMoveNow,
          excludeSemantics: true,
          onTap: state.canMoveNow ? onMoveNow : null,
          child: FilledButton.icon(
            key: CloudStorageKeys.moveNow,
            onPressed: state.canMoveNow ? onMoveNow : null,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Move documents to iCloud now'),
          ),
        ),
      ],
    );
  }
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
              'Your DocScanly iCloud library is unavailable. DocScanly will not '
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
  const _Failure({required this.onRetry});

  final CloudStorageAction onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'DocScanly could not check iCloud. Your documents are safe.',
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
  );
}
