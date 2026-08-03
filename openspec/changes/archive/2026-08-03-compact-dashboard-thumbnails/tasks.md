## 1. Lazy document thumbnail

- [x] 1.1 Add the documented `DocumentThumbnail` widget, registered loading/content keys and semantics, with memoized success/loading/fallback behavior; add focused Tier-1 widget tests and run them
- [x] 1.2 Extend `DocumentCard` through constructor injection to show the first-page thumbnail without adding a redundant accessibility focus stop; update its previews and focused tests

## 2. Compact scrolling dashboard

- [x] 2.1 Refactor `DashboardScreen` into one refreshable lazy vertical scroll surface, omit the root breadcrumb, preserve nested breadcrumbs, and compact the collection row; update Tier-1 dashboard tests
- [x] 2.2 Replace Recent chips with at most five compact thumbnail tiles in exactly one horizontal non-wrapping lane, register document-specific keys/semantics, and cover phone/tablet plus large-text layout
- [x] 2.3 Inject `LibraryModule.loadDocumentPageThumbnail.call` into production dashboard and other production document lists so visible rows use the existing secure cache pipeline; update composition/navigation tests

## 3. Required presentation and flow coverage

- [x] 3.1 Update deterministic `@Preview()` entries for document thumbnails/cards and dashboard ready/loading/empty/error/long-content states in light/dark phone/tablet coverage; run preview smoke tests
- [x] 3.2 Update the dashboard Tier-2 component test using the real `DashboardCubit` and repositories faked at their boundary, covering single-scroll layout, one Recent lane, thumbnail requests, and nested breadcrumb behavior
- [x] 3.3 Regenerate the materially changed dashboard phone/tablet light/dark goldens and run their focused suite
- [x] 3.4 Update the `browse_and_view` Tier-3 flow/robot to observe the dashboard document thumbnail before opening detail and viewer

## 4. Quality and completion

- [x] 4.1 Run formatting, Flutter/Dart analysis, layering/platform checks, all affected tests, and coverage verification; resolve every regression
- [x] 4.2 Validate and sync the OpenSpec delta, run `tool/verify.dart`, and report every per-stage result; Tier 3 must run on an attached device and no stage may be skipped or fail
