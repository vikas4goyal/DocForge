## 1. Thumbnail application and infrastructure

- [x] 1.1 Add the constructor-injected thumbnail cache port, `LoadDocumentPageThumbnail` use case, and pdfrx single-page renderer with dartdoc/resource-release comments; add Tier-1 tests for cache hits, password forwarding, failures, and release
- [x] 1.2 Construct and expose thumbnail loading through `LibraryModule`, preserving existing permanent-delete cache cleanup; run the affected module/infrastructure tests

## 2. Detail presentation and navigation

- [x] 2.1 Make `PageThumbnail` lazily load a derived path with loading/success/placeholder states, retain registered keys and semantics, and add/update Tier-1 widget tests
- [x] 2.2 Inject the page loader and existing `AppRoutes.documentView` Open callback from production composition; add navigation tests for the same document identifier
- [x] 2.3 Update `@Preview()` entries/fixtures for populated, loading and fallback page previews in light/dark phone/tablet preview coverage and run preview smoke tests
- [x] 2.4 Add/update document-detail golden coverage for the materially changed ready screen and run the golden test

## 3. User-flow regression coverage

- [x] 3.1 Add a Tier-2 document-detail component test under `test/features/document_library/component/` using the real Cubit/use cases with fake repositories, covering Open and derived preview behavior
- [x] 3.2 Update the `browse_and_view` Tier-3 flow and library robot to drive `document_open_button`, observe `viewer_screen`, and return successfully for a saved PDF

## 4. Quality and completion

- [x] 4.1 Run `dart format`, `flutter analyze`, relevant architecture checks, and coverage verification; resolve every regression
- [x] 4.2 Validate and sync the OpenSpec delta specifications, then run `tool/verify.dart` and report every per-stage result; Tier 3 must run on an attached device and no stage may be skipped or fail
