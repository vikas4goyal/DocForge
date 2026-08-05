## Context

The settings tab is built from the same screen builder as the pushed `/settings` route, so the screen currently receives an unconditional `onBack` callback even when tab selection did not create history. Generic settings choices always use a bottom sheet whose `Column` is not suitable for long recognition-language lists. The null save-location preference means “Ask each time,” but that same state disables the row. The Storage row refreshes its summary without navigating or showing progress, which appears inert. Finally, the shell uses a centered floating action button docked into a notched Material bar on every platform; this conflicts with iOS tab-bar conventions and creates the cartoon-like emphasis reported on physical iOS devices.

The implementation must preserve the existing clean-architecture boundaries, settings persistence, creation-flow semantics, accessibility guarantees, and Android users. No network, data-schema, authentication, or cloud-synchronization behavior changes.

## Goals / Non-Goals

**Goals:**

- Make Settings navigation reflect actual route history.
- Give recognition language, default save location, and storage information dedicated scrollable pushed screens.
- Keep platform pickers and storage access injected at the composition boundary.
- Render native-feeling iOS bottom navigation while keeping Material 3 behavior on Android.
- Preserve Dashboard/Settings state and make Create PDF a middle action rather than selected destination.
- Cover the behavior with deterministic previews and all relevant verification tiers.

**Non-Goals:**

- Rebrand the application or redesign every screen.
- Change OCR models, export formats, document storage layout, iCloud migration, app-lock behavior, or preference meanings.
- Add new packages, cloud services, analytics, web, desktop, or platform support beyond Android and iOS.
- Convert the entire Flutter application to `CupertinoApp` or replace Material 3 globally.

## Decisions

### 1. Composition explicitly distinguishes tab and pushed Settings

`SettingsScreen` will accept an optional back action (or an explicit presentation mode), with `automaticallyImplyLeading` disabled. The home tab composition passes no back action; a pushed typed route passes a pop callback. This is preferred over checking `Navigator.canPop()` inside the widget because the settings subtree and root navigator can have different ancestry and previews need deterministic behavior.

All public constructor changes and presentation-mode values receive dartdoc. An inline comment will explain why tab Settings intentionally suppresses automatic leading controls.

### 2. Dedicated typed child routes own selection/detail navigation

Add typed GoRouter destinations for:

- `settings_ocr_language_screen`
- `settings_save_location_screen`
- `settings_storage_screen`

Each route receives stable callbacks/values through explicit composition rather than locating services globally. The OCR list reads the current `SettingsCubit` state and invokes `setOcrScript`; the save-location screen invokes `setSaveLocation`; storage details invokes `refreshStorage`. If the existing generated typed-route setup cannot safely share the tab-scoped Cubit, the composition root supplies builders and callbacks while route paths remain centralized and typed—feature widgets never navigate using string literals.

Imperative modal sheets were considered, including making the existing sheet draggable. Pushed screens are chosen because they provide predictable height, native back gestures, a visible title, straightforward scrolling, and better large-text behavior.

### 3. Save-location picking remains a platform-edge dependency

The default-save-location screen shows two rows: `settings_save_location_ask_each_time` and `settings_save_location_choose_folder`. Null remains the persisted representation of “Ask each time.” Selecting the folder row invokes a constructor-injected `Future<String?> Function()` composed over the already-installed file picker. A null/cancelled result performs no Cubit transition. A selected path goes through `SettingsCubit` → `UpdateSetting.saveLocation` → `SettingsRepository`, preserving presentation/application/domain/infrastructure direction.

No new model is serialized. `AppSettings` remains immutable; no new Freezed or json_serializable contract is needed. SharedPreferences retains the existing key, Isar is untouched, and secure storage remains limited to app-lock data.

### 4. Storage details makes refresh visible and keeps cloud concerns separated

`settings_storage_info` pushes a dedicated details screen that renders the Cubit's current summary, a keyed refresh control, loading/error feedback consistent with existing settings behavior, and the iOS-only `settings_storage_manage_location` action. The latter calls the existing typed storage-location route through the composition callback; app_settings does not import cloud_storage directly.

No new storage use case is needed: `LoadStorageSummary` already owns the read. `SettingsCubit` retains its current immutable `SettingsState` variants (`loading`, `ready`, `failure`) and transitions. If implementation requires a distinct refresh indicator, add an immutable `isRefreshingStorage` field to `SettingsState.props`; it may coordinate UI only and MUST NOT contain business logic. A full Bloc is not justified.

### 5. Bottom navigation is platform-adaptive at the widget boundary

`AppTabScaffold` selects a Cupertino-style bar on iOS and a Material 3 `NavigationBar` on Android based on the injected/theme platform. Both expose the same keys, callbacks, labels, and logical index mapping:

- index 0 → Dashboard destination
- index 1 → Create PDF action
- index 2 → Settings destination

The selected index is always 0 or 2. Tapping index 1 calls `onCreate` without mutating the selected `AppTab`. Cupertino unfilled/filled icon pairs and Material outlined/filled icon pairs distinguish selection beyond color. Safe-area handling comes from the platform bar; no floating action button, notch, static overlay, or global mutable platform state remains.

Using Cupertino presentation on Android was rejected because the smaller Android audience still deserves native conventions. Keeping the floating center action only on Android was also rejected because both platforms benefit from consistent action semantics and the Material 3 bar already supports a restrained middle destination-shaped action.

### 6. Keys, semantics, previews, and testing are part of the public UI contract

Add the exact keys and semantics named in the delta specs to `settings_keys.dart` and keep shell keys stable. Reusable widgets remain constructor-injected and previewable without live plugins. Deterministic preview fixtures cover:

- Settings tab and pushed Settings, phone/tablet, light/dark, loading/error/long content.
- OCR selector default/long list/maximum-text-scale visual fixture, phone/tablet, light/dark.
- Save-location selector for “Ask each time,” selected long path, picker cancellation representation, phone/tablet, light/dark.
- Storage details loading/ready/empty/error/long numbers, iOS/Android, phone/tablet, light/dark.
- App tab scaffold iOS/Android, Dashboard/Settings selected, phone/tablet, light/dark, long labels/text scale.

Widget and navigation tests verify presentation modes and semantics; Tier-2 Settings tests wire the real Cubit/use cases with repository and picker boundaries faked; goldens cover major visual states; the Settings robot and existing end-to-end flows exercise all keys. Existing repository/serialization tests remain valid and should only change if implementation unexpectedly changes their contract.

No hidden, static, or global mutable state is introduced: platform style, current selection, paths, callbacks, and summaries enter through constructors or existing Cubit state. Public screens/widgets and callbacks receive mandatory dartdoc; inline comments document the middle-action index and deliberate suppression of automatic back behavior.

## Risks / Trade-offs

- **[Risk] A typed pushed route cannot see the tab-scoped SettingsCubit** → Compose the Cubit above the settings branch or inject value/callback builders explicitly; add a navigation/component test that changes a value and observes Settings after pop.
- **[Risk] Cupertino tab items assume every index is a selectable destination** → Keep the shell's selected state external and map it only to indices 0/2; test that Create never exposes selected semantics.
- **[Risk] Picker cancellation clears a previous path** → Treat null/empty results as no-op and test both a previous path and “Ask each time.”
- **[Risk] A platform path can become unavailable later** → Preserve current export fallback/error behavior; future provider validation stays behind repositories.
- **[Risk] Large text overflows a fixed native tab bar** → Use platform bar behavior, validate at supported maximum scale, and provide semantics access even if platform label layout compresses.
- **[Trade-off] Platform bars produce different pixel geometry** → Accept intentional platform differences while keeping logical navigation, keys, and semantics identical.

## Migration Plan

1. Add keys, typed route definitions, and presentation builders without changing persistence.
2. Introduce pushed screens and wire them to existing Cubit/use cases and injected picker/storage callbacks.
3. Replace the shell bar with adaptive iOS/Android implementations while preserving `AppTab` state.
4. Update previews, robots, tests, and goldens; run `tool/verify.dart` and verify the iOS result on a simulator or physical device.
5. Release normally; there is no user-data migration.

Rollback reverts the presentation/routes while leaving preferences and documents untouched. Existing keys remain readable because no persistence format changes.

## Open Questions

None blocking. During implementation, verify the exact iOS file-picker capability on the supported deployment target; if directory selection is unavailable, the screen SHALL use the existing export picker contract rather than introduce a new dependency or silently store an unusable path.
