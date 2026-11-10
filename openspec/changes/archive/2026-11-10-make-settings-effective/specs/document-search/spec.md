# Spec Delta

## ADDED Requirements

### Requirement: Search by title
The application SHALL allow the user to search documents by title. Documents carry no recognised text, so no result is attributed to one.

#### Scenario: Search by title
- **WHEN** the user enters a term that appears in a document's title into the field with key `search_input_field`
- **THEN** that document appears in the results list with key `search_results_list`

#### Scenario: Result rows show the document, not a snippet
- **WHEN** results are displayed
- **THEN** each row with key `search_result_<documentId>` shows the document title and its usual subtitle, and is announced to screen readers as the title followed by that subtitle

#### Scenario: Search is case-insensitive
- **WHEN** the user searches using different letter casing from the stored text
- **THEN** the same documents are returned

## MODIFIED Requirements

### Requirement: Search performance
Search SHALL remain responsive on large libraries.

#### Scenario: Large library search
- **WHEN** a search is performed against a library of several thousand documents
- **THEN** results are returned without blocking the UI thread and the results list scrolls smoothly

#### Scenario: Indexed queries
- **WHEN** a search executes
- **THEN** it uses indexed queries against local storage rather than scanning full document contents in memory

## REMOVED Requirements

### Requirement: Search by title and recognised text
**Reason**: Documents never carried recognised text: OCR was never shipped and has been removed, so no search result could match on it, and the snippet scenario described a row that never appeared.
**Migration**: Replaced by “Search by title”. Title search, case-insensitivity and the `search_input_field`/`search_results_list` keys are unchanged.
