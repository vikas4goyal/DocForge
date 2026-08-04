// swift-tools-version: 5.9

import PackageDescription
import Foundation

// ---------------------------------------------------------------------------
// Permission configuration
//
// Permissions are resolved in priority order:
//   1. Environment variable (e.g. `launchctl setenv PERMISSION_CAMERA 1`
//      or `launchctl setenv PERMISSION_NOTIFICATIONS 0` to explicitly disable)
//   2. Matching key present in the app's Info.plist
//   3. Default: enabled for permissions with no required plist key
//              (PERMISSION_NOTIFICATIONS, PERMISSION_CRITICAL_ALERTS),
//              disabled for all others.
//
// After changing Info.plist or env vars, clear DerivedData once so Xcode
// re-evaluates this manifest:
//   rm -rf ~/Library/Developer/Xcode/DerivedData
// ---------------------------------------------------------------------------

let env = ProcessInfo.processInfo.environment

func loadInfoPlist(at url: URL) -> [String: Any]? {
    NSDictionary(contentsOf: url) as? [String: Any]
}

/// Find the host app's Runner/Info.plist.
///
/// Flutter can resolve this package through a local plugin path, a generated
/// SPM package, or an Xcode package cache. Look for a Flutter app root by
/// walking up from the package and current working directory, using pubspec.yaml
/// next to ios/Runner/Info.plist as the app-root anchor.
func findInfoPlist() -> [String: Any] {
    let fileManager = FileManager.default
    
    let packageDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
    let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    
    var visited = Set<String>()
    
    for root in [packageDir, currentDir] {
        var dir = root

        for _ in 0..<10 {
            let key = dir.resolvingSymlinksInPath().path
            guard visited.insert(key).inserted else {
                break
            }
            
            let pubspecURL = dir.appendingPathComponent("pubspec.yaml")
            let plistURL = dir.appendingPathComponent("ios/Runner/Info.plist")

            if fileManager.fileExists(atPath: pubspecURL.path),
               let plist = loadInfoPlist(at: plistURL) {
                return plist
            }

            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path {
                break
            }
            dir = parent
        }
    }

    return [:]
}

let infoPlist = findInfoPlist()

// ── LOCAL PATCH (not upstream) ─────────────────────────────────────────────
// The permissions DocScanly requests, forced on rather than auto-detected.
//
// Neither mechanism below can work in a Flutter + Swift Package Manager app:
//
//   * findInfoPlist() resolves #file into the pub cache
//     (~/.pub-cache/hosted/pub.dev/permission_handler_apple-<version>/ios/…)
//     and walks upward looking for a directory holding both pubspec.yaml and
//     ios/Runner/Info.plist. The app is not an ancestor of the pub cache, so
//     the search always ends at / having found nothing and infoPlist is empty.
//
//   * The environment variable does not survive `flutter build` — it is not
//     inherited by SwiftPM's manifest evaluation — and `launchctl setenv` is
//     machine state that no checkout or CI runner would carry.
//
// The consequence is silent and severe: every permission falls back to its
// default of disabled, so the strategy is left out of the binary and a request
// returns an answer without iOS ever being asked. No system prompt appears and
// the app never shows up in Settings, because iOS was never told it wanted the
// permission.
//
// Anything added here needs its matching usage description in
// ios/Runner/Info.plist, or App Review will reject the build.
// See third_party/permission_handler_apple/LOCAL_PATCH.md.
let forcedOn: Set<String> = [
    "PERMISSION_CAMERA", // NSCameraUsageDescription — document scanning
    "PERMISSION_PHOTOS", // NSPhotoLibraryUsageDescription — importing images
]

/// Return "1" if the env var is set (non-zero), "0" if explicitly set to "0",
/// else "1" if any Info.plist key is present, else `defaultValue`.
func enabled(_ envKey: String, plistKeys: String..., defaultValue: String = "0") -> String {
    if forcedOn.contains(envKey) { return "1" }
    if let val = env[envKey] { return val == "0" ? "0" : "1" }
    for key in plistKeys where infoPlist[key] != nil { return "1" }
    return defaultValue
}

let permissionDefines: [CSetting] = [
    // dart: PermissionGroup.calendar (< iOS 17)
    .define("PERMISSION_EVENTS",
            to: enabled("PERMISSION_EVENTS",
                        plistKeys: "NSCalendarsUsageDescription")),
    // dart: PermissionGroup.calendarFullAccess (iOS 17+) / PermissionGroup.calendarWriteOnly (iOS 17+)
    .define("PERMISSION_EVENTS_FULL_ACCESS",
            to: enabled("PERMISSION_EVENTS_FULL_ACCESS",
                        plistKeys: "NSCalendarsFullAccessUsageDescription",
                                   "NSCalendarsWriteOnlyAccessUsageDescription")),
    // dart: PermissionGroup.reminders
    .define("PERMISSION_REMINDERS",
            to: enabled("PERMISSION_REMINDERS",
                        plistKeys: "NSRemindersUsageDescription")),
    // dart: PermissionGroup.contacts
    .define("PERMISSION_CONTACTS",
            to: enabled("PERMISSION_CONTACTS",
                        plistKeys: "NSContactsUsageDescription")),
    // dart: PermissionGroup.camera
    .define("PERMISSION_CAMERA",
            to: enabled("PERMISSION_CAMERA",
                        plistKeys: "NSCameraUsageDescription")),
    // dart: PermissionGroup.microphone
    .define("PERMISSION_MICROPHONE",
            to: enabled("PERMISSION_MICROPHONE",
                        plistKeys: "NSMicrophoneUsageDescription")),
    // dart: PermissionGroup.speech
    .define("PERMISSION_SPEECH_RECOGNIZER",
            to: enabled("PERMISSION_SPEECH_RECOGNIZER",
                        plistKeys: "NSSpeechRecognitionUsageDescription")),
    // dart: PermissionGroup.photos / PermissionGroup.photosAddOnly
    // NSPhotoLibraryAddUsageDescription alone also enables PhotoPermissionStrategy because the
    // native code compiles photosAddOnly support under PERMISSION_PHOTOS.
    .define("PERMISSION_PHOTOS",
            to: enabled("PERMISSION_PHOTOS",
                        plistKeys: "NSPhotoLibraryUsageDescription",
                                   "NSPhotoLibraryAddUsageDescription")),
    // dart: PermissionGroup.photosAddOnly
    .define("PERMISSION_PHOTOS_ADD_ONLY",
            to: enabled("PERMISSION_PHOTOS_ADD_ONLY",
                        plistKeys: "NSPhotoLibraryAddUsageDescription")),
    // dart: PermissionGroup.location / locationAlways / locationWhenInUse
    .define("PERMISSION_LOCATION",
            to: enabled("PERMISSION_LOCATION",
                        plistKeys: "NSLocationWhenInUseUsageDescription",
                                   "NSLocationAlwaysAndWhenInUseUsageDescription")),
    // dart: PermissionGroup.locationWhenInUse (only when locationAlways is NOT needed)
    .define("PERMISSION_LOCATION_WHENINUSE",
            to: enabled("PERMISSION_LOCATION_WHENINUSE",
                        plistKeys: "NSLocationWhenInUseUsageDescription")),
    // dart: PermissionGroup.locationAlways
    .define("PERMISSION_LOCATION_ALWAYS",
            to: enabled("PERMISSION_LOCATION_ALWAYS",
                        plistKeys: "NSLocationAlwaysAndWhenInUseUsageDescription")),
    // dart: PermissionGroup.notification (no required Info.plist key — enabled by default)
    .define("PERMISSION_NOTIFICATIONS",
            to: enabled("PERMISSION_NOTIFICATIONS", defaultValue: "1")),
    // dart: PermissionGroup.mediaLibrary
    .define("PERMISSION_MEDIA_LIBRARY",
            to: enabled("PERMISSION_MEDIA_LIBRARY",
                        plistKeys: "NSAppleMusicUsageDescription")),
    // dart: PermissionGroup.sensors
    .define("PERMISSION_SENSORS",
            to: enabled("PERMISSION_SENSORS",
                        plistKeys: "NSMotionUsageDescription")),
    // dart: PermissionGroup.bluetooth
    .define("PERMISSION_BLUETOOTH",
            to: enabled("PERMISSION_BLUETOOTH",
                        plistKeys: "NSBluetoothAlwaysUsageDescription",
                                   "NSBluetoothPeripheralUsageDescription")),
    // dart: PermissionGroup.appTrackingTransparency
    .define("PERMISSION_APP_TRACKING_TRANSPARENCY",
            to: enabled("PERMISSION_APP_TRACKING_TRANSPARENCY",
                        plistKeys: "NSUserTrackingUsageDescription")),
    // dart: PermissionGroup.criticalAlerts (no required Info.plist key — requires Apple entitlement,
    // opt-in via env var: launchctl setenv PERMISSION_CRITICAL_ALERTS 1)
    .define("PERMISSION_CRITICAL_ALERTS",
            to: enabled("PERMISSION_CRITICAL_ALERTS")),
    // dart: PermissionGroup.assistant
    .define("PERMISSION_ASSISTANT",
            to: enabled("PERMISSION_ASSISTANT",
                        plistKeys: "NSSiriUsageDescription")),
]

let package = Package(
    name: "permission_handler_apple",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "permission-handler-apple", targets: ["permission_handler_apple"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "permission_handler_apple",
            dependencies: [],
            path: "Sources/permission_handler_apple",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("strategies"),
                .headerSearchPath("util"),
                .headerSearchPath("include/permission_handler_apple"),
            ] + permissionDefines
        ),
    ]
)
