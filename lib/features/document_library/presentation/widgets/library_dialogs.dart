/// The dialogs the library uses to confirm and to collect names.
///
/// Each returns a value rather than acting, so the caller stays responsible for
/// the operation and the dialog stays trivially testable in isolation.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/features/document_library/domain/library_rules.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:flutter/material.dart';

/// Prompts for a document title or folder name.
///
/// Returns the entered name, or null when the user cancels. Validation happens
/// again in the use case: this only spares the user a round trip, it is not
/// where the rule lives.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialValue = '',
  Key? fieldKey,
  Key? confirmKey,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      fieldKey: fieldKey ?? LibraryKeys.documentRenameField,
      confirmKey: confirmKey ?? LibraryKeys.documentRenameConfirm,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialValue,
    required this.fieldKey,
    required this.confirmKey,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final Key fieldKey;
  final Key confirmKey;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = NameRules.normalise(_controller.text);
    if (name == null) {
      // The dialog stays open with the field's own message, so the user does
      // not lose what they typed to a dialog that closed and complained later.
      setState(() => _error = 'Enter a name.');
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        maxLength: NameRules.maxLength,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _confirm(),
        decoration: InputDecoration(
          labelText: LibrarySemantics.nameField,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: widget.confirmKey,
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Confirms permanent removal of a document.
///
/// Returns true only when the user explicitly confirms. Dismissing the dialog
/// any other way — the barrier, the back button, cancel — returns false, so an
/// accidental dismissal can never delete anything.
Future<bool> confirmPermanentRemoval(
  BuildContext context, {
  required String title,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: LibraryKeys.documentDeleteConfirmDialog,
      title: const Text('Delete permanently?'),
      content: Text(
        '“$title” and all of its pages and recognised text will be removed '
        'from this device. This cannot be undone.',
      ),
      actions: [
        // Labelled with what is being deleted, not just "Delete": a listener
        // who has lost track of which dialog is open cannot otherwise tell this
        // from any other delete in the application.
        Semantics(
          button: true,
          label: LibrarySemantics.deleteCancel,
          excludeSemantics: true,
          child: TextButton(
            key: LibraryKeys.documentDeleteCancelButton,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ),
        Semantics(
          button: true,
          label: LibrarySemantics.deleteConfirm(title),
          excludeSemantics: true,
          child: FilledButton(
            key: LibraryKeys.documentDeleteConfirmButton,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

/// Asks what should happen to a folder's documents before it is deleted.
///
/// Returns null when the user cancels. There is deliberately no default: the
/// spec requires that no document is silently lost, which means the choice must
/// come from the user rather than from a fallback here.
Future<FolderDeletionStrategy?> askFolderDeletionStrategy(
  BuildContext context, {
  required Folder folder,
}) {
  return showDialog<FolderDeletionStrategy>(
    context: context,
    builder: (context) => AlertDialog(
      key: LibraryKeys.folderDeleteStrategyDialog,
      title: Text('Delete “${folder.name}”?'),
      content: Text(
        folder.isEmpty
            ? 'This folder is empty.'
            : 'This folder contains ${folder.documentCount} '
                  '${folder.documentCount == 1 ? 'document' : 'documents'}. '
                  'What should happen to them?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // Both choices name the folder as well as the outcome: "Keep
        // documents" and "Delete documents" are indistinguishable to a listener
        // who cannot see which folder the dialog belongs to.
        Semantics(
          button: true,
          label: LibrarySemantics.folderDeleteMoveOut(folder.name),
          excludeSemantics: true,
          child: TextButton(
            key: LibraryKeys.folderDeleteMoveOut,
            onPressed: () => Navigator.of(
              context,
            ).pop(FolderDeletionStrategy.moveDocumentsOut),
            child: const Text('Keep documents'),
          ),
        ),
        Semantics(
          button: true,
          label: LibrarySemantics.folderDeleteWithDocuments(folder.name),
          excludeSemantics: true,
          child: FilledButton(
            key: LibraryKeys.folderDeleteWithDocuments,
            onPressed: () => Navigator.of(
              context,
            ).pop(FolderDeletionStrategy.deleteDocuments),
            child: const Text('Delete documents'),
          ),
        ),
      ],
    ),
  );
}

/// The outcome of the folder picker.
///
/// A sealed result rather than a nullable [Folder], because "unfile this
/// document" and "the user cancelled" are different answers that a null cannot
/// tell apart.
sealed class FolderChoice {
  const FolderChoice();
}

/// The user chose a folder.
class FolderChosen extends FolderChoice {
  /// Creates a choice of [folder].
  const FolderChosen(this.folder);

  /// The chosen folder.
  final Folder folder;
}

/// The user chose to leave the document unfiled.
class NoFolderChosen extends FolderChoice {
  /// Creates the unfiled choice.
  const NoFolderChosen();
}

/// Lets the user pick a destination folder, or none.
///
/// Returns null when the user cancels.
Future<FolderChoice?> showFolderPicker(
  BuildContext context, {
  required List<Folder> folders,
}) {
  return showDialog<FolderChoice>(
    context: context,
    builder: (context) => SimpleDialog(
      key: LibraryKeys.documentMoveDialog,
      title: const Text(LibrarySemantics.moveDialog),
      children: [
        Semantics(
          button: true,
          label: LibrarySemantics.moveOptionNone,
          excludeSemantics: true,
          child: SimpleDialogOption(
            key: LibraryKeys.documentMoveOptionNone,
            onPressed: () => Navigator.of(context).pop(const NoFolderChosen()),
            child: const Text('No folder'),
          ),
        ),
        for (final folder in folders)
          // Announced as the action rather than as the folder's bare name,
          // which on its own reads as a heading rather than as something the
          // user can choose.
          Semantics(
            button: true,
            label: LibrarySemantics.moveOption(folder.name),
            excludeSemantics: true,
            child: SimpleDialogOption(
              key: LibraryKeys.documentMoveOption(folder.id.value),
              onPressed: () => Navigator.of(context).pop(FolderChosen(folder)),
              child: Text(folder.name),
            ),
          ),
      ],
    ),
  );
}
