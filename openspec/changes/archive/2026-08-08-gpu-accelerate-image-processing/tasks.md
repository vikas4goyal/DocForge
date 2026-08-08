## 1. Baseline and Contracts

- [x] 1.1 Add the synthetic 12-megapixel document fixture, CPU benchmark harness, immutable tolerance manifest, and a report template that records host, Android emulator or iOS Simulator configuration, OS image, graphics backend, build mode, cold runs, five warm-ups, and 30 warm samples.
- [x] 1.2 Run and record the pre-change CPU preview/full-resolution latency, output dimensions, memory, and visual-reference results on the selected Android emulator and iOS Simulator configurations.
- [x] 1.3 Add dartdoc'd `ImageProcessingBackend`, request/result/capability/backend enums, cancellation contract, and typed failures under `lib/core/contracts/image_processing/`, keeping models independent of Flutter and feature code.
- [x] 1.4 Add Tier-1 contract tests for value equality, validation, backend identity, cancellation outcomes, and invalid dimensions/geometry/settings.
- [x] 1.5 Add immutable Freezed/json_serializable platform-channel DTOs with schema/colour-pipeline versions and generated serialization code; document all public conversion APIs.
- [x] 1.6 Add Tier-1 serialization tests that round-trip every filter, optional transform, preview/full scale, quality, request ID, timings, capability response, and unknown/malformed schema failures.

## 2. Dart Native-First Infrastructure

- [x] 2.1 Implement the typed `NativeImageProcessingDataSource` method-channel adapter for capability, render, cancel, and dispose calls without transferring decoded pixels or logging sensitive fields.
- [x] 2.2 Add Tier-1 data-source tests with a mock binary messenger for channel payloads, native error mapping, cancellation, disposal, and absence of paths/content in telemetry.
- [x] 2.3 Adapt the existing Dart isolate pipeline to `CpuImageProcessingBackend`, preserving operation order, preview bounds, file quality, typed failures, and cancellable pre/post-stage checks.
- [x] 2.4 Add Tier-1 CPU-backend regression tests for every filter/adjustment, geometry plus enhancement, corrupt input, storage failure, cancellation, and partial-file cleanup.
- [x] 2.5 Implement `NativeFirstImageRenderer` with capability probing, GPU-first selection, explicit recoverable/non-recoverable fallback classification, one CPU retry, request-scoped health, and atomic output publication.
- [x] 2.6 Add Tier-1 repository tests proving compatible selection, unsupported selection, each eligible fallback reason, no fallback for corrupt input/storage/cancellation, exactly one retry, atomic rename, and temporary-file cleanup.
- [x] 2.7 Add privacy-safe render telemetry for backend, render kind, coarse megapixel bucket, stage/total duration, outcome, and fallback reason.
- [x] 2.8 Add Tier-1 telemetry tests proving the required fields and proving paths, pixels, document IDs/metadata, OCR text, and exact settings are never emitted.

## 3. iOS Core Image and Metal Backend

- [x] 3.1 Register a versioned iOS image-processing channel and implement validated application-owned path handling, capability probing, serial worker execution, request cancellation, temporary output, and deterministic cleanup.
- [x] 3.2 Add XCTest coverage for schema/path rejection, capability reporting, corrupt input, cancellation, atomic output, cleanup, context recreation, and processor resource disposal.
- [x] 3.3 Implement the Core Image/Metal geometry, pixel-center bilinear perspective correction, orientation, canonical sRGB conversion, preview scaling, and JPEG file-to-file stages.
- [x] 3.4 Add iOS native fixture tests for dimensions, preview scaling, identity/perspective geometry, canonical sRGB decoding, JPEG output, and bounded structural tolerances.
- [x] 3.5 Implement iOS GPU passes for Original, Auto Enhance, Magic Colour, Grayscale, brightness, contrast, and Black & White with the specified stage ordering and clamping.
- [x] 3.6 Add iOS native parity tests for each named/point filter, representative combinations, grayscale equality, two-tone constraints, and bounded channel tolerances.
- [x] 3.7 Implement reusable separable blur, shadow normalization, adaptive threshold support, and unsharp masking with bounded Metal/Core Image resources.
- [x] 3.8 Add iOS native parity and stress tests for shadow removal, sharpening, combined blur consumers, 100 repeated previews, cancellation, and explicit resource release.
- [x] 3.9 Report the maximum Metal texture size, rely on Core Image's bounded region-of-interest evaluation for oversized graphs, preserve global illumination statistics across regions, and select CPU fallback when Core Image cannot preserve fidelity.
- [x] 3.10 Add iOS simulated-oversize tests for bounded Core Image evaluation, context recreation, output dimensions, and complete temporary-resource cleanup.

## 4. Android HardwareRenderer/AGSL Backend

- [x] 4.1 Register a versioned Android image-processing channel and implement validated application-owned path handling, API/renderer capability probing, a dedicated serial GPU worker, request cancellation, temporary output, and deterministic cleanup.
- [x] 4.2 Add Android emulator tests for schema/path rejection, unsupported capability, corrupt input, cancellation, atomic output, cleanup, renderer recreation, and engine detachment.
- [x] 4.3 Implement offscreen HardwareRenderer geometry, hardware-bilinear perspective correction, orientation, canonical sRGB conversion, preview scaling, and native JPEG file-to-file stages.
- [x] 4.4 Add Android emulator fixture tests for dimensions, perspective geometry, colour decoding, JPEG output, and bounded structural tolerances.
- [x] 4.5 Implement Android AGSL for Original, Auto Enhance, Magic Colour, Grayscale, brightness, contrast, and Black & White with shader reuse, specified stage ordering, and clamping.
- [x] 4.6 Add Android emulator parity tests for each named/point filter, representative combinations, grayscale equality, two-tone constraints, and bounded channel tolerances.
- [x] 4.7 Implement bounded GPU neighborhood sampling, shadow normalization, adaptive threshold support, and unsharp masking with bounded native surfaces.
- [x] 4.8 Add Android emulator parity and stress tests for shadow removal, sharpening, combined blur consumers, 100 repeated previews, cancellation, and explicit resource release/recreation.
- [x] 4.9 Implement maximum-surface detection and CPU fallback before publication when an oversized Android render cannot preserve fidelity on one GPU surface.
- [x] 4.10 Add Android simulated-oversize tests for maximum-surface detection, typed allocation fallback, and complete temporary-resource cleanup.

## 5. Application Integration and Latest-Wins Editing

- [x] 5.1 Wire native and CPU backends through explicit constructors in the composition root, route `RenderPage`, `ApplyEnhancement`, and `ApplyPerspectiveCorrection` through the one renderer, and version/clear only derived render caches.
- [x] 5.2 Add Tier-1 composition/use-case tests proving the native-first renderer is used for preview, full output, crop-only, enhancement-only, combined plans, and injected CPU/host configurations without changing page persistence.
- [x] 5.3 Update `EnhancementCubit` to assign cancellable preview scopes/request IDs while retaining debounce, generation guards, immutable `ready`/`previewing`/`failure` states, undo, revert, retry, and latest-result behavior.
- [x] 5.4 Add `bloc_test` coverage for rapid slider changes, filter changes during an active render, cancellation without failure UI, latest-only publication, fallback success, retry, close, undo, and revert state sequences.
- [x] 5.5 Update crop rendering orchestration to cancel obsolete correction previews and preserve the existing progress, retry, geometry, and enhancement-independent behavior.
- [x] 5.6 Add crop Cubit Tier-1 tests for latest-only correction, fallback success, double failure retaining the working image, composed single resample, retry, and cancellation on close.
- [x] 5.7 Update required dartdoc and intent comments for contracts, models, data sources, repositories, composition parameters, colour handling, shader ordering, oversized rendering, lifecycle, cancellation, and fallback; run the layering and platform-scope checks.
- [x] 5.8 Add architecture tests proving no feature-to-feature imports, no release-accessible fakes, no global/static mutable backend state, and Android/iOS-only platform additions.
- [x] 5.9 Use a 500 ms trailing debounce for continuous enhancement sliders, constrain brightness, contrast, and sharpening to practical continuous ranges across Dart and native validation, and cover the timing and bounds with Cubit, widget, contract, and platform compile checks.

## 6. UI-Level Regression Coverage

- [x] 6.1 Update Tier-2 enhancement screen/component tests using the real Cubit/use cases and an injected renderer to cover loading, latest success, fallback success, error/retry, undo/revert, and every existing keyed control.
- [x] 6.2 Update Tier-2 crop screen/component tests using the real Cubit/use cases and an injected renderer to cover applying, fallback, error/retry, geometry output, and existing accessible corner/apply/revert/next controls.
- [x] 6.3 Audit `enhancement_previews.dart`, `scan_previews.dart`, `enhance_keys.dart`, and `scan_keys.dart`; preserve or update deterministic default/loading/error/long-content, light/dark, phone/tablet previews and existing keys/semantics, with preview/widget tests proving no GPU dependency.
- [x] 6.4 Run existing enhancement and scanning golden suites and update baselines only if an intentional, reviewed UI change is discovered; GPU pixel parity remains covered by fixture tests rather than UI goldens.
- [x] 6.5 Extend the Tier-3 catalogue flow `integration_test/flows/capture_to_document_test.dart` and its robots to drive crop, every enhancement key, rapid adjustment, save, reopen, and an injected recoverable native failure that succeeds through CPU fallback.
- [x] 6.6 Run the updated crop/enhance flow on an Android emulator and a usable iOS Simulator, recording platform limitations without treating a skipped virtual-platform flow as verified. A physical device is not required.

## 7. Performance Acceptance and Release Verification

- [x] 7.1 Add benchmark execution scripts/assertions for backend proof, cold/warm separation, p95 preview ≤200 ms, p95 12-megapixel full render ≤1.5 seconds, and median GPU speedup ≥3x over CPU per documented virtual-device environment.
- [x] 7.2 Run Android emulator benchmarks and record the host/profile/OS image/graphics backend, 30-sample latency distributions, selected backend, output parity, peak memory, repeated-preview resource stability, and any fallback.
- [x] 7.3 Run iOS Simulator benchmarks and record the host/model/runtime/graphics backend, 30-sample latency distributions, selected backend, output parity, peak memory, repeated-preview resource stability, and any fallback.
- [x] 7.4 Run `dart format --set-exit-if-changed`, `flutter analyze`, all native test suites, and coverage verification; fix every failure and confirm overall coverage remains at least 80 percent and business logic targets at least 90 percent.
- [x] 7.5 Run `tool/verify.dart` and report its per-stage result. The change is not done while any stage fails, and a run that reports Tier 3 as SKIPPED because no Android emulator or usable iOS Simulator is available does not count as verified. A physical device is not required.
