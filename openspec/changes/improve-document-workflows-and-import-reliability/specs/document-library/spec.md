## ADDED Requirements

### Requirement: Files-inspired adaptive library grid and search
Dashboard and open-folder browsing SHALL present folders and documents in a clean, lazy, stable-geometry grid with a rounded platform-adaptive search control. A persistent Large/Small control SHALL let the user preserve the current two-column compact layout or choose a denser three-column compact layout; wider iPad and tablet widths SHALL add columns according to the selected density, available width, and documented minimum readable tile extents. The presentation SHALL use DocScanly theme tokens and original assets while following a restrained native information hierarchy.

#### Scenario: Two-column phone grid
- **WHEN** Dashboard or an open folder is displayed at a normal compact phone width and supported standard text scale
- **THEN** `Key('dashboard_content_grid')` presents exactly two columns with consistent margins, gaps, and tile geometry

#### Scenario: Choose Small display density
- **WHEN** the user chooses Small from `Key('dashboard_display_size_menu')`
- **THEN** `Key('dashboard_content_grid')` presents three stable columns at compact phone width and proportionally more columns at wider widths, with thumbnails approximately 40–50% of Large area

#### Scenario: Choose Large display density
- **WHEN** the user chooses Large from `Key('dashboard_display_size_menu')`
- **THEN** the existing two-column compact layout is restored without changing document order, selection, or search state

#### Scenario: Display density persists
- **WHEN** the user leaves and later reopens Dashboard after choosing Small or Large
- **THEN** the chosen density is restored and both modes retain two-line names, accessible semantics, and minimum touch targets

#### Scenario: Adaptive iPad and tablet grid
- **WHEN** the same content is displayed at a wider iPad or Android tablet width, including split-view widths
- **THEN** the grid derives three or more columns when the minimum readable tile extent is satisfied and recalculates without clipping after a width change

#### Scenario: Accessibility width fallback
- **WHEN** supported large text and the available compact width cannot preserve two readable columns with minimum touch targets
- **THEN** the grid uses the documented one-column accessibility fallback, exposes complete metadata to semantics, and does not horizontally scroll or clip content

#### Scenario: Document tile hierarchy
- **WHEN** a document tile with `Key('dashboard_document_<document-id>')` is visible
- **THEN** it presents a prominent bounded portrait preview with `Key('document_thumbnail_<document-id>')`, the document name on at most two lines, modified time, then formatted file size
- **AND** its button semantics announce the complete name, page count, modified time, file size, and selection state without relying on truncated visual text

#### Scenario: Folder tile hierarchy
- **WHEN** a folder tile with `Key('dashboard_folder_<path-token>')` is visible
- **THEN** it presents a restrained folder preview or platform-appropriate folder glyph, the folder name on at most two lines, modified time, then recursive document count rather than a misleading byte size
- **AND** its button semantics announce the complete folder name, modified time, and document count

#### Scenario: Long names preserve grid rhythm
- **WHEN** folder or document names exceed two visual lines
- **THEN** visual text is ellipsized after the second line, the full name remains available to semantics, and neighboring tiles retain aligned metadata and stable height

#### Scenario: Rounded search control
- **WHEN** Dashboard or an open folder is displayed
- **THEN** `Key('dashboard_search_field')` is a rounded platform-adaptive search control with semantics label “Search documents and folders”, a search keyboard action, and native-feeling focus treatment

#### Scenario: Clear and dismiss search
- **WHEN** the search query is non-empty
- **THEN** `Key('dashboard_search_clear')` with semantics label “Clear search” is reachable and clears the query without leaving stale results
- **AND** any platform-appropriate cancel or dismiss action closes the keyboard without discarding library content

#### Scenario: Search results use the same grid
- **WHEN** a query returns matching folders or documents
- **THEN** results appear in `Key('dashboard_content_grid')` with the same tile hierarchy, adaptive columns, lazy previews, navigation, and selection behavior

#### Scenario: Search has no matches
- **WHEN** a non-empty query returns no results
- **THEN** `Key('document_list_empty_state')` identifies the query in accessible text and the clear-search action remains available

#### Scenario: Selection does not reflow tiles
- **WHEN** document selection mode begins or a tile's selected state changes
- **THEN** the grid column count, tile size, title position, and metadata position remain unchanged while an accessible selected indicator and subtle theme-colour treatment appear

#### Scenario: Lazy thumbnail grid performance
- **WHEN** a folder contains thousands of documents and the user scrolls quickly
- **THEN** the lazy grid builds visible and near-visible tiles only, requests bounded thumbnails for those tiles, cancels or ignores obsolete work, uses stable lightweight placeholders, and does not retain full-resolution page images

#### Scenario: Grid presentation variants
- **WHEN** Dashboard and folder grids are used offline in light or dark mode on iPhone, iPad, Android phone, or Android tablet with long names and supported text scales
- **THEN** search, previews, titles, metadata, selection, empty/loading/error states, and touch targets remain readable, accessible, unclipped, and require no network request

#### Scenario: End-to-end grid and search coverage
- **WHEN** the `browse_and_view` and `organise` end-to-end flows browse seeded folders and documents on compact and wide fixtures
- **THEN** they observe the specified column behavior, search by `dashboard_search_field`, open a matching tile, and select multiple documents without tile reflow exclusively through keys and semantics

### Requirement: Bulk document selection and lifecycle actions
Dashboard and open-folder document lists SHALL allow document-only multi-selection through long press or an explicit Select control, and SHALL provide Select all, Archive, and confirmed Move to Trash actions with deterministic per-document outcomes.

#### Scenario: Enter selection with the Select control
- **WHEN** the user activates `Key('dashboard_select_button')` with semantics label “Select documents” on Dashboard or an open folder
- **THEN** selection mode starts, `Key('dashboard_selection_toolbar')` is visible, and no document is selected initially

#### Scenario: Enter selection by long press
- **WHEN** the user long-presses a document row
- **THEN** selection mode starts, that document is selected, and its semantics announce “<title>, selected”

#### Scenario: Folder remains a navigation target
- **WHEN** selection mode is active and folders are visible
- **THEN** folders are not included by `Key('dashboard_select_all')`, and a folder cannot be added to the document selection set

#### Scenario: Select all visible documents
- **WHEN** the user activates `Key('dashboard_select_all')` with semantics label “Select all documents”
- **THEN** every eligible document in the current Dashboard or folder view is selected and the toolbar announces the selected count

#### Scenario: Bulk archive
- **WHEN** the user activates `Key('dashboard_bulk_archive')` with semantics label “Archive selected documents”
- **THEN** the action submits once, shows bounded progress, archives each selected document in deterministic list order, and removes successful documents from the active list

#### Scenario: Bulk trash confirmation
- **WHEN** the user activates `Key('dashboard_bulk_trash')` with semantics label “Move selected documents to Trash”
- **THEN** `Key('dashboard_bulk_trash_confirm')` names the selected count and recovery consequence before any document is moved

#### Scenario: Partial bulk failure
- **WHEN** a bulk action succeeds for some selected documents and fails for others
- **THEN** successful documents reflect the new lifecycle state, failed documents remain selected, and a visible summary reports succeeded and failed counts with a retry action

#### Scenario: Repeated bulk submission is prevented
- **WHEN** a bulk archive or Trash action is running
- **THEN** all bulk submit controls are disabled and repeated taps do not start another mutation

#### Scenario: Exit selection
- **WHEN** the user activates `Key('dashboard_selection_cancel')` with semantics label “Cancel selection”
- **THEN** selection mode ends, the selection is cleared, and no lifecycle action occurs

#### Scenario: Bulk selection presentation variants
- **WHEN** selection is used offline in light or dark mode on a phone or tablet at a supported large text scale
- **THEN** selected state, counts, actions, progress, and failures remain readable, reachable, unclipped, and require no network request

#### Scenario: End-to-end bulk coverage
- **WHEN** the `organise` end-to-end flow selects multiple documents in Dashboard and an open folder
- **THEN** it archives them and confirms moving them to Trash exclusively through the specified keys and visible outcomes

### Requirement: Reviewed move and duplicate workflows
Document Detail SHALL load real folder destinations and SHALL review move and duplicate inputs before mutating storage. Loading, genuine emptiness, failure, cancellation, progress, and success SHALL be distinguishable.

#### Scenario: Move picker loads current folder hierarchy
- **WHEN** the user activates `Key('document_move_button')`
- **THEN** `Key('document_move_picker')` loads Root and eligible active folders from the library, including folders created before Detail opened, and does not report “no folders” while loading

#### Scenario: Choose a move destination
- **WHEN** the user selects `Key('document_move_folder_<folder-id>')` with semantics label “Move to <folder path>” and activates `Key('document_move_confirm')`
- **THEN** the document moves once, Detail refreshes its displayed path, and the source and destination folder counts update

#### Scenario: Current destination is excluded
- **WHEN** the move picker lists destinations
- **THEN** the document's current folder is not offered as a changed destination and confirmation remains disabled until an eligible destination is selected

#### Scenario: Folder loading failure
- **WHEN** folder options cannot be loaded
- **THEN** the picker displays a labelled error and retry control instead of an empty-folder message, and no move occurs

#### Scenario: Genuine empty folder hierarchy
- **WHEN** the library contains no eligible destination other than the current location
- **THEN** the picker explains that there is no other folder and provides access to Root when Root is eligible

#### Scenario: Duplicate opens a review
- **WHEN** the user activates the Duplicate action
- **THEN** `Key('document_duplicate_dialog')` shows the source document, a collision-safe proposed copy name in `Key('document_duplicate_name')`, and the destination in `Key('document_duplicate_folder')`

#### Scenario: Confirm reviewed duplicate
- **WHEN** the user supplies a valid distinct name and eligible destination and activates `Key('document_duplicate_confirm')`
- **THEN** exactly one independent copy is created, “Created <name>” is announced, and typed navigation opens the new document with its name and destination visible

#### Scenario: Duplicate cancellation
- **WHEN** the user cancels the duplicate review
- **THEN** no file or document record is created and the original Detail screen remains unchanged

#### Scenario: Repeated duplicate confirmation is prevented
- **WHEN** duplication is submitting
- **THEN** confirmation is disabled and repeated taps cannot create additional copies or navigate more than once

#### Scenario: Reviewed workflow presentation variants
- **WHEN** move and duplicate workflows are displayed offline in light or dark mode on a phone or tablet with long names and supported large text
- **THEN** all names, destinations, validation, and actions remain readable, scrollable, accessible, and require no network request

#### Scenario: End-to-end move and duplicate coverage
- **WHEN** the `organise` end-to-end flow creates a folder, opens Detail, moves a document, and duplicates it with a changed name and destination
- **THEN** the flow observes the created folder in the move picker and exactly one clearly named duplicate at the selected destination

## MODIFIED Requirements

### Requirement: Document detail reading and page previews
The document detail screen SHALL provide a visible reading action, SHALL use compact responsive typography that preserves meaningful long-title visibility, and SHALL present locally derived, lazily loaded previews for every document page, including imported PDF pages that have no stored page-image rows, without retaining full-resolution source images.

#### Scenario: Open action is present
- **WHEN** an active document detail screen with key `document_detail_screen` is ready
- **THEN** a control with `Key('document_open_button')` and semantics label “Open” is visible

#### Scenario: Compact long title
- **WHEN** Detail displays a long document title on a phone or at a supported large text scale
- **THEN** the app-bar and body title use compact bounded typography, expose the complete title to semantics, and do not clip or displace the primary actions

#### Scenario: Missing stored thumbnail is derived
- **WHEN** a page with no usable stored thumbnail becomes visible in the detail page strip
- **THEN** the application renders that page from the local PDF at thumbnail resolution, caches the derived image privately, and displays it under `Key('page_thumbnail_<page-id>')` with semantics label “Page <number> thumbnail”

#### Scenario: Imported PDF previews use stable page identities
- **WHEN** Detail opens an imported PDF whose dashboard thumbnail renders but that has no stored page-image rows
- **THEN** every PDF page is represented by a stable document-and-page-derived identity and visible pages render in the detail strip instead of showing “Page previews are not available”

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
- **THEN** previews, long titles, and placeholders remain readable, unclipped, and require no network access

#### Scenario: End-to-end coverage
- **WHEN** the `browse_and_view` end-to-end flow opens a newly saved or imported PDF from the dashboard
- **THEN** it observes at least one Detail page preview and the Open action, reaches `viewer_screen`, and can return without an exception
