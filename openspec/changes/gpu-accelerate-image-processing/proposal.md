## Why

Image editing currently performs perspective resampling and every enhancement pass in pure Dart on CPU isolates. This keeps the UI thread alive but still makes previews and full-resolution renders wait on expensive per-pixel CPU work, so the editing experience does not feel immediate on mobile devices.

## What Changes

- Replace the production page-rendering pixel pipeline with native, hardware-accelerated implementations: Core Image backed by Metal on iOS and offscreen `HardwareRenderer`/AGSL passes on Android.
- Accelerate the complete edit pipeline—composed crop/perspective correction, preview scaling, Original, Auto Enhance, Magic Colour, Black & White, Grayscale, brightness, contrast, sharpening, and shadow removal—while preserving the existing order of operations and non-destructive page model.
- Keep JPEG file I/O and codec work at the native platform edge, pass file paths and immutable settings across one typed platform boundary, and never transfer full decoded pixel buffers through Dart or Flutter.
- Prefer the GPU automatically when a compatible device/context is available; retain the existing isolate-based CPU implementation as a deterministic fallback for unsupported devices, GPU initialization/runtime failures, and host-VM tests.
- Add render cancellation/latest-request semantics so obsolete slider previews stop consuming GPU/codec work and can never replace the newest preview.
- Add benchmark and telemetry coverage for backend selection, preview latency, full-resolution latency, failures, and fallback use, with no image contents or paths recorded.
- Establish measurable responsiveness targets for representative 12-megapixel pages: p95 preview rendering within 200 ms after processing starts, p95 full-resolution rendering within 1.5 seconds, and at least a 3x median speedup over the CPU baseline on documented Android emulator and iOS Simulator configurations.
- Preserve output fidelity through fixture-based tolerances and structural document assertions rather than requiring byte-identical JPEG output across GPU vendors.
- Support Android and iOS only; no web or desktop implementation is introduced.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `image-enhancement`: Require hardware-accelerated preview and full-resolution enhancement when supported, bounded preview latency, latest-request cancellation, output fidelity, observable fallback, and safe CPU degradation.
- `document-scanning`: Require the perspective-correction stage used by page editing to use the same hardware-accelerated render path when supported while preserving responsive, correct cropping and CPU fallback.

## Impact

### Architecture and folders

The public `PageRenderer` contract and the non-destructive `PageRenderPlan` remain stable. The implementation moves from a Dart-isolate-only pixel writer to an injected renderer abstraction with native and CPU implementations.

```text
lib/
  core/
    contracts/image_processing/       # backend/result/capability contracts
  features/image_enhancement/
    presentation/                     # existing Cubit/State/screens; latest preview handling updated
    application/usecases/             # orchestration targets the renderer abstraction
    domain/                            # settings/rules remain platform independent
    infrastructure/
      datasource/                     # typed native image-processing channel
      repositories/                   # native-first renderer with CPU fallback
  features/document_scanning/
    presentation/                     # existing crop progress/error states retained
    application/usecases/             # correction delegates to shared renderer
    domain/                            # geometry remains pure Dart
    infrastructure/                   # legacy CPU correction retained as fallback
ios/Runner/ImageProcessing/            # Core Image/Metal context, filters, codecs
android/app/src/main/kotlin/.../imageprocessing/
                                      # HardwareRenderer/AGSL filters and codecs
test/                                 # contracts, parity, fallback, Cubit and benchmark harness tests
integration_test/flows/               # crop/enhance user-journey regression coverage
```

### Layer changes

- **Cubits and States:** `EnhancementCubit` retains its existing user-facing states and generation guard, but preview orchestration gains cancellable request identifiers. Crop state behavior remains unchanged. Backend choice is not exposed as UI state.
- **Use cases:** enhancement, page rendering, and perspective correction depend on an injected image-processing contract and preserve typed `Result` failures. No business logic moves into Cubits.
- **Repositories/infrastructure:** a native-first renderer reports capability, renders a file-to-file request, cancels superseded work, and retries once through the CPU renderer for eligible GPU failures. The CPU renderer remains injectable and testable.
- **Isar and storage:** no Isar schema, stored preference key, secure-storage key, page model, or document migration is required. Render cache entries remain derived and may be discarded across app upgrades.
- **Navigation:** no route or deep-link changes are required.

### Dependencies and platform APIs

- iOS uses system Core Image and Metal frameworks (`CIContext` with an `MTLDevice`); no third-party runtime dependency is required.
- Android uses system `HardwareRenderer`, `RenderNode`, `RenderEffect`, AGSL, and platform bitmap codecs; no third-party runtime dependency is required. Capability probing selects it on API 33+ and otherwise selects CPU before rendering.
- The Dart `image` package remains temporarily because it implements the CPU fallback and host-side golden fixtures. Removing it is explicitly outside this change.
- No commercial, network, cloud, or generative-AI image dependency is added.

### Performance, memory, and battery

- One native command performs decode, geometry, downscale, enhancement, and encode so intermediate full-resolution images never cross the Flutter channel and GPU passes reuse textures.
- Preview work is bounded to the existing preview resolution, reuses a long-lived native GPU context, allows only the newest request to complete, and releases textures deterministically.
- Full-resolution work remains serialized per renderer to cap peak texture/bitmap memory. On memory pressure or lost GPU context, work falls back to the isolate implementation instead of crashing.
- Benchmarks cover cold context creation separately from warm interaction, peak resident/graphics memory, repeated-preview resource stability, and GPU-versus-CPU latency on the documented virtual devices.

### Security and privacy

- Page images remain in application-controlled local storage and are processed fully offline.
- The native channel carries local paths, geometry, numeric settings, quality, and request IDs only. It performs no network request and records no paths, pixels, OCR text, or document metadata in telemetry.
- Destination paths are validated as application-owned before native writes; partial outputs are removed on failure or cancellation.

### Testing and previews

- Unit tests cover request serialization, capability selection, fallback classification, cancellation, failure mapping, settings parity, geometry, and unchanged use-case behavior.
- Native iOS and Android tests cover shader/filter stages, invalid input, context loss, cancellation, resource cleanup, and deterministic fixture output within documented tolerances.
- Repository tests prove native-first selection, single safe fallback, partial-file cleanup, and no fallback after cancellation.
- Cubit tests prove rapid slider changes display only the latest render and retain retry/error behavior.
- Component/widget tests retain the real Cubit/use-case boundary; navigation and serialization regression tests confirm no contract changes.
- Golden tests continue to cover enhancement and crop screens because UI appearance is unchanged; image fixture parity tests separately compare CPU and GPU output.
- The edit end-to-end flow exercises capture/import, crop, every enhancement control, completion, reopen, and fallback through widget keys on Android and iOS-capable test devices.
- Existing `@Preview()` coverage for enhancement and crop screens remains valid for default, loading, error, long-content, light/dark, phone/tablet states. No new UI widget or screen is introduced, so no additional preview surface is required.

### Risks and mitigations

- GPU output can vary by vendor and colour space; canonical sRGB handling, per-stage fixtures, perceptual/error tolerances, and CPU comparison mitigate visible drift.
- Large textures can exceed device limits or memory; capability/texture-size checks, preview bounds, serialized full-resolution work, tiled rendering where required, and CPU fallback prevent hard failure.
- Native resource leaks or context loss could degrade repeated edits; explicit lifecycle ownership, stress tests, memory instrumentation, and context recreation mitigate this.
- GPU setup can make the first render slower; contexts and compiled programs are lazily created once, warm-up is measured, and the unedited image remains visible until the first preview arrives.

### Future extensibility

The renderer contract describes an immutable local render request rather than a platform channel. A future cloud renderer or additional native backend can implement that contract without changing page models, Cubits, routes, or stored documents; this change itself remains fully offline.

### Definition of Done

- Every listed crop and enhancement operation uses the accelerated native backend on compatible Android and iOS devices, with telemetry proving backend selection and no sensitive fields.
- The stated p95 and 3x performance targets pass on the documented Android emulator and iOS Simulator configurations for representative preview and 12-megapixel fixtures, with cold and warm results reported separately. These are project regression gates, not claims about physical-device battery or thermal behavior.
- CPU/GPU fixture comparisons remain within documented visual tolerances and all non-destructive editing, crop, retry, cancellation, and storage behaviors remain unchanged.
- Unsupported devices and injected GPU failures complete successfully through one CPU fallback without partial output or UI-thread pixel work.
- Native unit/stress tests, Dart unit/Cubit/repository/component/golden tests, and the edit integration flow pass through `tool/verify.dart`; virtual-platform verification is reported as incomplete rather than passed if no usable Android emulator or iOS Simulator exists. A physical device is not part of this acceptance gate.
- Public APIs and non-obvious platform/resource trade-offs have current required documentation.
