## MODIFIED Requirements

### Requirement: Camera capture
The application SHALL open the device camera when the user adds a page from the camera, and SHALL allow the user to capture a page that is then taken through crop and enhancement before it joins the page table.

#### Scenario: Camera opens
- **WHEN** the user chooses the camera source from the page table and camera permission is granted
- **THEN** the camera capture screen with key `scan_camera_screen` is displayed with a live preview and a shutter control with key `scan_shutter_button`

#### Scenario: Single page capture
- **WHEN** the user captures one page
- **THEN** the crop and rotate screen is displayed for that capture

#### Scenario: Camera released after capture
- **WHEN** the user leaves the camera capture screen by any path
- **THEN** the camera resource is released

### Requirement: Manual edge adjustment and perspective correction
The application SHALL allow the user to adjust the detected edges manually and to rotate the page freely, and SHALL apply perspective correction so that the selected region is rendered as a rectangular page.

#### Scenario: Manual adjustment
- **WHEN** the user drags a corner handle of the edge overlay on the crop screen with key `scan_crop_screen`
- **THEN** the crop quadrilateral updates to follow the handle and the preview reflects the new region

#### Scenario: Perspective correction applied
- **WHEN** the user applies a crop whose quadrilateral is not rectangular
- **THEN** perspective correction is applied so the resulting page image is rectangular and deskewed

#### Scenario: Correction runs off the UI thread
- **WHEN** perspective correction is applied to a page
- **THEN** the work runs in a background isolate and the UI remains responsive with a progress state displayed

#### Scenario: Rotation applied with the crop
- **WHEN** the user rotates the page and then applies the crop
- **THEN** the rotation is baked into the resulting image

## ADDED Requirements

### Requirement: Crop applies in place and is repeatable
Applying a crop SHALL replace the working image on the crop screen with the cropped result and SHALL NOT navigate away, so that the user can crop the result again as many times as they wish.

#### Scenario: Apply replaces the image in place
- **WHEN** the user activates the apply control with key `scan_crop_apply_button`
- **THEN** the crop screen remains displayed, showing the cropped image as its working image

#### Scenario: View resets after applying
- **WHEN** a crop has been applied
- **THEN** the rotation control returns to 0 degrees and the selection covers the whole of the new working image

#### Scenario: Crop again
- **WHEN** the user adjusts the selection on the already-cropped working image and applies again
- **THEN** the working image becomes the result of cropping the current working image, and the screen stays on the crop screen

#### Scenario: Apply disabled when nothing would change
- **WHEN** the selection covers the whole working image and the rotation is 0 degrees
- **THEN** the apply control is disabled

#### Scenario: Apply failure keeps the working image
- **WHEN** applying a crop fails
- **THEN** an error message with a retry control is displayed and the working image is unchanged

### Requirement: Revert to the original image
The crop screen SHALL offer a revert control, positioned below the apply control, that discards every crop and rotation applied to the page and returns it to the full original frame. Reverting SHALL NOT change the page's enhancement. The crop screen SHALL NOT offer an undo control.

#### Scenario: Revert control present
- **WHEN** the crop screen is displayed
- **THEN** a revert control with key `scan_crop_revert_button`, labelled to name the crop layer it affects, is displayed below the apply control

#### Scenario: Revert restores the full original frame
- **WHEN** the user has applied one or more crops and activates the revert control
- **THEN** the page returns to the full original frame, the rotation returns to 0 degrees and the selection covers the whole image

#### Scenario: Revert keeps the enhancement
- **WHEN** the user has enhanced a page and then reverts its crop
- **THEN** the full original frame is shown with that enhancement still applied, and the enhancement settings are unchanged

#### Scenario: Revert disabled when no crop has been applied
- **WHEN** the page has no crop or rotation applied
- **THEN** the revert control is disabled

#### Scenario: No undo control
- **WHEN** the crop screen is displayed
- **THEN** no undo control is present

### Requirement: Continuing from crop to enhancement
The crop screen SHALL offer a Next control that is the only path from cropping to enhancement.

#### Scenario: Next control present
- **WHEN** the crop screen is displayed
- **THEN** a next control with key `scan_crop_next_button` is displayed in the navigation bar

#### Scenario: Next opens enhancement
- **WHEN** the user activates the next control with no unapplied changes
- **THEN** the enhancement screen is displayed for the current working image

#### Scenario: Apply does not continue
- **WHEN** the user activates the apply control
- **THEN** the enhancement screen is not displayed

### Requirement: Prompt for unapplied crop changes
When the user activates Next while the rotation or the selection has been changed without being applied, the application SHALL ask whether to apply those changes before continuing.

#### Scenario: Prompt shown
- **WHEN** the user has changed the rotation or moved the selection without applying, and activates the next control
- **THEN** a prompt with key `scan_crop_apply_prompt` asks whether to apply the crop changes and continue, offering a confirm control with key `scan_crop_prompt_apply` and a decline control with key `scan_crop_prompt_skip`

#### Scenario: Confirming applies then continues
- **WHEN** the user confirms the prompt
- **THEN** the crop is applied to the working image and the enhancement screen is then displayed for the applied result

#### Scenario: Declining continues without applying
- **WHEN** the user declines the prompt
- **THEN** the crop is not applied and the enhancement screen is displayed for the working image as it was before the unapplied changes

#### Scenario: Dismissing the prompt stays on crop
- **WHEN** the user dismisses the prompt without choosing
- **THEN** the crop screen remains displayed with the unapplied changes intact

#### Scenario: No prompt without unapplied changes
- **WHEN** the user activates the next control having applied every change they made
- **THEN** no prompt is shown and the enhancement screen is displayed immediately

### Requirement: Crop and enhancement are independent layers over one original
A page SHALL be held as an untouched original image plus two independent layers — its crop and rotation, and its enhancement settings. Every image shown for that page SHALL be produced by applying the crop layer to the original and then the enhancement layer, and changing either layer SHALL leave the other untouched.

#### Scenario: Reopening crop shows the current state
- **WHEN** the user opens crop for a page that was cropped in an earlier visit
- **THEN** the page is shown as it currently is — cropped, and with its enhancement applied — rather than as the raw original

#### Scenario: Crop screen shows the enhanced image
- **WHEN** the crop screen is displayed for a page that has been enhanced
- **THEN** the image shown carries that enhancement, so it matches the page's row in the page table

#### Scenario: Cropping does not disturb enhancement
- **WHEN** the user applies a further crop to an enhanced page
- **THEN** the enhancement settings are unchanged and are re-applied to the newly cropped result

#### Scenario: No quality loss from repeated cropping
- **WHEN** the user applies three successive crops to a page
- **THEN** the result is produced by resampling the original image once, and is not degraded relative to reaching the same region in a single crop

#### Scenario: Original retained for the session
- **WHEN** a page has been cropped or enhanced
- **THEN** the original image is retained until the creation session ends, so either layer can be reverted at any time

#### Scenario: Original discarded after saving
- **WHEN** the document has been saved
- **THEN** the original image is deleted, and page-level editing of the saved document works from the PDF

## REMOVED Requirements

### Requirement: Multi-page and batch scanning
**Reason**: Every captured page now goes through crop and then enhancement before becoming a row in the page table, so a batch mode that captures consecutively without an intermediate step no longer has a place in the flow. Multi-page documents are built by adding pages to the page table.
**Migration**: Users capture several pages by adding a page repeatedly from the page table screen; the resulting document is identical. The `scan_batch_mode_toggle` control and the `scan_page_counter` on the camera screen are removed; the page count is visible as the number of rows in the page table.

### Requirement: Page management
**Reason**: Rotating, reordering and deleting pages moved out of the scanning flow's review screen and into the page table, which is now the single place a document's pages are managed regardless of whether they came from the camera, the photo library or a share.
**Migration**: The same operations are specified by the `page-table-creation` capability, against keys `creation_page_list`, `creation_drag_handle`, `creation_row_crop_button`, `creation_row_enhance_button` and `creation_row_delete_button`. Rotation is now performed on the crop screen rather than by a per-row rotate control.
