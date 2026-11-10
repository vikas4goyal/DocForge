# Proposal

## Why

Several Settings controls look configurable but do not reliably change what the app does. An audit of the code found:

| Setting | Observed today | Verdict |
| --- | --- | --- |
| PDF quality | `SettingsChoiceTile` opens a bottom sheet listing 71 radio rows (30%…100%). The value seeds `SavePdfCubit` via `initialQuality`, and `generated_pdf_candidate_job.dart` scales and JPEG-encodes pages from it. | **Works**, but the control is unusable. It should be a slider. |
| Camera resolution | `ScanCaptureCubit` resolves the preference and `CameraScannerRepository.initialise` maps it to a `ResolutionPreset`. However: (a) `CapturePage.call` skips re-initialising when the camera is already open, so a changed preference is ignored until the camera is closed; (b) `resolutionPresetFor` maps 2K **and** 4K to `ultraHigh`, so choosing "2K" can capture 4K; (c) the probe measures `previewSize`, not the still-photo size, so advertised dimensions may not match captured files. | **Partly cosmetic** |
| Default file naming | `suggestName` → `generateName(currentSettings.value.namingPattern)` → `SavePdfScreen.initialName`. | **Works** (only as long as propagation below works) |
| Default save location | Persisted and shown, but `ShareOptionsSheet` is built in `viewer_screens.dart` without `initialDirectory`. Even if it were passed, the stored value is a plain filesystem path, while `file_picker` expects a `content://` URI on Android (`EXTRA_INITIAL_URI`) and an absolute URL string on iOS (`URLWithString`). | **Cosmetic** |
| Live propagation of all of the above | `currentSettings.value = …watch<SettingsCubit>().state.settings` is assigned inside a `build` method in `settings_screens.dart`. This is a side effect during build, and it publishes `AppSettings.defaults` while the cubit is still loading or has failed. | **Fragile:** can silently revert creation-time settings to their defaults |
| Recognition language (OCR) | Required by the `app-settings` and `ocr` specs, but absent from the Settings screen. `DocumentPageOcrTextSource`, which would read it, is never constructed. | **Dead**. The user decided to remove it. |

Users see their choices "take" in Settings, but captures, exports and saves do not always honour them. That breaks the existing `app-settings` requirement that every setting "SHALL take effect immediately".

## What Changes

- **PDF quality control becomes a slider.** Replace the 71-option choice sheet with an inline Material 3 slider on the Settings screen (30–100%, step 1%, with a live % label and the existing size/fidelity description). It persists when the drag ends, not on every tick.
- **Settings propagate through the domain, not through `build`.** Introduce a `SettingsSnapshot` contract in `core/contracts`, backed by the settings repository. The repository publishes each successfully persisted value. Creation, scanning, Save PDF and sharing read it through injected functions. The assignment inside `build` is removed. A failed or loading cubit can never overwrite the published values.
- **Camera resolution is actually applied.**
  - The capture use case re-resolves the preference before every capture. It re-initialises the camera when the resolved resolution differs from the one it is open at.
  - Each supported resolution carries the plugin preset that produced it, so the camera opens with the measured preset rather than one derived from the tier. 2K can no longer capture 4K.
  - The `camera` plugin exposes no still-capture size before the shutter fires, so probing keeps `previewSize` as an *estimate*.
  - After each capture, the real pixel size is decoded from the file header. The scanning status shows that real size and never claims a tier the photo did not meet.
- **Default file naming is verified end to end.** The behaviour already exists. This change adds the missing proof: a Tier-3 assertion that changing the pattern in Settings changes the prefilled name on the next Save PDF screen without a restart.
- **Default save location works.**
  - The viewer share sheet passes the configured location to Export.
  - The stored folder is converted into the form each platform's picker accepts: an Android tree URI, or an iOS `file://` URL.
  - Settings labels the value honestly as the folder exports *start in*.
  - When the platform cannot honour it, exports still complete with the picker's own default, with no error.
- **BREAKING (settings surface): Recognition language removed.**
  - Delete the `OCR language setting` requirement and the `settings_ocr_language*` keys from the spec.
  - Remove the `OcrScript` selection plumbing: the `script` parameters, `available()`/`install()`, and the unused `DocumentPageOcrTextSource._script` supplier.
  - Recognition runs with one fixed script, so no language choice is offered anywhere.
- **BREAKING (scope added 2026-11-10 by user decision): OCR removed entirely.** Implementation showed the whole `ocr` feature was dead code. It had no screen, no recogniser, no registered database table and no consumer. It is now removed along with:
  - `OcrTextSource`/`OcrSearchIndex`, `Failure.ocr` and `RecognisedText`
  - the `Document.hasRecognisedText` field (Isar ignores the removed property; there is a fixture test against a database written by the old schema)
  - the always-empty searchable-PDF text layer (`BuildSearchablePdf` → `BuildPdf`)
  - embedded PDF text extraction
  - search's recognised-text match source and snippets
  - every user-visible claim about recognised text

  The `ocr` capability is retired, and `document-search` becomes title-only.
- Spec cleanup: the Settings screen requirement no longer lists `settings_ocr_language` or the obsolete `settings_image_quality` key. The camera tile is `settings_camera_resolution`.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `app-settings`: Settings entries (OCR language and obsolete image-quality key removed, camera-resolution key named). PDF quality is presented as a slider. Settings take effect for creation, capture and export without a restart and without the Settings tab being open. Camera resolution is honoured by an already-open camera, and the presets it uses are faithful to the tier. The default save location is used by export. The OCR language setting requirement is removed.
- `document-sharing`: Export offers the configured default save location as the picker's starting destination, degrading gracefully where the platform ignores it.
- `ocr`: Retired. Every requirement is REMOVED, because OCR was never shipped and is now deleted.
- `document-search`: “Search by title and recognised text” is replaced by “Search by title”.
- `document-sharing`, `document-library`, `recoverable-trash`, `public-document-storage`, `app-security`, `image-enhancement`, `document-import`, `onboarding`, `automated-verification`: references to OCR or recognised text are removed from their requirements.

## Impact

**Architecture and folders touched** (no feature-to-feature imports are introduced; the dependency direction stays presentation → application → domain ← infrastructure):

```
lib/core/contracts/
  settings_snapshot.dart              (new: read-only contract + listenable)
lib/features/app_settings/
  presentation/widgets/settings_widgets.dart   (+ SettingsSliderTile)
  presentation/screens/settings_screen.dart    (slider; save-location copy)
  presentation/settings_keys.dart              (+ pdfQualitySlider)
  application/usecases/settings_usecases.dart  (publish on successful write)
  infrastructure/repositories/preference_settings_repository.dart
lib/features/document_sharing/
  infrastructure/export_start_location.dart     (new: platform URI normaliser)
lib/core/contracts/models/camera_resolution.dart  (SupportedCameraResolution + requestKey)
lib/features/document_scanning/
  application/usecases/scanning_usecases.dart  (re-resolve per capture)
  infrastructure/camera_scanner_repository.dart, camera_plugin_capability_repository.dart (cache + requestKey)
lib/features/document_sharing/presentation/…   (no change in shape; receives value)
lib/features/ocr/{domain,application,infrastructure}  (script plumbing removed)
lib/core/contracts/models/settings_values.dart (OcrScript removed)
lib/app/doc_scanly.dart, screens/settings_screens.dart, screens/viewer_screens.dart
```

- **Cubits / States:** `SettingsCubit` gains `previewPdfQuality(int)` (drag, not persisted) and keeps `setPdfQuality` (commit). `SettingsState` gains `pdfQualityDraft`. `ScanCaptureState` gains `capturedDimensions`. No new Cubits.
- **Use cases:** `UpdateSettings` publishes to the snapshot after a successful write. `CapturePage` re-resolves the resolution on each call. `ExportDocument` receives a normalised initial destination. The OCR use cases lose their `script` parameter.
- **Repositories:** `SettingsRepository` exposes `SettingsSnapshot`. `ScannerRepository.initialise` takes the measured preset. `OcrRepository` loses `available()` and `install()`.
- **Isar schema:** no change. `RecognisedText.languageTag` is retained and written with the fixed script tag to avoid a migration.
- **Navigation:** no route changes. The Recognition-language route was never implemented, so there is nothing to delete.
- **Stored preference keys:** `settings.pdfQuality.v2`, `settings.cameraResolution.v1`, `settings.fileNamingPattern` and `settings.defaultSaveLocation` are unchanged.
  - The camera preference stays tier-only (`DesiredCameraResolution`). The measured plugin request lives only on the runtime `SupportedCameraResolution`, so no stored data migrates.
  - `settings.defaultSaveLocation` keeps holding whatever the folder picker returned. Normalisation into a picker URI happens at read time, so existing values keep working.
  - No secure-storage keys change.
- **Dependencies:** none added or changed. `camera` and `file_picker` are used as already pinned.

**Performance:** The slider rebuilds only its own tile, through `BlocSelector`, and writes once per drag. Camera re-initialisation happens only when the resolution actually differs, so there is no per-shutter cost in the common case. Decoding captured dimensions reads only the image header in the existing background worker.

**Security:** No sensitive data is involved. The save-location value is a user-chosen folder path in SharedPreferences, as today. No PII and no secrets.

**Testing strategy:**
- Tier 1: snapshot publication, preset mapping, the URI normaliser, the `CapturePage` re-initialise rules, `SettingsCubit` slider states (bloc_test), migration of legacy camera JSON, and the OCR API without a script.
- Tier 2: the Settings component test for the slider, a Save PDF component test reading the snapshot, a share-sheet export component test, and a camera-resolution component test.
- Tier 3: update `settings_and_app_lock_test.dart` and the capture-to-document and share flows.
- Goldens: update the Settings golden.

**Previews:** `SettingsSliderTile` gets default, disabled/loading, error, long-description, light and dark previews. The Settings screen previews are refreshed for phone/tablet × light/dark plus the states that already exist.

**Risks and mitigations:**
- Plugins can silently capture a size other than the one requested. Mitigation: show the decoded actual size and never claim a tier that was not met.
- The iOS document picker may still ignore `directoryURL` for security-scoped locations. Mitigation: treat the location as a best-effort start folder, word the label honestly, and verify on an Android emulator plus the iOS Simulator.
- Removing the OCR script API is a breaking change for internal callers. Mitigation: everything is in-repo, and the analyzer surfaces every call site.

**Future extensibility:** `SettingsSnapshot` is the single read model that a future cloud-synced settings repository can publish to. Consumers will not change.

**Platforms:** Android and iOS only. No web or desktop code paths are added. `file_picker`'s desktop branches are not relied on.

**Definition of Done:**
- Every row in the audit table reads "Works", proven by Tier-1, Tier-2 and Tier-3 tests that observe the effect rather than the stored value.
- The Recognition-language code and spec are gone.
- dartdoc is updated.
- `tool/verify.dart` passes every stage with Tier 3 executed, not skipped.
