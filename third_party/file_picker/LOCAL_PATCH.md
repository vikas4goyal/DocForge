# Local compatibility patches

## iOS: document-only Swift package

DocScanly uses `file_picker` for document import, directory selection, and
document export. Gallery import uses `image_picker`, and the app never calls
the file picker's media or audio modes.

Upstream's Swift package nevertheless enables all picker modes and therefore
links `DKImagePickerController` and `DKCamera`. `DKCamera` includes optional
GPS-metadata support that references `CLLocationManager`. App Store Connect
then reports ITMS-90683 and asks for `NSLocationWhenInUseUsageDescription`,
even though the GPS feature defaults to off and DocScanly never enables it.

The local iOS `Package.swift` now compiles only `PICKER_DOCUMENT` and removes
the unused DK dependency. This keeps document/directory/save behavior intact
without linking location APIs or declaring a permission the app does not use.

## Android: AGP 9 compatibility

The upstream `file_picker` 11.0.3 Android build assumes every AGP 9 project
uses Android's built-in Kotlin and therefore skips applying the Kotlin Gradle
plugin. Flutter currently opts this app into its temporary legacy-KGP fallback
because several other plugins still apply KGP. That combination leaves
`FilePickerPlugin.kt` uncompiled.

This local copy applies KGP while that fallback is active and updates its KGP
version to 2.2.20. Remove the override once all Android plugins used by the app
support AGP built-in Kotlin and Flutter no longer adds
`android.builtInKotlin=false`.
