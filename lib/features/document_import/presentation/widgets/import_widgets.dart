/// The building blocks of the import flow.
library;

import 'package:doc_forge/features/document_import/domain/import_rules.dart';
import 'package:doc_forge/features/document_import/presentation/import_keys.dart';
import 'package:flutter/material.dart';

/// One import source in the options sheet.
///
/// A list tile rather than an icon: the accessibility scenario requires each
/// source to describe where content will come from, and a visible label conveys
/// that to everyone rather than only to a screen reader.
class ImportSourceTile extends StatelessWidget {
  /// Creates a tile for [source].
  const ImportSourceTile({required this.source, super.key, this.onTap});

  /// The source this tile offers.
  final ImportSource source;

  /// Invoked when the source is chosen. A null handler disables the tile.
  final VoidCallback? onTap;

  /// The icon shown for [source].
  IconData get _icon => switch (source) {
    ImportSource.camera => Icons.photo_camera_outlined,
    ImportSource.gallery => Icons.photo_library_outlined,
    ImportSource.files => Icons.folder_open_outlined,
    ImportSource.shareSheet => Icons.ios_share_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: source.semanticsLabel,
      // The tile already renders the same words; excluding them stops a screen
      // reader reading the label and then the visible text after it.
      excludeSemantics: true,
      child: ListTile(
        leading: Icon(_icon),
        title: Text(source.label),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}

/// The prompt shown for a password-protected imported PDF.
///
/// Offers cancellation as prominently as submission, because the spec requires
/// an abandoned import to create no document — and a prompt with no way out
/// but a correct password would strand the user on a file they cannot open.
class ImportPasswordPrompt extends StatefulWidget {
  /// Creates the prompt.
  const ImportPasswordPrompt({
    required this.onSubmit,
    required this.onCancel,
    super.key,
    this.wasRejected = false,
  });

  /// Invoked with the entered password.
  final ValueChanged<String> onSubmit;

  /// Invoked when the user abandons the import.
  final VoidCallback onCancel;

  /// Whether the previous attempt was rejected.
  final bool wasRejected;

  @override
  State<ImportPasswordPrompt> createState() => _ImportPasswordPromptState();
}

class _ImportPasswordPromptState extends State<ImportPasswordPrompt> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    // The entry is cleared as well as disposed. A password is held in memory
    // only for as long as the operation needs it.
    _controller
      ..clear()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This PDF is password-protected.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            key: ImportKeys.passwordField,
            controller: _controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: widget.wasRejected
                  ? 'That password did not open the file.'
                  : null,
            ),
            onSubmitted: widget.onSubmit,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: ImportKeys.passwordSubmitButton,
            onPressed: () => widget.onSubmit(_controller.text),
            child: const Text('Open'),
          ),
          TextButton(
            key: ImportKeys.passwordCancelButton,
            onPressed: widget.onCancel,
            child: const Text('Cancel import'),
          ),
        ],
      ),
    );
  }
}
