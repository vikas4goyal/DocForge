# Vendored fork of `permission_handler_apple` 9.4.10

Upstream `permission_handler_apple` 9.4.10, vendored to carry one local patch,
wired in through `dependency_overrides` in the root `pubspec.yaml`.

## Why

iOS permission prompts never appeared. Requesting camera access returned
"denied" immediately, and DocForge never showed up in iOS Settings with a
camera toggle — because iOS had never been asked, so it had nothing to list.

The cause is not in our Dart code. `PluginPermissionService.request()` calls
`Permission.camera.request()`, exactly as upstream's own example does. The
problem is one layer below: **the camera strategy was not compiled into the
binary at all.**

`PermissionHandlerEnums.h` defaults every permission to off:

```c
#ifndef PERMISSION_CAMERA
    #define PERMISSION_CAMERA 0
#endif
```

and `AudioVideoPermissionStrategy.m` is wrapped in
`#if PERMISSION_CAMERA | PERMISSION_MICROPHONE`. With the macro at 0 the class
does not exist, so `PermissionManager` cannot dispatch to it and answers
without ever consulting iOS.

Upstream offers two ways to set those macros. **Neither works in a Flutter app
using Swift Package Manager**, which this app must use — `receive_sharing_intent`
is SPM-only, so CocoaPods is not an option:

1. **Info.plist auto-detection.** `Package.swift` calls `findInfoPlist()`, which
   resolves `#file` and walks *upward* looking for a directory containing both
   `pubspec.yaml` and `ios/Runner/Info.plist`. Under SPM, `#file` resolves into
   the pub cache:

   ```
   ~/.pub-cache/hosted/pub.dev/permission_handler_apple-9.4.10/ios/permission_handler_apple/
   ```

   The app is not an ancestor of the pub cache. The walk finds the *package's*
   `pubspec.yaml` (which has no `ios/Runner/Info.plist` beside it), keeps going,
   and ends at `/` having found nothing. `infoPlist` is empty, so every
   permission falls through to its default of disabled.

   Adding `NSCameraUsageDescription` is still **required** — iOS refuses the
   permission without it — but it cannot switch the macro on by itself.

2. **Environment variable.** Verified not to survive `flutter build`: SwiftPM's
   manifest evaluation does not inherit it, even with both
   `~/Library/Developer/Xcode/DerivedData` and
   `~/Library/Caches/org.swift.swiftpm/manifests` cleared first. Upstream's
   documented fallback is `launchctl setenv`, which is machine state no
   checkout or CI runner carries.

The failure is silent: the build succeeds and the Dart call returns a plausible
`denied`, so nothing points at the native layer.

## What the patch does

`ios/permission_handler_apple/Package.swift` gains a `forcedOn` set, checked
first in `enabled()`, listing the permissions this app requests. Everything
else keeps upstream's behaviour.

Verified in the compiler flags of a clean build:

```
PERMISSION_CAMERA=1
PERMISSION_PHOTOS=1
PERMISSION_MICROPHONE=0, PERMISSION_LOCATION=0, PERMISSION_CONTACTS=0, ...
```

Only these two are on. That matters for App Review: every enabled permission
compiles in a strategy that review expects a matching usage description for, so
enabling extras invites rejection.

## Adding a permission later

1. Add its macro to `forcedOn` in `Package.swift` (names are listed in
   `Sources/permission_handler_apple/PermissionHandlerEnums.h`).
2. Add the matching `NS*UsageDescription` to `ios/Runner/Info.plist`.

Both are required. The macro alone compiles in a strategy iOS will refuse; the
usage description alone leaves the strategy out of the binary.

## Changes from upstream

- `ios/permission_handler_apple/Package.swift` — added `forcedOn` and its check
  at the top of `enabled()`, marked `LOCAL PATCH (not upstream)`.
- Deleted `example/`.

No source under `Sources/` was modified, so the plugin's behaviour is stock
9.4.10.

## Reverting

Delete this directory and drop the `permission_handler_apple` entry from
`dependency_overrides` once upstream can resolve the app's Info.plist under
SPM, or exposes a configuration hook that survives `flutter build`.
