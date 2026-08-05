## ADDED Requirements

### Requirement: Explicit PDF operation workflows and outcomes
Every page-derived and whole-document editing operation SHALL expose the inputs and effect before mutation, require an explicit confirmation, submit at most once, report progress, and show a concrete success or typed failure outcome. The editor SHALL navigate to newly created results or visibly refresh an in-place result as appropriate.

#### Scenario: Operation input and review
- **WHEN** the user starts split, merge, compress, watermark, protect, page extract, or another derived operation
- **THEN** `Key('pdf_edit_operation_sheet')` presents required inputs and effect, `Key('pdf_edit_review')` summarizes the affected source and output behavior, and no mutation occurs before `Key('pdf_edit_confirm')` is activated

#### Scenario: Operation cancellation
- **WHEN** the user activates `Key('pdf_edit_cancel')` before confirmation
- **THEN** the workflow closes without changing the source or creating an output

#### Scenario: Duplicate submission guard
- **WHEN** an operation is submitting
- **THEN** confirmation and operation entry controls are disabled, `Key('pdf_edit_progress')` reports progress, and repeated taps cannot perform the operation or navigate more than once

#### Scenario: Split review and result
- **WHEN** the user starts Split
- **THEN** the workflow requires a valid split boundary and two collision-safe output names before confirmation
- **AND** success displays `Key('pdf_edit_result')` listing both new documents, allows either output to be opened, and allows Done to return to Dashboard while the source remains unchanged

#### Scenario: Merge selection and ordering
- **WHEN** the user starts Merge
- **THEN** the workflow requires at least two eligible documents, exposes `Key('pdf_merge_order_list')` for user ordering, reviews the output name, and success opens exactly one new merged document while source documents remain unchanged

#### Scenario: Compress replacement disclosure
- **WHEN** the user starts Compress
- **THEN** review explicitly states that successful compression replaces the current PDF, and success keeps the editor on that document while reporting original and resulting sizes

#### Scenario: Watermark input review
- **WHEN** the user starts Watermark
- **THEN** the user sees a preview and reviews the text and visual settings before confirmation, and success visibly refreshes the current document once

#### Scenario: Protection input review
- **WHEN** the user starts Protect or Remove Password
- **THEN** the workflow reviews the protection effect without displaying or logging password text, and success refreshes the current document's protection status once

#### Scenario: Derived page result navigation
- **WHEN** Extract or another operation creates a new document
- **THEN** success names the created document and typed navigation opens that result exactly once rather than leaving an ambiguous success state

#### Scenario: Operation failure
- **WHEN** a confirmed operation fails
- **THEN** the source remains unchanged, `Key('pdf_edit_error_view')` identifies the failed operation with retry or recovery, and no partial output remains

#### Scenario: End-to-end operation coverage
- **WHEN** the `edit` end-to-end flow performs split, merge, compress, watermark, and protect
- **THEN** it observes review, one submission, progress, and the specified result/navigation for each operation exclusively through keys and semantics

### Requirement: Responsive PDF editor chrome and contextual actions
The PDF editor SHALL preserve meaningful title space and SHALL expose only applicable page actions in a contextual area or adaptive overflow menu.

#### Scenario: Long editor title
- **WHEN** a long-titled document opens on a constrained phone width
- **THEN** the app bar shows an ellipsized title with the full title in semantics and keeps `Key('pdf_edit_actions_menu')` reachable without overlap

#### Scenario: No pages selected
- **WHEN** no page is selected
- **THEN** page-only actions are absent and an accessible hint explains that selecting pages reveals page actions

#### Scenario: Applicable selected-page actions
- **WHEN** one or more pages are selected
- **THEN** applicable rotate, duplicate, extract, and delete controls appear with their existing stable keys and descriptive semantics

#### Scenario: Unavailable action is explained
- **WHEN** an editing action is not valid for the current selection or document
- **THEN** it is absent or exposes a human-readable reason and does not appear as an unexplained inert icon

#### Scenario: Editor presentation variants
- **WHEN** the editor is used offline in light or dark mode on a phone or tablet at a supported large text scale
- **THEN** the title, page selection, menus, workflows, progress, and results remain scrollable, accessible, unclipped, and require no network request

