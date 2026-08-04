/// The extracted-text view.
library;

import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_cubit.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_state.dart';
import 'package:doc_scanly/features/ocr/presentation/ocr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows a document's recognised text, with copy, export and re-run.
///
/// A view rather than a screen: it is hosted by the document detail screen and
/// by the viewer, so it takes no navigation callbacks and provides no app bar
/// of its own.
class ExtractedTextView extends StatelessWidget {
  /// Creates the extracted-text view.
  const ExtractedTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OcrCubit, OcrState>(
      listenWhen: (previous, current) => current.copied && !previous.copied,
      listener: (context, state) {
        // The confirmation the spec requires. Shown from a listener rather than
        // built into the tree so it does not reappear on every unrelated
        // rebuild while the state still says "copied".
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text copied to clipboard')),
        );
      },
      builder: (context, state) {
        final cubit = context.read<OcrCubit>();

        return Column(
          key: OcrKeys.textView,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Actions(state: state, cubit: cubit),
            const Divider(height: 1),
            Expanded(
              child: _Body(state: state, cubit: cubit),
            ),
          ],
        );
      },
    );
  }
}

/// The copy, export and re-run controls.
class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.cubit});

  final OcrState state;
  final OcrCubit cubit;

  @override
  Widget build(BuildContext context) {
    // Copy and export are unavailable rather than inert when there is nothing
    // to copy: a control that silently puts an empty string on the clipboard is
    // worse than one that is visibly unavailable.
    final enabled = state.hasText && !state.isRunning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // The label lives on the icon, not on the tooltip. A tooltip becomes
          // a semantics *tooltip* rather than a label, so a tooltip-only
          // icon button announces nothing a screen-reader user can act on —
          // which the spec requires these three controls to do.
          IconButton(
            key: OcrKeys.copyTextButton,
            onPressed: enabled ? cubit.copy : null,
            icon: const Icon(
              Icons.copy_outlined,
              semanticLabel: 'Copy recognised text',
            ),
            tooltip: 'Copy recognised text',
          ),
          IconButton(
            key: OcrKeys.exportTextButton,
            onPressed: enabled ? cubit.export : null,
            icon: const Icon(
              Icons.ios_share_outlined,
              semanticLabel: 'Export recognised text',
            ),
            tooltip: 'Export recognised text',
          ),
          const Spacer(),
          if (state.status != OcrStatus.notRecognised)
            TextButton.icon(
              key: OcrKeys.rerunButton,
              onPressed: state.isRunning ? null : cubit.rerun,
              icon: const Icon(Icons.refresh),
              label: const Text('Run again'),
            ),
        ],
      ),
    );
  }
}

/// Whichever of the view's states is current.
class _Body extends StatelessWidget {
  const _Body({required this.state, required this.cubit});

  final OcrState state;
  final OcrCubit cubit;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      OcrStatus.loading => const AppLoadingIndicator(
        semanticsLabel: 'Loading recognised text',
      ),
      OcrStatus.running => _Progress(state: state, cubit: cubit),
      OcrStatus.failure when state.failure != null => AppErrorView(
        key: OcrKeys.errorView,
        failure: state.failure!,
        retryKey: OcrKeys.errorRetryButton,
        onRetry: cubit.rerun,
      ),
      OcrStatus.notRecognised => AppEmptyState(
        key: OcrKeys.emptyState,
        title: 'No text extracted yet',
        message:
            'Read the text on this document so you can copy, export and '
            'search it.',
        icon: Icons.text_fields_outlined,
        actionLabel: 'Extract text',
        actionKey: OcrKeys.recogniseButton,
        onAction: cubit.recognise,
      ),
      OcrStatus.empty => const AppEmptyState(
        key: OcrKeys.emptyState,
        title: 'No text found',
        // Distinguished from "not read yet" deliberately: the pages *were*
        // read, and offering "try again" would imply the result was a failure.
        message:
            'This document was read but no text could be recognised on '
            'it.',
        icon: Icons.text_fields_outlined,
      ),
      _ => _Text(state: state),
    };
  }
}

/// Progress and cancellation for a running recognition.
class _Progress extends StatelessWidget {
  const _Progress({required this.state, required this.cubit});

  final OcrState state;
  final OcrCubit cubit;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;

    return AppProgressIndicator(
      key: OcrKeys.progressIndicator,
      completed: progress?.completed ?? 0,
      total: progress?.total ?? 0,
      label: OcrSemantics.extractingText,
      onCancel: cubit.cancel,
      cancelKey: OcrKeys.cancelButton,
    );
  }
}

/// The recognised text itself.
class _Text extends StatelessWidget {
  const _Text({required this.state});

  final OcrState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scrollbar(
      child: SingleChildScrollView(
        key: OcrKeys.textScrollView,
        padding: const EdgeInsets.all(16),
        // Selectable so a user can take one line rather than the whole
        // document, which is what the copy control gives them.
        child: SelectableText(
          state.combinedText,
          style: theme.textTheme.bodyMedium,
          // Named for screen readers as recognised content rather than as the
          // document itself, so a listener knows they are hearing a machine
          // reading rather than an authored transcript.
          semanticsLabel: 'Recognised text. ${state.combinedText}',
        ),
      ),
    );
  }
}
