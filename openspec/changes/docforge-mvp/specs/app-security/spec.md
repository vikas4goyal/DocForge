## ADDED Requirements

### Requirement: Local-only document storage
The application SHALL store all documents, page images and recognised text on the device only, and SHALL never upload them automatically.

#### Scenario: No automatic upload
- **WHEN** documents are created, edited or opened
- **THEN** no document content is transmitted off the device by the application

#### Scenario: App-private storage location
- **WHEN** a document, page image or recognised text is persisted
- **THEN** it is written to app-private storage that is not readable by other applications, rather than to shared or external storage

#### Scenario: Content leaves only by explicit user action
- **WHEN** document content leaves the application
- **THEN** it does so only as the direct result of a user-initiated share, export or print action

### Requirement: Biometric application lock
The application SHALL offer an application lock using biometric authentication with device-credential fallback, and SHALL not reveal document content until authentication succeeds.

#### Scenario: Enabling the lock
- **WHEN** the user enables the lock via the control with key `settings_biometric_lock` and authenticates successfully
- **THEN** the lock is enabled and its configuration is stored in secure storage

#### Scenario: Locked launch
- **WHEN** the application is launched with the lock enabled
- **THEN** the unlock screen with key `security_unlock_screen` is displayed and no document title, thumbnail or content is rendered before authentication succeeds

#### Scenario: Successful authentication
- **WHEN** the user authenticates successfully on the unlock screen
- **THEN** the application proceeds to the destination it would otherwise have shown

#### Scenario: Failed authentication
- **WHEN** authentication fails
- **THEN** the unlock screen remains displayed with a message and a retry control with key `security_unlock_retry_button`, and no document content is rendered

#### Scenario: Device-credential fallback
- **WHEN** biometric authentication is unavailable or the user chooses the fallback
- **THEN** the device credential (PIN, pattern or passcode) is accepted instead

#### Scenario: Returning from the background
- **WHEN** the application returns to the foreground after having been backgrounded with the lock enabled
- **THEN** the unlock screen is displayed again before any document content is shown

#### Scenario: Disabling the lock
- **WHEN** the user disables the lock
- **THEN** authentication is required to confirm the change, and afterwards launches proceed directly without an unlock step

#### Scenario: Biometrics not enrolled
- **WHEN** the user attempts to enable the lock on a device with no biometrics or device credential configured
- **THEN** a message explains what must be configured on the device and the lock remains disabled

### Requirement: Secure handling of PDF passwords
PDF passwords SHALL be stored only in secure storage, SHALL never be logged, and SHALL not be included when a document is shared.

#### Scenario: Password stored securely
- **WHEN** a PDF password is retained
- **THEN** it is written to secure storage only, and never to preferences, the database or application logs

#### Scenario: Password not shared
- **WHEN** a protected document is shared or exported
- **THEN** the file retains its protection and the password is not included in the shared content

#### Scenario: Password removed with the document
- **WHEN** a document is permanently removed
- **THEN** any stored password for it is deleted from secure storage

### Requirement: Security error handling
The application SHALL present a clear message and a recovery action when an authentication or secure-storage operation fails.

#### Scenario: Secure storage unavailable
- **WHEN** secure storage cannot be read or written
- **THEN** a human-readable message is displayed with a retry control, no sensitive value is written to an insecure location, and the application does not crash

#### Scenario: Authentication error
- **WHEN** the authentication mechanism reports an error rather than a rejection
- **THEN** the error is surfaced as a human-readable message with a retry control and the application remains locked

### Requirement: Security accessibility, theming, layout and offline behaviour
Security screens SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on the unlock screen
- **WHEN** a screen reader traverses the unlock screen
- **THEN** the authentication prompt and retry control each expose a descriptive semantics label

#### Scenario: Dark mode and tablet
- **WHEN** the unlock screen is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow

#### Scenario: Unlocking offline
- **WHEN** the device has no network connection
- **THEN** authentication and unlocking complete successfully with no network request
