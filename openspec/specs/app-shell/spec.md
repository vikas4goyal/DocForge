# app-shell Specification

## Purpose

Define the application's top-level navigation and the Dashboard that sits at its centre: a persistent three-destination tab bar, the composition of the Dashboard's folder-browsing home screen, its empty, loading and error states, and the shell-wide guarantees every screen inherits — typed routes, Material 3 theming, responsive layout, accessibility and offline operation.

## Requirements

### Requirement: Tab bar navigation
The application SHALL present a persistent bottom tab bar with three destinations — Dashboard, Create PDF and Settings — with Create PDF in the middle, and every destination SHALL be reachable from every other in one tap.

#### Scenario: Tab bar displayed
- **WHEN** the application is showing any top-level destination
- **THEN** a tab bar with key `app_tab_scaffold` is displayed with a dashboard tab with key `app_tab_dashboard`, a create-PDF control with key `app_tab_create` in the middle, and a settings tab with key `app_tab_settings`

#### Scenario: Settings reachable
- **WHEN** the user activates the settings tab
- **THEN** the settings screen is displayed

#### Scenario: Dashboard reachable
- **WHEN** the user activates the dashboard tab
- **THEN** the dashboard is displayed

#### Scenario: Create PDF starts a session
- **WHEN** the user activates the create-PDF control
- **THEN** a new PDF creation session is started and the page table screen is displayed

#### Scenario: Create PDF is not a browsing tab
- **WHEN** the user leaves the creation flow
- **THEN** the previously selected tab is restored rather than a Create tab remaining selected

#### Scenario: Each tab keeps its own history
- **WHEN** the user navigates into a folder on the dashboard, switches to settings, and switches back
- **THEN** the dashboard is still showing that folder

#### Scenario: Tab bar hidden inside full-screen flows
- **WHEN** the camera, crop, enhancement or document viewer is displayed
- **THEN** the tab bar is not displayed, so those screens use the full height

#### Scenario: Tab bar accessibility
- **WHEN** a screen reader is in use
- **THEN** each destination exposes a semantics label naming it and announces its selected state, and each tab target meets the minimum touch target size

#### Scenario: Tab bar in dark mode
- **WHEN** the device is in dark mode
- **THEN** the tab bar renders in the dark theme with the selected destination distinguishable by more than colour alone

### Requirement: Home screen composition
The Dashboard SHALL be the application's primary destination and SHALL display a search control, the contents of the currently open folder, a storage summary, and actions to create a folder, import a PDF and create a PDF in that folder.

#### Scenario: Dashboard displays all sections
- **WHEN** the dashboard is displayed and at least one document exists
- **THEN** the search control (`dashboard_search_field`), the folder and document list (`dashboard_content_list`), the storage summary (`dashboard_storage_summary`), the create-folder action (`dashboard_create_folder_button`) and the import-PDF action (`dashboard_import_pdf_button`) are all present

#### Scenario: Recent documents ordering
- **WHEN** the dashboard shows the root of the library
- **THEN** a recent documents section lists documents ordered by modified date descending
- **AND** archived documents are excluded

#### Scenario: Newly saved document appears
- **WHEN** a document is saved and the user returns to the dashboard
- **THEN** that document appears in the folder it was saved into, and at the top of the recent documents section, without requiring an app restart

#### Scenario: Folder contents shown
- **WHEN** the user opens a folder
- **THEN** the child folders and the PDFs of that folder are listed, and a breadcrumb with key `dashboard_breadcrumb` shows the path from the library root

#### Scenario: Only application folders are browsable
- **WHEN** the user browses the dashboard
- **THEN** only folders inside the application's own library folder are reachable, and no other location on the device can be browsed

### Requirement: Home empty state
When the open folder contains no documents and no subfolders, the Dashboard SHALL display an empty state that encourages the user to create their first PDF.

#### Scenario: No documents exist
- **WHEN** the dashboard is displayed and the open folder is empty
- **THEN** the empty state with key `dashboard_empty_state` is displayed with a call to action to create a PDF
- **AND** the document list is not rendered

#### Scenario: Empty state call to action
- **WHEN** the user activates the empty state call to action
- **THEN** a creation session is started, identically to activating the create-PDF control in the tab bar

### Requirement: Home loading and error states
The Dashboard SHALL present distinct loading and error states, and the error state SHALL offer a retry action.

#### Scenario: Loading
- **WHEN** the dashboard is loading its data
- **THEN** a loading indicator with key `dashboard_loading_indicator` is displayed

#### Scenario: Load failure
- **WHEN** loading dashboard data fails
- **THEN** an error view with key `dashboard_error_view` is displayed with a human-readable message and a retry control with key `dashboard_error_retry_button`

#### Scenario: Retry after failure
- **WHEN** the user activates the retry control
- **THEN** the dashboard data is loaded again and the error view is replaced by the resulting content

### Requirement: Storage summary
The Dashboard SHALL display a summary of storage consumed by the application's documents, and the summary SHALL update after documents are added or permanently removed.

#### Scenario: Storage summary displayed
- **WHEN** the dashboard loads
- **THEN** the storage summary shows the total size used by stored documents in a human-readable unit
- **AND** it exposes a semantics label stating the value

#### Scenario: Storage summary updates
- **WHEN** a document is permanently removed and the user returns to the dashboard
- **THEN** the storage summary reflects the reduced usage

#### Scenario: Storage summary is not the route to settings
- **WHEN** the user wants to reach settings
- **THEN** the settings tab is available without interacting with the storage summary

### Requirement: Typed navigation
All navigation SHALL be performed through typed routes; no navigation in feature code may use string literals.

#### Scenario: Navigating to a document
- **WHEN** the user selects a document from the dashboard
- **THEN** the application navigates to the document detail route with the document identifier passed as a typed route parameter

#### Scenario: Deep-linked route restores correctly
- **WHEN** the application is opened at a document detail route for a document that exists
- **THEN** that document is displayed, with a working back path to the dashboard

#### Scenario: Unknown document route
- **WHEN** a route references a document identifier that does not exist
- **THEN** a not-found state is displayed with a control returning the user to the dashboard, and the application does not crash

### Requirement: Material 3 theming and dark mode
The application SHALL use Material 3 with adaptive Cupertino affordances where platform-appropriate, and SHALL support light, dark and system-following theme modes.

#### Scenario: System dark mode
- **WHEN** the theme setting is set to follow the system and the device switches to dark mode
- **THEN** the entire application re-renders using the dark colour scheme without requiring a restart

#### Scenario: Explicit theme selection
- **WHEN** the user selects the light or dark theme explicitly in settings
- **THEN** that theme is applied regardless of the system setting and persists across launches

### Requirement: Responsive and tablet layout
Every screen SHALL adapt to phone and tablet viewports in both portrait and landscape without clipping, truncation or horizontal overflow.

#### Scenario: Tablet dashboard layout
- **WHEN** the dashboard is displayed on a tablet-width viewport
- **THEN** the layout uses the additional width (for example a multi-column document grid) rather than stretching phone-width content

#### Scenario: Orientation change
- **WHEN** the device is rotated while any screen is displayed
- **THEN** the layout adapts and the current screen state, including scroll position and entered text, is preserved

### Requirement: Accessibility baseline
Every screen SHALL support screen readers, large text, high contrast and accessible touch targets.

#### Scenario: Screen reader labels
- **WHEN** a screen reader traverses any screen
- **THEN** every interactive control exposes a semantics label that describes its action, and every image or icon conveying information exposes a descriptive label

#### Scenario: Touch target size
- **WHEN** any interactive control is rendered
- **THEN** its touch target measures at least 48dp on each axis

#### Scenario: Maximum text scale
- **WHEN** the system text scale is set to its maximum supported value on any screen
- **THEN** all text remains visible and reachable by scrolling, with no overflow errors

#### Scenario: High contrast
- **WHEN** the device requests high contrast
- **THEN** text and essential icons meet WCAG AA contrast against their background in both light and dark themes

### Requirement: Offline-first shell
The dashboard and all navigation SHALL function fully with no network connectivity.

#### Scenario: Dashboard with no connectivity
- **WHEN** the device has no network connection
- **THEN** the dashboard loads all of its sections from local storage and no network request is made
