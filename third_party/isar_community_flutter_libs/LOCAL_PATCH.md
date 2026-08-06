# Local Swift Package Manager patch

The upstream `isar_community_flutter_libs` 3.3.2 package contains an iOS
XCFramework with both device and arm64/x86_64 simulator slices, but it does not
declare Swift Package Manager support.

This local copy adds an SPM manifest and a small Objective-C registration shim
that keeps the static Isar library linked for Dart FFI. It lets Flutter build
the iOS app without CocoaPods while retaining the upstream binaries unchanged.

Remove this override when upstream publishes equivalent Swift Package Manager
support.
