# image-enhancement Specification

## Purpose

Define page enhancement: settings held over the page's cropped original rather than baked into an image, applied to exactly one page at a time, reachable from the crop screen while adding a page and from a page row afterwards, revertible to defaults without disturbing the crop, and processed off the UI thread.

## Requirements

### Requirement: Enhancement performance
Enhancement processing SHALL use the native GPU for pixel transforms on compatible Android and iOS devices, SHALL use a safe background CPU fallback when acceleration is unavailable or fails, and SHALL keep the preview responsive.

#### Scenario: Compatible device uses GPU acceleration
- **WHEN** any named filter, brightness, contrast, sharpening, or shadow removal is rendered on a device that passes the native capability probe
- **THEN** geometry, scaling, and enhancement pixel transforms execute through the native GPU backend
- **AND** full decoded pixel buffers do not cross the Flutter platform channel

#### Scenario: Processing stays off the UI thread
- **WHEN** an enhancement is applied to a full-resolution page through either the GPU or CPU backend
- **THEN** pixel processing and codec work run off the Flutter UI thread and the UI remains responsive

#### Scenario: Preview uses a downscaled image
- **WHEN** the enhancement preview is rendered
- **THEN** its longest edge equals the preview view's measured physical-pixel longest edge, rounded up without fixed buckets
- **AND** the saved result is computed at its required full resolution

#### Scenario: Preview meets the responsiveness target
- **WHEN** the benchmark preview is rendered after five warm-up renders on either the documented Android emulator or iOS Simulator configuration
- **THEN** at least 95 percent of 30 GPU renders complete within 200 milliseconds from native submission to an atomically readable output

#### Scenario: Full-resolution render meets the performance target
- **WHEN** the representative 12-megapixel benchmark page is rendered after five warm-up renders on either the documented Android emulator or iOS Simulator configuration
- **THEN** at least 95 percent of 30 GPU renders complete within 1.5 seconds
- **AND** median GPU latency is at least three times faster than the CPU reference latency on that same device

#### Scenario: Virtual-device measurements are identified
- **WHEN** an emulator or simulator performance report is produced
- **THEN** it records the host, virtual-device model, OS image, graphics backend, and build mode
- **AND** it does not present virtual-device battery or thermal observations as physical-device measurements

#### Scenario: Preview keeps up with adjustments
- **WHEN** the user moves an adjustment slider continuously
- **THEN** preview rendering waits until the value has remained unchanged for 500 milliseconds
- **AND** previews are coalesced so that at most one render is active and at most the newest render is queued
- **AND** only the most recent settings are shown when processing completes

#### Scenario: Adjustment controls expose useful ranges
- **WHEN** the user adjusts brightness, contrast, or sharpening
- **THEN** brightness is limited to -0.35 through 0.35, contrast to -0.5 through 0.5, and sharpening to 0 through 0.6
- **AND** each slider remains continuous so its full travel provides fine control without unusable extremes

#### Scenario: Superseded preview is cancelled
- **WHEN** a new preview request supersedes one that is already processing
- **THEN** the obsolete request stops between interruptible stages, does not encode or publish output when cancellation is observed, and cannot replace the newest preview

#### Scenario: Unsupported GPU falls back safely
- **WHEN** the device does not support the required native GPU pipeline or maximum texture size
- **THEN** enhancement completes through the background CPU backend with the same user-visible settings and typed error behavior

#### Scenario: Recoverable GPU failure falls back once
- **WHEN** GPU initialization, context, allocation, or shader processing fails recoverably
- **THEN** any partial destination is removed and the request is retried exactly once through the background CPU backend
- **AND** the user receives a successful result if the CPU render succeeds

#### Scenario: Cancellation does not trigger fallback
- **WHEN** an enhancement request is explicitly cancelled because it is obsolete
- **THEN** the request does not retry on CPU and does not publish an output

### Requirement: Enhancement is per page
The enhancement screen SHALL apply its settings to exactly one page — the page it was opened for — and SHALL NOT offer any control that applies settings to other pages.

#### Scenario: Only the opened page is affected
- **WHEN** the user enhances one page of a multi-page document
- **THEN** only that page is affected and every other page is left exactly as it was

#### Scenario: No bulk control offered
- **WHEN** the enhancement screen is displayed
- **THEN** no apply-to-all control is present, regardless of how many pages the document has

#### Scenario: Each page keeps its own settings
- **WHEN** the user enhances two pages with different settings
- **THEN** each page retains the settings chosen for it

### Requirement: Enhancement is entered from crop and from a page row
The enhancement screen SHALL be reachable from the crop screen's Next control when a page is being added, and from a page row's enhance control afterwards, and SHALL behave identically from both.

#### Scenario: Entered while adding a page
- **WHEN** the user continues from the crop screen while adding a page
- **THEN** the enhancement screen is displayed for the cropped working image, and finishing it appends the page to the page table

#### Scenario: Entered from a row
- **WHEN** the user activates the enhance control on a page row
- **THEN** the enhancement screen is displayed for that page, and finishing it updates that row in place without changing its position

#### Scenario: Finishing returns to the page table
- **WHEN** the user finishes enhancement by activating the done control with key `enhance_done_button`
- **THEN** the page table is displayed with the page's row showing the enhanced result

#### Scenario: Leaving without finishing
- **WHEN** the user leaves the enhancement screen without finishing
- **THEN** no enhancement is recorded, and a page being added is not appended to the table

### Requirement: Enhancement is settings over the cropped page, never baked in
The enhancement screen SHALL derive its preview and its result from the page's original image with its crop layer applied, plus the current settings, and SHALL never apply enhancement to an already-enhanced image.

#### Scenario: Reopening shows the previous settings
- **WHEN** the user enhances a page, leaves, and opens enhancement for that page again
- **THEN** the settings the user last chose are shown, and the preview is the page at its current crop with those settings applied

#### Scenario: Enhancement follows a later crop
- **WHEN** the user enhances a page and then crops it further
- **THEN** the same enhancement settings are applied to the newly cropped result without the user re-entering them

#### Scenario: Enhancement does not compound
- **WHEN** the user applies a strong contrast increase, leaves, reopens enhancement and returns the contrast to its default
- **THEN** the resulting page is visually identical to the unenhanced page at its current crop

#### Scenario: Revert enhancement returns the settings to their defaults
- **WHEN** the user activates the revert control with key `enhance_revert_button`
- **THEN** every enhancement setting returns to its default

#### Scenario: Reverting enhancement keeps the crop
- **WHEN** the user reverts the enhancement of a page that has been cropped
- **THEN** the page is shown unenhanced but still cropped, at its cropped size, and its crop and rotation are unchanged

#### Scenario: Revert disabled when nothing is enhanced
- **WHEN** the page's enhancement settings are already at their defaults
- **THEN** the revert control is disabled

### Requirement: Enhancement filters
The application SHALL offer the following enhancement filters for scanned pages: Original, Auto Enhance, Magic Colour, Black & White and Grayscale.

#### Scenario: Filter list is available
- **WHEN** the enhancement screen with key `enhance_screen` is displayed for a page
- **THEN** filter controls with keys `enhance_filter_original`, `enhance_filter_auto`, `enhance_filter_magic_colour`, `enhance_filter_black_white` and `enhance_filter_grayscale` are all present

#### Scenario: Applying a filter
- **WHEN** the user selects a filter
- **THEN** the preview updates to show the page with that filter applied and the selected filter is visually and semantically marked as selected

#### Scenario: Original restores the unmodified page
- **WHEN** the user selects the Original filter after applying another filter
- **THEN** the preview shows the page at its current crop with no enhancement applied

### Requirement: Manual adjustments
The application SHALL allow the user to adjust brightness, contrast and sharpness, and to apply shadow removal.

#### Scenario: Brightness and contrast adjustment
- **WHEN** the user changes the brightness control with key `enhance_brightness_slider` or the contrast control with key `enhance_contrast_slider`
- **THEN** the preview updates to reflect the new value
- **AND** the control exposes its current value to screen readers

#### Scenario: Sharpen
- **WHEN** the user applies sharpening via the control with key `enhance_sharpen_control`
- **THEN** the preview updates with the sharpened result

#### Scenario: Shadow removal
- **WHEN** the user enables shadow removal via the control with key `enhance_shadow_removal_toggle`
- **THEN** uneven shadowing is reduced in the preview and the page background is normalised

#### Scenario: Adjustments combine with a filter
- **WHEN** the user selects a filter and then changes brightness
- **THEN** both the filter and the adjustment are reflected in the preview and in the saved page

### Requirement: Immediate preview before saving
The preview SHALL update to reflect the current enhancement settings before the document is saved, and no enhancement SHALL be committed to storage until the user saves.

#### Scenario: Preview updates before save
- **WHEN** the user changes any enhancement setting
- **THEN** the preview reflects the change without the user having to save first

#### Scenario: Discarding enhancements
- **WHEN** the user leaves the enhancement screen without saving
- **THEN** the stored page remains unmodified

### Requirement: Enhancement error handling
The application SHALL present a clear message and a recovery action when enhancement fails.

#### Scenario: Enhancement failure
- **WHEN** an enhancement operation fails
- **THEN** an error view with key `enhance_error_view` is displayed with a human-readable message and a retry control
- **AND** the page remains in its previous state

### Requirement: Enhancement accessibility, theming and offline behaviour
The enhancement screen SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on filters
- **WHEN** a screen reader traverses the filter list
- **THEN** each filter exposes its name and selection state as a semantics label

#### Scenario: Dark mode preview fidelity
- **WHEN** the enhancement screen is displayed in dark mode
- **THEN** the page preview is rendered on a neutral surface so the enhancement result is judged accurately, and all controls use the dark colour scheme

#### Scenario: Tablet layout
- **WHEN** the enhancement screen is displayed on a tablet-width viewport
- **THEN** the preview and controls use the additional width without clipping or overflow

#### Scenario: Enhancement offline
- **WHEN** the device has no network connection
- **THEN** every filter and adjustment completes successfully with no network request

### Requirement: Accelerated enhancement fidelity
The GPU backend SHALL preserve the visual meaning, dimensions, orientation, operation order, and non-destructive behavior of every enhancement relative to the CPU reference within the reviewed fixture tolerances.

#### Scenario: Every enhancement operation has GPU parity
- **WHEN** the shared fixture page is rendered with Original, Auto Enhance, Magic Colour, Black & White, Grayscale, brightness, contrast, sharpening, shadow removal, and representative combinations
- **THEN** each GPU output has the expected dimensions and orientation
- **AND** its channel and perceptual differences from the CPU reference remain within the documented tolerance manifest

#### Scenario: Filter order is preserved
- **WHEN** shadow removal, a named filter, brightness or contrast, and sharpening are combined
- **THEN** the output applies shadow removal first, the named filter second, brightness and contrast third, and sharpening last

#### Scenario: Colour handling is stable
- **WHEN** an input image has an embedded colour profile or EXIF orientation
- **THEN** the GPU output is correctly oriented and normalized to the application's canonical sRGB output without an unexpected colour cast

#### Scenario: Large input exceeds one texture
- **WHEN** an input image exceeds the GPU's maximum texture dimensions
- **THEN** the accelerated backend produces a seam-free tiled result within the fidelity tolerances or selects CPU fallback before publishing output

### Requirement: Enhancement backend observability and privacy
The application SHALL measure backend performance and fallback outcomes without recording page content or identifying document data.

#### Scenario: Render outcome is measured
- **WHEN** an enhancement render finishes, fails, falls back, or is cancelled
- **THEN** telemetry records the backend, preview or full-resolution kind, coarse megapixel bucket, stage and total durations, outcome, and non-sensitive fallback reason

#### Scenario: Sensitive image data is excluded
- **WHEN** enhancement telemetry is emitted
- **THEN** it contains no source or destination path, pixel data, document identifier, OCR text, document metadata, or exact enhancement values

#### Scenario: Enhancement remains offline
- **WHEN** either the GPU or CPU backend processes a page without network connectivity
- **THEN** every filter and adjustment completes without a network request

### Requirement: Accelerated enhancement end-to-end coverage
The catalogue edit flow in `integration_test/flows/edit_test.dart` SHALL verify the accelerated enhancement journey through the existing user controls.

#### Scenario: Edit flow exercises enhancement
- **WHEN** the edit end-to-end flow runs on a GPU-capable device
- **THEN** it operates the controls keyed `enhance_filter_original`, `enhance_filter_auto`, `enhance_filter_magic_colour`, `enhance_filter_black_white`, `enhance_filter_grayscale`, `enhance_brightness_slider`, `enhance_contrast_slider`, `enhance_sharpen_control`, `enhance_shadow_removal_toggle`, and `enhance_done_button`
- **AND** the saved page can be reopened with its settings and latest preview intact

#### Scenario: Existing accessible UI remains unchanged
- **WHEN** accelerated processing is enabled in light or dark mode on phone or tablet layouts
- **THEN** existing enhancement keys, screen-reader labels, selection state, error/retry behavior, and responsive layout remain available without clipping or loss of contrast
