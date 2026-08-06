## MODIFIED Requirements

### Requirement: Folder management
The application SHALL allow the user to create, rename and move folders inside the library folder to recoverable Trash, move documents between them, and see the recursive document count for each folder. Folders SHALL be real directories in the library folder and SHALL be visible to the operating system's file browser while active.

#### Scenario: Create a folder
- **WHEN** the user creates a folder with a non-empty name via the control with key `dashboard_create_folder_button`
- **THEN** a directory of that name is created inside the currently open folder, it appears in the dashboard with a document count of zero, and it is visible in the operating system's file browser

#### Scenario: Nested folders
- **WHEN** the user creates a folder inside a folder
- **THEN** the nested directory is created inside the parent directory and both are browsable in the dashboard and in the file browser

#### Scenario: Duplicate folder name rejected
- **WHEN** the user attempts to create a folder with a name that already exists in the same parent
- **THEN** the creation is refused with a validation message

#### Scenario: Invalid folder name rejected
- **WHEN** the folder name contains a path separator or would resolve outside the library folder
- **THEN** the creation is refused with a validation message and nothing is written

#### Scenario: Rename a folder
- **WHEN** the user selects Rename from `Key('dashboard_folder_menu_<path-token>')` with semantics “Actions for <folder>” and confirms a valid name
- **THEN** the directory is renamed, the documents it contains keep their contents, and every affected document's recorded path is updated in the same operation

#### Scenario: Delete a folder containing documents
- **WHEN** the user selects Move to Trash from the dashboard folder action menu and confirms the recursive inventory
- **THEN** the complete folder subtree becomes one recoverable Trash entry and no child is silently lost

#### Scenario: Document counts
- **WHEN** the dashboard lists folders
- **THEN** each folder shows the number of non-archived, non-trashed documents it contains recursively, and the count updates when documents move, enter Trash or are restored

#### Scenario: Folders outside the library are not reachable
- **WHEN** the user browses folders in the application
- **THEN** only the library folder and its active descendants are reachable

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
- **THEN** its payload is removed along with thumbnails, pages, recognised text and credentials

#### Scenario: Delete removes the file
- **WHEN** the user permanently deletes a document from Trash
- **THEN** the file is removed from the reserved payload, along with its thumbnails and recognised text

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
- **THEN** the record, PDF payload, page records, derived images, recognised text and password are deleted, and storage usage decreases accordingly

#### Scenario: Destructive actions require confirmation
- **WHEN** the user initiates moving non-empty content to Trash, Empty Trash or permanent removal
- **THEN** a confirmation names the affected content and recovery consequence before the operation proceeds
