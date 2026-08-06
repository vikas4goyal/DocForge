## ADDED Requirements

### Requirement: Search by title and recognised text
The application SHALL allow the user to search documents by title and by recognised OCR text.

#### Scenario: Search by title
- **WHEN** the user enters a term that appears in a document's title into the field with key `search_input_field`
- **THEN** that document appears in the results list with key `search_results_list`

#### Scenario: Search by recognised text
- **WHEN** the user enters a term that appears only in a document's recognised text
- **THEN** that document appears in the results

#### Scenario: Match context shown
- **WHEN** a result matched on recognised text rather than title
- **THEN** the result row shows a snippet of the matching text so the user can see why it matched

#### Scenario: Search is case-insensitive
- **WHEN** the user searches using different letter casing from the stored text
- **THEN** the same documents are returned

### Requirement: Results update as the user types
Search results SHALL update as the user types, without requiring an explicit submit action.

#### Scenario: Incremental results
- **WHEN** the user types successive characters into the search field
- **THEN** the results list updates to reflect each refined query

#### Scenario: Rapid typing is debounced
- **WHEN** the user types rapidly
- **THEN** intermediate queries are debounced so the UI remains responsive, and the results shown correspond to the final entered text

#### Scenario: Clearing the query
- **WHEN** the user clears the search field via the control with key `search_clear_button`
- **THEN** the results list returns to its initial state and the query is removed

### Requirement: Search filters
The application SHALL allow search results to be filtered by folder, creation date and modified date.

#### Scenario: Filter by folder
- **WHEN** the user applies a folder filter via the control with key `search_filter_folder`
- **THEN** only documents in that folder appear in the results

#### Scenario: Filter by date
- **WHEN** the user applies a creation-date or modified-date range via the control with key `search_filter_date`
- **THEN** only documents whose corresponding date falls within the range appear in the results

#### Scenario: Combining filters
- **WHEN** a text query and one or more filters are applied together
- **THEN** the results satisfy all of the applied criteria simultaneously

#### Scenario: Clearing filters
- **WHEN** the user clears all filters
- **THEN** the results reflect the text query alone

### Requirement: Search result states
The search screen SHALL present distinct initial, loading, empty and error states.

#### Scenario: No results
- **WHEN** a query matches no documents
- **THEN** an empty state with key `search_empty_state` is displayed indicating that nothing matched and suggesting how to broaden the search

#### Scenario: Loading
- **WHEN** a search is in progress
- **THEN** a loading indicator with key `search_loading_indicator` is displayed

#### Scenario: Search failure
- **WHEN** a search fails
- **THEN** an error view with key `search_error_view` is displayed with a retry control

#### Scenario: Archived documents excluded by default
- **WHEN** a search is performed without an explicit archive filter
- **THEN** archived documents are excluded from the results

### Requirement: Search performance
Search SHALL remain responsive on large libraries.

#### Scenario: Large library search
- **WHEN** a search is performed against a library of several thousand documents with recognised text
- **THEN** results are returned without blocking the UI thread and the results list scrolls smoothly

#### Scenario: Indexed queries
- **WHEN** a search executes
- **THEN** it uses indexed queries against local storage rather than scanning full document contents in memory

### Requirement: Search accessibility, theming, layout and offline behaviour
The search screen SHALL support screen readers, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on search
- **WHEN** a screen reader traverses the search screen
- **THEN** the search field, clear control and each filter expose descriptive semantics labels
- **AND** the number of results is announced when the results change

#### Scenario: Dark mode and tablet
- **WHEN** the search screen is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow

#### Scenario: Search offline
- **WHEN** the device has no network connection
- **THEN** search runs entirely against local storage and returns results with no network request
