## MODIFIED Requirements

### Requirement: Favourites
The application SHALL allow a document to be marked and unmarked as a favourite from Viewer and Detail, and SHALL provide a favourites view.

#### Scenario: Marking a favourite from Viewer
- **WHEN** the user activates `Key('viewer_favourite_button')` with semantics `Add <title> to favourites`
- **THEN** the document's favourite status is persisted, the control becomes a filled star with semantics `Remove <title> from favourites`, and the PDF remains on the current page

#### Scenario: Removing a favourite from Viewer
- **WHEN** the user activates `Key('viewer_favourite_button')` with semantics `Remove <title> from favourites`
- **THEN** the favourite status is removed persistently, the control becomes an outlined star with add semantics, and the PDF remains on the current page

#### Scenario: Marking a favourite from Detail
- **WHEN** the user activates `Key('document_favourite_toggle')`
- **THEN** the document's favourite status is toggled, persists across launches, and the control reflects the new state to screen readers

#### Scenario: Favourite mutation failure
- **WHEN** a favourite mutation fails
- **THEN** the previous persisted state and icon remain in effect, a human-readable nonfatal message is presented, and the readable document stays open

#### Scenario: Favourites view
- **WHEN** the user opens the favourites view
- **THEN** exactly the documents marked as favourite and not archived are listed

### Requirement: Document detail reading and page previews
The document detail screen SHALL present document metadata, favourite status, and lifecycle actions without presenting a redundant reading action or enumerating, rasterizing, or caching document-page previews.

#### Scenario: Metadata-focused Detail
- **WHEN** an active document Detail screen with `Key('document_detail_screen')` is ready
- **THEN** it displays title, creation date, modified date, page count, file size, folder/cloud status where applicable, `Key('document_favourite_toggle')`, and the lifecycle overflow actions

#### Scenario: Detail has no redundant Open action
- **WHEN** Detail is opened from Viewer or through a deep link
- **THEN** no `Key('document_open_button')` is present because document reading is owned by Viewer

#### Scenario: Detail performs no page-preview work
- **WHEN** Detail opens a document containing one page or hundreds of pages
- **THEN** it does not enumerate page handles, call page materialisation, build a page strip, or create any `page_thumbnail_<page-id>` cache entry

#### Scenario: Compact long title
- **WHEN** Detail displays a long document title on a phone or at a supported large text scale
- **THEN** the app-bar and body title use compact bounded typography, expose the complete title to semantics, and do not clip or displace favourite or lifecycle actions

#### Scenario: Detail lifecycle actions remain available
- **WHEN** the user opens `Key('document_detail_menu')`
- **THEN** Rename, Move to folder, Duplicate, Archive/Restore, and Move to Trash remain reachable through their existing stable keys and semantics

#### Scenario: Detail presentation variants
- **WHEN** Detail is displayed offline in light or dark mode on a phone or tablet
- **THEN** metadata and actions remain readable, unclipped, accessible, and require no network request for locally available content

#### Scenario: End-to-end Details coverage
- **WHEN** the `organise` end-to-end flow opens `Key('viewer_document_details_button')`
- **THEN** it reaches `document_detail_screen`, observes metadata without a page strip, completes the requested lifecycle action, and returns deterministically

