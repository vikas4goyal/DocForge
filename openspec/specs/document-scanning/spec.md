# document-scanning Specification

## Purpose

Define capturing and cropping a page: the camera screen, manual edge adjustment with perspective correction, crop applied in place and repeatable over its own result, reverting to the full original frame, and the single Next path from cropping to enhancement. A page is held as an untouched original plus two independent layers — crop and rotation, and enhancement — so either can be changed or reverted without disturbing the other.

## Requirements

### Requirement: Camera capture
The application SHALL open the device camera when the user adds a page from the camera, SHALL initialize it with the selected resolution when supported or the active camera's highest full supported resolution by default, and SHALL allow the user to capture a page that is then taken through crop and enhancement before it joins the page table.

#### Scenario: Camera opens at default full resolution
- **WHEN** the user chooses the camera source from the page table, camera permission is granted, and no resolution preference exists
- **THEN** `Key('scan_camera_screen')` is displayed with `scan_shutter_button` and the active camera is initialized at its highest full supported still-image resolution

#### Scenario: Camera opens at selected supported resolution
- **WHEN** the user has selected a supported resolution tier and chooses the camera source
- **THEN** the camera requests the matching supported dimensions and exposes the resolved tier and dimensions through accessible capture-status text

#### Scenario: Selected resolution is unsupported
- **WHEN** the active camera cannot satisfy the saved resolution tier
- **THEN** capture visibly falls back to the highest supported resolution at or below that tier, or the camera's highest supported resolution when no lower match exists

#### Scenario: Single page capture
- **WHEN** the user captures one page
- **THEN** the captured original retains the actual camera output dimensions and the crop and rotate screen is displayed for that capture

#### Scenario: Add another page uses current resolution
- **WHEN** the user returns from the page table to capture another camera page
- **THEN** the current supported resolution preference is resolved again for the active camera and applied before capture

#### Scenario: Capture resolution is independent of PDF quality
- **WHEN** the camera captures a page at Full resolution and the user later chooses 50% on Save PDF
- **THEN** the original creation-session image retains its full capture dimensions and only the generated PDF page is scaled to 50%

#### Scenario: Camera released after capture
- **WHEN** the user leaves the camera capture screen by any path
- **THEN** the camera resource is released

#### Scenario: End-to-end capture resolution coverage
- **WHEN** the capture-to-document end-to-end flow selects a supported lower resolution, captures a page, then restores Full resolution and captures another page
- **THEN** it observes the resolved capture choices and later Save quality independently through stable keys and semantics without accessing repositories directly

### Requirement: Manual edge adjustment and perspective correction
The application SHALL allow the user to adjust the detected edges manually and to rotate the page freely, SHALL apply perspective correction so that the selected region is rendered as a rectangular page, and SHALL use the native GPU for correction pixel transforms on compatible Android and iOS devices with safe background CPU fallback.

#### Scenario: Manual adjustment
- **WHEN** the user drags a corner handle of the edge overlay on the crop screen with key `scan_crop_screen`
- **THEN** the crop quadrilateral updates to follow the handle and the preview reflects the new region

#### Scenario: Perspective correction applied
- **WHEN** the user applies a crop whose quadrilateral is not rectangular
- **THEN** perspective correction is applied so the resulting page image is rectangular and deskewed

#### Scenario: Compatible device accelerates correction
- **WHEN** perspective correction is rendered on a device that passes the native capability probe
- **THEN** the composed perspective transform and bilinear resampling execute through the same native GPU render pipeline used by enhancement
- **AND** the original is resampled only once before enhancement

#### Scenario: Correction stays off the UI thread
- **WHEN** perspective correction is applied to a page through either the GPU or CPU backend
- **THEN** processing runs off the Flutter UI thread and the UI remains responsive with a progress state displayed

#### Scenario: Correction preserves geometry fidelity
- **WHEN** the shared perspective fixture is rendered through the GPU backend
- **THEN** its output dimensions, orientation, corners, pixel-center sampling, and edge clamping match the CPU reference within the documented tolerance manifest

#### Scenario: Correction falls back safely
- **WHEN** GPU correction is unsupported or fails recoverably
- **THEN** any partial destination is removed and the same correction completes through the background CPU backend
- **AND** the working image remains unchanged if both backends fail

#### Scenario: Rotation applied with the crop
- **WHEN** the user rotates the page and then applies the crop
- **THEN** the rotation is included in the composed corrected result

#### Scenario: Edit flow covers accelerated crop
- **WHEN** the catalogue edit flow in `integration_test/flows/edit_test.dart` runs on a GPU-capable device
- **THEN** it adjusts the accessible corner handles on `scan_crop_screen`, activates `scan_crop_apply_button`, and observes the corrected preview before continuing through `scan_crop_next_button`

#### Scenario: Crop accessibility and layouts remain unchanged
- **WHEN** accelerated correction is enabled in light or dark mode on phone or tablet layouts
- **THEN** the existing apply, revert, next, and corner-handle semantics remain screen-reader accessible and the crop UI remains responsive without clipping

#### Scenario: Correction remains offline
- **WHEN** perspective correction uses either backend without network connectivity
- **THEN** it completes without a network request

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

### Requirement: Automatic edge detection
The application SHALL automatically detect the document edges in each captured page and apply the detected crop by default.

#### Scenario: Edges detected
- **WHEN** a page is captured and document edges are detected
- **THEN** the detected quadrilateral is shown overlaid on the page with key `scan_edge_overlay` and is used as the default selection

#### Scenario: Edges not detected
- **WHEN** document edges cannot be detected in a captured page
- **THEN** the full page is used as the default selection and the manual edge adjustment control is presented
- **AND** the capture is not rejected or discarded

### Requirement: Scanning error handling
The application SHALL present a clear message and a recovery action for every scanning failure.

#### Scenario: Camera permission denied
- **WHEN** the user chooses the camera source and camera permission has been denied
- **THEN** a permission-denied view with key `scan_permission_denied_view` explains why the permission is needed and offers a control that opens the system settings

#### Scenario: Camera unavailable
- **WHEN** the camera cannot be initialised or is in use by another application
- **THEN** an error view with key `scan_camera_error_view` is displayed with a retry control and an option to add a page from the photo library instead

#### Scenario: Storage full during capture
- **WHEN** a captured page cannot be written because device storage is full
- **THEN** a storage-full message is displayed, the pages already in the page table are retained, and the user is offered the option to free space and retry

### Requirement: Scanning accessibility, theming and offline behaviour
The scanning flow SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate entirely without network connectivity.

#### Scenario: Screen reader on capture controls
- **WHEN** a screen reader traverses the camera capture screen
- **THEN** the shutter and flash controls each expose a descriptive semantics label

#### Scenario: Screen reader on the crop screen
- **WHEN** a screen reader traverses the crop screen
- **THEN** the apply, revert and next controls and each corner handle expose a descriptive semantics label

#### Scenario: Dark mode and tablet crop
- **WHEN** the crop screen is displayed in dark mode on a tablet-width viewport
- **THEN** the layout uses the dark colour scheme and adapts to the wider viewport without clipping

#### Scenario: Scanning offline
- **WHEN** the device has no network connection
- **THEN** capture, edge detection, perspective correction and cropping all complete successfully with no network request
