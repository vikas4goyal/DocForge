## 1. Shared document page access

- [x] 1.1 Add documented Freezed `DocumentPageHandle`, sealed page-source/result values, deterministic virtual-page ID rules, and the core `DocumentPageAccessRepository` contract without adding an Isar schema.
- [x] 1.2 Add Tier-1 tests for stored-image handles, stable imported-PDF identities, source namespacing, ordering, typed locked/missing/corrupt failures, and Freezed value equality.
- [x] 1.3 Implement the documented page-access adapter over existing page storage, PDF resolver, secure password source, and `pdfrx`, with bounded render sizes and explicit cache lifetimes.
- [x] 1.4 Add Tier-1 adapter tests for stored scans, imported PDFs without page rows, protected PDFs, lazy rendering, cache cleanup, and large-page bounds.
- [x] 1.5 Compose page access explicitly at the application root and inject it into library preview, OCR, and sharing consumers without feature-to-feature imports or service location.
- [x] 1.6 Add layering/composition tests proving all page consumers receive the shared contract and existing documents require no migration.

## 2. Imported-PDF previews and text extraction

- [x] 2.1 Route Detail page enumeration and thumbnail loading through page access so imported PDFs expose all stable page handles and never depend on synthetic permanent image rows.
- [ ] 2.2 Add Tier-1 Detail Cubit/use-case tests and Tier-2 Detail component tests for imported pages, lazy previews, protected/missing/corrupt failures, and dashboard/detail consistency.
- [x] 2.3 Implement documented embedded-PDF text extraction and page-by-page on-device OCR fallback, persisting ordered results under stable page IDs and repairing text summary metadata after success.
- [x] 2.4 Add Tier-1 extraction tests for embedded text, image-only OCR, mixed PDFs, blank pages, persisted reuse, stale-summary repair, cancellation, and protected-page credential isolation.
- [ ] 2.5 Add Tier-2 OCR/extracted-text component coverage using real Cubits/use cases and page/text repository fakes for stored, embedded, fallback, progress, empty, and error states.
- [ ] 2.6 Update the `import`, `browse_and_view`, and `share` Tier-3 robots/flows to prove a text-heavy imported PDF has matching Dashboard/Detail previews and locally extractable text.

## 3. Dashboard and folder multi-selection

- [x] 3.1 Add documented Freezed bulk requests/outcomes and `BulkArchiveDocuments`/`BulkTrashDocuments` use cases with deterministic ordering, per-item typed failures, and retry-safe behavior.
- [x] 3.2 Add Tier-1 use-case tests for all-success, all-failure, partial failure, ordered processing, retry input, and confirmed Trash requirements.
- [x] 3.3 Extend Dashboard and folder-list Cubits with fully equatable selection and bulk-operation states, long-press/select-all rules, document-only eligibility, progress, cancellation, and one-shot submission.
- [x] 3.4 Add `bloc_test` coverage for every selection transition, list refresh, partial-failure retention, duplicate-tap guard, and exit-selection path.
- [x] 3.5 Implement and document the deterministic library-grid layout policy and metadata formatters for two-column compact widths, minimum-extent wide columns, split-view resizing, one-column accessibility fallback, two-line names, modified time, file size, and folder document count.
- [x] 3.6 Add Tier-1 tests for compact/wide/split-view/accessibility column decisions, stable tile extent, long-name bounds, document size/time formatting, folder counts, and deterministic behavior at exact breakpoints.
- [x] 3.7 Implement the lazy Dashboard/open-folder sliver grid, bounded portrait thumbnails/placeholders, quiet folder treatment, stable selection overlay, and rounded platform-adaptive search using the existing search use-case boundary.
- [x] 3.8 Add/update `dashboard_content_grid`, `dashboard_document_<document-id>`, `dashboard_folder_<path-token>`, `dashboard_search_field`, `dashboard_search_clear`, selection controls, and exact semantics in the library key registry; update dartdoc for every changed public widget/key.
- [x] 3.9 Add Tier-1 Dashboard Cubit/search tests for normalized queries, clear/cancel, results/no-results, deterministic debounce scheduling if required, and preservation of selection/grid content through search transitions.
- [ ] 3.10 Add Tier-2 Dashboard and folder component tests with real Cubits/use cases for two-column phone and adaptive iPad/tablet grids, split-view resize, accessibility fallback, long metadata, lazy thumbnails, rounded search, empty/loading/error/no-results, empty/partial/all selection, archive, Trash confirmation, progress, partial failure, retry, dark mode, and offline use.
- [ ] 3.11 Add fixture-backed `@Preview()` coverage and iPhone/iPad/Android phone/tablet light/dark/large-text goldens for two-column/adaptive grids, long two-line names, document/folder metadata, rounded search idle/focused/query/no-results, selection without reflow, working, and partial failure.
- [ ] 3.12 Update the `browse_and_view` and `organise` robots and Tier-3 flows to assert compact/wide grid behavior, search/clear/open through keys and semantics, stable multi-selection, bulk archive, and confirmed bulk Trash in Dashboard and an open folder.

## 4. Detail move, duplicate, and compact presentation

- [x] 4.1 Extend documented duplicate request/naming logic and `DuplicateDocument` to accept a validated title and destination while preserving independent file identity and collision safety.
- [x] 4.2 Add Tier-1 duplicate tests for proposed names, edited names, destination changes, collisions, cancellation/no mutation, failure, and exactly-one creation.
- [x] 4.3 Refactor `DocumentDetailCubit` into equatable document, folder-option, move, and duplicate phases; inject `LoadFolderOptions`, move, and duplicate use cases explicitly from composition.
- [x] 4.4 Add `bloc_test` coverage for folder loading/ready/empty/error/retry, current-folder exclusion, move refresh, duplicate review/submitting/success/failure, cancellation, and repeated-confirm suppression.
- [x] 4.5 Implement the populated move picker and reviewed duplicate dialog with the specified `document_move_*` and `document_duplicate_*` keys, semantics, validation, progress, announcement, and typed result navigation.
- [x] 4.6 Make Detail app-bar/body title typography compact and responsive with bounded long-title display and full-title semantics while retaining the Open action.
- [ ] 4.7 Add Tier-2 Detail component tests for created-folder discovery, Root/current destinations, empty/error/retry, reviewed duplication, navigation callback count, long titles, large text, imported previews, and offline behavior.
- [ ] 4.8 Add fixture-backed `@Preview()` entries and phone/tablet light/dark/large-text goldens for Detail default/loading/empty/error/long-title, move picker, duplicate review/progress/success/failure.
- [ ] 4.9 Update the `organise` robot and Tier-3 flow to create a folder, load it from Detail, move a document, duplicate with a reviewed name/destination, and observe exactly one new Detail result.

## 5. Compact Viewer workflow

- [x] 5.1 Replace the persistent page-number text field with the compact page-jump button/dialog and bounded validation while preserving current-page synchronization.
- [x] 5.2 Make Viewer title/action layout responsive, add `viewer_actions_menu`, preserve share/print/edit keys on reachable actions, and omit or explain unavailable actions.
- [x] 5.3 Add/update all Viewer keys and exact semantics in the Viewer key registry and document public widgets/Cubit APIs plus the intentional keyboard and responsive-layout behavior.
- [x] 5.4 Add `bloc_test`/Tier-1 widget tests for jump dialog open/valid/invalid/cancel, page synchronization, constrained action placement, and unavailable-action behavior.
- [x] 5.5 Add Tier-2 Viewer component tests with real Cubit/use cases for long titles, jump validation, overflow actions, loading/error, phone/tablet, dark mode, large text, and offline rendering.
- [ ] 5.6 Add fixture-backed `@Preview()` entries and Viewer goldens for default/loading/error/long-title, jump dialog/validation, phone/tablet, light/dark, and large text.
- [x] 5.7 Update the `browse_and_view` robot and Tier-3 flow to jump pages only through the compact control and reach share, print, and edit through stable keys/semantics.

## 6. Explicit PDF editing workflows

- [x] 6.1 Add documented Freezed operation drafts/reviews/results and use-case validation for split boundaries/output names, merge selection/order/name, compression replacement, watermark settings, protection effect, and derived page outputs.
- [x] 6.2 Add Tier-1 domain/use-case tests for each valid and invalid operation input, source preservation, output naming, result cardinality, and typed failure mapping.
- [x] 6.3 Refactor `PdfEditCubit` into equatable input/review/submitting/succeeded/failed phases with an operation token cleared before callbacks and no business rules in Cubit code.
- [ ] 6.4 Add comprehensive `bloc_test` state-sequence coverage for cancel, progress, success, failure, retry, repeated-confirm suppression, and exactly-one navigation for every operation family.
- [x] 6.5 Implement the shared adaptive operation sheet/result UI and operation-specific split, merge, compress, watermark, protect, and derived-page inputs using the specified `pdf_edit_*` keys and semantics.
- [x] 6.6 Make Editor chrome responsive: preserve the semantic full title, add `pdf_edit_actions_menu`, hide page actions until selection, and replace unexplained inert controls with omission or an accessible reason.
- [ ] 6.8 Add Tier-2 Editor component tests with real Cubit/use cases for every input/review/progress/result/failure path, two-output Split result, one-output navigation, in-place refresh, contextual actions, long titles, and large text.
- [ ] 6.9 Add fixture-backed `@Preview()` entries and phone/tablet light/dark/large-text goldens for Editor and every operation's input, review, working, success, failure, empty, and long-content states.
- [ ] 6.10 Update the `edit` robot and Tier-3 flow to perform split, merge, compress, watermark, protect, and a derived page action while asserting one submission and the specified visible result/navigation.

## 7. Sharing images, text, and platform export

- [x] 7.1 Route share-images through page access with ordered bounded rendering and handoff-safe temporary-file cleanup for both stored scans and imported PDFs.
- [x] 7.2 Add Tier-1 share-image tests for selections/order, imported PDFs without page rows, protected pages, render failure stages, handoff lifetime, cleanup, and cancellation.
- [x] 7.3 Route text availability through persisted/embedded/OCR extraction, exposing progress and truthful no-text/retry outcomes instead of relying only on document summary metadata.
- [x] 7.4 Add Tier-1 share-text tests for stored text, stale flags, embedded text, OCR offer/fallback, blank results, protected PDFs, ordered output, and failures.
- [x] 7.5 Replace path-returning export behavior with the documented platform-owned export repository/result contract and implement deterministic Android/iOS adapters for completion, cancellation, collision, provider handoff, and stage failure.
- [x] 7.6 Add Tier-1 export adapter/use-case tests proving exactly-one write, no application `.partial` path beside provider items, cancellation as non-error, collision delegation, cleanup, and stage-specific failures.
- [x] 7.7 Extend Share Cubit equatable state and UI for preparing, handoff, exporting, completed, cancelled, and failed stages; add `share_export_done` plus updated keys and exact semantics to the share registry.
- [ ] 7.8 Add `bloc_test` and Tier-2 Share component coverage with real Cubit/use cases for scanned/imported images, absent extracted-text action, export success/cancel/failure, platform differences, progress, long names, dark mode, tablet, and offline use.
- [ ] 7.9 Add fixture-backed `@Preview()` entries and phone/tablet light/dark/large-text goldens for Share default/loading/empty/error/long-content, preparation, handoff, export completion, cancellation, and each failure stage.
- [ ] 7.10 Update the `share` robot and Android/iOS Tier-3 flow to share imported PDF pages as images, prove extracted text is not offered, export successfully, cancel without error, and recover from deterministic provider failure.

## 8. Documentation and verification

- [x] 8.1 Review every new or changed public API for complete Effective Dart dartdoc and add concise inline comments for virtual IDs, cache lifetimes, PDF concurrency, provider ownership, and one-shot operation ordering; remove stale comments and hidden/static mutable state.
- [x] 8.2 Run code generation where required, `dart format --set-exit-if-changed`, `flutter analyze`, `tool/check_layering.dart`, and `tool/check_platforms.dart`; resolve every failure.
- [x] 8.3 Run Tier-1 and Tier-2 tests, golden tests, and coverage verification; keep overall coverage at least 80% and business-logic coverage at least 90%, resolving every regression.
- [ ] 8.4 Verify share/export, PDF rendering, OCR, and navigation on attached Android and iOS targets, including an iOS document provider and supported large-text settings.
- [x] 8.5 Run `tool/verify.dart` and report its per-stage result. The change is not done while any stage fails, and a run that reports Tier 3 as SKIPPED (no device attached) does not count as verified.

## 9. Density, camera creation, focused PDF actions, and settings polish

- [x] 9.1 Add a persisted Large/Small library density value, deterministic compact/wide layout policies, `dashboard_display_size_menu` keys/semantics, and Tier-1 tests proving Large preserves the current layout while Small uses a three-column phone grid without losing selection/search state.
- [x] 9.2 Implement Large/Small Dashboard and open-folder presentation, adaptive iPad/tablet counts, bounded thumbnails, accessible touch targets, and component/golden coverage for both modes.
- [x] 9.3 Remove automatic camera capture, require the explicit shutter action after a visible live preview, and add camera-flow tests proving no capture occurs on entry.
- [x] 9.4 Make Enhance Back restore Crop state, make Crop flip preview immediate, enlarge invisible corner/edge hit regions, smooth continuous drag updates, compact confirmation titles, and add widget/component tests for navigation and manipulation.
- [x] 9.5 Replace the multi-page naming popup with a dedicated scrollable `page_naming_screen`, leading Cancel/close, trailing Done/check, ordered Page sections without overlapping redundant field labels, reviewed collision-safe names, exactly-once creation, and phone/tablet/large-text tests.
- [x] 9.6 Expose Print, Compress, Split, Watermark, and Set/Remove Password directly from `viewer_actions_menu`, route each to its focused adaptive sheet/screen, preview watermark text over the bounded first-page thumbnail, retain page management only where selection is required, and add navigation/semantics/golden tests proving no generic editor hub appears first.
- [x] 9.7 Remove Share Extracted Text from the share UI, keys, robots, previews, and goldens while retaining embedded/OCR text infrastructure for search; update sharing tests to prove the option is absent and remaining actions work.
- [x] 9.8 Make the Settings PDF-quality chooser constrained, safe-area-aware, and scrollable at supported large text scales; add bottom content padding below Privacy Policy above the tab bar/home indicator and cover both fixes with component/golden tests.
- [x] 9.9 Update camera, browse/view, edit, share, and settings Tier-3 robots/flows for manual shutter, reversible Crop/Enhance, density persistence, direct PDF operation entry, absent Share Text, PDF-quality scrolling, and Settings bottom spacing.
- [ ] 9.10 Re-run formatting, analysis, layering/platform checks, Tier-1/Tier-2/goldens/coverage, attached Android/iOS flows, and `tool/verify.dart`; resolve every regression before archive.
