## MODIFIED Requirements

### Requirement: Local-first and user-controlled document storage
The application SHALL keep private working data on the device and SHALL transmit finished PDFs to iCloud only after the user selects iCloud Drive or when continuing an already established app-owned iCloud library. Finished PDFs SHALL remain user-visible in the selected storage location; page images, thumbnails, recognised text, the Isar database, and stored passwords SHALL remain app-private and device-local.

#### Scenario: No automatic cloud opt-in
- **WHEN** an existing local user creates, edits, or opens documents without selecting iCloud
- **THEN** no document content is transmitted to iCloud by DocScanly

#### Scenario: User enables iCloud
- **WHEN** the user confirms migration to iCloud Drive
- **THEN** the application explains what will synchronize and copies only public library payloads after that confirmation

#### Scenario: Same-account established library continues
- **WHEN** a new device finds the valid marker for an established app-owned iCloud library
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
- **THEN** it does so through the selected iCloud library or a direct user-initiated share, export, or print action, as disclosed in Settings

#### Scenario: Sensitive values are absent from logs
- **WHEN** cloud availability, migration, reconciliation, download, or identity changes are logged for diagnostics
- **THEN** logs contain no document content, user-facing path/name, Apple identity token, PDF password, or secure-storage value

#### Scenario: The user is told what is visible
- **WHEN** the user opens the settings screen
- **THEN** it states where saved PDFs are stored, whether they synchronize with iCloud, which data remains local, and that password-protected PDFs cannot be read without their password
