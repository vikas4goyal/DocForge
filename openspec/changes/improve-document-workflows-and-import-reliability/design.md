## Context

The library currently has several independent presentation defects that share two architectural causes. First, screens receive incomplete data or infer business outcomes from callbacks: Detail is composed without the existing folder-options use case, duplicate and editor operations navigate as soon as a repository call returns, and there is no explicit selection or operation state. Second, imported PDFs do not create `DocumentPage` rows. Dashboard thumbnails bypass that absence by rendering page 1 from the PDF, while Detail, OCR, share-images, and share-text depend on stored page rows and therefore disagree about the same document.

This change spans document-library, viewer, PDF editing, import, OCR, and sharing. It must preserve feature-first dependency direction, offline operation, existing library files and Isar data, typed GoRouter navigation, secure password handling, and bounded rendering for large PDFs. Android and iOS are the only targets. The user-visible result must feel native and compact on iPhone while remaining responsive on Android phones and tablets.

## Goals / Non-Goals

**Goals:**

- Add deterministic multi-selection and bulk archive/trash outcomes to Dashboard and open-folder document lists.
- Present Dashboard and open-folder content in a quiet, Files-inspired adaptive grid with a rounded native-feeling search control and stable document metadata hierarchy.
- Make Move and Duplicate reviewed, truthful Detail workflows backed by loaded folder data.
- Make Detail, Viewer, and Editor chrome compact, accessible, and useful with long titles and large text.
- Give split, merge, compress, watermark, protect, and page-derived actions explicit input, review, progress, and result phases with one-shot submission.
- Give scanned and imported documents one page-access contract for previews, rendering, sharing, and text extraction.
- Prefer embedded PDF text and use OCR only when embedded text is absent.
- Make platform export ownership explicit so iOS and Android destinations are handled correctly.
- Cover the behavior through stable keys, semantics, previews, goldens, all three test tiers, and the existing end-to-end catalogue.

**Non-Goals:**

- Adding web or desktop targets, cloud OCR, networking, analytics, or a new PDF dependency.
- Eagerly rasterizing every imported PDF page or permanently duplicating those images.
- Redesigning the entire application navigation or visual system.
- Making a multi-document file mutation transactionally atomic across the filesystem and Isar.
- Changing the PDF password storage model or synchronizing OCR/favourite/archive metadata between devices.

## Decisions

### 1. A shared page-access contract represents both stored images and PDF-backed pages

Add immutable Freezed domain values in `lib/core/document_pages/`: `DocumentPageHandle`, a sealed `DocumentPageSource` (`storedImage` or `pdfPage`), and typed render/text outcomes. Add a `DocumentPageAccessRepository` abstraction with operations to list page handles, render a bounded image, and extract embedded text. The application composition root injects its infrastructure implementation into library preview, OCR, and sharing use cases. Features depend only on the core abstraction and never import one another.

For an imported PDF, the adapter reads the authoritative document page count and creates transient handles with a deterministic ID derived from document ID and one-based page number. It renders through the existing PDF engine only when a consumer requests a page. For a scanned document, the adapter exposes existing `DocumentPage` records and their stored images. Rendered thumbnails and share/OCR intermediates are private, reclaimable cache artifacts with an explicit lifetime; they are not authoritative page records.

This is preferred over writing synthetic `DocumentPage` rows because that model requires an image path and would falsely imply permanent page images. It is also preferred over feature-specific fallbacks because one contract prevents Dashboard, Detail, OCR, and sharing from disagreeing again. No Isar migration is required. The deterministic virtual ID lets existing recognised-text storage associate text with a PDF page without storing a fake raster row.

### 2. Embedded PDF text is the first extraction source and OCR is the fallback

Introduce an `ExtractDocumentText` application use case in OCR. For each requested page handle it asks page access for embedded text. Non-blank embedded text is normalized and persisted through the existing recognised-text repository. A page with no usable embedded text is rendered at the OCR input bound and passed to the injected on-device OCR repository. Mixed PDFs can therefore use both sources page by page.

Text availability is derived from actual persisted or extractable content rather than trusting only `Document.hasRecognisedText`. Internal search and recognition flows perform extraction when needed and report progress. After successful extraction, the document summary flag is repaired as a derived cache. The share sheet does not expose this internal text feature. Passwords are resolved through the existing secure-storage boundary and never enter Cubit state, logs, fixtures, or serialized models.

This is preferred over OCR-only extraction because text PDFs retain accuracy and reading order more reliably and avoid unnecessary CPU use. It reuses `pdfrx`/`pdfrx_engine`; no dependency is added.

### 3. Dashboard uses a lazy adaptive grid and platform-responsive search

Replace the document/folder list presentation with one sliver-based browsing surface. A persisted display-density value chooses Large or Small. Large renders exactly two columns at compact widths and preserves the current layout. Small renders three columns at compact widths and derives proportionally more columns at wider widths, reducing thumbnail area to roughly 40–50% while preserving two title lines and minimum touch targets. Wider widths derive both modes from available content width and documented minimum extents, allowing iPad multitasking and Android tablets to settle naturally without device-name checks.

Each document tile has stable vertical regions: a portrait-oriented thumbnail well with a restrained rounded surface and PDF placeholder, a maximum two-line title, one modified-time line, and one formatted file-size line. Each folder tile uses a quiet platform-appropriate folder glyph/preview in the same geometry, followed by a maximum two-line name, modified time, and recursive document count instead of a misleading byte size. Metadata uses secondary theme colours and compact text styles; thumbnails carry the visual emphasis. Tiles avoid decorative gradients, heavy elevation, oversized radii, and cartoon-like icon treatments. The result borrows the Files app's information hierarchy, spacing discipline, and low visual noise but uses DocScanly theme tokens and original assets.

Tile geometry never changes when selection mode begins. Selection is expressed by an accessible check affordance, semantic selected state, and subtle theme-colour outline/tint over the existing tile. `Key('document_thumbnail_<document-id>')` remains on the preview and the existing document-row action identity is retained or aliased at the tile boundary so navigation robots do not depend on a list-specific implementation.

`Key('dashboard_search_field')` becomes a rounded adaptive search control labelled “Search documents and folders”. It supports focus, clear, platform-appropriate cancel/dismiss behavior, keyboard search action, and the existing deterministic search Cubit path. Query submission/filtering remains in the application use case; presentation only forwards normalized user input. If keystroke frequency requires protection, the Cubit uses an injected deterministic debounce/scheduler rather than widget-local timers or static state. Search results use the same grid, while empty results preserve `document_list_empty_state` and provide the query in accessible text.

The entire page remains one lazy vertical scroll surface. Root discovery sections may precede the grid, but grid construction and thumbnails are lazy and bounded to visible/near-visible tiles. `SliverGridDelegateWithFixedCrossAxisCount` is used for the compact two-column branch and an extent/breakpoint-derived delegate for wider constraints; tile height is calculated from bounded thumbnail aspect, two title lines, and two metadata lines so heterogeneous content does not cause masonry movement. This is preferred over a fixed tablet column count because width can change under rotation and iPad split view, and over a masonry grid because stable rows are calmer, faster, and make multi-selection easier to track.

### 4. Selection and bulk mutation are explicit library state

Dashboard and folder list Cubits gain immutable `selectionMode`, `selectedDocumentIds`, and `bulkOperation` fields. Selection begins through `Key('dashboard_select_button')` with semantics “Select documents” or a long press on a document row. Folder rows remain navigation targets and cannot enter the document selection set. The toolbar uses `dashboard_selection_toolbar`, `dashboard_select_all`, `dashboard_bulk_archive`, `dashboard_bulk_trash`, and `dashboard_selection_cancel`; Trash confirmation uses `dashboard_bulk_trash_confirm`.

`BulkArchiveDocuments` and `BulkTrashDocuments` use cases own ordering, validation, and per-document mutation. They return a Freezed `BulkDocumentOutcome` containing ordered successes and typed failures. Operations are sequential and guarded against a second submission. On partial failure, successful items leave the list, failed items remain selected, and a visible summary identifies counts and a retry action. This is preferred over optimistic all-or-nothing UI because filesystem/metadata mutations cannot be made atomically across all documents. Cubits only invoke the use case and emit states; no business rule lives in presentation.

### 5. Detail owns loadable folder options and a reviewed duplicate request

`DocumentDetailCubit` receives `LoadFolderOptions`, `MoveDocument`, and an extended `DuplicateDocument` through its constructor. Its state contains separate immutable phases for document loading, folder-option loading (`idle/loading/ready/empty/failure`), and duplicate (`idle/reviewing/submitting/succeeded/failure`). Every field participates in `props`.

The composition root stops passing a default empty list. Opening Move loads the real hierarchy and presents `document_move_picker` with Root and eligible folders under `document_move_folder_<folder-id>`, excluding the current destination. `document_move_confirm` is enabled only for a changed destination. Loading, genuine empty, and retryable failure are distinct and screen-reader-labelled.

Duplicate opens `document_duplicate_dialog` with source summary, collision-safe proposed name in `document_duplicate_name`, and destination in `document_duplicate_folder`. `document_duplicate_confirm` validates and submits once. Success announces “Created <name>” and uses the existing typed detail route to replace the old Detail destination with the new document; the explicit review and result make that transition intentional. Cancellation creates nothing. The request and outcome are Freezed domain values; if serialized later they use generated JSON, never manual parsing.

### 6. Compact chrome preserves title space and makes page jumping intentional

Detail uses `titleMedium`/bounded two-line body text instead of a headline-sized duplicate title. Viewer and Editor app bars render a one-line ellipsized title with a semantic full-title value and reserve at most one primary action on narrow widths. Secondary actions move into adaptive overflow controls (`viewer_actions_menu` and `pdf_edit_actions_menu`) while retaining their existing action keys on menu items.

The Viewer removes the persistent 120-point numeric text field. `viewer_page_jump_button`, labelled “Page <current> of <total>, jump to page”, opens `viewer_page_jump_dialog`; only then does `viewer_page_jump_field` request a numeric keyboard. `viewer_page_jump_confirm` accepts only 1 through page count and keeps invalid input visible with an error. This is preferred over shrinking the existing field because an always-editable control still consumes space and opens the keyboard without explaining the action.

In Editor, page actions are absent until pages are selected, then appear in a contextual action area or the overflow menu. Unsupported actions are omitted; temporarily unavailable actions expose an explanation instead of inert icons. Responsive decisions use layout constraints and platform-adaptive controls, not device-name checks.

### 7. PDF operations use a common input-review-progress-result state machine

`PdfEditCubit` remains a Cubit because the workflow is linear and user-driven; a full Bloc adds no event-transformer benefit. Its immutable state adds a sealed operation draft, phase (`idle/input/review/submitting/succeeded/failed`), and operation token. Input validation and operation semantics live in use cases/domain values; the Cubit coordinates presentation only. Starting a submission creates one token, disables all submit controls, and ignores repeated confirms until that token resolves. Consuming a success clears the token before navigation, preventing a listener rebuild from navigating or creating files twice.

The shared sheet has `pdf_edit_operation_sheet`, `pdf_edit_review`, `pdf_edit_confirm`, `pdf_edit_cancel`, and `pdf_edit_result`. Existing operation keys remain entry points. Split requires a boundary and two collision-safe output names, then shows both outputs; PDF 1/PDF 2 section headings replace redundant floating name labels so the prefilled fields cannot visually overlap their labels. Each output can be opened and Done returns to Dashboard. Merge requires document selection and ordering, then opens the one created result. Compress explicitly states that it replaces the current PDF and reports before/after size while staying in Editor. Watermark previews the entered text over the bounded first-page thumbnail rather than a generic sample card. Watermark and Protect review all inputs and update the current document in place. Page extract/duplicate and other derived actions show the same progress/result contract and open exactly one result where applicable.

This common state machine is preferred over bespoke dialogs because it gives consistent cancellation, accessibility, error mapping, and duplicate-tap protection while allowing operation-specific input widgets.

The Viewer overflow menu is the primary entry point for Print, Compress, Split, Watermark, and Set/Remove Password. Selecting an operation routes directly to its focused adaptive sheet or full-screen form and initializes the same state machine; it does not require an intermediate editor hub. The page-management editor remains reachable only for operations that genuinely require selecting or reordering page thumbnails.

### 8. Export ownership belongs to the platform-edge repository

Replace the “pick a path, then application code copies to that path” contract with `ExportDocumentRepository.export(source, suggestedName)`, returning a Freezed result of `completed`, `cancelled`, or typed stage failure. Its Android/iOS implementation owns the entire platform picker/handoff/write contract and may pass bytes to a provider or copy to a confirmed filesystem path according to the plugin/platform API. Application code never assumes a provider result is a writable local path and never appends a `.partial` sibling beside a provider destination.

Share-images obtains handles from page access, renders only selected pages with bounded concurrency, retains temporary files through the share handoff, then cleans them. OCR and embedded-text extraction remain available to internal search/recognition consumers, but the share sheet no longer exposes Share Extracted Text. Share state distinguishes preparing content, handing off to the platform, exporting, completed, cancelled, and failed stages so messages identify what the user can retry.

This is preferred over iOS-only branching in a Cubit or use case because platform semantics belong at the infrastructure edge and can be deterministically faked in component and integration tests.

### 9. Composition, persistence, navigation, and documentation stay explicit

The application root constructs page access, text extraction, export repositories, use cases, and Cubits through constructors and supplies Cubits with `BlocProvider`. There is no service locator, singleton, static mutable cache, global operation flag, randomness, or wall-clock-generated identity. Operation IDs and virtual page IDs are deterministic values based on inputs or injected ID generation where a new document ID is required.

Authoritative document metadata, folder paths, and recognised text remain in Isar; simple UI selection and workflow drafts are transient Cubit state and are not persisted; passwords remain in `flutter_secure_storage`; no new `SharedPreferences` data is required. Existing typed GoRouter routes are reused, adding a typed result route only if the split-result presentation cannot be hosted in the editor. No feature code uses route strings.

Every new public model, repository, use case, Cubit, state, widget, constructor, and key constant receives Effective Dart dartdoc. Inline comments explain deterministic virtual IDs, PDF-engine isolate/concurrency boundaries, provider export ownership, cache cleanup timing, and the one-shot operation token.

### 10. Preview and verification fixtures mirror every meaningful state

Reusable grid tile, rounded search, selection toolbar, move picker, duplicate dialog, jump dialog, operation sheet/result, and share status widgets receive deterministic fixture-backed `@Preview()` entries for default, loading, empty, error, and long content. Changed Dashboard/folder, Detail, Viewer, Editor, and Share screens add phone/tablet and light/dark previews; Dashboard additionally covers two-column compact width, three-or-more-column wide width, long two-line/truncated titles, folder/document metadata, focused/query/no-results search, selection without reflow, and supported large text. Large-text and iOS/Android variants cover the materially adaptive layouts. No preview reaches Isar, filesystem, platform plugins, network, or wall clock.

Tier 1 covers the grid layout policy at compact/wide/split-view widths, metadata formatting, search state/debounce behavior, domain values, use cases, repository adapters, Cubit sequences, one-shot tokens, virtual IDs, embedded-text fallback, cache cleanup, and export result mapping. Tier 2 wires each changed screen to real Cubits/use cases with repository/platform fakes. Goldens cover the Dashboard/folder grid and search on phone/tablet, then light/dark, long titles, large text, selection, review, result, and failure states. Tier 3 extends organise, edit, import, browse-and-view, and share flows using only declared keys and semantics.

### 11. Camera creation and naming use explicit reversible steps

Opening camera capture first shows a live preview and never invokes capture automatically. Only the labelled shutter action creates a photo. Crop handles use larger invisible hit regions than their visual marks, drag updates are continuous, and flip updates the preview immediately. Crop Apply advances to Enhance; Enhance Back restores the same Crop state instead of closing the creation flow. Confirmation titles use compact responsive typography.

When captured pages require individual output names, the flow pushes a dedicated scrollable naming screen instead of opening a dialog. Its app bar has Cancel/close on the leading side and Done/check on the trailing side. Each ordered section is labelled Page 1, Page 2, and so on and contains the corresponding preview and editable name. Done validates all names before creating output; Cancel creates nothing.

### 12. Settings sheets and final rows respect usable safe areas

The PDF-quality chooser is height-constrained, scrollable when necessary, and wrapped in keyboard/view and bottom safe-area padding so supported text scales cannot overflow. The Settings scroll surface includes explicit bottom content padding in addition to the device inset, leaving comfortable separation below Privacy Policy and above the tab bar or home indicator.

## Risks / Trade-offs

- **[Risk] Large imported PDFs can make multi-page sharing or OCR slow and memory-heavy.** → Render lazily with bounded concurrency, release PDF page/image objects promptly, expose progress, and clean temporary files after platform handoff.
- **[Risk] A bulk filesystem mutation can partially succeed.** → Return ordered per-item outcomes, retain failed selections, refresh from authoritative storage, and offer retry without pretending the batch is atomic.
- **[Risk] Two columns can become cramped at extreme accessibility text sizes.** → Preserve two columns at normal compact widths, bound metadata lines, expose full values to semantics, and allow the documented accessibility breakpoint to use a single column when two columns cannot meet minimum touch/readability constraints.
- **[Risk] Thumbnail-heavy grids can trigger excessive PDF work during fast scrolling.** → Keep lazy slivers, request bounded previews only for visible/near-visible tiles, cancel obsolete work, and retain stable lightweight placeholders.
- **[Risk] Deterministic virtual IDs could collide with stored page IDs.** → Namespace the ID input by source kind and document ID and unit-test stability/collision boundaries.
- **[Risk] Embedded PDF text can be empty, malformed, or poorly ordered.** → Normalize defensively, reject blank output, fall back page-by-page to OCR, and preserve typed failures.
- **[Risk] iOS document providers differ in whether they expose paths or accept bytes.** → Keep all destination semantics inside the platform adapter, test completion/cancellation/failure contracts, and verify on an attached iOS target.
- **[Risk] Replacing the current Detail route after duplication can still surprise a user.** → Require a reviewed name/destination, disable repeated confirmation, announce the created copy by name, and make the new title/destination immediately visible.
- **[Trade-off] Unsupported editor actions disappear instead of remaining disabled.** → This reduces discoverability but avoids inert controls; contextual help explains how selection exposes page actions.
- **[Trade-off] Imported pages do not become permanent `DocumentPage` records.** → Consumers must use page access, but storage remains bounded and the PDF stays the single authority.

## Migration Plan

1. Add the shared page values/repository and adapter while keeping existing thumbnail behavior behind the new contract.
2. Route Detail previews, share-images, and OCR through page access; backfill no page rows and perform no destructive Isar migration.
3. Introduce embedded-text extraction and repair summary availability only after successful persistence.
4. Replace export destination handling behind the repository without changing existing document files.
5. Add selection, Detail workflows, compact chrome, and editor state machine behind their current entry points.
6. Run format, analysis, layering/platform checks, Tier 1/2, goldens, coverage, and attached Android/iOS Tier 3 verification.

Rollback removes the new presentation entry points and returns consumers to their previous adapters; authoritative PDFs, Isar document rows, stored scan pages, and secure credentials remain unchanged. Cache artifacts can be deleted safely. If implementation discovers that a persistent page-source discriminator is unavoidable, work stops for an additive schema/migration design and migration tests before modifying Isar.

## Open Questions

- Confirm through the installed file-picker/plugin source and attached-device tests whether each iOS provider path uses byte-based save, security-scoped copy, or share/export handoff; the repository contract intentionally supports any of these implementations.
- Decide during implementation whether the two-output split result fits cleanly in the Editor shell or warrants a small typed result route; either choice must preserve the specified keys and navigation outcome.
