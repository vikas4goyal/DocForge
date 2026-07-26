## ADDED Requirements

### Requirement: Home screen composition
The Home screen SHALL be the primary screen of the application and SHALL display a search bar, a Scan Document action, recent documents, an All Documents shortcut, folders, favourites, archive and a storage summary.

#### Scenario: Home displays all sections
- **WHEN** the Home screen is displayed and at least one document exists
- **THEN** the search bar (`home_search_bar`), Scan Document action (`home_scan_button`), recent documents section (`home_recent_documents`), All Documents shortcut (`home_all_documents_shortcut`), folders section (`home_folders_section`), favourites shortcut (`home_favourites_shortcut`), archive shortcut (`home_archive_shortcut`) and storage summary (`home_storage_summary`) are all present

#### Scenario: Recent documents ordering
- **WHEN** the Home screen loads recent documents
- **THEN** they are ordered by modified date descending
- **AND** archived documents are excluded

#### Scenario: Newly saved document appears in Recent
- **WHEN** a document is saved and the user returns to Home
- **THEN** that document appears first in the recent documents section without requiring an app restart

### Requirement: Home empty state
When no documents exist, the Home screen SHALL display an empty state that encourages the user to scan their first document.

#### Scenario: No documents exist
- **WHEN** the Home screen is displayed and the document count is zero
- **THEN** the empty state with key `home_empty_state` is displayed with a call to action to scan the first document
- **AND** the recent documents list is not rendered

#### Scenario: Empty state call to action
- **WHEN** the user activates the empty state call to action
- **THEN** the scanning flow is started, identically to activating the Scan Document action

### Requirement: Storage summary
The Home screen SHALL display a summary of storage consumed by the application's documents, and the summary SHALL update after documents are added or permanently removed.

#### Scenario: Storage summary displayed
- **WHEN** the Home screen loads
- **THEN** the storage summary shows the total size used by stored documents in a human-readable unit
- **AND** it exposes a semantics label stating the value

#### Scenario: Storage summary updates
- **WHEN** a document is permanently removed and the user returns to Home
- **THEN** the storage summary reflects the reduced usage

### Requirement: Home loading and error states
The Home screen SHALL present distinct loading and error states, and the error state SHALL offer a retry action.

#### Scenario: Loading
- **WHEN** the Home screen is loading its data
- **THEN** a loading indicator with key `home_loading_indicator` is displayed

#### Scenario: Load failure
- **WHEN** loading Home data fails
- **THEN** an error view with key `home_error_view` is displayed with a human-readable message and a retry control with key `home_error_retry_button`

#### Scenario: Retry after failure
- **WHEN** the user activates the retry control
- **THEN** the Home data is loaded again and the error view is replaced by the resulting content

### Requirement: Typed navigation
All navigation SHALL be performed through typed routes; no navigation in feature code may use string literals.

#### Scenario: Navigating to a document
- **WHEN** the user selects a document from the Home screen
- **THEN** the application navigates to the document detail route with the document identifier passed as a typed route parameter

#### Scenario: Deep-linked route restores correctly
- **WHEN** the application is opened at a document detail route for a document that exists
- **THEN** that document is displayed, with a working back path to Home

#### Scenario: Unknown document route
- **WHEN** a route references a document identifier that does not exist
- **THEN** a not-found state is displayed with a control returning the user to Home, and the application does not crash

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

#### Scenario: Tablet home layout
- **WHEN** the Home screen is displayed on a tablet-width viewport
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
The Home screen and all navigation SHALL function fully with no network connectivity.

#### Scenario: Home with no connectivity
- **WHEN** the device has no network connection
- **THEN** the Home screen loads all of its sections from local storage and no network request is made
