## MODIFIED Requirements

### Requirement: Typed navigation
All navigation SHALL be performed through typed routes; no navigation in feature code may use string literals.

#### Scenario: Navigating to a document
- **WHEN** the user selects a document from Dashboard, Recent, Documents, an open folder, search, favourites, or archive
- **THEN** the application navigates directly to the typed document viewer route with the document identifier and displays `Key('viewer_screen')`

#### Scenario: Returning to the originating surface
- **WHEN** the user leaves a Viewer opened from a library surface
- **THEN** the application returns to that same Dashboard, list, folder, search-result, favourites, or archive surface without inserting Detail into the Back stack

#### Scenario: Deep-linked detail route restores correctly
- **WHEN** the application is opened at a typed document detail route for a document that exists
- **THEN** `Key('document_detail_screen')` displays that document with a working typed Back path

#### Scenario: Unknown document route
- **WHEN** a typed Viewer or Detail route references a document identifier that does not exist
- **THEN** a not-found state is displayed with a control returning the user to the originating library surface, and the application does not crash

