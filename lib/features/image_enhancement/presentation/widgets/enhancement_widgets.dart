/// The reusable controls of the enhancement screen.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_scanly/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:flutter/material.dart';

/// A selectable enhancement filter.
///
/// Named `EnhancementFilterChip` rather than `FilterChip` because Material
/// already ships a widget by that name; a screen importing both would not
/// compile, and the ambiguity would be resolved differently in each file.
///
/// Announces its name and whether it is selected, which the spec requires of
/// the filter list under a screen reader.
class EnhancementFilterChip extends StatelessWidget {
  /// Creates a chip for [filter].
  const EnhancementFilterChip({
    required this.filter,
    required this.selected,
    super.key,
    this.onSelected,
  });

  /// The filter this chip selects.
  final EnhancementFilter filter;

  /// Whether this filter is the active one.
  final bool selected;

  /// Called when the chip is activated.
  final ValueChanged<EnhancementFilter>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: filter.label,
      hint: filter.description,
      child: ExcludeSemantics(
        child: ChoiceChip(
          key: EnhanceKeys.forFilter(filter),
          label: Text(filter.label),
          selected: selected,
          onSelected: onSelected == null
              ? null
              : (_) => onSelected!.call(filter),
        ),
      ),
    );
  }
}

/// A labelled slider for one enhancement adjustment.
///
/// Exposes its current value to screen readers as a percentage rather than as
/// the raw -1.0 to 1.0 offset: "brightness, 30%" is something a listener can
/// act on, where "brightness, 0.3" requires knowing the scale.
class AdjustmentSlider extends StatelessWidget {
  /// Creates a slider for the adjustment named [label].
  const AdjustmentSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.min = EnhancementRules.minAdjustment,
    this.max = EnhancementRules.maxAdjustment,
    this.enabled = true,
  });

  /// The adjustment's name.
  final String label;

  /// The current value.
  final double value;

  /// Called as the value changes.
  final ValueChanged<double> onChanged;

  /// The lowest selectable value.
  final double min;

  /// The highest selectable value.
  final double max;

  /// Whether the control accepts input.
  final bool enabled;

  /// The value as a percentage of its range, for display and for semantics.
  String get _displayValue => '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      slider: true,
      enabled: enabled,
      label: label,
      value: _displayValue,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                Text(_displayValue, style: theme.textTheme.labelMedium),
              ],
            ),
            // Deliberately unkeyed. The key belongs to this widget, which is
            // what the spec names and what a test targets; repeating it on the
            // inner Slider would put two widgets under one key and make every
            // finder for it ambiguous.
            Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The page image as the current settings would render it.
///
/// Always drawn on a neutral surface rather than on the theme's background:
/// judging an enhancement against a dark surround makes every result look
/// brighter than it is, and the spec requires the preview to be accurate in
/// dark mode specifically.
class EnhancementPreview extends StatelessWidget {
  /// Creates a preview of the image at [imagePath].
  const EnhancementPreview({
    required this.imagePath,
    super.key,
    this.isRendering = false,
  });

  /// The image to display, or null when there is nothing to show.
  final String? imagePath;

  /// Whether a newer preview is currently being rendered.
  final bool isRendering;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    return Semantics(
      image: true,
      label: EnhanceSemantics.pagePreview,
      child: ExcludeSemantics(
        child: ColoredBox(
          // A fixed neutral grey in both themes, so the same enhancement is
          // judged against the same surround whichever theme is active.
          color: const Color(0xFF757575),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (path != null)
                Image.file(
                  File(path),
                  key: EnhanceKeys.preview,
                  fit: BoxFit.contain,
                  // A preview file that cannot be read is not fatal: the
                  // settings are still valid and the next render may succeed.
                  errorBuilder: (context, error, stackTrace) =>
                      const _PreviewPlaceholder(),
                )
              else
                const _PreviewPlaceholder(),
              // Layered over the previous preview rather than replacing it, so
              // the image does not blink out on every slider frame.
              if (isRendering)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in for a page image that cannot be displayed.
class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.image_outlined, size: 48, color: Colors.white70),
  );
}
