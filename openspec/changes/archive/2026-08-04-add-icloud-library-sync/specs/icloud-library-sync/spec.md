## ADDED Requirements

### Requirement: App-owned iCloud library
On iOS, the application SHALL access only the iCloud Documents container `iCloud.com.bruxkey.docscanly` for its automatic cloud library, SHALL present that container in Files as `DocScanly`, and SHALL NOT require CloudKit or iCloud Extended Share Access.

#### Scenario: iCloud library is created
- **WHEN** the user confirms iCloud Drive as the storage location and the container is available
- **THEN** the application creates its document scope and a valid versioned library marker, and Files presents it under `iCloud Drive → DocScanly`

#### Scenario: No redundant nested folder
- **WHEN** the app-owned container is opened in Files
- **THEN** the library contents appear directly within `DocScanly` rather than within `DocScanly/DocScanly`

#### Scenario: App-owned access requires no picker
- **WHEN** DocScanly reads or changes content in its registered iCloud container
- **THEN** no folder-picker or broad iCloud Drive permission prompt is shown

### Requirement: Automatic same-account discovery
The application SHALL recognize and select an established app-owned iCloud library on a new iOS device signed into the same Apple Account and SHALL rebuild its local Isar index from the container without requiring the user to select the folder again.

#### Scenario: New device discovers existing library
- **WHEN** DocScanly starts with no local storage-location preference and finds a valid marker in its registered container
- **THEN** it selects iCloud, displays reconciliation status, and indexes the existing folders and PDFs

#### Scenario: Empty established library is discovered
- **WHEN** the registered container has a valid marker but no active documents
- **THEN** DocScanly selects that iCloud library and displays its empty state rather than creating a separate local authority

#### Scenario: Different Apple Account
- **WHEN** the current iCloud identity cannot access the previously selected container
- **THEN** DocScanly displays an unavailable state with key `cloud_storage_unavailable` and semantics label “DocScanly iCloud library unavailable”, without switching roots or deleting local metadata

### Requirement: Explicit storage selection and safe migration
The application SHALL require confirmation before moving an existing library between local storage and iCloud, SHALL use copy–verify–switch–cleanup migration, and SHALL resume an interrupted migration without duplication or data loss.

#### Scenario: User selects iCloud
- **WHEN** the user activates `cloud_storage_icloud_option`, with semantics label “Use iCloud Drive for DocScanly documents”, while a local library exists
- **THEN** the screen shows `cloud_storage_migration_confirm` describing the item count, destination, synchronization effect, and that source deletion occurs only after verification

#### Scenario: Migration succeeds
- **WHEN** the user activates `cloud_storage_migration_confirm` and every active and reserved Trash payload is copied and verified
- **THEN** `cloud_storage_migration_progress` reaches completion, iCloud becomes the single authoritative root, and source cleanup begins only afterward

#### Scenario: Migration is interrupted
- **WHEN** the process stops during copying or verification
- **THEN** the source remains authoritative and the next attempt resumes verified checkpoints without duplicating documents

#### Scenario: Migration fails
- **WHEN** iCloud becomes unavailable, storage is insufficient, or verification fails
- **THEN** the previous root remains authoritative and controls `cloud_storage_retry` (“Retry iCloud migration”) and `cloud_storage_cancel` (“Cancel iCloud migration”) provide recoverable actions where safe

### Requirement: Cloud reconciliation and lazy download
The application SHALL reconcile iCloud metadata into the device-local index without eagerly downloading every PDF and SHALL download content before an operation that requires its bytes.

#### Scenario: Remote PDF is listed
- **WHEN** reconciliation finds a valid PDF whose bytes are not downloaded
- **THEN** it appears in the library with `document_cloud_status_<document-id>` announcing “Stored in iCloud” and remains a valid document record

#### Scenario: Remote PDF is opened
- **WHEN** the user opens a remote-only PDF
- **THEN** DocScanly starts its download, exposes `document_cloud_download_<document-id>` with semantics label “Downloading <title> from iCloud”, and opens the viewer after local bytes become readable

#### Scenario: Download fails
- **WHEN** a requested PDF cannot download
- **THEN** the document remains listed, shows a recoverable cloud failure, and neither its index record nor cloud payload is deleted

#### Scenario: Reconciliation trigger is bounded
- **WHEN** launch, resume, refresh, or an iCloud identity event requests reconciliation repeatedly
- **THEN** DocScanly debounces duplicate full scans, enumerates metadata asynchronously in bounded batches, and keeps the interface responsive

#### Scenario: User refreshes cloud state
- **WHEN** the user activates `library_cloud_refresh` with semantics label “Refresh DocScanly iCloud library”
- **THEN** one reconciliation runs and the visible status reflects its completion or recoverable failure

### Requirement: Cloud conflict preservation
The application SHALL coordinate iCloud file access and SHALL preserve every conflicting payload until the user can resolve it.

#### Scenario: Same-path conflict occurs
- **WHEN** two devices produce unresolved different payloads at the same relative path
- **THEN** DocScanly retains both under deterministic user-visible names and does not silently overwrite either payload

#### Scenario: External cloud deletion occurs
- **WHEN** a cloud PDF is deleted outside DocScanly and reconciliation confirms its absence
- **THEN** its local index and derived data are cleaned without creating an app-managed Trash promise

### Requirement: Manual iCloud folder import
The application SHALL treat a manually created same-named iCloud Drive folder as external content and SHALL import it only after explicit user selection.

#### Scenario: Same-named folder is not adopted
- **WHEN** a folder named `DocScanly` exists outside the registered app container
- **THEN** the application does not silently use or scan it as the authoritative library

#### Scenario: User imports an existing folder
- **WHEN** the user activates `cloud_storage_import_folder` with semantics label “Import an existing iCloud Drive folder” and selects a folder
- **THEN** supported folders and PDFs are copied through the normal import rules into the authoritative library and access to the external folder is released after the operation

### Requirement: Cloud storage presentation
The storage-location and cloud-status interfaces SHALL support screen readers, large text, light and dark themes, phone and tablet layouts, deterministic previews, and useful offline behavior.

#### Scenario: Storage location screen is accessible
- **WHEN** `cloud_storage_screen` is traversed with a screen reader
- **THEN** local and iCloud choices announce their current selection and availability and every confirmation, retry, cancel, import, and refresh control has the specified semantics label

#### Scenario: Responsive cloud states
- **WHEN** the storage screen displays loading, unavailable, error, migration, or long-content states on a phone or tablet in light or dark mode at a supported large text scale
- **THEN** content remains readable, scrollable, and free from clipping or overflow

#### Scenario: Offline with downloaded content
- **WHEN** iCloud has no network connectivity and a selected PDF is already downloaded
- **THEN** local reading and editing continue and pending synchronization is communicated without blocking the operation

#### Scenario: Offline with remote-only content
- **WHEN** iCloud has no network connectivity and a selected PDF is remote-only
- **THEN** the application explains that download is required and offers retry without reporting the PDF as lost

#### Scenario: End-to-end cloud coverage
- **WHEN** the `icloud_library_sync` end-to-end flow runs against its deterministic platform fixture
- **THEN** it drives storage selection, migration, relaunch/new-device discovery, remote download, unavailable recovery, and library refresh exclusively through the specified keys and semantics
