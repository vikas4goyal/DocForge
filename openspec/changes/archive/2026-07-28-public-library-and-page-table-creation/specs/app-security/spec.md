## MODIFIED Requirements

### Requirement: Local-only document storage
The application SHALL store all documents, page images and recognised text on the device only, and SHALL never upload them automatically. Finished PDFs SHALL be written to a user-visible folder so the user can reach their own documents from the file browser and from other applications; everything else SHALL be written to app-private storage.

#### Scenario: No automatic upload
- **WHEN** documents are created, edited or opened
- **THEN** no document content is transmitted off the device by the application

#### Scenario: Finished PDFs are user-visible by design
- **WHEN** a PDF is saved
- **THEN** it is written to the application's folder in user-visible storage, where the operating system's file browser and other applications can reach it

#### Scenario: Everything else is app-private
- **WHEN** a page image, thumbnail, recognised text, database file or stored password is persisted
- **THEN** it is written to app-private storage that is not readable by other applications, and never to the user-visible folder

#### Scenario: Content leaves only by explicit user action
- **WHEN** document content is transmitted anywhere off the device
- **THEN** it does so only as the direct result of a user-initiated share, export or print action

#### Scenario: The user is told what is visible
- **WHEN** the user opens the settings screen
- **THEN** it states that saved PDFs are stored in a folder other applications can see, and that password-protected PDFs cannot be read without their password

### Requirement: Secure handling of PDF passwords
PDF passwords SHALL be stored only in secure storage, SHALL never be logged, and SHALL not be included when a document is shared. A password SHALL apply to a single document and SHALL be chosen by the user.

#### Scenario: Password stored securely
- **WHEN** a PDF password is retained
- **THEN** it is written to secure storage only, and never to preferences, the database or application logs

#### Scenario: One password per document
- **WHEN** the user protects two documents
- **THEN** each has its own password, and no application-wide or shared password exists

#### Scenario: Password not shared
- **WHEN** a protected document is shared or exported
- **THEN** the file retains its protection and the password is not included in the shared content

#### Scenario: Password removed with the document
- **WHEN** a document is permanently removed
- **THEN** any stored password for it is deleted from secure storage

## ADDED Requirements

### Requirement: Setting a document password at creation
The application SHALL allow the user to password-protect a document at the moment they save it, and SHALL require the password to be confirmed by re-entry before it is applied.

#### Scenario: Protection offered at save
- **WHEN** the user is naming a document before saving it
- **THEN** a password-protection option is offered and is off by default

#### Scenario: Confirmation required
- **WHEN** the user enables password protection
- **THEN** both a password field and a confirm-password field must be filled identically before the document can be saved

#### Scenario: Mismatch blocks saving
- **WHEN** the password and its confirmation differ
- **THEN** saving is refused with a message stating that the passwords do not match, and no file is written

#### Scenario: Password obscured
- **WHEN** the password and confirmation fields are displayed
- **THEN** their contents are obscured, and they are excluded from screenshots and from autofill save prompts

#### Scenario: Protection is honoured outside the application
- **WHEN** a protected document is opened in another application
- **THEN** that application requires the password the user set

#### Scenario: No re-prompt inside the application
- **WHEN** the user opens a document they protected
- **THEN** it opens without prompting, because the password was stored in secure storage when it was set
