# iOS Simulator GPU benchmark

- Host: Apple silicon Mac, macOS 26.5.2
- Simulator: iPhone 16 Pro
- Runtime: iOS 18.4, build 22E238
- Graphics: Core Image with a Metal `CIContext`
- Build mode: debug
- Backend proof: `iosCoreImage`; no CPU fallback
- Fixture: 4000×3000 synthetic document, five warmups, 30 warm samples

| Render | Median | p95 | Output | CPU median | Speedup |
|---|---:|---:|---:|---:|---:|
| Preview | 97.6 ms | 106.7 ms | 1400×1022 | 3882.0 ms | 39.8× |
| Full | 325.3 ms | 357.1 ms | 3780×2760 | 12404.1 ms | 38.1× |

Both latency gates and the 3× speedup gate pass. Native output dimensions and
backend identity were asserted by the benchmark. Simulator timings characterize
the host-backed Metal stack; they are not physical-device battery/thermal data.
Sampled RSS rose by 88,424,448 bytes during previews and 11,616,256 bytes during
the following full-resolution sample series.
