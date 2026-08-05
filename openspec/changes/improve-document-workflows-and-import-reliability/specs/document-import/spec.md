## ADDED Requirements

### Requirement: Imported PDF page capability
Every successfully imported PDF SHALL expose its complete page sequence through stable document-and-page-derived identities and SHALL allow each page to be rendered lazily from the authoritative local PDF without requiring permanent page-image rows.

#### Scenario: Imported pages are addressable
- **WHEN** a PDF import completes with a valid page count
- **THEN** page consumers can enumerate exactly that many ordered page handles whose identities remain stable across application launches

#### Scenario: Imported page renders on demand
- **WHEN** Detail, Viewer, Editor, OCR, or Sharing requests an imported PDF page
- **THEN** that page is rendered from the copied library PDF at the bounded resolution required by the consumer

#### Scenario: No eager raster duplication
- **WHEN** a large PDF is imported
- **THEN** import does not permanently rasterize every page, and any derived thumbnails or working images remain private reclaimable cache artifacts

#### Scenario: Protected imported page
- **WHEN** page access requires a password-protected imported PDF
- **THEN** it resolves the credential through secure storage, does not persist or log the password elsewhere, and returns a typed locked failure when no valid credential is available

#### Scenario: Imported PDF consistency
- **WHEN** the dashboard can show a first-page thumbnail for an imported PDF
- **THEN** Detail previews, Viewer, Editor, image sharing, and text extraction address the same authoritative PDF pages rather than reporting that page content no longer exists

#### Scenario: Imported page access is offline and responsive
- **WHEN** page access runs offline on a phone or tablet in light or dark mode
- **THEN** no network request occurs, rendering remains bounded, and progress or stable placeholders keep the requesting screen responsive

#### Scenario: End-to-end imported page coverage
- **WHEN** the `import` end-to-end flow imports a multi-page text PDF and opens it through `browse_and_view`
- **THEN** the flow observes matching Dashboard and Detail previews and can open, edit, share images, and request text from the imported document

