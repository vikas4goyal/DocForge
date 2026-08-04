## Why

Settings currently presents navigation affordances that do not match how users reach it, several rows either appear inert or constrain content inside non-scrollable sheets, and the floating notched bottom bar looks unlike a polished iOS application. Since most purchases are on iOS, the top-level navigation and settings interactions need to feel native and predictable while remaining appropriate on Android.

## What Changes

- Remove the back button from Settings when Settings is the active tab; retain normal back navigation when Settings or a child selection screen is genuinely pushed.
- Open Recognition language as a full, pushed, scrollable selection screen instead of a modal sheet.
- Make Default save location actionable even while its value is “Ask each time,” allowing users to retain that behavior or choose/change a folder through the platform picker.
- Make the Storage row open a dedicated storage-details screen instead of performing a silent refresh; show usage and document count there, and let iOS users continue to the existing typed storage-location screen.
- Replace the floating, notched Material bottom bar on iOS with a restrained, platform-adaptive iOS tab bar. Keep Dashboard and Settings as selected destinations while Create PDF remains a middle action that starts creation without becoming selected.
- Preserve Android-native presentation with an adaptive Material 3 navigation bar and Android-appropriate icons/behavior.
- Add stable keys, semantics, previews, component coverage, navigation/widget tests, goldens, and an end-to-end settings flow for the changed interactions.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `app-settings`: Clarify tab-aware back behavior; require pushed, scrollable recognition-language selection; make default save-location selection and storage management actionable.
- `app-shell`: Require platform-adaptive bottom navigation with a native iOS presentation while preserving the middle Create PDF action and tab-selection semantics.

## Impact

### Architecture and folder structure

The change is limited to Android and iOS presentation/composition code and existing settings persistence contracts:

```text
lib/
  app/
    router/                         # typed settings child routes
    screens/                        # tab-versus-pushed composition callbacks
  features/
    app_settings/
      presentation/
        screens/                    # Settings and selection screens
        widgets/                    # adaptive rows and choice lists
        cubit/                      # existing SettingsCubit coordination only
      application/usecases/        # existing save-location update use case
      domain/repositories/          # existing settings contract
      infrastructure/repositories/ # existing preference persistence
    app_shell/
      presentation/
        screens/                    # adaptive tab scaffold
        widgets/                    # extracted platform bars if useful
test/features/{app_settings,app_shell}/
integration_test/flows/
```

- **Cubits and States:** no new business state is required. `SettingsCubit` continues to publish persisted settings and storage summaries; only UI coordination and test coverage change.
- **Use cases and repositories:** reuse `UpdateSetting.saveLocation` and `SettingsRepository.saveSaveLocation`; no new repository or storage access from presentation.
- **Isar schema:** unchanged.
- **Navigation:** Recognition language, default save location, and storage details become typed pushed screens; storage details can continue to the existing typed iOS storage-location destination. No untyped feature route strings are introduced.
- **Dependencies:** no new package is expected. Reuse Flutter Material/Cupertino widgets, GoRouter, and the existing file-picker platform edge. The folder-picker callback remains constructor-injected for previews/tests.

### Persistence, security, and migration

Existing SharedPreferences keys and meanings remain unchanged: null default-save-location continues to mean “Ask each time,” and a chosen folder remains the stored path. There are no Isar, preference-key, secure-storage-key, or document migrations. Folder paths are user-selected metadata, are not secrets, remain in preferences, and are never sent over the network. App-lock and iCloud authorization behavior are unchanged.

### Performance and extensibility

The adaptive tab bar adds no background work, isolates, polling, or persistent memory. Selection lists build only while their route is visible; long recognition lists use lazy scrolling where practical. Rebuilds remain scoped to the settings subtree. Keeping storage and picker access behind injected interfaces preserves the path to future cloud providers without making UI widgets aware of cloud storage.

### Verification and Definition of Done

- Unit/widget tests cover conditional back affordance, pushed scrolling selection, save-location actions, storage navigation, Create action behavior, tab selection, large text, semantics, and both platform variants.
- Tier-2 Settings component tests use the real Cubit/use cases with only repository/platform boundaries substituted.
- Navigation tests verify all pushed screens and the typed storage destinations.
- Settings and tab-bar goldens cover iPhone/iPad and Android phone/tablet, light/dark, long content, and large text.
- Existing settings/shell previews are updated for default, loading, empty where meaningful, error, long-content, phone/tablet, light/dark, and both platform styles.
- The settings-and-app-lock end-to-end flow is extended to tap every affected row, scroll the recognition list, select “Ask each time” and a deterministic folder, open storage management, and exercise Dashboard/Create/Settings navigation.
- Repository, serialization, and Isar tests remain unchanged because their contracts and schemas do not change; this is explicitly confirmed during verification.
- `tool/verify.dart` completes through all available tiers; on a device, the affected Tier-3 flow passes.

Primary risks are inconsistent route ancestry when deciding whether Settings can go back, a middle Create action being announced as a selected tab, and file-picker cancellation being mistaken for a value change. These are mitigated by explicit composition inputs, dedicated semantics tests, and treating picker cancellation as no-op. The change is complete when both platforms retain correct native behavior, accessibility requirements pass, and no top-level or settings interaction appears inert.
