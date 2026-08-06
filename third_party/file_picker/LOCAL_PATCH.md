# Local AGP 9 compatibility patch

The upstream `file_picker` 11.0.3 Android build assumes every AGP 9 project
uses Android's built-in Kotlin and therefore skips applying the Kotlin Gradle
plugin. Flutter currently opts this app into its temporary legacy-KGP fallback
because several other plugins still apply KGP. That combination leaves
`FilePickerPlugin.kt` uncompiled.

This local copy applies KGP while that fallback is active and updates its KGP
version to 2.2.20. Remove the override once all Android plugins used by the app
support AGP built-in Kotlin and Flutter no longer adds
`android.builtInKotlin=false`.
