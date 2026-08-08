# Image Processing Benchmark Report

## Run identity

- Date/time (UTC):
- Commit:
- Backend: `dart_cpu_isolate_reference` / `ios_core_image` / `android_gles` / `cpu_fallback`
- Host hardware/OS:
- Virtual environment: Android emulator / iOS Simulator
- Emulator profile or Simulator model:
- Android system image or iOS runtime:
- Graphics backend:
- Build mode: release/profile/debug
- Fixture SHA-256:
- Tolerance manifest schema/version:

## Method

- Cold runs:
- Warm-up runs: 5
- Measured warm runs: 30
- Preview longest edge: 1400 px
- Full-resolution source: 4000 × 3000 (12 MP)
- Other running workloads:

## Preview results

- Output dimensions:
- Cold duration(s):
- Warm durations (µs, all 30):
- Median:
- p95:
- Sampled RSS before/peak/delta:
- Backend proof/log excerpt:
- Visual-parity result:

## Full-resolution results

- Output dimensions:
- Cold duration(s):
- Warm durations (µs, all 30):
- Median:
- p95:
- Sampled RSS before/peak/delta:
- Backend proof/log excerpt:
- Visual-parity result:

## Repeated-preview resource observations

- Duration/load pattern:
- Host load before/after:
- Graphics/process resource trend:
- Memory trend after 100 renders:
- Cancellation/latest-wins behavior:

## Acceptance

- Preview p95 ≤ 200 ms: pass/fail/not applicable to CPU baseline
- Full-resolution p95 ≤ 1.5 s: pass/fail/not applicable to CPU baseline
- Median speedup over same-device CPU ≥ 3×: pass/fail/pending
- Output within immutable tolerance manifest: pass/fail
- No unexpected fallback: pass/fail

## Notes and limitations

These pinned virtual-device measurements are project regression gates. They do
not claim physical-device battery life, thermal behavior, or absolute latency.
