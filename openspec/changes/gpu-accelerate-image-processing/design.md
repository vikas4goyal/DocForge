## Context

The application has three overlapping CPU pixel paths:

1. `enhancePageJob` applies enhancement passes with `package:image` in a background isolate.
2. `correctPageJob` performs bilinear perspective resampling with nested Dart loops in a background isolate.
3. `pageRenderJob` repeats the composed crop, resize, enhancement, and JPEG encode pipeline used by previews and final page output.

Isolates prevent main-isolate jank but do not reduce work. The shared page renderer is the critical path because crop and enhancement screens both use it, and its preview is regenerated after edit changes. The product targets Android and iOS only, works offline, stores edits as geometry plus enhancement settings, and must preserve deterministic behavior and output quality.

The stakeholders are users adjusting scans interactively, maintainers who need one authoritative render pipeline, and test/release engineering who need measurable device performance and a host-VM fallback.

## Goals / Non-Goals

**Goals:**

- Run geometry, scaling, and all enhancement pixel passes on the mobile GPU when the device supports the required pipeline.
- Meet p95 warm preview and full-resolution latency targets on documented Android emulator and iOS Simulator configurations and demonstrate a median speedup over the current CPU implementation in each environment.
- Preserve the existing page model, processing order, visual intent, offline behavior, UI contracts, and typed failure behavior.
- Bound memory and battery cost, cancel obsolete previews, clean partial output, and recover automatically from GPU unavailability or failure.
- Keep the CPU implementation as an injectable fallback and reference oracle.
- Provide explicit backend, latency, and fallback telemetry without sensitive image data.

**Non-Goals:**

- GPU-accelerating camera capture, OpenCV edge detection, OCR, PDF rasterization, or JPEG codec internals.
- Adding web, macOS, Windows, or Linux support.
- Changing filters, adding UI, changing routes, applying edits destructively, or changing stored document/page schemas.
- Byte-identical JPEGs across CPU, iOS, and Android; visual and structural parity is required instead.
- Cloud rendering or network processing.

## Decisions

### 1. One cross-feature renderer contract owns the complete file-to-file pipeline

Add an immutable `ImageRenderRequest` and an `ImageProcessingBackend` contract under `lib/core/contracts/image_processing/`. A request includes source and destination paths, request ID, preview/full scale, composed homography and output size, enhancement settings, JPEG quality, and colour-space version. The response includes the selected backend and measured stage timings without image data.

`RenderPage` continues to be the public page-facing use case and cache owner. It delegates to a native-first renderer repository that invokes one backend operation for decode → composed geometry → preview scaling → enhancement → encode. The same renderer adapter replaces direct production use of `correctPageJob` and `enhancePageJob`; those functions remain as the CPU backend/reference during migration.

The contract lives in `core` because document creation, scanning, and enhancement need it. Features depend on the contract and never import each other. `app/` remains the only composition layer that maps `PageRenderPlan` and feature-owned enhancement settings into the cross-feature request.

Alternatives considered:

- Accelerating only `enhance()` leaves perspective resampling and extra decode/encode work on the CPU and duplicates buffers.
- Independent platform calls per filter introduce Flutter channel overhead and repeatedly upload/download images.
- A third-party Flutter GPU-filter package gives less control over shadow removal, cancellation, resource limits, and output parity, and adds maintenance/licensing risk.

### 2. Native system GPU stacks are used behind one typed Flutter channel

iOS creates one lazily initialized `CIContext` backed by an injected `MTLDevice`. It composes `CIPerspectiveCorrection`/transform and Lanczos scaling with Core Image colour, threshold, blur, blend, and sharpen kernels. Custom Metal/Core Image kernels implement operations whose current maths cannot be represented faithfully by stock filters.

Android owns one worker thread and renders into an offscreen `ImageReader` through `HardwareRenderer` and `RenderNode`. Canvas' hardware perspective sampler performs geometry and an AGSL `RuntimeShader` performs point filters, bounded illumination sampling, adaptive thresholding, shadow normalization, and unsharp masking. Resources are scoped to the renderer instance, not statically; API levels below 33 fail capability probing closed and use CPU.

The Dart data source uses one method channel with generated `toJson`/`fromJson` values from immutable Freezed/json_serializable channel models. Native handlers validate enum/schema versions and application-owned paths. Calls are asynchronous and never execute pixel loops on the platform UI thread.

Alternatives considered:

- Vulkan gives stronger compute control on Android but materially raises device/driver complexity for 2D filters with no demonstrated need.
- Android `RenderEffect` is limited by API level and does not cover the complete pipeline.
- Metal shaders directly on both platforms would still require a separate Android implementation and duplicate more image plumbing than Core Image.

### 3. GPU capability is probed, not assumed, and CPU fallback is automatic

At composition, `NativeImageProcessingDataSource` and `CpuImageProcessingBackend` are passed explicitly into `NativeFirstImageRenderer`; no singleton or service locator is introduced. The first request lazily probes native availability and maximum texture size. Unsupported API/device capability chooses CPU without first attempting a GPU render.

Recoverable initialization, context-loss, allocation, shader, and native-codec failures delete any partial destination and retry exactly once through CPU. Corrupt input, invalid settings/path, storage-full, explicit cancellation, and CPU failure are returned immediately and are not disguised by fallback. A failed context may be recreated for a later independent request, but no global mutable health flag is used.

This accepts that “GPU instead of CPU” applies to pixel transforms. Native JPEG decode/encode can still consume CPU because mobile GPU APIs do not guarantee hardware JPEG codecs.

Alternatives considered:

- Removing CPU code would make older/low-memory devices and host tests unable to edit images.
- Always racing CPU and GPU wastes battery and memory.
- Persisting backend choice adds stale preferences and migration complexity; capability is session-local and cheap to probe once per injected renderer.

### 4. Preview requests are latest-wins and genuinely cancellable

The existing 120 ms Cubit debounce and generation check remain. Each render gains a monotonically increasing request ID owned by the renderer instance. Before submitting a newer preview for the same page/editor scope, the adapter sends cancellation for the prior ID. Native workers check cancellation between passes and before encode/atomic rename. An obsolete result is discarded even if a platform codec could not be interrupted.

`EnhancementCubit` keeps the existing immutable `ready`, `previewing`, and `failure` status values and transitions:

- `ready → previewing → ready` for a successful latest preview.
- `ready/previewing → previewing → failure` for a latest request that fails after fallback.
- an obsolete/cancelled request produces no state transition after the newer generation exists.
- `failure → previewing → ready|failure` on retry.

`CropCubit` retains its current ready/applying/failure transitions. No full Bloc is warranted because ordered UI commands and immutable Cubit states remain sufficient; cancellation is infrastructure orchestration, not business state.

### 5. Output parity is defined by colour and perceptual contracts

Both GPU paths normalize input to sRGB, use premultiplied-alpha-safe operations, clamp channels at the same stage boundaries, preserve EXIF orientation in raster orientation, and emit the existing JPEG quality. Geometry uses pixel-center bilinear sampling and clamped edges. Filter order remains shadow removal → named filter → brightness/contrast → sharpen.

Fixture parity uses exact output dimensions, orientation, two-tone constraints for Black & White, grayscale channel equality, no unexpected transparency/borders, and bounded per-pixel/perceptual error versus the CPU reference. Tolerances are recorded with the benchmark fixture manifest and cannot be loosened without review.

Alternatives considered:

- Byte equality is not portable across native codecs and GPU floating-point implementations.
- Visual-only manual review cannot catch regressions reliably.

### 6. Performance is measured at the user-facing boundary

The benchmark fixture is a checked-in synthetic 12-megapixel document page containing text, colour, gradients, uneven illumination, and a non-rectangular crop. The Android emulator and iOS Simulator model, OS image, host hardware/OS, graphics backend, and app build mode are recorded before implementation acceptance. These virtual-device configurations are the reproducible project performance gates; they are not evidence of physical-device battery life or thermal behavior.

Warm interaction targets measure from native render submission to an atomically readable output: p95 ≤200 ms for the 1400-pixel preview and p95 ≤1.5 s for the full-resolution fixture, plus ≥3x median improvement over the CPU reference in each virtual-device environment. Cold context creation is reported separately. At least 30 warm samples follow 5 warm-ups, with host load, graphics backend, and build mode recorded.

Stage telemetry records backend (`ios_core_image`, `android_gles`, `cpu_fallback`), preview/full kind, coarse source megapixel bucket, decode/transform/encode/total milliseconds, outcome, and non-sensitive fallback reason. It records no file path, pixel, document identifier, filter values, or OCR content.

### 7. Memory, lifetime, and atomic files are bounded

Native rendering is serial per backend instance. Preview surfaces are capped to preview size and both backends retain at most one modification-aware source for rapid edits, releasing it on memory warnings, engine detach, and disposal. Core Image evaluates oversized graphs in bounded regions of interest. Android reports no tiling support and selects CPU before publishing when an output exceeds its GPU surface limit; this preserves fidelity instead of introducing seams.

Output is encoded to a sibling temporary file and atomically renamed only after success and latest-request validation. Cancellation/failure removes the temporary file. Existing render cache keys remain valid because requested visual semantics do not change; derived caches may be cleared at rollout to avoid comparing old CPU files with new telemetry.

### 8. Persistence, navigation, UI, and preview surfaces do not change

There are no changes to Isar schemas, `SharedPreferences`, secure-storage keys, page JSON, routes, widget keys, or semantics labels. No sensitive data is newly persisted. Existing `enhance_*` and `scan_*` controls and screens are unchanged.

No new screen/widget requires `@Preview()`. Existing enhancement and crop previews continue covering default, loading, error, long content, light/dark, and phone/tablet configurations with deterministic fixtures. Their fake renderer remains injected, so previews never require a GPU or platform channel.

### 9. Verification spans contracts, native implementations, and the edit journey

Dart unit tests cover generated channel serialization, backend selection, fallback eligibility, typed failure mapping, atomic cleanup, cancellation, use cases, Cubit state sequences, geometry, and CPU/reference results. Repository tests inject scripted native and CPU backends. Component tests wire the real Cubit/use-case stack at the renderer boundary. Existing navigation tests assert route stability; no new route is added.

XCTest on an iOS Simulator and Android emulator instrumentation/JVM-native tests cover each GPU stage, schema rejection, corrupt files, storage errors, cancellation, context loss, texture limits/tiling, cleanup, and repeated-render resource stability. Virtual-platform fixture tests compare GPU output to the shared reference tolerance manifest.

Existing crop/enhancement goldens remain because the UI is unchanged. `integration_test/flows/edit_test.dart` is extended to operate every filter/adjustment, crop, save, reopen, and use an injected platform failure to prove visible fallback success. The full `tool/verify.dart` gate remains required; GPU performance acceptance additionally requires Android emulator and iOS Simulator benchmark reports.

### 10. Documentation and determinism are implementation requirements

New public contracts, immutable request/response models, data source, repository, and composition parameters receive truthful dartdoc stating parameters, returns, failures, and offline behavior. Inline comments explain colour conversion, pixel coordinates, shader pass ordering, tiling overlap, resource lifetime, cancellation boundaries, and fallback classification.

Request IDs and timings are instance-scoped. GPU contexts contain mutable native resources but are owned by injected backend instances and confined to their serial worker queues; there is no static/global mutable application state. Given the same request, backend, OS/device, and colour profile, processing is deterministic within the specified tolerance.

## Risks / Trade-offs

- **GPU/vendor output differences** → Normalize colour space, share fixture semantics, use reviewed tolerances, and retain the CPU oracle.
- **Texture-size or memory exhaustion on large photos** → Probe limits, tile with overlap, serialize full-resolution work, release pools on pressure, then fall back safely.
- **First-render shader/context setup cost** → Lazy one-time initialization, program caching, preserve the current image while loading, and report cold separately from warm latency.
- **Native implementation doubles platform-specific maintenance** → Keep one versioned request contract and shared fixture manifest; isolate platform code behind matching tests.
- **Cancellation cannot interrupt every codec call** → Suppress obsolete results, cancel between stages, skip encode when possible, and keep only one queued latest preview.
- **GPU can consume battery during rapid interaction** → Keep debounce, bound preview resolution, cancel obsolete work, and reuse contexts/textures. Virtual-device stress tests verify bounded work; physical battery impact is explicitly outside this acceptance gate.
- **Virtual-device speed differs from phones** → Pin and report both virtual-device configurations and host details, compare GPU and CPU within the same environment, and describe the thresholds as regression gates rather than physical-device guarantees.
- **CPU and GPU cache outputs can coexist during rollout** → Treat render cache as disposable derived data and clear/version it once when enabling the backend.

## Migration Plan

1. Capture CPU baselines and lock the shared fixture/tolerance manifest before changing production selection.
2. Introduce contracts, generated channel models, the CPU adapter, and native-first repository while continuing to select CPU.
3. Implement and validate iOS stages, then Android stages, against the same fixtures and failure contract.
4. Wire the renderer through the composition root, enable native capability probing, and retain injected CPU selection for tests.
5. Add cancellation, atomic output, telemetry, resource stress tests, and Android emulator/iOS Simulator benchmarks.
6. Enable GPU-first behavior for all compatible devices and clear/version only derived render caches; no user-data migration runs.
7. Run the complete verification gate and attach Android/iOS benchmark reports.

Rollback is a composition-root switch back to `CpuImageProcessingBackend`; stored pages, settings, routes, and documents require no rollback. Native code can remain dormant until a fixed version ships.

## Open Questions

- Which exact Android emulator profile and iOS Simulator model/OS image represent release acceptance? Record them with host and build-mode details before performance sign-off.
- Android acceleration deliberately targets API 33+ where AGSL `RuntimeShader` is available; older supported devices use the existing isolate backend through capability selection.
- Can full-resolution tiling meet parity for the largest supported input dimensions, or should product limits cap imported image dimensions? The fixture/stress phase must resolve this before rollout.
