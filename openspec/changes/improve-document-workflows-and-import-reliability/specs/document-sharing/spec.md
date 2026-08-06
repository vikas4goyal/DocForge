## MODIFIED Requirements

### Requirement: Share pages as images
The application SHALL allow the user to share one or more pages of scanned or imported documents as ordered images, rendering PDF-backed pages lazily when stored page images do not exist.

#### Scenario: Sharing stored page images
- **WHEN** the user selects scanned pages and activates the control with key `share_images_button`
- **THEN** the system share sheet opens with those pages attached as image files in page order

#### Scenario: Sharing imported PDF pages
- **WHEN** the user selects pages of an imported PDF and activates `Key('share_images_button')` with semantics label “Share pages as images”
- **THEN** the selected PDF pages render at bounded share resolution and the system share sheet opens with the resulting image files in page order

#### Scenario: Share-image temporary lifetime
- **WHEN** page images are prepared for sharing
- **THEN** temporary files remain available through platform handoff and are cleaned afterward without deleting authoritative document content

#### Scenario: Imported page records are absent
- **WHEN** an imported PDF has no stored page-image rows but its local PDF is readable
- **THEN** image sharing uses PDF-backed page handles and does not report that the item no longer exists

### Requirement: Focused share surface
The application SHALL offer PDF sharing, ordered page-image sharing, printing, and platform export without presenting a Share Extracted Text action. Embedded-text extraction and OCR SHALL remain available to internal search and recognition features.

#### Scenario: Extracted text is not a share action
- **WHEN** the share options are displayed for a scanned or imported document
- **THEN** no `share_text_button` or “Share extracted text” option is present and the remaining actions stay reachable and correctly spaced

### Requirement: Export to device storage
The application SHALL allow the user to export a document through a platform-appropriate destination operation whose infrastructure implementation owns destination selection and writing. Application logic SHALL NOT assume that an iOS or Android provider result is an ordinary writable filesystem path.

#### Scenario: Exporting a document
- **WHEN** the user activates the control with key `share_export_button` and completes the platform destination flow
- **THEN** the authoritative PDF bytes are written exactly once through the platform adapter and `Key('share_export_done')` confirms the exported document name and destination description

#### Scenario: Export to an iOS document provider
- **WHEN** an iOS provider accepts bytes or grants provider-scoped access instead of returning an ordinary writable path
- **THEN** the platform adapter completes the provider's supported write/handoff contract without application code appending a partial path or copying onto the returned provider item

#### Scenario: Export cancelled
- **WHEN** the user cancels the destination picker or provider handoff
- **THEN** nothing is written, cancellation is not displayed as an error, and the application returns to the previous screen

#### Scenario: Export name collision
- **WHEN** the destination reports an existing item with the proposed name
- **THEN** replacement or keep-both behavior is resolved through the platform flow and no existing file is silently overwritten by application code

### Requirement: Sharing error handling
The application SHALL present a clear stage-specific message and recovery action when content preparation, platform share handoff, printing, or exporting fails.

#### Scenario: Content preparation failure
- **WHEN** a page cannot be rendered or text cannot be extracted
- **THEN** an error view with key `share_error_view` names the preparation stage and affected content, offers an applicable retry, and does not incorrectly claim the document no longer exists when its PDF is readable

#### Scenario: Export failure
- **WHEN** an export fails, including because storage is full, provider permission ends, or the destination is not writable
- **THEN** `Key('share_error_view')` identifies the export stage with a human-readable message and retry control, and the platform adapter leaves no application-created partial file

#### Scenario: Share handoff failure
- **WHEN** prepared content cannot be handed to the system share sheet
- **THEN** the message identifies the platform handoff stage and keeps the document unchanged

#### Scenario: No application available to receive the share
- **WHEN** the system reports that no application can handle the shared content
- **THEN** a message explains this and offers export to device storage as an alternative

#### Scenario: Print failure
- **WHEN** printing fails or no printer is available
- **THEN** a human-readable message is displayed and the application does not crash

#### Scenario: End-to-end share and export coverage
- **WHEN** the `share` end-to-end flow uses an imported PDF on Android and iOS
- **THEN** it shares page images, confirms extracted text is not offered, completes or cancels export, and observes stage-specific recovery for deterministic platform failures through the specified keys and semantics
