## MODIFIED Requirements

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
- **THEN** it is computed with its longest edge bounded to 1400 pixels so interaction stays responsive, while the saved result is computed at its required full resolution

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
- **THEN** previews are coalesced so that at most one render is active and at most the newest render is queued
- **AND** only the most recent settings are shown when processing completes

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

## ADDED Requirements

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
