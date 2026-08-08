## 1. Shared Quality and Preference Foundations

- [x] 1.1 Add documented Freezed/json-serializable `PdfQualityPercent` and `PageQualityPlan` core values with 30–100 validation, dimension scaling, stable page overrides, effective-value lookup, and reset operations.
- [x] 1.2 Add Tier-1 unit/serialization tests for percentage bounds, rounding/no-upscale rules, page override precedence/removal/reset, value equality, and generated JSON round trips.
- [x] 1.3 Replace the persisted PDF preset contract with a versioned percentage default and implement backward-compatible `low -> 40`, `balanced -> 70`, `high -> 100`, and invalid/missing -> 70 reads.
- [x] 1.4 Add Tier-1 settings repository/use-case tests proving legacy migration, integer persistence, restart behavior, and that per-document/page overrides never update the default.
- [x] 1.5 Add documented Freezed/json-serializable camera tier, supported-resolution, and desired-resolution values, including the missing-preference “Full resolution” state.
- [x] 1.6 Add Tier-1 value/migration tests for resolution ordering, friendly tier plus exact-dimension labels, old image-quality mapping, full-resolution default, and deterministic fallback selection.

## 2. Camera Capability and Capture Resolution

- [x] 2.1 Add `CameraCapabilityRepository`, `LoadCameraResolutions`, and `ResolveCaptureResolution` contracts/use cases with explicit constructor injection and no dependency on Settings feature code.
- [x] 2.2 Implement the camera-plugin adapter that probes the active camera, maps only satisfiable resolution tiers, requests maximum when enumeration is unavailable, and verifies actual captured dimensions.
- [x] 2.3 Add Tier-1 repository/use-case tests for full-resolution default, exact supported choice, nearest-lower fallback, no-lower fallback to active-camera maximum, camera switch, unavailable probe, and offline behavior.
- [x] 2.4 Update Settings state/use cases/repository and composition-root wiring to expose and persist the desired camera resolution separately from the default PDF percentage.
- [x] 2.5 Add/update Settings keys and semantics for `settings_camera_resolution`, its typed screen, supported options, loading/fallback/error copy, and Retry; update every Settings robot that drives the moved/renamed controls.
- [x] 2.6 Build the adaptive camera-resolution Settings screen and migrate the old image-quality UI/copy without offering unsupported fixed tiers.
- [x] 2.7 Add `bloc_test` coverage for Settings resolution loading, selection, persistence failure, camera change fallback, Retry, and simultaneous preservation of the PDF default.
- [x] 2.8 Add Tier-2 Settings component tests with the real Cubit/use cases and repository-boundary capability/preference fakes for loading, supported, fallback, error, offline, and maximum-text states.
- [x] 2.9 Update camera capture initialization/add-page orchestration to resolve the selected active-camera size before each capture while leaving photo-library source dimensions unchanged.
- [x] 2.10 Add Tier-1 capture use-case/Cubit tests and repository tests proving chosen dimensions, full-resolution default, add-another-page re-resolution, plugin fallback verification, photo-library independence, and camera release.
- [x] 2.11 Add Tier-2 scanning component tests with real Cubit/use cases and camera-boundary fakes for full, lower-tier, fallback, camera-switch, error, and offline capture states.
- [x] 2.12 Add deterministic `@Preview()` entries and golden tests for the resolution Settings screen and changed capture status on phone/tablet, light/dark, loading/error/fallback, long dimensions, and maximum text scale.

## 3. Candidate Jobs and Exact Size Infrastructure

- [x] 3.1 Add documented Freezed candidate fingerprint/result and async job-view variants plus route-scoped job generation/cancellation contracts shared without feature-to-feature imports.
- [x] 3.2 Add Tier-1 tests for all job-state equality, progress bounds, deterministic generations, stale completion rejection, and candidate ownership/discard rules.
- [x] 3.3 Extend PDF-generation repository/application contracts to build, verify, promote, and discard exact temporary candidates with page progress and cooperative cancellation.
- [x] 3.4 Implement isolate-backed generated-PDF candidates using ordered effective per-page percentages, bounded memory, protection in the fingerprint, exact bytes, and at-most-one retained candidate.
- [x] 3.5 Add Tier-1 generation candidate/repository tests for exact bytes, page dimensions/order, protected/unprotected fingerprints, cancellation cleanup, failure cleanup, progress, and matching-candidate reuse.
- [x] 3.6 Extend PDF-editing repository/application contracts to build, verify, promote, and discard compression candidates with mixed per-page percentages and 100% pass-through pages.
- [x] 3.7 Implement bounded isolate-backed compression candidates, preserving page count/order, copying effective-100% pages when supported, and reporting exact original/result bytes and saving.
- [x] 3.8 Add Tier-1 compression candidate/repository tests for 30/50/80/100 and mixed plans, valid output/page count, exact size, no-benefit results, stale cancellation, temp cleanup, progress, and offline behavior.

## 4. Save PDF Domain and Application Workflow

- [x] 4.1 Add the route-scoped `PdfPasswordDraft` secret boundary with replace/read/clear behavior and update password validation so secret text never enters Equatable state, JSON, logs, fixtures, Isar, or preferences.
- [x] 4.2 Add Tier-1 tests proving password set/remove/route-dispose cleanup, mismatch rejection, candidate fingerprint changes, secure storage only after verified commit, and cleanup on cancel/failure.
- [x] 4.3 Implement `CalculateSavePdfSize`, `PrepareSavePdfPreview`, and `SaveGeneratedPdf` use cases with 350ms calculation debounce, immediate Save supersession, verified candidate promotion, collision handling, atomic commit, Isar record, secure credential, and session cleanup/rollback.
- [x] 4.4 Add Tier-1 use-case/repository tests for Save during calculation, exact candidate reuse/non-reuse, per-page plans, cancellation before commit, storage/encryption failure rollback, one-shot completion, and successful metadata/session cleanup.
- [x] 4.5 Add typed `SavePdfRoute` and `PdfTemporaryPreviewRoute` plus composition-root factories so document creation launches the flow without importing PDF-generation implementation code.
- [x] 4.6 Add Tier-1 typed-navigation tests for Save entry, preview open/close, successful folder return, cancelled job staying on Save, invalid handles, and exactly-once navigation.

## 5. Save PDF Presentation

- [x] 5.1 Add/update the PDF-generation and creation key/semantics registries for the Save screen, name, document quality, page rows/override dialog/reset, size status/Retry, password controls/dialog, Preview, Save, progress, cancel, temporary preview, and errors; update all affected robots in the same change.
- [x] 5.2 Implement `SavePdfCubit`/immutable State with name, document percentage, page overrides, password-enabled flag, independent calculation/preview/commit jobs, exact bytes, typed failures, and deterministic stale-job rejection.
- [x] 5.3 Add `bloc_test` Tier-1 coverage for load, name edits, debounced quality/page changes, override/reset precedence, calculation success/failure/retry, password flag, preview/cancel, Save-during-calculation, save cancel/retry, and one-shot success.
- [x] 5.4 Build the adaptive full-page Save PDF screen, lazy page-quality rows/dialog, password dialog/status/removal, non-blocking size status, Preview/Save actions, and cancellable percent progress dialog.
- [x] 5.5 Build the read-only temporary PDF preview surface with close/cancel cleanup and retained Save configuration, reusing the viewer renderer only through injected core contracts.
- [x] 5.6 Add Tier-2 Save component tests with the real Cubit/use cases and repository-boundary fakes for default/edit/override/reset/password/calculating/Preview/Save/cancel/failure/completion and Save-without-Preview paths.
- [x] 5.7 Add deterministic `@Preview()` entries for every new Save widget/dialog and the Save/temporary-preview screens in default/loading/empty/error/long-content, 30/70/100, override, protected, progress, phone/tablet, light/dark, and maximum-text states.
- [x] 5.8 Add/update golden tests for the materially changed Save screen and temporary preview across adaptive layouts, themes, long names, page overrides, password enabled, calculation/progress, failure, and maximum text scale.

## 6. Compress PDF Domain and Application Workflow

- [x] 6.1 Extend compression draft/request/result domain values with document percentage, immutable page-index overrides, effective-all-pages-100 detection, copy/overwrite destination, and original/result/saved byte summaries.
- [x] 6.2 Add Tier-1 tests for compression validation, override precedence/reset, mixed 100% plans, all-pages-100 warning eligibility, saving calculations, and result equality/serialization.
- [x] 6.3 Implement `CalculateCompressedSize`, `PrepareCompressionPreview`, and `SaveCompressedPdf` use cases with independent cancellation, immediate Save supersession, candidate reuse, no-benefit review, and one-shot results.
- [x] 6.4 Implement collision-safe copy commit and verified atomic overwrite/backup/Isar rollback paths while preserving the source on cancellation or failure.
- [x] 6.5 Add Tier-1 use-case/repository tests for copy naming/source preservation, overwrite success/rollback, metadata updates, 100% pass-through, mixed page plans, no-benefit continuation, cancellation cleanup, storage failure, and exactly-once commit.
- [x] 6.6 Add typed `CompressPdfRoute` entry from Viewer/editor and typed completion navigation for opening a copy or refreshing the original.
- [x] 6.7 Add Tier-1 navigation tests for direct Viewer entry, 100% warning branches, destination choice dismissal, copy open, overwrite refresh, cancellation staying on Compress, and one-shot completion.

## 7. Compress PDF Presentation

- [x] 7.1 Add/update PDF-editing keys and semantics for the Compress screen, document slider, page rows/override/reset, original/calculated sizes, Preview, Save, all-pages-100 warning, no-benefit review, copy/overwrite, progress/cancel, and error controls; update Viewer/edit robots in the same change.
- [x] 7.2 Implement `CompressPdfCubit`/immutable State with 80% document default, page overrides, exact size/saving, independent calculation/preview/commit jobs, pending destination, typed failures, and deterministic stale-job rejection.
- [x] 7.3 Add `bloc_test` Tier-1 coverage for load/default, document/page changes, override/reset, calculation/retry, Preview/cancel, Save-during-calculation, warning/adjust/continue, copy/overwrite, cancel/retry, failure, and one-shot completion.
- [x] 7.4 Build the adaptive full-page Compress PDF screen, lazy page-quality rows/dialog, size comparison/saving, Preview/Save, 100% and no-benefit reviews, copy/overwrite choice, and cancellable percent progress dialog.
- [x] 7.5 Add Tier-2 Compress component tests with the real Cubit/use cases and repository-boundary fakes for 30/80/100/mixed overrides, calculation failure, Preview, Save during calculation, warning branches, copy, overwrite, cancellation, failure, and completion.
- [x] 7.6 Add deterministic `@Preview()` entries for every changed compression widget/dialog and screen in default/loading/empty/error/long-content, override, mixed/all-100, progress, phone/tablet, light/dark, and maximum-text states.
- [x] 7.7 Add/update golden tests for the materially changed Compress screen across adaptive layouts, themes, long titles, page overrides, size/progress/failure, warning/destination dialogs, and maximum text scale.

## 8. End-to-End, Documentation, and Verification

- [x] 8.1 Extend the Tier-3 Settings and capture-to-document robots/flows to verify supported-resolution listing, default Full capture, lower-tier selection, fallback, add-another-page, photo-library independence, and separation from Save quality using keys/semantics only.
- [x] 8.2 Extend the Tier-3 capture-to-document/page-table-creation flow to verify Save name/default quality, one-page override/reset, password set/remove, size progress, Preview close/cancel, Save while calculating, Save cancel/retry, completion, and output metadata.
- [x] 8.3 Extend the Tier-3 `edit` flow to verify Compress at 80%, one-page override/reset, exact size progress, Preview close/cancel, Save while calculating, all-pages-100 warning, copy, overwrite, save cancel/retry, source safety, and final navigation.
- [x] 8.4 Add/update dartdoc on every public value, repository, use case, Cubit, state variant, widget, key, semantics constant, and route, plus inline rationale comments for migration, capability fallback, scaling math, secret lifetime, isolate cancellation, candidate ownership, and atomic rollback.
- [ ] 8.5 Run `dart format --set-exit-if-changed`, `flutter analyze`, layering/platform checks, targeted Tier-1/Tier-2 suites, goldens, and coverage verification; fix every failure and keep overall coverage at least 80% and business-logic coverage at least 90%.
- [x] 8.6 Run `tool/verify.dart` and report its per-stage result.
