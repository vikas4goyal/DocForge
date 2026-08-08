# Android emulator GPU benchmark

- Host: Apple silicon Mac, macOS 26.5.2
- Virtual device: Pixel 9 / sdk gphone64 arm64
- OS image: Android 16, API 36, build BP22.250325.006
- Graphics: gfxstream / ANGLE / SwiftShader OpenGL ES 3.1
- Build mode: debug
- Backend proof: `androidOpenGl`; no CPU fallback
- Fixture: 4000×3000 synthetic document, five warmups, 30 warm samples

| Render | Median | p95 | Output | CPU median | Speedup |
|---|---:|---:|---:|---:|---:|
| Preview | 67.4 ms | 71.8 ms | 1400×1022 | 4665.3 ms | 69.2× |
| Full | 415.5 ms | 490.2 ms | 3780×2760 | 15355.7 ms | 37.0× |

Both latency gates and the 3× speedup gate pass. Native output dimensions and
backend identity were asserted by the benchmark. Emulator timings characterize
this virtual graphics stack; they are not physical-device battery/thermal data.
Sampled RSS rose by 42,176,512 bytes during previews and remained flat during
the following full-resolution sample series.
