## MODIFIED Requirements

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

## ADDED Requirements

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
