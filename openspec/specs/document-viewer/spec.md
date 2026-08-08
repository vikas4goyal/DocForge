# document-viewer Specification

## Purpose

Define reading a saved document: rendering its PDF, zooming and scrolling through pages, jumping to a page, reaching share, print and the editing tools, and prompting for a password before any protected content is rendered.

## Requirements

### Requirement: PDF viewing
The application SHALL render a selected stored document directly in Viewer without requiring Detail as an intermediary, and SHALL keep Detail reachable as a secondary metadata action.

#### Scenario: Selecting a document
- **WHEN** the user selects a document from Dashboard, Recent, Documents, a folder, search, favourites, or archive
- **THEN** the typed route for that document opens `Key('viewer_screen')` and renders its first page without first displaying `document_detail_screen`

#### Scenario: Opening after creation or derivation
- **WHEN** creation, import, duplication, split, merge, compression, watermark, protection, or page management produces a document that should be opened
- **THEN** exactly one Viewer route for the resulting document opens through its typed identifier

#### Scenario: Page indicator
- **WHEN** a document is open in Viewer
- **THEN** an indicator with `Key('viewer_page_indicator')` shows the current page number and total page count

#### Scenario: Open document details
- **WHEN** the user activates `Key('viewer_document_details_button')` with semantics `Show document details`
- **THEN** the typed Detail route for the same document opens over Viewer with `Key('document_detail_screen')`

#### Scenario: End-to-end coverage
- **WHEN** the `browse_and_view` end-to-end flow selects a saved document
- **THEN** it reaches `viewer_screen` directly, reads the document, and returns to the originating library surface without traversing Detail

### Requirement: Zoom and continuous scroll
The viewer SHALL support zooming and continuous scrolling through pages.

#### Scenario: Zoom
- **WHEN** the user performs a pinch gesture on the page view
- **THEN** the page scales between the supported minimum and maximum zoom levels and the rendering stays legible at the current zoom

#### Scenario: Continuous scroll
- **WHEN** the user scrolls the viewer
- **THEN** pages scroll continuously and the page indicator updates to the page currently in view

#### Scenario: Zoom is reset appropriately
- **WHEN** the user double-taps the page view while zoomed in
- **THEN** the zoom returns to fit-to-width

### Requirement: Jump to page
The viewer SHALL present page position as a compact, clearly labelled control and SHALL request numeric input only after the user explicitly opens a bounded jump-to-page dialog.

#### Scenario: Compact page navigation control
- **WHEN** a document is open in the viewer
- **THEN** `Key('viewer_page_jump_button')` displays “Page <current> of <total>” and exposes semantics “Page <current> of <total>, jump to page” without showing an always-editable text field

#### Scenario: Open jump dialog
- **WHEN** the user activates `Key('viewer_page_jump_button')`
- **THEN** `Key('viewer_page_jump_dialog')` opens, `Key('viewer_page_jump_field')` accepts numeric input, and only that explicit action requests the keyboard

#### Scenario: Jumping to a page
- **WHEN** the user enters a valid page number and activates `Key('viewer_page_jump_confirm')` with semantics label “Go to page”
- **THEN** the dialog closes, the viewer scrolls to that page, and the page indicator updates

#### Scenario: Out-of-range page number
- **WHEN** the user enters a page number outside the document's range
- **THEN** the dialog remains open with a validation message and the current page is unchanged

#### Scenario: Cancel page jump
- **WHEN** the user cancels the jump dialog
- **THEN** the dialog closes, the keyboard is dismissed, and the current page is unchanged

### Requirement: Viewer actions
The viewer SHALL provide responsive access to favourite, share, Details, print, and focused PDF operations while preserving meaningful title space. On constrained widths, Details, Print, Compress, Split, Watermark, Set/Remove Password, and any page-management entry SHALL be placed in the adaptive overflow rather than requiring a generic editor hub or rendering inert or clipped buttons.

#### Scenario: Long viewer title
- **WHEN** Viewer displays a long title on a constrained phone width
- **THEN** the app bar shows a one-line ellipsized title, exposes the complete title to semantics, and `Key('viewer_favourite_button')`, `Key('viewer_share_button')`, and `Key('viewer_actions_menu')` remain reachable without overlap

#### Scenario: Favourite from Viewer
- **WHEN** a readable document is open
- **THEN** `Key('viewer_favourite_button')` displays a filled star when favourite and an outlined star otherwise, with add/remove semantics naming the document

#### Scenario: Share from the viewer
- **WHEN** the user activates `Key('viewer_share_button')`, directly or through `Key('viewer_actions_menu')`
- **THEN** the share flow for the open document is started

#### Scenario: Show Details
- **WHEN** the user opens `Key('viewer_actions_menu')`
- **THEN** `Key('viewer_document_details_button')` with semantics `Show document details` is available

#### Scenario: Print from the viewer
- **WHEN** the user activates `Key('viewer_print_button')` through `Key('viewer_actions_menu')`
- **THEN** the system print flow for the open document is started

#### Scenario: Open a focused PDF operation
- **WHEN** the user chooses Print, Compress, Split, Watermark, or Set/Remove Password from `Key('viewer_actions_menu')`
- **THEN** that operation's focused sheet or screen opens directly with Cancel and Done/Confirm behavior and no generic editor hub is shown first

#### Scenario: Open page management when required
- **WHEN** the user chooses an operation that genuinely requires page thumbnail selection or ordering
- **THEN** the page-management editor opens with only applicable contextual actions and generates previews on demand

#### Scenario: No inert viewer action
- **WHEN** an action cannot be offered for the open document
- **THEN** it is absent or presents a human-readable reason, and no visible action silently ignores activation

### Requirement: Protected document handling
The viewer SHALL prompt for a password when opening a password-protected document and SHALL not render its contents until the correct password is supplied.

#### Scenario: Correct password
- **WHEN** the user enters the correct password in the field with key `viewer_password_field`
- **THEN** the document is rendered

#### Scenario: Incorrect password
- **WHEN** the user enters an incorrect password
- **THEN** an error message is displayed, the document contents are not rendered, and the user can retry

### Requirement: Viewer performance
The viewer SHALL open documents quickly, support large documents without exhausting memory, and avoid document-wide thumbnail generation during ordinary reading.

#### Scenario: Large document
- **WHEN** a document with hundreds of pages is opened
- **THEN** PDF pages are rendered on demand rather than all at once, scrolling remains smooth, memory use stays bounded, and no Detail page-preview list is loaded

#### Scenario: Open latency
- **WHEN** a document is opened from a library surface
- **THEN** the first page is rendered promptly, with `Key('viewer_loading_indicator')` shown while rendering is in progress and without waiting for page-handle enumeration

#### Scenario: Favourite does not rebuild the page surface
- **WHEN** favourite status changes while page N is visible
- **THEN** only Viewer chrome/state is updated and the current PDF page and zoom surface remain in place

### Requirement: Viewer error handling
The viewer SHALL present a clear message and a recovery action when a document cannot be rendered.

#### Scenario: Corrupt or missing file
- **WHEN** the document file is missing or cannot be parsed
- **THEN** an error view with key `viewer_error_view` is displayed with a human-readable message and a control to return to the previous screen, and the application does not crash

### Requirement: Viewer accessibility, theming, layout and offline behaviour
The viewer SHALL support screen readers, supported large text scales, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader in the viewer
- **WHEN** a screen reader traverses Viewer
- **THEN** the full document title and page position are announced, and favourite, share, Details, print, focused-operation, actions-menu, and jump-to-page controls each expose a descriptive semantics label

#### Scenario: Large text on a phone
- **WHEN** Viewer is displayed at a supported large text scale on a phone
- **THEN** title, favourite, share, overflow actions, and page navigation remain reachable and unclipped, and page content keeps the remaining usable viewport

#### Scenario: Dark mode chrome
- **WHEN** Viewer is displayed in dark mode
- **THEN** surrounding chrome and filled/outlined favourite states use the dark colour scheme while page content remains rendered as authored

#### Scenario: Tablet layout
- **WHEN** Viewer is displayed on a tablet-width viewport
- **THEN** it uses the additional width without clipping or overflow and does not eagerly build a page-count-sized thumbnail rail

#### Scenario: Viewing offline
- **WHEN** the device has no network connection and the PDF is locally available
- **THEN** the document, favourite action, and Details metadata operate against local storage with no network request

#### Scenario: End-to-end viewer coverage
- **WHEN** the `browse_and_view` flow opens a long-titled document and jumps to a page
- **THEN** it uses stable page, favourite, Details, share, print, and edit keys/semantics without layout failure

### Requirement: Viewer metadata reconciliation
Viewer SHALL reconcile document metadata after Details closes without reopening the PDF or losing the current reading position.

#### Scenario: Detail changes metadata
- **WHEN** Detail renames, moves, archives/restores, or favourites the document and then closes
- **THEN** Viewer reloads metadata only, updates title/favourite state, and preserves its resolved file, password, current page, and page surface

#### Scenario: Detail deletes the document
- **WHEN** Detail moves the document to Trash and closes
- **THEN** Viewer detects that the active document is unavailable and closes exactly once to the originating library surface

#### Scenario: Metadata refresh fails transiently
- **WHEN** metadata refresh fails for a reason other than not-found
- **THEN** the readable PDF stays open at the current page and a human-readable nonfatal message is presented

#### Scenario: Detail returns without changes
- **WHEN** the user opens Details and returns without mutation
- **THEN** Viewer remains on the same page without flashing a new PDF loading state
