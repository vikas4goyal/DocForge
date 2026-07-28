## ADDED Requirements

### Requirement: PDF creation from scanned pages
The application SHALL generate a PDF from the enhanced pages of a scanning session, preserving page order and orientation.

#### Scenario: PDF generated from a multi-page session
- **WHEN** the user saves a session containing three ordered pages
- **THEN** a PDF containing exactly three pages in the same order is written to app-private storage

#### Scenario: Rotation preserved
- **WHEN** a page was rotated during review
- **THEN** the corresponding PDF page is generated with that rotation applied

#### Scenario: Enhancement preserved
- **WHEN** enhancement settings were applied to a page
- **THEN** the corresponding PDF page contains the enhanced image, not the raw capture

### Requirement: Document preview before saving
The application SHALL let the user preview the document before it is saved.

#### Scenario: Preview shown
- **WHEN** the user proceeds from the enhancement step
- **THEN** a document preview with key `pdf_preview_screen` is displayed showing every page as it will appear in the PDF

#### Scenario: Returning from preview
- **WHEN** the user navigates back from the preview
- **THEN** the session and all page edits are preserved and no PDF has been written

### Requirement: Configurable PDF and image quality
PDF generation SHALL honour the PDF quality and image quality settings, trading file size against fidelity.

#### Scenario: Quality setting is applied
- **WHEN** a document is generated with the PDF quality setting at its lowest value
- **THEN** the resulting file is smaller than the same document generated at the highest value

#### Scenario: Quality is recorded
- **WHEN** a document is generated
- **THEN** the quality settings used are recorded with the document so the result is reproducible

### Requirement: Document saving and naming
Saving a document SHALL store the PDF in app-private storage, create the document record, and name the document according to the default file-naming setting while allowing the user to override the name.

#### Scenario: Document saved
- **WHEN** the user activates the save control with key `pdf_save_button`
- **THEN** the PDF is written to app-private storage, a document record is created with title, creation date, modified date, page count and file size, and the user is returned to the Home screen

#### Scenario: Default name applied
- **WHEN** a document is saved without the user editing the name
- **THEN** the title is generated from the configured default file-naming pattern

#### Scenario: Name overridden
- **WHEN** the user edits the name in the field with key `pdf_document_name_field` before saving
- **THEN** the entered name is used as the document title

#### Scenario: Document appears in Recent
- **WHEN** saving completes and the user is returned to Home
- **THEN** the new document appears at the top of the recent documents section

### Requirement: PDF generation performance
PDF generation SHALL run off the UI thread, report progress and be cancellable.

#### Scenario: Generation off the UI thread
- **WHEN** a PDF is generated
- **THEN** the work runs in a background isolate and the UI remains responsive

#### Scenario: Progress reported
- **WHEN** generation is in progress
- **THEN** a progress indicator with key `pdf_generation_progress` reports progress to the user

#### Scenario: Cancellation
- **WHEN** the user cancels generation before it completes
- **THEN** generation stops, no partial document record is created, and no orphaned file is left in storage

### Requirement: PDF generation error handling
The application SHALL present a clear message and a recovery action when PDF generation fails, and SHALL leave no partial artefacts.

#### Scenario: Generation failure
- **WHEN** PDF generation fails
- **THEN** an error view with key `pdf_generation_error_view` is displayed with a human-readable message and a retry control
- **AND** the captured pages are retained so the user can retry without rescanning

#### Scenario: Storage full during generation
- **WHEN** the PDF cannot be written because device storage is full
- **THEN** a storage-full message with guidance to free space is displayed, and any partially written file is removed

### Requirement: PDF generation works offline
PDF generation SHALL complete with no network connectivity.

#### Scenario: Generating offline
- **WHEN** the device has no network connection and the user saves a document
- **THEN** the PDF is generated and stored successfully with no network request

### Requirement: PDF preview accessibility, theming and layout
The document preview and save screens SHALL support screen readers, dark mode and phone and tablet layouts.

#### Scenario: Screen reader on preview
- **WHEN** a screen reader traverses the document preview
- **THEN** the page count, the name field and the save control each expose a descriptive semantics label

#### Scenario: Dark mode and tablet preview
- **WHEN** the document preview is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow
