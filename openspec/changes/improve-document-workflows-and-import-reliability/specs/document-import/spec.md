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

### Requirement: User-driven camera creation and reversible processing
Camera document creation SHALL show a live preview before capture, SHALL capture only from an explicit shutter action, and SHALL preserve reversible Crop and Enhance navigation with responsive manipulation controls.

#### Scenario: Camera does not capture automatically
- **WHEN** the user opens camera document creation
- **THEN** the live camera preview remains visible and no photo is captured until `Key('camera_shutter_button')` is activated

#### Scenario: Enhance Back returns to Crop
- **WHEN** the user advances from Crop to Enhance and activates Back
- **THEN** the same image and crop state are restored on Crop instead of closing document creation

#### Scenario: Flip previews immediately
- **WHEN** the user activates the Crop flip control
- **THEN** the crop preview updates immediately before Apply and the saved result matches that preview

#### Scenario: Crop handles are forgiving and smooth
- **WHEN** the user starts near a visible crop corner or edge and drags
- **THEN** a larger accessible hit region acquires that handle and its preview follows continuous movement without requiring pixel-precise initial contact

#### Scenario: Compact confirmation titles
- **WHEN** Crop, Enhance, confirmation, or naming appears on a phone or supported large text scale
- **THEN** its title uses compact bounded typography and does not displace navigation actions

### Requirement: Dedicated multi-page naming screen
Naming page-derived outputs SHALL use a dedicated scrollable screen rather than a popup and SHALL make cancellation and completion explicit in the header.

#### Scenario: Naming screen structure
- **WHEN** captured pages require individual output names
- **THEN** `Key('page_naming_screen')` shows Cancel/close in the leading header, Done/check in the trailing header, and ordered Page 1, Page 2, and later sections with preview and editable name

#### Scenario: Complete page naming
- **WHEN** every visible page has a valid collision-safe name and the user activates `Key('page_naming_done')`
- **THEN** each intended output is created exactly once using its reviewed name

#### Scenario: Cancel page naming
- **WHEN** the user activates `Key('page_naming_cancel')`
- **THEN** the screen closes without creating any output
