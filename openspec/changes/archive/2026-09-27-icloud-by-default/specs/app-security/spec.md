## MODIFIED Requirements

### Requirement: Local-first and user-controlled document storage
The application SHALL keep private working data on the device. On iOS, it SHALL store finished PDFs in the app-owned iCloud library whenever that library is available, and SHALL disclose this on the storage-location screen and when an automatic migration completes. Finished PDFs SHALL remain user-visible in the authoritative storage location. Page images, thumbnails, recognised text, the Isar database, and stored passwords SHALL remain app-private and device-local.

#### Scenario: No automatic cloud opt-in
- **WHEN** a user without an available iCloud container creates, edits, or opens documents
- **THEN** no document content is transmitted to iCloud by DocScanly

#### Scenario: User enables iCloud
- **WHEN** the app-owned iCloud container is available
- **THEN** DocScanly stores and moves only public library payloads (PDFs, folders, and the reserved Trash tree) to that container, and `cloud_storage_status` discloses that documents are stored in iCloud Drive

#### Scenario: Automatic move is disclosed
- **WHEN** an automatic migration from the device to iCloud completes
- **THEN** `cloud_storage_migration_done` tells the user their documents are now in `iCloud Drive → DocScanly` before the library opens

#### Scenario: Same-account established library continues
- **WHEN** a device finds the valid marker for an established app-owned iCloud library
- **THEN** it uses that library and discloses its iCloud status without requiring a second folder grant

#### Scenario: Finished PDFs are user-visible by design
- **WHEN** a PDF is saved
- **THEN** it is written to the authoritative DocScanly folder where the operating system's file browser and other applications can reach it

#### Scenario: Everything else is app-private
- **WHEN** a page image, thumbnail, recognised text, database file or stored password is persisted
- **THEN** it is written to app-private device storage, never to the iCloud Documents container or public folder

#### Scenario: Passwords do not synchronize
- **WHEN** a password-protected PDF synchronizes to another device
- **THEN** no password accompanies it and the receiving device requests the password when required

#### Scenario: Content leaves through declared user control
- **WHEN** document content leaves the device
- **THEN** it does so through the app-owned iCloud library or a direct user-initiated share, export, or print action, as disclosed in Settings

#### Scenario: Sensitive values are absent from logs
- **WHEN** cloud availability, automatic migration, merge, reconciliation, download, or identity changes are logged for diagnostics
- **THEN** logs contain no document content, user-facing path/name, Apple identity token, PDF password, or secure-storage value

#### Scenario: The user is told what is visible
- **WHEN** the user opens the settings screen
- **THEN** it states where saved PDFs are stored, whether they synchronize with iCloud (and, during device fallback, why not), which data remains local, and that password-protected PDFs cannot be read without their password
