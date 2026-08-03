## ADDED Requirements

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
