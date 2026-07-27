/// The building blocks of the sharing options.
library;

import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:doc_forge/features/document_sharing/presentation/share_keys.dart';
import 'package:flutter/material.dart';

/// One option in the share sheet.
///
/// A list tile rather than an icon button: the accessibility scenario requires
/// each option to name what will be shared and in what format, and a row with a
/// visible label conveys that to everyone rather than only to a screen reader.
///
/// Supply [semanticsLabel] from
/// [ShareRules.optionSemanticsLabel] so the spoken label stays a domain
/// decision rather than a string assembled in the widget tree.
class ShareOptionTile extends StatelessWidget {
  /// Creates an option showing [label] and [icon].
  const ShareOptionTile({
    required this.label,
    required this.icon,
    required this.semanticsLabel,
    super.key,
    this.subtitle,
    this.onTap,
  });

  /// The visible label.
  final String label;

  /// The leading icon.
  final IconData icon;

  /// What a screen reader announces, naming content and format.
  final String semanticsLabel;

  /// Supporting text, such as why an option is unavailable.
  final String? subtitle;

  /// Invoked when the option is chosen. A null handler disables the option.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      // The children already render the same words; excluding them stops a
      // screen reader reading the label and then the visible text after it.
      excludeSemantics: true,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle!),
        enabled: enabled,
        onTap: onTap,
      ),
    );
  }
}

/// The message shown in place of the text option when there is no text.
///
/// The spec allows either disabling the control or explaining the situation;
/// this does both, because a disabled control with no explanation leaves the
/// user guessing why.
class NoRecognisedTextNotice extends StatelessWidget {
  /// Creates the notice.
  const NoRecognisedTextNotice({super.key, this.onRunRecognition});

  /// Invoked when the user chooses to run recognition now.
  final VoidCallback? onRunRecognition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      key: ShareKeys.noTextMessage,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ShareRules.noTextMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRunRecognition != null)
            TextButton(
              key: ShareKeys.runRecognitionButton,
              onPressed: onRunRecognition,
              child: const Text(ShareRules.runRecognitionLabel),
            ),
        ],
      ),
    );
  }
}
