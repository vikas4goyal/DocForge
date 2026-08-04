# app-settings Specification

## Purpose

Define the settings destination: what the user can configure (theme, OCR language, quality, default file naming and save location, iOS library storage, application lock), how those values persist and take effect, and the About and Privacy Policy screens that accurately disclose device-local and user-selected iCloud storage.

## Requirements

### Requirement: Settings screen
The application SHALL provide a settings screen exposing theme, OCR language, PDF quality, image quality, default file naming, default save location, iOS library storage location, biometric lock, storage information, About and Privacy Policy.

#### Scenario: Settings entries present on iOS
- **WHEN** the settings screen with key `settings_screen` is displayed on iOS
- **THEN** entries with keys `settings_theme`, `settings_ocr_language`, `settings_pdf_quality`, `settings_image_quality`, `settings_file_naming`, `settings_save_location`, `settings_library_storage`, `settings_biometric_lock`, `settings_storage_info`, `settings_about` and `settings_privacy_policy` are all present

#### Scenario: Settings entries present on Android
- **WHEN** the settings screen is displayed on Android
- **THEN** the normal settings entries are present and `settings_library_storage` is absent because Android has no iCloud provider

#### Scenario: Current values displayed
- **WHEN** the settings screen is displayed
- **THEN** each setting shows its current value, and iOS storage identifies Local, iCloud Drive, or Unavailable without implying that local and cloud are simultaneously authoritative

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
The application SHALL allow the user to choose the language used for text recognition.

#### Scenario: Choosing a language
- **WHEN** the user selects an OCR language
- **THEN** subsequent recognition runs use that language

#### Scenario: Existing documents are unaffected
- **WHEN** the OCR language is changed
- **THEN** previously recognised text is retained until recognition is explicitly re-run

### Requirement: Quality settings
The application SHALL allow the user to configure PDF quality and image quality, and these SHALL be applied to newly created documents.

#### Scenario: Quality applied to new documents
- **WHEN** the PDF quality setting is changed and a new document is created
- **THEN** the new document is generated at the selected quality

#### Scenario: Quality trade-off explained
- **WHEN** the user views a quality setting
- **THEN** the effect on file size and fidelity is described

### Requirement: Default file naming and save location
The application SHALL allow the user to configure a default file-naming pattern and a default save location for exports.

#### Scenario: Default naming applied
- **WHEN** a document is saved without an explicit name
- **THEN** its title follows the configured naming pattern

#### Scenario: Naming pattern preview
- **WHEN** the user edits the naming pattern
- **THEN** a preview of a resulting example name is shown

#### Scenario: Default save location used
- **WHEN** the user exports a document
- **THEN** the configured default save location is offered as the initial destination

### Requirement: Storage information
The application SHALL display how much device storage its documents consume and SHALL keep this figure accurate as documents are added and removed.

#### Scenario: Storage information displayed
- **WHEN** the storage information entry is opened
- **THEN** the total storage used by documents is displayed in a human-readable unit, together with the document count

#### Scenario: Storage information updates
- **WHEN** documents are permanently removed and the storage information is reopened
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
Settings screens SHALL support screen readers, large text, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on settings
- **WHEN** a screen reader traverses the settings screen
- **THEN** each entry announces its name and current value, and each control exposes a descriptive semantics label

#### Scenario: Dark mode and tablet
- **WHEN** the settings screen is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow

#### Scenario: Settings offline
- **WHEN** the device has no network connection
- **THEN** every setting, including About and the Privacy Policy, can be viewed and changed with no network request
