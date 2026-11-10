# Spec Delta

## MODIFIED Requirements

### Requirement: Documents are addressed by library path
Every library and Trash operation SHALL act on the file identified by its library-relative active or reserved payload path, so that active lists, Trash manifests and storage contents cannot disagree.

#### Scenario: Rename moves the file
- **WHEN** the user renames a document in the application
- **THEN** the file in the library folder is renamed to match

#### Scenario: Move to Trash hides the public file
- **WHEN** the user moves a document to Trash
- **THEN** its bytes move to the reserved payload path, its original path is retained in the Trash manifest, and it no longer appears in active public-folder browsing

#### Scenario: Permanent removal deletes all data
- **WHEN** the user permanently deletes a Trash entry
- **THEN** its payload is removed along with thumbnails, pages and credentials

#### Scenario: Delete removes the file
- **WHEN** the user permanently deletes a document from Trash
- **THEN** the file is removed from the reserved payload, along with its thumbnails

#### Scenario: Duplicate creates a second file
- **WHEN** the user duplicates a document
- **THEN** a second file is created in the same folder with a distinct name, and both are listed

#### Scenario: Archive does not hide the file
- **WHEN** the user archives a document
- **THEN** the document is excluded from the main lists but its file remains in the folder where the user put it and no Trash entry is created

### Requirement: Document lifecycle operations
The application SHALL allow the user to rename, move, duplicate, archive, restore from Archive, move to Trash, restore from Trash and permanently remove documents.

#### Scenario: Rename
- **WHEN** the user renames a document via the control with key `document_rename_button` and confirms a non-empty name
- **THEN** the title is updated in the library and the modified date is updated

#### Scenario: Empty name rejected
- **WHEN** the user attempts to confirm an empty or whitespace-only name
- **THEN** the confirmation is refused with a validation message and the existing title is retained

#### Scenario: Move to a folder
- **WHEN** the user moves a document to a folder via the control with key `document_move_button`
- **THEN** the document's folder assignment changes, it appears in the destination folder, and the document counts of both folders update

#### Scenario: Duplicate
- **WHEN** the user duplicates a document
- **THEN** a new independent document is created with its own identifier, its own copy of the file, and a distinguishable title

#### Scenario: Archive
- **WHEN** the user archives a document via the control with key `document_archive_button`
- **THEN** the document is excluded from recent documents and the main document list, and appears in the archive

#### Scenario: Restore
- **WHEN** the user restores an archived document via the control with key `document_restore_button`
- **THEN** the document returns to active lists at its unchanged public path

#### Scenario: Delete
- **WHEN** the user deletes a document through `Key('document_move_to_trash_button')`
- **THEN** the document is excluded from active and Archive views and is recoverable from Trash for up to 30 days

#### Scenario: Restore from Trash
- **WHEN** the user restores a trashed document
- **THEN** its identity, metadata, content and protection return at a collision-safe active path

#### Scenario: Permanent removal
- **WHEN** the user permanently removes a document from Trash and confirms in the dialog with key `trash_permanent_delete_dialog`
- **THEN** the record, PDF payload, page records, derived images and password are deleted, and storage usage decreases accordingly

#### Scenario: Destructive actions require confirmation
- **WHEN** the user initiates moving non-empty content to Trash, Empty Trash or permanent removal
- **THEN** a confirmation names the affected content and recovery consequence before the operation proceeds

### Requirement: Cloud-backed library entries
On iOS with iCloud selected, the library SHALL distinguish remote-only, downloading, locally available, and failed cloud content without treating an undownloaded payload as a missing document.

#### Scenario: Remote-only entry remains actionable
- **WHEN** a reconciled PDF is remote-only
- **THEN** its document row remains navigable and exposes `document_cloud_status_<document-id>` with the current availability

#### Scenario: Byte-reading operation waits for download
- **WHEN** a thumbnail, viewer, editor, share, or print operation needs a remote-only PDF
- **THEN** the operation invokes the injected download use case, reports bounded progress, and reads bytes only after the platform confirms availability

#### Scenario: Password-protected PDF on a new device
- **WHEN** a protected PDF is discovered but its password is absent from that device's secure storage
- **THEN** the PDF remains visible and prompts for its password when opened rather than synchronizing or fabricating a credential

#### Scenario: Device-local metadata limitation
- **WHEN** a PDF is first discovered on another device
- **THEN** DocScanly reconstructs metadata available from the folder and PDF but does not claim that unsynchronized favourites, archive state, or custom ordering transferred
