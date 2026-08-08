## MODIFIED Requirements

### Requirement: Captured images are temporary
The application SHALL treat captured and imported page images as temporary working files, SHALL keep them in app-private storage, SHALL delete them once no longer needed, and SHALL bound any reproducible PDF-derived page-preview cache.

#### Scenario: Deleted after a document is saved
- **WHEN** a PDF is written successfully from a creation session
- **THEN** every full-resolution page image belonging to that session is deleted from storage

#### Scenario: Deleted when creation is cancelled
- **WHEN** the user abandons a creation session without saving
- **THEN** every full-resolution page image belonging to that session is deleted from storage

#### Scenario: Orphans swept at startup
- **WHEN** the application starts and page images from a session that never completed are still present
- **THEN** those images are deleted before the first frame is shown and the sweep does not block the first frame for more than one animation frame

#### Scenario: Nothing but the PDF survives a save
- **WHEN** a document has been saved
- **THEN** every image belonging to that session—originals, cached renders, and thumbnails—is deleted, and the PDF plus index metadata are all that remain

#### Scenario: List thumbnails are derived
- **WHEN** a document thumbnail is needed for Dashboard or another library list
- **THEN** page 1 is rendered from the PDF into an evictable private cache and reused, and a missing cached thumbnail is re-rendered rather than treated as a failure

#### Scenario: Detail creates no page thumbnails
- **WHEN** the metadata-focused Detail screen opens
- **THEN** no PDF page is rasterized or added to a derived page-preview cache

#### Scenario: Explicit page previews are bounded
- **WHEN** page management, page-image sharing, OCR, or another explicit page consumer derives cached thumbnail previews
- **THEN** the private `document-pages` cache retains no more than 128 files or 64 MiB and removes least-recently-used reproducible entries before accepting work beyond either limit

#### Scenario: Evicted preview is regenerated
- **WHEN** an explicit page consumer requests a preview that cache pruning removed
- **THEN** the preview is rendered again from the authoritative PDF without data loss or a user-visible missing-page failure

#### Scenario: Active and authoritative files are not pruned
- **WHEN** cache maintenance runs concurrently with page materialisation
- **THEN** the requested target, authoritative PDF, stored source images, and files being produced by the current operation are not deleted

#### Scenario: Cached thumbnails invalidated by a changed file
- **WHEN** a document's PDF changes
- **THEN** its cached list and page previews are discarded and re-rendered from the new file

