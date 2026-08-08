## Context

Document activation currently pushes `/documents/:id`, loads `DocumentDetail` plus stored pages and unified page handles, builds a horizontal page strip, and only then exposes an Open button that pushes `/documents/:id/view`. The strip is widget-lazy, so opening a 100-page PDF does not rasterize all pages immediately, but scrolling eventually creates reusable files beneath the private `document-pages` cache with no explicit global bound. It also makes Detail an unnecessary gate in the most common journey: reading the PDF.

The existing `pdfrx` viewer already renders pages on demand and holds the resolved document, page count, current page, password, and title in `ViewerState`. The library already owns favourite and lifecycle use cases. The design must reverse the navigation relationship without introducing a document-viewer → document-library import, preserve typed routes, work offline on Android/iOS, and reconcile changes made while Detail is pushed over Viewer.

## Goals / Non-Goals

**Goals:**

- Open Viewer directly from every active document entry point and return to the originating surface.
- Expose favourite status as a direct, accessible Viewer app-bar action.
- Reach a metadata-focused Detail screen from Viewer overflow without generating page previews.
- Preserve Detail metadata, favourite, rename, move, duplicate, archive/restore, and Trash actions.
- Reconcile Viewer title/favourite/archive/deletion after Detail closes without resetting the current page.
- Keep page-image materialisation for explicit page workflows and cap its derived thumbnail cache.
- Preserve existing typed route paths, stored documents, passwords, and offline behavior.

**Non-Goals:**

- Replacing `pdfrx`, changing its zoom/page rendering implementation, or adding a viewer thumbnail rail.
- Removing `DocumentPage`, page access, OCR, page-image sharing, or page-management functionality.
- Synchronizing favourites or archive state through iCloud.
- Changing Isar schemas, public PDF locations, password storage, or adding dependencies.
- Adding web or desktop targets; this remains Android/iOS only.

## Decisions

### 1. Viewer becomes the default typed destination

Dashboard, Recent, Documents, folder contents, search, favourites, archive, successful creation/import, duplication, and derived editor outcomes navigate to `AppRoutes.documentView(id)`. The existing detail path remains a valid typed deep link and Viewer pushes it for `Document details`.

```text
Library origin ──push──▶ Viewer ──push──▶ Detail
     ▲                 │  page N          │ metadata/actions
     └──────pop────────┴◀────pop───────────┘
```

Viewer receives `onShowDetails: Future<void> Function()` from the composition root. `ViewerDocumentAction.details` is selected through `Key('viewer_document_details_button')` with semantics `Show document details`. Feature widgets do not construct or parse route strings.

Alternative considered: keep Detail as the first screen and optimize its strip. This avoids navigation changes but retains an unnecessary reading step and still gives page-preview caching a role in ordinary opening. A modal details sheet was also considered, but the existing full Detail route already handles long metadata, dialogs, tablet layout, deep links, and lifecycle workflows.

### 2. Detail loads metadata only

`LoadDocumentDetail` is narrowed or replaced by `LoadDocumentMetadata`, which reads only the `DocumentRepository`. `DocumentDetailState` removes `pages` and `pageHandles`; `DocumentDetailScreen` removes `loadPageThumbnail`, the Pages strip, and `document_open_button`. Existing lifecycle use cases continue to load pages internally when duplication or purge requires them.

Detail retains:

- title, page count, size, created/modified dates, folder and cloud status;
- `Key('document_favourite_toggle')`;
- the existing rename, move, duplicate, archive/restore, and Trash overflow controls.

No Detail initial/load/ready transition may call `DocumentPageAccessRepository.pagesOf` or `materialize`. Deep-linked Detail remains usable and its Back action returns through the typed router.

Alternative considered: retain page handles but stop building the strip. That would avoid rasterization but preserve unnecessary page repository reads and a misleading state contract.

### 3. Favourite mutation is injected into Viewer without feature coupling

The viewer application layer defines function contracts over core models:

```dart
typedef LoadViewerMetadata = Future<Result<Document>> Function(DocumentId id);
typedef ToggleViewerFavourite = Future<Result<Document>> Function(DocumentId id);
```

The app composition root adapts `library.documentReader.findById` and `library.toggleFavourite.call` to these contracts. The document-viewer feature imports core models/results only and never imports document-library.

`ViewerState` remains one immutable Equatable state and gains:

- `bool isFavouriteWorking`;
- `Failure? actionFailure` separate from the fatal open failure;
- `bool isUnavailable` for a document removed while Detail was open.

Transitions are deterministic:

```text
ready ──toggle──▶ ready/working ──success──▶ ready(updated Document)
                              └─failure───▶ ready(actionFailure)

ready(page N) ──Detail closes──▶ refresh metadata
                              ├─success──▶ ready(page N, updated Document)
                              ├─notFound─▶ unavailable ──UI callback──▶ pop Viewer
                              └─failure──▶ ready(page N, actionFailure)
```

`ViewerCubit` invokes the injected operations and emits state; favourite and availability rules remain in use cases/repositories. A `BlocListener` presents nonfatal failures and invokes `onDocumentUnavailable`; a `BlocSelector` or narrowly rebuilt app-bar action ensures favourite changes do not replace the PDF surface. The surface keeps a stable key based on the resolved file path, so current page/zoom state is not discarded by metadata-only updates.

The favourite control uses `Key('viewer_favourite_button')`, semantics `Add <title> to favourites` or `Remove <title> from favourites`, `Icons.star_border` or `Icons.star`, a minimum 48 logical-pixel target, and disabled/progress semantics during mutation.

Alternative considered: pass a UI-only callback and optimistically flip the icon. That hides typed repository failures and can leave Viewer inconsistent with Dashboard. Importing `ToggleFavourite` directly was rejected because it violates feature boundaries.

### 4. Viewer refreshes metadata after Detail returns

The composition callback awaits the typed Detail push, then calls `ViewerCubit.refreshMetadata()`. Refresh reads the document record only; it does not resolve or reopen the PDF and does not change `filePath`, password, page count, or current page. This captures rename, favourite, archive/restore, move, and external metadata reconciliation cheaply.

If Detail moves the document to Trash, its existing deleted transition pops Detail. The following metadata lookup returns not-found; Viewer marks itself unavailable and the screen invokes its supplied Back callback once. Other refresh failures retain the readable PDF and show a SnackBar rather than replacing it with a fatal error surface.

When duplication succeeds from Detail, its typed callback replaces Detail with the copied document's Viewer route, preserving the existing “exactly one copy” behavior without stacking the source Detail route.

Alternative considered: return a custom mutable outcome from every Detail action. A metadata refresh is simpler, also covers external reconciliation, and avoids making Detail know which parent opened it.

### 5. Explicitly bound derived page-preview caching

Dashboard/list first-page thumbnails remain in their existing document-thumbnail cache. `LibraryDocumentPageAccessRepository` keeps materialising thumbnail-sized page images only when page-management or another explicit consumer requests them. Its `document-pages` cache is capped at both 128 files and 64 MiB globally.

Before writing a new cached render, asynchronous pruning removes oldest last-accessed/last-modified entries until the incoming render can fit both limits. The requested target, files created during the current operation, and non-cache authoritative images are never candidates. Cache hits touch the file timestamp to maintain deterministic least-recently-used ordering; path is the stable tie-breaker. Missing pruned files are normal cache misses and are regenerated from the authoritative PDF.

Directory enumeration and file stats use asynchronous Dart I/O outside the frame build path. No isolate is introduced initially because PDF rendering dominates this bounded work; profiling may move pruning to an isolate later without changing the repository contract. Cleanup failures do not hide a successfully readable PDF page but are covered by diagnostics/tests.

Alternative considered: delete every page preview on Viewer/Detail close. That causes repeated work for page-management workflows and creates lifecycle coupling. An unbounded cache was rejected because scrolling large PDFs can consume growing private storage.

### 6. Persistence, security, dependency construction, and models

- Isar continues storing `Document` and existing page rows; no schema migration or generated model change is required.
- No SharedPreferences key is added because cache limits are fixed implementation policy, not a user setting.
- No secure-storage key changes. PDF passwords remain read from `flutter_secure_storage` and retained in Viewer memory only while open.
- Derived previews remain app-private and are never logged, synced, or published.
- No new Freezed/json_serializable persisted model is introduced. If a navigation result type is needed, it is a non-persisted immutable sealed/domain value and requires no JSON.
- `buildLibraryModule` continues constructing repositories/use cases; `buildViewerScreens` receives metadata/favourite functions from `LibraryModule` and passes them explicitly to `ViewerCubit`. There is no locator, singleton, hidden mutable cache registry, or nondeterministic clock dependency; cache ordering receives/injects filesystem timestamps or a test clock where needed.

### 7. Keys, semantics, previews, and documentation

New/changed stable controls:

| Control | Key | Semantics |
|---|---|---|
| Viewer favourite | `viewer_favourite_button` | `Add <title> to favourites` / `Remove <title> from favourites` |
| Viewer Details menu item | `viewer_document_details_button` | `Show document details` |
| Detail favourite | `document_favourite_toggle` | Existing add/remove favourite labels |

`document_detail_screen` and `viewer_screen` remain stable. `document_open_button`, `page_thumbnail_<page-id>`, and Detail page-loading keys are removed from the Detail journey; page-thumbnail keys remain valid wherever explicit page workflows still use that widget.

Viewer previews cover loading, locked, error, ready non-favourite, ready favourite, mutation working/failure, unavailable, long title, phone/tablet, light/dark, and supported large text. Lean Detail previews cover loading, error, ready, long title, protected/cloud states, phone/tablet, light/dark, and large text; the old no-thumbnails/page-strip preview is removed. Deterministic fixture documents supply every state.

All new public contracts, use cases, Cubit methods, state fields, and keys receive truthful dartdoc. Inline comments explain why metadata refresh preserves the PDF surface and why cache pruning occurs before writing.

## Risks / Trade-offs

- [Viewer app bar becomes crowded on narrow phones] → Keep Back, title, Favourite, and Share direct; place Details and focused operations in the existing overflow and verify large-text layouts.
- [Detail mutation leaves Viewer stale] → Await typed Detail navigation and perform metadata-only refresh on every return while preserving page/file state.
- [Deleting from Detail reveals a deleted PDF in Viewer] → Treat not-found refresh as unavailable and pop Viewer exactly once.
- [Non-not-found refresh failure interrupts reading] → Keep the open PDF and show a nonfatal action message.
- [Cache pruning races an image decoder] → Prune before writing new content, exclude current targets, touch hits, use deterministic serialized cache maintenance, and treat a missing file as a normal re-render.
- [Direct routing breaks Back behavior in nested tabs] → Use typed `push` from each origin and navigation tests that assert return to the same Dashboard/list/folder/search surface.
- [Existing completed OpenSpec change still describes Detail previews] → This change's full modified requirements supersede those scenarios; archive/sync changes in dependency order and validate final main specs.
- [Removing page previews reduces page discoverability] → Viewer already provides continuous scroll and jump-to-page; page thumbnails remain in Manage Pages where they support a concrete task.

## Migration Plan

1. Add viewer metadata/favourite contracts, state transitions, controls, and component coverage without changing entry routes.
2. Simplify Detail data/query/state and UI; keep the existing typed Detail route functional for deep links.
3. Add Viewer → Detail navigation and metadata reconciliation, including delete and duplicate outcomes.
4. Switch each library/creation/import/editor entry point to the typed Viewer route and update robots/tests incrementally.
5. Add deterministic page-cache bounds and repository tests.
6. Update previews/goldens and run the full verification gate on Android/iOS-supported infrastructure.

Rollback consists of restoring activation callbacks to Detail and restoring the page strip/query fields. No data rollback is needed because routes, Isar schema, public PDFs, preferences, and credentials are unchanged. Cache pruning only deletes reproducible derived files.

## Open Questions

None blocking. The 128-file/64-MiB cache limits are explicit initial defaults and can be revised from device profiling without changing observable page-access behavior.
