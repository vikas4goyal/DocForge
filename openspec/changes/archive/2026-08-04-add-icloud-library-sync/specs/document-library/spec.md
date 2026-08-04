## ADDED Requirements

### Requirement: Cloud-backed library entries
On iOS with iCloud selected, the library SHALL distinguish remote-only, downloading, locally available, and failed cloud content without treating an undownloaded payload as a missing document.

#### Scenario: Remote-only entry remains actionable
- **WHEN** a reconciled PDF is remote-only
- **THEN** its document row remains navigable and exposes `document_cloud_status_<document-id>` with the current availability

#### Scenario: Byte-reading operation waits for download
- **WHEN** a thumbnail, viewer, editor, share, print, or OCR operation needs a remote-only PDF
- **THEN** the operation invokes the injected download use case, reports bounded progress, and reads bytes only after the platform confirms availability

#### Scenario: Password-protected PDF on a new device
- **WHEN** a protected PDF is discovered but its password is absent from that device's secure storage
- **THEN** the PDF remains visible and prompts for its password when opened rather than synchronizing or fabricating a credential

#### Scenario: Device-local metadata limitation
- **WHEN** a PDF is first discovered on another device
- **THEN** DocScanly reconstructs metadata available from the folder and PDF but does not claim that unsynchronized favourites, archive state, OCR text, or custom ordering transferred

### Requirement: Library remains usable during cloud conditions
The library SHALL preserve local-first operations for downloaded content and SHALL clearly constrain operations that require unavailable remote bytes.

#### Scenario: Downloaded document while offline
- **WHEN** the device is offline and a cloud-backed document is downloaded
- **THEN** supported browse, view, edit, folder, Trash, restore, and purge operations continue locally and pending cloud synchronization is indicated

#### Scenario: Remote-only document while offline
- **WHEN** the device is offline and a cloud-backed document is remote-only
- **THEN** its row remains visible and the requested byte-reading action shows a retryable download-required state

#### Scenario: Android behavior remains local
- **WHEN** the library runs on Android
- **THEN** all library and folder operations continue against MediaStore-backed `Documents/DocScanly` with no iCloud controls or network request

#### Scenario: Cloud item presentation variants
- **WHEN** document rows and dashboard tiles preview remote, downloading, available, and failed states in light or dark mode on phone or tablet
- **THEN** status is accessible, bounded, and does not cause clipping, overflow, or eager payload loading
