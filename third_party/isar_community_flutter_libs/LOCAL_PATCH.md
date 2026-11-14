# Local Swift Package Manager patch

This copy carries the upstream `isar_community_flutter_libs` 3.4.1 binaries.
The fork was made from 3.3.2, which contained an iOS XCFramework with both device
and arm64/x86_64 simulator slices but did not declare Swift Package Manager
support. Upstream 3.4.1 now ships its own Swift Package Manager manifest, but it
builds Isar as a dynamic library, which changes how the Release link below
behaves; adopting it needs a Release device test first.

This local copy adds an SPM manifest and a small Objective-C registration shim
that keeps the static Isar library linked for Dart FFI. It lets Flutter build
the iOS app without CocoaPods while retaining the upstream binaries unchanged.

The Runner Release xcconfig also force-loads
`$(BUILT_PRODUCTS_DIR)/libisar.a`, disables dead-code stripping, and preserves
global symbols when Xcode strips the archived application.
Referencing a single symbol in the registration shim is not sufficient for a
Release build: the linker otherwise dead-strips the remaining Isar entry points
because Dart FFI resolves them dynamically through `DynamicLibrary.process()`.

Remove this override once upstream's Swift Package Manager build is verified in
a Release build on a device. To update the binaries, copy every `libisar.*`,
`isar.xcframework` and `jniLibs` file from the new upstream package and bump the
`isar_community` version in this `pubspec.yaml`.
