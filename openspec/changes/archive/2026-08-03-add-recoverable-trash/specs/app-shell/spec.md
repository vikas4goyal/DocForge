## MODIFIED Requirements

### Requirement: Home screen composition
The Dashboard SHALL be the application's primary destination and SHALL display search, the currently open folder, storage usage, a root Collections section, and actions to create a folder, import a PDF and create a PDF.

#### Scenario: Dashboard displays all sections
- **WHEN** the dashboard root is displayed and at least one document exists
- **THEN** the search control (`dashboard_search_field`), folder/document list (`dashboard_content_list`), storage summary (`dashboard_storage_summary`), Collections section (`dashboard_collections`), create-folder action (`dashboard_create_folder_button`) and import-PDF action (`dashboard_import_pdf_button`) are present

#### Scenario: Collections are discoverable
- **WHEN** the dashboard root is displayed
- **THEN** Favourites, Archive and Trash are reachable through `Key('dashboard_favourites_collection')`, `Key('dashboard_archive_collection')` and `Key('dashboard_trash_collection')` with semantics “Open Favourites,” “Open Archive” and “Open Trash”

#### Scenario: Recent documents ordering
- **WHEN** the dashboard shows the root of the library
- **THEN** recent documents are ordered by modified date descending and archived or trashed documents are excluded

#### Scenario: Newly saved document appears
- **WHEN** a document is saved and the user returns to the dashboard
- **THEN** that document appears in its folder and at the top of recents without an app restart

#### Scenario: Folder contents shown
- **WHEN** the user opens a folder
- **THEN** child folders and active PDFs are listed, and `dashboard_breadcrumb` shows the path from the library root

#### Scenario: Folder actions are discoverable
- **WHEN** a dashboard folder row is displayed
- **THEN** tapping the row opens it and its keyed action menu provides Rename and Move to Trash without relying on a separate legacy folder screen

#### Scenario: Only application folders are browsable
- **WHEN** the user browses the dashboard
- **THEN** only active folders inside the application's library are reachable and the reserved Trash payload namespace is never listed

### Requirement: Storage summary
The Dashboard SHALL display total storage consumed by active and recoverable Trash payloads and SHALL update after additions or permanent removal.

#### Scenario: Storage summary displayed
- **WHEN** the dashboard loads
- **THEN** the summary shows total stored bytes in a human-readable unit and exposes a semantics label stating the value

#### Scenario: Moving to Trash does not free storage
- **WHEN** an item moves to Trash or is restored
- **THEN** the storage summary remains unchanged after refresh

#### Scenario: Storage summary updates after purge
- **WHEN** an item is permanently removed or expires and the dashboard refreshes
- **THEN** the storage summary reflects the reduced usage

#### Scenario: Storage summary updates
- **WHEN** a document is permanently removed and the user returns to the dashboard
- **THEN** the storage summary reflects the reduced usage

#### Scenario: Storage summary is not the route to settings
- **WHEN** the user wants to reach settings
- **THEN** the settings tab is available without interacting with the storage summary
