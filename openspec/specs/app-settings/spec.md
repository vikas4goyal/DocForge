# app-settings Specification

## Purpose

Define the settings destination: what the user can configure (theme, PDF quality, camera resolution, default file naming and save location, iOS library storage, application lock), how those values persist and take effect, and the About and Privacy Policy screens that accurately disclose device-local and user-selected iCloud storage.

## Requirements

### Requirement: Settings screen
The application SHALL provide Settings as a top-level tab destination exposing theme, PDF quality, camera resolution, default file naming, default save location, iOS library storage location, biometric lock, storage information, About and Privacy Policy. The tab destination SHALL NOT display a back control, while a Settings screen reached by a genuine push or deep-link stack SHALL provide a working back control.

#### Scenario: Settings entries present on iOS
- **WHEN** the settings screen with key `settings_screen` is displayed on iOS
- **THEN** entries with keys `settings_theme`, `settings_pdf_quality`, `settings_camera_resolution`, `settings_file_naming`, `settings_save_location`, `settings_library_storage`, `settings_biometric_lock`, `settings_storage_info`, `settings_about` and `settings_privacy_policy` are all present
- **AND** no entry with key `settings_ocr_language` or `settings_image_quality` is present

#### Scenario: Settings entries present on Android
- **WHEN** the settings screen is displayed on Android
- **THEN** the normal settings entries are present and `settings_library_storage` is absent because Android has no iCloud provider

#### Scenario: Current values displayed
- **WHEN** the settings screen is displayed
- **THEN** each setting shows its current value, and iOS storage identifies Local, iCloud Drive, or Unavailable without implying that local and cloud are simultaneously authoritative

#### Scenario: Settings tab has no back control
- **WHEN** the user activates `app_tab_settings` from the top-level tab bar
- **THEN** `settings_screen` is displayed without an enabled back button because changing tabs did not push a route

#### Scenario: Pushed settings retains back navigation
- **WHEN** `settings_screen` is displayed above another route in a genuine navigation stack
- **THEN** a back control is displayed and returns to the preceding route

### Requirement: Settings persistence
Every setting SHALL persist across application restarts and SHALL take effect immediately when changed, for every feature that consumes it, whether or not the Settings screen is still displayed. A setting whose write fails or has not yet loaded SHALL NOT change the value other features use.

#### Scenario: Setting persists
- **WHEN** the user changes a setting and relaunches the application
- **THEN** the changed value is still in effect

#### Scenario: Setting applies immediately
- **WHEN** the user changes the theme setting
- **THEN** the application re-renders in the selected theme immediately, without a restart

#### Scenario: Creation settings apply without revisiting Settings
- **WHEN** the user changes PDF quality, camera resolution, file naming or save location, leaves Settings for another tab, and starts a capture, a save or an export
- **THEN** that workflow uses the newly persisted value without a restart

#### Scenario: Loading or failed settings do not reset consumers
- **WHEN** the Settings screen is still loading persisted values, or a write fails
- **THEN** capture, Save PDF, naming and export continue to use the last successfully persisted values rather than the documented defaults

#### Scenario: Defaults on first launch
- **WHEN** the settings screen is opened before any setting has been changed
- **THEN** each setting shows a documented default value

### Requirement: Theme setting
The application SHALL allow the theme to be set to light, dark or follow the system.

#### Scenario: Following the system
- **WHEN** the theme setting is set to follow the system and the system theme changes
- **THEN** the application theme changes to match without a restart

#### Scenario: Explicit theme overrides the system
- **WHEN** the theme setting is set to light or dark explicitly
- **THEN** the application uses that theme regardless of the system setting

### Requirement: Quality settings
The application SHALL let the user set a default PDF quality percentage from 30% through 100% with an inline slider on the Settings screen, and a separate device-supported camera capture resolution. Newly opened Save PDF screens SHALL use the PDF value as their initial selection; Compress PDF SHALL NOT.

#### Scenario: PDF quality is an inline slider
- **WHEN** `settings_screen` is displayed
- **THEN** `Key('settings_pdf_quality')` contains a slider with key `settings_pdf_quality_slider` ranging from 30 to 100 in steps of 1, showing the current value as “<percent>%” beside it, with no choice sheet or option list
- **AND** the slider exposes semantics label “Default PDF quality, <percent> percent” and supports screen-reader increase/decrease actions

#### Scenario: Dragging previews without persisting each step
- **WHEN** the user drags `settings_pdf_quality_slider` from 70% to 45%
- **THEN** the displayed percentage and description update continuously during the drag
- **AND** the value is persisted exactly once, with 45%, when the drag ends

#### Scenario: Failed slider write reverts
- **WHEN** persisting a new slider value fails
- **THEN** the slider returns to the previously persisted percentage and the settings error banner offers a retry

#### Scenario: Default PDF quality applied to save workflow
- **WHEN** the PDF quality setting is changed to 60% and a new Save PDF screen is opened
- **THEN** `Key('pdf_save_quality_slider')` initially displays 60%

#### Scenario: Default PDF quality changes the saved file
- **WHEN** identical pages are saved without touching the Save PDF slider, once after setting the default to 30% and once after setting it to 100%
- **THEN** the 30% document has smaller page raster dimensions and a smaller file size than the 100% document

#### Scenario: Save override does not change default
- **WHEN** the Settings PDF quality is 60%, the user saves one document at 40%, and later opens another Save PDF screen
- **THEN** the later screen initially displays 60%

#### Scenario: Compression has independent default
- **WHEN** the Settings PDF quality has any value and the user opens Compress PDF
- **THEN** `Key('pdf_compress_quality_slider')` initially displays 80%

#### Scenario: Quality trade-off explained
- **WHEN** the user views `Key('settings_pdf_quality')` or `Key('settings_camera_resolution')`
- **THEN** the effect on file size and fidelity is described, PDF quality explains that it scales pages after capture and supplies the default for Save PDF while actual bytes are calculated separately, and the camera setting explains that it controls source capture dimensions before cropping and PDF scaling

#### Scenario: Existing PDF quality preset migrated
- **WHEN** an upgrade reads an existing `low`, `balanced`, or `high` PDF-quality preference
- **THEN** it deterministically uses 40%, 70%, or 100% respectively without losing other settings

#### Scenario: Default percentage persists
- **WHEN** the user changes the default PDF quality percentage and relaunches the application
- **THEN** Settings and the next Save PDF screen display that percentage

### Requirement: Device-supported camera capture resolution
Settings SHALL expose camera capture resolution separately from PDF quality, list only choices supported by the active camera, use the active camera's highest full supported resolution by default, and apply the current choice to every subsequent capture, including one taken while the camera is already open.

#### Scenario: Default is full supported resolution
- **WHEN** no camera-resolution preference has been saved and the active camera reports supported still-image sizes
- **THEN** `Key('settings_camera_resolution')` displays “Full resolution” with the highest supported dimensions and new camera captures use those dimensions

#### Scenario: Supported choices loaded
- **WHEN** the user activates `settings_camera_resolution`
- **THEN** typed navigation opens `Key('settings_camera_resolution_screen')` and displays only `Key('settings_camera_resolution_option_<tier>')` choices the active camera can satisfy, with friendly labels such as 720p, 1080p, 2K, 4K or Full and their exact dimensions

#### Scenario: Choose a lower capture size
- **WHEN** the user selects a supported camera-resolution option
- **THEN** the choice persists and subsequent camera add-page captures request that resolution without changing the default PDF-quality percentage

#### Scenario: Selected tier is requested faithfully
- **WHEN** the user selects a tier whose measured dimensions differ from a higher tier, for example 2K on a camera that also offers 4K
- **THEN** the camera is opened with the request that produced the selected tier's measured dimensions, and the captured image is not larger than that tier's advertised dimensions

#### Scenario: Change applies to an already-open camera
- **WHEN** the camera is open at one resolution and the preference changes before the next capture
- **THEN** the camera is re-opened at the newly resolved resolution before that capture, and an unchanged preference does not re-open the camera

#### Scenario: Actual captured size reported
- **WHEN** a page has been captured
- **THEN** `Key('scan_camera_resolution_status')` shows the decoded width × height of the captured image, and if those dimensions do not satisfy the requested tier it states the actual size instead of claiming that tier

#### Scenario: Camera capability changes
- **WHEN** the selected resolution is unavailable on the newly active camera
- **THEN** Settings and capture visibly use the highest supported resolution at or below the preference, or the camera's highest supported resolution when no lower match exists

#### Scenario: Capabilities unavailable
- **WHEN** supported dimensions cannot be enumerated
- **THEN** the setting displays Full resolution, capture requests the camera plugin's maximum preset, and the actual captured dimensions are used without claiming an unsupported fixed tier

#### Scenario: Photo-library import is independent
- **WHEN** the user adds an existing image from the photo library
- **THEN** its source dimensions are retained without upscaling and the camera-resolution preference is not applied

#### Scenario: Legacy image-quality migration
- **WHEN** the application upgrades with an existing low, balanced, or high image-quality preference
- **THEN** it maps the desired camera tier to 720p, 1080p, or Full/highest-supported respectively on the first successful capability query

#### Scenario: Camera resolution setting presentation
- **WHEN** the resolution screen is shown offline in light or dark mode on a phone or tablet at maximum supported text scale
- **THEN** loading, supported, fallback, and error states remain scrollable and screen-reader accessible and `Key('settings_camera_resolution_retry')` retries a failed capability query without a network request

### Requirement: Default file naming and save location
The application SHALL allow the user to configure a default file-naming pattern and choose either “Ask each time” or a default folder in which document exports start.

#### Scenario: Default naming applied
- **WHEN** a document is saved without an explicit name
- **THEN** its title follows the configured naming pattern

#### Scenario: Changed naming pattern used by the next save
- **WHEN** the user changes `settings_file_naming` from “Date and time” to “Sequential number” and then opens a new Save PDF screen without restarting
- **THEN** `creation_save_name_field` is prefilled with a name in the “Scan <n>” form

#### Scenario: Naming pattern preview
- **WHEN** the user edits the naming pattern
- **THEN** a preview of a resulting example name is shown with key `settings_naming_preview` and semantics label “Example name, <example>”

#### Scenario: Open default save location while asking each time
- **WHEN** `settings_save_location` displays “Ask each time” and the user activates it
- **THEN** typed navigation pushes `settings_save_location_screen`
- **AND** `settings_save_location_ask_each_time` and `settings_save_location_choose_folder` are both enabled and reachable

#### Scenario: Keep asking each time
- **WHEN** the user activates `settings_save_location_ask_each_time` with semantics label “Ask each time, selected”
- **THEN** the null default-location preference remains in effect
- **AND** each future export opens the platform destination picker at its own default location

#### Scenario: Choose or change a folder
- **WHEN** the user activates `settings_save_location_choose_folder` with semantics label “Choose a folder” and selects a folder in the platform picker
- **THEN** the selected location is persisted through the existing settings repository in a form the platform export picker can open
- **AND** Settings displays the selected folder's readable name as the current value and describes it as the folder exports start in

#### Scenario: Cancel folder picker
- **WHEN** the user cancels the folder picker
- **THEN** the previous default save-location value remains unchanged

#### Scenario: Default save location used
- **WHEN** the user exports a document from any share surface
- **THEN** the configured default save location is offered as the initial destination

### Requirement: Storage information
The application SHALL make storage information actionable through a dedicated details screen and SHALL keep the displayed usage accurate as documents are added and removed.

#### Scenario: Open storage details
- **WHEN** the user activates `settings_storage_info` with semantics label “Storage, <usage summary>”
- **THEN** typed navigation pushes `settings_storage_screen`
- **AND** it displays total document storage in a human-readable unit and the document count

#### Scenario: Refresh storage details
- **WHEN** `settings_storage_screen` is opened or `settings_storage_refresh` with semantics label “Refresh storage usage” is activated
- **THEN** the usage summary is re-read and visibly updated

#### Scenario: Manage iOS library location
- **WHEN** the user activates `settings_storage_manage_location` with semantics label “Manage storage location” on iOS
- **THEN** typed navigation opens `cloud_storage_screen` showing local and iCloud availability and the current selection

#### Scenario: Android storage details
- **WHEN** `settings_storage_screen` is displayed on Android
- **THEN** usage and document count remain visible and `settings_storage_manage_location` is absent

#### Scenario: Storage information updates
- **WHEN** documents are permanently removed and storage details is reopened or refreshed
- **THEN** the reported usage has decreased accordingly

### Requirement: About and Privacy Policy
The application SHALL provide an About screen showing the DocScanly name and application version and a Privacy Policy screen accurately describing device-local and user-selected iCloud storage.

#### Scenario: About screen
- **WHEN** the About screen with key `settings_about_screen` is displayed
- **THEN** it shows `DocScanly` and the application version

#### Scenario: Privacy Policy with local storage
- **WHEN** the Privacy Policy screen with key `settings_privacy_screen` is displayed while local storage is selected
- **THEN** it states that PDFs are stored on the device and no document is uploaded automatically
- **AND** the content is readable without a network connection

#### Scenario: Privacy Policy with iCloud storage
- **WHEN** the Privacy Policy screen is displayed while iCloud is selected
- **THEN** it states that PDFs and the library folder synchronize through the user's iCloud account while the Isar index, thumbnails, working images, and passwords remain device-local/app-private
- **AND** the content is readable without a network connection

### Requirement: Library storage setting
On iOS, the application SHALL expose the selected library authority through `settings_library_storage` and a typed storage-location screen, and SHALL require informed confirmation before migration.

#### Scenario: Open storage-location settings
- **WHEN** the user activates `settings_library_storage` with semantics label “DocScanly library storage”
- **THEN** typed navigation opens `cloud_storage_screen` showing local and iCloud availability and the current selection

#### Scenario: iCloud unavailable
- **WHEN** iCloud Drive is disabled, signed out, restricted, or its container cannot be reached
- **THEN** `cloud_storage_icloud_option` explains the unavailable reason, local remains selected where authoritative, and `cloud_storage_retry` permits a fresh availability check

#### Scenario: Setting persists
- **WHEN** a migration completes and the application restarts
- **THEN** the versioned storage-location preference selects the verified authoritative root before normal library writes begin

#### Scenario: Settings previews and component flow
- **WHEN** storage settings are exercised in previews and the Settings component test
- **THEN** default, loading, unavailable, error, migration, long-content, phone/tablet, and light/dark states use deterministic fixtures and the real Cubit/use cases with infrastructure substituted only at the repository boundary

### Requirement: Settings error handling
The application SHALL present a clear message when a setting cannot be read or written, and SHALL retain a usable default.

#### Scenario: Setting write failure
- **WHEN** a setting cannot be persisted
- **THEN** an error message is displayed with a retry control, and the previous value remains in effect

### Requirement: Settings accessibility, theming, layout and offline behaviour
Settings and its pushed selection/detail screens SHALL support screen readers, large text, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on settings
- **WHEN** a screen reader traverses the settings screen and its pushed children
- **THEN** each entry announces its name and current value, each option announces its selected state, and each control exposes the semantics label named by this specification

#### Scenario: Dark mode and tablet
- **WHEN** Settings, camera resolution, default save location, or storage details is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and width-limited adaptive content without clipping or overflow

#### Scenario: Slider usable at large text and on tablets
- **WHEN** `settings_pdf_quality_slider` is displayed at maximum supported text scale or on a tablet-width viewport in light or dark mode
- **THEN** the title, percentage and description wrap without overflow, the slider remains full-width within the width-limited content, and its touch target is at least 48dp tall

#### Scenario: Maximum text scale
- **WHEN** any changed Settings screen is displayed at maximum supported text scale
- **THEN** all content remains visible and reachable by scrolling and every target remains at least 48dp on each axis

#### Scenario: Settings offline
- **WHEN** the device has no network connection
- **THEN** every setting and changed child screen can be viewed and changed with no network request, except that iCloud availability continues to follow the existing platform contract

#### Scenario: End-to-end coverage
- **WHEN** `integration_test/flows/settings_and_app_lock_test.dart` runs
- **THEN** its Settings robot verifies tab-aware back behavior, the PDF quality slider, both save-location modes, and storage details
- **AND** `integration_test/flows/icloud_library_sync_test.dart` verifies navigation from storage details to iOS storage management

#### Scenario: End-to-end settings coverage
- **WHEN** the “settings and app lock” end-to-end flow runs
- **THEN** it changes the PDF quality slider, file naming and save location in Settings, and the “capture to document” and “share” flows observe those values on the next Save PDF screen and the next export
