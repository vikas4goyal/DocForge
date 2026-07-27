## ADDED Requirements

### Requirement: Page table screen
The application SHALL present PDF creation as a single screen containing an ordered table of pages, in which row 1 is page 1, row 2 is page 2 and so on through row n.

#### Scenario: Screen opened
- **WHEN** the user activates Create PDF
- **THEN** the page table screen with key `creation_page_table_screen` is displayed with a page list with key `creation_page_list`, an add-page control with key `creation_add_page_button`, and a save control with key `creation_save_button` in the navigation bar on the trailing side

#### Scenario: Rows are pages in order
- **WHEN** three pages have been added
- **THEN** the list shows three rows, each labelled with its page number from 1 to 3, in the order the pages will appear in the PDF

#### Scenario: Empty state
- **WHEN** the page table contains no pages
- **THEN** an empty state with key `creation_empty_state` invites the user to add a page from the camera or the photo library
- **AND** the save control is disabled

#### Scenario: Save disabled until a page exists
- **WHEN** the page table contains no pages
- **THEN** the save control is disabled and cannot be activated

### Requirement: Adding a page
The application SHALL allow the user to add a page from the device camera or from the photo library, and SHALL take each added image through crop and rotate, then enhancement, before it becomes a row.

#### Scenario: Sources offered
- **WHEN** the user activates the add-page control
- **THEN** a sheet with key `creation_add_page_sheet` offers a camera source with key `creation_add_from_camera` and a photo library source with key `creation_add_from_gallery`

#### Scenario: Add from camera
- **WHEN** the user captures a page with the camera
- **THEN** the crop and rotate screen is displayed for that capture
- **AND** on continuing, the enhancement screen is displayed
- **AND** on finishing enhancement, the page is appended as the last row of the table

#### Scenario: Add from photo library
- **WHEN** the user selects an image from the photo library
- **THEN** the crop and rotate screen is displayed for that image
- **AND** on continuing, the enhancement screen is displayed
- **AND** on finishing enhancement, the page is appended as the last row of the table

#### Scenario: Multiple images selected
- **WHEN** the user selects several images from the photo library at once
- **THEN** each image is taken through crop and then enhancement in selection order, and each becomes a row in that order

#### Scenario: Abandoning an addition
- **WHEN** the user leaves the crop or the enhancement screen without finishing
- **THEN** no row is added to the table and the table is left exactly as it was

#### Scenario: Camera permission denied
- **WHEN** the user chooses the camera source and camera permission has been denied
- **THEN** a permission-denied view explains why the permission is needed and offers a control that opens the system settings, and the page table remains intact behind it

### Requirement: Reordering pages
The application SHALL allow the user to change page order by dragging a row to a new position, and the resulting order SHALL be the order of pages in the generated PDF.

#### Scenario: Drag to reorder
- **WHEN** the user drags the row at position 3 to position 1 using the drag handle with key `creation_drag_handle`
- **THEN** that page becomes page 1, the previous pages 1 and 2 become pages 2 and 3, and every row's page number is renumbered immediately

#### Scenario: Order is preserved into the PDF
- **WHEN** the user reorders pages and then saves
- **THEN** the pages appear in the generated PDF in the order shown in the table

#### Scenario: Drag cancelled
- **WHEN** a drag ends outside the list
- **THEN** the order is unchanged

#### Scenario: Reordering is accessible without dragging
- **WHEN** a screen reader is in use
- **THEN** each row exposes move-up and move-down semantic actions that produce the same reordering as a drag

### Requirement: Per-row page actions
Each row SHALL offer crop and rotate, enhance and delete. Crop and enhance SHALL each act on their own layer of the page, leaving the other layer untouched, and each SHALL be revertible independently so that any edit can be redone from scratch.

#### Scenario: Actions present on every row
- **WHEN** the page table shows a row
- **THEN** that row offers a crop and rotate control with key `creation_row_crop_button`, an enhance control with key `creation_row_enhance_button` and a delete control with key `creation_row_delete_button`

#### Scenario: Crop reopens on the current state
- **WHEN** the user crops a page, returns to the table, and opens crop for that page again
- **THEN** the crop screen opens on the page as it currently is — cropped, with its enhancement applied — and offers the revert control to return to the full original frame

#### Scenario: Reverting the crop keeps the enhancement
- **WHEN** the user crops and enhances a page, then reverts the crop
- **THEN** the row shows the full original frame with the enhancement still applied

#### Scenario: Reverting the enhancement keeps the crop
- **WHEN** the user crops and enhances a page, then reverts the enhancement
- **THEN** the row shows the cropped page at its cropped size, unenhanced

#### Scenario: Crops do not compound
- **WHEN** the user crops a page to half its width, returns to the table, opens crop again and reverts to the original
- **THEN** the resulting page is the full original image

#### Scenario: Enhance reopens on the current state
- **WHEN** the user enhances a page, returns to the table, and opens enhance for that page again
- **THEN** the enhancement screen opens on the page at its current crop with the settings the user last chose, and the enhancement is not applied twice

#### Scenario: Finishing an action updates the row
- **WHEN** the user finishes cropping or enhancing a page
- **THEN** the row's thumbnail updates to reflect the result and the row keeps its position in the table

#### Scenario: Delete a page
- **WHEN** the user deletes a row
- **THEN** the page is removed, the remaining rows are renumbered, and the removal can be undone from the confirmation affordance

#### Scenario: Deleting the last page
- **WHEN** the user deletes the only remaining row
- **THEN** the empty state is displayed and the save control becomes disabled

### Requirement: Saving the document
Saving SHALL ask the user for a document name before anything is written, and SHALL offer Cancel and Save.

#### Scenario: Save dialog shown
- **WHEN** the user activates the save control
- **THEN** a dialog with key `creation_save_dialog` is displayed with a name field with key `creation_save_name_field`, a cancel control with key `creation_save_cancel_button` and a save control with key `creation_save_confirm_button`

#### Scenario: Name prefilled
- **WHEN** the save dialog opens
- **THEN** the name field is prefilled from the configured default file-naming pattern and is fully editable

#### Scenario: Cancel
- **WHEN** the user activates the cancel control
- **THEN** the dialog closes, no file is written, and the page table is unchanged with every page still present

#### Scenario: Save
- **WHEN** the user activates the save control with a valid name
- **THEN** the PDF is generated from the table's pages in their displayed order and written into the currently open folder under that name

#### Scenario: Empty name rejected
- **WHEN** the name field is empty or contains only whitespace
- **THEN** the save control is disabled and a validation message is shown

#### Scenario: Duplicate name
- **WHEN** the entered name matches a document that already exists in the target folder
- **THEN** the user is asked whether to replace it or choose another name, and nothing is overwritten without that confirmation

#### Scenario: Saving progress
- **WHEN** the PDF is being generated
- **THEN** a progress state is displayed, the dialog's controls are disabled, and the generation runs in a background isolate so the interface stays responsive

#### Scenario: Save failure
- **WHEN** generating or writing the PDF fails
- **THEN** an error message with a retry control is displayed, and the page table and all its pages are retained

#### Scenario: Session cleaned up after saving
- **WHEN** the PDF has been written successfully
- **THEN** every image belonging to the creation session — originals, cached renders and thumbnails — is deleted, and the user is returned to the folder containing the new document

### Requirement: Optional password protection at creation
The save dialog SHALL offer optional password protection for the document being created, and SHALL require the password to be entered twice identically before it is applied.

#### Scenario: Protection offered
- **WHEN** the save dialog is displayed
- **THEN** a password-protection toggle with key `creation_save_password_toggle` is present and is off by default

#### Scenario: Fields revealed
- **WHEN** the user turns the password-protection toggle on
- **THEN** a password field with key `creation_save_password_field` and a confirm-password field with key `creation_save_password_confirm_field` are displayed, both obscured

#### Scenario: Mismatch rejected
- **WHEN** the password and confirmation differ
- **THEN** the save control is disabled and a message states that the passwords do not match

#### Scenario: Empty password rejected
- **WHEN** the toggle is on and either field is empty
- **THEN** the save control is disabled

#### Scenario: Protected document produced
- **WHEN** the user saves with a matching password
- **THEN** the written PDF is encrypted with that password and cannot be opened by another application without it

#### Scenario: Password is per document
- **WHEN** the user creates two protected documents with different passwords
- **THEN** each document opens only with its own password, and no application-wide password exists

#### Scenario: No re-prompt inside the application
- **WHEN** the user opens a document they protected during creation
- **THEN** the document opens without prompting for the password, because the password was stored in secure storage when it was set

#### Scenario: Document marked as protected
- **WHEN** a protected document is listed
- **THEN** its row shows a protected indicator with key `document_protected_badge`

### Requirement: Abandoning a creation session
The application SHALL confirm before discarding a creation session that contains pages, and SHALL delete that session's page images once it is discarded.

#### Scenario: Confirmation on exit
- **WHEN** the user leaves the page table while it contains at least one page and nothing has been saved
- **THEN** a confirmation asks whether to discard the pages, offering discard and keep-editing

#### Scenario: Discard cleans up
- **WHEN** the user confirms discarding
- **THEN** every page image belonging to the session is deleted from storage and the user is returned to the dashboard

#### Scenario: Keep editing
- **WHEN** the user declines to discard
- **THEN** the page table is displayed unchanged with every page still present

#### Scenario: No confirmation when empty
- **WHEN** the user leaves the page table while it contains no pages
- **THEN** no confirmation is shown

### Requirement: Page table accessibility, theming, layout and offline behaviour
The page table screen SHALL meet the application's accessibility, dark mode, responsive layout and offline baselines.

#### Scenario: Screen reader support
- **WHEN** a screen reader is in use on the page table
- **THEN** each row announces its page number, and the crop, enhance, delete and drag controls each expose a semantics label naming the action and the page it applies to

#### Scenario: Dark mode
- **WHEN** the device is in dark mode
- **THEN** the page table, add-page sheet and save dialog render in the dark theme with contrast meeting the application's accessibility baseline

#### Scenario: Tablet layout
- **WHEN** the page table is displayed on a tablet
- **THEN** the extra width is used to show pages in a multi-column grid rather than stretching single-column rows

#### Scenario: Text scaling
- **WHEN** the largest supported text scale is in use
- **THEN** every control on the page table and in the save dialog remains reachable and no text is clipped

#### Scenario: Works offline
- **WHEN** the device has no network connection
- **THEN** adding pages, cropping, enhancing, reordering, deleting and saving all work normally
