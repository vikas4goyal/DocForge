# document-import Specification

## Purpose

Define how content enters the application: from the camera, the photo gallery, device files and the operating system share sheet. Images enter through the page table so they can be cropped and enhanced; PDFs are copied into the library. Nothing outside the library folder is ever edited in place.

## Requirements

### Requirement: Import sources
The application SHALL allow the user to bring in content from the camera, the photo gallery, device files and the operating system share sheet. Images SHALL enter through the page table so they can be cropped and enhanced; PDFs SHALL be copied into the currently open folder of the library.

#### Scenario: Image sources reached from the page table
- **WHEN** the user activates the add-page control with key `creation_add_page_button`
- **THEN** a camera source with key `creation_add_from_camera` and a photo library source with key `creation_add_from_gallery` are offered

#### Scenario: Import from camera
- **WHEN** the user chooses the camera source
- **THEN** the capture is taken through crop and then enhancement and becomes a row in the page table

#### Scenario: Import from gallery
- **WHEN** the user selects one or more images from the photo gallery
- **THEN** each selected image is taken through crop and then enhancement in selection order, and each becomes a row in the page table

#### Scenario: Import a PDF from device files
- **WHEN** the user selects a PDF from device files using the import-PDF action with key `dashboard_import_pdf_button`
- **THEN** the PDF is copied into the currently open folder of the library, and a document record is created with the correct page count and file size

#### Scenario: Import images from device files
- **WHEN** the user selects one or more image files from device files
- **THEN** a creation session is started containing those images as rows in the page table

#### Scenario: Nothing is edited in place
- **WHEN** any file is imported
- **THEN** the source file outside the library folder is neither modified nor deleted, and the application retains no long-lived grant to it

### Requirement: Share-sheet import
The application SHALL accept PDFs and images sent to it from other applications, and SHALL route them through the same paths as an in-application import.

#### Scenario: PDF received
- **WHEN** another application sends a PDF to DocScanly
- **THEN** the PDF is copied into the library's root folder, a document record is created, and the document is opened

#### Scenario: Images received
- **WHEN** another application sends one or more images to DocScanly
- **THEN** a creation session is started with those images as rows in the page table, where they can be cropped, enhanced, reordered and saved

#### Scenario: Share received while another flow is open
- **WHEN** content is shared to DocScanly while the user is in another part of the application
- **THEN** the content is not dropped, and the user is taken to the appropriate import result once the current action allows it

#### Scenario: Unsupported type received
- **WHEN** another application sends a file that is neither a PDF nor a supported image
- **THEN** a message explains that the file type is not supported and nothing is added to the library

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

### Requirement: Imported PDF page capability
Every successfully imported PDF SHALL expose its complete page sequence through stable document-and-page-derived identities and SHALL allow each page to be rendered lazily from the authoritative local PDF without requiring permanent page-image rows.

#### Scenario: Imported pages are addressable
- **WHEN** a PDF import completes with a valid page count
- **THEN** page consumers can enumerate exactly that many ordered page handles whose identities remain stable across application launches

#### Scenario: Imported page renders on demand
- **WHEN** Viewer, Editor, OCR, Sharing, or another explicit page consumer requests an imported PDF page
- **THEN** that page is rendered from the copied library PDF at the bounded resolution required by the consumer

#### Scenario: No eager raster duplication
- **WHEN** a large PDF is imported
- **THEN** import does not permanently rasterize every page, and any derived thumbnails or working images remain private reclaimable cache artifacts

#### Scenario: Protected imported page
- **WHEN** page access requires a password-protected imported PDF
- **THEN** it resolves the credential through secure storage, does not persist or log the password elsewhere, and returns a typed locked failure when no valid credential is available

#### Scenario: Imported PDF consistency
- **WHEN** the dashboard can show a first-page thumbnail for an imported PDF
- **THEN** Viewer, Editor, image sharing, and text extraction address the same authoritative PDF pages rather than reporting that page content no longer exists

#### Scenario: Imported page access is offline and responsive
- **WHEN** page access runs offline on a phone or tablet in light or dark mode
- **THEN** no network request occurs, rendering remains bounded, and progress or stable placeholders keep the requesting screen responsive

#### Scenario: End-to-end imported page coverage
- **WHEN** the `import` end-to-end flow imports a multi-page text PDF and opens it through `browse_and_view`
- **THEN** the flow observes a matching Dashboard preview and can open, edit, share images, and request text from the imported document

### Requirement: User-driven camera creation and reversible processing
Camera document creation SHALL show a live preview before capture, SHALL capture only from an explicit shutter action, and SHALL preserve reversible Crop and Enhance navigation with responsive manipulation controls.

#### Scenario: Camera does not capture automatically
- **WHEN** the user opens camera document creation
- **THEN** the live camera preview remains visible and no photo is captured until `Key('camera_shutter_button')` is activated

#### Scenario: Enhance Back returns to Crop
- **WHEN** the user advances from Crop to Enhance and activates Back
- **THEN** the same image and crop state are restored on Crop instead of closing document creation

#### Scenario: Flip previews immediately
- **WHEN** the user activates the Crop flip control
- **THEN** the crop preview updates immediately before Apply and the saved result matches that preview

#### Scenario: Crop handles are forgiving and smooth
- **WHEN** the user starts near a visible crop corner or edge and drags
- **THEN** a larger accessible hit region acquires that handle and its preview follows continuous movement without requiring pixel-precise initial contact

#### Scenario: Compact confirmation titles
- **WHEN** Crop, Enhance, confirmation, or naming appears on a phone or supported large text scale
- **THEN** its title uses compact bounded typography and does not displace navigation actions

### Requirement: Dedicated multi-page naming screen
Naming page-derived outputs SHALL use a dedicated scrollable screen rather than a popup and SHALL make cancellation and completion explicit in the header.

#### Scenario: Naming screen structure
- **WHEN** captured pages require individual output names
- **THEN** `Key('page_naming_screen')` shows Cancel/close in the leading header, Done/check in the trailing header, and ordered Page 1, Page 2, and later sections with preview and editable name

#### Scenario: Complete page naming
- **WHEN** every visible page has a valid collision-safe name and the user activates `Key('page_naming_done')`
- **THEN** each intended output is created exactly once using its reviewed name

#### Scenario: Cancel page naming
- **WHEN** the user activates `Key('page_naming_cancel')`
- **THEN** the screen closes without creating any output
