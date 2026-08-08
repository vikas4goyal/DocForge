/// Adaptive dedicated Compress PDF configuration and commit surface.
library;

import 'dart:async';

import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_state.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Receives a verified private candidate handle for preview navigation.
typedef OpenCompressionPreview = void Function(String candidateHandle);

/// Receives the one committed compression result for typed navigation.
typedef CompleteCompression = void Function(CompressionCommitResult result);

/// Full-page adaptive compression workflow.
class CompressPdfScreen extends StatelessWidget {
  /// Creates the screen over route-scoped [cubit].
  const CompressPdfScreen({
    required this.cubit,
    required this.onOpenPreview,
    required this.onCompleted,
    super.key,
  });

  /// Route-scoped orchestration.
  final CompressPdfCubit cubit;

  /// Opens read-only temporary preview.
  final OpenCompressionPreview onOpenPreview;

  /// Completes copy or overwrite navigation exactly once.
  final CompleteCompression onCompleted;

  @override
  Widget build(BuildContext context) => BlocProvider<CompressPdfCubit>.value(
    value: cubit,
    child: Scaffold(
      key: PdfEditKeys.compressScreen,
      appBar: AppBar(title: const Text('Compress PDF')),
      body: BlocBuilder<CompressPdfCubit, CompressPdfState>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth >= 840 ? 760 : double.infinity,
                child: _CompressionConfiguration(
                  state: state,
                  onOpenPreview: onOpenPreview,
                  onCompleted: onCompleted,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CompressionConfiguration extends StatelessWidget {
  const _CompressionConfiguration({
    required this.state,
    required this.onOpenPreview,
    required this.onCompleted,
  });

  final CompressPdfState state;
  final OpenCompressionPreview onOpenPreview;
  final CompleteCompression onCompleted;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CompressPdfCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(state.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${state.pageCount} ${state.pageCount == 1 ? 'page' : 'pages'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Semantics(
          label: PdfEditSemantics.compressQuality(
            state.qualityPlan.documentQuality.value,
          ),
          slider: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Document quality · ${state.qualityPlan.documentQuality.value}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                key: PdfEditKeys.compressQualitySlider,
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
        _CompressionSizeStatus(state: state),
        const SizedBox(height: 20),
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
                key: PdfEditKeys.compressResetAll,
                onPressed: cubit.resetPageQualities,
                child: const Text('Reset all'),
              ),
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.pageCount,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final overridden = state.qualityPlan.pageOverrides.containsKey(
              '$index',
            );
            final quality = state.qualityPlan.effectiveFor('$index').value;
            return Semantics(
              label: PdfEditSemantics.compressPage(
                index + 1,
                quality,
                overridden: overridden,
              ),
              button: true,
              child: ListTile(
                key: PdfEditKeys.compressPageQuality(index),
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
                  pageIndex: index,
                  initial: quality,
                  overridden: overridden,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: <Widget>[
            OutlinedButton.icon(
              key: PdfEditKeys.compressPreview,
              onPressed: state.pageCount == 0
                  ? null
                  : () => _runPreview(context, cubit, onOpenPreview),
              icon: const Icon(Icons.preview_outlined),
              label: const Text('Preview'),
            ),
            FilledButton.icon(
              key: PdfEditKeys.compressSave,
              onPressed: state.canSave
                  ? () => _beginSave(context, cubit, onCompleted)
                  : null,
              icon: const Icon(Icons.compress),
              label: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompressionSizeStatus extends StatelessWidget {
  const _CompressionSizeStatus({required this.state});

  final CompressPdfState state;

  @override
  Widget build(BuildContext context) {
    final calculated = state.calculatedBytes;
    final (icon, title, subtitle, failed) = switch (state.calculation) {
      AsyncJobQueued() => (
        Icons.hourglass_top,
        'Original: ${_formatBytes(state.originalBytes)}',
        'Calculating compressed size…',
        false,
      ),
      AsyncJobRunning(:final progress) => (
        Icons.hourglass_top,
        'Original: ${_formatBytes(state.originalBytes)}',
        'Calculating… ${progress.percent}%',
        false,
      ),
      AsyncJobSucceeded() => (
        Icons.check_circle_outline,
        'Original: ${_formatBytes(state.originalBytes)} · Result: ${_formatBytes(calculated ?? 0)}',
        calculated != null && calculated >= state.originalBytes
            ? 'No size reduction'
            : '${_formatBytes(state.savedBytes ?? 0)} saved',
        false,
      ),
      AsyncJobFailed(:final failure) => (
        Icons.error_outline,
        'Original: ${_formatBytes(state.originalBytes)}',
        failure.presentation.message,
        true,
      ),
      AsyncJobCancelled() || AsyncJobIdle() => (
        Icons.info_outline,
        'Original: ${_formatBytes(state.originalBytes)}',
        'Compressed size will be calculated automatically',
        false,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: ListTile(
        key: PdfEditKeys.compressSizeStatus,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: failed
            ? TextButton(
                key: PdfEditKeys.compressSizeRetry,
                onPressed: context.read<CompressPdfCubit>().recalculate,
                child: const Text('Retry'),
              )
            : null,
      ),
    );
  }
}

Future<void> _showPageQualityDialog(
  BuildContext context,
  CompressPdfCubit cubit, {
  required int pageIndex,
  required int initial,
  required bool overridden,
}) async {
  var selected = initial;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Page ${pageIndex + 1} quality'),
        content: Slider(
          key: PdfEditKeys.compressPageSlider,
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
              key: PdfEditKeys.compressUseDocumentQuality,
              onPressed: () {
                cubit.useDocumentQuality(pageIndex);
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
              cubit.pageQualityChanged(pageIndex, selected);
              Navigator.pop(dialogContext);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _beginSave(
  BuildContext context,
  CompressPdfCubit cubit,
  CompleteCompression onCompleted,
) async {
  if (!cubit.beginDestinationSelection()) {
    final continueAt100 = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: PdfEditKeys.compressPassThroughDialog,
        title: const Text('Keep full quality?'),
        content: const Text(
          'Every page is at 100%. The PDF may not become smaller.',
        ),
        actions: <Widget>[
          TextButton(
            key: PdfEditKeys.compressAdjustQuality,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Adjust quality'),
          ),
          FilledButton(
            key: PdfEditKeys.compressContinuePassThrough,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (continueAt100 != true) {
      cubit.dismissReview();
      return;
    }
    cubit.acknowledgeAllPassThrough();
  }
  if (!context.mounted) return;
  final destination = await _chooseDestination(context);
  if (destination == null || !context.mounted) return;
  await _runCommit(context, cubit, destination, onCompleted);
}

Future<CompressionDestination?> _chooseDestination(
  BuildContext context,
) => showDialog<CompressionDestination>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    key: PdfEditKeys.compressDestinationDialog,
    title: const Text('Where should it be saved?'),
    content: const Text(
      'A copy preserves the original. Overwrite safely replaces it after verification.',
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Cancel'),
      ),
      OutlinedButton(
        key: PdfEditKeys.compressDestinationCopy,
        onPressed: () =>
            Navigator.pop(dialogContext, CompressionDestination.copy),
        child: const Text('Save as copy'),
      ),
      FilledButton(
        key: PdfEditKeys.compressDestinationOverwrite,
        onPressed: () =>
            Navigator.pop(dialogContext, CompressionDestination.overwrite),
        child: const Text('Overwrite original'),
      ),
    ],
  ),
);

Future<void> _runPreview(
  BuildContext context,
  CompressPdfCubit cubit,
  OpenCompressionPreview onOpenPreview,
) async {
  unawaited(_showProgress(context, cubit, preview: true));
  final handle = await cubit.previewPdf();
  if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  if (handle != null) onOpenPreview(handle);
}

Future<void> _runCommit(
  BuildContext context,
  CompressPdfCubit cubit,
  CompressionDestination destination,
  CompleteCompression onCompleted, {
  bool allowNoBenefit = false,
}) async {
  unawaited(_showProgress(context, cubit, preview: false));
  final result = await cubit.saveTo(
    destination,
    allowNoBenefit: allowNoBenefit,
  );
  if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  if (result != null) {
    onCompleted(result);
    return;
  }
  if (!context.mounted || !cubit.state.showNoBenefitReview) return;
  final continueSaving = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: PdfEditKeys.compressNoBenefitDialog,
      title: const Text('No size reduction'),
      content: Text(
        'The result is ${_formatBytes(cubit.state.calculatedBytes ?? cubit.state.originalBytes)}. Save it anyway?',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Adjust quality'),
        ),
        FilledButton(
          key: PdfEditKeys.compressContinueNoBenefit,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Save anyway'),
        ),
      ],
    ),
  );
  if (continueSaving == true && context.mounted) {
    await _runCommit(
      context,
      cubit,
      destination,
      onCompleted,
      allowNoBenefit: true,
    );
  } else {
    cubit.dismissReview();
  }
}

Future<void> _showProgress(
  BuildContext context,
  CompressPdfCubit cubit, {
  required bool preview,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => BlocProvider<CompressPdfCubit>.value(
    value: cubit,
    child: BlocBuilder<CompressPdfCubit, CompressPdfState>(
      builder: (context, state) {
        final job = preview ? state.preview : state.commit;
        final progress = job is AsyncJobRunning ? job.progress.percent : 0;
        return AlertDialog(
          key: PdfEditKeys.compressProgressDialog,
          title: Text(preview ? 'Preparing preview' : 'Saving compressed PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LinearProgressIndicator(
                key: PdfEditKeys.compressProgressIndicator,
                value: progress / 100,
              ),
              const SizedBox(height: 12),
              Text('$progress percent'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              key: PdfEditKeys.compressCancelJob,
              onPressed: preview ? cubit.cancelPreview : cubit.cancelSave,
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ),
  ),
);

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(kib >= 10 ? 0 : 1)} KB';
  final mib = kib / 1024;
  return '${mib.toStringAsFixed(mib >= 10 ? 0 : 1)} MB';
}

/// Dialog state rendered independently by deterministic previews and goldens.
enum CompressionDialogPreviewKind {
  /// Page-specific quality override.
  pageQuality,

  /// All-pages-100 warning.
  passThrough,

  /// Copy-or-overwrite choice.
  destination,

  /// Exact candidate did not reduce bytes.
  noBenefit,

  /// Cancellable determinate commit progress.
  progress,
}

/// Inert rendering of each compression dialog for visual verification.
///
/// The interactive screen uses the same keys, copy, and controls above. This
/// surface removes navigation callbacks so IDE previews and golden tests can
/// render a dialog without first driving an asynchronous route.
class CompressionDialogPreview extends StatelessWidget {
  /// Creates one deterministic dialog state.
  const CompressionDialogPreview({required this.kind, super.key});

  /// Dialog to render.
  final CompressionDialogPreviewKind kind;

  @override
  Widget build(BuildContext context) => switch (kind) {
    CompressionDialogPreviewKind.pageQuality => AlertDialog(
      title: const Text('Page 2 quality'),
      content: Slider(
        key: PdfEditKeys.compressPageSlider,
        min: 30,
        max: 100,
        divisions: 70,
        value: 50,
        onChanged: (_) {},
      ),
      actions: <Widget>[
        TextButton(
          key: PdfEditKeys.compressUseDocumentQuality,
          onPressed: () {},
          child: const Text('Use document quality'),
        ),
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        FilledButton(onPressed: () {}, child: const Text('Apply')),
      ],
    ),
    CompressionDialogPreviewKind.passThrough => AlertDialog(
      key: PdfEditKeys.compressPassThroughDialog,
      title: const Text('Keep full quality?'),
      content: const Text(
        'Every page is at 100%. The PDF may not become smaller.',
      ),
      actions: <Widget>[
        TextButton(
          key: PdfEditKeys.compressAdjustQuality,
          onPressed: () {},
          child: const Text('Adjust quality'),
        ),
        FilledButton(
          key: PdfEditKeys.compressContinuePassThrough,
          onPressed: () {},
          child: const Text('Continue'),
        ),
      ],
    ),
    CompressionDialogPreviewKind.destination => AlertDialog(
      key: PdfEditKeys.compressDestinationDialog,
      title: const Text('Where should it be saved?'),
      content: const Text(
        'A copy preserves the original. Overwrite safely replaces it after verification.',
      ),
      actions: <Widget>[
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        OutlinedButton(
          key: PdfEditKeys.compressDestinationCopy,
          onPressed: () {},
          child: const Text('Save as copy'),
        ),
        FilledButton(
          key: PdfEditKeys.compressDestinationOverwrite,
          onPressed: () {},
          child: const Text('Overwrite original'),
        ),
      ],
    ),
    CompressionDialogPreviewKind.noBenefit => AlertDialog(
      key: PdfEditKeys.compressNoBenefitDialog,
      title: const Text('No size reduction'),
      content: const Text('The result is 3.1 MB. Save it anyway?'),
      actions: <Widget>[
        TextButton(onPressed: () {}, child: const Text('Adjust quality')),
        FilledButton(
          key: PdfEditKeys.compressContinueNoBenefit,
          onPressed: () {},
          child: const Text('Save anyway'),
        ),
      ],
    ),
    CompressionDialogPreviewKind.progress => AlertDialog(
      key: PdfEditKeys.compressProgressDialog,
      title: const Text('Saving compressed PDF'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LinearProgressIndicator(
            key: PdfEditKeys.compressProgressIndicator,
            value: 0.62,
          ),
          SizedBox(height: 12),
          Text('62 percent'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: PdfEditKeys.compressCancelJob,
          onPressed: () {},
          child: const Text('Cancel'),
        ),
      ],
    ),
  };
}
