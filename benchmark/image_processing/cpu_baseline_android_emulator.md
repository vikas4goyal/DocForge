# CPU Baseline — Android Emulator

## Run identity

- Date: 2026-08-08
- Backend: `dart_cpu_isolate_reference`
- Host: macOS 26.5.2 (25F84), arm64
- Virtual environment: Android Emulator, AVD `Pixel_9`
- Reported device: `sdk gphone64 arm64`
- Android image: Android 16 / API 36 (`BP22.250325.006`)
- Graphics: hardware rendering reported by Flutter; exact emulator renderer was not captured
- Build mode: debug (`flutter test` integration-test runner)
- Fixture SHA-256: `93b5ec026718b9bcbbd5f71574c7e301f56ef36beb66d5698c46d00967d0014f`
- Tolerance manifest schema/version: 1 / colour pipeline 1

## Method

- Warm-up runs: 5 per render kind
- Measured warm runs: 30 per render kind
- Preview longest edge: 1400 px
- Full-resolution source: 4000 × 3000 (12 MP)
- Pipeline: composed perspective transform, preview scaling where applicable, Magic Colour, brightness 0.12, contrast 0.18, sharpen 0.35, shadow removal, JPEG encode

## Preview results

- Output dimensions: 1400 × 1022
- Warm durations (µs): 4563746, 4587023, 4592738, 4606116, 4630467, 4631225, 4635593, 4644385, 4645253, 4646347, 4649080, 4649523, 4655129, 4656237, 4657471, 4665289, 4669305, 4679762, 4684212, 4685044, 4685046, 4688391, 4692594, 4698778, 4701632, 4711245, 4715712, 4724342, 4735435, 5235919
- Median: 4,665,289 µs
- p95: 4,735,435 µs
- Sampled RSS before/peak/delta: 430,493,696 / 524,783,616 / 94,289,920 bytes
- Visual reference: output decoded successfully at the required preview bound; the CPU output is the parity oracle locked by the tolerance manifest.

## Full-resolution results

- Output dimensions: 3780 × 2760
- Warm durations (µs): 15219706, 15255414, 15275280, 15278330, 15278845, 15289329, 15292380, 15298154, 15303540, 15308485, 15309996, 15315460, 15319191, 15331581, 15345259, 15355661, 15362101, 15377100, 15378519, 15399307, 15419618, 15435361, 15463114, 15463605, 15472099, 15494484, 15530634, 15535868, 15538550, 15804727
- Median: 15,355,661 µs
- p95: 15,538,550 µs
- Sampled RSS before/peak/delta: 376,586,240 / 532,246,528 / 155,660,288 bytes
- Visual reference: output decoded successfully at the requested composed size; the CPU output is the parity oracle locked by the tolerance manifest.

## Notes

These pinned virtual-device measurements are project regression gates. They do
not claim physical-device battery life, thermal behavior, or absolute latency.
The emulator stopped after the memory-intensive benchmark completed, so exact
OpenGL renderer metadata must be captured when running the post-change report.
