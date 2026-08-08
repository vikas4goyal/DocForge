# CPU Baseline — iOS Simulator

## Run identity

- Date: 2026-08-08
- Backend: `dart_cpu_isolate_reference`
- Host: macOS 26.5.2 (25F84), arm64
- Virtual environment: iOS Simulator, iPhone 17 Pro (`8DB1E399-20B8-4672-9C94-1F4210CD218F`)
- iOS runtime: 26.5 (`23F77`)
- Graphics: Simulator host graphics; CPU reference performs no GPU pixel transforms
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
- Warm durations (µs): 3817663, 3829704, 3832075, 3837898, 3840956, 3846716, 3859869, 3868845, 3870125, 3870252, 3870459, 3872825, 3875894, 3876165, 3877764, 3881959, 3882857, 3886663, 3886725, 3886867, 3887040, 3887581, 3891651, 3892199, 3902184, 3912597, 3947926, 3958000, 3964888, 4000954
- Median: 3,881,959 µs
- p95: 3,964,888 µs
- Sampled RSS before/peak/delta: 479,281,152 / 697,827,328 / 218,546,176 bytes
- Visual reference: output decoded successfully at the required preview bound; the CPU output is the parity oracle locked by the tolerance manifest.

## Full-resolution results

- Output dimensions: 3780 × 2760
- Warm durations (µs): 12296588, 12318687, 12319519, 12332654, 12333836, 12335024, 12339818, 12352516, 12365906, 12370350, 12371285, 12373009, 12388048, 12395788, 12400911, 12404061, 12419348, 12421287, 12428867, 12444566, 12453636, 12473559, 12475062, 12478388, 12488122, 12566539, 12632140, 12651598, 12665364, 13052646
- Median: 12,404,061 µs
- p95: 12,665,364 µs
- Sampled RSS before/peak/delta: 621,707,264 / 762,576,896 / 140,869,632 bytes
- Visual reference: output decoded successfully at the requested composed size; the CPU output is the parity oracle locked by the tolerance manifest.

## Notes

These pinned virtual-device measurements are project regression gates. They do
not claim physical-device battery life, thermal behavior, or absolute latency.
