## MODIFIED Requirements

### Requirement: PDF viewing
The application SHALL render a stored document as a PDF for viewing and SHALL make that viewer reachable from the document detail screen.

#### Scenario: Selecting a document
- **WHEN** the user selects a document from an active document list
- **THEN** its detail screen with key `document_detail_screen` opens and presents the control with `Key('document_open_button')`

#### Scenario: Opening from document detail
- **WHEN** the user activates `Key('document_open_button')` with semantics label “Open” on the detail screen
- **THEN** the existing viewer route for the same document identifier opens with key `viewer_screen` and renders the first page

#### Scenario: Page indicator
- **WHEN** a document is open in the viewer
- **THEN** an indicator with key `viewer_page_indicator` shows the current page number and the total page count

#### Scenario: End-to-end coverage
- **WHEN** the `browse_and_view` end-to-end flow selects a saved document and activates its Open control
- **THEN** it verifies navigation to `viewer_screen` for that document
