## 1. Public storage foundation

- [x] 1.1 Add `lib/core/contracts/models/library_path.dart` — `LibraryPath` value object with `parse`, `relative`, `folders`, `fileName`, rejecting `..`, absolute paths and separators inside names (design D1)
- [x] 1.2 Unit-test `LibraryPath`: normalisation, nesting, traversal rejection, name sanitisation, equality
- [x] 1.3 Add `lib/core/storage/public_storage/public_file_store.dart` — the `PublicFileStore` contract and `PublicEntry` model, with full dartdoc stating the offline and failure contract (design D2)
- [x] 1.4 Implement `FilesystemPublicFileStore` over the real filesystem, rooted at an injected directory
- [x] 1.5 Repository-test `FilesystemPublicFileStore` against a temp directory: initialise, list, createFolder, writeFile, materialise, rename, delete, totalBytes, and the storage-full and not-found failure mappings
- [x] 1.6 Add the Android `MethodChannel` wrapper `MediaStoreChannel` with an injectable channel, and its Kotlin counterpart in the host app implementing insert/query/openFd/update/delete against `MediaStore.Files` under `Documents/DocForge`
- [x] 1.7 Implement `MediaStorePublicFileStore` over the channel, including the flat-fallback path when a nested `RELATIVE_PATH` insert is refused, and the LRU `materialise` cache
- [x] 1.8 Repository-test `MediaStorePublicFileStore` against a fake channel: asserts the MediaStore arguments, exercises the nested-folder fallback, and asserts cache eviction on close
- [x] 1.9 Wire store selection by `Platform.isAndroid` in `buildPublicFileStore` only, and dartdoc why no feature branches on platform

## 2. Private/public split and migration

- [x] 2.1 Resolve the library over Application Support and publish PDFs through `PublicFileStore`, so iOS `Documents/` holds only `DocForge/` (design D4); `Document` now carries a `LibraryPath` and consumers resolve bytes through `DocumentFileResolver`
- [x] 2.2 Add `folderPath` and `fileName` to `DocumentEntity` and `relativePath` to `FolderEntity`; regenerate Isar and Freezed sources
- [x] 2.3 Serialization-test the changed entities: round-trip including nested folder paths and the protected flag
- [x] 2.4 Implement the layout-1 → layout-2 migration: copy, verify size and page count, rewrite the entity, then delete the old directory; drop entries whose source file is missing
- [x] 2.5 Unit-test the migration: happy path, missing source, duplicate resulting names, and resumption after interruption
- [x] 2.6 Turn existing `FolderEntity` records into real directories during migration, sanitising names, and copy their documents into them
- [x] 2.7 Set `UIFileSharingEnabled` to true and `LSSupportsOpeningDocumentsInPlace` to true in `ios/Runner/Info.plist`, with a comment stating what the latter does and does not mean
- [ ] 2.8 Verify on a device that `Documents/` contains only `DocForge/` after migration, and that the folder appears in the iOS Files app

## 3. Reconciliation and temporary-file lifecycle

- [x] 3.1 Add `ReconcileLibrary` use case as a pure diff over index entries and tree entries producing added / removed / modified / renamed, matching on `(size, mtime)` fingerprint before path (design D5)
- [x] 3.2 Unit-test the diff for each case including a rename that must retain favourite, archive and OCR text, and a fingerprint collision
- [x] 3.3 Run the tree walk in the pooled background isolate and throttle with the `library.reconcile.lastRunAt` preference; verify a resume within 60s does not re-walk
- [x] 3.4 Trigger reconcile on launch and on app resume, and cover it with a widget test using a fake lifecycle observer
- [x] 3.5 Add `CleanupOrphanedCaptures` — sweep the creation-session cache at startup — and unit-test that it deletes orphans and spares an in-progress session
- [x] 3.6 Delete every image belonging to a session — originals, cached renders and thumbnails — after a successful save and after a confirmed discard; unit-test both, and that nothing is deleted when generation fails
- [x] 3.7 Make thumbnails a derived cache rendered from the PDF on demand, keyed by document fingerprint and evictable; unit-test that a missing thumbnail is re-rendered rather than reported as a failure, and that a changed file invalidates it (design D4a)

## 4. Layered page model and render pipeline

- [ ] 4.1 Add `CropOp` and extend `PageDraft` to hold `originalImagePath`, an ordered `geometry` list and `enhancement`, with no pixels of its own (design D6)
- [ ] 4.2 Add `composeGeometry(List<CropOp>)` to `document_scanning/domain/perspective_transform.dart`, returning the single transform equivalent to applying the ops in order
- [ ] 4.3 Unit-test composition: one op matches today's behaviour, N ops equal sequential application within tolerance, an empty list is the identity, and rotation composes with perspective
- [ ] 4.4 Add `PageRenderPlan` with value equality over (original, geometry, enhancement) and a render cache keyed by it; unit-test that an unchanged plan reuses its render and a changed one invalidates
- [ ] 4.5 Render previews at display resolution and generation at full resolution through the same pipeline, and unit-test that both use one resampling pass regardless of op count

## 5. Crop screen rework

- [ ] 5.1 Extend `CropState` with `originalImagePath`, `applied`, `enhancement`, `renderPath`, `rotationDegrees` and the `hasUnappliedChanges` / `canApply` / `canRevert` predicates (design D6)
- [ ] 5.2 Rewrite `CropCubit.apply` to append a `CropOp`, re-render from the original through the composed transform, and emit with rotation 0 and a full-page selection, without popping
- [ ] 5.3 Implement `CropCubit.revertToOriginal` clearing the geometry list and re-rendering, carrying the enhancement through untouched
- [ ] 5.4 Cubit-test (`bloc_test`) apply-in-place, repeated apply, revert leaving enhancement intact, apply failure leaving the render intact, and the unapplied-changes flag
- [ ] 5.5 Add the `scan_crop_apply_button`, `scan_crop_revert_button` (below apply) and `scan_crop_next_button` controls to `CropScreen`, and remove the pop-on-apply behaviour
- [ ] 5.6 Display the enhanced render on the crop screen so it matches the page's row, and widget-test that an enhanced page looks the same in both places
- [ ] 5.7 Add the unapplied-changes prompt (`scan_crop_apply_prompt`) on Next, with apply-and-continue and continue-without-applying, and dismissal leaving the screen intact
- [ ] 5.8 Widget-test the crop screen: apply keeps the screen, Next navigates, prompt appears only with unapplied changes, both answers behave as specified, revert disabled until an apply has happened, and no undo control exists
- [ ] 5.9 Golden-test `CropScreen` in light and dark, phone and tablet
- [ ] 5.10 Add `@Preview()` entries for `CropScreen`: adjusting, applied once, applied twice, correcting, error, revert available

## 6. Single-page enhancement

- [ ] 6.1 Reduce `EnhancementState` to a single page and remove `progress`, `applyingToAll`, `canApplyToAll` and the index clamping (design D7a)
- [ ] 6.2 Remove `applyToAll`, `cancelApplyToAll` and `PlanSessionEnhancement`, and delete the `_BatchProgress` widget and the `enhance_apply_to_all_button`, `enhance_progress_indicator` and `enhance_cancel_button` controls
- [ ] 6.3 Rename the reset control to `enhance_revert_button` ("Revert enhancement") and make it clear settings only, never geometry (design D7)
- [ ] 6.4 Seed the enhancement preview from the page's original with its geometry applied, so enhancement follows a later crop without re-entry
- [ ] 6.5 Cubit-test the reduced `EnhancementCubit`: filter and slider changes, undo, revert clearing settings while geometry is retained, preview coalescing, and failure handling
- [ ] 6.6 Widget-test that no apply-to-all control is present regardless of document length, that done returns the settings, and that reverting enhancement leaves the page cropped
- [ ] 6.7 Update `@Preview()` entries for `EnhancementScreen` to the single-page states, and remove the batch previews
- [ ] 6.8 Delete the now-unused bulk enhancement tests rather than leaving them skipped

## 7. Creation feature — session and page table

- [ ] 7.1 Create `lib/features/document_creation/` with the layer folders, and confirm `PageDraft` (added in 4.1) is owned here (design D6)
- [ ] 7.2 Move `ScanSessionRules` reorder / delete / restore / canSave into `CreationSession`, re-typed to `PageDraft`, and move their unit tests with them
- [ ] 7.3 Add `CreationRules` with name validation and `validatePassword(password, confirmation)`, and unit-test both
- [ ] 7.4 Add `PageTableCubit` and `PageTableState` — add, replace, reorder, delete, undo delete — with no business logic in the Cubit
- [ ] 7.5 Cubit-test `PageTableCubit` for every operation, including reorder renumbering and undo restoring position
- [ ] 7.6 Build `PageTableScreen` with `creation_page_table_screen`, `creation_page_list`, `creation_add_page_button`, `creation_save_button`, empty, loading and error states
- [ ] 7.7 Build `PageRow` with crop, enhance, delete and drag-handle controls, page numbering, and `moveUp` / `moveDown` semantic actions for screen-reader reordering
- [ ] 7.8 Build `AddPageSheet` offering camera and photo-library sources, with the permission-denied path
- [ ] 7.9 Widget-test the page table: rows are pages in order, drag reorders and renumbers, delete and undo, save disabled while empty, semantic reordering
- [ ] 7.10 Implement the exit confirmation when the table has pages, discarding cleanly, and widget-test both answers plus the no-confirmation-when-empty case
- [ ] 7.11 Golden-test `PageTableScreen` in light and dark, phone and tablet
- [ ] 7.12 Add `@Preview()` entries for `PageTableScreen`, `PageRow` and `AddPageSheet` covering default, loading, empty, error and long content

## 8. Creation feature — add-page loop

- [ ] 8.1 Add `AddPageFromCamera` and `AddPageFromGallery` use cases producing a `PageDraft` from a source image, and unit-test them
- [ ] 8.2 Wire the loop in the creation flow host: pick or capture → crop → enhance → append row, with abandonment at either step adding nothing
- [ ] 8.3 Make each row action open its editor on the layer it owns, and widget-test that cropping twice does not compound, that re-enhancing does not double-apply, and that reverting either layer leaves the other intact
- [ ] 8.4 Handle multi-select from the photo library by running the loop per image in selection order, and test the ordering
- [ ] 8.5 Strip `ScanCaptureCubit` down to camera lifecycle, removing `pages`, `batchMode` and the page counter, and update its Cubit tests

## 9. Save dialog and generation

- [ ] 9.1 Add `SaveDocumentCubit` and `SaveDocumentState` covering name, password, confirmation, validity and save progress
- [ ] 9.2 Cubit-test the save Cubit: prefilled name, empty-name invalid, password mismatch invalid, save success, save failure retaining the session
- [ ] 9.3 Build `SaveNameDialog` with the name field, the password toggle, the password and confirm fields (obscured), Cancel and Save
- [ ] 9.4 Extend `SaveDocument` with a destination folder and an optional password; write the unprotected PDF to cache, protect it with `PdfManipulatorEditor.protect`, then publish through `PublicFileStore` (design D11)
- [ ] 9.5 Store the password through `RememberDocumentPassword` when protection is used, and unit-test that it never reaches preferences or the database
- [ ] 9.6 Handle the duplicate-name case with a replace-or-rename confirmation, and unit-test that nothing is overwritten without it
- [ ] 9.7 Widget-test the dialog: Cancel writes nothing, Save disabled on empty name and on password mismatch, progress disables the controls
- [ ] 9.8 Remove `PdfPreviewScreen` and `PdfGenerationCubit`'s preview responsibility, and delete their now-dead tests
- [ ] 9.9 Add `@Preview()` entries for `SaveNameDialog`: default, empty name, password on, password mismatch, saving, error

## 10. Dashboard and library operations

- [ ] 10.1 Add `DashboardCubit` and `DashboardState` covering the open folder path, entries, search query, loading, empty and error
- [ ] 10.2 Cubit-test the dashboard: opening a folder, going up, search filtering, reconcile-driven refresh, error and retry
- [ ] 10.3 Build `DashboardScreen` with the search field, breadcrumb, content list, storage summary, create-folder and import-PDF actions, and the empty, loading and error states
- [ ] 10.4 Add `CreateFolder` use case writing a real directory through `PublicFileStore`, rejecting duplicates and invalid names; unit-test both refusals
- [ ] 10.5 Make rename, move, duplicate, delete and archive act on the file at the document's `LibraryPath`, and unit-test that each keeps the tree and the index in step
- [ ] 10.6 Add `ImportPdfIntoFolder` copying an external PDF into the open folder, leaving the source untouched and retaining no grant; unit-test the collision, invalid-file and protected-source cases
- [ ] 10.7 Repoint the share-sheet and "Open with" paths at `ImportPdfIntoFolder` for PDFs and at the page table for images
- [ ] 10.8 Widget-test the dashboard: folder navigation, breadcrumb, only-our-folders browsable, import action, create-folder validation
- [ ] 10.9 Golden-test `DashboardScreen` in light and dark, phone and tablet
- [ ] 10.10 Add `@Preview()` entries for `DashboardScreen`: default, loading, empty folder, error, long content

## 11. Tab shell and routing

- [ ] 11.1 Replace the Home route with a `StatefulShellRoute.indexedStack` over `/dashboard`, `/create` and `/settings`; remove `scan`, `scanReview`, `scanEnhance`, `scanPreview` from `AppRoutes` and add `dashboard`, `create` and the folder-path parameter (design D10)
- [ ] 11.2 Build `AppTabScaffold` with the three destinations, the middle Create control intercepted to push the creation flow onto the root navigator, and the previous branch left selected
- [ ] 11.3 Hide the tab bar inside camera, crop, enhancement and viewer routes
- [ ] 11.4 Navigation-test: `/` redirects to `/dashboard`, each branch keeps its own stack across tab switches, backing out of creation restores the previous branch, removed scan routes resolve to not-found
- [ ] 11.5 Fold the storage summary and recents into the dashboard header and delete `HomeScreen`, `HomeCubit` and `HomeActions` along with their dead tests
- [ ] 11.6 Golden-test `AppTabScaffold` with each tab selected, light and dark, phone and tablet
- [ ] 11.7 Add `@Preview()` entries for `AppTabScaffold`

## 12. Wiring, deletion and settings copy

- [ ] 12.1 Delete `ScanFlow` and its step machine from `scanning_module.dart`; rename the module to reflect its narrowed camera-and-crop responsibility
- [ ] 12.2 Rebuild the `main.dart` composition for the new graph: public store, reconciler, creation module, dashboard, tab shell
- [ ] 12.3 Add the settings copy stating that saved PDFs are visible to other applications and that protected PDFs cannot be read without their password
- [ ] 12.4 Add the protected badge (`document_protected_badge`) to document rows and the detail screen
- [ ] 12.5 Confirm no feature imports another feature after the restructure, and no `Platform.` branch exists outside the composition root

## 13. Integration, documentation and gates

- [ ] 13.1 Integration test on a device: capture → crop → crop again → Next → enhance → row → add a second page → reorder → save → file present in the public tree → every session image gone
- [ ] 13.1a Integration test of the layers: crop and enhance a page, revert the crop and confirm the enhancement survives, then revert the enhancement and confirm the crop survives
- [ ] 13.2 Integration test: save with a password, confirm the file cannot be opened without it externally and opens without prompting in the application
- [ ] 13.3 Integration test: create a folder in the app, verify it in the file browser; delete a PDF in the file browser, verify it disappears after resume; rename externally and verify metadata is retained
- [ ] 13.4 Integration test: import an external PDF into an open folder and confirm the source is untouched
- [ ] 13.5 Integration test: migration from a seeded layout-1 library, asserting no document is lost
- [ ] 13.6 Add dartdoc to every new public API named in the design's documentation section, and the inline comments it lists
- [ ] 13.7 Run `dart format --set-exit-if-changed` and fix
- [ ] 13.8 Run `flutter analyze` and fix every issue
- [ ] 13.9 Run the full test suite including goldens and verify coverage is at least 80% overall and at least 90% for the new domain and application code
- [ ] 13.10 Resolve the design's open questions on the device — external duplicate-name renames, and whether the sanitised or original folder name wins after an external rename — and record the answers in the design
