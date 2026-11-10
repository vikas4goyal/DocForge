# Spec Delta

## MODIFIED Requirements

### Requirement: Enhancement backend observability and privacy
The application SHALL measure backend performance and fallback outcomes without recording page content or identifying document data.

#### Scenario: Render outcome is measured
- **WHEN** an enhancement render finishes, fails, falls back, or is cancelled
- **THEN** telemetry records the backend, preview or full-resolution kind, coarse megapixel bucket, stage and total durations, outcome, and non-sensitive fallback reason

#### Scenario: Sensitive image data is excluded
- **WHEN** enhancement telemetry is emitted
- **THEN** it contains no source or destination path, pixel data, document identifier, document metadata, or exact enhancement values

#### Scenario: Enhancement remains offline
- **WHEN** either the GPU or CPU backend processes a page without network connectivity
- **THEN** every filter and adjustment completes without a network request
