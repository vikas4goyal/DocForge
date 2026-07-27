# Vendored fork of `pdf_manipulator` 4.0.0

This is upstream [whuppi/pdf_manipulator](https://github.com/whuppi/pdf_manipulator)
at tag `v4.0.0`, vendored so we can carry one local patch. It is wired in via a
path dependency in the root `pubspec.yaml`.

## Why

`pdf_manipulator`'s PDF engine is a Rust crate (`pdf_oxide`). You normally never
see that: the package's build hook downloads a precompiled binary for your
target platform.

For iOS that download does not exist. Upstream publishes only **static**
archives:

| Platform | Published artifact | Flutter asks for |
| --- | --- | --- |
| Android | `android-*-libpdf_oxide.so` | dynamic ✅ |
| macOS | `macos-*-libpdf_oxide.dylib` | dynamic ✅ |
| iOS | `ios-*-libpdf_oxide.a` (**static only**) | dynamic ❌ |

Flutter requests `link_mode_preference: dynamic` for iOS and enforces it:

```
CodeAsset "package:pdf_manipulator/src/ffi/native_bindings.g.dart" has a
link mode "static", which is not allowed by the input link mode preference
"dynamic"
```

There is no `ios-arm64-libpdf_oxide.dylib` release asset, so the stock hook
falls through to compiling the Rust engine from source and fails with:

```
This build needs to compile the PDF engine from source (a trimmed feature set
has no prebuilt binary), but Rust is not installed.
```

(That message is a fixed string and is misleading — no feature set is trimmed
here. The real cause is the 404 on the dylib.)

Compiling from source would mean **every** machine that builds iOS needs a Rust
toolchain — `rust-version = "1.88"` — plus network access to fetch the 610
crates in `Cargo.lock`, and the compile time to build them, on every CI agent
and every developer Mac.

Upstream had this right once: their changelog references commit
`28daa58 hook: use StaticLinking for iOS`. That override is absent from 4.0.0,
so this is a regression. 4.0.0 is the latest release, so there is no upgrade out.

## What the patch does

The static `.a` already contains the compiled machine code — upstream simply
never published it in dynamic form. So the hook now, **for iOS only**:

1. Resolves `ios-*-libpdf_oxide.a` through upstream's normal, **hash-verified**
   download waterfall (unchanged — the pinned SHA-256 in `asset_hashes.dart`
   is still checked).
2. Relinks it into a dylib with `clang -dynamiclib -Wl,-all_load`.
3. Registers that as the dynamic code asset.

`-all_load` matters: the FFI entry points have no references *inside* the
library — Dart looks them up by name at runtime — so without it the linker
would drop them.

Every machine that builds iOS already has Xcode, so this introduces no new
tooling. **No Rust is required anywhere**, including CI.

Verified on device (iPhone, iOS 26.5):

```
PDF ENGINE IO MODE: PdfIoMode.native
PDF PAGE COUNT: 1
```

See `integration_test/pdf_engine_smoke_test.dart`.

## Changes from upstream

- `hook/build.dart` — added the iOS branch in `_resolveNative` plus
  `_resolveIosDylibFromStatic` / `_relinkStaticToDylib`. Both are marked
  `LOCAL PATCH (not upstream)`.
- Deleted `vendor/` (55MB of Rust source), `example/`, `example_trimmed/`,
  `test/`, `tool/`, `docs/`, `deploy/` — we ship a prebuilt binary, so the
  engine source is dead weight.

Deleting `vendor/` also means `hasVendorSource()` is now false, so a failed
download on any platform is a hard, explicit error instead of a silent
from-source compile. That is the behaviour we want here.

Nothing in `lib/` was modified, so the Dart API is stock 4.0.0.

## Reverting

When upstream publishes `ios-*-libpdf_oxide.dylib`, this whole directory can be
deleted and the root `pubspec.yaml` restored to:

```yaml
  pdf_manipulator: ^4.0.0
```

Upstream issue: not yet filed at time of writing — there was no open issue
covering the missing iOS dynamic artifact.
