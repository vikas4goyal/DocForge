## MODIFIED Requirements

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

## ADDED Requirements

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
