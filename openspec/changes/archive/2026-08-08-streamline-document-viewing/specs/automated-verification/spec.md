## MODIFIED Requirements

### Requirement: End-to-end flow catalogue

The project SHALL maintain a catalogue of user journeys covered by Tier‑3 tests, with one test file per journey. The catalogue SHALL cover at minimum:

1. **First launch** — onboarding completes and the app lands on the dashboard.
2. **Capture to document** — capture pages, enhance them, create the page table, generate the PDF, and open the result directly in Viewer.
3. **Page table creation** — build a page table, reorder and remove pages, and confirm the generated document reflects the final order in Viewer.
4. **Import** — import an existing file, confirm it appears in the library, and open it directly in Viewer without eager page preview generation.
5. **Browse and view** — open a document directly from the library in Viewer, read and jump within it, open Details from Viewer, and return to the originating surface.
6. **Search** — search the library and open a result directly in Viewer.
7. **Organise** — open Details from Viewer, rename, favourite, move to a folder, archive, and delete a document while verifying Viewer metadata reconciliation or closure.
8. **Edit** — modify a document with the editing tools and confirm the saved result opens directly in Viewer and changed.
9. **Share** — invoke share on a document and confirm the correct file and metadata reach the share boundary.
10. **Settings and lock** — change a setting and confirm it persists; enable the app lock and confirm a relaunch requires unlocking.

Each flow file SHALL state its precondition, its scripted user path, and assertions on user-visible outcomes only.

#### Scenario: Every catalogued journey has a test

- **WHEN** the flow catalogue is compared against the files in `integration_test/flows/`
- **THEN** every catalogued journey has exactly one corresponding test file, and every test file corresponds to a catalogued journey

#### Scenario: A flow asserts what the user sees

- **WHEN** a flow reaches its final step
- **THEN** it asserts on rendered widgets, route location and displayed state, not on internal objects or database rows

#### Scenario: A broken flow is reported by name

- **WHEN** a flow fails
- **THEN** the failure output names the journey and the step within it that failed

#### Scenario: Direct-view route is verified across entry points
- **WHEN** capture, import, browse, search, organise, or edit opens a document
- **THEN** the corresponding flow observes `viewer_screen` before any `document_detail_screen` and drives Details only through `viewer_document_details_button`
