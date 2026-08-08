## ADDED Requirements

### Requirement: Compression size calculation and preview
The Compress PDF screen SHALL show original bytes and calculate the exact bytes of a candidate for the current 30–100% selection without blocking Preview or Save, and SHALL let the user inspect that candidate before committing it.

#### Scenario: Original and calculated sizes
- **WHEN** `Key('pdf_compress_screen')` opens
- **THEN** `Key('pdf_compress_original_size')` announces the original human-readable size and `Key('pdf_output_size_status')` reports calculation progress before announcing the exact candidate size and saving

#### Scenario: Latest quality owns the result
- **WHEN** the user changes `Key('pdf_compress_quality_slider')` while calculation is queued or running
- **THEN** obsolete work is cancelled and only the latest quality selection may update `pdf_output_size_status`

#### Scenario: Preview compressed candidate
- **WHEN** the user activates `Key('pdf_compress_preview_button')` with semantics label “Preview compressed PDF”
- **THEN** `pdf_job_progress_dialog` reports preparation progress and a successful candidate opens `pdf_temporary_preview_screen` with the same page count as the source

#### Scenario: Cancel compression preview
- **WHEN** the user cancels preview preparation or closes the temporary preview
- **THEN** no source mutation occurs and `pdf_compress_screen` remains open with its quality and calculated-size state retained

#### Scenario: Save while calculation is unfinished
- **WHEN** the user activates `Key('pdf_compress_save_button')` while calculation is queued, running, failed, or absent
- **THEN** the Save decision flow begins immediately without waiting for calculation

#### Scenario: Calculation failure remains recoverable
- **WHEN** compression-size calculation fails
- **THEN** `pdf_output_size_status` presents Retry while Preview and Save remain available

### Requirement: Compression commit progress and cancellation
Preparing and committing a compressed copy or overwrite SHALL run off the UI thread, report progress, be cancellable until commit, and leave no partial output.

#### Scenario: Compression save progress
- **WHEN** the user chooses copy or overwrite
- **THEN** modal `Key('pdf_job_progress_dialog')` displays `pdf_job_progress_indicator` with semantics “Saving PDF, <percent> percent” and `pdf_job_cancel_button`

#### Scenario: Cancel compression save
- **WHEN** the user activates `pdf_job_cancel_button` before commit completes
- **THEN** work stops, no partial copy or source mutation remains, and `pdf_compress_screen` remains open with all configuration retained

#### Scenario: Compression save failure
- **WHEN** preparation or commit fails
- **THEN** the source remains unchanged, no partial output remains, and `Key('pdf_edit_error_view')` displays a typed human-readable failure with Retry or recovery

#### Scenario: Compression save completes
- **WHEN** commit and verification reach 100%
- **THEN** the progress dialog and Compress PDF screen close exactly once; a copy opens the new document and overwrite refreshes the original document

### Requirement: Per-page compression quality overrides
Compress PDF SHALL use the document compression percentage as the default for every page and SHALL let the user set or remove a 30–100% override for an individual page without changing the document default or any other page.

#### Scenario: Override one compressed page
- **WHEN** the user activates `Key('pdf_compress_page_quality_<page-number>')`, chooses 50% in `pdf_page_quality_slider`, and confirms
- **THEN** only that page uses 50%, its row announces that it overrides document quality, and exact-size calculation restarts for the effective page plan

#### Scenario: Document quality changes around an override
- **WHEN** the user changes `pdf_compress_quality_slider` while one page has an override
- **THEN** non-overridden pages use the new document percentage and the overridden page retains its explicit percentage

#### Scenario: Use document compression quality
- **WHEN** the user activates `pdf_page_quality_use_document` for an overridden compressed page
- **THEN** that override is removed and the page uses the current document compression percentage

#### Scenario: Reset all compression overrides
- **WHEN** the user activates `pdf_page_quality_reset_all`
- **THEN** every page override is removed without changing `pdf_compress_quality_slider`

#### Scenario: Mixed 100 percent plan
- **WHEN** the document percentage is 100% and at least one page override is below 100%
- **THEN** compression processes the lower-quality page, preserves effective-100% pages without downsampling when supported, and does not show the all-pages-no-compression warning

## MODIFIED Requirements

### Requirement: Compress PDF
The application SHALL provide a dedicated Compress PDF screen with a 30–100% quality slider initially set to 80%, report original and exact candidate sizes, preserve page count, and require an explicit choice to save a copy or overwrite the original.

#### Scenario: Open Compress PDF
- **WHEN** the user activates the control with key `pdf_compress_button` or chooses Compress from the Viewer overflow menu
- **THEN** typed navigation opens full-page `Key('pdf_compress_screen')` containing `pdf_compress_quality_slider`, `pdf_compress_original_size`, `pdf_output_size_status`, `pdf_compress_preview_button`, and `pdf_compress_save_button`

#### Scenario: Compression quality meaning
- **WHEN** the user adjusts `pdf_compress_quality_slider` with semantics “Compression quality, <percent> percent” below 100%
- **THEN** every page is rendered and downscaled to the selected percentage of the bounded source width and height, the page count and order remain unchanged, and the UI does not claim that byte size changes by the same percentage

#### Scenario: Default compression quality
- **WHEN** the Compress PDF screen opens
- **THEN** `pdf_compress_quality_slider` displays 80% regardless of the Settings PDF-quality default

#### Scenario: Saving at 100 percent
- **WHEN** the user activates `pdf_compress_save_button` while every page is effectively 100%
- **THEN** `Key('pdf_compress_no_compression_dialog')` explains that every page keeps the current PDF quality and the file is not expected to reduce in size, offers Continue and Adjust, and makes no mutation before Continue

#### Scenario: Choose copy or overwrite
- **WHEN** the user continues Save at any quality
- **THEN** `Key('pdf_compress_destination_dialog')` asks for `Key('pdf_compress_save_copy')` with semantics “Save as a copy” or `Key('pdf_compress_overwrite')` with semantics “Replace original”

#### Scenario: Save compressed copy
- **WHEN** the user chooses `pdf_compress_save_copy`
- **THEN** one valid collision-safe copy is created with the selected quality and resulting size, the source remains unchanged, and success opens the copy

#### Scenario: Overwrite original
- **WHEN** the user chooses `pdf_compress_overwrite`
- **THEN** a verified candidate atomically replaces the original, its document record receives the resulting size and modified date, and success refreshes the original document

#### Scenario: Compression result reported
- **WHEN** compression completes
- **THEN** the result reports original size, resulting size, bytes saved and percentage saved, and page count is unchanged

#### Scenario: Compression yields no benefit
- **WHEN** a below-100% candidate would not reduce file size
- **THEN** the user is informed before commit and can return to adjust quality or explicitly continue with the chosen copy/overwrite behavior

### Requirement: Explicit PDF operation workflows and outcomes
Every page-derived and whole-document editing operation SHALL expose the inputs and effect before mutation, require an explicit confirmation, submit at most once, report progress, and show a concrete success or typed failure outcome. The editor SHALL navigate to newly created results or visibly refresh an in-place result as appropriate.

#### Scenario: Operation input and review
- **WHEN** the user starts split, merge, watermark, protect, page extract, or another derived operation
- **THEN** `Key('pdf_edit_operation_sheet')` presents required inputs and effect, `Key('pdf_edit_review')` summarizes the affected source and output behavior, and no mutation occurs before `Key('pdf_edit_confirm')` is activated

#### Scenario: Direct operation entry
- **WHEN** the user chooses Compress, Split, Watermark, or Set/Remove Password from the Viewer overflow menu
- **THEN** Compress opens `pdf_compress_screen`, while the other operation opens its corresponding focused input sheet or screen and initializes the common workflow without first opening the generic PDF editor screen

#### Scenario: Operation cancellation
- **WHEN** the user activates `Key('pdf_edit_cancel')` before confirmation
- **THEN** the workflow closes without changing the source or creating an output

#### Scenario: Duplicate submission guard
- **WHEN** an operation is submitting
- **THEN** confirmation and operation entry controls are disabled, `Key('pdf_edit_progress')` reports progress, and repeated taps cannot perform the operation or navigate more than once

#### Scenario: Split review and result
- **WHEN** the user starts Split
- **THEN** the workflow requires a valid split boundary and two collision-safe output names before confirmation, with separate PDF 1/PDF 2 section headings that do not collide with redundant floating field labels
- **AND** success displays `Key('pdf_edit_result')` listing both new documents, allows either output to be opened, and allows Done to return to Dashboard while the source remains unchanged

#### Scenario: Merge selection and ordering
- **WHEN** the user starts Merge
- **THEN** the workflow requires at least two eligible documents, exposes `Key('pdf_merge_order_list')` for user ordering, reviews the output name, and success opens exactly one new merged document while source documents remain unchanged

#### Scenario: Compress configuration and result
- **WHEN** the user starts Compress
- **THEN** the dedicated Compress PDF workflow exposes quality, size calculation, Preview, copy/overwrite review, progress, cancellation, and the specified copy navigation or original refresh result

#### Scenario: Watermark input review
- **WHEN** the user starts Watermark
- **THEN** the user sees the entered watermark over the current document's bounded first-page thumbnail, reviews the text and visual settings before confirmation, and success visibly refreshes the current document once

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
- **THEN** it observes review, one submission, progress, cancellation/retry, and the specified result/navigation for each operation exclusively through keys and semantics

### Requirement: PDF editing accessibility, theming, layout and offline behaviour
The PDF editing screens, including Compress PDF and temporary preview, SHALL support screen readers, maximum supported text scaling, dark mode, phone and tablet layouts, and SHALL operate without network connectivity.

#### Scenario: Screen reader on editing tools
- **WHEN** a screen reader traverses the PDF editor or Compress PDF
- **THEN** every editing control exposes a descriptive semantics label and current value, and each page thumbnail announces its page number and selection state

#### Scenario: Dark mode and tablet editor
- **WHEN** the editor or Compress PDF is displayed in dark mode on a tablet-width viewport
- **THEN** it uses the dark colour scheme and adapts to the wider viewport without clipping or overflow

#### Scenario: Large text compression layout
- **WHEN** `pdf_compress_screen` is displayed on a phone at maximum supported text scale
- **THEN** all settings, sizes, Preview, and Save remain reachable in a safe-area-aware scroll view with targets at least 48dp

#### Scenario: Editing offline
- **WHEN** the device has no network connection
- **THEN** every PDF editing operation, size calculation, and temporary preview completes with no network request
