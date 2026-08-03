# public-document-storage Specification

## Purpose

Define where DocForge keeps what it stores: finished PDFs in a user-visible `DocForge` folder that the operating system's file browser and other applications can reach, and everything else — index, thumbnails, recognised text, passwords, in-progress captures — in app-private storage. Covers folder-relative addressing, reconciliation with changes made outside the application, migration from the earlier app-private layout, and the failure modes of platform storage.
## Requirements
### Requirement: Public document folder
The application SHALL store every active saved PDF in the user-visible `DocForge` folder tree and SHALL move app-trashed payloads into a reserved namespace excluded from normal browsing and reconciliation.

#### Scenario: Folder exists on first launch
- **WHEN** the application starts for the first time
- **THEN** a folder named `DocForge` exists in user-visible storage and is empty

#### Scenario: Visible on iOS
- **WHEN** an active document has been saved and the user opens Files
- **THEN** the PDF is listed under “On My iPhone → Doc Forge → DocForge” with its user-facing name

#### Scenario: Visible on Android
- **WHEN** an active document has been saved and the user opens a file manager
- **THEN** the PDF is listed under `Documents/DocForge` with its user-facing name

#### Scenario: Trashed payload excluded
- **WHEN** a payload is in Trash
- **THEN** it is excluded from DocForge's active file listings, dashboard and reconciliation inputs, and the reserved namespace is not offered as a user folder

#### Scenario: Readable by other applications
- **WHEN** another application opens an active saved PDF from the file browser
- **THEN** it opens with the content the user created

#### Scenario: No permission prompt
- **WHEN** DocForge creates, reads, renames, trashes, restores or permanently removes its own content
- **THEN** no storage permission or folder-picker prompt is shown

### Requirement: Private working storage
The application SHALL keep its index, Trash manifests, thumbnails, recognised text, passwords and in-progress captures in app-private storage, while Trash payload bytes SHALL be isolated behind the public-storage abstraction and excluded from the active public tree.

#### Scenario: Index is not exposed
- **WHEN** the user browses `DocForge` from the file browser
- **THEN** the database, Trash manifests, thumbnails, recognised text and passwords are not present

#### Scenario: Only PDFs and folders are exposed
- **WHEN** the user browses active `DocForge` content
- **THEN** only active PDFs and folders are presented as library content

#### Scenario: Protected Trash item
- **WHEN** a password-protected document moves to Trash
- **THEN** its credential remains in secure storage until restore or permanent removal and is never copied into the public payload

### Requirement: Captured images are temporary
The application SHALL treat captured and imported page images as temporary working files, SHALL keep them in app-private storage, and SHALL delete them once they are no longer needed.

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
- **THEN** every image belonging to that session — originals, cached renders and thumbnails — is deleted, and the PDF plus the index metadata are all that remain

#### Scenario: Thumbnails are derived, not retained
- **WHEN** a document's thumbnail is needed for a list or a detail screen
- **THEN** it is rendered from the PDF into an evictable cache and reused from there, and a missing cached thumbnail is re-rendered rather than treated as a failure

#### Scenario: Cached thumbnails invalidated by a changed file
- **WHEN** a document's file changes
- **THEN** its cached thumbnails are discarded and re-rendered from the new file

### Requirement: Folder-relative addressing
The application SHALL address every document by its path relative to `DocForge` rather than by a device-local identifier, and SHALL keep that path in step with the file on disk.

#### Scenario: Path recorded on save
- **WHEN** a document is saved into a folder
- **THEN** its record stores the folder path relative to `DocForge` and the file name, and no absolute device path is persisted

#### Scenario: Move updates the file
- **WHEN** the user moves a document to a different folder inside the application
- **THEN** the file is moved in the public tree and its recorded path is updated in the same operation

#### Scenario: Path traversal rejected
- **WHEN** a document name or folder name would resolve outside `DocForge`
- **THEN** the operation is refused with a validation message and nothing is written

### Requirement: Reconciliation with external changes
The application SHALL reconcile active index records with active public-folder contents on launch/resume while excluding its reserved Trash payloads and treating external deletion separately from app-managed Trash.

Reconciliation remains asymmetric on Android because MediaStore visibility is ownership-scoped; Trash SHALL NOT broaden platform permissions.

#### Scenario: File added externally (iOS)
- **WHEN** a PDF is placed into active `DocForge` on iOS and DocForge resumes
- **THEN** it appears in the dashboard with metadata read from the file

#### Scenario: File added externally (Android)
- **WHEN** another application places a PDF in `DocForge` on Android and DocForge resumes
- **THEN** it does not appear when MediaStore does not expose the other owner's row, and the import action remains the supported path

#### Scenario: File removed externally
- **WHEN** an active PDF is deleted outside DocForge and DocForge resumes
- **THEN** it disappears and associated metadata is cleaned without creating a Trash entry or promising recovery

#### Scenario: Folder added externally
- **WHEN** a folder is created inside active `DocForge` by another application and DocForge resumes
- **THEN** the folder appears in the dashboard, while Android still shows only files visible through DocForge-owned MediaStore rows

#### Scenario: Trash payload is ignored
- **WHEN** reconciliation walks storage containing reserved Trash payloads
- **THEN** none are indexed as new active documents or folders

#### Scenario: Renamed file keeps its metadata
- **WHEN** an active PDF is renamed externally and DocForge resumes
- **THEN** it appears under its new name and retains favourite, archive and recognised text

#### Scenario: Reconciliation is throttled
- **WHEN** the app resumes twice within one minute
- **THEN** the active folder tree is walked at most once while expiry cleanup remains idempotent

#### Scenario: Reconciliation runs off the UI thread
- **WHEN** reconciliation handles several thousand files
- **THEN** traversal remains asynchronous and the UI responsive

### Requirement: Storage migration from the private layout
The application SHALL migrate documents stored under the previous app-private layout into the public folder exactly once, without losing any document.

#### Scenario: Existing documents migrated
- **WHEN** the application starts and finds documents in the previous layout
- **THEN** each document's PDF is copied into `DocForge`, verified, and only then removed from the old location, and its record is rewritten with the new path

#### Scenario: Migration runs once
- **WHEN** the application starts again after a successful migration
- **THEN** the migration does not run a second time

#### Scenario: Interrupted migration resumes
- **WHEN** migration is interrupted before completion and the application starts again
- **THEN** migration resumes, already-migrated documents are not duplicated, and no document is lost

#### Scenario: Missing source file
- **WHEN** a record in the previous layout points at a PDF that no longer exists
- **THEN** the record is removed from the index and migration continues with the remaining documents

### Requirement: Platform storage failures
The application SHALL present a clear message and a recovery action for every public-storage failure.

#### Scenario: Storage full while saving
- **WHEN** a PDF cannot be written because device storage is full
- **THEN** a storage-full message is displayed, the creation session and its pages are retained, and the user is offered the option to free space and retry

#### Scenario: Public folder unavailable
- **WHEN** the public folder cannot be created or opened
- **THEN** an error view is displayed explaining that documents cannot be saved, with a retry control, and the application does not crash

#### Scenario: Nested folders unsupported by the platform
- **WHEN** the platform refuses to create a nested folder inside `DocForge`
- **THEN** the document is saved into `DocForge` itself, its recorded folder is preserved in the index, and the user is told where the file was placed

