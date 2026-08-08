## Why

Opening a document currently detours through a Detail screen whose page strip can rasterize and retain previews that add little value, especially for PDFs with hundreds of pages. Documents should open directly in the existing on-demand PDF viewer, while metadata and organisation actions remain available without making per-page preview generation part of ordinary browsing.

## What Changes

- **BREAKING** Change taps on documents in Dashboard, Documents, folders, search, favourites, archive, and post-creation/derived-document flows to open the typed viewer route directly instead of routing through Detail.
- Add an accessible favourite toggle to the viewer app bar: an outlined star for a non-favourite document and a filled star for a favourite document.
- Add `Document details` to the viewer overflow menu and open the existing typed Detail route over the viewer.
- Make Detail metadata-focused: retain document metadata, favourite control, and lifecycle actions, but remove the page thumbnail strip and the redundant `Open` button.
- Stop loading page handles or materialising page thumbnails merely because Detail was opened.
- Refresh viewer metadata after returning from Detail, preserve the current page, and close the viewer safely when the document was deleted or otherwise became unavailable.
- Keep page materialisation available for workflows that genuinely need individual page images, including page management, page-image sharing, and OCR.
- Bound reclaimable PDF-derived page-preview cache growth so page-oriented workflows cannot accumulate unlimited private temporary data.
- Update previews, keys/semantics, navigation robots, and the three-tier verification coverage for the revised flow.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `app-shell`: Document activation opens the typed viewer route directly and returns to the originating library surface.
- `document-library`: Detail becomes metadata-focused, no longer enumerates or previews pages, and retains favourite and lifecycle management.
- `document-viewer`: Viewer exposes favourite and Details actions and reconciles metadata or deletion after returning from Detail.
- `public-document-storage`: Reclaimable PDF-derived page previews have an explicit bounded-cache policy while first-page library thumbnails remain reusable.
- `automated-verification`: Browse, view, organise, creation, import, and derived-document journeys verify the direct viewer route and viewer-to-Detail path.

## Impact

### Architecture and code

- `lib/features/document_library/`
  - `presentation/`: simplify `DocumentDetailScreen`, its previews, keys, semantics, and component tests; remove page-strip presentation dependencies.
  - `application/`: replace Detail's page-enumerating query with a metadata-only query while preserving lifecycle use cases.
  - `domain/`: retain existing document/page abstractions; no cross-feature imports are introduced.
  - `infrastructure/`: retain unified page materialisation for page-oriented consumers and add bounded cleanup at the private cache boundary.
- `lib/features/document_viewer/`
  - `presentation/`: add favourite state/action and a Details overflow action to `ViewerScreen`, `ViewerCubit`, `ViewerState`, keys, semantics, and previews.
  - `application/`: add injected metadata refresh and favourite-toggle orchestration through core/domain abstractions.
  - `domain/`: define only the minimal viewer-facing contracts needed to avoid importing document-library feature code.
  - `infrastructure/`: continue using the existing on-demand `pdfrx` surface; no eager page rasterizer is added.
- `lib/app/`
  - update typed route callbacks and composition-root adapters across Dashboard, lists, folders, search, creation, import, and editor-success paths.
- `integration_test/` and `test/`
  - update robots, navigation assertions, components, Cubits, cache repositories, previews, and goldens.

Resulting structure remains feature-first:

```text
lib/features/
  document_library/
    presentation/{cubit,screens,widgets}/
    application/usecases/
    domain/repositories/
    infrastructure/
  document_viewer/
    presentation/{cubit,screens}/
    application/usecases/
    domain/repositories/
    infrastructure/repositories/
lib/core/
  contracts/                 # cross-feature document metadata operations
  isolates/                  # bounded derived-thumbnail cache where applicable
lib/app/
  router/
  screens/
```

### State, use cases, repositories, and persistence

- Cubits/States: Viewer state gains a favourite mutation/refresh state without losing its current page; Detail state no longer carries page handles or page-preview loading concerns.
- Use cases: introduce or adapt metadata-only load/refresh and viewer favourite orchestration; page access remains separate for consumers that request page pixels.
- Repositories: use injected core/domain contracts for document lookup/mutation; add bounded pruning to the existing private derived-page cache implementation rather than creating a new storage system.
- Isar: no schema migration is expected; existing page rows remain compatible for sharing, OCR, duplication, and deletion.
- Preferences and secure storage: no new preference or secure-storage key is required. Existing PDF password handling remains unchanged.
- Navigation: route paths and typed identifiers remain stable, but the default activation target changes from Detail to Viewer. Details is pushed from Viewer and returns a deterministic updated/deleted outcome.

### Dependencies, migration, security, and platforms

- No new package dependency is planned. Existing GoRouter, flutter_bloc, Isar, `pdfrx`, and cache/file abstractions are sufficient.
- Existing deep links to Detail remain valid; existing documents need no data migration.
- Derived thumbnails remain app-private and contain document content, so pruning must never publish, log, or move them into public storage. PDF passwords remain in secure storage and in viewer memory only while required.
- The change targets Android and iOS only. It adds no web or desktop support.

### Performance and future sync

- Ordinary document opening performs no Detail page enumeration and no per-page thumbnail generation before the viewer appears.
- The viewer continues to render visible PDF pages on demand and must not build a page-count-sized widget or image list.
- Favourite updates rebuild only viewer chrome, not the PDF surface. Metadata refresh preserves page/zoom surface identity where practical.
- Cache pruning uses bounded file count/bytes and deterministic oldest-entry removal off the frame-critical path; it does not require a new isolate unless profiling shows directory scanning exceeds the existing background-work threshold.
- Future cloud sync can surface the same direct Viewer flow after the existing resolver materialises remote bytes; favourite/archive metadata contracts remain injectable and sync-ready.

### Testing, previews, risks, and Definition of Done

- Unit: viewer/domain rules, metadata refresh outcomes, favourite success/failure, cache bounds/pruning, and route destinations.
- Cubit: loading, ready, favourite mutation, failed mutation, Detail return, metadata refresh, deletion, and current-page preservation.
- Repository: bounded cache reuse/pruning and compatibility with protected, missing, corrupt, scanned, and imported PDFs.
- Component: real Viewer and Detail Cubits/use cases with repository fakes; direct actions, semantics, long titles, large documents, and no Detail thumbnail requests.
- Navigation: typed direct-open from every library surface and viewer-to-Detail/back/deleted outcomes.
- Integration: update browse-and-view, organise, capture, import, and editing flows to use stable keys/semantics and prove return behavior.
- Goldens/previews: Viewer non-favourite/favourite/loading/error/locked/long-title phone/tablet light/dark; lean Detail ready/loading/error/long-title phone/tablet light/dark. Empty states remain represented where valid; Detail has no artificial empty page-strip state.
- Risks: viewer action crowding is mitigated by keeping Share and Favourite direct while secondary actions stay in overflow; stale metadata is mitigated by an explicit return outcome plus lightweight refresh; disappearing organisation actions are prevented by retaining them on Detail; cache deletion races are mitigated by never pruning files currently leased/materialised.
- Definition of Done: all modified specs are satisfied; no Detail opening requests a page preview; documents open directly in Viewer from every supported source; favourite status is accessible and persistent from Viewer and Detail; Detail lifecycle changes reconcile correctly on return; derived cache limits are enforced; formatting, analysis, layering/platform checks, all three test tiers, goldens, and coverage gates pass or device-gate limitations are reported exactly as required.
