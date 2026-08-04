/// The sheet offering every way content can enter the application.
library;

import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/document_import/domain/import_rules.dart';
import 'package:doc_scanly/features/document_import/presentation/cubit/import_cubit.dart';
import 'package:doc_scanly/features/document_import/presentation/cubit/import_state.dart';
import 'package:doc_scanly/features/document_import/presentation/import_keys.dart';
import 'package:doc_scanly/features/document_import/presentation/widgets/import_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The import sources and everything that can happen after one is chosen.
///
/// Designed to be shown as a modal bottom sheet, but built as an ordinary
/// widget so previews, goldens and widget tests can render it directly.
///
/// Keys: [ImportKeys.sheet] on the root, and one key per source. The keys are
/// normative and come from `specs/document-import/spec.md`.
class ImportOptionsSheet extends StatelessWidget {
  /// Creates the sheet.
  const ImportOptionsSheet({
    required this.onScan,
    required this.onOpenSettings,
    super.key,
    this.onReadyForReview,
    this.onImported,
  });

  /// Invoked when the user chooses the camera, which starts the scanning flow.
  ///
  /// Handled by whoever opened the sheet rather than here, because scanning is
  /// a whole flow with its own route — the sheet's job is to say which source
  /// was chosen.
  final VoidCallback onScan;

  /// Invoked when the user opens the system settings from the permission view.
  final VoidCallback onOpenSettings;

  /// Invoked with copied images once they are ready for the review step.
  final ValueChanged<ScannedPageBundle>? onReadyForReview;

  /// Invoked once every selected PDF has become a document.
  final ValueChanged<ImportState>? onImported;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportCubit, ImportState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ImportStatus.readyForReview:
            final bundle = state.bundle;
            if (bundle != null) onReadyForReview?.call(bundle);
          case ImportStatus.done:
            onImported?.call(state);
          case _:
            break;
        }
      },
      builder: (context, state) => SafeArea(
        key: ImportKeys.sheet,
        child: switch (state.status) {
          ImportStatus.choosing ||
          ImportStatus.importing => _Importing(state: state),
          ImportStatus.awaitingPassword => _Password(state: state),
          ImportStatus.permissionDenied => _PermissionDenied(
            state: state,
            onOpenSettings: onOpenSettings,
          ),
          ImportStatus.failure => _Failure(state: state),
          _ => _Sources(onScan: onScan),
        },
      ),
    );
  }
}

/// The list of sources.
class _Sources extends StatelessWidget {
  const _Sources({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Add a document',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ImportSourceTile(
          key: ImportKeys.sourceCamera,
          source: ImportSource.camera,
          onTap: onScan,
        ),
        ImportSourceTile(
          key: ImportKeys.sourceGallery,
          source: ImportSource.gallery,
          // The photo permission is requested by the picker as it opens, which
          // is what makes it just-in-time: nothing is asked for until the user
          // taps this.
          onTap: cubit.fromGallery,
        ),
        ImportSourceTile(
          key: ImportKeys.sourceFiles,
          source: ImportSource.files,
          onTap: cubit.fromFiles,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The progress view shown while files are copied.
class _Importing extends StatelessWidget {
  const _Importing({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;

    return Padding(
      key: ImportKeys.progressIndicator,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppProgressIndicator(
        completed: progress?.completed ?? 0,
        total: progress?.total ?? 0,
        label: state.progressLabel,
        onCancel: context.read<ImportCubit>().cancel,
        cancelKey: ImportKeys.cancelButton,
      ),
    );
  }
}

/// The password prompt for a protected PDF.
class _Password extends StatelessWidget {
  const _Password({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();

    return ImportPasswordPrompt(
      onSubmit: cubit.submitPassword,
      onCancel: cubit.cancelPassword,
      wasRejected: state.passwordRejected,
    );
  }
}

/// The view shown when photo or file access was refused.
///
/// Distinct from the error view because the recovery is distinct: only this one
/// leads to the system settings, and the spec requires the *other* sources to
/// stay usable, which is why it offers a way back rather than replacing the
/// sheet permanently.
class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.state, required this.onOpenSettings});

  final ImportState state;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();

    return Padding(
      key: ImportKeys.permissionDeniedView,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppErrorView(
            failure: state.failure!,
            onRetry: cubit.dismissError,
            onOpenSettings: onOpenSettings,
            onGoBack: cubit.dismissError,
            retryKey: state.isPermanentlyDenied
                ? ImportKeys.openSettingsButton
                : ImportKeys.errorRetryButton,
          ),
          TextButton(
            onPressed: cubit.dismissError,
            child: const Text('Choose another source'),
          ),
        ],
      ),
    );
  }
}

/// The error view shown when an import could not be completed.
class _Failure extends StatelessWidget {
  const _Failure({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();

    return Padding(
      key: ImportKeys.errorView,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppErrorView(
        failure: state.failure!,
        // Every recovery returns to the sources, whichever one the failure
        // calls for. Supplying only `onRetry` would leave a full device — whose
        // recovery is "manage storage" — with a message and no way forward.
        onRetry: cubit.dismissError,
        onGoBack: cubit.dismissError,
        onOpenSettings: cubit.dismissError,
        retryKey: ImportKeys.errorRetryButton,
      ),
    );
  }
}
