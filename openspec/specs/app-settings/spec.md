# app-settings Specification

## Purpose

Define the settings destination: what the user can configure (theme, OCR language, quality, default file naming and save location, iOS library storage, application lock), how those values persist and take effect, and the About and Privacy Policy screens that accurately disclose device-local and user-selected iCloud storage.

## Requirements

### Requirement: Settings screen
The application SHALL provide Settings as a top-level tab destination exposing theme, OCR language, PDF quality, image quality, default file naming, default save location, iOS library storage location, biometric lock, storage information, About and Privacy Policy. The tab destination SHALL NOT display a back control, while a Settings screen reached by a genuine push or deep-link stack SHALL provide a working back control.

#### Scenario: Settings entries present on iOS
- **WHEN** the settings screen with key `settings_screen` is displayed on iOS
- **THEN** entries with keys `settings_theme`, `settings_ocr_language`, `settings_pdf_quality`, `settings_image_quality`, `settings_file_naming`, `settings_save_location`, `settings_library_storage`, `settings_biometric_lock`, `settings_storage_info`, `settings_about` and `settings_privacy_policy` are all present

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
Every setting SHALL persist across application restarts and SHALL take effect immediately when changed.

#### Scenario: Setting persists
- **WHEN** the user changes a setting and relaunches the application
- **THEN** the changed value is still in effect

#### Scenario: Setting applies immediately
- **WHEN** the user changes the theme setting
- **THEN** the application re-renders in the selected theme immediately, without a restart

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

### Requirement: OCR language setting
The application SHALL allow the user to choose the language used for text recognition on a pushed, vertically scrollable screen.

#### Scenario: Open recognition-language screen
- **WHEN** the user activates `settings_ocr_language` with semantics label “Recognition language, <current language>”
- **THEN** typed navigation pushes `settings_ocr_language_screen` titled “Recognition language” instead of opening a modal sheet
- **AND** a back control returns to `settings_screen`

#### Scenario: Recognition languages remain reachable
- **WHEN** `settings_ocr_language_screen` contains more choices than fit in the viewport or the system uses maximum text scale
- **THEN** the list with key `settings_ocr_language_list` scrolls vertically so every keyed `settings_ocr_language_option_<language>` remains reachable without overflow

#### Scenario: Choosing a language
- **WHEN** the user selects `settings_ocr_language_option_<language>` with semantics label “<language>, recognition language”
- **THEN** subsequent recognition runs use that language
- **AND** navigation returns to Settings showing the selected value

#### Scenario: Existing documents are unaffected
- **WHEN** the OCR language is changed
- **THEN** previously recognised text is retained until recognition is explicitly re-run

### Requirement: Quality settings
The application SHALL allow the user to configure a default PDF quality percentage from 30% through 100% and a separate device-supported camera capture resolution, and SHALL use the PDF value as the initial selection on newly opened Save PDF screens without applying it to Compress PDF.

#### Scenario: Default PDF quality applied to save workflow
- **WHEN** the PDF quality setting is changed to 60% and a new Save PDF screen is opened
- **THEN** `Key('pdf_save_quality_slider')` initially displays 60%

#### Scenario: Save override does not change default
- **WHEN** the Settings PDF quality is 60%, the user saves one document at 40%, and later opens another Save PDF screen
- **THEN** the later screen initially displays 60%

#### Scenario: Compression has independent default
- **WHEN** the Settings PDF quality has any value and the user opens Compress PDF
- **THEN** `Key('pdf_compress_quality_slider')` initially displays 80%

#### Scenario: Quality trade-off explained
- **WHEN** the user views `Key('settings_pdf_quality')` or `Key('settings_image_quality')`
- **THEN** the effect on file size and fidelity is described, PDF quality explains that it scales pages after capture and supplies the default for Save PDF while actual bytes are calculated separately, and the camera setting explains that it controls source capture dimensions before cropping and PDF scaling

#### Scenario: Existing PDF quality preset migrated
- **WHEN** an upgrade reads an existing `low`, `balanced`, or `high` PDF-quality preference
- **THEN** it deterministically uses 40%, 70%, or 100% respectively without losing other settings

#### Scenario: Default percentage persists
- **WHEN** the user changes the default PDF quality percentage and relaunches the application
- **THEN** Settings and the next Save PDF screen display that percentage

### Requirement: Device-supported camera capture resolution
Settings SHALL expose camera capture resolution separately from PDF quality, list only choices supported by the active camera, and use the active camera's highest full supported resolution by default.

#### Scenario: Default is full supported resolution
- **WHEN** no camera-resolution preference has been saved and the active camera reports supported still-image sizes
- **THEN** `Key('settings_camera_resolution')` displays “Full resolution” with the highest supported dimensions and new camera captures use those dimensions

#### Scenario: Supported choices loaded
- **WHEN** the user activates `settings_camera_resolution`
- **THEN** typed navigation opens `Key('settings_camera_resolution_screen')` and displays only `Key('settings_camera_resolution_option_<tier>')` choices the active camera can satisfy, with friendly labels such as 720p, 1080p, 2K, 4K or Full and their exact dimensions

#### Scenario: Choose a lower capture size
- **WHEN** the user selects a supported camera-resolution option
- **THEN** the choice persists and subsequent camera add-page captures request that resolution without changing the default PDF-quality percentage

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
The application SHALL allow the user to configure a default file-naming pattern and choose either “Ask each time” or a default folder for exports.

#### Scenario: Default naming applied
- **WHEN** a document is saved without an explicit name
- **THEN** its title follows the configured naming pattern

#### Scenario: Naming pattern preview
- **WHEN** the user edits the naming pattern
- **THEN** a preview of a resulting example name is shown

#### Scenario: Open default save location while asking each time
- **WHEN** `settings_save_location` displays “Ask each time” and the user activates it
- **THEN** typed navigation pushes `settings_save_location_screen`
- **AND** `settings_save_location_ask_each_time` and `settings_save_location_choose_folder` are both enabled and reachable

#### Scenario: Keep asking each time
- **WHEN** the user activates `settings_save_location_ask_each_time` with semantics label “Ask each time, selected”
- **THEN** the null default-location preference remains in effect
- **AND** each future export asks for a destination

#### Scenario: Choose or change a folder
- **WHEN** the user activates `settings_save_location_choose_folder` with semantics label “Choose a folder” and selects a folder in the platform picker
- **THEN** the selected path is persisted through the existing settings repository
- **AND** Settings displays the selected folder as the current value

#### Scenario: Cancel folder picker
- **WHEN** the user cancels the folder picker
- **THEN** the previous default save-location value remains unchanged

#### Scenario: Default save location used
- **WHEN** the user exports a document
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
- **THEN** it states that PDFs and the library folder synchronize through the user's iCloud account while the Isar index, thumbnails, OCR text, working images, and passwords remain device-local/app-private
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
- **WHEN** Settings, recognition language, default save location, or storage details is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and width-limited adaptive content without clipping or overflow

#### Scenario: Maximum text scale
- **WHEN** any changed Settings screen is displayed at maximum supported text scale
- **THEN** all content remains visible and reachable by scrolling and every target remains at least 48dp on each axis

#### Scenario: Settings offline
- **WHEN** the device has no network connection
- **THEN** every setting and changed child screen can be viewed and changed with no network request, except that iCloud availability continues to follow the existing platform contract

#### Scenario: End-to-end coverage
- **WHEN** `integration_test/flows/settings_and_app_lock_test.dart` runs
- **THEN** its Settings robot verifies tab-aware back behavior, scrollable recognition selection, both save-location modes, and storage details
- **AND** `integration_test/flows/icloud_library_sync_test.dart` verifies navigation from storage details to iOS storage management
