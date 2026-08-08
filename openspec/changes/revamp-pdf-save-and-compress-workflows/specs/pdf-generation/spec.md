## ADDED Requirements

### Requirement: Save PDF output-size calculation
The Save PDF screen SHALL calculate the exact byte size of a candidate generated from the current name, quality, pages, and protection choice without blocking configuration, Preview, or Save.

#### Scenario: Calculation starts on screen entry
- **WHEN** `Key('pdf_save_screen')` opens with a valid creation session
- **THEN** `Key('pdf_output_size_status')` displays “Calculating” and reports progress from 0 through 100 percent before displaying the candidate size in a human-readable unit

#### Scenario: Quality change supersedes calculation
- **WHEN** the user changes `Key('pdf_save_quality_slider')` while a size calculation is queued or running
- **THEN** the obsolete calculation is cancelled, only the latest 30–100% selection may publish a size, and calculation progress remains responsive

#### Scenario: Save does not wait for calculation
- **WHEN** a size calculation is queued, running, failed, or not yet started and the user activates `Key('creation_save_confirm_button')`
- **THEN** saving begins immediately with the current settings and does not wait for the calculation to finish

#### Scenario: Calculation failure is non-blocking
- **WHEN** candidate-size calculation fails
- **THEN** `Key('pdf_output_size_status')` presents a human-readable failure and Retry while Preview and Save remain available

### Requirement: Save PDF preview
The Save PDF screen SHALL let the user inspect a temporary PDF generated with the current quality and protection configuration before saving, without requiring preview as a condition of saving.

#### Scenario: Preview current configuration
- **WHEN** the user activates `Key('pdf_save_preview_button')` with semantics label “Preview PDF”
- **THEN** modal `Key('pdf_job_progress_dialog')` reports “Preparing PDF, <percent> percent” and a successful candidate opens `Key('pdf_temporary_preview_screen')` in read-only mode

#### Scenario: Return from preview
- **WHEN** the user activates `Key('pdf_temporary_preview_close')` with semantics label “Close PDF preview”
- **THEN** the temporary preview closes and `pdf_save_screen` retains the same name, quality, and password-enabled status

#### Scenario: Cancel preview preparation
- **WHEN** the user activates `Key('pdf_job_cancel_button')` with semantics label “Cancel PDF operation” while Preview is being prepared
- **THEN** preview generation stops, no temporary or partial output remains, and `pdf_save_screen` remains open with all configuration retained

#### Scenario: Save without preview
- **WHEN** the user activates `creation_save_confirm_button` without having activated Preview
- **THEN** the document is saved using the current configuration

### Requirement: Per-page Save PDF quality overrides
The Save PDF screen SHALL use the document quality as the default for every page and SHALL let the user set or remove a 30–100% override for an individual page without changing the document default or any other page.

#### Scenario: Set one page quality
- **WHEN** the user activates `Key('pdf_save_page_quality_<page-id>')`, chooses 40% in `Key('pdf_page_quality_slider')`, and confirms
- **THEN** that row announces “Page <number>, quality 40 percent, overrides document quality,” only that page uses 40%, and size calculation is restarted for the new effective quality plan

#### Scenario: Non-overridden pages follow document quality
- **WHEN** the document quality changes and page 2 has an explicit override
- **THEN** every page except page 2 uses the new document percentage and page 2 retains its override

#### Scenario: Return one page to document quality
- **WHEN** the user activates `Key('pdf_page_quality_use_document')` for an overridden page
- **THEN** that override is removed and the page immediately uses the current document quality

#### Scenario: Reset every page override
- **WHEN** one or more overrides exist and the user activates `Key('pdf_page_quality_reset_all')` with semantics label “Reset all page quality overrides”
- **THEN** every page uses the document quality and the document slider value is unchanged

#### Scenario: Preview and save use page overrides
- **WHEN** the user previews or saves while page overrides exist
- **THEN** the candidate uses each page's effective override-or-document percentage in page order and the displayed calculated size describes that same candidate

## MODIFIED Requirements

### Requirement: Document saving and naming
Saving a document SHALL use a dedicated Save PDF screen, write the PDF into the currently open folder of the library folder, create the document record, and name the document according to the default file-naming setting while allowing the user to override the name.

#### Scenario: Save screen opens
- **WHEN** the user activates `Key('creation_save_button')` from a valid creation session
- **THEN** typed navigation opens full-page `Key('pdf_save_screen')` containing `creation_save_name_field`, `pdf_save_quality_slider`, `pdf_output_size_status`, `pdf_save_preview_button`, and `creation_save_confirm_button` instead of a save dialog

#### Scenario: Document saved
- **WHEN** the user activates the save control with key `creation_save_confirm_button`
- **THEN** the PDF is written into the currently open folder of the library folder, a document record is created with title, creation date, modified date, page count, file size, selected quality percentage and folder path, the Save PDF screen closes, and the user is returned to that folder

#### Scenario: Default name applied
- **WHEN** the Save PDF screen opens
- **THEN** the name field is prefilled from the configured default file-naming pattern

#### Scenario: Name overridden
- **WHEN** the user edits the name in the field with key `creation_save_name_field` before saving
- **THEN** the entered name is used as both the document title and the file name

#### Scenario: File name matches the title
- **WHEN** a document has been saved
- **THEN** the file in the library folder is named after the document title with a `.pdf` extension

#### Scenario: Document appears in the dashboard
- **WHEN** saving completes and the user is returned to the dashboard
- **THEN** the new document appears in the folder it was saved into and at the top of the recent documents section

#### Scenario: Saved document is visible outside the application
- **WHEN** saving completes
- **THEN** the file is present in the operating system's file browser under the same folder path and name, without any further action by the user

### Requirement: Optional encryption at generation
PDF generation SHALL let the user set or remove a password draft on the Save PDF screen and SHALL encrypt the document with the confirmed password when saving or previewing while protection is enabled.

#### Scenario: Open password dialog
- **WHEN** the user activates `Key('pdf_save_set_password')` with semantics label “Set PDF password”
- **THEN** a focused dialog displays obscured `creation_save_password_field`, `creation_save_password_confirm_field`, and `pdf_save_password_dialog_confirm` controls without placing password text in persistent or observable workflow state

#### Scenario: Password enabled
- **WHEN** the user submits a valid matching password through `pdf_save_password_dialog_confirm`
- **THEN** the dialog closes, `Key('pdf_save_password_enabled')` announces “Password protection enabled,” the password text is not displayed, and `Key('pdf_save_remove_password')` is available

#### Scenario: Password removed before save
- **WHEN** the user activates `pdf_save_remove_password` with semantics label “Remove PDF password”
- **THEN** the draft password is cleared immediately and the Save PDF screen returns to the Set Password state

#### Scenario: Encrypted output produced
- **WHEN** the user saves with password protection enabled and a confirmed password
- **THEN** the written PDF is encrypted with that password using the application's PDF encryption, and opening it in another application requires that password

#### Scenario: Password stored for in-application use
- **WHEN** a document is saved with password protection
- **THEN** the password is stored in secure storage against that document, and never in preferences, the database, logs, previews, or serialized workflow state

#### Scenario: Unprotected by default
- **WHEN** the user saves without enabling password protection
- **THEN** the written PDF is not encrypted and opens without a password

#### Scenario: Encryption failure
- **WHEN** encryption fails
- **THEN** no file is left in the library folder, an error message with a retry control is displayed on the Save PDF screen, and the creation session and its pages are retained

### Requirement: Configurable PDF and image quality
PDF generation SHALL expose a document PDF quality slider from 30% through 100% on the Save PDF screen, initialize it from the configured default PDF quality, apply the selected value as the default for the current document's pages, honour explicit per-page overrides, and remain independent of camera capture resolution.

#### Scenario: Quality slider bounds and meaning
- **WHEN** the user adjusts `Key('pdf_save_quality_slider')` with semantics “PDF quality, <percent> percent”
- **THEN** the value remains within 30–100%, 100% preserves each prepared source image's dimensions, and a lower value scales both width and height to that percentage without enlarging any image

#### Scenario: Quality setting is applied
- **WHEN** the same pages are generated once at 30% and once at 100%
- **THEN** the 30% PDF uses smaller raster dimensions and is smaller than the 100% PDF while preserving page count, order, rotation, and enhancement

#### Scenario: Save quality default applied
- **WHEN** the Save PDF screen opens
- **THEN** `pdf_save_quality_slider` initially uses the persisted Settings PDF-quality percentage

#### Scenario: Per-document quality override
- **WHEN** the user changes `pdf_save_quality_slider` and saves
- **THEN** the selected percentage applies to that document and does not change the persisted Settings default

#### Scenario: Quality is recorded
- **WHEN** a document is generated
- **THEN** the selected document percentage, effective ordered page-quality plan, and capture dimensions used are recorded when supported by the metadata contract so the result is reproducible

### Requirement: PDF generation performance
PDF size calculation, preview generation, final generation, and commit SHALL run off the UI thread, report determinate progress when work is measurable, and be independently cancellable.

#### Scenario: Generation off the UI thread
- **WHEN** a PDF candidate or final PDF is generated
- **THEN** the work runs in a background isolate, processes pages with bounded memory, and the UI remains responsive

#### Scenario: Progress reported
- **WHEN** Preview or Save is in progress
- **THEN** `Key('pdf_job_progress_indicator')` reports progress from 0 through 100 percent and `Key('pdf_job_cancel_button')` remains available

#### Scenario: Save cancellation
- **WHEN** the user cancels Save before it completes
- **THEN** generation stops, the progress dialog closes, `pdf_save_screen` remains open with the same configuration, no partial document record or orphaned file is left, and the session pages remain available

#### Scenario: Save completion closes workflow
- **WHEN** saving reaches verified 100% completion
- **THEN** the progress dialog and Save PDF screen close exactly once and cancellation can no longer roll back the committed document

### Requirement: PDF save accessibility, theming and layout
The Save PDF, password, progress, and temporary preview screens SHALL support screen readers, maximum supported text scaling, dark mode, and phone and tablet layouts, and SHALL operate offline.

#### Scenario: Screen reader on the save screen
- **WHEN** a screen reader traverses `pdf_save_screen`
- **THEN** page count, name, quality percentage, calculated-size status, protection status, Preview, and Save expose descriptive semantics including their current values

#### Scenario: Dark mode and tablet save screen
- **WHEN** the Save PDF screen is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and an adaptive width-limited layout without clipping or overflow

#### Scenario: Large text and phone layout
- **WHEN** the Save PDF screen is displayed on a phone at maximum supported text scale
- **THEN** all controls remain reachable in one scrollable safe-area-aware layout and every interactive target is at least 48dp

#### Scenario: Save workflow offline
- **WHEN** the device has no network connection
- **THEN** calculation, Preview, password configuration, and Save complete without a network request

#### Scenario: End-to-end save coverage
- **WHEN** the capture-to-document or page-table-creation end-to-end flow saves a PDF
- **THEN** it verifies quality change, calculation progress, password set/remove, Preview cancellation, Save during calculation, Save cancellation/retry, and successful closure exclusively through the specified keys and semantics
