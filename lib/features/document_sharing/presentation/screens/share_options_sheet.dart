/// The sheet offering every way a document can leave the application.
library;

import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/document_sharing/domain/share_content.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:doc_scanly/features/document_sharing/presentation/share_keys.dart';
import 'package:doc_scanly/features/document_sharing/presentation/widgets/share_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The share options for one document.
///
/// Designed to be shown as a modal bottom sheet, but built as an ordinary
/// widget so previews, goldens and widget tests can render it directly rather
/// than having to drive a sheet open first.
///
/// Keys: [ShareKeys.sheet] on the root, and one key per option. The keys are
/// normative and come from `specs/document-sharing/spec.md`.
class ShareOptionsSheet extends StatelessWidget {
  /// Creates the sheet.
  const ShareOptionsSheet({
    super.key,
    this.onRunRecognition,
    this.onDone,
    this.initialDirectory,
  });

  /// Invoked when the user chooses to run recognition from the no-text notice.
  final VoidCallback? onRunRecognition;

  /// Invoked once content has been handed over or an export has been written.
  ///
  /// The sheet does not dismiss itself: whether it closes is a decision for
  /// whoever opened it, and a sheet that closed itself would be untestable
  /// without a navigator.
  final ValueChanged<ShareState>? onDone;

  /// The configured default save location, offered first when exporting.
  final String? initialDirectory;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareCubit, ShareState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ShareStatus.done,
      listener: (context, state) => onDone?.call(state),
      builder: (context, state) => SafeArea(
        key: ShareKeys.sheet,
        child: switch (state.status) {
          ShareStatus.preparing => _Preparing(state: state),
          ShareStatus.failure => _Failure(state: state),
          _ => _Options(
            state: state,
            onRunRecognition: onRunRecognition,
            initialDirectory: initialDirectory,
          ),
        },
      ),
    );
  }
}

/// The list of options.
class _Options extends StatelessWidget {
  const _Options({
    required this.state,
    required this.onRunRecognition,
    required this.initialDirectory,
  });

  final ShareState state;
  final VoidCallback? onRunRecognition;
  final String? initialDirectory;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShareCubit>();
    final theme = Theme.of(context);

    String label(ShareAction action, ShareFormat format) =>
        ShareRules.optionSemanticsLabel(
          action,
          format,
          title: state.title,
          pageCount: state.pageCount,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            state.title.isEmpty ? 'Share' : state.title,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ShareOptionTile(
          key: ShareKeys.pdfButton,
          label: 'Share PDF',
          icon: Icons.picture_as_pdf_outlined,
          semanticsLabel: label(ShareAction.share, ShareFormat.pdf),
          onTap: cubit.sharePdf,
        ),
        ShareOptionTile(
          key: ShareKeys.imagesButton,
          label: 'Share pages as images',
          icon: Icons.image_outlined,
          semanticsLabel: label(ShareAction.share, ShareFormat.images),
          onTap: cubit.shareImages,
        ),
        ShareOptionTile(
          key: ShareKeys.textButton,
          label: 'Share extracted text',
          icon: Icons.text_snippet_outlined,
          semanticsLabel: label(ShareAction.share, ShareFormat.text),
          // A null handler is what disables the tile, and the notice below says
          // why — the spec's "disabled or explained" answered as both.
          onTap: state.canShareText ? cubit.shareText : null,
        ),
        if (!state.canShareText)
          NoRecognisedTextNotice(onRunRecognition: onRunRecognition),
        const Divider(height: 1),
        ShareOptionTile(
          key: ShareKeys.printButton,
          label: 'Print',
          icon: Icons.print_outlined,
          semanticsLabel: label(ShareAction.print, ShareFormat.pdf),
          onTap: cubit.printDocument,
        ),
        ShareOptionTile(
          key: ShareKeys.exportButton,
          label: 'Export to device storage',
          icon: Icons.save_alt_outlined,
          semanticsLabel: label(ShareAction.export, ShareFormat.pdf),
          onTap: () => cubit.export(initialDirectory: initialDirectory),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The progress view shown while content is prepared.
class _Preparing extends StatelessWidget {
  const _Preparing({required this.state});

  final ShareState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;

    return Padding(
      key: ShareKeys.progressIndicator,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppProgressIndicator(
        completed: progress?.completed ?? 0,
        total: progress?.total ?? 0,
        label: state.progressLabel,
        // Only a page render can be cancelled; handing a single file to the
        // share sheet is over before a cancel control could be pressed.
        cancelKey: ShareKeys.cancelButton,
        onCancel: state.format == ShareFormat.images
            ? context.read<ShareCubit>().cancel
            : null,
      ),
    );
  }
}

/// The error view shown when an operation could not be completed.
class _Failure extends StatelessWidget {
  const _Failure({required this.state});

  final ShareState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShareCubit>();

    return Padding(
      key: ShareKeys.errorView,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppErrorView(
            failure: state.failure!,
            // Every recovery from here returns to the options, whichever one
            // the failure calls for. Supplying only `onRetry` would leave a
            // full device — whose recovery is "manage storage" — with a message
            // and no way forward, which is the situation the spec's "clear
            // message and a working recovery action" exists to prevent.
            onRetry: cubit.dismissError,
            onGoBack: cubit.dismissError,
            onOpenSettings: cubit.dismissError,
            retryKey: ShareKeys.errorRetryButton,
          ),
          // Offered only for "nothing can receive this", which is the one
          // failure the spec answers with a different action rather than a
          // retry.
          if (state.canOfferExportInstead)
            TextButton(
              key: ShareKeys.errorExportButton,
              onPressed: cubit.export,
              child: const Text('Export to device storage instead'),
            ),
        ],
      ),
    );
  }
}
