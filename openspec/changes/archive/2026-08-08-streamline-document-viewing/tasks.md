## 1. Viewer Metadata and Favourite State

- [x] 1.1 Add dartdoc-documented viewer-facing metadata/favourite function contracts over core `Document`, `DocumentId`, and `Result` types, inject them explicitly from the app composition root, and confirm the viewer feature has no document-library import or new dependency.
- [x] 1.2 Extend immutable Equatable `ViewerState` and `ViewerCubit` with favourite-working, nonfatal action-failure, metadata-refresh, and unavailable transitions while preserving file path, password, current page, and surface identity.
- [x] 1.3 Add Tier-1 use-case and `bloc_test` coverage for favourite success/failure, metadata refresh/no-change, not-found closure state, transient refresh failure, and current-page preservation; run the focused unit tests.
- [x] 1.4 Add `viewer_favourite_button` and `viewer_document_details_button` to `viewer_keys.dart` with dartdoc, 48-point touch targets, filled/outlined star states, exact add/remove/Details semantics, disabled working behavior, and narrow rebuild boundaries around Viewer chrome.
- [x] 1.5 Add Tier-1 widget coverage for favourite/Details keys, semantics, icon states, long-title/large-text reachability, nonfatal messages, and proof that favourite mutation preserves the keyed PDF surface; run the focused tests.
- [x] 1.6 Add a Tier-2 Viewer component test using the real `ViewerCubit` and real viewer use cases with repository/platform boundaries faked, covering open, favourite persistence/failure, Details activation, refresh, and unavailable outcomes; run the component test.

## 2. Metadata-Only Document Details

- [x] 2.1 Replace Detail's page-enumerating load contract with a metadata-only use case, remove `pages`/`pageHandles` from `DocumentDetailState`, and update `DocumentDetailCubit` while retaining all favourite and lifecycle use cases.
- [x] 2.2 Add Tier-1 query and `bloc_test` coverage proving Detail loads metadata without calling page repositories/page access and retains rename, move, duplicate, archive/restore, favourite, and Trash transitions; run the focused unit tests.
- [x] 2.3 Remove Detail's Open button, page strip, `loadPageThumbnail` dependency, page-preview loading state, and now-unreferenced Detail-only `PageThumbnail` presentation code/keys while retaining metadata, cloud status, favourite, and lifecycle controls.
- [x] 2.4 Add Tier-1 widget coverage for metadata-only ready/loading/error states, absence of `document_open_button` and page thumbnails, existing lifecycle keys, accessibility, long titles, large text, dark mode, and phone/tablet layouts; run the focused tests.
- [x] 2.5 Update the Tier-2 Detail component test to use the real Cubit/use cases, assert zero page enumeration/materialisation for a hundreds-page fixture, and exercise favourite plus lifecycle actions through repository fakes; run the component test.

## 3. Typed Direct-Viewer Navigation and Reconciliation

- [x] 3.1 Add the Viewer → typed Detail callback in `buildViewerScreens`, await its return, trigger metadata-only refresh, show transient failures without replacing the PDF, and pop Viewer exactly once when the record is no longer available.
- [x] 3.2 Add Tier-1 Viewer/navigation tests for Details push/back, mutation refresh, deletion, duplicate-result routing, deep-linked Detail, unknown IDs, and stable current-page/file state; run the focused tests.
- [x] 3.3 Change Dashboard/Recent, Documents, folders, search, favourites, archive, creation, import, duplication, and editor-derived success callbacks to push/replace the typed Viewer route directly, preserving each origin's Back stack and avoiding string route literals.
- [x] 3.4 Add Tier-1 router/navigation tests for every changed entry point and result path, including return to the originating surface and exactly-one Viewer route after creation/derivation; run the focused tests.
- [x] 3.5 Add or update Tier-2 Dashboard/list/search/Viewer components with real Cubits and use cases to prove document activation emits the direct-view callback and Detail reconciliation does not create a page-thumbnail request; run all affected component tests.

## 4. Bounded Derived Page Cache

- [x] 4.1 Add a dartdoc-documented deterministic cache-maintenance abstraction for `document-pages`, capped globally at 128 files and 64 MiB, using asynchronous least-recently-used pruning before writes with path tie-breaking and protection for current/authoritative files.
- [x] 4.2 Integrate cache touch/prune/regenerate behavior into `LibraryDocumentPageAccessRepository` without changing authoritative PDF/image lifetimes, password handling, or typed failure contracts, and add inline comments explaining race prevention and reproducible eviction.
- [x] 4.3 Add Tier-1 repository tests for count/byte bounds, deterministic LRU ordering, cache-hit timestamp refresh, regeneration after eviction, changed-PDF invalidation, protected PDFs, concurrent/current-target protection, cleanup failure, and no Detail-triggered materialisation; run the focused tests.
- [x] 4.4 Add a performance regression test using a hundreds-page document fixture to prove ordinary direct viewing and Detail loading create no page-preview cache entries while explicit page consumers remain bounded; run the focused performance test.

## 5. Keys, Robots, and Tier-3 Journeys

- [x] 5.1 Update the central key/semantics registries and all affected robots in the same change: add Viewer favourite/Details controls, remove Detail Open/page-strip dependencies from browse/organise robots, and keep explicit page-workflow keys where still used.
- [x] 5.2 Update the Tier-3 `browse_and_view` flow to open Viewer directly, jump/read, open metadata-only Detail through `viewer_document_details_button`, return without losing position, and finally return to the original library surface.
- [x] 5.3 Update the Tier-3 `organise` flow to favourite from Viewer, perform rename/move/archive through Details, verify metadata reconciliation, delete through Details, and verify Viewer closes exactly once.
- [x] 5.4 Update the Tier-3 capture, page-table creation, import, search, edit, and share journeys so every resulting/selected document reaches `viewer_screen` before any Detail screen and no flow depends on `document_open_button`.
- [x] 5.5 Run all changed Tier-3 flows on an Android emulator/device or usable iOS Simulator and fix navigation, semantics, or persistence failures; do not treat a skipped device run as passing.

## 6. Previews, Goldens, Documentation, and Compatibility

- [x] 6.1 Update deterministic `@Preview()` entries for Viewer loading/locked/error/non-favourite/favourite/working/failure/unavailable/long-title and Detail loading/error/ready/long-title/protected/cloud states across phone/tablet, light/dark, empty-where-valid, and supported large-text variants; remove obsolete Detail page-strip/no-thumbnail previews.
- [x] 6.2 Update major-screen golden fixtures and golden tests for Viewer favourite states/overflow and lean Detail on phone/tablet in light/dark themes; review and accept only intentional visual changes.
- [x] 6.3 Update dartdoc for every changed public class, constructor, function, use case, Cubit method, state field, repository contract, key, and widget, plus intent-focused inline comments for metadata-only refresh, stable PDF surface identity, and cache pruning.
- [x] 6.4 Run layering and compatibility audits proving no feature-to-feature import, no Isar/Freezed/json serialization or stored-key migration, no new package, unchanged secure-password behavior, typed routes only, and Android/iOS-only platform scope.

## 7. Verification

- [x] 7.1 Run `dart format --set-exit-if-changed`, `flutter analyze`, the layering/platform checks, all Tier-1 and Tier-2 tests, updated goldens, and coverage verification; fix every failure and keep overall coverage at least 80% and business-logic coverage at least 90%.
- [x] 7.2 Run `openspec validate streamline-document-viewing` and resolve every artifact/spec validation issue, including conflicts with the completed page-preview change.
- [x] 7.3 Run `tool/verify.dart` and report its per-stage result. The change is not done while any stage fails, and a run that reports Tier 3 as SKIPPED (no Android emulator/device or usable iOS Simulator available) does not count as verified. Physical iOS device runs are not required.
