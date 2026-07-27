## Why

Two problems, one root cause. The document creation flow is a four-step wizard (capture → review → enhance → save) in which crop is a dead end — applying a crop leaves the screen and there is no way to crop again, refine a crop, or undo a bad one — and every editor works from whatever the previous step produced rather than from the untouched capture, so cropping twice compounds. Separately, a saved PDF is invisible: it lives in a per-document UUID folder inside app-private storage that the iOS Files app never shows and no Android file manager can reach, and Settings is reachable only by tapping the storage card on Home, so the settings screen and the document dashboard both read as missing.

The fix for the second problem is not a plist flag. `UIFileSharingEnabled` exposes the *whole* iOS Documents container, so making PDFs visible means the private working data must first move out of it — which is the moment to make the public folder tree the library rather than an export of it.

## What Changes

### Document storage becomes a real, user-visible folder tree

- **BREAKING** — `DocForge/` in public storage becomes the source of truth for PDFs. Isar stops owning file layout and becomes an index over that tree, keyed by folder-relative path.
  - iOS: `<App Documents>/DocForge/…`, exposed via `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`.
  - Android: `Documents/DocForge/…` via MediaStore (no runtime permission, survives uninstall, visible to Files/Drive/any file manager).
- **BREAKING** — everything private moves out of the iOS Documents container: Isar to Application Support, capture staging to Caches and thumbnails to a derived cache. Exposing Documents while the database sat in it would publish the library index.
- Folders created in the app are real directories; folders created outside the app appear in the app. A reconcile pass on launch and on resume adds files found in the tree and drops files that vanished.
- On Android, rendering and editing materialise a cache copy of the MediaStore item and write back on save, because `pdfrx`, `pdf_manipulator` and `printing` all require a file path.

### Captured images become strictly temporary and private

- **BREAKING** — once the PDF is written, *every* image belonging to it is deleted: originals, cached renders and thumbnails. The PDF plus its index metadata are all that remain. The same cleanup runs when creation is cancelled, and an orphan sweep runs at startup.
- Thumbnails become a **derived, evictable cache** rendered from the PDF on demand, rather than stored data. Lists stay fast; nothing is retained.
- Consequence: re-editing a saved document's pages re-renders from the PDF rather than from the original capture.

### Creation is one screen: a reorderable table of pages

- **BREAKING** — `ScanFlow`'s capture → review → enhance → save step machine is retired. `PageReviewScreen` and `PdfPreviewScreen` are reworked into a single page-table screen plus a save dialog; share-import enters the same screen.
- Rows are pages 1..n, drag-reorderable, each with crop/rotate, enhance and delete actions.
- Add a page from the camera or the photo library; either goes through crop/rotate then enhance before becoming a row.
- **A page is one untouched original plus two independent layers** — geometry (crop and rotate) and enhancement (settings). Everything shown anywhere is the original with geometry applied, then enhancement applied. Neither layer is ever baked into the other, so each is revertible on its own: reverting the crop returns the full original frame *still enhanced*; reverting the enhancement keeps the crop at its cropped size.
- Repeated crops compose into a **single** transform, so the original is resampled exactly once however many times the user cropped — no quality loss, no intermediate files on disk.
- **BREAKING** — crop and enhancement are strictly per page. Adding pages is a loop: pick or capture → crop → enhance → done → row. Bulk enhancement ("apply to all") and its progress and cancellation machinery are removed, because at the moment a page is enhanced there is no session of sibling pages to apply settings to.
- Save lives in the page-table app bar and opens a dialog with the document name, an optional "Protect with password" toggle, and Cancel / Save.
- Enabling the toggle reveals a password field and a confirm-password field; Save stays disabled until both are non-empty and identical. The password is per-document and user-chosen — never an application-wide password — and is remembered in secure storage so opening the document inside DocForge does not re-prompt, while any other application still needs it. This reuses the existing `PdfManipulatorEditor.protect` and the viewer's existing password handling.

### Crop becomes iterative rather than terminal

- **BREAKING** — "Apply crop" no longer navigates. It appends to the page's geometry, re-renders in place and resets the view (rotation 0, selection back to the full new image), so the user can crop again.
- "Next" in the app bar is the only path to enhancement.
- Tapping Next with an unapplied rotation or edge adjustment prompts "Apply crop changes and continue?" — No continues without applying, Yes applies then continues.
- **"Revert to original"** sits below Apply crop and clears the geometry layer, leaving the enhancement untouched. The enhance screen gets a matching **"Revert enhancement"** that clears settings and leaves the crop untouched — each control names the layer it affects, so neither reads as "undo everything". There is deliberately no undo stack.

### Navigation gains a tab bar

- Three tabs: **Dashboard** · **Create PDF** (centre) · **Settings**.
- Dashboard replaces Home: folder tree of `DocForge/`, search across it, recents and storage summary in its header, and New folder / Import PDF / Create PDF actions scoped to the open folder.
- Import PDF copies an external file into the open folder — DocForge never edits a file in place outside its own tree. The existing "Open with DocForge" share-sheet registration routes to the same copy-then-open path.

## Capabilities

### New Capabilities

- `public-document-storage`: the `DocForge/` public folder tree as the library's source of truth — its per-platform backing (iOS filesystem, Android MediaStore), the private/public split, folder-relative path addressing, reconciliation with external changes, and the temporary-file lifecycle for captures.
- `page-table-creation`: the single-screen PDF creation flow — the reorderable page table, adding pages from camera and gallery, per-row crop/enhance/delete over two independently revertible layers, and the named save with optional per-document password protection.

### Modified Capabilities

- `app-shell`: Home becomes the Dashboard tab under a three-tab bar; Settings becomes reachable as a tab rather than only through the storage card.
- `document-scanning`: crop applies in place and is repeatable, gains Revert to original and an explicit Next, prompts on unapplied changes, and treats crop as a geometry layer over an untouched original; the capture → review → enhance → save step machine is removed.
- `image-enhancement`: entered from a page-table row and from crop's Next, applied as settings over the page's current crop and independently revertible, and single-page only — bulk apply is removed.
- `document-library`: folders are real directories inside `DocForge/`; documents are addressed by folder-relative path; the library reconciles with external file changes; Import PDF is a library action.
- `pdf-generation`: the PDF is written into the open `DocForge/` folder under a user-supplied name, optionally encrypted with a user-supplied password, and every image belonging to the session is deleted once it is written.
- `app-security`: a document password is set at creation time rather than only afterwards, and is confirmed by re-entry before it is applied.
- `document-import`: importing a PDF copies it into the currently open folder rather than into a private UUID directory.

## Impact

### Architecture impact by feature folder

| Feature | Layers touched |
| --- | --- |
| `core/storage/` | **new** `public_storage/` — platform channel wrapper, path addressing |
| `features/document_library/` | domain (new `LibraryPath` value object, repository contracts), infrastructure (file store rewritten, MediaStore data source, reconciler, Isar entity change), application (new reconcile + import use cases), presentation (dashboard screens) |
| `features/document_creation/` | **new feature** — page-table presentation + application; replaces `ScanFlow` |
| `features/document_scanning/` | presentation only (crop screen and `CropCubit`); domain gains an `originalImagePath` on `CapturedPage` |
| `features/image_enhancement/` | presentation (entry contract; batch state, controls and `PlanSessionEnhancement` removed), no domain change |
| `features/pdf_generation/` | application (save writes to a public path), presentation (save dialog replaces preview screen) |
| `features/app_shell/` | presentation (tab scaffold, dashboard) |
| `features/document_import/` | application (import target is the open folder) |
| `app/` | router (tab shell route, `StatefulShellRoute`), `main.dart` wiring, `library_module.dart`, `scanning_module.dart` → `creation_module.dart` |

### Resulting folder structure (new and materially changed only)

```
lib/core/storage/public_storage/
  public_file_store.dart              # domain-level contract (core, so no feature owns it)
  ios_public_file_store.dart          # direct filesystem
  android_media_store.dart            # MethodChannel over MediaStore
  public_path.dart                    # folder-relative path value object

lib/features/document_creation/
  presentation/
    cubit/       page_table_cubit.dart, page_table_state.dart,
                 save_document_cubit.dart, save_document_state.dart
    screens/     page_table_screen.dart, save_name_dialog.dart
    widgets/     page_row.dart, add_page_sheet.dart, page_table_previews.dart
    creation_keys.dart
  application/usecases/  add_page_from_camera.dart, add_page_from_gallery.dart,
                         reorder_pages.dart, discard_creation_session.dart
  domain/      creation_session.dart, page_draft.dart

lib/features/document_library/
  domain/       library_path.dart, repositories/public_library_repository.dart
  application/usecases/  reconcile_library.dart, create_folder.dart,
                         import_pdf_into_folder.dart
  infrastructure/
    datasource/ public_document_file_store.dart      # replaces LocalDocumentFileStore
    repositories/ library_reconciler.dart
  presentation/
    cubit/      dashboard_cubit.dart, dashboard_state.dart
    screens/    dashboard_screen.dart, folder_browser_screen.dart

lib/features/app_shell/presentation/
  screens/      app_tab_scaffold.dart
  widgets/      create_pdf_tab_button.dart
```

### Dependencies

No new Dart packages. MediaStore is reached through a `MethodChannel` in the existing Android host rather than a plugin: every candidate (`saf_util`, `media_store_plus`, `external_path`) either requires a user folder prompt we ruled out, or does not support nested `RELATIVE_PATH` creation and enumeration together. `path_provider`, `file_picker`, `image_picker` and `share_plus` are already present and cover the rest.

### Migration

- **Isar schema**: `DocumentEntity` gains `folderPath` (folder-relative, e.g. `Invoices/2026`) and `fileName`; `filePath` becomes derived. `FolderEntity` gains `relativePath`. A schema migration runs at open: for each existing document, move `documents/<uuid>/document.pdf` into `DocForge/<title>.pdf`, delete `pages/` and the stored `thumbnails/` (they are re-derived on demand), and rewrite the entity. Documents whose file is already gone are dropped from the index.
- **iOS container**: Isar moves from Application Support (already correct) — but the documents root moves from `Documents/documents/` to `Documents/DocForge/`, and thumbnails become a derived cache. Migration is idempotent and guarded by the existing `.layout-version` marker, bumped to `2`.
- **Preferences**: new key `library.reconcile.lastRunAt`. No secure-storage key changes.
- **Routes**: `/` becomes a `StatefulShellRoute` with branches `/dashboard`, `/create`, `/settings`. `/scan`, `/scan/review`, `/scan/enhance`, `/scan/preview` are removed and `/` redirects to `/dashboard`. `AppRoutes.all` and the navigation tests change accordingly.

### Performance

- The reconcile pass is a directory walk, so it runs in the existing pooled background isolate and is throttled by `lastRunAt` — resume within 60s does not re-walk.
- Android cache materialisation is per-open, LRU-evicted, and never happens for list rendering (rows read the derived thumbnail cache).
- Page renders are keyed by value equality on (original, geometry, enhancement), so an unchanged page is never re-rendered; the page table reads them through the existing `ThumbnailCache`; rows are `const`-constructible and rebuild through `BlocSelector` on their own page only, so dragging one row does not rebuild the rest.
- Crop's Apply composes the geometry ops into one transform and resamples the original once off the UI thread via the existing `ApplyPerspectiveCorrection`; the original is never re-encoded, and no intermediate crop files are written.
- Deleting captures at save time is what keeps a 40-page session from leaving 40 full-resolution JPEGs behind — the current flow keeps them forever.

### Security

- Sensitive: the captures themselves. They stay in Caches (app-private on both platforms) and are deleted on save, on cancel, and by the startup sweep.
- Deliberately public: the finished PDFs, which is the user's stated intent. This is a reduction in confidentiality relative to today and is called out in the specs — the app-lock protects the *app*, not files the user has asked to be visible to other apps.
- The Isar index, OCR text and passwords stay app-private (Application Support / secure storage) and never enter the exposed container.
- Import copies bytes into our tree and never retains a security-scoped bookmark or a persisted SAF grant, so revoking access to the source has no effect on us.

### Cubits, States, use cases, repositories, Isar schema, navigation

- **Cubits**: new `PageTableCubit`, `SaveDocumentCubit`, `DashboardCubit`. Changed `CropCubit` (apply-in-place, revert-to-original, pending-change tracking) and `EnhancementCubit` (single page; bulk apply, progress and cancellation removed). Removed `PageReviewCubit`; `ScanCaptureCubit` keeps only camera lifecycle. `PdfGenerationCubit` loses its preview responsibility.
- **States**: new `PageTableState`, `SaveDocumentState`, `DashboardState`. `CropState` gains `originalImagePath`, an `applied` list of crop ops, the page's `enhancement` for display, a cached `renderPath` and `rotationDegrees`. `EnhancementState` collapses `pages`/`index` to a single page and loses `progress` and `applyingToAll`.
- **Use cases**: new `AddPageFromCamera`, `AddPageFromGallery`, `DiscardCreationSession`, `ReconcileLibrary`, `CreateFolder`, `ImportPdfIntoFolder`, `CleanupOrphanedCaptures`. `SaveDocument` gains a destination folder and an optional password. `PlanSessionEnhancement` is removed.
- **Repositories**: new `PublicFileStore` contract in `core` with iOS and Android implementations; `DocumentFileStore` narrows to derived caches and temporary work.
- **Isar schema**: as above, migration version 2.
- **Navigation**: `StatefulShellRoute` tab shell; crop and enhance stay nested-navigator pushes owned by the creation flow.

### Testing strategy

- **Unit**: `LibraryPath` normalisation and traversal rejection; geometry composition (N ops to one transform, and equivalence with sequential application); crop apply/revert transitions; `CreationSession` reorder/delete rules; reconcile diffing (added/removed/renamed).
- **Cubit** (`bloc_test`): `PageTableCubit` add/reorder/delete/replace sequences; `CropCubit` apply-in-place, revert leaving enhancement intact, unapplied-change flag; `SaveDocumentCubit` validation and failure paths; `DashboardCubit` folder navigation and search.
- **Repository**: `PublicFileStore` against a temp directory for the iOS implementation; the Android implementation against a fake `MethodChannel` asserting the MediaStore arguments; migration from layout 1 to 2 including the drop-missing-file case.
- **Serialization**: `DocumentEntity`/`FolderEntity` round-trips with the new path fields.
- **Widget**: page-table row actions and drag handles; the save dialog's Cancel/Save; the crop screen's Apply/Reset/Next and the unapplied-changes prompt in both answers; dashboard empty and populated states.
- **Navigation**: tab switching preserves each branch's stack; `/` redirects to `/dashboard`; removed scan routes resolve to not-found; Import routes into the open folder.
- **Integration**: capture → crop → crop again → enhance → row → reorder → save → file present in the public tree → captures gone. Driven on device, since camera and MediaStore have no host-VM equivalent.
- **Golden**: `PageTableScreen`, `DashboardScreen`, `CropScreen`, `AppTabScaffold`, each in light and dark, phone and tablet.
- Coverage stays ≥ 80% overall and ≥ 90% for the new domain and application code.

### Preview coverage

| Widget / screen | Previewed states |
| --- | --- |
| `PageTableScreen` | default (3 rows), loading, empty, error, long content (30 rows) · phone + tablet · light + dark |
| `PageRow` | default, processing, error, long title |
| `AddPageSheet` | default, permission-denied |
| `SaveNameDialog` | default, empty-name invalid, password enabled, password mismatch, saving, error |
| `CropScreen` | adjusting, applied once, applied twice, correcting, error, revert-available · phone + tablet · light + dark |
| `DashboardScreen` | default, loading, empty folder, error, long content · phone + tablet · light + dark |
| `AppTabScaffold` | each tab selected · phone + tablet · light + dark |

All fed from `core/previews/fixtures`; no camera, filesystem, database or clock dependency.

### Definition of Done

1. Creating a PDF from camera and from gallery both land rows in the page table, and crop → apply → crop again → Next → enhance works without leaving the crop screen between applies.
2. Reverting the crop leaves the enhancement applied, and reverting the enhancement leaves the crop at its cropped size, each verified on a page that has both.
3. Three successive crops resample the original once and are not degraded relative to reaching the same region in one crop.
3a. Revert to original on the crop screen clears geometry only; no undo control exists.
4. Next with unapplied changes prompts, and both answers behave as specified.
5. Save asks for a name, Cancel dismisses without writing, Save writes into the open folder.
5a. Enabling password protection requires a matching confirmation, produces a PDF another application cannot open without that password, and does not re-prompt inside DocForge.
6. The saved PDF is visible in the iOS Files app under "On My iPhone → Doc Forge → DocForge" and in an Android file manager under `Documents/DocForge`, without further user action.
7. No image of any kind remains on disk after a save or a cancel — originals, renders and thumbnails alike; a killed session's captures are swept at next launch, and list thumbnails still render by deriving from the PDF.
8. Dashboard, Create PDF and Settings are all reachable from the tab bar; Settings is no longer reachable only through the storage card.
9. Folders created in the app appear in Files, and a PDF deleted in Files disappears from Dashboard after reconcile.
10. Migration from layout 1 runs once, moves existing documents into `DocForge/`, and no document is lost.
11. `dart format`, `flutter analyze`, all test tiers and the coverage gate pass.

### Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| MediaStore has no nested-folder guarantee across OEM builds | The `MethodChannel` implementation falls back to a flat `Documents/DocForge/` with folder names encoded in the index when a nested `RELATIVE_PATH` insert fails; integration test asserts both paths |
| Android cache copies double transient storage for large PDFs | LRU eviction with a size cap, and eviction on memory pressure; the copy is deleted when the viewer closes |
| Migration loses documents | Migration is copy-then-verify-then-delete, guarded by the layout marker, and unit-tested including the interrupted case |
| Public files make the app-lock look weaker than it is | Settings gains explicit copy stating that saved PDFs are visible to other apps; the risk is the user's stated intent, not an accident |
| External renames orphan Isar metadata (favourite, OCR) | Reconcile matches on a size+mtime fingerprint before falling back to path, so a rename in Files keeps its metadata |
| Retiring `ScanFlow` breaks share-import | Share-import is repointed at the page table in the same change and covered by a navigation test |

### Future extensibility

Addressing documents by folder-relative path rather than by device-local UUID directory is exactly the shape a sync engine needs: the path is the stable remote key, the fingerprint is the change detector, and the reconciler is already a three-way-merge-shaped diff (local tree vs index vs — later — remote manifest). `PublicFileStore` is a domain contract in `core`, so a future `SyncedFileStore` slots in beside the two platform implementations without touching a feature.

### Platform scope

Android and iOS only. No web or desktop support is introduced, and the two new platform implementations are guarded so that no other platform is reachable.
