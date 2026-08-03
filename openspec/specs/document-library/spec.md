# document-library Specification

## Purpose

Define the library: what a document record carries, how folders are managed as real directories in the library folder, how external PDFs are brought in by copying, the lifecycle operations and favourites the user can apply to a document, how document lists present themselves, and the rule that every library operation acts on the file identified by the document's library-relative path so that the index and the folder contents can never disagree.
## Requirements
### Requirement: Document record
Every document SHALL carry a title, creation date, modified date, number of pages, file size, folder path relative to the library root, favourite status, archive status and whether it is password protected.

#### Scenario: Record created on save
- **WHEN** a document is saved
- **THEN** its record contains a title, creation date, modified date, page count, file size, the folder path relative to the library root, favourite status, archive status and protection status

#### Scenario: No absolute path persisted
- **WHEN** a document record is written
- **THEN** it stores a folder-relative path and a file name, and no absolute device path

#### Scenario: Modified date maintained
- **WHEN** any operation changes a document's content or metadata
- **THEN** its modified date is updated and its creation date is unchanged

#### Scenario: Metadata displayed
- **WHEN** the document detail screen with key `document_detail_screen` is displayed
- **THEN** the title, creation date, modified date, page count, file size and folder path are all shown

#### Scenario: Title follows the file name
- **WHEN** a document's file is renamed inside or outside the application
- **THEN** the document's title matches the file name

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

### Requirement: Importing an external PDF into the library
The application SHALL allow the user to bring a PDF from anywhere on the device into the library by copying it into the currently open folder, and SHALL NOT modify any file outside the library folder.

#### Scenario: Import action present
- **WHEN** the dashboard is displayed
- **THEN** an import-PDF action with key `dashboard_import_pdf_button` is present

#### Scenario: Import copies into the open folder
- **WHEN** the user chooses a PDF from the system file picker while a folder is open
- **THEN** the file is copied into that folder, a document record is created with the correct page count and file size, and the document appears in the list

#### Scenario: Source is left untouched
- **WHEN** a PDF has been imported
- **THEN** the file the user selected is unchanged and is not deleted

#### Scenario: Imported document is editable
- **WHEN** the user opens an imported document
- **THEN** it can be viewed, edited, shared and deleted exactly like a document the application created

#### Scenario: Opened from another application
- **WHEN** another application sends a PDF to DocForge through the share sheet or an "Open in" action
- **THEN** the file is copied into the library using the same import path and is then opened

#### Scenario: Name collision on import
- **WHEN** the imported file's name matches a document already in the target folder
- **THEN** the user is asked whether to replace it or keep both, and nothing is overwritten without that confirmation

#### Scenario: Password-protected import
- **WHEN** the imported PDF is password protected
- **THEN** the import succeeds, the document is marked as protected, and the password is requested when it is opened

#### Scenario: Import failure
- **WHEN** the file cannot be read or is not a valid PDF
- **THEN** an error message explains what went wrong, nothing is added to the library, and no partial file is left in the folder

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

### Requirement: Favourites
The application SHALL allow a document to be marked and unmarked as a favourite, and SHALL provide a favourites view.

#### Scenario: Marking a favourite
- **WHEN** the user activates the control with key `document_favourite_toggle`
- **THEN** the document's favourite status is toggled, persists across launches, and the control reflects the new state to screen readers

#### Scenario: Favourites view
- **WHEN** the user opens the favourites view
- **THEN** exactly the documents marked as favourite and not archived are listed

### Requirement: Document list presentation
Document lists SHALL present a loading state, an empty state and an error state with a retry action, SHALL load large libraries lazily, and SHALL show bounded first-page previews for visible document rows.

#### Scenario: Empty list
- **WHEN** a document list has no documents to show
- **THEN** an empty state with key `document_list_empty_state` is displayed with guidance appropriate to the list

#### Scenario: Loading state
- **WHEN** a document list is loading
- **THEN** a loading indicator with key `document_list_loading` is displayed

#### Scenario: Error and retry
- **WHEN** a document list fails to load
- **THEN** an error view with key `document_list_error_view` is displayed with a retry control that reloads the list

#### Scenario: Visible document thumbnail
- **WHEN** a document row becomes visible and its cached first-page preview is absent
- **THEN** the application lazily renders page 1 at thumbnail resolution, caches it privately, and displays it with key `document_thumbnail_<document-id>` and semantics label “<title> preview”

#### Scenario: Thumbnail loading or failure
- **WHEN** a first-page preview is loading or cannot be rendered from a missing, corrupt, protected-without-password, or unreadable PDF
- **THEN** the row remains usable and shows a bounded loading state or stable PDF placeholder without crashing

#### Scenario: Protected list thumbnail
- **WHEN** a protected document has a valid password stored for its document identifier
- **THEN** thumbnail rendering reads that password from secure storage without persisting or displaying it elsewhere

#### Scenario: Large library performance
- **WHEN** the library contains several thousand documents
- **THEN** the list loads incrementally, requests thumbnails only for lazily built rows near the visible viewport, scrolls smoothly, and does not retain full-resolution page images

### Requirement: Compact dashboard discovery
The library dashboard SHALL present quick access and recent documents without permanently reducing the document-list viewport.

#### Scenario: One-row Recent lane
- **WHEN** the root dashboard has recently modified documents
- **THEN** at most five documents appear in exactly one non-wrapping horizontal lane with key `dashboard_recents`

#### Scenario: Compact Recent document
- **WHEN** a Recent document tile with key `dashboard_recent_<document-id>` is visible
- **THEN** it presents a small first-page thumbnail beside an ellipsized title and exposes the document metadata as button semantics

#### Scenario: Dashboard content scrolls together
- **WHEN** the root dashboard content exceeds the available phone or tablet viewport
- **THEN** search, collections, Recent, folders, documents, and storage content participate in one vertical scroll surface so the library can reclaim the viewport

#### Scenario: Root breadcrumb is omitted
- **WHEN** the dashboard displays the library root
- **THEN** `dashboard_breadcrumb` is absent because the `DocForge` app-bar title already identifies the location

#### Scenario: Nested breadcrumb remains available
- **WHEN** the dashboard displays a nested folder
- **THEN** `dashboard_breadcrumb` identifies the current path and allows navigation to its ancestors

#### Scenario: Dashboard presentation variants
- **WHEN** the dashboard is used offline in light or dark mode on a phone or tablet, including at supported large text scales
- **THEN** its one-row Recent lane, collections, and content remain readable, scrollable, unclipped, and require no network access

#### Scenario: End-to-end dashboard coverage
- **WHEN** the `browse_and_view` end-to-end flow displays a saved document on the dashboard
- **THEN** it observes `document_thumbnail_<document-id>` and can open the same document through detail into `viewer_screen`

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

### Requirement: Document detail reading and page previews
The document detail screen SHALL provide a visible reading action and SHALL present locally derived, lazily loaded previews for the document's pages without retaining full-resolution source images.

#### Scenario: Open action is present
- **WHEN** an active document detail screen with key `document_detail_screen` is ready
- **THEN** a control with `Key('document_open_button')` and semantics label “Open” is visible

#### Scenario: Missing stored thumbnail is derived
- **WHEN** a page with no usable stored thumbnail becomes visible in the detail page strip
- **THEN** the application renders that page from the local PDF at thumbnail resolution, caches the derived image privately, and displays it under `Key('page_thumbnail_<page-id>')` with semantics label “Page <number> thumbnail”

#### Scenario: Preview work is lazy and bounded
- **WHEN** a document contains many pages
- **THEN** previews are requested only for the bounded set of page tiles built around the visible horizontal viewport and full-resolution page images are not retained

#### Scenario: Preview cannot be rendered
- **WHEN** a page preview cannot be rendered because the PDF is missing, corrupt, locked without a stored password, or unreadable
- **THEN** that tile displays a stable placeholder, the detail screen remains usable, and the application does not crash

#### Scenario: Protected preview
- **WHEN** a protected document has a valid password stored for its document identifier
- **THEN** preview rendering reads that password from secure storage without persisting or displaying it elsewhere

#### Scenario: Preview presentation variants
- **WHEN** the detail screen is used offline in light or dark mode on a phone or tablet
- **THEN** previews and placeholders remain readable, unclipped, and require no network access

#### Scenario: End-to-end coverage
- **WHEN** the `browse_and_view` end-to-end flow opens a newly saved PDF from the dashboard
- **THEN** it observes the detail Open action, reaches `viewer_screen`, and can return without an exception
