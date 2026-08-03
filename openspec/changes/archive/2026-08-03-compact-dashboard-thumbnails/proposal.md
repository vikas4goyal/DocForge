## Why

The dashboard permanently reserves roughly a third of a phone viewport for search, a redundant root breadcrumb, Recent, and collection controls, leaving too little room for the library itself. Document rows and Recent chips also lack visual page previews, making similarly named PDFs harder to distinguish.

## What Changes

- Make dashboard chrome and content one vertically scrolling surface so quick-access sections scroll away with the library.
- Hide the breadcrumb at the library root while retaining it inside folders.
- Keep Recent bounded to five documents in exactly one non-wrapping horizontal lane.
- Present each Recent document as a compact horizontal tile with a lazy first-page thumbnail, title, loading state, and stable fallback.
- Add lazy first-page thumbnails to normal document rows without loading full-resolution page images.
- Compact the Favourites, Archive, and Trash row while preserving its actions, counts, keys, and accessibility.
- Update previews, goldens, component coverage, and the real-device browse flow for the changed dashboard.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `document-library`: The dashboard layout, one-row Recent presentation, and document-list thumbnail behavior change.

## Impact

- **Presentation:** `document_library` dashboard composition, Recent tiles, `DocumentCard`, keys, semantics, and previews change. The dashboard uses one lazy scroll surface rather than fixed sections above an `Expanded` list.
- **Application/domain/infrastructure:** The existing constructor-injected `LoadDocumentPageThumbnail` use case and `DocumentThumbnailCache` abstraction are reused; no new storage implementation is required.
- **Composition:** `LibraryModule` already exposes thumbnail loading; the dashboard production builder will inject it explicitly.
- **Cubit and state:** `DashboardCubit.maxRecents` remains five and `DashboardState` remains the source of the single Recent list; no business rule changes are needed.
- **Repositories and persistence:** No repository API, Isar schema, migration, preference key, secure-storage key, or route changes are required.
- **Dependencies and platforms:** No dependency is added. The change remains Android/iOS only.
- **Performance:** Thumbnails are requested only by lazily built visible rows/tiles, rendered at bounded dimensions, cached privately, and replaced by stable placeholders on failure. Full-resolution page images are not retained.
- **Security:** Protected PDFs continue to retrieve passwords only through secure storage inside the existing use case; widgets receive only a derived thumbnail path or failure.
- **Testing:** Unit/widget tests cover lazy loading, one-lane layout, fallback, semantics, and root/nested breadcrumb behavior. The real Cubit component test, dashboard previews, phone/tablet light/dark goldens, key audit, and `browse_and_view` device flow cover integration.
- **Risks:** Rebuilding a shared thumbnail widget could duplicate requests or disturb accessibility. Memoized stateful loading, deterministic keys, constrained image decoding, and targeted regression tests mitigate this.
- **Future extensibility:** Thumbnail retrieval remains behind the existing domain port, allowing a future synced document source to populate the same private cache without changing presentation.

## Resulting Feature Structure

```text
lib/features/document_library/
  presentation/
    screens/dashboard_screen.dart
    widgets/document_card.dart
    widgets/document_thumbnail.dart
    library_dashboard_keys.dart
    library_previews.dart
  application/usecases/document_thumbnails.dart   (reused)
  domain/repositories/library_repositories.dart   (reused)
  infrastructure/datasource/
    derived_thumbnail_cache.dart                  (reused)
    pdfrx_thumbnail_renderer.dart                 (reused)
```

## Definition of Done

- Recent contains at most five items in one horizontal, non-wrapping lane on phone and tablet.
- Root dashboard no longer shows a redundant breadcrumb; nested navigation still does.
- Dashboard sections scroll away and document rows can use the full viewport.
- Recent and visible document rows show lazy cached thumbnails or an accessible fallback without crashing.
- Previews, goldens, unit, component, and Tier-3 coverage are updated; formatting, analysis, architecture, coverage, and all configured device flows pass.
