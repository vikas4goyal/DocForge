## 1. UI Contracts and Typed Navigation

- [x] 1.1 Add the specified Settings screen/control keys and exact semantics labels to `settings_keys.dart`, preserve shell keys, update affected robots in the same edit, and add Tier-1 registry/semantics assertions.
- [x] 1.2 Add centralized typed routes and screen builders for Recognition language, Default save location, and Storage details, wire dependencies explicitly from the composition root, and add Tier-1 navigation tests for every push, pop, deep-link/back path, and iOS storage-management continuation.
- [x] 1.3 Add truthful dartdoc for all changed public constructors, screens, callbacks, route APIs, keys, and semantics helpers, plus inline rationale for suppressed tab back navigation, picker cancellation, and the middle Create action.

## 2. Settings Tab and Recognition Language

- [x] 2.1 Make Settings presentation mode explicit so the tab has no back control while a pushed Settings screen does, and add Tier-1 widget tests proving both modes and working pop behavior.
- [x] 2.2 Implement `settings_ocr_language_screen` as a pushed, lazy, vertically scrollable language list using the existing SettingsCubit/update use case, and add Tier-1 widget tests for opening, scrolling at maximum text scale, selecting, persistence on pop, cancellation/back, semantics, dark mode, and phone/tablet layouts.
- [x] 2.3 Extend the Tier-2 Settings component suite with the real SettingsCubit/use cases and a repository fake to prove tab-aware back behavior and recognition selection update the screen and persisted setting together.

## 3. Default Save Location

- [x] 3.1 Implement `settings_save_location_screen` with enabled “Ask each time” and “Choose a folder” controls, inject the existing platform picker at composition, route accepted paths through `UpdateSetting.saveLocation`, treat picker cancellation as no-op, and add Tier-1 widget/use-case tests for null, selected, changed, long-path, cancelled, failure, semantics, and offline behavior.
- [x] 3.2 Extend the Tier-2 Settings component suite with the real Cubit/use cases plus repository and platform-picker fakes to prove both save modes persist immediately, write failures retain the prior value, and cancelled picks do not emit a change.
- [x] 3.3 Confirm the existing SharedPreferences key, repository serialization, and export initial-directory contract need no migration; run the focused repository/serialization/sharing tests and document any required compatibility adjustment before marking this task complete.

## 4. Actionable Storage Details

- [x] 4.1 Implement `settings_storage_screen` with current usage, document count, explicit refresh/loading/error feedback, and the iOS-only keyed “Manage storage location” action wired through the existing typed callback; add Tier-1 widget tests for ready/loading/empty/error/refresh, changed totals, iOS/Android visibility, semantics, dark mode, large text, and phone/tablet layouts.
- [x] 4.2 If visible refresh progress requires SettingsState/Cubit changes, add the immutable field to `props`, keep coordination only in the Cubit, and add `bloc_test` coverage for load, refresh success, refresh failure, and closed-Cubit safety; otherwise record that the existing state transitions were sufficient.
- [x] 4.3 Extend the Tier-2 Settings component suite with the real Cubit and `LoadStorageSummary` over a deterministic repository-boundary fake to prove opening/refreshing updates the visible summary and iOS management invokes the injected navigation callback.

## 5. Platform-Adaptive Bottom Navigation

- [x] 5.1 Replace the floating notched shell bar with a Cupertino-style iOS tab bar and Material 3 Android navigation bar, keep the selected index limited to Dashboard/Settings, preserve the middle Create action and IndexedStack state, and add Tier-1 widget tests for platform structure, taps, no selected Create state, native filled/outlined icon changes, safe area, semantics, dark mode, 48dp targets, and maximum text scale.
- [x] 5.2 Extend the Tier-2 app-shell component coverage with real top-level selection state to prove Dashboard/Settings retention and Create push/pop behavior on both iOS and Android without rebuilding the selected destination.

## 6. Previews and Visual Regression

- [x] 6.1 Add/update deterministic `@Preview()` entries for tab and pushed Settings, OCR selection, save-location selection, and storage details across default/loading/empty/error/long-content states where meaningful, phone/tablet, light/dark, and iOS/Android platform variants.
- [x] 6.2 Add/update deterministic `@Preview()` entries for the app tab scaffold across iOS/Android, Dashboard/Settings selected, phone/tablet, light/dark, and large-text states without live services or global platform mutation.
- [x] 6.3 Update Settings and app-shell golden tests and approved images for materially changed iPhone/iPad and Android phone/tablet light/dark screens, then run the focused golden suites and inspect diffs for native spacing, safe areas, contrast, clipping, and cartoony/oversized treatment.

## 7. End-to-End User Journeys

- [x] 7.1 Update the Settings robot and `integration_test/flows/settings_and_app_lock_test.dart` to verify no tab back button, scroll and select a recognition language, choose “Ask each time,” select/change a deterministic folder through the fake platform edge, cancel without mutation, and open/refresh Storage details exclusively through keys and semantics.
- [ ] 7.2 Update the cloud-storage robot and `integration_test/flows/icloud_library_sync_test.dart` to navigate from Storage details through “Manage storage location” to `cloud_storage_screen`, while retaining local/iCloud migration and unavailable-state coverage.
- [ ] 7.3 Extend an appropriate full-app flow (prefer Settings and app lock) to verify the adaptive Dashboard/Create/Settings bar on iOS and Android, including Create returning to the previously selected tab and no selected Create semantics, and run both affected Tier-3 flows on attached platform targets.

## 8. Quality Gates and Completion

- [x] 8.1 Run `dart format --set-exit-if-changed` on changed Dart files, `flutter analyze`, layering/platform checks, focused Tier-1 and Tier-2 tests, golden tests, and coverage verification; fix every failure and confirm overall coverage remains at least 80%.
- [ ] 8.2 Inspect the implemented iOS screens on a simulator or physical iPhone in light/dark mode and at large text, confirming native tab-bar proportions, scrolling, back gestures, folder-picker cancellation, safe-area behavior, and accessible touch targets; record the device/runtime used.
- [x] 8.3 Run `tool/verify.dart` and report its per-stage result. The change is not done while any stage fails, and a run that reports Tier 3 as SKIPPED (no device attached) does not count as verified.
