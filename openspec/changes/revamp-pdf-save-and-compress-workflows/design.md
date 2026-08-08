## Context

DocScanly currently has two overlapping creation-save paths: a `SaveNameDialog` in `document_creation` that collects name/password and a `PdfPreviewScreen` in `pdf_generation` that exposes coarse `PdfQuality` presets. Compression is a focused branch of the shared PDF editor and uses a fixed image-quality constant, with successful compression assumed to replace the source. Camera capture always requests `ResolutionPreset.max`, while the existing image-quality preference controls stored page rendering rather than selecting a device-supported capture size. The existing repositories already provide background composition/editing and cancellation primitives, but their states do not model independent size calculation, preview, and commit jobs.

The new experience spans creation, generation, settings, PDF editing, filesystem safety, secure password handling, and typed navigation. It must remain offline, deterministic, testable, responsive on phones/tablets, accessible, and limited to Android and iOS. It must preserve feature-layer direction and cannot make one feature import another merely to launch a workflow.

## Goals / Non-Goals

**Goals:**

- Make Save PDF and Compress PDF full-page, explicit workflows with quality, calculated size, Preview, and Save.
- Give size calculation, preview preparation, and commit independent cancellable lifecycles so a slow calculation never disables Save.
- Preserve exact user choices while returning from a preview or a cancelled job.
- Keep password text out of Equatable state, logs, previews, Isar, and preferences while supporting Set and Remove on the Save screen.
- Separate device-supported capture resolution from post-capture document scaling and allow an effective quality override for one page without changing the document default.
- Make copy versus overwrite explicit and make overwrite atomic and recoverable.
- Reuse existing PDF, isolate, cancellation, secure-storage, persistence, and viewer surfaces without a new package.
- Define stable keys, semantics, previews, and tests before implementation.

**Non-Goals:**

- Predicting output bytes with a linear percentage formula or guaranteeing that 50% quality produces a file half the original byte size.
- Editing individual PDF content streams, fonts, vectors, or images selectively; compressed outputs are normalized page renders below 100%.
- Adding compression password controls, cloud processing, analytics, web, or desktop support.
- Persisting unfinished drafts, calculated candidates, preview files, progress, or passwords for crash recovery.
- Changing the independent image-export quality preference.

## Decisions

### 1. A shared percentage value defines quality consistently

Add a Freezed `PdfQualityPercent` value under `lib/core/contracts/models/` because Settings and PDF generation both consume it and feature-to-feature imports are forbidden. It validates an integer from 30 through 100 inclusive and exposes deterministic raster dimensions: `round(originalDimension * percent / 100)`, clamped to at least one pixel and never enlarged. `PageQualityPlan` contains the document default plus immutable overrides keyed by stable page ID for creation or zero-based page identity for an existing PDF; `effectiveFor(page)` returns the override or default. PDF-generation composition and PDF-editing compression requests carry this plan. Models that cross persistence boundaries use generated `json_serializable` support; there is no manual JSON.

For newly generated PDFs, 100% preserves the prepared/enhanced source image dimensions. Lower values reduce both width and height by the selected ratio and use a documented JPEG encoding curve bounded by that ratio. For compression, 100% is a pass-through candidate equal to the existing PDF; below 100%, each page is rendered at a bounded base resolution, scaled by the selected ratio, and encoded into a new PDF. Thus 50% means half width and half height, not half the pixels or bytes. The UI always separates “Quality” from “Calculated size.”

This is preferred over retaining only three presets because the requested per-document control cannot be represented. It is preferred over treating the percentage as expected byte savings because PDF content is nonlinear and such a promise would be false.

The Settings default moves from `PdfQuality` to `PdfQualityPercent`. Existing stored names migrate on read as `low -> 40`, `balanced -> 70`, and `high -> 100`; the new integer is written to a versioned preference key after the user changes it. Missing/invalid values use 70%. The Settings row remains the default selector for Save PDF and explains that each Save screen can override it. Compression always initializes to 80% and never reads or writes this preference. Per-page overrides are route/session state only and never change Settings.

### 2. Capture resolution is capability-driven and precedes PDF quality

Replace the ambiguous `ImageQuality` setting with a Freezed `CaptureResolutionChoice` contract in core: a stable preference expresses the desired tier, while `CameraCapabilityRepository` in `document_scanning/domain` reports the concrete resolutions supported by the active camera. Canonical display tiers (such as 720p, 1080p, 2K, and 4K) are derived from reported dimensions and only shown when the device can satisfy them. The exact width × height is shown alongside the friendly tier, so labels never overstate the hardware.

`LoadCameraResolutions` queries capabilities off the UI thread and `ResolveCaptureResolution` chooses the persisted tier when supported, otherwise the nearest lower supported tier. With no saved preference, it chooses the active camera's highest full supported still-image resolution; if capabilities cannot be enumerated, it requests the plugin's maximum preset and verifies the resulting dimensions. `CapturePage` passes the resolved size/preset to the existing camera repository before capture. Switching front/back cameras re-queries the list and visibly updates a fallback if the prior choice is unavailable. Photo-library imports retain their source pixels and are never upscaled; their later PDF reduction is governed only by Save quality.

Settings uses `settings_camera_resolution`, `settings_camera_resolution_screen`, `settings_camera_resolution_option_<tier>`, and `settings_camera_resolution_retry`, with semantics including tier and dimensions. A missing preference means “Full resolution” and resolves to the active camera's highest supported size. The old `settings.imageQuality` values migrate to desired tiers (`low -> 720p`, `balanced -> 1080p`, `high -> full/highest supported`) on first successful capability query. The resolved hardware size is not persisted as universal truth because supported sizes vary by device and camera.

This is preferred over fixed options because some cameras cannot deliver every named tier and plugins may fall back silently. It is preferred over continuing to request `max`, which makes capture cost unpredictable and prevents the user from controlling source size.

### 3. Dedicated Cubits model configuration plus three independent jobs

Use Cubits, not full Blocs: all transitions are user-driven and linear, and no event transformer or replay behavior is needed. Business rules remain in values/use cases; Cubits only invoke them and publish UI state.

`SavePdfCubit` owns immutable `SavePdfState` with configuration (`name`, `documentQuality`, `pageQualityOverrides`, `pageCount`, `passwordEnabled`) and three orthogonal `AsyncJobView` values: `calculation`, `preview`, and `commit`. Each job view has variants `idle`, `queued`, `running(progress)`, `succeeded(resultSummary)`, `cancelled`, and `failed(Failure)`. Screen transitions are:

```text
load -> editable -> qualityChanged -> calculation.queued/running -> calculated
editable -> preview.running -> previewReady(route) -> editable
editable -> commit.running -> saved(close workflow)
preview.running/commit.running -> cancel -> editable
any running -> typed failure -> editable with recovery
```

`CompressPdfCubit` owns `CompressPdfState` with the source summary, `documentQuality` (80 initially), page-index overrides, calculated result, the same three independent job views, and a transient `pendingDestinationChoice`. Its commit transition is `Save -> optional all-pages-100% warning -> copy/overwrite choice -> commit.running -> completed(close)`. A copy result carries the new document; overwrite carries the refreshed source document.

Every field participates in `Equatable.props`. A monotonically increasing route-local job generation is attached to each request; only a completion matching the current generation is emitted. The counter is instance state owned by the Cubit, never static/global, and tests inject deterministic job runners. This prevents stale calculations from replacing the size for a newer slider value.

This is preferred over a single `status` because calculation must run while Save remains enabled and because cancelling Preview/Save must not erase configuration. Separate Cubits are preferred over expanding `PdfEditCubit` further: compression is now a dedicated route with independent long-lived configuration, while the editor retains its shared entry/result contract.

### 4. Password text lives in an explicit route-scoped secret boundary

The Set Password dialog owns obscured password and confirmation controllers and validates them through the existing creation rules. On acceptance it transfers a `SecretValue` into an explicitly constructed `PdfPasswordDraft` owned by the Save route. That collaborator is injected into `SavePdfCubit` and the preview/save use cases; the Cubit state contains only `passwordEnabled`. Remove clears and zeroizes the draft immediately. Route disposal and successful/cancelled workflow exit also clear it.

The password is passed directly to candidate generation. Only after a committed document is verified is it stored under the existing per-document `flutter_secure_storage` contract. It never enters Isar, SharedPreferences, JSON, `Equatable.props`, logs, error text, previews, or fixtures. This small route-scoped mutable holder is explicit constructor state, not a singleton or hidden global; its narrow API is `replace`, `readForOperation`, and `clear`.

This is preferred over keeping the password in Cubit state, as the current dialog does, and over a temporary secure-storage key that could survive a crash as an orphaned credential.

### 5. Page overrides are explicit exceptions to the document default

Both dedicated screens show an ordered, lazy page summary. Selecting `pdf_save_page_quality_<page-id>` or `pdf_compress_page_quality_<page-number>` opens `pdf_page_quality_dialog` with a 30–100% `pdf_page_quality_slider`, an option `pdf_page_quality_use_document`, and current document-default copy. Setting a value records one override; choosing Use document quality removes it. `pdf_page_quality_reset_all` is shown only when overrides exist. Each overridden row announces “Page N, quality X percent, overrides document quality.”

Changing the document slider does not erase overrides; it updates every non-overridden page. This predictable precedence is preferred over proportionally shifting overrides, which would make an explicit page choice unstable. In Save, a page override operates on its prepared/cropped/enhanced image. In Compress, a page below 100% is normalized/downsampled while a page effectively at 100% is copied through when supported. Candidate fingerprints include the ordered effective percentage for every page, so size and Preview cannot accidentally reuse a result with different overrides.

No override is written to Settings. Creation-session overrides may be retained in the in-memory `PageDraft`/save request while the workflow is open; compression overrides live only in `CompressPdfState`. The committed document records the effective ordered quality plan only if the current metadata contract can store it additively; otherwise it records the document default and the exact final byte size without adding a destructive schema migration.

### 6. Candidate jobs provide exact size and reusable preview output

Add domain repository contracts in each owning feature for `buildCandidate(request, token, onProgress)` and `discard(candidate)`. `PdfCandidate` is a Freezed value containing a private temporary path/handle, exact byte count, page count, a fingerprint of every output-affecting input, and whether protection is applied. Infrastructure performs work in a background isolate and reports progress as completed pages divided by total pages, with final verification included before 100%.

Quality changes debounce calculation by 350 ms. A new value cancels the prior token and schedules a new candidate. Until it completes the UI shows `Calculating… N%` under `Key('pdf_output_size_status')`; when complete it shows human-readable exact candidate bytes. Calculation failure is non-blocking and offers Retry. Save is enabled whenever the name/pages are valid and no commit is already running, regardless of calculation state.

Preview asks the use case for a candidate matching the current fingerprint. It reuses a verified calculation candidate when present; otherwise it creates one with modal progress. A typed `PdfTemporaryPreviewRoute` displays the temporary PDF using the existing injected viewer surface in read-only mode. Back/cancel deletes preview-only output when it is not retained in the route's bounded candidate cache and returns to the unchanged configuration screen.

Save similarly promotes a verified matching candidate when safe; otherwise it cancels calculation and starts its own candidate immediately. It never awaits an unrelated calculation. Candidate ownership is explicit so a file is deleted exactly once. The route keeps at most one verified candidate and one in-flight job, limiting disk and memory use.

This exact dry-run approach is preferred over a fast arithmetic estimate because the user asked for actual output size. Its cost is managed by debounce, cancellation, candidate reuse, background work, and bounded page processing.

### 7. Commit is transactional and cancellation returns to configuration

`SaveGeneratedPdf` validates the name/collision policy, generates or promotes the candidate, atomically moves it to the library, verifies it, creates the Isar document record, stores the password if enabled, and only then cleans the creation session. Rollback removes the final file/record/credential if a later commit stage fails. Cancelling before commit completion removes partial/candidate output and retains source pages.

`SaveCompressedPdf` accepts `CompressionDestination.copy` or `overwrite`:

- Copy resolves a collision-safe title such as `<title> compressed`, commits a new file and document row, and leaves the source unchanged.
- Overwrite writes beside the source, verifies page count/readability, uses the existing atomic replace/backup strategy, updates file size/modified metadata, and removes the backup only after Isar succeeds. Cancellation/failure restores the source.

When every page is effectively 100%, `PrepareCompression` returns a verified pass-through candidate with the original exact size without rasterizing. `Key('pdf_compress_no_compression_dialog')` explains “Every page is at 100%, so the current PDF quality is kept and its size is not expected to reduce”; Continue proceeds to destination choice and Adjust returns to the slider. A document default of 100% with any lower page override is real compression and does not show this warning. `Key('pdf_compress_destination_dialog')` contains `pdf_compress_save_copy` (“Save as a copy”) and `pdf_compress_overwrite` (“Replace original”).

Preview and commit show `Key('pdf_job_progress_dialog')`, `pdf_job_progress_indicator`, and `pdf_job_cancel_button`, with semantics “Preparing PDF, N percent”, “Saving PDF, N percent”, and “Cancel PDF operation.” Cancellation dismisses only the progress dialog and leaves the Save/Compress route and all configuration intact. A successful commit closes that route: Save returns to the destination folder; compression copy opens the copy via typed navigation; overwrite refreshes the original viewer/editor.

### 8. Typed navigation keeps features decoupled

Add typed GoRouter destinations `SavePdfRoute`, `CompressPdfRoute`, and `PdfTemporaryPreviewRoute`. Entry code passes identifiers/session handles and composition-root factories, not feature implementation objects. `document_creation` continues to call a core application-facing save-flow launcher/typed route and does not import `pdf_generation`; the Viewer uses its existing typed operation route to enter `CompressPdfRoute` directly. The temporary route receives an app-private candidate handle and a read-only surface factory.

No string-literal navigation or feature-to-feature domain import is introduced. The composition root constructs repositories -> use cases -> route-scoped secret/job collaborators -> Cubits and supplies Cubits through `BlocProvider`.

### 9. Stable controls, semantics, adaptive layout, and previews

Save uses `pdf_save_screen`, `creation_save_name_field`, `pdf_save_quality_slider`, `pdf_save_page_quality_<page-id>`, `pdf_page_quality_reset_all`, `pdf_output_size_status`, `pdf_save_set_password`, `pdf_save_password_enabled`, `pdf_save_remove_password`, `pdf_save_preview_button`, and `creation_save_confirm_button`. The password dialog uses existing password field keys plus `pdf_save_password_dialog_confirm`. Compress uses `pdf_compress_screen`, `pdf_compress_quality_slider`, `pdf_compress_page_quality_<page-number>`, `pdf_page_quality_reset_all`, `pdf_compress_original_size`, `pdf_output_size_status`, `pdf_compress_preview_button`, and `pdf_compress_save_button`. All controls are at least 48dp and expose their visible purpose and current value, including “PDF quality, 70 percent,” “Page 2, quality 40 percent, overrides document quality,” “Calculated PDF size, 4.2 MB,” “Password protection enabled,” and “Preview PDF.”

Both screens use one scrollable, safe-area-aware content column on phones and a width-limited two-pane arrangement on tablets where size summary/preview actions can sit beside settings. Large text falls back to one column. `BlocSelector` limits slider progress/size updates to the smallest widgets. Material 3/adaptive dialogs use the active color scheme and remain usable offline.

Fixture-backed `@Preview()` entries cover every reusable quality slider, size status, password status, progress dialog, size comparison, and destination dialog in default, loading, empty/not-calculated, error, and long-content states. Save and Compress screens cover those states plus phone/tablet, light/dark, maximum supported text, 30/80/100%, password enabled, long names, running/cancelled/failed jobs, and 100% warning. Fixtures use fixed paths, bytes, pages, progress, and IDs; no filesystem, database, plugins, secure values, randomness, or wall clock is reached.

### 10. Persistence, documentation, tests, and sync boundary

Isar persists only committed document metadata including exact final bytes and selected quality percentage. SharedPreferences persists only the Save default quality. `flutter_secure_storage` persists only a committed document password. Calculation candidates, job generations, preview handles, configuration drafts, and compression destination choice are transient.

Public value objects, repository contracts, use cases, Cubits, states/variants, widgets, constructors, route data, keys, and semantics constants receive Effective Dart dartdoc. Inline comments explain dimension rounding, legacy-quality migration, debounce/job supersession, isolate progress, candidate ownership, secret zeroization limitations in Dart strings, and atomic-replacement rollback.

Tier 1 tests cover domain math/migration, per-page precedence/reset, camera capability resolution/fallback, use cases, job cancellation/supersession, candidate ownership, repository rollback and PDF validity, settings persistence, route parsing, and `bloc_test` state sequences. Tier 2 component tests use real Cubits/use cases with repository-boundary fakes for Settings resolution, capture, both output screens, and dialogs. Goldens cover adaptive/theme/text variants and all meaningful phases. Tier 3 extends capture-to-document/page-table creation for device-supported capture resolution and Save, and `edit` for Compress using keys/semantics only, including per-page override, Preview, Save-during-calculation, cancel-and-retry, copy, overwrite, and all-pages-100% warning. `tool/verify.dart` remains the release gate.

Only committed document files/metadata cross the future cloud-sync boundary. Temporary candidates, preview files, progress, defaults, and passwords remain local; copy versus overwrite is expressed as a repository mutation that a future sync layer can translate into create versus update.

## Risks / Trade-offs

- **[Risk] Exact calculation can duplicate expensive work and consume battery.** → Debounce changes, cancel obsolete jobs, run off-thread, reuse matching verified candidates, and never calculate 100% compression.
- **[Risk] Rasterizing an existing PDF can remove selectable text/vector fidelity below 100%.** → Explain that lower quality normalizes pages, preserve page count, keep 100% as pass-through, and require Preview before the user chooses when fidelity matters; selective object compression remains a non-goal.
- **[Risk] Large pages can exhaust memory.** → Process one/bounded pages at a time, cap base render resolution, release page/image objects immediately, and cancel cooperatively between stages.
- **[Risk] A cancelled isolate may finish a filesystem write before observing cancellation.** → Write only to owned temporary paths, check the token between stages and before commit, and have the parent unconditionally discard uncommitted output.
- **[Risk] Overwrite could lose the only source.** → Verify a sibling candidate first, use atomic replacement with backup/rollback, update Isar after the file swap, and retain the backup until metadata succeeds.
- **[Risk] Exact candidate bytes may differ after encryption or final metadata.** → Include password-enabled state and all metadata-affecting inputs in the fingerprint and calculate the same final candidate format that is promoted to save.
- **[Risk] Dart strings cannot guarantee physical zeroization.** → Minimize lifetime and copies, never serialize/log/store the draft, clear controllers/holder promptly, and document the runtime limitation truthfully.
- **[Trade-off] A 30% minimum prevents very tiny files.** → It protects legibility and matches the requested meaningful lower bound; users see the calculated size and can choose 30% when space matters most.
- **[Risk] Camera plugins expose presets rather than a complete stable resolution list on some devices.** → Probe what the active plugin/device can honor, show exact dimensions when known, verify the captured dimensions, and fall back visibly to the nearest supported lower tier.
- **[Risk] Many per-page overrides can become hard to understand.** → Keep one document default, mark overrides on their rows, provide Use document quality and Reset all, and compute a single effective value per page.

## Migration Plan

1. Add `PdfQualityPercent`, `PageQualityPlan`, generated persistence support, and legacy preset mapping while keeping old reads compatible.
2. Add camera capability/resolution contracts, migrate the old image-quality preference, and wire capture through the resolved supported tier.
3. Add candidate/job contracts and fakes, then implement generation candidates and exact-size calculation behind existing composition.
4. Introduce `SavePdfCubit`, page overrides, dedicated route/screen, password draft boundary, progress/preview route, and update creation entry points.
5. Add compression candidate, page overrides, and transactional copy/overwrite use cases, then replace the focused compress route with `CompressPdfCubit` and screen.
6. Update Settings copy/controls and wire explicit dependencies in the composition root.
7. Add previews, unit/component/golden/navigation/Tier-3 coverage and run the full verification gate on an available Android/iOS target.

Rollback keeps the backward-compatible preference reader, restores the old route entry widgets, and removes transient candidate files. No authoritative PDF or Isar row is migrated destructively. If percentage metadata requires an Isar schema change rather than an existing attribute/map, implementation pauses for an additive schema version and migration tests before rollout.

## Open Questions

- During implementation, confirm whether the installed PDF engine can preserve searchable text while downsampling embedded images. If it cannot, keep the specified raster normalization and surface that fidelity trade-off in Compress copy; do not silently claim text preservation.
- Confirm the current atomic replacement helper's guarantees on both Android and iOS library providers. If a provider cannot atomically replace, use copy-and-verify with a recoverable backup under the storage repository contract and exercise it on-device.
