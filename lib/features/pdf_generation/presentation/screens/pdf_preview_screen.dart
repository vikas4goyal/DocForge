/// The document preview and save screen.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_cubit.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_state.dart';
import 'package:doc_forge/features/pdf_generation/presentation/pdf_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the finished document and saves it.
///
/// Nothing is written until the user saves, which is what makes navigating back
/// from here leave the session intact and no PDF on disk.
class PdfPreviewScreen extends StatelessWidget {
  /// Creates the preview screen.
  const PdfPreviewScreen({
    required this.onSaved,
    required this.onBack,
    super.key,
  });

  /// Called with the saved document once it exists.
  final void Function(Document document) onSaved;

  /// Called when the user leaves without saving.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PdfGenerationCubit, PdfGenerationState>(
      listenWhen: (previous, current) => !previous.isSaved && current.isSaved,
      listener: (context, state) {
        if (state.document case final document?) onSaved(document);
      },
      builder: (context, state) {
        final cubit = context.read<PdfGenerationCubit>();

        return Scaffold(
          key: PdfKeys.previewScreen,
          appBar: AppBar(
            title: const Text('Save document'),
            leading: BackButton(onPressed: onBack),
          ),
          body: SafeArea(
            child: switch (state.status) {
              PdfGenerationStatus.failure when state.failure != null =>
                AppErrorView(
                  key: PdfKeys.errorView,
                  failure: state.failure!,
                  retryKey: PdfKeys.errorRetryButton,
                  onRetry: cubit.retry,
                  onGoBack: onBack,
                ),
              PdfGenerationStatus.generating => _Generating(cubit: cubit),
              _ => _Preview(state: state, cubit: cubit),
            },
          ),
        );
      },
    );
  }
}

/// Progress and cancellation while the PDF is composed.
class _Generating extends StatelessWidget {
  const _Generating({required this.cubit});

  final PdfGenerationCubit cubit;

  @override
  Widget build(BuildContext context) {
    // No page count: composition reports completion, not per-page progress,
    // because the expensive step is inside one call to the PDF library. An
    // indeterminate bar is honest where a fake percentage would not be.
    return AppProgressIndicator(
      key: PdfKeys.generationProgress,
      completed: 0,
      total: 0,
      label: 'Creating your document',
      onCancel: cubit.cancel,
    );
  }
}

/// The name field, the quality choice and the page list.
class _Preview extends StatelessWidget {
  const _Preview({required this.state, required this.cubit});

  final PdfGenerationState state;
  final PdfGenerationCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                key: PdfKeys.documentNameField,
                // The generated name is the field's *initial* value rather than
                // a hint, so a user who saves without typing gets the name they
                // can see rather than one they have to guess.
                initialValue: state.title,
                onChanged: cubit.setTitle,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Document name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _QualitySelector(state: state, cubit: cubit),
            ],
          ),
        ),
        Expanded(child: _PageList(pages: state.pages)),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: PdfKeys.saveButton,
                onPressed: state.canSave ? cubit.save : null,
                icon: const Icon(Icons.save_outlined),
                label: Text('Save ${state.pageCount}-page document'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The fidelity choice.
class _QualitySelector extends StatelessWidget {
  const _QualitySelector({required this.state, required this.cubit});

  final PdfGenerationState state;
  final PdfGenerationCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Document quality',
      value: state.quality.label,
      child: SegmentedButton<PdfQuality>(
        key: PdfKeys.qualitySelector,
        segments: [
          for (final quality in PdfQuality.values)
            ButtonSegment(value: quality, label: Text(quality.label)),
        ],
        selected: {state.quality},
        onSelectionChanged: (selected) => cubit.setQuality(selected.first),
      ),
    );
  }
}

/// The pages as they will appear in the PDF.
class _PageList extends StatelessWidget {
  const _PageList({required this.pages});

  final List<PageRef> pages;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const AppEmptyState(
        title: 'No pages',
        message: 'A document needs at least one page.',
        icon: Icons.description_outlined,
      );
    }

    return GridView.builder(
      key: PdfKeys.pageList,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // Wider viewports get more columns rather than larger thumbnails: on a
      // tablet the point of the extra width is seeing more of the document at
      // once.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) =>
          _PagePreview(page: pages[index], number: index + 1),
    );
  }
}

/// One page thumbnail with its number.
class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.page, required this.number});

  final PageRef page;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      image: true,
      label: 'Page $number',
      child: ExcludeSemantics(
        child: Column(
          key: PdfKeys.pageItem(page.id.value),
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: ClipRect(
                  child: Transform.rotate(
                    // Shown as it will be composed, so the preview is a promise
                    // rather than an approximation.
                    angle: page.rotation.degrees * 3.1415926535 / 180,
                    child: Image.file(
                      File(page.imagePath),
                      fit: BoxFit.contain,
                      // A page image that cannot be read must not take the
                      // screen down; the page still exists and still composes.
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_outlined,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('$number', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
