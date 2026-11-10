# Design

## Context

See `proposal.md` → Why for the audit. These code facts shape the approach:

- **How settings reach consumers.** `lib/app/doc_scanly.dart` creates `currentSettings = ValueNotifier<AppSettings>(await settings.load())`. It passes closures (`() => currentSettings.value.namingPattern`, `.cameraResolution`, `.pdfQuality`) into the creation, scanning and Save PDF modules. The only writer is `settings_screens.dart`, which assigns `currentSettings.value = context.watch<SettingsCubit>().state.settings` inside `build`. That assignment runs while the cubit is `loading` (state holds `AppSettings.defaults`) and after a failed write.
- **PDF quality.** It is already a real `PdfQualityPercent` (30–100) and already drives `SavePdfCubit` → `generated_pdf_candidate_job.dart` (`scaleDimension` + `encodeJpg(quality: value.clamp(30, 95))`). Only the Settings control is wrong: `SettingsChoiceTile<PdfQualityPercent>` builds 71 options.
- **Camera resolution.**
  - The preference is stored tier-only as `DesiredCameraResolution`.
  - `ResolveCaptureResolution` calls `LoadCameraResolutions`, which runs the probe *every time*. `FlutterCameraPresetProbe` opens three `CameraController`s in sequence and reads `previewSize`.
  - `resolutionPresetFor` maps the tier back to a preset: 720p→high, 1080p→veryHigh, anything else→ultraHigh. So 2K and 4K collide.
  - `CapturePage.call` only initialises when `!_scanner.isReady`.
- **Save location.**
  - `settings.defaultSaveLocation` holds the string returned by `FilePicker.getDirectoryPath()`: a filesystem path on both platforms.
  - `PlatformShareRepository.export` forwards `initialDirectory` to `FilePicker.saveFile`.
  - On Android the plugin does `initialDirectory.toUri()` → `EXTRA_INITIAL_URI`, which only works with a `content://` document or tree URI.
  - On iOS it does `[NSURL URLWithString:]` → `directoryURL`, which needs a `file://` URL string.
  - `viewer_screens.dart` never passes a value at all.
- **OCR script.** `OcrScript` lives in `core/contracts/models/settings_values.dart`. It threads through `OcrRepository.recognise(script:)`, `available()`, `install()`, `RecogniseDocument`, `RecognisePage` and `DocumentPageOcrTextSource._script`. In `lib/`, only `FakeOcrRepository` implements the interface.

## Goals / Non-Goals

**Goals:**
- Give the rest of the app one read model of the *persisted* settings, updated only by successful writes.
- Make every audited setting observably change its workflow, and prove each in all three test tiers.
- Remove recognition-language plumbing without touching stored OCR data.

**Non-Goals:**
- Adding a production OCR recogniser. Only a fake implements `OcrRepository` today, and that is out of scope.
- Deleting `DocumentPageOcrTextSource`, which is unused in `lib/`. Only its script supplier is removed.
- Guaranteeing that the iOS or Android picker *lands* in the chosen folder. The platforms treat it as a hint, and the spec wording reflects that.
- Changing Compress PDF's independent 80% default.

## Decisions

### D1. Settings read model owned by the repository, not by a widget
`SettingsRepository` (domain interface, `features/app_settings/domain/repositories/`) gains:

```dart
/// The last successfully persisted settings; never a loading placeholder.
AppSettings get current;
/// Emits [current] after each successful write. Broadcast, never errors.
Stream<AppSettings> get changes;
```

- `PreferenceSettingsRepository` updates `current` and emits only after `SharedPreferences` confirms a write. `load()` primes `current`.
- The composition root awaits `load()` before building modules, exactly as it awaits `settings.load()` today, so `current` is never a placeholder.
- The closures in `doc_scanly.dart` change from `currentSettings.value.x` to `settingsRepository.current.x`.
- The `ValueNotifier` and the build-time assignment in `settings_screens.dart` are deleted.
- `ThemeModeController` keeps using the existing `onThemeChanged` callback, which already works.

*Alternatives:*
- (a) Keep the `ValueNotifier` but write it from a `BlocListener`. Rejected: Settings would still have to be mounted for creation to see changes, and a widget would still own app-wide state.
- (b) A `core/contracts` `SettingsSnapshot` consumed by features. Rejected: consumers already receive narrow typed closures from the root, which keeps features unaware of settings. Adding a contract adds surface for no gain.

The instance is constructed once in the composition root and injected, so there is no static or global state.

### D2. PDF quality slider: draft in state, commit on drag end
- Add a `SettingsSliderTile` to `presentation/widgets/settings_widgets.dart`: title, live “N%” trailing label, description, and an M3 `Slider` (`min: 30, max: 100, divisions: 70`, `Key('settings_pdf_quality_slider')`, `semanticFormatterCallback` → “Default PDF quality, N percent”).
- The tile keeps `Key('settings_pdf_quality')` on its outer container.
- `SettingsState` gains `int? pdfQualityDraft`, listed in `props`.
- The cubit gets these transitions:
  - `previewPdfQuality(int)` → `ready(draft: n)`. In-memory only.
  - `setPdfQuality(PdfQualityPercent)`, called from `onChangeEnd`, follows `ready(draft)` → (write ok) `ready(settings', draft: null)`, or (write failed) `failure(settings unchanged, draft: null)`.
- The cubit holds no business rule. Range validation stays in `PdfQualityPercent`, and the write goes through the existing `UpdateSettings` use case.
- The tile rebuilds through `BlocSelector<SettingsCubit, SettingsState, (int, int?)>`, so dragging does not rebuild the whole list.

*Alternative:* write on every `onChanged`. Rejected: 70 SharedPreferences writes per drag, and racing failure banners.

### D3. Camera: cached capabilities, opaque request key, re-resolve per capture
- **Cache.** `CameraPluginCapabilityRepository` memoises the probe result per camera (`CameraDescription.name`) for the life of the instance. `loadActiveResolutions({bool refresh = false})` bypasses the cache, and Settings' Retry uses `refresh: true`. This makes per-capture re-resolution cheap. It also guarantees the probe never opens extra controllers while the capture controller is open, because the first resolve always happens before the first `initialise`.
- **Request key.** `SupportedCameraResolution` (core contract, Freezed) gains `String? requestKey`: an opaque infrastructure token, here the `ResolutionPreset.name` that produced the measurement. The domain treats it as opaque. `resolutionPresetFor` becomes `ResolutionPreset.values.byName(resolution.requestKey)` when present, and falls back to the current tier mapping when absent. This fixes 2K→ultraHigh, since the measured 2K preset (often `veryHigh` on 1440p sensors, or whichever preset measured 1440×2560) is replayed exactly.
- **Full means full.** Found during implementation: the probe measured only `high`, `veryHigh` and `ultraHigh`, so “Full resolution” could never request more than 2160p, even on a 12 MP sensor. The probe now also measures `ResolutionPreset.max`, and each tier keeps its *largest* measurement rather than its smallest. As a result, Full, which resolves to the highest entry, replays `max`. Lower tiers are unaffected, because each measurement still maps to the single highest tier it satisfies.
- **Re-resolve.** `CapturePage.call` always calls `initialise(desired)` when a resolver is configured. `CameraScannerRepository.initialise` already returns early when `isReady && _requestedResolution == resolution`, so an unchanged preference costs one cached lookup and the camera is never torn down.
- **Actual size.** `CaptureResult` and `CapturedPage` gain `int width, int height`. `CameraScannerRepository.capture` reads them with `ui.ImmutableBuffer.fromFilePath` + `ui.ImageDescriptor.encoded`, which reads the header only and never decodes pixels. `ScanCaptureState` gains `capturedWidth`/`capturedHeight`, and `resolutionLabel` prefers them: “Captured 2560 × 1440” or “4K requested, captured 3264 × 2448”.
- **Preview fidelity.** `previewSize` remains the advertised estimate. The Settings option copy reads “about W × H” only when the measured key came from preview, which is always the case today. The spec's honesty requirement is met by the post-capture label.

*Alternatives:*
- Add `camerawesome` or a native still-size channel. Rejected: a new dependency, more native code, and Android/iOS divergence.
- Probe on every capture. Rejected: it opens three controllers while one is already open.

### D4. Export start location normalised in sharing infrastructure
- `ExportDocument` (sharing application) takes an injected `String? Function() defaultLocation` from the composition root (`() => settingsRepository.current.saveLocation`). It passes the value to `ShareRepository.export(initialDirectory:)`.
- `ShareCubit.export` and `ShareOptionsSheet` lose their `initialDirectory` parameters. The value is read at export time, so no share surface can forget it. That omission is exactly the cause of today's bug.
- New `infrastructure/export_start_location.dart` converts the raw stored value into what each platform's picker accepts:
  - **Android:** `/storage/emulated/0/<rel>` → `content://com.android.externalstorage.documents/document/primary%3A<rel-encoded>`. Other volumes `/storage/<UUID>/<rel>` → `…/document/<UUID>%3A<rel>`. Values that are already `content://` pass through. Anything else → `null`.
  - **iOS:** an absolute path → `Uri.directory(path).toString()` (`file:///…/`). A `file://` value passes through.
  - Non-existent directories → `null`. On iOS this is checked with `Directory.existsSync()`. On Android the check is skipped, because scoped storage hides existence and the picker falls back by itself.
- The platform is injected as a constructor value (`TargetPlatform`) so the normaliser is a pure, unit-testable function. Platform channel errors from `saveFile` with a bad hint are caught. The export is then retried once with `initialDirectory: null` before any failure is reported.
- In Settings, the value label shows the last path segment (for example, “Downloads”) and the subtitle reads “Exports start in this folder”.

*Alternative:* re-pick with `FilePicker.getDirectoryPath` and persist a `content://` URI directly. Rejected: the plugin returns a resolved path rather than the tree URI, so there is nothing better to store.

### D5. OCR script removal — superseded by D6
- Delete `OcrScript` from `settings_values.dart`.
- Add `const ocrLanguageTag = 'la'` to `features/ocr/domain/` (OCR rules), documented as the bundled Latin recogniser's tag.
- `OcrRepository.recognise` drops `script`. `available()` and `install()` are deleted. `RecognisePage`, `RecogniseDocument` and `DocumentPageOcrTextSource` drop their script parameters, and `FakeOcrRepository` writes `languageTag: ocrLanguageTag`.
- The Isar `RecognisedText.languageTag` field is unchanged, so no schema migration is needed.

### D6. Remove OCR entirely (user decision during implementation)
OCR was unreachable: nothing outside `lib/features/ocr` imported it, `OcrTextEntitySchema` was absent from the production `Isar.open`, the searchable-PDF lookup was `(_) async => const {}`, and `MatchSource.recognisedText` was never produced. The removal is a deletion, not a rewrite:
- **Deleted:** `lib/features/ocr/`, `OcrTextSource`, `OcrSearchIndex`/`OcrIndexHit`, `Failure.ocr`, `RecognisedText`/`TextBlock`/`NormalisedRect`, `DocumentPageAccessRepository.embeddedText` with its pdfrx extractor, and the PDF text layer (`PdfPageSpec.textBlocks`, `PdfBuildRequest.isSearchable`, `ComposedPdf.hasTextLayer`, the invisible-text drawing).
- **Search:** `SearchResult` is now just a document. `MatchSource`, snippets and `SearchRules.merge` are removed.
- **Isar:** removing `DocumentEntity.hasRecognisedText` is a compatible change, because Isar ignores unknown stored properties. `test/fixtures/isar/document_with_recognised_text_flag.isar.gz` is a database written by the previous schema, and `legacy_schema_compat_test.dart` proves it still opens and reads.
- **Copy:** the delete dialog, iCloud storage/migration screens and onboarding no longer mention recognised text.
- **Coverage:** business-logic coverage had dropped because the OCR files were counted once a test imported them. Deleting the dead code, rather than testing it, restores the gate honestly.

### Dependency direction (no feature-to-feature coupling)

```
lib/app (composition root)
  ├─ settingsRepository.current ─▶ closures ─▶ document_scanning / pdf_generation / document_creation / document_sharing (application)
  └─ owns PreferenceSettingsRepository (app_settings infrastructure)
features/*/presentation ─▶ application ─▶ domain ◀─ infrastructure
core/contracts/models (camera_resolution, pdf_quality, settings_values) ◀─ all features
```

No feature imports `app_settings`. The sharing and scanning features see only closures and `core/contracts` types.

### Freezed / JSON
- `SupportedCameraResolution` adds `String? requestKey` with `@JsonKey(includeIfNull: false)`. It is never persisted today, but it stays JSON-safe.
- `CaptureResult`/`CapturedPage` add `width`/`height`. Regenerate with `build_runner`. No manual JSON.

### Navigation
No route changes. The camera-resolution and save-location screens keep their existing pushes.

### Keys and semantics (added to `settings_keys.dart`)
| Element | Key | Semantics |
| --- | --- | --- |
| PDF quality tile | `settings_pdf_quality` (existing) | “PDF quality, N%” |
| PDF quality slider | `settings_pdf_quality_slider` (new) | “Default PDF quality, N percent” |
| Capture status | `scan_camera_resolution_status` (existing) | label text as displayed |
| Removed | `choiceOption` usages for PDF quality | — |

The `SettingsRobot` gains `setPdfQuality(int)`, which drags to the value's fractional offset and then verifies the label. Any `settings_ocr_language*` references are removed. None exist today in robots or flows.

### Previews
- `SettingsSliderTile`: default (70%), dragging draft (45%), minimum (30%), maximum (100%), disabled/loading, error banner above it, long description at 2.0 text scale, light and dark.
- `SettingsScreen`: the existing phone/tablet × light/dark plus loading, empty-default, error and long content, re-rendered with the slider.
- `ScanCaptureScreen` status: “captured below tier” fixture.
- All previews use fixtures from `settings_previews.dart` and `scan_previews.dart`, and a seeded `SettingsCubit`.

### Determinism
- No wall clock is introduced. The naming preview already uses the injected clock.
- The capability cache is instance-scoped, not static.
- Tier-3 fakes: the fake camera returns a checked-in fixture whose pixel size equals the requested tier (`720p`, `1080p`, `full`), and the fake export adapter records `initialDirectory`.

### Documentation
dartdoc is needed on:
- `SettingsRepository.current`/`changes`
- `SettingsSliderTile`
- `SettingsCubit.previewPdfQuality`
- `SupportedCameraResolution.requestKey`
- `CaptureResult.width/height`
- the `exportStartLocation` normaliser
- `ocrLanguageTag`

Inline `//` comments are needed on:
- why commit happens on drag end
- why the capability cache exists (no probing while open)
- the Android `primary%3A` document-URI encoding
- the retry without a hint
- why `languageTag` is retained

## Risks / Trade-offs

- [Probe preview size ≠ still size on some devices] → Advertised dimensions are labelled “about”, the actual size is shown after capture, and the tier is never claimed when unmet.
- [Two presets measure identically, so 2K is not offered] → Correct behaviour: only honest tiers are listed. This is documented in the camera screen description.
- [Android `EXTRA_INITIAL_URI` ignored by some OEM DocumentsUI builds] → Export still completes. The device-verification task records the behaviour on an emulator (API 34+) and the iOS Simulator.
- [The cache goes stale after a camera hardware change, such as a foldable or external camera] → Settings Retry and app restart refresh it. The resolver falls back to the highest supported tier at or below the preference, which the spec already requires.
- [Removing `OcrScript` breaks tests] → All call sites are in-repo, and `flutter analyze` lists them. The change is mechanical.
- [The repository read model diverges from the cubit if a write races] → Writes are serialised by `UpdateSettings` (await before the next). The cubit renders from the write result, and the read model is updated from the same result.

### Device verification results (task 8.1, 2026-11-10)

I ran a throwaway integration test against the real plugins, then deleted it.

- **Android emulator (Pixel 9, API 36): export start location verified.** `SystemExportDocumentRepository` normalised `/storage/emulated/0/Documents/DocScanlyCheck` to `content://…/document/primary%3ADocuments%2FDocScanlyCheck`. DocumentsUI opened *in that folder*, with its marker file listed. Cancelling with a starting location set returned `cancelled`, not an error.
- **iOS Simulator (iPhone 16 Pro): export start location only partly honoured.** The configured folder was a subfolder of the app's own Documents directory, normalised to a `file://` directory URL. The picker opened in the app's **DocScanly** root, the *parent* of that folder, and not in the folder itself. The export path is unaffected. This matches the risk above: on iOS the hint is best-effort. It is still open whether a real device or a location outside the app container behaves differently.
- **Camera: plugin path verified, tier fidelity not verifiable here.** On the Android emulator the real probe, open, capture and header-decode path works. It measured `max` → 1280×960, and the capture was decoded as 960×1280 (portrait, still meeting 720p). However, the emulator's virtual camera has a single size, so it cannot show 720p vs Full or 2K vs 4K producing different captures. The iOS Simulator has no camera. **This needs a physical device.**
- **TalkBack/VoiceOver on the slider: not run.** Semantics are covered by widget tests: the "Default PDF quality, N percent" label, increase/decrease actions and the 48 dp target. A live screen-reader pass still needs a person on a device.

## Migration Plan

- No persisted format changes and no Isar migration. Existing `settings.defaultSaveLocation` paths are normalised at read time.
- Rollback is a code revert. No data written by this change is unreadable by the previous version.
