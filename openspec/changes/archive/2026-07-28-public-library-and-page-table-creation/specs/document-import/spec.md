## MODIFIED Requirements

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
- **WHEN** another application sends a PDF to DocForge
- **THEN** the PDF is copied into the library's root folder, a document record is created, and the document is opened

#### Scenario: Images received
- **WHEN** another application sends one or more images to DocForge
- **THEN** a creation session is started with those images as rows in the page table, where they can be cropped, enhanced, reordered and saved

#### Scenario: Share received while another flow is open
- **WHEN** content is shared to DocForge while the user is in another part of the application
- **THEN** the content is not dropped, and the user is taken to the appropriate import result once the current action allows it

#### Scenario: Unsupported type received
- **WHEN** another application sends a file that is neither a PDF nor a supported image
- **THEN** a message explains that the file type is not supported and nothing is added to the library
