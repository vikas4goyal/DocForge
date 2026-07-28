# app-settings Specification

## Purpose

Define the settings destination: what the user can configure (theme, OCR language, quality, default file naming and save location, application lock), how those values persist and take effect, and the About and Privacy Policy screens that state the application's local-only guarantee.

## Requirements

### Requirement: Settings screen
The application SHALL provide a settings screen exposing theme, OCR language, PDF quality, image quality, default file naming, default save location, biometric lock, storage information, About and Privacy Policy.

#### Scenario: Settings entries present
- **WHEN** the settings screen with key `settings_screen` is displayed
- **THEN** entries with keys `settings_theme`, `settings_ocr_language`, `settings_pdf_quality`, `settings_image_quality`, `settings_file_naming`, `settings_save_location`, `settings_biometric_lock`, `settings_storage_info`, `settings_about` and `settings_privacy_policy` are all present

#### Scenario: Current values displayed
- **WHEN** the settings screen is displayed
- **THEN** each setting shows its current value

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
The application SHALL provide an About screen showing the application version and a Privacy Policy screen stating the local-only storage guarantee.

#### Scenario: About screen
- **WHEN** the About screen with key `settings_about_screen` is displayed
- **THEN** it shows the application name and version

#### Scenario: Privacy Policy screen
- **WHEN** the Privacy Policy screen with key `settings_privacy_screen` is displayed
- **THEN** it states that documents are stored only on the device and that no document is uploaded automatically
- **AND** the content is readable without a network connection

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
