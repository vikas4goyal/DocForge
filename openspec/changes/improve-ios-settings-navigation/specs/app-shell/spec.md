## MODIFIED Requirements

### Requirement: Tab bar navigation
The application SHALL present a persistent, platform-adaptive bottom bar containing Dashboard, a middle Create PDF action, and Settings. On iOS it SHALL use a restrained Cupertino-style tab-bar presentation with native icons, spacing, safe-area treatment, separator, typography and selected-state treatment; on Android it SHALL use a Material 3 navigation-bar presentation. Dashboard and Settings are selectable destinations, while Create PDF SHALL start a flow without becoming selected.

#### Scenario: Tab bar displayed
- **WHEN** the application is showing any top-level destination
- **THEN** a tab bar with key `app_tab_scaffold` is displayed with a dashboard control with key `app_tab_dashboard`, a create-PDF control with key `app_tab_create` in the middle, and a settings control with key `app_tab_settings`

#### Scenario: Native iOS presentation
- **WHEN** the top-level shell is displayed on iOS
- **THEN** the bottom bar uses Cupertino-style unfilled/filled icon pairs, standard tab labels, system-safe-area insets and a subtle top separator
- **AND** no floating action button, notch, oversized circular background, or Material ink splash is shown

#### Scenario: Native Android presentation
- **WHEN** the top-level shell is displayed on Android
- **THEN** the bottom bar uses the Material 3 navigation-bar treatment and Android-appropriate icons and feedback

#### Scenario: Settings reachable
- **WHEN** the user activates `app_tab_settings` with semantics label “Settings, tab”
- **THEN** `settings_screen` is displayed and Settings is announced as selected

#### Scenario: Dashboard reachable
- **WHEN** the user activates `app_tab_dashboard` with semantics label “Dashboard, tab”
- **THEN** the dashboard is displayed and Dashboard is announced as selected

#### Scenario: Create PDF starts a session
- **WHEN** the user activates `app_tab_create` with semantics label “Create PDF”
- **THEN** a new PDF creation session is started and the page table screen is displayed

#### Scenario: Create PDF is not a browsing tab
- **WHEN** Create PDF is activated or the user leaves the creation flow
- **THEN** Create PDF is never announced or rendered as the selected tab
- **AND** the previously selected Dashboard or Settings tab remains selected

#### Scenario: Each tab keeps its own history
- **WHEN** the user navigates into a folder on the dashboard, switches to settings, and switches back
- **THEN** the dashboard is still showing that folder

#### Scenario: Tab bar hidden inside full-screen flows
- **WHEN** the camera, crop, enhancement or document viewer is displayed
- **THEN** the tab bar is not displayed, so those screens use the full height

#### Scenario: Tab bar accessibility
- **WHEN** a screen reader is in use
- **THEN** Dashboard and Settings expose their exact tab semantics labels and selected state, Create PDF exposes its action label without a selected state, and every target measures at least 48dp on each axis

#### Scenario: Tab bar at maximum text scale
- **WHEN** the system uses maximum supported text scale
- **THEN** all three labels remain visible or follow the platform's accessible tab-bar behavior without overflow or an unreachable action

#### Scenario: Tab bar in dark mode
- **WHEN** the device is in dark mode
- **THEN** each platform bar uses its native dark appearance and Dashboard or Settings is distinguishable as selected by both icon form and colour

#### Scenario: End-to-end coverage
- **WHEN** any full application flow uses the top-level navigation and `integration_test/flows/settings_and_app_lock_test.dart` explicitly traverses it
- **THEN** the robot can activate all three controls exclusively through `app_tab_dashboard`, `app_tab_create`, and `app_tab_settings` and their semantics labels

### Requirement: Material 3 theming and dark mode
The application SHALL use Material 3 on Android and adaptive Cupertino affordances on iOS where platform conventions materially differ, and SHALL support light, dark and system-following theme modes.

#### Scenario: System dark mode
- **WHEN** the theme setting is set to follow the system and the device switches to dark mode
- **THEN** the entire application, including the platform-adaptive bottom bar, re-renders using the platform-appropriate dark colour scheme without requiring a restart

#### Scenario: Explicit theme selection
- **WHEN** the user selects the light or dark theme explicitly in settings
- **THEN** that theme is applied to Material and adaptive Cupertino surfaces regardless of the system setting and persists across launches
