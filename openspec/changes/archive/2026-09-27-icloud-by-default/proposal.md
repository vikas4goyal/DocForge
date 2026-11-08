# Proposal: iCloud by default with automatic migration

## Why

On iOS, DocScanly keeps every library on the device unless the user finds Settings → Storage location and opts in to iCloud Drive. Most users never do, so a lost or replaced phone loses their scans, and a second device sees nothing. Libraries are small (single-digit to low-hundreds of PDFs), so there is no good reason to hold them back. When an iCloud account is available, DocScanly's documents should live in iCloud Drive without the user having to do anything.

## What Changes

- **BREAKING (behaviour):** On iOS, whenever the app-owned iCloud container is available, the iCloud library is the **only** authority. Users can no longer choose "On this device" while iCloud works.
- **New installs** with iCloud available start directly in `iCloud Drive → DocScanly` and write the library marker on first launch. Nothing needs to be migrated.
- **Existing local libraries** (including users who previously chose local explicitly) are moved to iCloud automatically at the next cold launch. The move uses the existing restart-safe copy → verify → switch → clean migration and runs in a startup migration gate **before** the library is composed, so no document can be written during the move.
- **Merging into an existing iCloud library:** if iCloud already holds a DocScanly library (for example from another device) and the local library differs, the migration now **merges** it. A same-path payload with different bytes is copied under a deterministic conflict name instead of failing the whole migration with `cloud:conflict`.
- **No iCloud (signed out, iCloud Drive off, DocScanly turned off in iOS iCloud settings, restricted):** the library stays on the device and the app works fully. Settings explains why and how to turn iCloud on. The next cold launch after iCloud becomes available moves the library automatically. Users can also start the move at once with "Move documents to iCloud now", which recomposes the app through the migration gate.
- **Migration failure** (quota, verification, interruption): the gate shows the reason, **Retry**, and **Continue on this device for now**. Local stays authoritative for that session, and the next launch retries.
- **An iCloud library becomes unavailable later** (sign-out, DocScanly turned off in iCloud settings): the existing "never silently fall back" guarantee stays. The unavailable screen gains an explicit, confirmed **Use this device without iCloud** escape. It starts a device library, leaves iCloud content untouched, and is merged back automatically when iCloud returns. Today such a user is stuck on the retry screen.
- The Settings → Storage location screen changes from a two-option chooser to a **status screen**. It shows iCloud as active, local with a reason, migration progress or failure, "Move documents to iCloud now", and the existing "Import an existing iCloud Drive folder" action.
- When an automatic migration completes, the gate ends on a completion screen telling the user their documents are now in `iCloud Drive → DocScanly`.
- Android is unchanged.

## Capabilities

### New Capabilities
_None._

### Modified Capabilities
- `icloud-library-sync`: replaces "Explicit storage selection and safe migration" with "Automatic iCloud authority and migration". Adds requirements for the local fallback when iCloud is unavailable, the explicit device-library escape, and merge-with-conflict-preservation. Updates the presentation requirement for the status screen and the new keys.
- `app-security`: "Local-first and user-controlled document storage" no longer requires an explicit opt-in before finished PDFs go to iCloud. Transmission follows iCloud availability and is disclosed. Private working data rules are unchanged.
- `onboarding`: the privacy introduction's storage and upload statements become platform-true. Android keeps "stored only on this device" and "nothing is uploaded automatically". iOS says documents are kept in the user's own iCloud Drive when iCloud is on (otherwise only on the device), and that nothing is sent to DocScanly servers.
- `automated-verification`: the iCloud end-to-end journey and the deterministic fixture cover automatic first-launch selection, the automatic migration gate, local fallback when signed out, the device-library escape, and the merge, instead of manual selection and confirmation.

## Impact

### Architecture and layers touched
Only `lib/features/cloud_storage/` and the composition root in `lib/app/` change. No other feature imports `cloud_storage`, and the library feature still reaches it only through the composition root (`cloud_library_reconciler.dart`, `doc_scanly.dart`).

```
lib/features/cloud_storage/
  presentation/
    cubit/        storage_location_cubit.dart   (status + move-now; chooser/confirm removed)
                  storage_location_state.dart   (status variants reworked)
                  cloud_migration_gate_cubit.dart   NEW
                  cloud_migration_gate_state.dart   NEW
    screens/      storage_location_screen.dart  (status screen)
                  cloud_migration_gate_screen.dart  NEW
    cloud_storage_keys.dart                     (keys added/removed)
    cloud_storage_previews.dart                 (new previews)
  application/usecases/
                  load_storage_location.dart    (automatic policy → StorageDecision)
                  resolve_storage_decision.dart NEW (pure policy)
                  migrate_library_location.dart (merge + conflict naming)
                  adopt_device_library.dart     NEW (explicit escape)
                  load_storage_status.dart      NEW (read-only status for Settings)
                  choose_storage_location.dart  REMOVED
  domain/entities/
                  storage_decision.dart         NEW (sealed)
                  storage_location.dart         (unchanged enum)
  infrastructure/ (unchanged; ScriptedICloudPlatform gains scripts)
lib/app/
  cloud_storage_module.dart   (gate + escape wiring; CloudLibraryUnavailableApp escape)
  doc_scanly.dart             (routes startup through StorageDecision)
lib/main.dart                 (passes recompose callback)
```

- **Cubits / States:** `StorageLocationCubit` loses `choose` and `confirm` and gains `moveNow`. Its states change to `loading`, `iCloudActive`, `localFallback(reason)`, `unavailable` and `failure`. A new `CloudMigrationGateCubit` owns gate progress and failure.
- **Use cases:** a new `ResolveStorageDecision` (pure policy) and `AdoptDeviceLibrary`. `LoadStorageLocation` delegates to the policy. `MigrateLibraryLocation` gains a merge mode. `ChooseStorageLocation` is removed.
- **Repositories:** no interface changes. `LibraryLocationRepository` and `CloudContainerRepository` already expose everything the policy, gate, merge and escape need.
- **Isar schema:** unchanged. The iCloud reconciler re-indexes after the switch exactly as it does for a relaunch today.
- **Navigation:** the typed `storageLocation` route is kept. The gate is a composition-root screen (like `CloudLibraryUnavailableApp`), not a route.
- **Dependencies:** none added or changed.

### Migration considerations
- `libraryStorageLocation` keeps its meaning (the current authority). A stored `local` no longer means "user opted out". It means "not yet in iCloud" and triggers automatic migration when iCloud is available.
- There are no new preference keys, secure-storage keys or Isar changes.
- Existing migration checkpoints (`migration*` keys) are resumed by the gate exactly as before.

### Performance
- The gate copies with the existing streamed-digest verification. Libraries are small, so a gate should take seconds. Progress is shown and nothing else composes until it finishes.
- There are no extra launches or polling. Moves start at cold launch or when the user chooses "Move now".

### Security
- Only public library payloads (PDFs and the reserved Trash tree) move, as today. Thumbnails, OCR text, Isar and passwords stay app-private and on the device.
- Transmission to iCloud now happens without a confirmation step. This is disclosed on the Storage location status screen and on the gate's completion screen.

### Testing strategy
- **Tier 1:** the `ResolveStorageDecision` matrix, the `MigrateLibraryLocation` merge and conflict naming, `AdoptDeviceLibrary`, preference serialization, and bloc_test for both Cubits.
- **Tier 2:** `test/features/cloud_storage/component/` covers the status screen and gate screen with the real Cubits and use cases and a scripted platform.
- **Tier 3:** `icloud_library_sync_test.dart` is rewritten around automatic selection, the gate, the signed-out fallback, move-now, the escape, and the merge. `first_launch_test.dart` is checked on iOS with iCloud available.
- **Goldens:** the status screen and the gate in light and dark, on phone and tablet.

### Preview coverage
- `StorageLocationScreen` previews iCloud active, local fallback for each reason, migrating, failure, loading, and long content.
- `CloudMigrationGateScreen` previews copying, verifying, failure, and long reason text.
- Every preview covers phone and tablet in light and dark.

### Definition of Done
- All delta requirements pass Tier 1, 2 and 3.
- `tool/verify.dart` is green with Tier 3 actually run.
- README storage section is updated.
- No stale references to `cloud_storage_local_option`, `cloud_storage_icloud_option` or `cloud_storage_migration_confirm` remain.

### Risks and mitigations
| Risk | Mitigation |
|---|---|
| Quota exceeded blocks every launch | The gate fails fast with "Continue on this device for now". Local stays authoritative and nothing is lost. |
| Merge produces unexpected duplicates | The merge only duplicates on differing bytes, under a deterministic `(Conflict …)` name. Identical files are deduplicated by digest. |
| User did not want iCloud | Documents stay in the user's own iCloud container and are visible in Files. iOS Settings → iCloud → DocScanly off → the app falls back to the device with an explicit escape. |
| Different Apple account signed in | The local library moves to the current account's container. An established library of another account is never touched. |
| Migration interrupted by force-quit | The existing checkpoints resume the migration on the next gate run. |

### Future extensibility
The `StorageDecision` policy is the single seam for future providers (for example Google Drive on Android). A per-user opt-out could be restored later by adding a policy input, without touching migration.

### Platforms
iOS and Android only. The Android path constructs no cloud module and is unchanged. There is no web or desktop impact.
