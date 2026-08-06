## MODIFIED Requirements

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
