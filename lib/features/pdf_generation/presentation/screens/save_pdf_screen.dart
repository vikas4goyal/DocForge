/// Adaptive full-page Save PDF configuration and temporary preview surfaces.
library;

import 'dart:async';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_state.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/pdf_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Receives a verified private candidate handle for typed preview navigation.
typedef OpenTemporaryPdfPreview = void Function(String candidateHandle);

/// Receives the one committed document for folder navigation.
typedef CompleteSavePdf = void Function(Document document);

/// Dedicated adaptive Save PDF screen.
class SavePdfScreen extends StatelessWidget {
  /// Creates the screen over its route-scoped [cubit].
  const SavePdfScreen({
    required this.cubit,
    required this.onOpenPreview,
    required this.onSaved,
    super.key,
  });

  /// Route-scoped orchestration.
  final SavePdfCubit cubit;

  /// Opens the typed temporary-preview route.
  final OpenTemporaryPdfPreview onOpenPreview;

  /// Completes the route with its committed document exactly once.
  final CompleteSavePdf onSaved;

  @override
  Widget build(BuildContext context) => BlocProvider<SavePdfCubit>.value(
    value: cubit,
    child: Scaffold(
      key: PdfKeys.saveScreen,
      appBar: AppBar(title: const Text('Save PDF')),
      body: BlocBuilder<SavePdfCubit, SavePdfState>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth >= 840 ? 760 : double.infinity,
                child: _SaveConfiguration(
                  state: state,
                  onOpenPreview: onOpenPreview,
                  onSaved: onSaved,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SaveConfiguration extends StatelessWidget {
  const _SaveConfiguration({
    required this.state,
    required this.onOpenPreview,
    required this.onSaved,
  });

  final SavePdfState state;
  final OpenTemporaryPdfPreview onOpenPreview;
  final CompleteSavePdf onSaved;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SavePdfCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          key: PdfKeys.saveNameField,
          initialValue: state.name,
          decoration: const InputDecoration(
            labelText: 'Document name',
            suffixText: '.pdf',
            border: OutlineInputBorder(),
          ),
          onChanged: cubit.nameChanged,
        ),
        const SizedBox(height: 24),
        Semantics(
          label: PdfSemantics.quality(state.qualityPlan.documentQuality.value),
          slider: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PDF quality · ${state.qualityPlan.documentQuality.value}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                key: PdfKeys.saveQualitySlider,
                min: 30,
                max: 100,
                divisions: 70,
                value: state.qualityPlan.documentQuality.value.toDouble(),
                label: '${state.qualityPlan.documentQuality.value}%',
                onChanged: (value) =>
                    cubit.documentQualityChanged(value.round()),
              ),
            ],
          ),
        ),
        _SizeStatus(state: state),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Page quality',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (state.hasPageOverrides)
              TextButton(
                key: PdfKeys.pageQualityResetAll,
                onPressed: cubit.resetPageQualities,
                child: const Text('Reset all'),
              ),
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.pages.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final page = state.pages[index];
            final overridden = state.qualityPlan.pageOverrides.containsKey(
              page.id.value,
            );
            final quality = state.qualityPlan.effectiveFor(page.id.value).value;
            return Semantics(
              label: PdfSemantics.pageQuality(
                index + 1,
                quality,
                overridden: overridden,
              ),
              button: true,
              child: ListTile(
                key: PdfKeys.savePageQuality(page.id.value),
                title: Text('Page ${index + 1}'),
                subtitle: Text(
                  overridden
                      ? '$quality% · Custom quality'
                      : '$quality% · Uses document quality',
                ),
                trailing: const Icon(Icons.tune),
                onTap: () => _showPageQualityDialog(
                  context,
                  cubit,
                  pageId: page.id.value,
                  initial: quality,
                  overridden: overridden,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _PasswordControls(state: state),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: <Widget>[
            OutlinedButton.icon(
              key: PdfKeys.savePreviewButton,
              onPressed: state.pages.isEmpty
                  ? null
                  : () => _runPreview(context, cubit, onOpenPreview),
              icon: const Icon(Icons.preview_outlined),
              label: const Text('Preview'),
            ),
            FilledButton.icon(
              key: PdfKeys.saveConfirmButton,
              onPressed: state.canSave
                  ? () => _runSave(context, cubit, onSaved)
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SizeStatus extends StatelessWidget {
  const _SizeStatus({required this.state});

  final SavePdfState state;

  @override
  Widget build(BuildContext context) {
    final calculation = state.calculation;
    final (icon, text, failed) = switch (calculation) {
      AsyncJobQueued() => (Icons.hourglass_top, 'Calculating…', false),
      AsyncJobRunning(:final progress) => (
        Icons.hourglass_top,
        'Calculating… ${progress.percent}%',
        false,
      ),
      AsyncJobSucceeded() => (
        Icons.check_circle_outline,
        'Calculated size: ${_formatBytes(state.calculatedBytes ?? 0)}',
        false,
      ),
      AsyncJobFailed(:final failure) => (
        Icons.error_outline,
        failure.presentation.message,
        true,
      ),
      AsyncJobCancelled() || AsyncJobIdle() => (
        Icons.info_outline,
        'Size will be calculated automatically',
        false,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: ListTile(
        key: PdfKeys.outputSizeStatus,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(text),
        trailing: failed
            ? TextButton(
                key: PdfKeys.outputSizeRetry,
                onPressed: context.read<SavePdfCubit>().recalculate,
                child: const Text('Retry'),
              )
            : null,
      ),
    );
  }
}

class _PasswordControls extends StatelessWidget {
  const _PasswordControls({required this.state});

  final SavePdfState state;

  @override
  Widget build(BuildContext context) => state.passwordEnabled
      ? ListTile(
          key: PdfKeys.savePasswordEnabled,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: const Text('Password protection enabled'),
          trailing: TextButton(
            key: PdfKeys.saveRemovePassword,
            onPressed: context.read<SavePdfCubit>().removePassword,
            child: const Text('Remove'),
          ),
        )
      : OutlinedButton.icon(
          key: PdfKeys.saveSetPassword,
          onPressed: () =>
              _showPasswordDialog(context, context.read<SavePdfCubit>()),
          icon: const Icon(Icons.lock_outline),
          label: const Text('Set password'),
        );
}

Future<void> _showPageQualityDialog(
  BuildContext context,
  SavePdfCubit cubit, {
  required String pageId,
  required int initial,
  required bool overridden,
}) async {
  var selected = initial;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Page quality'),
        content: Slider(
          key: PdfKeys.pageQualitySlider,
          min: 30,
          max: 100,
          divisions: 70,
          value: selected.toDouble(),
          label: '$selected%',
          onChanged: (value) => setState(() => selected = value.round()),
        ),
        actions: <Widget>[
          if (overridden)
            TextButton(
              key: PdfKeys.pageQualityUseDocument,
              onPressed: () {
                cubit.useDocumentQuality(pageId);
                Navigator.pop(dialogContext);
              },
              child: const Text('Use document quality'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cubit.pageQualityChanged(pageId, selected);
              Navigator.pop(dialogContext);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showPasswordDialog(BuildContext context, SavePdfCubit cubit) =>
    showDialog<void>(
      context: context,
      builder: (_) => _PasswordDialog(cubit: cubit),
    );

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.cubit});

  final SavePdfCubit cubit;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Set PDF password'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: PdfKeys.savePasswordField,
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          TextField(
            key: PdfKeys.savePasswordConfirmField,
            controller: _confirmation,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              errorText: _error,
            ),
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: PdfKeys.savePasswordDialogConfirm,
        onPressed: _submit,
        child: const Text('Set password'),
      ),
    ],
  );

  void _submit() {
    if (_password.text.isEmpty || _confirmation.text.isEmpty) {
      setState(() => _error = 'Enter and confirm a password.');
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }
    widget.cubit.setPassword(_password.text, _confirmation.text);
    Navigator.pop(context);
  }
}

Future<void> _runPreview(
  BuildContext context,
  SavePdfCubit cubit,
  OpenTemporaryPdfPreview onOpenPreview,
) async {
  unawaited(_showJobDialog(context, cubit, preview: true));
  final handle = await cubit.preview();
  if (context.mounted && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
  if (handle != null) {
    onOpenPreview(handle);
  }
}

Future<void> _runSave(
  BuildContext context,
  SavePdfCubit cubit,
  CompleteSavePdf onSaved,
) async {
  unawaited(_showJobDialog(context, cubit, preview: false));
  final document = await cubit.save();
  if (context.mounted && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
  if (document != null) {
    onSaved(document);
  }
}

Future<void> _showJobDialog(
  BuildContext context,
  SavePdfCubit cubit, {
  required bool preview,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => BlocProvider<SavePdfCubit>.value(
    value: cubit,
    child: _JobProgressDialog(preview: preview),
  ),
);

class _JobProgressDialog extends StatelessWidget {
  const _JobProgressDialog({required this.preview});

  final bool preview;

  @override
  Widget build(BuildContext context) => BlocBuilder<SavePdfCubit, SavePdfState>(
    builder: (context, state) {
      final job = preview ? state.preview : state.commit;
      final progress = job is AsyncJobRunning ? job.progress.percent : 0;
      return AlertDialog(
        key: PdfKeys.jobProgressDialog,
        title: Text(preview ? 'Preparing PDF' : 'Saving PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LinearProgressIndicator(
              key: PdfKeys.jobProgressIndicator,
              value: progress / 100,
            ),
            const SizedBox(height: 12),
            Text('$progress percent'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            key: PdfKeys.jobCancelButton,
            onPressed: preview
                ? context.read<SavePdfCubit>().cancelPreview
                : context.read<SavePdfCubit>().cancelSave,
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kib = bytes / 1024;
  if (kib < 1024) {
    return '${kib.toStringAsFixed(kib >= 10 ? 0 : 1)} KB';
  }
  final mib = kib / 1024;
  return '${mib.toStringAsFixed(mib >= 10 ? 0 : 1)} MB';
}

/// Builds the injected read-only renderer for one private candidate handle.
typedef TemporaryPdfSurfaceBuilder =
    Widget Function(BuildContext context, String candidateHandle);

/// Read-only temporary PDF preview with explicit close cleanup callback.
class PdfTemporaryPreviewScreen extends StatelessWidget {
  /// Creates the preview surface.
  const PdfTemporaryPreviewScreen({
    required this.candidateHandle,
    required this.surfaceBuilder,
    required this.onClose,
    super.key,
  });

  /// App-private candidate handle.
  final String candidateHandle;

  /// Injected renderer surface; no viewer-feature import crosses this boundary.
  final TemporaryPdfSurfaceBuilder surfaceBuilder;

  /// Closes the typed route and releases preview-only ownership when needed.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: PdfKeys.temporaryPreviewScreen,
    appBar: AppBar(
      title: const Text('PDF preview'),
      leading: IconButton(
        key: PdfKeys.temporaryPreviewClose,
        tooltip: PdfSemantics.closePreview,
        onPressed: onClose,
        icon: const Icon(Icons.close),
      ),
    ),
    body: surfaceBuilder(context, candidateHandle),
  );
}

/// Inert Save PDF dialog rendered by deterministic previews.
enum SavePdfDialogPreviewKind {
  /// Page-quality override selection.
  pageQuality,

  /// Route-scoped password entry.
  password,

  /// Cancellable determinate Save progress.
  progress,
}

/// Visual verification surface for every Save PDF dialog.
class SavePdfDialogPreview extends StatelessWidget {
  /// Creates one deterministic dialog state.
  const SavePdfDialogPreview({required this.kind, super.key});

  /// Dialog to render.
  final SavePdfDialogPreviewKind kind;

  @override
  Widget build(BuildContext context) => switch (kind) {
    SavePdfDialogPreviewKind.pageQuality => AlertDialog(
      title: const Text('Page quality'),
      content: Slider(
        key: PdfKeys.pageQualitySlider,
        min: 30,
        max: 100,
        divisions: 70,
        value: 40,
        onChanged: (_) {},
      ),
      actions: <Widget>[
        TextButton(
          key: PdfKeys.pageQualityUseDocument,
          onPressed: () {},
          child: const Text('Use document quality'),
        ),
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        FilledButton(onPressed: () {}, child: const Text('Apply')),
      ],
    ),
    SavePdfDialogPreviewKind.password => AlertDialog(
      title: const Text('Set PDF password'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: PdfKeys.savePasswordField,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          TextField(
            key: PdfKeys.savePasswordConfirmField,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Confirm password'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        FilledButton(
          key: PdfKeys.savePasswordDialogConfirm,
          onPressed: () {},
          child: const Text('Set password'),
        ),
      ],
    ),
    SavePdfDialogPreviewKind.progress => AlertDialog(
      key: PdfKeys.jobProgressDialog,
      title: const Text('Saving PDF'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LinearProgressIndicator(
            key: PdfKeys.jobProgressIndicator,
            value: 0.58,
          ),
          SizedBox(height: 12),
          Text('58 percent'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: PdfKeys.jobCancelButton,
          onPressed: () {},
          child: const Text('Cancel'),
        ),
      ],
    ),
  };
}
