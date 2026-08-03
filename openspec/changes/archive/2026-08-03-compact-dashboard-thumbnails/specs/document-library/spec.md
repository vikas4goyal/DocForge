## ADDED Requirements

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

## MODIFIED Requirements

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
