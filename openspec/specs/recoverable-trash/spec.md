# recoverable-trash Specification

## Purpose
TBD - created by archiving change add-recoverable-trash. Update Purpose after archive.
## Requirements
### Requirement: Recoverable Trash lifecycle
The application SHALL move documents and complete folder trees deleted inside DocForge to Trash, SHALL keep them recoverable for up to 30 days, and SHALL remove bytes irreversibly only through confirmed permanent removal or expiry.

#### Scenario: Document moved to Trash
- **WHEN** the user activates `Key('document_move_to_trash_button')` with semantics “Move <title> to Trash” and confirms
- **THEN** the document disappears from active library, recents, favourites, archive and search views, appears in Trash with its original path and deletion date, and remains recoverable

#### Scenario: Folder tree moved to Trash
- **WHEN** the user moves a folder to Trash from its dashboard action menu
- **THEN** the folder, all descendant folders, every contained document and every other file DocForge can inventory move as one Trash entry and disappear from active browsing

#### Scenario: Archive remains distinct
- **WHEN** a document is archived
- **THEN** it remains indefinitely at its public folder path and does not appear in Trash

#### Scenario: Retention boundary
- **WHEN** an entry reaches 30 days after its UTC deletion timestamp and expiry cleanup next runs
- **THEN** the entry is permanently removed
- **AND** an entry younger than 30 days is not removed

#### Scenario: Offline lifecycle
- **WHEN** the device has no network connection
- **THEN** move, list, restore, permanent removal and expiry complete entirely against local storage

### Requirement: Recursive destructive-action preflight
Before moving a non-empty folder tree to Trash, the application SHALL recursively inventory and disclose its documents, descendant folders, other files and bytes without relying only on indexed document records.

#### Scenario: Non-empty folder warning
- **WHEN** a folder contains four documents, two descendant folders and one other file
- **THEN** `Key('trash_move_confirmation')` states those counts, says the content can be restored for up to 30 days, and offers Cancel and `Key('trash_move_confirm')`

#### Scenario: Cancel preserves everything
- **WHEN** the user cancels the move-to-Trash confirmation
- **THEN** no public file, folder, index record, OCR record, page record or password changes

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
- **THEN** the complete entry returns to its original path, retains identifiers, favourite/archive state, pages, OCR and protection, and disappears from Trash

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
- **THEN** the payload, document/folder records, pages, OCR, derived caches and protected-document passwords are removed and the entry disappears from Trash

#### Scenario: Permanent removal warning
- **WHEN** the permanent-removal dialog is shown
- **THEN** it names the item, states “This cannot be undone,” and exposes Cancel and a destructive confirmation with semantics “Delete <name> permanently”

#### Scenario: Empty Trash
- **WHEN** the user activates `Key('trash_empty_button')` with semantics “Empty Trash” and confirms
- **THEN** every Trash entry is permanently removed and the screen displays its empty state

#### Scenario: Partial empty failure
- **WHEN** permanent removal fails part-way through Empty Trash
- **THEN** processing stops, unprocessed entries remain listed and retryable, and already removed entries do not reappear

### Requirement: Trash presentation and navigation
Trash SHALL be reachable from the dashboard Collections section, use a typed route, and present accessible loading, empty, error, ready and mutating states on phone and tablet in light and dark themes.

#### Scenario: Open Trash
- **WHEN** the user activates `Key('dashboard_trash_collection')` with semantics “Open Trash”
- **THEN** typed navigation opens the screen with `Key('trash_screen')`

#### Scenario: Trash list
- **WHEN** recoverable entries exist
- **THEN** `Key('trash_list')` lists them newest first with name, kind, deletion date, expiry message, counts and restore/permanent-delete actions

#### Scenario: Empty and error states
- **WHEN** no entries exist
- **THEN** `Key('trash_empty_state')` explains that deleted items are kept for up to 30 days
- **AND WHEN** loading fails
- **THEN** `Key('trash_error_view')` presents a human-readable message and `Key('trash_retry_button')`

#### Scenario: Accessibility and scaling
- **WHEN** a screen reader or maximum supported text scale is active
- **THEN** every Trash control announces the item and outcome, targets are at least 48dp, and all content remains visible or scrollable without overflow

#### Scenario: Preview coverage
- **WHEN** widget previews are run
- **THEN** Trash screen/widget previews cover loading, empty, error, default, long content, near-expiry, phone, tablet, light and dark states using deterministic fixtures

### Requirement: Trash storage accounting and cleanup
Recoverable Trash SHALL continue to count toward local storage usage until permanent removal, and expiry cleanup SHALL be deterministic, idempotent and best-effort on startup and resume.

#### Scenario: Move and restore preserve usage
- **WHEN** an entry moves to Trash or is restored
- **THEN** the dashboard storage total does not decrease

#### Scenario: Purge decreases usage
- **WHEN** an entry is permanently removed
- **THEN** the storage summary decreases by the removed payload bytes after refresh

#### Scenario: Cleanup runs safely
- **WHEN** startup or resume invokes expiry cleanup more than once
- **THEN** expired entries are removed once, younger entries remain, and repeated invocation succeeds without hidden mutable state or duplicate effects

#### Scenario: Organise journey coverage
- **WHEN** `integration_test/flows/organise_test.dart` runs
- **THEN** it creates nested content, moves it to Trash, verifies active exclusion, restores it, moves it again, permanently removes it, and drives only registered keys/semantics through the real application composition

