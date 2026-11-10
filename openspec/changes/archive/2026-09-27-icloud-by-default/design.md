# Design: iCloud by default with automatic migration

## Context

See `proposal.md` (Why) and the delta specs for the required behaviour. The current code has these properties that constrain the approach:

- **Authority is fixed at composition time.** `buildDocScanly` (`lib/app/doc_scanly.dart`) resolves `LoadedStorageLocation` once and then builds the `PublicFileStore`, the document resolver, and either `ReconcileCloudLibrary` or local reconciliation from it. Nothing re-composes after a switch. Today's manual migration from Settings writes the new authority, but the running app keeps using the old store until relaunch.
- **Migration inventories the source once.** `MigrateLibraryLocation` lists the source tree, then copies, verifies, switches and cleans exactly that inventory. A file created in the source during a migration is not copied, yet is left behind after cleanup. This is safe only if nothing writes during the move.
- **The same path with different bytes fails the migration** (`cloud:conflict` in `_copyAndVerify`). Moving a device library into an established iCloud library therefore fails today.
- **Startup already has a swap-in pattern.** `CloudLibraryUnavailableApp` shows a standalone `MaterialApp` and replaces itself with the result of `buildDocScanly()` on retry. `_BootstrapApp` in `lib/main.dart` can re-run composition (`_retry`).
- **`LoadStorageLocation` persists `local` whenever no marker is found**, so every existing user already has `libraryStorageLocation = local` stored.

## Goals / Non-Goals

**Goals**
- One pure, fully tested policy decides the startup authority from the stored authority, the availability, the marker and whether the device library is empty.
- Every automatic move happens before composition, so no concurrent writes are possible and the app always composes against exactly one root.
- Reuse the existing migration engine and checkpoints. Only add merge semantics.

**Non-Goals**
- Live, mid-session switching without re-composition.
- Automatic reaction to `NSUbiquityIdentityDidChange` while the app runs, beyond what reconciliation already does. The move happens at the next cold launch or through "Move now".
- A user preference to opt out of iCloud while it is available.
- Any Android change.

## Decisions

### D1. A pure `ResolveStorageDecision` policy returns a sealed `StorageDecision`
`domain/entities/storage_decision.dart` (Freezed sealed union):

| Variant | Meaning |
|---|---|
| `useICloud` | Compose on the iCloud root now. Write the marker if absent. |
| `migrateToICloud(source: local, resume: checkpoint?)` | Run the gate, then re-compose. |
| `useLocal(reason: CloudAvailabilityStatus)` | Device fallback. Compose on the local root. |
| `iCloudUnavailable` | iCloud is authoritative but unreachable. Show the unavailable app. |

Policy, evaluated in order:
1. A migration checkpoint exists → `migrateToICloud(resume)`. This covers an interruption in any phase, including cleaning after the switch.
2. Stored `iCloud` → `useICloud` if available, otherwise `iCloudUnavailable`. The "never silently fall back" rule is unchanged.
3. Stored `local` or absent, and iCloud available → `useICloud` if the device library has no payloads, otherwise `migrateToICloud`.
4. Stored `local` or absent, and iCloud not available → `useLocal(reason)`.

`LoadStorageLocation` gathers the inputs through the existing repositories plus an `isEmpty` check on the local `PublicFileStore`, then calls the policy. The policy is a plain function over values with no I/O, so its whole matrix can be covered by Tier-1 tests. It replaces the "absent preference only" discovery branch. Discovery of an established marker becomes case 3, with merge when the device has content.

*Alternative considered:* keep `LoadedStorageLocation` and add flags. Rejected because the four outcomes are mutually exclusive and a sealed union makes the composition root's `switch` exhaustive.

### D2. The automatic migration runs in a startup gate, before composition
When `buildDocScanly` receives `migrateToICloud`, it returns `CloudMigrationGateApp` (in `lib/app/cloud_storage_module.dart`, a sibling of `CloudLibraryUnavailableApp`) instead of the composed app. The gate hosts `CloudMigrationGateScreen` with a `CloudMigrationGateCubit` that invokes the migration use case.
- On success it shows the completion state, and `cloud_storage_migration_continue` calls `onRecompose()`. Composition then resolves `useICloud`.
- On failure it shows `cloud_storage_retry` (re-run the migration) and `cloud_storage_continue_local`. The second option sets `shouldCancel` if copying is still running, then calls `onContinueLocal()`, which composes with a one-shot `forceLocalThisSession` override. That override is a constructor argument of `buildDocScanly`, not stored state, so the next cold launch retries automatically.

*Why pre-composition:* this satisfies the single-inventory constraint in Context, so no document can be written mid-move. It also removes the need for live store swapping.
*Alternative considered:* a background migration while the app runs on local, followed by a hot swap. Rejected because it needs source-change tracking and a live store swap across every Cubit. For small libraries a short gate is the simpler and safer trade.

### D3. Re-composition is an injected callback
`buildDocScanly` gains `Future<Widget> Function()? onRecompose`. `_BootstrapApp` passes a closure that re-runs `_buildApplication` (the existing `_retry` path). The gate uses it, and so does "Move documents to iCloud now" on the status screen: with iCloud available and authority local, re-composition resolves `migrateToICloud` and shows the gate. There is exactly one migration path and no global state. Tests inject their own recompose closure through `bootDocScanly`, which hosts the app in a small `_RecomposeHost` standing in for `_BootstrapApp`. Because a recomposed app runs `buildLibraryModule` again while its database is open, that function reuses `Isar.getInstance()` before opening. On iOS, a flow that does not script iCloud gets a signed-out scripted edge, so the simulator's Apple account never decides a flow's library.

### D4. Merge mode in `MigrateLibraryLocation`
When a destination path exists:
- identical digest → verified (as today);
- different digest and destination is iCloud → probe `<stem> (Conflict device)<ext>`, `<stem> (Conflict device 2)<ext>`, … in order. A candidate holding identical bytes counts as verified, and the first free one receives the copy, which is then verified. The checkpoint still records the **source** path. This keeps resume idempotent without storing renamed paths: an earlier run's conflict copy is recognised by its digest, so no third copy is made.
- Reserved Trash payload paths are never renamed, because the device index addresses them exactly; a Trash collision keeps failing with `cloud:conflict`.
- A cancelled merge into an established library removes only the files this run wrote, never verified pre-existing files or folders.
- different digest with a local destination (a device-to-device merge is not produced by this policy) → keep today's `cloud:conflict` failure.

The marker is written only if absent (D1, case 3). An established marker is preserved. Cleanup still deletes only the verified source inventory.

The suffix format intentionally differs from the reconciler's `(Conflict <token>)`. The reconciler's names are index-only projections of iCloud conflict versions, while these are real files, so the formats must not collide.

### D5. Explicit device-library escape
`AdoptDeviceLibrary` (a use case) discards any migration checkpoint and writes `libraryStorageLocation = local`. iCloud payloads, marker and Isar metadata stay untouched. The checkpoint must go because a switched move that was still cleaning would otherwise keep resolving to `iCloudUnavailable`; its device files are verified copies and merge back without duplicates. `CloudLibraryUnavailableApp` gains `cloud_storage_use_device`. It opens an adaptive confirmation dialog (`cloud_storage_use_device_confirm`), then runs the use case and `onRecompose()`. Because authority is now local and iCloud is unavailable, D1 resolves `useLocal`. When iCloud returns, D1 case 3 merges the device library back through D4.

The Isar index still holds rows for iCloud documents that are no longer reachable. The local reconciler removes rows whose payload is missing from the authoritative store, which is existing behaviour. After the merge back, the iCloud reconciler re-adds them. Nothing is lost because payloads live in the container.

### D6. Presentation: Cubits and States
**`StorageLocationCubit`** (status screen). It loses `choose`, `confirm` and `cancel`. `ChooseStorageLocation` is deleted. The Cubit now reads a new read-only `LoadStorageStatus` use case (the session's composed authority plus a fresh availability snapshot). It must not reuse `LoadStorageLocation`, because that one persists the authority, and opening Settings must never switch the running session's root. The Cubit gains `moveNow()`, which calls the injected `onRecompose`.

`StorageLocationStatus` variants:

| Variant | When |
|---|---|
| `loading` | Initial load or refresh |
| `iCloudActive` | The iCloud library is authoritative |
| `localFallback` | Carries `CloudAvailabilityStatus reason`. `canMoveNow` is `reason == available`, meaning iCloud appeared during the session. |
| `unavailable` | The iCloud library is authoritative but unreachable |
| `failure` | Recoverable load failure, with `cloud_storage_retry` |

Transitions: `loading → {iCloudActive | localFallback | unavailable | failure}`, `failure → loading` (retry), and `localFallback(available) → (recompose)`.

**`CloudMigrationGateCubit`** (new). Its states:
- `preparing`
- `copying(done, total)`
- `verifying(done, total)`
- `cleaning`
- `completed`
- `failed(failure)`

The migration use case reports no separate switching progress, so the switch is folded into `verifying → cleaning`.

Transitions:
- `preparing → copying → verifying → cleaning → completed`
- any state before `cleaning` → `failed`
- `failed → preparing` (retry)
- after `cleaning`, a failure keeps the state `completed`. The authority has already moved, and the retained checkpoint re-runs cleanup at the next gate. This mirrors the existing post-switch rule.
- `continueOnDevice()` cancels a running move before its switch, waits for the use case's rollback, and reports whether the device is still authoritative.

Both are Cubits. There is no event stream that needs a Bloc. They only map use-case progress and results to states, and all business rules live in D1, D4 and D5.

States extend Equatable with every field in `props`. `StorageDecision` and its payloads are Freezed. No JSON is involved: checkpoints keep their existing preference encoding.

### D7. Composition and DI
`buildCloudStorageModule` constructs:
- `StorageLocationPreferences`
- `PlatformCloudContainerRepository`
- `ResolveStorageDecision`
- `LoadStorageLocation(locations, cloud, localStore, policy)`
- `AdoptDeviceLibrary(locations)`
- a `migrate` closure (the existing `_migrate` with merge)

`CloudStorageModule` exposes `decision` in place of `resolution`. `buildDocScanly` switches exhaustively on it. There is no service locator, and `onRecompose` and `forceLocalThisSession` travel as constructor and function parameters.

Dependency direction: `presentation → application → domain`, and `infrastructure → domain`. `cloud_storage` imports no other feature. The only place that joins cloud storage and the library remains `lib/app/`.

### D8. Keys and semantics (`cloud_storage_keys.dart`)

**Added**

| Key | Semantics label |
|---|---|
| `cloud_storage_status` | “DocScanly documents are stored in iCloud Drive” / “DocScanly documents are stored on this device. <reason>” |
| `cloud_storage_move_now` | “Move documents to iCloud now” |
| `cloud_storage_migration_gate` | “Moving DocScanly documents to iCloud” |
| `cloud_storage_migration_done` | “Your DocScanly documents are now in iCloud Drive” |
| `cloud_storage_migration_continue` | “Continue to DocScanly” |
| `cloud_storage_continue_local` | “Continue on this device for now” |
| `cloud_storage_use_device` | “Use this device without iCloud” |
| `cloud_storage_use_device_confirm` | “Confirm using this device without iCloud” |

**Kept:** `cloud_storage_screen`, `cloud_storage_migration_progress`, `cloud_storage_unavailable`, `cloud_storage_retry` (label varies: “Retry iCloud migration” / “Retry iCloud connection”), `cloud_storage_import_folder`, `library_cloud_refresh`.

**Removed:** `cloud_storage_local_option`, `cloud_storage_icloud_option`, `cloud_storage_migration_confirm`, `cloud_storage_cancel`. `fixedValues` and the registry test are updated to match.

Reason copy lives in `CloudStorageSemantics.fallbackReason(CloudAvailabilityStatus)`. It is a pure switch, so it is deterministic and previewable.

### D9. Previews and fixtures
- `StorageLocationScreen` previews: iCloud active; local fallback for signed out, disabled, restricted, unavailable, and available (move-now shown); loading; failure; long content at a large text scale.
- `CloudMigrationGateScreen` previews: preparing, copying 3/12, verifying, completed, failed (quota), and long failure text.
- Each preview covers phone and tablet in light and dark. They use seeded Cubits or fake Cubits over fixture states. There is no platform channel, clock or randomness.

### D10. Hidden state and determinism
- No static or global state is introduced. `forceLocalThisSession` is an explicit parameter, and re-composition is an explicit callback.
- The policy is pure.
- Conflict names come from a deterministic probe over the destination, never from time or randomness.
- Dartdoc is required on `StorageDecision`, `ResolveStorageDecision`, `AdoptDeviceLibrary`, both Cubits and States, the gate app and screen, and the new keys.
- Inline comments are required where the reason is not obvious: why the gate precedes composition (the single-inventory constraint), why an existing iCloud marker is preserved, why a post-switch failure maps to `completed`, and why checkpoints record renamed paths.

## Risks / Trade-offs

- **[A persistent quota failure shows the gate at every cold launch]** → The gate fails fast (the availability and space check before copying), and "Continue on this device for now" is one tap. This is acceptable for small libraries. A backoff can be added later without spec changes.
- **[The startup gate delays the first launch after upgrade]** → Only libraries with content see it, once. Progress is visible.
- **[Upgrade silently changes behaviour for users who chose "On this device"]** → This is intended per the product decision. The completion screen discloses it. Users can still turn DocScanly off in iOS iCloud settings to get the device fallback.
- **[Signed into a different Apple Account]** → The device library merges into that account's container. The previous account's container is never touched. This matches the "current account owns the library" model iOS uses.
- **[A crash between the switch and cleanup leaves source copies]** → Case 1 in D1 resumes cleanup through the gate. The copies are verified duplicates, never the only copy.
- **[Stale Isar rows after the use-device escape]** → Existing local reconciliation removes rows whose payload is missing. Payloads are safe in iCloud and are re-indexed after the merge back.

## Migration Plan

1. Ship the policy, the gate and merge together. Existing `local` preferences need no data migration: they now mean "not yet in iCloud".
2. On the first cold launch after upgrade, iOS users with iCloud and documents see the gate once. Users without iCloud see no change except the status screen.
3. **Rollback:** a previous build reads `libraryStorageLocation = icloud` and continues in iCloud, which it already supports. There is no schema change to revert.
