## ADDED Requirements

### Requirement: PDF viewing
The application SHALL render a stored document as a PDF for viewing.

#### Scenario: Opening a document
- **WHEN** the user selects a document from any list
- **THEN** the viewer with key `viewer_screen` opens and renders the first page

#### Scenario: Page indicator
- **WHEN** a document is open in the viewer
- **THEN** an indicator with key `viewer_page_indicator` shows the current page number and the total page count

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
The viewer SHALL allow the user to jump directly to a chosen page.

#### Scenario: Jumping to a page
- **WHEN** the user enters a valid page number in the control with key `viewer_jump_to_page_field`
- **THEN** the viewer scrolls to that page and the page indicator updates

#### Scenario: Out-of-range page number
- **WHEN** the user enters a page number outside the document's range
- **THEN** the input is refused with a validation message and the current page is unchanged

### Requirement: Viewer actions
The viewer SHALL provide access to share, print and the editing tools.

#### Scenario: Share from the viewer
- **WHEN** the user activates the control with key `viewer_share_button`
- **THEN** the share flow for the open document is started

#### Scenario: Print from the viewer
- **WHEN** the user activates the control with key `viewer_print_button`
- **THEN** the system print flow for the open document is started

#### Scenario: Open editing tools
- **WHEN** the user activates the control with key `viewer_edit_button`
- **THEN** the PDF editing tools for the open document are opened

### Requirement: Protected document handling
The viewer SHALL prompt for a password when opening a password-protected document and SHALL not render its contents until the correct password is supplied.

#### Scenario: Correct password
- **WHEN** the user enters the correct password in the field with key `viewer_password_field`
- **THEN** the document is rendered

#### Scenario: Incorrect password
- **WHEN** the user enters an incorrect password
- **THEN** an error message is displayed, the document contents are not rendered, and the user can retry

### Requirement: Viewer performance
The viewer SHALL open documents quickly and support large documents without exhausting memory.

#### Scenario: Large document
- **WHEN** a document with many pages is opened
- **THEN** pages are rendered on demand rather than all at once, scrolling remains smooth, and memory use stays bounded

#### Scenario: Open latency
- **WHEN** a document is opened from a list
- **THEN** the first page is rendered promptly, with a loading indicator with key `viewer_loading_indicator` shown while rendering is in progress

### Requirement: Viewer error handling
The viewer SHALL present a clear message and a recovery action when a document cannot be rendered.

#### Scenario: Corrupt or missing file
- **WHEN** the document file is missing or cannot be parsed
- **THEN** an error view with key `viewer_error_view` is displayed with a human-readable message and a control to return to the previous screen, and the application does not crash

### Requirement: Viewer accessibility, theming, layout and offline behaviour
The viewer SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader in the viewer
- **WHEN** a screen reader traverses the viewer
- **THEN** the page indicator announces the current and total page numbers, and the share, print, edit and jump-to-page controls each expose a descriptive semantics label

#### Scenario: Dark mode chrome
- **WHEN** the viewer is displayed in dark mode
- **THEN** the surrounding chrome uses the dark colour scheme while the page content itself remains rendered as authored

#### Scenario: Tablet layout
- **WHEN** the viewer is displayed on a tablet-width viewport
- **THEN** it uses the additional width and may present a page thumbnail rail, without clipping or overflow

#### Scenario: Viewing offline
- **WHEN** the device has no network connection
- **THEN** the document renders from local storage with no network request
