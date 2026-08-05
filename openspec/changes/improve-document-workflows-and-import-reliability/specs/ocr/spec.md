## MODIFIED Requirements

### Requirement: Offline text extraction
The application SHALL extract text without a network by using embedded text from PDF-backed pages when usable and falling back page-by-page to on-device recognition for image-only or blank-text pages. It SHALL persist the resulting text against each stable page identity and SHALL derive document text availability from actual stored or extractable content rather than only a stale metadata flag.

#### Scenario: Embedded PDF text extracted
- **WHEN** text extraction runs on an imported PDF page containing usable embedded text
- **THEN** that text is normalized and persisted against the page without rasterizing it for OCR

#### Scenario: Image page uses OCR fallback
- **WHEN** a scanned page or PDF page has no usable embedded text
- **THEN** the page is rendered at a bounded recognition resolution, on-device OCR runs, and the recognised text is persisted against that page

#### Scenario: Mixed PDF text sources
- **WHEN** a document contains both text-backed and image-only pages
- **THEN** each page uses its available source and the ordered document result combines embedded and recognised text

#### Scenario: Text extracted from a page
- **WHEN** extraction is run on a page containing legible text
- **THEN** the extracted or recognised text is returned and persisted against that page's stable identity

#### Scenario: OCR with no connectivity
- **WHEN** the device has no network connection and text extraction is run
- **THEN** embedded extraction and any recognition fallback complete locally and no network request is made

#### Scenario: Page with no recognisable text
- **WHEN** embedded extraction and OCR both produce no usable text for a page
- **THEN** an empty result is persisted and this is not treated as an error

#### Scenario: Text availability is repaired
- **WHEN** stored or newly extracted text exists but the document summary flag is false
- **THEN** Share Text and extracted-text features become available and the summary flag is repaired after successful persistence

#### Scenario: Protected PDF text
- **WHEN** text extraction runs on a protected PDF
- **THEN** the password is resolved only through secure storage and never enters Cubit state, logs, previews, or text results

#### Scenario: End-to-end text extraction coverage
- **WHEN** the `share` end-to-end flow opens a text-heavy imported policy PDF whose summary flag was initially false
- **THEN** it can extract and share the document text without a network request

