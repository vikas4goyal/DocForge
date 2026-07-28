## ADDED Requirements

### Requirement: Public document folder
The application SHALL store every saved PDF in a folder tree named `DocForge` in user-visible storage, so that saved documents are reachable from the operating system's file browser and from other applications without any further action by the user.

#### Scenario: Folder exists on first launch
- **WHEN** the application starts for the first time
- **THEN** a folder named `DocForge` exists in user-visible storage and is empty

#### Scenario: Visible on iOS
- **WHEN** a document has been saved and the user opens the iOS Files app
- **THEN** the PDF is listed under "On My iPhone → Doc Forge → DocForge" with the name the user gave it

#### Scenario: Visible on Android
- **WHEN** a document has been saved and the user opens any file manager
- **THEN** the PDF is listed under `Documents/DocForge` with the name the user gave it

#### Scenario: Readable by other applications
- **WHEN** another application opens the saved PDF from the file browser
- **THEN** the file opens and its contents are the document the user created

#### Scenario: No permission prompt
- **WHEN** the application creates, reads, renames or deletes a file inside `DocForge`
- **THEN** no storage permission prompt and no folder-picker prompt is shown to the user

### Requirement: Private working storage
The application SHALL keep its index, thumbnails, recognised text, passwords and in-progress captures in app-private storage that is never exposed by the public folder.

#### Scenario: Index is not exposed
- **WHEN** the user browses `DocForge` from the file browser
- **THEN** the database, thumbnail cache, recognised text and any stored passwords are not present anywhere in the browsable tree

#### Scenario: Only PDFs and folders are exposed
- **WHEN** the user browses `DocForge` from the file browser
- **THEN** only PDF files and folders the user created are present

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
The application SHALL reconcile its index with the contents of the public folder on launch and on resume, so that changes made outside the application are reflected inside it.

Reconciliation is asymmetric on Android, and deliberately so. Android publishes the library through MediaStore, which returns only the rows the writing package owns: DocForge therefore sees its own files change or disappear, and sees directories however they were made, but never sees a file another application put there. Making those files visible would require either `MANAGE_EXTERNAL_STORAGE`, which Google Play restricts to file managers and backup tools, or moving the whole Android store onto the Storage Access Framework, which costs a one-time folder grant the design set out to avoid (D2). The gap is recorded rather than hidden because it also means a document written before an uninstall, or restored from a backup, is on disk but outside the application's view.

#### Scenario: File added externally (iOS)
- **WHEN** a PDF is placed into `DocForge` by another application on iOS and DocForge is resumed
- **THEN** the document appears in the dashboard with a page count and file size read from the file

#### Scenario: File added externally (Android)
- **WHEN** a PDF is placed into `DocForge` by another application on Android and DocForge is resumed
- **THEN** the document does NOT appear in the dashboard, because Android returns only the MediaStore rows the application itself owns and denies direct filesystem reads of another application's files
- **AND** the user reaches such a PDF through the import action instead, which copies it into the library under the application's own ownership

#### Scenario: File removed externally
- **WHEN** a PDF is deleted from `DocForge` by another application and DocForge is resumed
- **THEN** the document no longer appears in the dashboard and its index entry, thumbnails and recognised text are removed

#### Scenario: Folder added externally
- **WHEN** a folder is created inside `DocForge` by another application and DocForge is resumed
- **THEN** the folder appears in the dashboard and can be opened
- **AND** on Android it opens empty unless the files inside it were written by DocForge, for the reason given above

#### Scenario: Renamed file keeps its metadata
- **WHEN** a PDF inside `DocForge` is renamed by another application and DocForge is resumed
- **THEN** the document appears under its new name and retains its favourite status, archive status and recognised text

#### Scenario: Reconciliation is throttled
- **WHEN** the application is resumed twice within one minute
- **THEN** the folder tree is walked at most once

#### Scenario: Reconciliation runs off the UI thread
- **WHEN** reconciliation runs over a tree containing several thousand files
- **THEN** the walk runs in a background isolate and the user interface remains responsive

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
