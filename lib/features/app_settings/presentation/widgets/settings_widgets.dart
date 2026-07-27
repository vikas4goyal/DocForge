/// The building blocks of the settings screen.
///
/// Every tile announces its **name and current value together**, which the
/// accessibility scenario requires: a screen reader that reads "Theme" and then
/// "Dark" as two separate items leaves the user to associate them, and in a
/// list of ten settings that is guesswork.
library;

import 'package:doc_forge/features/app_settings/presentation/settings_keys.dart';
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
          label: '$title, $valueLabel',
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
            // `RadioGroup` rather than per-tile `groupValue`/`onChanged`,
            // which Flutter deprecated: the group owns the selection, so a
            // tile cannot disagree with its siblings about what is selected.
            RadioGroup<T>(
              groupValue: value,
              onChanged: (chosen) => Navigator.of(sheetContext).pop(chosen),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    RadioListTile<T>(
                      value: option,
                      title: Text(labelFor(option)),
                      subtitle: descriptionFor == null
                          ? null
                          : Text(descriptionFor!(option)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (chosen != null && chosen != value) onSelected(chosen);
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
  });

  /// The setting's name.
  final String title;

  /// The current value, or an empty string for an entry that has none.
  final String value;

  /// Invoked when tapped. A null handler makes the tile inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: value.isEmpty ? title : '$title, $value',
      excludeSemantics: true,
      child: ListTile(
        title: Text(title),
        subtitle: value.isEmpty ? null : Text(value),
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
      label: '$title, ${value ? 'on' : 'off'}',
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
        label: 'Example name, $example',
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
