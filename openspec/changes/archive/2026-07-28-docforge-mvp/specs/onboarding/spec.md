## ADDED Requirements

### Requirement: First-launch onboarding flow
The application SHALL present the onboarding flow exactly once, on the first launch after installation, in the order Welcome → Privacy & Offline Introduction → Camera Permission Request → Home.

#### Scenario: First launch shows welcome
- **WHEN** the application is launched and no onboarding-completed flag exists in preferences
- **THEN** the Welcome screen is displayed with key `onboarding_welcome_screen`
- **AND** the Home screen is not reachable until onboarding completes

#### Scenario: Advancing through onboarding
- **WHEN** the user activates the continue control with key `onboarding_welcome_continue_button`
- **THEN** the Privacy & Offline Introduction screen with key `onboarding_privacy_screen` is displayed

#### Scenario: Onboarding completion is persisted
- **WHEN** the user completes the permission step
- **THEN** the onboarding-completed flag is written to preferences before navigation to Home occurs

### Requirement: Returning users skip onboarding
The application SHALL navigate directly to the Home screen on every launch after onboarding has been completed.

#### Scenario: Returning user launch
- **WHEN** the application is launched and the onboarding-completed flag is set
- **THEN** the Home screen is displayed
- **AND** no onboarding screen is rendered at any point during startup

#### Scenario: Onboarding is not repeated after app update
- **WHEN** the application is updated to a newer version and relaunched
- **THEN** the persisted onboarding-completed flag is still honoured and onboarding is not shown again

### Requirement: Privacy and offline introduction
The Privacy & Offline Introduction screen SHALL state that documents are stored only on the device, that no document is uploaded automatically, and that scanning and OCR work without an internet connection.

#### Scenario: Privacy statements are presented
- **WHEN** the Privacy & Offline Introduction screen is displayed
- **THEN** it shows the local-storage statement, the no-automatic-upload statement and the offline-capability statement
- **AND** each statement is exposed to screen readers with a descriptive semantics label

### Requirement: Just-in-time camera permission request
The application SHALL request camera permission during onboarding with a rationale shown before the system dialog, and SHALL allow the user to proceed to Home whether or not permission is granted.

#### Scenario: Permission granted
- **WHEN** the user activates the control with key `onboarding_permission_allow_button` and grants camera permission
- **THEN** the user is navigated to the Home screen
- **AND** the Scan Document action on Home is enabled

#### Scenario: Permission denied
- **WHEN** the user denies camera permission
- **THEN** the user is still navigated to the Home screen
- **AND** the Scan Document action remains visible and, when activated, presents the permission-recovery path

#### Scenario: Permission request can be skipped
- **WHEN** the user activates the control with key `onboarding_permission_skip_button`
- **THEN** no system permission dialog is shown
- **AND** the user is navigated to the Home screen

### Requirement: Onboarding accessibility, theming and responsiveness
Every onboarding screen SHALL support screen readers, large text, high contrast, dark mode and both phone and tablet layouts.

#### Scenario: Dark mode
- **WHEN** the device is in dark mode
- **THEN** every onboarding screen renders with the dark Material 3 colour scheme and meets contrast requirements

#### Scenario: Tablet layout
- **WHEN** an onboarding screen is displayed on a tablet-width viewport
- **THEN** the layout adapts to the wider viewport without truncation, clipping or horizontal overflow

#### Scenario: Large text scaling
- **WHEN** the system text scale factor is set to its maximum supported value
- **THEN** all onboarding text remains fully visible and no content overflows

#### Scenario: Screen reader navigation
- **WHEN** a screen reader traverses an onboarding screen
- **THEN** every interactive control exposes a semantics label describing its action
- **AND** every interactive control has a touch target of at least 48dp

### Requirement: Onboarding works offline
The onboarding flow SHALL complete successfully with no network connectivity.

#### Scenario: Onboarding with no connectivity
- **WHEN** the device has no network connection and the application is launched for the first time
- **THEN** the full onboarding flow completes and the user reaches the Home screen without any error or network request
