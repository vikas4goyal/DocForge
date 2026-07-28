# pdf-generation Specification

## Purpose

Define how a creation session becomes a file: the PDF is written into the currently open folder of the library under a name the user can override, optionally encrypted with a password they supply at save time, and the session's images are deleted once the file has been written and verified so the PDF is the document's only remaining representation.

## Requirements

### Requirement: Document saving and naming
Saving a document SHALL write the PDF into the currently open folder of the library folder, create the document record, and name the document according to the default file-naming setting while allowing the user to override the name.

#### Scenario: Document saved
- **WHEN** the user activates the save control with key `creation_save_confirm_button`
- **THEN** the PDF is written into the currently open folder of the library folder, a document record is created with title, creation date, modified date, page count, file size and folder path, and the user is returned to that folder

#### Scenario: Default name applied
- **WHEN** the save dialog opens
- **THEN** the name field is prefilled from the configured default file-naming pattern

#### Scenario: Name overridden
- **WHEN** the user edits the name in the field with key `creation_save_name_field` before saving
- **THEN** the entered name is used as both the document title and the file name

#### Scenario: File name matches the title
- **WHEN** a document has been saved
- **THEN** the file in the library folder is named after the document title with a `.pdf` extension

#### Scenario: Document appears in the dashboard
- **WHEN** saving completes and the user is returned to the dashboard
- **THEN** the new document appears in the folder it was saved into and at the top of the recent documents section

#### Scenario: Saved document is visible outside the application
- **WHEN** saving completes
- **THEN** the file is present in the operating system's file browser under the same folder path and name, without any further action by the user

### Requirement: Optional encryption at generation
PDF generation SHALL encrypt the document with a user-supplied password when the user asks for password protection at save time.

#### Scenario: Encrypted output produced
- **WHEN** the user saves with password protection enabled and a confirmed password
- **THEN** the written PDF is encrypted with that password using the application's PDF encryption, and opening it in another application requires that password

#### Scenario: Password stored for in-application use
- **WHEN** a document is saved with password protection
- **THEN** the password is stored in secure storage against that document, and never in preferences or in the database

#### Scenario: Unprotected by default
- **WHEN** the user saves without enabling password protection
- **THEN** the written PDF is not encrypted and opens without a password

#### Scenario: Encryption failure
- **WHEN** encryption fails
- **THEN** no file is left in the library folder, an error message with a retry control is displayed, and the creation session and its pages are retained

### Requirement: Session cleanup after generation
Generating a document SHALL delete every image the session used — originals, cached renders and thumbnails — once the PDF has been written and verified, so that the PDF is the only remaining representation of the document.

#### Scenario: Page images deleted
- **WHEN** the PDF has been written successfully
- **THEN** every original page image and every cached render belonging to that session is deleted from storage

#### Scenario: Nothing is retained but the PDF
- **WHEN** the session has been cleaned up
- **THEN** no image belonging to the document remains in storage, and its thumbnails are re-derived from the PDF when they are next needed

#### Scenario: Nothing deleted on failure
- **WHEN** generating or writing the PDF fails
- **THEN** no page image is deleted and the user can retry from the same session

### Requirement: PDF creation from the page table
The application SHALL generate a PDF from the pages of a creation session, preserving page order, rotation and enhancement.

#### Scenario: PDF generated from a multi-page session
- **WHEN** the user saves a session containing three ordered pages
- **THEN** a PDF containing exactly three pages in the same order is written

#### Scenario: Rotation preserved
- **WHEN** a page was rotated as part of its crop layer
- **THEN** the corresponding PDF page is generated with that rotation applied

#### Scenario: Enhancement preserved
- **WHEN** enhancement settings were applied to a page
- **THEN** the corresponding PDF page contains the enhanced image, not the raw capture

### Requirement: Configurable PDF and image quality
PDF generation SHALL honour the PDF quality and image quality settings, trading file size against fidelity.

#### Scenario: Quality setting is applied
- **WHEN** a document is generated with the PDF quality setting at its lowest value
- **THEN** the resulting file is smaller than the same document generated at the highest value

#### Scenario: Quality is recorded
- **WHEN** a document is generated
- **THEN** the quality settings used are recorded with the document so the result is reproducible

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
- **AND** the session's pages are retained so the user can retry without rescanning

#### Scenario: Storage full during generation
- **WHEN** the PDF cannot be written because device storage is full
- **THEN** a storage-full message with guidance to free space is displayed, and any partially written file is removed

### Requirement: PDF generation works offline
PDF generation SHALL complete with no network connectivity.

#### Scenario: Generating offline
- **WHEN** the device has no network connection and the user saves a document
- **THEN** the PDF is generated and stored successfully with no network request

### Requirement: PDF save accessibility, theming and layout
The save screen SHALL support screen readers, dark mode and phone and tablet layouts.

#### Scenario: Screen reader on the save screen
- **WHEN** a screen reader traverses the save screen
- **THEN** the page count, the name field and the save control each expose a descriptive semantics label

#### Scenario: Dark mode and tablet save screen
- **WHEN** the save screen is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow
