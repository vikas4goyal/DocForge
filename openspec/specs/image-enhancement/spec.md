# image-enhancement Specification

## Purpose

Define page enhancement: settings held over the page's cropped original rather than baked into an image, applied to exactly one page at a time, reachable from the crop screen while adding a page and from a page row afterwards, revertible to defaults without disturbing the crop, and processed off the UI thread.

## Requirements

### Requirement: Enhancement performance
Enhancement processing SHALL run off the UI thread and SHALL keep the preview responsive.

#### Scenario: Processing off the UI thread
- **WHEN** an enhancement is applied to a full-resolution page
- **THEN** the processing runs in a background isolate and the UI remains responsive

#### Scenario: Preview uses a downscaled image
- **WHEN** the enhancement preview is rendered
- **THEN** it is computed from a downscaled copy of the page so interaction stays responsive, while the saved result is computed at full resolution

#### Scenario: Preview keeps up with adjustments
- **WHEN** the user moves an adjustment slider continuously
- **THEN** previews are coalesced so that at most one render is in flight and the most recent settings are the ones shown when it completes

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
