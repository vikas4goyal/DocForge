/// Startup screen shown while the device library moves into iCloud.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the automatic move into iCloud before the library opens.
///
/// Reads [CloudMigrationGateCubit] from the tree. [onFinished] opens the app
/// once the library is in iCloud; [onContinueLocal] opens it on the device
/// library for this session only.
///
/// Keys: `cloud_storage_migration_gate` (root, “Moving DocScanly documents to
/// iCloud”), `cloud_storage_migration_progress`, `cloud_storage_migration_done`,
/// `cloud_storage_migration_continue`, `cloud_storage_retry` and
/// `cloud_storage_continue_local`.
class CloudMigrationGateScreen extends StatelessWidget {
  /// Creates the gate screen.
  const CloudMigrationGateScreen({
    required this.onFinished,
    required this.onContinueLocal,
    super.key,
  });

  /// Opens DocScanly on the iCloud library.
  final VoidCallback onFinished;

  /// Opens DocScanly on the device library for this session.
  final VoidCallback onContinueLocal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: CloudStorageSemantics.migrationGate,
      container: true,
      explicitChildNodes: true,
      child: Scaffold(
        key: CloudStorageKeys.migrationGate,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child:
                    BlocBuilder<
                      CloudMigrationGateCubit,
                      CloudMigrationGateState
                    >(
                      builder: (context, state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            state.status == CloudMigrationGateStatus.failed
                                ? Icons.cloud_off_outlined
                                : Icons.cloud_upload_outlined,
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Moving your documents to iCloud',
                            style: textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'DocScanly keeps your PDFs in iCloud Drive so they '
                            'stay safe and appear on your other Apple devices. '
                            'Every file is verified before the copy on this '
                            'device is removed.',
                            style: textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          switch (state.status) {
                            CloudMigrationGateStatus.completed => _Completed(
                              onContinue: onFinished,
                            ),
                            CloudMigrationGateStatus.failed => _Failed(
                              failure: state.failure,
                              onRetry: context
                                  .read<CloudMigrationGateCubit>()
                                  .retry,
                              onContinueLocal: onContinueLocal,
                            ),
                            _ => _Progress(
                              state: state,
                              onContinueLocal: () => _leave(context),
                            ),
                          },
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _leave(BuildContext context) async {
    final stillLocal = await context
        .read<CloudMigrationGateCubit>()
        .continueOnDevice();
    // Once the move switched to iCloud the gate shows completion instead.
    if (stillLocal) onContinueLocal();
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state, required this.onContinueLocal});

  final CloudMigrationGateState state;
  final VoidCallback onContinueLocal;

  @override
  Widget build(BuildContext context) {
    final percent = (state.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: CloudStorageSemantics.migrationProgress(percent),
          liveRegion: true,
          child: ExcludeSemantics(
            child: Card(
              key: CloudStorageKeys.migrationProgress,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (state.status) {
                      CloudMigrationGateStatus.preparing =>
                        'Preparing documents',
                      CloudMigrationGateStatus.verifying =>
                        'Verifying documents',
                      CloudMigrationGateStatus.cleaning => 'Finishing up',
                      _ => 'Copying documents',
                    }),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: state.status == CloudMigrationGateStatus.preparing
                          ? null
                          : state.progress,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.completedFiles} of ${state.totalFiles} files '
                      'verified',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (state.isRunning) ...[
          const SizedBox(height: 16),
          _ContinueLocalButton(onPressed: onContinueLocal),
        ],
      ],
    );
  }
}

class _Completed extends StatelessWidget {
  const _Completed({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        label: CloudStorageSemantics.migrationDone,
        liveRegion: true,
        child: ExcludeSemantics(
          child: Card(
            key: CloudStorageKeys.migrationDone,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your documents are now in iCloud Drive',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find them in the Files app under iCloud Drive → '
                    'DocScanly. Thumbnails, recognised text, settings and '
                    'passwords stay only on this device.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Semantics(
        label: CloudStorageSemantics.migrationContinue,
        button: true,
        excludeSemantics: true,
        onTap: onContinue,
        child: FilledButton(
          key: CloudStorageKeys.migrationContinue,
          onPressed: onContinue,
          child: const Text('Continue'),
        ),
      ),
    ],
  );
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.failure,
    required this.onRetry,
    required this.onContinueLocal,
  });

  final Failure? failure;
  final VoidCallback onRetry;
  final VoidCallback onContinueLocal;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _reason(failure),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your documents are safe on this device. DocScanly will try '
                'again the next time it opens.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Semantics(
        label: CloudStorageSemantics.retryMigration,
        button: true,
        excludeSemantics: true,
        onTap: onRetry,
        child: FilledButton(
          key: CloudStorageKeys.retry,
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ),
      const SizedBox(height: 8),
      _ContinueLocalButton(onPressed: onContinueLocal),
    ],
  );

  /// User-facing explanation of why the move stopped.
  static String _reason(Failure? failure) => switch (failure) {
    StorageFullFailure() => 'Your iCloud storage is full',
    CorruptFileFailure() => 'A document could not be verified in iCloud',
    CancelledFailure() => 'The move to iCloud was stopped',
    _ => 'iCloud could not be reached',
  };
}

class _ContinueLocalButton extends StatelessWidget {
  const _ContinueLocalButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: CloudStorageSemantics.continueLocal,
    button: true,
    excludeSemantics: true,
    // The label replaces the button's own text, so the action is re-exposed.
    onTap: onPressed,
    child: TextButton(
      key: CloudStorageKeys.continueLocal,
      onPressed: onPressed,
      child: const Text('Continue on this device for now'),
    ),
  );
}
