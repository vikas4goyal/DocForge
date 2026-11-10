/// The building blocks of the settings screen.
///
/// Every tile announces its **name and current value together**, which the
/// accessibility scenario requires: a screen reader that reads "Theme" and then
/// "Dark" as two separate items leaves the user to associate them, and in a
/// list of ten settings that is guesswork.
library;

import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';

/// A setting whose value is chosen from a fixed set.
///
/// Generic over the choice type so each setting keeps its own enum rather than
/// being stringly-typed at the widget boundary.
class SettingsChoiceTile<T> extends StatelessWidget {
  /// Creates a choice tile.
  const SettingsChoiceTile({
    required this.title,
    required this.value,
    required this.valueLabel,
    required this.options,
    required this.labelFor,
    required this.onSelected,
    super.key,
    this.descriptionFor,
    this.footer,
  });

  /// The setting's name.
  final String title;

  /// The current value.
  final T value;

  /// How the current value is shown.
  final String valueLabel;

  /// Every value that can be chosen.
  final List<T> options;

  /// How an option is named.
  final String Function(T option) labelFor;

  /// How an option's trade-off is described, when it has one.
  final String Function(T option)? descriptionFor;

  /// Invoked with the chosen value.
  final ValueChanged<T> onSelected;

  /// Extra content shown beneath the tile, such as a preview.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: SettingsSemantics.choiceTile(title, valueLabel),
          excludeSemantics: true,
          child: ListTile(
            title: Text(title),
            subtitle: Text(valueLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _choose(context),
          ),
        ),
        ?footer,
      ],
    );
  }

  Future<void> _choose(BuildContext context) async {
    final chosen = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        key: SettingsKeys.choiceSheet,
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              // Keep the options scrollable so quality descriptions remain
              // reachable on short devices and with large accessibility text.
              Flexible(
                child: RadioGroup<T>(
                  groupValue: value,
                  onChanged: (chosen) => Navigator.of(sheetContext).pop(chosen),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      for (final option in options)
                        RadioListTile<T>(
                          key: SettingsKeys.choiceOption(
                            SettingsKeys.optionNameOf(option),
                          ),
                          value: option,
                          title: Text(labelFor(option)),
                          subtitle: descriptionFor == null
                              ? null
                              : Text(descriptionFor!(option)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (chosen != null && chosen != value) onSelected(chosen);
  }
}

/// A setting whose value is a whole number picked on an inline slider.
///
/// Used for the default PDF quality, a 30–100% range: a list of seventy-one
/// radio options is not a usable way to pick a percentage. The title, the live
/// value ("45%") and [description] sit above a full-width Material slider.
///
/// Required inputs: [title], [value], [min]/[max] and the two callbacks.
/// [sliderKey] keys the slider itself so flows can drag it, and
/// [semanticLabelFor] supplies what a screen reader announces for a value, for
/// example "Default PDF quality, 45 percent". The tile's own `key` sits on the
/// outer container. When [enabled] is false the slider is shown but inert,
/// which is how the loading state presents it.
class SettingsSliderTile extends StatelessWidget {
  /// Creates a slider tile.
  const SettingsSliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
    required this.semanticLabelFor,
    super.key,
    this.sliderKey,
    this.valueLabelFor,
    this.description,
    this.enabled = true,
  });

  /// The setting's name.
  final String title;

  /// The value shown on the slider, clamped into [min]..[max] for display.
  final int value;

  /// The smallest selectable value.
  final int min;

  /// The largest selectable value.
  final int max;

  /// Invoked continuously while the user drags, for a live preview only.
  final ValueChanged<int> onChanged;

  /// Invoked once when a drag or a keyboard/accessibility step ends — the
  /// single point at which the value is persisted.
  final ValueChanged<int> onChangeEnd;

  /// What a screen reader announces for a value.
  final String Function(int value) semanticLabelFor;

  /// The key placed on the slider control itself.
  final Key? sliderKey;

  /// How a value is shown beside the title; defaults to the bare number.
  final String Function(int value)? valueLabelFor;

  /// The trade-off the value controls, shown under the title.
  final String? description;

  /// Whether the slider accepts input.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = value.clamp(min, max);
    final label = valueLabelFor?.call(shown) ?? '$shown';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and value are one semantic node, "PDF quality, 45%", read
          // together like every other tile; the slider below carries its own,
          // more specific announcement.
          Semantics(
            container: true,
            label: SettingsSemantics.choiceTile(title, label),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Semantics(
              container: true,
              child: Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          // 48dp minimum, the touch-target floor, whatever the theme's
          // default slider height happens to be.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Semantics(
              label: semanticLabelFor(shown),
              child: Slider(
                key: sliderKey,
                value: shown.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                // The value is announced as the bare formatted value; the label
                // above already names the setting.
                semanticFormatterCallback: (raw) =>
                    valueLabelFor?.call(raw.round()) ?? '${raw.round()}',
                onChanged: enabled ? (raw) => onChanged(raw.round()) : null,
                // Persisted here rather than in onChanged: a single drag passes
                // through dozens of values, and writing each would mean dozens
                // of preference writes and racing failure banners.
                onChangeEnd: enabled ? (raw) => onChangeEnd(raw.round()) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A setting that shows a value and, optionally, does something when tapped.
class SettingsValueTile extends StatelessWidget {
  /// Creates a value tile.
  const SettingsValueTile({
    required this.title,
    required this.value,
    super.key,
    this.onTap,
    this.detail,
  });

  /// The setting's name.
  final String title;

  /// The current value, or an empty string for an entry that has none.
  final String value;

  /// A short line under the value explaining what it does, when it needs one.
  final String? detail;

  /// Invoked when tapped. A null handler makes the tile inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: [title, if (value.isNotEmpty) value, ?detail].join(', '),
      excludeSemantics: true,
      child: ListTile(
        title: Text(title),
        subtitle: value.isEmpty
            ? null
            : Text(detail == null ? value : '$value\n$detail'),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// A setting that is either on or off.
class SettingsSwitchTile extends StatelessWidget {
  /// Creates a switch tile.
  const SettingsSwitchTile({
    required this.title,
    required this.value,
    super.key,
    this.subtitle,
    this.onChanged,
  });

  /// The setting's name.
  final String title;

  /// Whether it is currently on.
  final bool value;

  /// Supporting text explaining what it does.
  final String? subtitle;

  /// Invoked with the requested state. A null handler disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: SettingsSemantics.switchTile(title, on: value),
      excludeSemantics: true,
      child: SwitchListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Shows what the chosen naming pattern will produce.
///
/// Required by the spec: "Sequential" tells the user nothing about whether they
/// will get "Scan 1" or "Scan 0001".
class NamingPatternPreview extends StatelessWidget {
  /// Creates the preview showing [example].
  const NamingPatternPreview({required this.example, super.key});

  /// An example of a generated name.
  final String example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      key: SettingsKeys.namingPreview,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Semantics(
        label: SettingsSemantics.namingPreview(example),
        excludeSemantics: true,
        child: Text(
          'Example: $example',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
