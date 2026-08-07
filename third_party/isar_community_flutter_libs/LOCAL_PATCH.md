# Local Swift Package Manager patch

The upstream `isar_community_flutter_libs` 3.3.2 package contains an iOS
XCFramework with both device and arm64/x86_64 simulator slices, but it does not
declare Swift Package Manager support.

This local copy adds an SPM manifest and a small Objective-C registration shim
that keeps the static Isar library linked for Dart FFI. It lets Flutter build
the iOS app without CocoaPods while retaining the upstream binaries unchanged.

The Runner Release xcconfig also force-loads
`$(BUILT_PRODUCTS_DIR)/libisar.a` and disables dead-code stripping.
Referencing a single symbol in the registration shim is not sufficient for a
Release build: the linker otherwise dead-strips the remaining Isar entry points
because Dart FFI resolves them dynamically through `DynamicLibrary.process()`.

Remove this override when upstream publishes equivalent Swift Package Manager
support.
