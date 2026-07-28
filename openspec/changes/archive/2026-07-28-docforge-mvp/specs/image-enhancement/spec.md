## ADDED Requirements

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
- **THEN** the preview shows the page exactly as captured, with no enhancement applied

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

#### Scenario: Reset adjustments
- **WHEN** the user activates the reset control with key `enhance_reset_button`
- **THEN** all filters and adjustments return to their default values and the preview shows the unmodified page

### Requirement: Enhancement applies per page and in bulk
The application SHALL allow enhancement settings to be applied to an individual page and to be applied to all pages of the current scanning session.

#### Scenario: Single page enhancement
- **WHEN** the user enhances one page of a multi-page session
- **THEN** only that page is affected and the other pages retain their own settings

#### Scenario: Apply to all pages
- **WHEN** the user activates the control with key `enhance_apply_to_all_button`
- **THEN** the current enhancement settings are applied to every page in the session and each page preview updates accordingly

### Requirement: Enhancement performance
Enhancement processing SHALL run off the UI thread and SHALL report progress for long-running operations.

#### Scenario: Processing off the UI thread
- **WHEN** an enhancement is applied to a full-resolution page
- **THEN** the processing runs in a background isolate and the UI remains responsive

#### Scenario: Progress and cancellation for bulk enhancement
- **WHEN** enhancement is applied to all pages of a large session
- **THEN** a progress indicator with key `enhance_progress_indicator` reports progress and a cancel control is available
- **AND** cancelling leaves already-processed pages intact and stops further processing

#### Scenario: Preview uses a downscaled image
- **WHEN** the enhancement preview is rendered
- **THEN** it is computed from a downscaled copy of the page so interaction stays responsive, while the saved result is computed at full resolution

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
