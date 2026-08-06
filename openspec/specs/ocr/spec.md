# ocr Specification

## Purpose

Define on-device text recognition: extracting text from pages without a network, writing an invisible text layer into the generated PDF so it is searchable and selectable, and letting the user copy, search, export and re-run that text.

## Requirements

### Requirement: Offline text extraction
The application SHALL extract text from scanned pages using on-device recognition, and SHALL do so without requiring an internet connection.

#### Scenario: Text extracted from a page
- **WHEN** OCR is run on a page containing legible text
- **THEN** the recognised text is returned and persisted against that page

#### Scenario: OCR with no connectivity
- **WHEN** the device has no network connection and OCR is run
- **THEN** recognition completes successfully and no network request is made

#### Scenario: Page with no recognisable text
- **WHEN** OCR is run on a page containing no recognisable text
- **THEN** an empty result is persisted and this is not treated as an error

### Requirement: Searchable PDF text layer
The application SHALL produce an invisible text layer positioned over the page image so the generated PDF is searchable and selectable.

#### Scenario: Searchable PDF produced
- **WHEN** a document is saved with OCR results available
- **THEN** the generated PDF contains an invisible text layer whose text is selectable and searchable in a standard PDF reader

#### Scenario: Text layer alignment
- **WHEN** the text layer is written
- **THEN** each recognised text block is positioned over the corresponding region of the page image

#### Scenario: PDF is still produced when OCR is unavailable
- **WHEN** OCR fails or returns no results for a page
- **THEN** the PDF is still generated with the page image and without a text layer for that page

### Requirement: Copy, search and export recognised text
The application SHALL allow the user to copy recognised text, search within it and export it.

#### Scenario: Copy recognised text
- **WHEN** the user activates the control with key `ocr_copy_text_button` on the extracted-text view with key `ocr_text_view`
- **THEN** the recognised text is placed on the system clipboard and a confirmation is shown

#### Scenario: Recognised text is searchable
- **WHEN** the user searches for a term that appears only in a document's recognised text
- **THEN** that document is returned in the search results

#### Scenario: Export recognised text
- **WHEN** the user activates the control with key `ocr_export_text_button`
- **THEN** the recognised text is exported as a plain-text file through the system share or save flow

### Requirement: OCR language selection
The application SHALL run recognition using the OCR language configured in settings, and SHALL allow OCR to be re-run on an existing document.

#### Scenario: Configured language is used
- **WHEN** the OCR language is set in settings and a page is recognised
- **THEN** recognition uses the configured language

#### Scenario: Re-running OCR
- **WHEN** the user activates the control with key `ocr_rerun_button` for an existing document
- **THEN** recognition runs again using the current language setting and replaces the previously stored text

### Requirement: OCR performance
OCR SHALL run off the UI thread, report progress, be cancellable, and persist its result so a page is recognised at most once unless explicitly re-run.

#### Scenario: Recognition off the UI thread
- **WHEN** OCR runs on a multi-page document
- **THEN** the work runs in a background isolate and the UI remains responsive

#### Scenario: Progress reported
- **WHEN** OCR runs across multiple pages
- **THEN** a progress indicator with key `ocr_progress_indicator` reports the number of pages completed out of the total

#### Scenario: Cancellation
- **WHEN** the user cancels an in-progress OCR run
- **THEN** processing stops, pages already recognised keep their results, and the UI returns to a non-processing state

#### Scenario: Results are not recomputed
- **WHEN** a document whose pages have already been recognised is opened
- **THEN** the stored recognised text is used and recognition does not run again

### Requirement: OCR error handling
The application SHALL present a clear message and a recovery action when recognition fails.

#### Scenario: OCR failure
- **WHEN** recognition fails for a page
- **THEN** an error view with key `ocr_error_view` is displayed with a human-readable message and a retry control
- **AND** the document remains usable, including saving and sharing, without recognised text

### Requirement: OCR accessibility, theming and layout
The extracted-text view SHALL support screen readers, large text, dark mode and phone and tablet layouts.

#### Scenario: Screen reader reads extracted text
- **WHEN** a screen reader traverses the extracted-text view
- **THEN** the recognised text is exposed as readable content and the copy, export and re-run controls each expose a descriptive semantics label

#### Scenario: Dark mode and tablet
- **WHEN** the extracted-text view is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow

#### Scenario: Long extracted text
- **WHEN** a document produces a large volume of recognised text
- **THEN** the extracted-text view scrolls and remains responsive without truncating content
