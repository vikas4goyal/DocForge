## ADDED Requirements

### Requirement: Import sources
The application SHALL allow the user to import content from the camera, the photo gallery, device files and the operating system share sheet.

#### Scenario: Import options presented
- **WHEN** the user opens the import options with key `import_options_sheet`
- **THEN** options for camera (`import_source_camera`), photo gallery (`import_source_gallery`) and device files (`import_source_files`) are presented

#### Scenario: Import from camera
- **WHEN** the user chooses the camera source
- **THEN** the scanning flow is started and its result is saved as a document

#### Scenario: Import from gallery
- **WHEN** the user selects one or more images from the photo gallery
- **THEN** the selected images become pages of a new document in selection order, and the user is taken to the review step where cropping and enhancement can be applied

#### Scenario: Import a PDF from device files
- **WHEN** the user selects a PDF from device files
- **THEN** the PDF is copied into app-private storage and a document record is created with the correct page count and file size

#### Scenario: Import images from device files
- **WHEN** the user selects one or more image files from device files
- **THEN** they become pages of a new document and are taken to the review step

### Requirement: Share-sheet import
The application SHALL appear as a destination in the operating system share sheet for PDFs and images, and SHALL import content shared to it.

#### Scenario: Content shared to the application while it is closed
- **WHEN** a PDF is shared to the application from another application and DocForge is not running
- **THEN** the application launches, imports the file, and presents the resulting document

#### Scenario: Content shared to the application while it is running
- **WHEN** an image is shared to the application while it is already running
- **THEN** the import is handled without restarting the application and the resulting document is presented

#### Scenario: Multiple files shared at once
- **WHEN** several files are shared to the application at once
- **THEN** each is imported and the user is told how many documents were created

### Requirement: Import permissions
The application SHALL request photo and file access only when the user chooses the corresponding import source, and SHALL provide a recovery path when access is denied.

#### Scenario: Permission requested just in time
- **WHEN** the user chooses the gallery source for the first time
- **THEN** the photo permission is requested at that moment, with a rationale, and not before

#### Scenario: Permission denied
- **WHEN** photo or file access is denied
- **THEN** a permission-denied view with key `import_permission_denied_view` explains why access is needed and offers a control that opens the system settings
- **AND** the other import sources remain usable

### Requirement: Import validation and error handling
The application SHALL validate imported content and SHALL present a clear message and a recovery action when an import fails.

#### Scenario: Unsupported file type
- **WHEN** the user selects a file that is neither a supported image nor a PDF
- **THEN** the file is rejected with a message naming the supported types, and no document record is created

#### Scenario: Corrupt file
- **WHEN** an imported file cannot be parsed
- **THEN** an error view with key `import_error_view` is displayed with a human-readable message and a retry control, no partial document is created, and the application does not crash

#### Scenario: Password-protected PDF imported
- **WHEN** the imported PDF is password-protected
- **THEN** the user is prompted for the password, and on cancellation the import is abandoned without creating a document

#### Scenario: Storage full during import
- **WHEN** an import cannot complete because device storage is full
- **THEN** a storage-full message with guidance to free space is displayed and no partial file remains

#### Scenario: Import cancelled
- **WHEN** the user cancels the source picker
- **THEN** no document is created and the application returns to the previous screen

### Requirement: Import performance
Importing SHALL run off the UI thread, report progress and be cancellable.

#### Scenario: Importing many files
- **WHEN** a large batch of images or a large PDF is imported
- **THEN** the work runs in a background isolate, a progress indicator with key `import_progress_indicator` reports progress, and a cancel control is available

#### Scenario: Cancelling an import
- **WHEN** the user cancels an in-progress import
- **THEN** processing stops and no partial document record or orphaned file is left behind

### Requirement: Import accessibility, theming, layout and offline behaviour
Import screens SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on import options
- **WHEN** a screen reader traverses the import options
- **THEN** each source exposes a semantics label describing where the content will come from

#### Scenario: Dark mode and tablet
- **WHEN** import screens are displayed in dark mode on a tablet-width viewport
- **THEN** they use the dark colour scheme and adapt to the wider viewport without clipping or overflow

#### Scenario: Importing offline
- **WHEN** the device has no network connection
- **THEN** imports from gallery, files and the share sheet complete successfully with no network request
