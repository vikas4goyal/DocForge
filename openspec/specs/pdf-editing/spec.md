# pdf-editing Specification

## Purpose

Define editing a document that already exists as a PDF: page-level operations, merging, splitting, compressing, watermarking, adding and removing a password, viewing metadata — each running off the UI thread and leaving the source document untouched on failure.

## Requirements

### Requirement: Page-level PDF operations
The application SHALL allow the user to rotate, delete, extract and duplicate pages within an existing PDF.

#### Scenario: Rotate a page
- **WHEN** the user selects a page in the editor with key `pdf_edit_screen` and activates the rotate control with key `pdf_edit_rotate_button`
- **THEN** that page is rotated 90 degrees clockwise in the saved document and the page count is unchanged

#### Scenario: Delete a page
- **WHEN** the user deletes a page and confirms
- **THEN** the page is removed, the page count decreases by one, and the document's modified date and file size are updated

#### Scenario: Deleting the last remaining page is prevented
- **WHEN** the user attempts to delete the only page of a document
- **THEN** the operation is refused with a message explaining that a document must contain at least one page

#### Scenario: Extract pages
- **WHEN** the user selects pages and activates the control with key `pdf_edit_extract_button`
- **THEN** a new document containing only the selected pages is created and the source document is left unchanged

#### Scenario: Duplicate a page
- **WHEN** the user duplicates a page
- **THEN** a copy is inserted immediately after the original and the page count increases by one

### Requirement: Merge PDFs
The application SHALL allow the user to merge two or more documents into a single document in a user-controlled order.

#### Scenario: Merging documents
- **WHEN** the user selects two documents and activates the control with key `pdf_merge_confirm_button`
- **THEN** a new document is created whose pages are those of the selected documents in the chosen order
- **AND** the source documents remain unchanged

#### Scenario: Merge order is user-controlled
- **WHEN** the user reorders the selected documents in the merge list with key `pdf_merge_order_list`
- **THEN** the merged result follows that order

#### Scenario: Merge requires at least two documents
- **WHEN** fewer than two documents are selected
- **THEN** the merge confirmation control is disabled

### Requirement: Split PDF
The application SHALL allow the user to split a document into multiple documents at chosen page boundaries.

#### Scenario: Splitting a document
- **WHEN** the user chooses a split point and confirms via the control with key `pdf_split_confirm_button`
- **THEN** two documents are created whose combined pages equal the original, in the original order
- **AND** the original document remains unchanged unless the user chooses to replace it

### Requirement: Compress PDF
The application SHALL allow the user to compress a document and SHALL report the resulting size change.

#### Scenario: Compressing a document
- **WHEN** the user compresses a document via the control with key `pdf_compress_button`
- **THEN** the resulting file size is reported alongside the original size and the page count is unchanged

#### Scenario: Compression yields no benefit
- **WHEN** compression would not reduce the file size
- **THEN** the user is informed and the original document is left unchanged

### Requirement: Watermark PDF
The application SHALL allow the user to apply a text watermark to every page of a document.

#### Scenario: Applying a watermark
- **WHEN** the user enters watermark text in the field with key `pdf_watermark_text_field` and confirms
- **THEN** the watermark appears on every page of the resulting document

#### Scenario: Watermark preview
- **WHEN** the user is editing watermark settings
- **THEN** a preview shows how the watermark will appear before it is applied

### Requirement: Password protection
The application SHALL allow the user to protect a document with a password and to remove an existing password, and SHALL store passwords only in secure storage.

#### Scenario: Protecting a document
- **WHEN** the user sets a password via the field with key `pdf_protect_password_field` and confirms
- **THEN** the resulting PDF requires that password to open in a standard PDF reader
- **AND** the document is marked as protected in the library

#### Scenario: Password stored securely
- **WHEN** a password is retained for a document
- **THEN** it is stored in secure storage only, never in preferences, never in the database, and never written to logs

#### Scenario: Removing a password
- **WHEN** the user supplies the correct current password and activates the control with key `pdf_remove_password_button`
- **THEN** the protection is removed and the resulting PDF opens without a password

#### Scenario: Incorrect password
- **WHEN** the user supplies an incorrect password when removing protection
- **THEN** an error message is displayed, the document is left unchanged, and the user can retry

### Requirement: PDF metadata
The application SHALL display the metadata of a document.

#### Scenario: Viewing metadata
- **WHEN** the user opens the metadata view with key `pdf_metadata_view`
- **THEN** the title, page count, file size, creation date, modified date and protection status are displayed

### Requirement: Editing safety and error handling
Every editing operation SHALL either complete fully or leave the source document unchanged, and SHALL present a clear message and recovery action on failure.

#### Scenario: Operation failure leaves the document intact
- **WHEN** any PDF editing operation fails partway through
- **THEN** the source document is left in its original state, no partial file remains in storage, and an error view with key `pdf_edit_error_view` is displayed with a retry control

#### Scenario: Storage full during an edit
- **WHEN** an editing operation cannot complete because device storage is full
- **THEN** a storage-full message with guidance to free space is displayed and the source document is unchanged

#### Scenario: Corrupt or unreadable PDF
- **WHEN** an editing operation is attempted on a corrupt or unreadable PDF
- **THEN** a typed failure is surfaced as a human-readable message and the application does not crash

### Requirement: Editing performance
PDF editing operations SHALL run off the UI thread, report progress and be cancellable.

#### Scenario: Large document edit
- **WHEN** an editing operation runs on a large document
- **THEN** it runs in a background isolate, the UI remains responsive, a progress indicator with key `pdf_edit_progress` is shown, and a cancel control is available

### Requirement: PDF editing accessibility, theming, layout and offline behaviour
The PDF editing screens SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on editing tools
- **WHEN** a screen reader traverses the PDF editor
- **THEN** every editing control exposes a descriptive semantics label, and each page thumbnail announces its page number and selection state

#### Scenario: Dark mode and tablet editor
- **WHEN** the editor is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow

#### Scenario: Editing offline
- **WHEN** the device has no network connection
- **THEN** every PDF editing operation completes successfully with no network request
