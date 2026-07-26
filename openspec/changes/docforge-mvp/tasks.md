Tasks are phased by capability. Each group is independently complete — implementation, tests, previews and documentation — and independently mergeable. **Groups 1–9 form the shippable vertical slice** (foundation, core, onboarding, library, app shell, scanning, enhancement, OCR, PDF generation): after group 9 a user can scan, get a searchable PDF, save it and see it on Home.

Every group ends with its own format / analyze / coverage gate, so no group can be marked done while the build is red.

## 1. Foundation and blocking decisions

- [x] 1.1 Resolve open question 2: verify `isar` ^3.1.0+1 + `isar_flutter_libs` + `isar_generator` build against Dart SDK ^3.12.2 on Android and iOS; if not, evaluate the community fork, and escalate the Drift + SQLite FTS5 alternative if neither builds. Record the decision in `design.md`.
- [x] 1.2 Resolve open question 1: decide the PDF-manipulation library, record the licence terms in `design.md`. Blocking for group 14 only.
- [x] 1.3 Add all non-blocked dependencies to `pubspec.yaml` (flutter_bloc, equatable, go_router, go_router_builder, freezed, json_serializable, build_runner, shared_preferences, flutter_secure_storage, dio, camera, google_mlkit_text_recognition, image, pdf, printing, pdfrx, permission_handler, local_auth, image_picker, file_picker, receive_sharing_intent, share_plus, path_provider, intl, bloc_concurrency) plus dev dependencies (bloc_test, mocktail, integration_test, golden toolkit). Verify `flutter pub get` succeeds on both platforms.
- [x] 1.4 Confirm no web or desktop platform folders, dependencies or build configuration exist anywhere in the repo; add a CI assertion that fails if any appear.
- [x] 1.5 Delete the default counter app from `lib/main.dart` and delete `test/widget_test.dart`.
- [x] 1.6 Create the `lib/features/`, `lib/core/` and `lib/app/` folder skeleton with the four-layer structure from `design.md` §1.
- [x] 1.7 Write `tool/check_layering.dart`: fail on any `domain/` import of `package:flutter`, any `application/` import of `infrastructure/`, and any cross-feature import.
- [x] 1.8 Write unit tests for `tool/check_layering.dart` covering each violation type and the passing case.
- [x] 1.9 Configure `analysis_options.yaml` beyond `flutter_lints`: require dartdoc on public members, enable `prefer_const_constructors` and immutability lints.
- [x] 1.10 Set up the CI workflow: `flutter pub get` → `dart format --set-exit-if-changed` → `flutter analyze` → layering check → `flutter test` → integration tests → golden tests → coverage, failing below 80% overall and 90% for `application/` + `domain/`. Android and iOS matrix only.

## 2. Core shared layer

- [x] 2.1 Implement the `Failure` base type and the shared Freezed failure union in `lib/core/failures/` (`CameraFailure`, `PermissionFailure`, `OcrFailure`, `PdfFailure`, `StorageFullFailure`, `ImportFailure`, `ExportFailure`, `AuthFailure`, `NotFoundFailure`, `CorruptFileFailure`) and the `Result<T, Failure>` union.
- [x] 2.2 Unit-test the failure union and `Result`, including exhaustive mapping of every variant to a user-facing message.
- [x] 2.3 Implement injected `Clock` and `IdGenerator` interfaces with production (`DateTime.now()`, UUID v4) and fixed test implementations (`design.md` §16).
- [x] 2.4 Unit-test `Clock` and `IdGenerator` fixed implementations for determinism.
- [x] 2.5 Implement `lib/core/storage/storage_keys.dart` with every `settings.*`, `app.*` and `secure.*` key as a documented constant.
- [x] 2.6 Implement the Isar bootstrap, `SharedPreferences` and `flutter_secure_storage` wrappers in `lib/core/storage/`, each behind an interface.
- [x] 2.7 Write repository-level tests for the storage wrappers against a temp-directory Isar instance and in-memory fakes.
- [x] 2.8 Implement the cross-feature contracts in `lib/core/contracts/` (`DocumentReader`, `DocumentWriter`, `PageBundleSink`, `OcrTextSource`, `FolderReader`, `StorageSummaryReader`, `AppLockGate`) and their Freezed value objects (`DocumentId`, `PageRef`, `ScannedPageBundle`, `RecognisedText`).
- [x] 2.9 Write serialization round-trip tests for every core contract value object.
- [x] 2.10 Implement `lib/core/isolates/` — one-shot `Isolate.run` wrapper and the progress-reporting worker with a cooperative `CancellationToken` (`design.md` §7).
- [x] 2.11 Unit-test the isolate helpers: progress emission, cooperative cancellation, and that cancellation leaves completed work intact and removes partial output.
- [x] 2.12 Implement the bounded LRU thumbnail cache with count and byte limits; unit-test eviction behaviour.
- [x] 2.13 Implement the Material 3 light and dark themes in `lib/core/theme/`, including high-contrast handling and text-scaling behaviour.
- [x] 2.14 Implement the shared widgets in `lib/core/widgets/`: `AppEmptyState`, `AppErrorView` (with retry), `AppLoadingIndicator`, `AppProgressIndicator`, each with keys and semantics labels.
- [x] 2.15 Widget-test the shared widgets, including the retry callback and semantics labels.
- [x] 2.16 Add `@Preview()` entries for every shared widget: default, loading, empty, error and long-content.
- [x] 2.17 Implement `lib/core/previews/fixtures/` (`sampleDocument`, `sampleDocuments(n)`, `sampleFolder`, `samplePage`, `sampleRecognisedText`, `longTitleDocument`, `sampleStorageSummary`) with fixed timestamps and no randomness.
- [x] 2.18 Implement `lib/core/previews/fakes/` — fake Cubit base helpers that emit fixed states without touching any repository.
- [x] 2.19 Implement `lib/core/permissions/` permission abstraction with granted / denied / permanently-denied states and an open-settings action; unit-test each state.
- [x] 2.20 Implement `lib/app/composition_root.dart` and the immutable `AppDependencies` `InheritedWidget` (`design.md` §5).
- [x] 2.21 Test that `AppDependencies` can be fully overridden with fakes in a widget test.
- [x] 2.22 Implement the GoRouter typed route table in `lib/app/router/app_router.dart` with all routes from `design.md` §8 and both redirect gates, lock gate ordered before onboarding gate.
- [x] 2.23 Write navigation tests for every route, both redirect gates, the gate ordering, and the unknown-document not-found path.
- [x] 2.24 Add dartdoc to every public API in `lib/core/` and `lib/app/`, and inline comments at the isolate boundary, cache bounds and router redirect ordering.
- [x] 2.25 Run `dart format`, `flutter analyze`, the layering check and coverage for groups 1–2; resolve all findings.

## 3. Onboarding

- [x] 3.1 Implement the `onboarding` domain and application layers: onboarding-completed flag repository interface, `CompleteOnboarding` and `IsOnboardingComplete` use cases.
- [x] 3.2 Unit-test the onboarding use cases.
- [x] 3.3 Implement the SharedPreferences-backed onboarding repository; write repository tests.
- [x] 3.4 Implement `OnboardingCubit` and `OnboardingState` (Equatable, all fields in `props`) with the welcome → privacy → permission → finished transitions.
- [x] 3.5 Write `bloc_test` coverage for `OnboardingCubit`: full state sequence including permission granted, denied and skipped.
- [x] 3.6 Implement the Welcome, Privacy & Offline Introduction and Camera Permission screens with the keys from `specs/onboarding/spec.md`.
- [x] 3.7 Widget-test all three onboarding screens, asserting through the specified keys.
- [x] 3.8 Wire the onboarding gate so first launch routes to onboarding and returning launches route to Home; write navigation tests for both branches, including after an app update.
- [x] 3.9 Add `@Preview()` entries for each onboarding screen: default, loading, empty, error, long content, plus phone, tablet, light and dark.
- [x] 3.10 Verify accessibility: semantics labels on every control, 48dp touch targets, maximum text scale without overflow, high contrast. Add tests.
- [x] 3.11 Add dartdoc to all new public APIs in the onboarding feature.
- [x] 3.12 Run `dart format`, `flutter analyze`, the layering check and coverage for group 3.

## 4. Document library and folders

- [x] 4.1 Implement the `document-library` domain layer: `Document`, `Folder`, `Page`, `StorageSummary` entities and the `DocumentRepository`, `FolderRepository`, `PageRepository` interfaces.
- [x] 4.2 Unit-test the domain business rules: a document must retain at least one page, duplicate folder names are rejected, archived documents are excluded from recents and lists.
- [x] 4.3 Implement the Isar collections (`DocumentEntity`, `PageEntity`, `FolderEntity`) with UUID ids, `createdAt`/`updatedAt`, `schemaVersion` and the indexes from `design.md` §6.
- [x] 4.4 Implement DTOs and mappers between Isar collections and domain entities; write serialization round-trip tests for each.
- [x] 4.5 Implement the file store for `<appDocuments>/documents/<documentId>/` with the on-disk layout version marker.
- [x] 4.6 Implement the repositories; write repository tests against a temp-directory Isar instance, including offline behaviour.
- [x] 4.7 Implement the lifecycle use cases: `SaveDocument`, `RenameDocument`, `MoveDocument`, `DuplicateDocument`, `ArchiveDocument`, `RestoreDocument`, `DeleteDocument`, `PurgeDocument`.
- [x] 4.8 Unit-test every lifecycle use case, including empty-name rejection and that permanent removal deletes the record, PDF, page images and OCR text.
- [x] 4.9 Implement the folder use cases: `CreateFolder`, `RenameFolder`, `DeleteFolder` (with the move-or-delete choice), and per-folder document counts.
- [x] 4.10 Unit-test the folder use cases, including that deleting a folder never silently loses documents.
- [x] 4.11 Implement `ComputeStorageSummary` and unit-test it against known fixtures.
- [x] 4.12 Implement `DocumentListCubit`, `DocumentDetailCubit` and `FolderCubit` with their Equatable states and named factory constructors.
- [x] 4.13 Write `bloc_test` coverage for all three Cubits: loading, ready, empty, failure, pagination and each lifecycle action.
- [x] 4.14 Implement the document list, document detail, folder list and folder detail screens with the keys from `specs/document-library/spec.md`.
- [x] 4.15 Implement the reusable `DocumentCard`, `FolderTile` and `PageThumbnail` widgets with keys and semantics labels.
- [x] 4.16 Widget-test all library screens and reusable widgets, including confirmation dialogs for destructive actions.
- [x] 4.17 Add `@Preview()` entries for every library widget (default, loading, empty, error, long content) and every library screen (plus phone, tablet, light, dark).
- [x] 4.18 Implement lazy/paginated loading and verify list performance with a fixture library of several thousand documents.
- [x] 4.19 Implement `DocumentReader`, `DocumentWriter`, `FolderReader` and `StorageSummaryReader` contract implementations; test them against the contract.
- [x] 4.20 Add navigation tests for the library routes and the document detail route parameter.
- [x] 4.21 Add dartdoc to all new public APIs and inline comments on the Isar schema and index choices and their migration implications.
- [x] 4.22 Run `dart format`, `flutter analyze`, the layering check and coverage for group 4.

## 5. App shell and Home

- [x] 5.1 Implement the `app-shell` application layer: `LoadHomeData` use case composing recents, folders, favourites, archive and storage summary through core contracts.
- [x] 5.2 Unit-test `LoadHomeData`, including ordering by modified date descending and exclusion of archived documents.
- [x] 5.3 Implement `HomeCubit` and `HomeState` with initial / loading / ready / empty / failure factories.
- [x] 5.4 Write `bloc_test` coverage for `HomeCubit` including the retry-after-failure path.
- [x] 5.5 Implement the Home screen with every key from `specs/app-shell/spec.md`.
- [x] 5.6 Implement the `StorageSummaryCard`, `RecentDocumentsSection` and `HomeShortcut` widgets with keys and semantics labels.
- [x] 5.7 Widget-test the Home screen and its widgets, including the empty state and its call to action.
- [x] 5.8 Implement the responsive Home layout (multi-column grid on tablet) and verify state preservation across orientation change.
- [x] 5.9 Add `@Preview()` entries for every Home widget and the Home screen across all required states, form factors and themes.
- [x] 5.10 Wire theme mode through the app so a system or explicit theme change re-renders without restart; test both paths.
- [x] 5.11 Verify the accessibility baseline on Home: semantics labels, 48dp targets, maximum text scale, high contrast. Add tests.
- [x] 5.12 Add golden tests for Home in light and dark, phone and tablet.
- [x] 5.13 Add dartdoc to all new public APIs in the app-shell feature.
- [x] 5.14 Run `dart format`, `flutter analyze`, the layering check and coverage for group 5.

## 6. Document scanning

- [ ] 6.1 Implement the `document-scanning` domain layer: `ScanSession`, `PageQuad` value objects and the `ScannerRepository` and `EdgeDetector` interfaces.
- [ ] 6.2 Implement the camera-backed `ScannerRepository` and a fake implementation for tests and previews.
- [ ] 6.3 Write repository tests for `ScannerRepository` against the fake, including camera-unavailable and permission-denied failures.
- [ ] 6.4 Implement `CapturePage` and the disk-first page persistence rule (write immediately, keep only thumbnails in memory); unit-test both.
- [ ] 6.5 Implement `ApplyPerspectiveCorrection` running in a background isolate with progress and cancellation; unit-test the transform maths against known fixtures.
- [ ] 6.6 Implement the phase-3a `EdgeDetector` fallback returning the full page quad; unit-test it.
- [ ] 6.7 Implement `ScanCaptureCubit`, `PageReviewCubit` and `CropCubit` with their Equatable states.
- [ ] 6.8 Write `bloc_test` coverage for all three Cubits, including batch mode, permission denied, camera unavailable, storage full and deleting the last page.
- [ ] 6.9 Implement the camera capture screen with live preview, shutter, batch-mode toggle and page counter, using the specified keys.
- [ ] 6.10 Implement the page review screen with rotate, drag-to-reorder, delete with undo, and the empty state.
- [ ] 6.11 Implement the crop screen with the edge overlay and draggable corner handles.
- [ ] 6.12 Widget-test all three scanning screens against the fake `ScannerRepository`.
- [ ] 6.13 Verify the camera is released on every exit path from the capture screen; add a test.
- [ ] 6.14 Implement the permission-denied and camera-error views with their recovery actions; widget-test both.
- [ ] 6.15 Add `@Preview()` entries for every scanning widget and screen across all required states, form factors and themes, fed only by fixtures.
- [ ] 6.16 Verify scanning accessibility: semantics labels on shutter, batch toggle, flash and page counter; 48dp targets. Add tests.
- [ ] 6.17 Add golden tests for the page review and crop screens in light and dark, phone and tablet.
- [ ] 6.18 Add dartdoc to all new public APIs and inline comments on the perspective-transform maths and the isolate boundary.
- [ ] 6.19 Run `dart format`, `flutter analyze`, the layering check and coverage for group 6.
- [ ] 6.20 Phase 3b — resolve open question 3, implement automatic edge detection behind `EdgeDetector`, and unit-test it against real-capture fixtures including the not-detected fallback.

## 7. Image enhancement

- [ ] 7.1 Implement the `EnhancementSettings` value object and the enhancement domain rules.
- [ ] 7.2 Implement the filter algorithms (Original, Auto Enhance, Magic Colour, Black & White, Grayscale) as pure functions; unit-test each against fixture images.
- [ ] 7.3 Implement brightness, contrast, sharpen and shadow removal as pure functions; unit-test each, including combination with a filter.
- [ ] 7.4 Implement `ApplyEnhancement` running in a background isolate with progress and cancellation, using downscaled previews and full-resolution saves.
- [ ] 7.5 Unit-test `ApplyEnhancement`, including that cancellation leaves processed pages intact.
- [ ] 7.6 Implement `EnhancementCubit` and `EnhancementState`.
- [ ] 7.7 Write `bloc_test` coverage for `EnhancementCubit`: filter selection, adjustments, reset, apply-to-all, progress, cancellation and failure.
- [ ] 7.8 Implement the enhancement screen with all filter and adjustment controls using the specified keys.
- [ ] 7.9 Implement the `FilterChip` and `AdjustmentSlider` widgets with keys and semantics labels exposing current values.
- [ ] 7.10 Widget-test the enhancement screen and its widgets, including that leaving without saving does not modify the stored page.
- [ ] 7.11 Add `@Preview()` entries for every enhancement widget and the enhancement screen across all required states, form factors and themes.
- [ ] 7.12 Verify the preview stays responsive at full-resolution page sizes; add a performance test asserting the downscaled preview path.
- [ ] 7.13 Verify enhancement accessibility, including that sliders announce their values.
- [ ] 7.14 Add golden tests for the enhancement screen in light and dark, phone and tablet.
- [ ] 7.15 Add dartdoc to all new public APIs and inline comments on the enhancement maths.
- [ ] 7.16 Run `dart format`, `flutter analyze`, the layering check and coverage for group 7.

## 8. OCR

- [ ] 8.1 Implement the `ocr` domain layer: `RecognisedText`, text-block and bounding-box value objects, and the `OcrRepository` interface.
- [ ] 8.2 Implement the on-device `OcrRepository` and a fake implementation returning fixture text with bounding boxes.
- [ ] 8.3 Write repository tests against the fake, including the no-recognisable-text and failure paths.
- [ ] 8.4 Implement the `OcrTextEntity` Isar collection with the word index; write repository and serialization tests.
- [ ] 8.5 Implement `RecogniseText` running in a background isolate with per-page progress and cancellation; unit-test it, including that results are persisted and never recomputed.
- [ ] 8.6 Implement `OcrCubit` and `OcrState`.
- [ ] 8.7 Write `bloc_test` coverage for `OcrCubit`: running with progress, ready, empty, failure, cancelled and re-run.
- [ ] 8.8 Implement the extracted-text view with copy, export and re-run controls using the specified keys.
- [ ] 8.9 Widget-test the extracted-text view, including copy-to-clipboard confirmation and the long-text scrolling case.
- [ ] 8.10 Implement `OcrTextSource` contract implementation for search and sharing; test against the contract.
- [ ] 8.11 Add `@Preview()` entries for the extracted-text view and its widgets across all required states, form factors and themes.
- [ ] 8.12 Verify OCR accessibility: text exposed as readable content, controls labelled.
- [ ] 8.13 Verify OCR runs with no network connection; add a test asserting no network call is made.
- [ ] 8.14 Add dartdoc to all new public APIs and inline comments on bounding-box handling.
- [ ] 8.15 Run `dart format`, `flutter analyze`, the layering check and coverage for group 8.

## 9. PDF generation

- [ ] 9.1 Implement the `pdf-generation` domain layer and the `PdfRepository` interface (composition methods only at this stage).
- [ ] 9.2 Implement PDF composition from page images preserving order, rotation and enhancement; write repository tests asserting page count and order.
- [ ] 9.3 Implement the invisible OCR text-layer placement using bounding boxes; write a test asserting the generated PDF's text is selectable and positioned over the correct region.
- [ ] 9.4 Implement `BuildSearchablePdf` running in a background isolate with progress and cancellation; unit-test it, including that a PDF is still produced when OCR is unavailable.
- [ ] 9.5 Implement the default file-naming pattern expansion as a use case; unit-test it against each supported pattern.
- [ ] 9.6 Implement `SaveDocument` end to end (write PDF, create record, compute size) and unit-test it.
- [ ] 9.7 Verify cancellation and failure leave no partial document record and no orphaned file; add tests for both, plus the storage-full path.
- [ ] 9.8 Implement `PdfGenerationCubit` and `PdfGenerationState`.
- [ ] 9.9 Write `bloc_test` coverage for `PdfGenerationCubit`: generating with progress, saved, failure, cancelled.
- [ ] 9.10 Implement the document preview and save screen with the name field and save control using the specified keys.
- [ ] 9.11 Widget-test the preview screen, including that navigating back preserves the session and writes no PDF.
- [ ] 9.12 Implement the `PageBundleSink` contract implementation consumed by scanning and import; test against the contract.
- [ ] 9.13 Verify the saved document appears at the top of Recent on Home; add a test.
- [ ] 9.14 Add `@Preview()` entries for the preview screen and its widgets across all required states, form factors and themes.
- [ ] 9.15 Verify PDF-generation accessibility and quality-setting application (lowest quality yields a smaller file than highest).
- [ ] 9.16 Add golden tests for the document preview screen in light and dark, phone and tablet.
- [ ] 9.17 Add dartdoc to all new public APIs and inline comments on the text-layer positioning.
- [ ] 9.18 Run `dart format`, `flutter analyze`, the layering check and coverage for group 9.
- [ ] 9.19 Write the vertical-slice integration test: scan → review → crop → enhance → OCR → generate → save → appears in Recent, with camera and OCR faked at the repository boundary.

## 10. Document viewer

- [ ] 10.1 Implement the `document-viewer` domain layer and the PDF rendering repository interface.
- [ ] 10.2 Implement on-demand page rendering; write repository tests including the corrupt-file and missing-file failures.
- [ ] 10.3 Implement `ViewerCubit` and `ViewerState` including the locked (password-required) variant.
- [ ] 10.4 Write `bloc_test` coverage for `ViewerCubit`: loading, ready, locked, correct and incorrect password, failure.
- [ ] 10.5 Implement the viewer screen with continuous scroll, zoom, page indicator and jump-to-page using the specified keys.
- [ ] 10.6 Implement the share, print and edit entry points from the viewer.
- [ ] 10.7 Widget-test the viewer, including out-of-range page numbers, double-tap zoom reset and the password prompt not rendering content until authenticated.
- [ ] 10.8 Verify large-document performance: on-demand rendering, bounded memory, smooth scrolling. Add a performance test.
- [ ] 10.9 Add `@Preview()` entries for the viewer and its widgets across all required states, form factors and themes, fed by a fixture PDF.
- [ ] 10.10 Implement the tablet viewer layout and verify it uses the additional width.
- [ ] 10.11 Verify viewer accessibility: page indicator announcement, labelled action controls.
- [ ] 10.12 Add golden tests for the viewer in light and dark, phone and tablet.
- [ ] 10.13 Add dartdoc to all new public APIs in the viewer feature.
- [ ] 10.14 Run `dart format`, `flutter analyze`, the layering check and coverage for group 10.

## 11. Search

- [ ] 11.1 Implement the `document-search` domain layer: query, filter and result value objects including the match snippet and its source.
- [ ] 11.2 Implement `SearchDocuments` using indexed Isar queries over the title index and the `OcrTextEntity` word index, merging by document id.
- [ ] 11.3 Unit-test `SearchDocuments`: title match, OCR-text match, case insensitivity, snippet generation, archived exclusion.
- [ ] 11.4 Implement folder, creation-date and modified-date filters as indexed query clauses; unit-test each and their combination.
- [ ] 11.5 Implement `SearchBloc` with the debounced `restartable()` event transformer, per the justification in `design.md` §3.
- [ ] 11.6 Write `bloc_test` coverage for `SearchBloc`: incremental results, debounce collapsing rapid input, superseded-query cancellation, clear, empty, failure.
- [ ] 11.7 Implement the search screen with the input field, clear control, filters and results list using the specified keys.
- [ ] 11.8 Implement the `SearchResultRow` widget showing the match snippet, with keys and semantics labels.
- [ ] 11.9 Widget-test the search screen and result row, including the initial, empty and error states.
- [ ] 11.10 Verify search performance against a fixture library of several thousand documents with OCR text; assert the UI thread is not blocked.
- [ ] 11.11 Add `@Preview()` entries for the search screen and its widgets across all required states, form factors and themes.
- [ ] 11.12 Verify search accessibility, including that the result count is announced when results change.
- [ ] 11.13 Add golden tests for the search screen in light and dark, phone and tablet.
- [ ] 11.14 Add dartdoc to all new public APIs and inline comments on the index choices behind search.
- [ ] 11.15 Run `dart format`, `flutter analyze`, the layering check and coverage for group 11.

## 12. Sharing, printing and export

- [ ] 12.1 Implement the `document-sharing` domain layer and the `ShareRepository` interface.
- [ ] 12.2 Implement `ShareDocument`, `PrintDocument` and `ExportDocument` use cases with isolate-backed preparation, progress and cancellation.
- [ ] 12.3 Unit-test all three use cases, including that a protected document retains protection and the password is never included.
- [ ] 12.4 Implement page-image and extracted-text sharing; unit-test page ordering and the no-recognised-text path.
- [ ] 12.5 Implement `ShareCubit` and `ShareState`; write `bloc_test` coverage including preparing, ready, failure and cancellation.
- [ ] 12.6 Implement the share options UI with the specified keys and semantics labels naming what will be shared and in what format.
- [ ] 12.7 Widget-test the share options, the cancelled-picker path and the disabled share-text control.
- [ ] 12.8 Implement error handling for export failure, storage full, no receiving application and print failure; widget-test each, asserting no partial file remains.
- [ ] 12.9 Add `@Preview()` entries for the share options and progress widgets across all required states, form factors and themes.
- [ ] 12.10 Verify no network request is made while preparing content to share; add a test.
- [ ] 12.11 Add dartdoc to all new public APIs in the sharing feature.
- [ ] 12.12 Run `dart format`, `flutter analyze`, the layering check and coverage for group 12.

## 13. Import

- [ ] 13.1 Implement the `document-import` domain layer and the `ImportRepository` interface.
- [ ] 13.2 Implement `ImportFromGallery`, `ImportFromFiles` and `HandleSharedFiles` with isolate-backed processing, progress and cancellation.
- [ ] 13.3 Unit-test the import use cases, including selection order preservation and correct page count and file size for imported PDFs.
- [ ] 13.4 Implement import validation: unsupported type, corrupt file, password-protected PDF; unit-test each, asserting no partial document is created.
- [ ] 13.5 Implement share-sheet registration on Android and iOS and handle both cold-launch and already-running imports; write integration tests for both.
- [ ] 13.6 Implement `ImportCubit` and `ImportState`; write `bloc_test` coverage including permission denied, cancellation and the multiple-files case.
- [ ] 13.7 Implement the import options sheet, permission-denied view and error view with the specified keys.
- [ ] 13.8 Widget-test the import screens, including the cancelled-picker and storage-full paths.
- [ ] 13.9 Wire imported images into the scanning review step so cropping and enhancement can be applied; add a test.
- [ ] 13.10 Add `@Preview()` entries for the import widgets and screens across all required states, form factors and themes.
- [ ] 13.11 Verify import accessibility and that photo/file permissions are requested just in time, not before.
- [ ] 13.12 Add dartdoc to all new public APIs in the import feature.
- [ ] 13.13 Run `dart format`, `flutter analyze`, the layering check and coverage for group 13.

## 14. PDF editing

- [ ] 14.1 Extend `PdfRepository` with the manipulation methods and implement the atomic write-verify-replace sequence from `design.md` §12.
- [ ] 14.2 Write repository tests proving that a failure at any point leaves the source document unchanged and removes the temporary file.
- [ ] 14.3 Implement `RotatePage`, `DeletePage`, `ExtractPages` and `DuplicatePage`; unit-test each, including the refusal to delete the last remaining page.
- [ ] 14.4 Implement `MergePdfs` with user-controlled ordering; unit-test ordering and that sources are unchanged.
- [ ] 14.5 Implement `SplitPdf`; unit-test that combined output equals the original in order.
- [ ] 14.6 Implement `CompressPdf` reporting the size change; unit-test the no-benefit path.
- [ ] 14.7 Implement `WatermarkPdf`; unit-test that the watermark appears on every page.
- [ ] 14.8 Implement `ProtectPdf` and `RemovePdfPassword` with passwords in secure storage only; unit-test the incorrect-password path and assert no password is written to preferences, the database or logs.
- [ ] 14.9 Implement `ReadPdfMetadata`; unit-test the returned fields.
- [ ] 14.10 Implement `PdfEditCubit` and `PdfEditState`; write `bloc_test` coverage for every operation plus progress, failure and cancellation.
- [ ] 14.11 Implement the PDF editor screen, page selection, merge ordering list, watermark and password UIs with the specified keys.
- [ ] 14.12 Widget-test the editing screens, including the disabled merge control with fewer than two documents and the watermark preview.
- [ ] 14.13 Implement error handling for corrupt PDFs and storage-full during an edit; widget-test both.
- [ ] 14.14 Add `@Preview()` entries for every editing widget and screen across all required states, form factors and themes.
- [ ] 14.15 Verify editing accessibility: labelled controls, page thumbnails announcing page number and selection state.
- [ ] 14.16 Add golden tests for the PDF editor in light and dark, phone and tablet.
- [ ] 14.17 Add dartdoc to all new public APIs and inline comments on the atomic write-verify-replace sequence.
- [ ] 14.18 Run `dart format`, `flutter analyze`, the layering check and coverage for group 14.

## 15. Settings

- [ ] 15.1 Implement the `app-settings` domain layer and the `SettingsRepository` interface with documented defaults for every setting.
- [ ] 15.2 Implement the SharedPreferences-backed settings repository; write repository tests including the write-failure path.
- [ ] 15.3 Implement `LoadSettings` and `UpdateSetting`; unit-test persistence, immediate effect and default values.
- [ ] 15.4 Implement the naming-pattern preview and the quality trade-off descriptions; unit-test pattern expansion.
- [ ] 15.5 Implement `SettingsCubit` and `SettingsState`; write `bloc_test` coverage including the write-failure path retaining the previous value.
- [ ] 15.6 Implement the settings screen with every entry key from `specs/app-settings/spec.md`, each showing its current value.
- [ ] 15.7 Implement the About and Privacy Policy screens with the local-only storage statement.
- [ ] 15.8 Implement the storage information view backed by `StorageSummaryReader`; test that it updates after permanent removal.
- [ ] 15.9 Widget-test all settings screens, including that changing the theme re-renders immediately without a restart.
- [ ] 15.10 Verify that changing the OCR language does not alter previously recognised text; add a test.
- [ ] 15.11 Add `@Preview()` entries for every settings widget and screen across all required states, form factors and themes.
- [ ] 15.12 Verify settings accessibility: each entry announces its name and current value.
- [ ] 15.13 Add golden tests for the settings screen in light and dark, phone and tablet.
- [ ] 15.14 Add dartdoc to all new public APIs in the settings feature.
- [ ] 15.15 Run `dart format`, `flutter analyze`, the layering check and coverage for group 15.

## 16. Security and app lock

- [ ] 16.1 Implement the `app-security` domain layer, the `AppLockRepository` interface and the `SecureStorageRepository` interface.
- [ ] 16.2 Implement the secure-storage-backed repositories; write repository tests including the storage-unavailable failure.
- [ ] 16.3 Implement `AuthenticateAppLock` with biometric and device-credential fallback; unit-test success, rejection, error and not-enrolled paths.
- [ ] 16.4 Implement `AppLockCubit` and `AppLockState`; write `bloc_test` coverage for unknown → locked → authenticating → unlocked and every failure path.
- [ ] 16.5 Implement the `AppLockGate` contract implementation and wire it into the router ahead of the onboarding gate.
- [ ] 16.6 Write navigation tests proving no document title, thumbnail or content renders before authentication, on launch and on resume from background.
- [ ] 16.7 Implement the unlock screen with the specified keys and its retry control.
- [ ] 16.8 Widget-test the unlock screen, including that failed authentication keeps the app locked.
- [ ] 16.9 Implement enabling and disabling the lock from settings, requiring authentication to confirm; widget-test both.
- [ ] 16.10 Implement deletion of a document's stored password on permanent removal; add a test.
- [ ] 16.11 Add a test asserting that no document content, page image or OCR text is transmitted off the device by any flow, and that all writes go to app-private storage.
- [ ] 16.12 Add a test asserting no secret is ever written to preferences, the database or logs.
- [ ] 16.13 Add `@Preview()` entries for the unlock screen and its widgets across all required states, form factors and themes.
- [ ] 16.14 Verify security-screen accessibility and add golden tests for the unlock screen in light and dark, phone and tablet.
- [ ] 16.15 Add dartdoc to all new public APIs in the security feature.
- [ ] 16.16 Run `dart format`, `flutter analyze`, the layering check and coverage for group 16.

## 17. Finalisation

- [ ] 17.1 Write the success-criteria integration test end to end in airplane mode: install → scan → searchable PDF → saved locally → found from Home → organised into a folder → searched → edited → shared, with no account.
- [ ] 17.2 Write integration tests for the import, PDF-edit and app-lock flows end to end.
- [ ] 17.3 Audit every screen against the accessibility requirements: screen reader, maximum text scale, high contrast, 48dp targets. Fix and test all findings.
- [ ] 17.4 Audit `@Preview()` coverage: every reusable widget has default, loading, empty, error and long-content previews; every screen additionally has phone, tablet, light and dark. Fix any gaps.
- [ ] 17.5 Verify every preview renders from fixtures alone — no live service, network, real database or randomness. Fix any that do not.
- [ ] 17.6 Audit golden-test coverage for every major screen (Home, Page Review, Crop, Enhancement, PDF Preview, Document List, Folder, Search, Viewer, PDF Editor, Settings, Unlock) in light and dark, phone and tablet.
- [ ] 17.7 Audit dartdoc coverage on every public class, function, method, constructor and top-level constant; fix gaps and remove any stale documentation.
- [ ] 17.8 Audit inline comments at every location listed in `design.md` §17; add what is missing and delete noise comments.
- [ ] 17.9 Verify no Cubit contains business logic — every Cubit method is emit / await use case / emit. Fix any violations.
- [ ] 17.10 Verify no hidden state, static mutable state or global mutable variables exist outside the documented `AppDependencies` exception.
- [ ] 17.11 Run the full performance verification: cold start under 2s, document open under 1s, smooth scrolling with 1,000+ documents, bounded memory on a large batch scan.
- [ ] 17.12 Verify every error-handling scenario in the specs shows a clear message with a working recovery action.
- [ ] 17.13 Run `dart format --set-exit-if-changed`, `flutter analyze`, the layering check and the full test suite; confirm coverage ≥80% overall and ≥90% for `application/` and `domain/`.
- [ ] 17.14 Manually verify on a physical Android device and a physical iPhone; confirm no web or desktop artefacts exist anywhere in the repo.
