/// The dialog that names — and optionally protects — a document being saved.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/features/document_creation/presentation/creation_keys.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/save_document_state.dart';
import 'package:flutter/material.dart';

/// Asks for a name before anything is written.
///
/// Takes its state and callbacks rather than reading a Cubit, so it can be
/// previewed and golden-tested at any state without one.
///
/// Password protection is offered here rather than afterwards because this is
/// the moment the file is created: protecting it later would mean writing an
/// unprotected version first, into a folder other applications can read.
class SaveNameDialog extends StatelessWidget {
  /// Creates the dialog over [state].
  const SaveNameDialog({
    required this.state,
    required this.onNameChanged,
    required this.onPasswordChanged,
    required this.onConfirmationChanged,
    required this.onPasswordEnabledChanged,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  /// What the dialog shows.
  final SaveDocumentState state;

  /// Called as the name is edited.
  final ValueChanged<String> onNameChanged;

  /// Called as the password is edited.
  final ValueChanged<String> onPasswordChanged;

  /// Called as the confirmation is edited.
  final ValueChanged<String> onConfirmationChanged;

  /// Called when password protection is turned on or off.
  final ValueChanged<bool> onPasswordEnabledChanged;

  /// Dismisses without writing anything.
  final VoidCallback onCancel;

  /// Writes the document.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: CreationKeys.saveDialog,
      title: const Text('Save PDF'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: CreationKeys.saveNameField,
              initialValue: state.name,
              enabled: !state.isSaving,
              autofocus: true,
              decoration: InputDecoration(
                labelText: CreationSemantics.saveNameField,
                suffixText: '.pdf',
                errorText: _messageFor(state.nameProblem),
              ),
              onChanged: onNameChanged,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: CreationKeys.savePasswordToggle,
              contentPadding: EdgeInsets.zero,
              title: const Text(CreationSemantics.savePasswordToggle),
              subtitle: const Text(CreationSemantics.savePasswordHint),
              value: state.passwordEnabled,
              onChanged: state.isSaving ? null : onPasswordEnabledChanged,
            ),
            if (state.passwordEnabled) ...[
              TextFormField(
                key: CreationKeys.savePasswordField,
                enabled: !state.isSaving,
                obscureText: true,
                // Excluded from autofill: this password belongs to one
                // document, not to an account, and offering to save it to a
                // keychain would file it under the wrong thing entirely.
                autofillHints: const [],
                decoration: const InputDecoration(
                  labelText: CreationSemantics.savePasswordField,
                ),
                onChanged: onPasswordChanged,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: CreationKeys.savePasswordConfirmField,
                enabled: !state.isSaving,
                obscureText: true,
                autofillHints: const [],
                decoration: InputDecoration(
                  labelText: CreationSemantics.savePasswordConfirmField,
                  errorText: _messageFor(state.passwordProblem),
                ),
                onChanged: onConfirmationChanged,
              ),
            ],
            if (state.isSaving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (state.failure != null) ...[
              const SizedBox(height: 12),
              Text(
                state.message ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Both actions name what they act on: "Save" and "Cancel" are what a
        // listener hears in every dialog the application has, and this is the
        // one where the difference is a document either existing or not.
        Semantics(
          button: true,
          label: CreationSemantics.saveCancel,
          excludeSemantics: true,
          child: TextButton(
            key: CreationKeys.saveCancelButton,
            // Enabled even while saving: cancelling is how the user stops, and
            // a dialog with no way out during a slow write is a trap.
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        Semantics(
          button: true,
          enabled: state.canSave,
          label: CreationSemantics.saveConfirm,
          excludeSemantics: true,
          child: FilledButton(
            key: CreationKeys.saveConfirmButton,
            onPressed: state.canSave ? onSave : null,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  /// The message for [issue], or null when there is none.
  ///
  /// Null rather than an empty string: an empty `errorText` still reserves the
  /// space for one, which makes the field jump as the user types.
  static String? _messageFor(ValidationIssue? issue) => issue == null
      ? null
      : Failure.validation(issue: issue).presentation.message;
}
