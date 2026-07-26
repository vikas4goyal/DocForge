## ADDED Requirements

### Requirement: Camera capture
The application SHALL open the device camera when the user starts a scan, and SHALL allow the user to capture one or more pages.

#### Scenario: Camera opens
- **WHEN** the user activates the Scan Document action and camera permission is granted
- **THEN** the camera capture screen with key `scan_camera_screen` is displayed with a live preview and a shutter control with key `scan_shutter_button`

#### Scenario: Single page capture
- **WHEN** the user captures one page and confirms
- **THEN** the page review screen is displayed containing exactly that one page

#### Scenario: Camera released after capture
- **WHEN** the user leaves the camera capture screen by any path
- **THEN** the camera resource is released

### Requirement: Multi-page and batch scanning
The application SHALL support capturing multiple pages in one scanning session, and SHALL support batch scanning in which pages are captured consecutively without returning to review between captures.

#### Scenario: Multi-page capture
- **WHEN** the user captures three pages in one session
- **THEN** the page review screen lists all three pages in capture order
- **AND** a page counter with key `scan_page_counter` shows the number captured

#### Scenario: Batch mode
- **WHEN** batch mode is enabled via the control with key `scan_batch_mode_toggle` and the user captures pages consecutively
- **THEN** each capture returns immediately to the live camera preview without an intermediate confirmation step

#### Scenario: Large batch does not exhaust memory
- **WHEN** the user captures a batch of pages
- **THEN** each captured page is written to device storage immediately and only its thumbnail is retained in memory

### Requirement: Automatic edge detection
The application SHALL automatically detect the document edges in each captured page and apply the detected crop by default.

#### Scenario: Edges detected
- **WHEN** a page is captured and document edges are detected
- **THEN** the detected quadrilateral is shown overlaid on the page with key `scan_edge_overlay` and is used as the default crop

#### Scenario: Edges not detected
- **WHEN** document edges cannot be detected in a captured page
- **THEN** the full page is used as the default crop and the manual edge adjustment control is presented
- **AND** the capture is not rejected or discarded

### Requirement: Manual edge adjustment and perspective correction
The application SHALL allow the user to adjust the detected edges manually, and SHALL apply perspective correction so the cropped region is rendered as a rectangular page.

#### Scenario: Manual adjustment
- **WHEN** the user drags a corner handle of the edge overlay on the crop screen with key `scan_crop_screen`
- **THEN** the crop quadrilateral updates to follow the handle and the preview reflects the new region

#### Scenario: Perspective correction applied
- **WHEN** the user confirms a crop whose quadrilateral is not rectangular
- **THEN** perspective correction is applied so the resulting page image is rectangular and deskewed

#### Scenario: Correction runs off the UI thread
- **WHEN** perspective correction is applied to a page
- **THEN** the work runs in a background isolate and the UI remains responsive with a progress state displayed

### Requirement: Page management
The application SHALL allow the user to rotate, reorder and delete pages before saving a document.

#### Scenario: Rotate a page
- **WHEN** the user activates the rotate control with key `scan_page_rotate_button` on a page
- **THEN** the page is rotated 90 degrees clockwise and the thumbnail updates immediately

#### Scenario: Reorder pages
- **WHEN** the user drags a page in the review list with key `scan_page_list` to a new position
- **THEN** the page order updates and is preserved through to the generated document

#### Scenario: Delete a page
- **WHEN** the user deletes a page
- **THEN** the page is removed from the session, the page counter decreases, and the deletion can be undone from the confirmation affordance

#### Scenario: Deleting the last page
- **WHEN** the user deletes the only remaining page in a session
- **THEN** the review screen shows an empty state with key `scan_review_empty_state` offering to capture a new page or exit the flow

### Requirement: Scanning error handling
The application SHALL present a clear message and a recovery action for every scanning failure.

#### Scenario: Camera permission denied
- **WHEN** the user starts a scan and camera permission has been denied
- **THEN** a permission-denied view with key `scan_permission_denied_view` explains why the permission is needed and offers a control that opens the system settings

#### Scenario: Camera unavailable
- **WHEN** the camera cannot be initialised or is in use by another application
- **THEN** an error view with key `scan_camera_error_view` is displayed with a retry control and an option to import from the gallery instead

#### Scenario: Storage full during capture
- **WHEN** a captured page cannot be written because device storage is full
- **THEN** a storage-full message is displayed, already-captured pages are retained, and the user is offered the option to free space and retry

### Requirement: Scanning accessibility, theming and offline behaviour
The scanning flow SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate entirely without network connectivity.

#### Scenario: Screen reader on capture controls
- **WHEN** a screen reader traverses the camera capture screen
- **THEN** the shutter, batch-mode toggle, flash control and page counter each expose a descriptive semantics label

#### Scenario: Dark mode and tablet review
- **WHEN** the page review screen is displayed in dark mode on a tablet-width viewport
- **THEN** the layout uses the dark colour scheme and adapts to the wider viewport without clipping

#### Scenario: Scanning offline
- **WHEN** the device has no network connection
- **THEN** capture, edge detection, perspective correction and page management all complete successfully with no network request
