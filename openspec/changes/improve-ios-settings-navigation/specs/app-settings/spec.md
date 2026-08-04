## MODIFIED Requirements

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
