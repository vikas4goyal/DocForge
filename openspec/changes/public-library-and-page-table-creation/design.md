## Context

Two behaviours in the shipped application motivate this design, and they turn out to share a root.

**Creation is a wizard whose editors are one-way.** `ScanFlow` (`lib/app/scanning_module.dart`) is a four-state machine — capture → review → enhance → save — driven by a `setState` on `_ScanStep`. `CropCubit.confirm` writes a corrected file and the screen immediately pops with the result, so a crop can never be refined or undone; and because `_editCapturedPage` chains crop into enhance and replaces `CapturedPage.imagePath` with the corrected file, every subsequent edit operates on the *previous result*, not on the capture. Cropping twice compounds.

**Saved documents are unreachable.** `LocalDocumentFileStore` writes to `<appDocuments>/documents/<uuid>/document.pdf` and the class doc states the app-private guarantee explicitly. On iOS, `Info.plist` sets neither `UIFileSharingEnabled` nor `LSSupportsOpeningDocumentsInPlace` (the latter is deliberately `false`), so the Files app shows nothing. On Android nothing writes to shared storage at all. Separately `/settings` is reachable only through `HomeActions.onStorage` — tapping the storage card — which is why Settings reads as missing.

The root shared by both: **the application owns file layout as an implementation detail**. Fixing visibility is not a plist flag, because `UIFileSharingEnabled` exposes the *entire* iOS Documents container — and `buildLibraryModule` currently puts the Isar database in Application Support but the documents tree in Documents, so flipping the flag would publish the library's file layout alongside the PDFs. The container has to be cleaned out before it can be opened, and once the public tree is the thing the user sees and manipulates, it is the honest source of truth.

Constraints this design works inside:
- Feature-first clean architecture; no feature imports another; dependencies passed through constructors from `main.dart`; no service locator.
- flutter_bloc, Cubit-preferred, no business logic in Cubits.
- Android and iOS only. Offline-first, with room for later cloud sync.
- `pdfrx`, `pdf_manipulator` and `printing` all take file **paths**, not streams or URIs.
- Android 10+ scoped storage forbids arbitrary path writes into shared `Documents/`.

Decisions already taken with the user, and treated here as given: public tree on both platforms; Android via MediaStore with no user prompt; `ScanFlow` retired rather than kept alongside; three tabs (Dashboard · Create · Settings); no secure folder — optional per-document password instead.

## Goals / Non-Goals

**Goals:**

1. One creation screen — a reorderable table of pages — reached from a Create tab and from every import path.
2. Crop that applies in place and can be repeated, with a revert to the original and an explicit Next to enhancement.
3. Crop and enhancement as two independent layers over one untouched original, each revertible without disturbing the other, so no edit ever compounds.
4. Saved PDFs visible in the iOS Files app and in Android file managers with no user action and no permission prompt.
5. Captures treated as temporary: deleted on save, on cancel, and swept at startup.
6. A dashboard that browses the application's own folder tree, with create-folder and import-PDF, and a reachable Settings tab.
7. Optional per-document password at save time, confirmed by re-entry.
8. A migration off the private UUID layout that loses nothing.

**Non-Goals:**

- Cloud sync. The design is shaped so it can arrive later (see *Future extensibility*), but nothing here talks to a network.
- A secure/hidden vault. Dropped with the user; encryption at rest for a document is the password, not a location.
- Browsing arbitrary device folders. Only `DocForge/` and its descendants are reachable in-app.
- In-place editing of files outside `DocForge/`. External files are copied in.
- Re-editing the *original captures* of an already-saved document. Once saved, page-level editing works from the PDF.
- Any platform other than Android and iOS.

## Decisions

### D1. The public folder is the source of truth; Isar is an index over it

**Decision.** `DocForge/` in user-visible storage holds the PDFs and the user's folders. Isar holds metadata that cannot live in a PDF — favourite, archived, recognised text, thumbnails, page count cache, protection flag — keyed by a folder-relative path plus a content fingerprint. A reconciler diffs the tree against the index on launch and on resume.

**Why not a private library with mirrored public copies.** Two copies double storage for every document, and they diverge the moment the user renames or deletes in Files — which they now can, because the whole point is that the folder is theirs. Reconciling a mirror is strictly harder than reconciling an index, because a mirror has to decide which side won.

**Why not "public folder, no index at all".** Favourites, archive state and OCR text have nowhere to live in a PDF, and computing page count and thumbnails on every list render would make a large library unscrollable.

**Consequence.** `DocumentId` stops being a directory name. It stays as the identity used across features (`core/contracts/models/ids.dart` is unchanged) but is now an index key, with `LibraryPath` as the file address.

`LibraryPath` lives in `core/contracts/models/` beside `ids.dart`, not in `document_library/domain/`. It is the address type in the `PublicFileStore` contract, which `core` owns (D2), and `core` may not import a feature — putting the type in the feature would invert the dependency. It is a cross-boundary value object of exactly the kind `core/contracts` exists for.

```
lib/core/contracts/models/library_path.dart

/// A location inside the library folder, as folder segments plus a file name.
///
/// A value object rather than a String because every path the application
/// writes has to be proven not to escape the library root, and a String that
/// has been validated somewhere is indistinguishable from one that has not.
final class LibraryPath {
  factory LibraryPath.parse(String relative);   // rejects '..', absolute, separators in names
  final List<String> folders;
  final String fileName;
  String get relative;                          // 'Invoices/2026/Receipt.pdf'
}
```

### D2. `PublicFileStore` is a `core` contract with two platform implementations

**Decision.** The contract lives in `lib/core/storage/public_storage/public_file_store.dart` — not in `document_library` — because `pdf_generation` writes through it and `document_library` reads through it, and a contract owned by one feature and imported by another is exactly the feature-to-feature coupling the architecture forbids.

```dart
abstract interface class PublicFileStore {
  Future<Result<void>> initialise();
  Future<Result<List<PublicEntry>>> list(List<String> folders);
  Future<Result<void>> createFolder(List<String> folders);
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath);
  Future<Result<String>> materialise(LibraryPath path);  // a readable file path
  Future<Result<void>> rename(LibraryPath from, LibraryPath to);
  Future<Result<void>> delete(LibraryPath path);
  Future<Result<int>> totalBytes();
}
```

`materialise` is the seam that makes the platform difference disappear for consumers: on iOS it returns the real path; on Android it copies the MediaStore item into the cache and returns that. `pdfrx`, `pdf_manipulator` and `printing` see a path either way.

**Selection happens in the composition root**, by `Platform.isAndroid`, and nowhere else — no feature branches on platform.

### D3. Android goes through MediaStore over a `MethodChannel`, not a plugin

**Decision.** A small Kotlin class in the existing Android host exposes `insert`, `query`, `openFd`, `update` and `delete` against `MediaStore.Files` with `RELATIVE_PATH` under `Documents/DocForge/…`. API < 29 takes the legacy direct-path branch.

**Why not a plugin.** `media_store_plus` does not expose nested `RELATIVE_PATH` creation and enumeration together; `saf_util` and every SAF-based option requires the folder-picker prompt the user explicitly ruled out; `external_path` only resolves paths that scoped storage then refuses to write.

**Why not `getExternalFilesDir`.** It gives real paths and needs no permission, but Android 11+ hides `Android/data/` from the system Files app, so the files would still be invisible — which is the entire problem.

**Fallback.** Some OEM builds reject a nested `RELATIVE_PATH` insert. The implementation catches that, retries flat in `Documents/DocForge/`, and records the intended folder in the index. The spec requires the user be told where the file landed; the dashboard still shows it in the folder they chose.

**Cache discipline.** `materialise` writes into `<cache>/materialised/<hash>.pdf`, LRU-capped, evicted when the viewer or editor closes. It is never called for list rendering — rows use the derived thumbnail cache (D4a).

### D4. iOS opens the Documents container, so the container is emptied first

**Decision.** `Info.plist` gains `UIFileSharingEnabled=true` and flips `LSSupportsOpeningDocumentsInPlace` to `true`. Because that exposes the whole container, `buildLibraryModule` changes what it resolves:

| Data | Before | After |
| --- | --- | --- |
| Isar database | Application Support | Application Support (unchanged) |
| PDFs | `Documents/documents/<uuid>/document.pdf` | `Documents/DocForge/<folders>/<name>.pdf` |
| Page images | `Documents/documents/<uuid>/pages/` | Cache (`<cache>/creation/<sessionId>/`), deleted after save |
| Thumbnails | `Documents/documents/<uuid>/thumbnails/` | Cache (`<cache>/thumbnails/`), derived from the PDF, evictable |
| Captures in progress | Cache (already) | Cache (unchanged) |

After this, `Documents/` contains exactly one entry: `DocForge/`.

`LSSupportsOpeningDocumentsInPlace=true` does **not** mean the app edits foreign files in place — it means files inside *our* container can be opened in place by other apps, which is what makes the folder feel real in Files. Foreign files still go through import-copy (D8).

### D4a. Once a PDF is saved, the PDF is all there is

**Decision.** Saving deletes every image belonging to the session — originals, cached renders and thumbnails. Nothing about a saved document is retained except the PDF itself and the index metadata that cannot live in a PDF.

Thumbnails therefore become a **derived cache** rather than stored data: rendered from the PDF on first display into `<cache>/thumbnails/<documentId>/<page>.jpg`, keyed by the document fingerprint so a changed file invalidates them, and evictable by the OS at any time. A list render that finds no thumbnail renders one; it never finds a missing *source*.

**Why not keep thumbnails as stored files.** They are the one thing that made the old layout keep a per-document directory alive after saving, and "we just have the PDF" is only true if nothing else survives. A derived cache gets the same scroll performance without the retention.

**Consequence, stated plainly.** Revert-to-original is a creation-session capability. Editing a page of an already-saved document works from the PDF, at PDF fidelity, and the original photo is gone. This is the accepted trade for a 40-page scan leaving no full-resolution JPEGs behind.

### D5. Reconciliation is a diff, not a rebuild

**Decision.** `ReconcileLibrary` walks the tree in the existing pooled isolate and produces a diff against the index:

- present in tree, absent from index → **added** (read page count, generate thumbnail lazily on first render, not during reconcile)
- absent from tree, present in index → **removed** (drop entry, cached thumbnails, OCR text, stored password)
- present in both with a changed fingerprint → **modified** (refresh size, page count, modified date)
- absent from index at its old path but a new entry matches `(size, mtime)` → **renamed**, and the entry is re-pathed with its metadata intact

Matching on fingerprint before path is what keeps a rename in Files from silently discarding the document's favourite status and OCR text. Fingerprint collisions are possible in principle — two identical files renamed in the same pass — and resolve to an arbitrary but consistent pairing, which loses nothing because the metadata is identical too.

Throttled by `library.reconcile.lastRunAt` in SharedPreferences: a resume within 60 seconds does not re-walk. Thumbnails are *not* generated during reconcile — that would turn a resume into a batch render job — they are produced lazily and cached.

### D6. A page is an original plus two independent, revertible layers

**Decision.** A page is never "an image that gets replaced". It is:

```
original image  +  geometry (an ordered list of crop/rotate ops)  +  enhancement (settings)
```

and every rendering — row thumbnail, crop screen, enhance screen, generated PDF — is produced by the same pipeline: apply geometry to the original, then apply enhancement. Neither layer is ever baked into the other, so each is independently revertible:

| Action | Geometry | Enhancement |
| --- | --- | --- |
| Apply a crop | appended to the op list | untouched, re-applies to the new geometry |
| Revert to original (crop screen) | cleared | untouched — the full frame is still enhanced |
| Change enhancement | untouched | replaced |
| Revert enhancement (enhance screen) | untouched — the crop is kept | back to defaults |

```dart
lib/features/document_creation/domain/page_draft.dart

/// One page of a creation session: an untouched source image and the two
/// independent layers applied over it.
///
/// Holds no pixels of its own. Everything the user sees is derived by
/// [PageRenderPlan] from [originalImagePath], which is what lets either layer
/// be reverted without disturbing the other.
final class PageDraft {
  final PageId id;
  final String originalImagePath;        // the untouched capture or picked image
  final List<CropOp> geometry;           // empty == the full original frame
  final EnhancementSettings enhancement; // identity == unenhanced
}

/// One crop-and-rotate the user applied, in the coordinate space of the result
/// of the ops before it.
final class CropOp {
  final PageQuad quad;
  final double rotationDegrees;
}
```

**Geometry composes into one resampling pass.** Applying the op list literally — crop the crop of the crop — resamples the photo once per op, losing sharpness each time and costing N passes. Instead the list is composed into a single homography and the original is resampled exactly once, however many times the user cropped. `features/document_scanning/domain/perspective_transform.dart` already builds the per-op matrix; composing is a matrix product, and it stays in the domain layer as a pure function:

```dart
/// The single transform equivalent to applying [ops] in order.
Matrix3 composeGeometry(List<CropOp> ops);
```

This also removes the intermediate `crop-1.jpg`, `crop-2.jpg` files an earlier version of this design accumulated: there is the original, and there is a cached render. Nothing else is on disk.

**Rendering is cached, not recomputed per frame.** `PageRenderPlan(original, geometry, enhancement)` has value equality, so a render is keyed by the plan: change the geometry and the key changes and the render is redone; change nothing and the cached file is reused. Previews render at display resolution; generation renders once at full resolution.

**Consequence for `CropState`:**

```dart
class CropState extends Equatable {
  final CropStatus status;
  final String originalImagePath;         // never written to
  final List<CropOp> applied;             // the ops committed so far this page
  final EnhancementSettings enhancement;  // for display only; this screen never changes it
  final String? renderPath;               // cached render of original+applied+enhancement
  final PageQuad quad;                    // pending selection, against the current render
  final double rotationDegrees;           // pending rotation
  final Failure? failure;

  bool get hasUnappliedChanges => !quad.isFullPage || rotationDegrees != 0;
  bool get canApply => hasUnappliedChanges && status != CropStatus.correcting;
  bool get canRevert => applied.isNotEmpty;
}
```

- `apply()` appends a `CropOp`, re-renders from the original through the composed transform, and emits with `quad: full, rotationDegrees: 0`. It does **not** navigate.
- `revertToOriginal()` emits `applied: []` and re-renders. The enhancement is carried through untouched, so the user gets the full original frame *still enhanced* — which is the behaviour that makes the two layers legible as two layers.
- No undo stack. The user asked for revert without undo, and a stack that only ever unwinds to the bottom is a stack pretending to be a flag.

**The crop screen displays the enhanced render.** Chosen for consistency: the row thumbnail is enhanced, so an unenhanced crop screen would read as "my enhancement was lost". The cost is that an aggressive black-and-white filter can wash out the paper edge; accepted, and revisitable with a press-and-hold peek if it proves a problem in use.

**The Next prompt lives in the screen, not the Cubit.** `hasUnappliedChanges` is state; deciding to show a dialog is presentation. The screen reads the flag, shows `AlertDialog` keyed `scan_crop_apply_prompt`, and on confirm awaits `apply()` before navigating.

### D7. Control naming follows the layers

**Decision.** "Reset" is wrong once there are two revertible layers — it reads as "undo everything". Each control names the layer it touches:

| Screen | Control | Effect |
| --- | --- | --- |
| Crop | **Revert to original** (`scan_crop_revert_button`) | geometry cleared, enhancement kept |
| Enhance | **Revert enhancement** (`enhance_revert_button`) | settings to defaults, geometry kept |

Both are disabled when their own layer is already empty, so a disabled control means "there is nothing of mine to revert" rather than "nothing has been done".

### D7a. Enhancement is single-page, and the batch machinery is deleted

**Decision.** The flow is a loop of one page at a time — pick or capture → crop → enhance → done → row — so at the moment enhancement runs there is no session of sibling pages to apply settings to. `EnhancementCubit` is reduced to one `PageRef`:

- removed: `applyToAll`, `cancelApplyToAll`, `PlanSessionEnhancement`, `EnhancementStatus.applyingToAll`, `progress`, `canApplyToAll`, and the `_BatchProgress` widget with its `enhance_apply_to_all_button`, `enhance_progress_indicator` and `enhance_cancel_button` controls.
- kept: filters, sliders, shadow removal, undo, revert-enhancement (D7), the downscaled preview, and `ApplyEnhancement` on the pooled isolate — all of which act on settings only, never on geometry.
- `EnhancementState.pages`/`index` collapse to a single `page`, which removes the index-clamping the multi-page state needed.

This deletes the one place `Cancellation`/`Progress` was used in this feature; both stay in `core` for PDF generation, which still reports progress over pages.

**Why not keep it as a convenience.** "Apply to all" only makes sense against a session of already-added pages, and the pages it would target were shot under different light — which is the exact case per-page enhancement exists to handle. Keeping a control that is wrong for its most common use is worse than not having it.

**Trade-off stated plainly:** re-cropping from the original means a user who cropped, moved on, and comes back to *refine* their crop starts over rather than refining. That is exactly what the user asked for ("for these option we always use original image with no changes"), and within a single crop visit refinement is available through repeated Apply.

### D8. Import copies in; nothing outside `DocForge/` is ever written

**Decision.** `ImportPdfIntoFolder(source, targetFolders)` reads the picked file's bytes and writes them through `PublicFileStore.writeFile`, then indexes the result. The share-sheet path (`SharedContentWatcher`) and the "Open with DocForge" path both funnel into the same use case.

**Why not edit in place.** iOS in-place editing needs a security-scoped bookmark that the provider can revoke, leaving a library entry pointing at a file we can no longer open; Android SAF write grants have the same failure mode across reboots and app updates. A copy is one code path with no revocation story.

No security-scoped bookmark and no persisted SAF grant is retained after the copy completes.

### D9. Creation is a new feature; `ScanFlow` is deleted

**Decision.** `lib/features/document_creation/` owns the page table. `document_scanning` narrows to camera capture and the crop editor; `image_enhancement` is unchanged except for its entry contract.

State ownership:

| Cubit | Owns | Notes |
| --- | --- | --- |
| `PageTableCubit` | `List<PageDraft>`, last deletion for undo | Ordering rules live in `CreationSession` (domain), not here |
| `SaveDocumentCubit` | name, password, confirm, validity, save progress | Validation rules in `CreationRules` (domain) |
| `DashboardCubit` | open folder path, entries, search query | Path arithmetic in `LibraryPath` |
| `CropCubit` | geometry ops, pending selection, cached render | as D6; never mutates enhancement |
| `EnhancementCubit` | one page's settings, undo history, preview | as D7a; never mutates geometry |
| `ScanCaptureCubit` | camera lifecycle only | loses `pages`, `batchMode` |

`PageReviewCubit` and `PdfGenerationCubit`'s preview responsibility are removed. `CreationSession` (domain) holds `reorder`, `delete`, `restore`, `canSave` — the existing `ScanSessionRules` functions, moved and re-typed to `PageDraft`, so their unit tests move with them rather than being rewritten.

**Why a new feature folder rather than growing `document_scanning`.** The page table serves camera, gallery, files and shares. Naming it "scanning" would make the import feature depend on the scanning feature to reach it, which the architecture forbids.

### D10. Tabs are a `StatefulShellRoute`, and Create is an action

**Decision.** GoRouter's `StatefulShellRoute.indexedStack` with three branches: `/dashboard`, `/create`, `/settings`. Each branch keeps its own navigator stack, which is what makes "open a folder, visit settings, come back" land where the user left.

The middle tab is not a browsing destination. Its `onTap` is intercepted: it starts a session and pushes the page table onto the *root* navigator (above the shell, so the tab bar is hidden and the flow is full-screen), and the previously selected branch stays selected underneath. A Create branch that stayed selected after the user backed out would leave the tab bar highlighting a screen that is not there.

Crop, enhancement and the camera are pushed onto that same root navigator as nested routes owned by the creation flow, not declared in `AppRoutes` — they are steps of a transient session and a deep link into them would land on a session that does not exist.

`AppRoutes` loses `scan`, `scanReview`, `scanEnhance`, `scanPreview`; gains `dashboard`, `create`, and `folderPath` (query-parameterised rather than templated, because a folder path has an arbitrary number of segments).

### D11. Password is applied at generation, per document

**Decision.** `SaveDocument` gains `password`. When set, generation produces the PDF and then runs the existing `PdfManipulatorEditor.protect` (owner and user password identical, as its existing doc comment explains), writes the protected result through `PublicFileStore`, and stores the password via the existing `RememberDocumentPassword` in secure storage keyed by `DocumentId`.

Confirmation is UI-level validation in `CreationRules.validatePassword(password, confirmation)` — a pure function, unit-tested, so the Cubit only reports validity.

The unprotected intermediate is written to cache, not to the public folder, and is deleted after protection succeeds. Writing it publicly first would leave an unprotected copy visible for the duration of the protect call.

## Widget keys and semantics

Keys follow the existing `<feature>_<element>` convention and are what the automated UI tests bind to.

| Screen | Keys |
| --- | --- |
| `AppTabScaffold` | `app_tab_scaffold`, `app_tab_dashboard`, `app_tab_create`, `app_tab_settings` |
| `PageTableScreen` | `creation_page_table_screen`, `creation_page_list`, `creation_add_page_button`, `creation_save_button`, `creation_empty_state`, `creation_loading_indicator`, `creation_error_view` |
| `PageRow` | `creation_row_crop_button`, `creation_row_enhance_button`, `creation_row_delete_button`, `creation_drag_handle` |
| `AddPageSheet` | `creation_add_page_sheet`, `creation_add_from_camera`, `creation_add_from_gallery` |
| `SaveNameDialog` | `creation_save_dialog`, `creation_save_name_field`, `creation_save_password_toggle`, `creation_save_password_field`, `creation_save_password_confirm_field`, `creation_save_cancel_button`, `creation_save_confirm_button` |
| `CropScreen` | `scan_crop_screen`, `scan_crop_apply_button`, `scan_crop_revert_button`, `scan_crop_next_button`, `scan_crop_apply_prompt`, `scan_crop_prompt_apply`, `scan_crop_prompt_skip` |
| `DashboardScreen` | `dashboard_screen`, `dashboard_search_field`, `dashboard_content_list`, `dashboard_breadcrumb`, `dashboard_create_folder_button`, `dashboard_import_pdf_button`, `dashboard_storage_summary`, `dashboard_empty_state`, `dashboard_loading_indicator`, `dashboard_error_view`, `dashboard_error_retry_button` |
| Document row | `document_protected_badge` |

Semantics: each page row announces "Page N of M" and its actions announce the action plus the page ("Crop page 3"); rows expose `SemanticsAction.moveUp`/`moveDown` so reordering does not require a drag; the storage summary announces its value; tab destinations announce name and selected state; password fields are obscured and excluded from screenshots.

## Preview coverage

Fixtures come from `core/previews/fixtures`; nothing touches a camera, the filesystem, Isar or the wall clock.

| Widget / screen | States | Form factors / themes |
| --- | --- | --- |
| `PageTableScreen` | default (3 rows), loading, empty, error, long (30 rows) | phone + tablet, light + dark |
| `PageRow` | default, processing, error, long title | phone |
| `AddPageSheet` | default, permission denied | phone |
| `SaveNameDialog` | default, empty name, password on, password mismatch, saving, error | phone + tablet, light + dark |
| `CropScreen` | adjusting, applied once, applied twice, correcting, error, revert available | phone + tablet, light + dark |
| `DashboardScreen` | default, loading, empty folder, error, long content | phone + tablet, light + dark |
| `AppTabScaffold` | each tab selected | phone + tablet, light + dark |

## Determinism and hidden state

- `PublicFileStore` and the reconciler take their roots by constructor injection; no ambient path lookup inside a repository, matching `LocalDocumentFileStore`'s existing shape.
- No static mutable state. The materialised-file cache is an instance owned by the Android store, injected, and substitutable in tests.
- Reconcile is a pure diff over two lists — index entries and tree entries — so it is unit-testable without a filesystem; only the walk is I/O.
- `MethodChannel` calls go through one injectable wrapper so a fake channel can assert MediaStore arguments without a device.
- Fingerprints use file size and mtime supplied by the caller, never `DateTime.now()` inside the diff, so tests are byte-stable.

## Documentation

Dartdoc is required on: `PublicFileStore` and both implementations, `LibraryPath`, `PageDraft`, `CreationSession`, `CreationRules`, `ReconcileLibrary`, `ImportPdfIntoFolder`, `CleanupOrphanedCaptures`, every new Cubit and State variant, and every new widget including its keys.

Inline comments are required where intent is not evident: the MediaStore nested-`RELATIVE_PATH` fallback; why `LSSupportsOpeningDocumentsInPlace` is now `true` and what it does *not* mean; why reconcile matches fingerprint before path; why crop bakes rotation rather than carrying it; why the unprotected PDF is written to cache first; why the Create tab does not stay selected.

## Risks / Trade-offs

- **MediaStore nested folders vary by OEM** → flat fallback in `Documents/DocForge/` with the intended folder kept in the index; both branches covered by integration tests; the user is told where the file landed.
- **Android cache copies double transient storage for large PDFs** → LRU cap, eviction on close and on memory pressure; never invoked for list rendering.
- **Migration could lose documents** → copy, verify size and page count, only then delete; guarded by the `.layout-version` marker bumped to `2`; the interrupted case is unit-tested and resumes.
- **Publicly visible PDFs are a real reduction in confidentiality** → it is the user's stated intent, stated back to them in Settings, with per-document password protection offered at the moment of saving.
- **External renames could orphan metadata** → fingerprint-first matching in the reconciler; a rename keeps favourite, archive and OCR text.
- **A user deleting files in Files while the app is open** → reconcile on resume, plus a not-found failure path in the viewer that offers to remove the stale entry rather than crashing.
- **Retiring `ScanFlow` breaks the share-import entry point** → repointed in the same change and covered by a navigation test; `ScanFlow` is deleted, not left dead, so nothing can quietly keep using it.
- **Discarding originals at save time closes the door on later original-fidelity re-editing** → accepted; it is what keeps a 40-page session from leaving 40 full-resolution JPEGs behind, and post-save page editing renders from the PDF.
- **`StatefulShellRoute` plus a non-destination middle tab is fiddly** → the interception is one place, covered by navigation tests asserting that backing out of creation restores the previous branch.

## Migration Plan

1. **Layout marker.** `LocalDocumentFileStore.layoutVersion` → `2`. Migration runs in `buildLibraryModule` before the router is built, so no screen ever sees a half-migrated library.
2. **Per document:** copy `documents/<uuid>/document.pdf` → `DocForge/<title>.pdf` (de-duplicating the name with a numeric suffix), verify size and page count, discard the old stored thumbnails (they are re-derived on demand, D4a), rewrite the Isar entity with `folderPath` and `fileName`, then delete the old directory including `pages/`.
3. **Missing source** → drop the index entry and continue.
4. **Interruption** → the marker is written only after the last document; on restart, already-migrated documents are recognised by the presence of their public file and skipped.
5. **Folders.** Existing `FolderEntity` records become real directories under `DocForge/`, and their documents are copied into them rather than into the root.
6. **iOS `Info.plist`** ships in the same build; the flags only take effect once `Documents/` contains nothing but `DocForge/`, which step 2 guarantees.
7. **Rollback.** Reverting the build after migration leaves documents in `DocForge/` that the old code cannot see. Mitigation: migration is additive-then-deleting per document, so a revert taken before the update is released loses nothing; once released, forward-fix rather than roll back. This is stated so the release decision is made with it in view.

## Future extensibility

Addressing documents by folder-relative path with a content fingerprint is the shape a sync engine needs: the path is the stable remote key, the fingerprint is the change detector, and `ReconcileLibrary` is already a two-way diff that a remote manifest turns into a three-way merge. `PublicFileStore` being a `core` contract means a `SyncedFileStore` composes beside the platform stores without a feature changing. Per-document passwords stay device-local in secure storage; syncing them is a separate decision the design does not foreclose.

## Open Questions

1. **Duplicate names across a rename.** If a user renames a document to a name already in the folder *in Files*, the OS may allow it on one platform and not the other. Proposed: the reconciler treats whatever the filesystem ended up with as truth and re-indexes; no in-app resolution. Confirm during implementation on both platforms.
2. **Archived documents stay visible in Files.** Archive is metadata-only, so an archived document remains in its folder externally. Alternative is moving it to `DocForge/.Archive/`, which makes archive a file move and complicates restore. Proposed: metadata-only, as specified.
3. **Legacy folder names that are invalid as directories.** Existing `FolderEntity` names were never constrained to filesystem-safe characters. Proposed: sanitise during migration and keep the original name as the display title; needs a decision on whether the sanitised name or the original wins after a later external rename.

### Answers recorded during implementation

**Q3 — the name on disk wins, and there was never a contest.** `DashboardCubit` lists folders from `PublicFileStore.list`, never from `FolderEntity`, so what the dashboard shows is what the directory is called. `ReconcileLibrary` reads the folder set only to build the diff and writes no folder records back. A folder renamed externally therefore shows its new name on the next load with no reconciliation step involved, and the migration's sanitised name only ever mattered as the directory it created. The `FolderEntity` record survives as the identifier documents are filed under; its `name` is not what the user reads.

**Q1 — the filesystem's outcome is taken as truth, as proposed.** `LibraryReconciliation.diff` matches on path first and then on a *uniquely* sized file, and reports an ambiguous pair as an addition plus a removal rather than guessing which document moved where. So whichever way a platform resolves a duplicate-name rename — refusing it, suffixing it, or replacing the file — the index follows the folder and no in-app dialog is raised. What still needs a device (task 13.10) is only the observation of *which* of those three each platform does, and whether either produces a case-only collision that a case-insensitive filesystem hides.
