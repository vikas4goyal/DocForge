## MODIFIED Requirements

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

