## MODIFIED Requirements

### Requirement: Public document folder
The application SHALL store every active saved PDF in the user-visible `DocScanly` folder tree and SHALL move app-trashed payloads into a reserved namespace excluded from normal browsing and active reconciliation.

#### Scenario: Folder exists on first launch
- **WHEN** the application starts for the first time without an established iCloud marker
- **THEN** a folder named `DocScanly` exists in device-local user-visible storage and is empty

#### Scenario: Visible in local iOS storage
- **WHEN** local storage is authoritative, an active document has been saved, and the user opens Files
- **THEN** the PDF is listed under “On My iPhone → DocScanly → DocScanly” with its user-facing name

#### Scenario: Visible in iCloud on iOS
- **WHEN** iCloud storage is authoritative, an active document has been saved, and the user opens Files
- **THEN** the PDF is listed directly under “iCloud Drive → DocScanly” with its user-facing name

#### Scenario: Visible on Android
- **WHEN** an active document has been saved and the user opens a file manager
- **THEN** the PDF is listed under `Documents/DocScanly` with its user-facing name

#### Scenario: Trashed payload excluded
- **WHEN** a payload is in Trash
- **THEN** it is excluded from DocScanly's active file listings, dashboard and active reconciliation inputs, and the reserved namespace is not offered as a user folder

#### Scenario: Readable by other applications
- **WHEN** another application opens an active saved PDF from the file browser
- **THEN** it opens with the content the user created

#### Scenario: No permission prompt for owned roots
- **WHEN** DocScanly creates, reads, renames, trashes, restores or permanently removes its own content in the selected local or app-owned iCloud root
- **THEN** no storage permission or folder-picker prompt is shown

### Requirement: Reconciliation with external changes
The application SHALL reconcile active index records with the authoritative public-folder contents on launch/resume and explicit refresh while excluding reserved Trash payloads, treating external deletion separately from app-managed Trash, and preserving remote-only iCloud records.

Reconciliation remains asymmetric on Android because MediaStore visibility is ownership-scoped; Trash and iCloud support SHALL NOT broaden platform permissions.

#### Scenario: File added externally (iOS)
- **WHEN** a PDF is placed into the authoritative local or app-owned iCloud `DocScanly` folder on iOS and DocScanly resumes
- **THEN** it appears in the dashboard with available file metadata whether or not its payload is downloaded

#### Scenario: File added externally (Android)
- **WHEN** another application places a PDF in `DocScanly` on Android and DocScanly resumes
- **THEN** it does not appear when MediaStore does not expose the other owner's row, and the import action remains the supported path

#### Scenario: File removed externally
- **WHEN** an active PDF is deleted outside DocScanly and DocScanly confirms the authoritative item is absent
- **THEN** it disappears and associated local metadata is cleaned without creating a Trash entry or promising recovery

#### Scenario: Folder added externally
- **WHEN** a folder is created inside the authoritative active `DocScanly` root by another application and DocScanly resumes
- **THEN** the folder appears in the dashboard, while Android still shows only files visible through DocScanly-owned MediaStore rows

#### Scenario: Trash payload is ignored
- **WHEN** reconciliation walks storage containing reserved Trash payloads
- **THEN** none are indexed as new active documents or folders

#### Scenario: Renamed file keeps available metadata
- **WHEN** an active PDF is renamed externally and DocScanly resumes
- **THEN** it appears under its new name and retains metadata that can be matched safely on that device

#### Scenario: Reconciliation is throttled
- **WHEN** the app resumes twice within one minute without a user refresh or identity change
- **THEN** the active folder tree is walked at most once while expiry cleanup remains idempotent

#### Scenario: Reconciliation runs off the UI thread
- **WHEN** reconciliation handles several thousand local, downloaded, or remote-only files
- **THEN** traversal remains asynchronous and bounded and the UI remains responsive

### Requirement: Storage migration from the private layout
The application SHALL migrate documents from prior private or public `DocForge` layouts into the selected `DocScanly` root exactly once per migration version, without losing any active or trashed document.

#### Scenario: Legacy DocForge content is migrated
- **WHEN** the application starts and finds content in a supported `DocForge` layout
- **THEN** each payload is copied into `DocScanly`, verified, and only then removed from the old location, and its record is rewritten with the new relative path

#### Scenario: Migration runs once
- **WHEN** the application starts again after a successful migration version
- **THEN** that migration does not run a second time

#### Scenario: Interrupted migration resumes
- **WHEN** migration is interrupted before completion and the application starts again
- **THEN** migration resumes, already-verified payloads are not duplicated, and no document is lost

#### Scenario: Missing source file
- **WHEN** a legacy record points at a PDF that no longer exists
- **THEN** the stale record is removed from the index and migration continues with the remaining documents

#### Scenario: Trash is migrated
- **WHEN** the legacy library contains recoverable Trash entries
- **THEN** their manifests, payloads, original relative paths, and expiry information remain recoverable after migration
