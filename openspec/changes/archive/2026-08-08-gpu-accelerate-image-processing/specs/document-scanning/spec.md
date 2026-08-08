## MODIFIED Requirements

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
