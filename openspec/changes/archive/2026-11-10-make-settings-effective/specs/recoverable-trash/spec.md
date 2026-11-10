# Spec Delta

## MODIFIED Requirements

### Requirement: Recursive destructive-action preflight
Before moving a non-empty folder tree to Trash, the application SHALL recursively inventory and disclose its documents, descendant folders, other files and bytes without relying only on indexed document records.

#### Scenario: Non-empty folder warning
- **WHEN** a folder contains four documents, two descendant folders and one other file
- **THEN** `Key('trash_move_confirmation')` states those counts, says the content can be restored for up to 30 days, and offers Cancel and `Key('trash_move_confirm')`

#### Scenario: Cancel preserves everything
- **WHEN** the user cancels the move-to-Trash confirmation
- **THEN** no public file, folder, index record, page record or password changes

#### Scenario: Empty folder remains recoverable
- **WHEN** the user moves an empty folder to Trash
- **THEN** the empty folder appears as a restorable Trash entry and no misleading content count is shown

#### Scenario: Inventory failure is safe
- **WHEN** the complete subtree cannot be inventoried
- **THEN** the operation is refused with a retryable message and nothing is deleted or moved

### Requirement: Restore without overwrite
The application SHALL restore a Trash entry with its metadata and protection intact and SHALL never overwrite an existing active path.

#### Scenario: Original path is free
- **WHEN** the user activates `Key('trash_restore_<id>')` with semantics “Restore <name>” and the original path is available
- **THEN** the complete entry returns to its original path, retains identifiers, favourite/archive state, pages and protection, and disappears from Trash

#### Scenario: Original path is occupied
- **WHEN** restoration finds a file or folder at the original path
- **THEN** the restored root receives the first available deterministic “(Recovered N)” suffix, descendants keep their relative structure, and existing content is unchanged

#### Scenario: Undo after move
- **WHEN** the “Moved to Trash” snackbar is visible and the user activates its Undo action
- **THEN** the just-moved entry is restored using the same collision-safe rule

#### Scenario: Restore failure remains recoverable
- **WHEN** storage fails while restoring an entry
- **THEN** the app reports the failure and retains a consistent Trash entry that can be retried

### Requirement: Permanent removal and empty Trash
Permanent removal SHALL be available only in Trash, SHALL require an explicit irreversible confirmation, and SHALL delete payload bytes and all associated metadata and credentials.

#### Scenario: Permanently remove one entry
- **WHEN** the user activates `Key('trash_delete_permanently_<id>')`, confirms through `Key('trash_permanent_delete_confirm')`, and the operation succeeds
- **THEN** the payload, document/folder records, pages, derived caches and protected-document passwords are removed and the entry disappears from Trash

#### Scenario: Permanent removal warning
- **WHEN** the permanent-removal dialog is shown
- **THEN** it names the item, states “This cannot be undone,” and exposes Cancel and a destructive confirmation with semantics “Delete <name> permanently”

#### Scenario: Empty Trash
- **WHEN** the user activates `Key('trash_empty_button')` with semantics “Empty Trash” and confirms
- **THEN** every Trash entry is permanently removed and the screen displays its empty state

#### Scenario: Partial empty failure
- **WHEN** permanent removal fails part-way through Empty Trash
- **THEN** processing stops, unprocessed entries remain listed and retryable, and already removed entries do not reappear
