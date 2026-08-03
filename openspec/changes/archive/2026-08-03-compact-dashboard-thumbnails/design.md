## Context

`DashboardScreen` currently builds search, breadcrumb, Recent, and collections as fixed children above an `Expanded` document `ListView`. At the root this consumes about 300 logical pixels before content, including a disabled “DocForge” breadcrumb that duplicates the app bar. Recent already contains at most five documents but uses title-only chips. The prior `fix-document-detail-viewing` change established a secure, cached, bounded first-page renderer exposed as `LibraryModule.loadDocumentPageThumbnail`.

## Goals / Non-Goals

**Goals:**

- Keep Recent to one non-wrapping horizontal lane containing at most five compact tiles.
- Make dashboard sections participate in one vertical lazy scroll so content can reclaim the viewport.
- Add first-page previews to Recent and normal document rows using the existing thumbnail boundary.
- Preserve folder navigation, search, collection actions, refresh, accessibility, dark mode, text scaling, and phone/tablet behavior.

**Non-Goals:**

- Changing recent ordering, the five-item bound, search behavior, navigation routes, or folder persistence.
- Generating thumbnails eagerly or storing image bytes in Cubit state/Isar.
- Adding web/desktop support, cloud sync, dependencies, or schema migrations.

## Decisions

### D1 — One dashboard scroll surface

The body will use a `CustomScrollView`/slivers (or an equivalent single lazy scrollable) containing root quick access, the one-lane Recent section, folders, documents, empty/error/loading states, and storage summary. Search remains at the beginning of that surface and refresh wraps the scroll view. The breadcrumb is omitted at root and inserted only for a nested path.

This is preferred to shrinking individual fixed sections because fixed chrome would continue constraining the library at every scroll position. A nested `ListView` was rejected because competing scrollables complicate gestures, refresh, accessibility traversal, and lazy construction.

### D2 — Recent is one bounded horizontal lane

Recent remains backed by `DashboardState.recents` and `DashboardCubit.maxRecents == 5`. A fixed-height horizontal `ListView` never wraps; each compact tile places a small portrait thumbnail beside an ellipsized title. The section is vertically compact and remains horizontally scrollable at large text scales.

A wrapping grid was rejected because it violates the explicit one-row requirement and grows vertically as documents are added. Portrait cards with the title below the image were rejected because they consume more height.

### D3 — Reusable lazy document thumbnail

A stateful `DocumentThumbnail` presentation widget will memoize one injected `Future<Result<String>>` request for page 1, display bounded loading/success/fallback states, and decode the cached file at an appropriate cache size. It owns no storage knowledge and never receives a password. Stable keys will include `document_thumbnail_<document-id>` and `document_thumbnail_loading_<document-id>`; its image semantics label is “<title> preview”.

`DocumentCard` and Recent tiles receive an optional `Future<Result<String>> Function(Document, int)` callback through constructors. Production composition passes `library.loadDocumentPageThumbnail.call`; previews/tests may omit or fake it. This keeps dependency direction presentation → application → domain, with infrastructure still reached only by the use case.

Reusing `PageThumbnail` directly was rejected because that widget requires a `DocumentPage`, renders a page-number caption, and models detail-screen interaction rather than a document cover.

### D4 — Existing Cubit and persistence contracts remain authoritative

No Cubit/State variant or transition changes. `DashboardCubit` continues `initial/loading → ready|failure`, and search/path operations remain unchanged. No business logic moves into widgets or the Cubit. There are no new Freezed/json contracts, repository methods, Isar data, preference values, secure-storage keys, or routes.

The existing use case retrieves protected-document passwords through `SecureStore`, resolves the authoritative PDF, and calls `DocumentThumbnailCache`. Composition injects it explicitly from `LibraryModule`; there is no service locator or hidden mutable state.

### D5 — Accessibility, previews, and verification

Recent tiles are buttons labeled with document metadata and retain deterministic document-specific keys. Normal rows retain their merged metadata semantics; their decorative thumbnail does not add a redundant focus stop. The horizontal lane remains one lane under large text and allows scrolling rather than clipping.

`@Preview()` fixtures will cover dashboard ready/loading/empty/error/long-content states and document thumbnails in success/loading/fallback forms, across existing phone/tablet and light/dark surfaces. Dashboard goldens will be regenerated for phone/tablet light/dark. Tier-1 widgets cover request memoization and layout; the dashboard Tier-2 component test uses the real Cubit; `browse_and_view` observes the dashboard thumbnail and still opens the detail/viewer flow.

Public widget APIs and key/semantics helpers receive dartdoc. Inline comments explain why requests are memoized, why the root breadcrumb is suppressed, and why the thumbnail remains excluded from row semantics.

## Risks / Trade-offs

- **Many visible rows trigger simultaneous PDF opens** → Lazy sliver construction, cache hits, bounded render sizes, and memoized per-widget requests limit work; failed previews fall back without retry loops.
- **A thumbnail makes a row taller** → Use a compact portrait size within the existing practical ListTile touch target and constrain decoding rather than expanding to a card grid.
- **Horizontal Recent content is less discoverable past the viewport** → Partial trailing content and horizontal scroll semantics signal continuation; the maximum remains five.
- **Moving search into scrolling content means it can leave the viewport** → The app bar remains visible and the list returns to the search control at the top; this trade-off is accepted to reclaim reading space.
- **Golden churn** → Update only the dashboard baselines after behavior-focused widget tests pass.

## Migration Plan

No persisted data migration or staged rollout is required. Deploy the presentation and injection changes together. Rollback consists of restoring the previous dashboard composition; existing cached thumbnails remain harmless derived files and continue to be purged with their documents.

## Open Questions

None. The product decisions—five maximum Recent documents, exactly one lane, compact horizontal tiles, and thumbnails in the normal list—are resolved.
