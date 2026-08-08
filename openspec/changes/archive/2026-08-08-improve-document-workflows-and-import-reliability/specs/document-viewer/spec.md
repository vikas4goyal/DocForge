## MODIFIED Requirements

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
The viewer SHALL provide responsive access to share, print, and focused PDF operations while preserving meaningful title space. On constrained widths, Print, Compress, Split, Watermark, Set/Remove Password, and any page-management entry SHALL be placed in an adaptive overflow control rather than requiring a generic editor hub or rendering inert or clipped buttons.

#### Scenario: Long viewer title
- **WHEN** the viewer displays a long title on a constrained phone width
- **THEN** the app bar shows a one-line ellipsized title, exposes the complete title to semantics, and `Key('viewer_actions_menu')` remains reachable without overlap

#### Scenario: Share from the viewer
- **WHEN** the user activates the control with key `viewer_share_button`, directly or through `Key('viewer_actions_menu')`
- **THEN** the share flow for the open document is started

#### Scenario: Print from the viewer
- **WHEN** the user activates the control with key `viewer_print_button`, directly or through `Key('viewer_actions_menu')`
- **THEN** the system print flow for the open document is started

#### Scenario: Open a focused PDF operation
- **WHEN** the user chooses Print, Compress, Split, Watermark, or Set/Remove Password from `Key('viewer_actions_menu')`
- **THEN** that operation's focused sheet or screen opens directly with Cancel and Done/Confirm behavior and no generic editor hub is shown first

#### Scenario: Open page management when required
- **WHEN** the user chooses an operation that genuinely requires page thumbnail selection or ordering
- **THEN** the page-management editor opens with only applicable contextual actions

#### Scenario: No inert viewer action
- **WHEN** an action cannot be offered for the open document
- **THEN** it is absent or presents a human-readable reason, and no visible action silently ignores activation

### Requirement: Viewer accessibility, theming, layout and offline behaviour
The viewer SHALL support screen readers, supported large text scales, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader in the viewer
- **WHEN** a screen reader traverses the viewer
- **THEN** the full document title and page position are announced, and the share, print, focused-operation, actions-menu, and jump-to-page controls each expose a descriptive semantics label

#### Scenario: Large text on a phone
- **WHEN** the viewer is displayed at a supported large text scale on a phone
- **THEN** title, actions, and page navigation remain reachable and unclipped, and the page content keeps the remaining usable viewport

#### Scenario: Dark mode chrome
- **WHEN** the viewer is displayed in dark mode
- **THEN** the surrounding chrome uses the dark colour scheme while the page content itself remains rendered as authored

#### Scenario: Tablet layout
- **WHEN** the viewer is displayed on a tablet-width viewport
- **THEN** it uses the additional width and may present a page thumbnail rail, without clipping or overflow

#### Scenario: Viewing offline
- **WHEN** the device has no network connection
- **THEN** the document renders from local storage with no network request

#### Scenario: End-to-end viewer coverage
- **WHEN** the `browse_and_view` end-to-end flow opens a long-titled document and jumps to a page
- **THEN** it uses the compact page control and reaches share, print, and edit through their stable keys and semantics
