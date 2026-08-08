/// The enhancement screen.
library;

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/widgets/enhancement_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lets the user tune how a captured page is rendered.
///
/// Takes its callbacks rather than navigating itself, so the screen can be
/// previewed, golden-tested and hosted by whichever flow needs it — scanning
/// today, import once that lands.
///
/// Nothing here writes to the stored page. Settings are recorded on the session
/// and the full-resolution image is produced when the document is built, which
/// is what makes leaving without saving leave the page exactly as captured.
class EnhancementScreen extends StatelessWidget {
  /// Creates the enhancement screen.
  const EnhancementScreen({required this.onDone, super.key});

  /// Called with the page once the user is finished.
  ///
  /// Carries the settings, not pixels: the full-resolution result is produced
  /// when the document is built, which is what makes leaving without finishing
  /// leave the page exactly as it was.
  final void Function(PageDraft page) onDone;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnhancementCubit, EnhancementState>(
      builder: (context, state) {
        final cubit = context.read<EnhancementCubit>();

        return Scaffold(
          key: EnhanceKeys.screen,
          appBar: AppBar(
            title: Text(
              'Enhance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // Undo and Reset live here rather than under the controls. Below a
            // column of filters and sliders they sat at the very bottom of the
            // screen — the furthest point from the thing being corrected, and
            // off-screen entirely once the controls scrolled. Undo in
            // particular is used *while* adjusting, so it has to stay put.
            actions: [
              IconButton(
                key: EnhanceKeys.undoButton,
                tooltip: 'Undo last change',
                onPressed: state.canUndo ? cubit.undo : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: EnhanceKeys.resetButton,
                // Named for the layer it affects: the page's crop is not this
                // screen's business, and a bare "Reset" would read as though
                // it were.
                tooltip: 'Revert enhancement',
                onPressed: state.hasChanges ? cubit.revertEnhancement : null,
                icon: const Icon(Icons.restart_alt),
              ),
              TextButton(
                key: EnhanceKeys.doneButton,
                onPressed: () => onDone(cubit.edited),
                child: const Text('Done'),
              ),
            ],
          ),
          body: SafeArea(
            child: switch (state.status) {
              EnhancementStatus.failure when state.failure != null =>
                AppErrorView(
                  key: EnhanceKeys.errorView,
                  failure: state.failure!,
                  retryKey: EnhanceKeys.errorRetryButton,
                  onRetry: cubit.retry,
                ),
              _ => ResponsiveLayout(
                compact: (context) => _Stacked(state: state, cubit: cubit),
                expanded: (context) => _SideBySide(state: state, cubit: cubit),
              ),
            },
          ),
        );
      },
    );
  }
}

/// Phone layout: preview above, controls below.
class _Stacked extends StatelessWidget {
  const _Stacked({required this.state, required this.cubit});

  final EnhancementState state;
  final EnhancementCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: EnhancementPreview(
            imagePath: state.displayedImagePath,
            isRendering: state.isPreviewing,
            onPhysicalLongestEdgeChanged: cubit.updatePreviewDimension,
          ),
        ),
        Expanded(
          flex: 2,
          child: _Controls(state: state, cubit: cubit),
        ),
      ],
    );
  }
}

/// Tablet layout: preview beside the controls.
///
/// The extra width goes to the preview rather than to wider sliders — a page is
/// what the user is judging, and a slider twice as long is no easier to use.
class _SideBySide extends StatelessWidget {
  const _SideBySide({required this.state, required this.cubit});

  final EnhancementState state;
  final EnhancementCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: EnhancementPreview(
            imagePath: state.displayedImagePath,
            isRendering: state.isPreviewing,
            onPhysicalLongestEdgeChanged: cubit.updatePreviewDimension,
          ),
        ),
        SizedBox(
          width: 360,
          child: _Controls(state: state, cubit: cubit),
        ),
      ],
    );
  }
}

/// The filter row, the adjustment sliders and the session actions.
class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.cubit});

  final EnhancementState state;
  final EnhancementCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: EnhanceKeys.controlsList,
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            key: EnhanceKeys.filterList,
            scrollDirection: Axis.horizontal,
            itemCount: EnhancementFilter.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = EnhancementFilter.values[index];
              return EnhancementFilterChip(
                filter: filter,
                selected: state.settings.filter == filter,
                onSelected: cubit.selectFilter,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        AdjustmentSlider(
          key: EnhanceKeys.brightnessSlider,
          label: EnhanceSemantics.brightness,
          value: state.settings.brightness,
          onChanged: cubit.setBrightness,
        ),
        AdjustmentSlider(
          key: EnhanceKeys.contrastSlider,
          label: EnhanceSemantics.contrast,
          value: state.settings.contrast,
          min: EnhancementRules.minContrast,
          max: EnhancementRules.maxContrast,
          onChanged: cubit.setContrast,
        ),
        AdjustmentSlider(
          key: EnhanceKeys.sharpenControl,
          label: EnhanceSemantics.sharpen,
          value: state.settings.sharpen,
          min: EnhancementRules.minSharpen,
          max: EnhancementRules.maxSharpen,
          onChanged: cubit.setSharpen,
        ),
        SwitchListTile(
          key: EnhanceKeys.shadowRemovalToggle,
          title: const Text('Remove shadows'),
          subtitle: const Text('Evens out uneven lighting'),
          value: state.settings.shadowRemoval,
          onChanged: (value) => cubit.setShadowRemoval(enabled: value),
        ),
      ],
    );
  }
}
