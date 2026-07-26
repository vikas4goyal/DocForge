## ADDED Requirements

### Requirement: Document record
Every document SHALL carry a title, creation date, modified date, number of pages, file size, folder, favourite status and archive status.

#### Scenario: Record created on save
- **WHEN** a document is saved
- **THEN** its record contains a title, creation date, modified date, page count, file size, folder assignment, favourite status and archive status

#### Scenario: Modified date maintained
- **WHEN** any operation changes a document's content or metadata
- **THEN** its modified date is updated and its creation date is unchanged

#### Scenario: Metadata displayed
- **WHEN** the document detail screen with key `document_detail_screen` is displayed
- **THEN** the title, creation date, modified date, page count and file size are all shown

### Requirement: Document lifecycle operations
The application SHALL allow the user to rename, move, duplicate, archive, restore, delete and permanently remove documents.

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
- **THEN** the document returns to its previous folder and reappears in the main document list

#### Scenario: Delete
- **WHEN** the user deletes a document
- **THEN** the document is removed from the main list and is recoverable until it is permanently removed

#### Scenario: Permanent removal
- **WHEN** the user permanently removes a document and confirms in the dialog with key `document_delete_confirm_dialog`
- **THEN** the record, the PDF file, all page images and all recognised text for that document are deleted from storage, and the storage summary decreases accordingly

#### Scenario: Destructive actions require confirmation
- **WHEN** the user initiates deletion or permanent removal
- **THEN** a confirmation is required before the operation proceeds

### Requirement: Favourites
The application SHALL allow a document to be marked and unmarked as a favourite, and SHALL provide a favourites view.

#### Scenario: Marking a favourite
- **WHEN** the user activates the control with key `document_favourite_toggle`
- **THEN** the document's favourite status is toggled, persists across launches, and the control reflects the new state to screen readers

#### Scenario: Favourites view
- **WHEN** the user opens the favourites view
- **THEN** exactly the documents marked as favourite and not archived are listed

### Requirement: Folder management
The application SHALL allow the user to create, rename and delete folders, move documents between folders, and see the document count for each folder.

#### Scenario: Create a folder
- **WHEN** the user creates a folder with a non-empty name via the control with key `folder_create_button`
- **THEN** the folder appears in the folder list with a document count of zero

#### Scenario: Duplicate folder name rejected
- **WHEN** the user attempts to create a folder with a name that already exists
- **THEN** the creation is refused with a validation message

#### Scenario: Rename a folder
- **WHEN** the user renames a folder
- **THEN** the new name appears everywhere the folder is shown and the documents it contains are unaffected

#### Scenario: Delete a folder containing documents
- **WHEN** the user deletes a folder that contains documents
- **THEN** the user is asked whether to move the documents out or delete them, and no document is silently lost

#### Scenario: Document counts
- **WHEN** the folder list with key `folder_list_screen` is displayed
- **THEN** each folder shows the number of non-archived documents it contains, and the count updates when documents are moved in or out

### Requirement: Document list presentation
Document lists SHALL present a loading state, an empty state and an error state with a retry action, and SHALL load large libraries lazily.

#### Scenario: Empty list
- **WHEN** a document list has no documents to show
- **THEN** an empty state with key `document_list_empty_state` is displayed with guidance appropriate to the list

#### Scenario: Loading state
- **WHEN** a document list is loading
- **THEN** a loading indicator with key `document_list_loading` is displayed

#### Scenario: Error and retry
- **WHEN** a document list fails to load
- **THEN** an error view with key `document_list_error_view` is displayed with a retry control that reloads the list

#### Scenario: Large library performance
- **WHEN** the library contains several thousand documents
- **THEN** the list loads incrementally, scrolls smoothly, and does not load full-resolution page images for list rows

### Requirement: Library accessibility, theming, layout and offline behaviour
Library and folder screens SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on a document row
- **WHEN** a screen reader traverses a document row with key `document_list_item`
- **THEN** it announces the document title, page count, modified date and favourite status, and each action control exposes a descriptive label

#### Scenario: Dark mode and tablet list
- **WHEN** a document list is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and presents a multi-column layout without clipping or overflow

#### Scenario: Library offline
- **WHEN** the device has no network connection
- **THEN** every library and folder operation completes successfully against local storage with no network request
