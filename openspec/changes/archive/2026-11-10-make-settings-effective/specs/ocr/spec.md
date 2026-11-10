# Spec Delta

## REMOVED Requirements

### Requirement: Offline text extraction
**Reason**: Text recognition was never shipped. The `ocr` feature had no screen, no on-device recogniser, no registered database table, and no consumer: the searchable-PDF lookup always returned nothing and search never produced a recognised-text match. The product decision (2026-11-10) is to remove OCR rather than finish it.
**Migration**: None. No recognised text was ever stored in a shipped build.

### Requirement: Searchable PDF text layer
**Reason**: Text recognition was never shipped. The `ocr` feature had no screen, no on-device recogniser, no registered database table, and no consumer: the searchable-PDF lookup always returned nothing and search never produced a recognised-text match. The product decision (2026-11-10) is to remove OCR rather than finish it.
**Migration**: Generated PDFs contain page images only, as they already did. PDF generation drops the always-empty text-layer plumbing.

### Requirement: Copy, search and export recognised text
**Reason**: Text recognition was never shipped. The `ocr` feature had no screen, no on-device recogniser, no registered database table, and no consumer: the searchable-PDF lookup always returned nothing and search never produced a recognised-text match. The product decision (2026-11-10) is to remove OCR rather than finish it.
**Migration**: Search matches document titles only (see `document-search`). Copy and export of recognised text never existed in the UI.

### Requirement: OCR language selection
**Reason**: Text recognition was never shipped. The `ocr` feature had no screen, no on-device recogniser, no registered database table, and no consumer: the searchable-PDF lookup always returned nothing and search never produced a recognised-text match. The product decision (2026-11-10) is to remove OCR rather than finish it.
**Migration**: None. No language was ever stored. The Settings entry was removed in `app-settings`.

### Requirement: OCR performance
**Reason**: Text recognition was never shipped. The `ocr` feature had no screen, no on-device recogniser, no registered database table, and no consumer: the searchable-PDF lookup always returned nothing and search never produced a recognised-text match. The product decision (2026-11-10) is to remove OCR rather than finish it.
**Migration**: None.

### Requirement: OCR error handling
**Reason**: Text recognition was never shipped. The `ocr` feature had no screen, no on-device recogniser, no registered database table, and no consumer: the searchable-PDF lookup always returned nothing and search never produced a recognised-text match. The product decision (2026-11-10) is to remove OCR rather than finish it.
**Migration**: `Failure.ocr` is removed from the failure vocabulary.

### Requirement: OCR accessibility, theming and layout
**Reason**: Text recognition was never shipped. The `ocr` feature had no screen, no on-device recogniser, no registered database table, and no consumer: the searchable-PDF lookup always returned nothing and search never produced a recognised-text match. The product decision (2026-11-10) is to remove OCR rather than finish it.
**Migration**: None. No OCR screen existed.
