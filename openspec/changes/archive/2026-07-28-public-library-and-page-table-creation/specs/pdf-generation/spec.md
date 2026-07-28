## MODIFIED Requirements

### Requirement: Document saving and naming
Saving a document SHALL write the PDF into the currently open folder of the library folder, create the document record, and name the document according to the default file-naming setting while allowing the user to override the name.

#### Scenario: Document saved
- **WHEN** the user activates the save control with key `creation_save_confirm_button`
- **THEN** the PDF is written into the currently open folder of the library folder, a document record is created with title, creation date, modified date, page count, file size and folder path, and the user is returned to that folder

#### Scenario: Default name applied
- **WHEN** the save dialog opens
- **THEN** the name field is prefilled from the configured default file-naming pattern

#### Scenario: Name overridden
- **WHEN** the user edits the name in the field with key `creation_save_name_field` before saving
- **THEN** the entered name is used as both the document title and the file name

#### Scenario: File name matches the title
- **WHEN** a document has been saved
- **THEN** the file in the library folder is named after the document title with a `.pdf` extension

#### Scenario: Document appears in the dashboard
- **WHEN** saving completes and the user is returned to the dashboard
- **THEN** the new document appears in the folder it was saved into and at the top of the recent documents section

#### Scenario: Saved document is visible outside the application
- **WHEN** saving completes
- **THEN** the file is present in the operating system's file browser under the same folder path and name, without any further action by the user

## ADDED Requirements

### Requirement: Optional encryption at generation
PDF generation SHALL encrypt the document with a user-supplied password when the user asks for password protection at save time.

#### Scenario: Encrypted output produced
- **WHEN** the user saves with password protection enabled and a confirmed password
- **THEN** the written PDF is encrypted with that password using the application's PDF encryption, and opening it in another application requires that password

#### Scenario: Password stored for in-application use
- **WHEN** a document is saved with password protection
- **THEN** the password is stored in secure storage against that document, and never in preferences or in the database

#### Scenario: Unprotected by default
- **WHEN** the user saves without enabling password protection
- **THEN** the written PDF is not encrypted and opens without a password

#### Scenario: Encryption failure
- **WHEN** encryption fails
- **THEN** no file is left in the library folder, an error message with a retry control is displayed, and the creation session and its pages are retained

### Requirement: Session cleanup after generation
Generating a document SHALL delete every image the session used — originals, cached renders and thumbnails — once the PDF has been written and verified, so that the PDF is the only remaining representation of the document.

#### Scenario: Page images deleted
- **WHEN** the PDF has been written successfully
- **THEN** every original page image and every cached render belonging to that session is deleted from storage

#### Scenario: Nothing is retained but the PDF
- **WHEN** the session has been cleaned up
- **THEN** no image belonging to the document remains in storage, and its thumbnails are re-derived from the PDF when they are next needed

#### Scenario: Nothing deleted on failure
- **WHEN** generating or writing the PDF fails
- **THEN** no page image is deleted and the user can retry from the same session

## REMOVED Requirements

### Requirement: Document preview before saving
**Reason**: The page table is itself a continuous preview of the document, showing every page in order as it will appear in the PDF, so a separate preview step at the end of the flow duplicates what the user has been looking at throughout.
**Migration**: The `pdf_preview_screen` and the `pdf_save_button` are removed. The page table screen with key `creation_page_table_screen` shows every page, and saving starts from the control with key `creation_save_button` in its navigation bar. Reviewing a page before saving is done by opening it from its row.
