# document-sharing Specification

## Purpose

Define the only ways document content leaves the application: sharing a PDF, page images or recognised text through the system share sheet, printing, and exporting to a destination the user chooses — each an explicit, user-initiated action.

## Requirements

### Requirement: Share a document as a PDF
The application SHALL allow the user to share a document as a PDF through the system share sheet.

#### Scenario: Sharing a PDF
- **WHEN** the user activates the control with key `share_pdf_button`
- **THEN** the system share sheet opens with the document's PDF attached

#### Scenario: Sharing a protected document
- **WHEN** the user shares a password-protected document
- **THEN** the shared file retains its password protection and the password itself is not included in the share

#### Scenario: Share is explicit
- **WHEN** no share, export or print action has been invoked
- **THEN** no document leaves the application

### Requirement: Share pages as images
The application SHALL allow the user to share one or more pages of a document as images.

#### Scenario: Sharing page images
- **WHEN** the user selects pages and activates the control with key `share_images_button`
- **THEN** the system share sheet opens with those pages attached as image files in page order

### Requirement: Share extracted text
The application SHALL allow the user to share a document's recognised text.

#### Scenario: Sharing text
- **WHEN** the user activates the control with key `share_text_button` for a document with recognised text
- **THEN** the system share sheet opens with the recognised text as shareable content

#### Scenario: No recognised text available
- **WHEN** the user attempts to share text for a document with no recognised text
- **THEN** the control is disabled or a message explains that no text is available and offers to run recognition

### Requirement: Printing
The application SHALL allow the user to print a document through the system print flow.

#### Scenario: Printing a document
- **WHEN** the user activates the control with key `share_print_button`
- **THEN** the system print dialog opens with the document loaded

#### Scenario: Print cancelled
- **WHEN** the user cancels the system print dialog
- **THEN** the application returns to the previous screen with no change to the document

### Requirement: Export to device storage
The application SHALL allow the user to export a document to a location of their choosing on the device.

#### Scenario: Exporting a document
- **WHEN** the user activates the control with key `share_export_button` and chooses a destination
- **THEN** the document file is written to the chosen destination and a confirmation is shown

#### Scenario: Export cancelled
- **WHEN** the user cancels the destination picker
- **THEN** nothing is written and the application returns to the previous screen

### Requirement: Sharing error handling
The application SHALL present a clear message and a recovery action when sharing, printing or exporting fails.

#### Scenario: Export failure
- **WHEN** an export fails, including because storage is full or the destination is not writable
- **THEN** an error view with key `share_error_view` is displayed with a human-readable message and a retry control, and no partial file remains at the destination

#### Scenario: No application available to receive the share
- **WHEN** the system reports that no application can handle the shared content
- **THEN** a message explains this and offers export to device storage as an alternative

#### Scenario: Print failure
- **WHEN** printing fails or no printer is available
- **THEN** a human-readable message is displayed and the application does not crash

### Requirement: Sharing performance
Preparing content for sharing SHALL run off the UI thread and report progress for long operations.

#### Scenario: Preparing a large document
- **WHEN** a large document is prepared for sharing or export
- **THEN** the work runs in a background isolate, a progress indicator with key `share_progress_indicator` is displayed, and the UI remains responsive

### Requirement: Sharing accessibility, theming, layout and offline behaviour
Sharing controls and screens SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on share options
- **WHEN** a screen reader traverses the sharing options
- **THEN** each option exposes a semantics label naming what will be shared and in what format

#### Scenario: Dark mode and tablet
- **WHEN** the sharing options are displayed in dark mode on a tablet-width viewport
- **THEN** they use the dark colour scheme and adapt to the wider viewport without clipping or overflow

#### Scenario: Preparing to share offline
- **WHEN** the device has no network connection
- **THEN** the document, images or text are prepared and handed to the system share sheet with no network request made by the application
