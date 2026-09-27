# Tasks

## 1. Storage decision policy (domain + application)

- [x] 1.1 Add Freezed sealed `StorageDecision` (`useICloud`, `migrateToICloud(resume)`, `useLocal(reason)`, `iCloudUnavailable`) in `lib/features/cloud_storage/domain/entities/storage_decision.dart` with dartdoc. Verify `dart run build_runner build` succeeds and `flutter analyze` is clean.
- [x] 1.2 Implement pure `ResolveStorageDecision` in `application/usecases/resolve_storage_decision.dart` following the D1 order (checkpoint → stored iCloud → available and empty/non-empty → unavailable). Verify with a Tier-1 matrix test in `test/features/cloud_storage/application/resolve_storage_decision_test.dart` covering every stored value × availability status × marker × empty/non-empty × checkpoint combination.
- [x] 1.3 Rework `LoadStorageLocation` to gather stored authority, availability, marker, checkpoint and local `isEmpty`, then return the policy's `StorageDecision`. Remove the "absent preference only" discovery branch. Verify that the updated `storage_location_usecases_test.dart` passes, including the stored-`local`-with-available-iCloud case.
- [x] 1.4 Delete `ChooseStorageLocation` and its tests, and remove every reference. Verify `flutter analyze` reports no unresolved references.

## 2. Merge mode and device escape (application)

- [x] 2.1 Add merge to `MigrateLibraryLocation._copyAndVerify`: with an iCloud destination and a differing digest, copy to the first free `<stem> (Conflict device[ N])<ext>` and verify it. Keep `cloud:conflict` for local destinations. Verify with Tier-1 tests for identical-bytes dedupe, one conflict, and two conflicts (`… 2`).
- [x] 2.2 Make resume idempotent by accepting an earlier identical conflict copy (digest probe), make cancellation remove only this run's writes when merging, and write the marker only when absent. Verify with Tier-1 tests: an interrupted merge resumes without a third copy, and an established marker is byte-identical after the merge.
- [x] 2.3 Implement the `AdoptDeviceLibrary` use case, which discards any checkpoint and writes `local` authority. Verify with a Tier-1 test that the iCloud marker and payloads are unchanged and that a cleaning checkpoint no longer resolves to `iCloudUnavailable`.
- [x] 2.4 Add inline comments for the marker preservation, renamed-path checkpoints and the reason for the conflict-suffix format (D4, D10). Verify by review against the design checklist.

## 3. Migration gate (presentation)

- [x] 3.1 Add the `CloudMigrationGateCubit` and `CloudMigrationGateState` (preparing, copying, verifying, switching, cleaning, completed, failed) with dartdoc. Map post-switch failure to `completed` (D6). Verify with bloc_test sequences for success, pre-switch failure → retry → success, continue-local cancellation, and post-switch cleanup failure.
- [x] 3.2 Build `CloudMigrationGateScreen` with the keys `cloud_storage_migration_gate`, `cloud_storage_migration_progress`, `cloud_storage_migration_done`, `cloud_storage_migration_continue`, `cloud_storage_retry` and `cloud_storage_continue_local`, and their D8 semantics. It must be adaptive, responsive and scrollable at large text. Verify with a Tier-1 widget test asserting keys and semantics per state.
- [x] 3.3 Add `@Preview()` entries for the gate: preparing, copying 3/12, verifying, completed, failed (quota) and long failure text, each on phone and tablet in light and dark, using fixture states. Verify that `flutter widget-preview start` lists them and that they render without errors.
- [x] 3.4 Add a Tier-2 component test `test/features/cloud_storage/component/cloud_migration_gate_component_test.dart` that uses the real Cubit, real `MigrateLibraryLocation` over real temporary directories and `ScriptedICloudPlatform`. Cover success with completion and continue, quota failure with retry and continue-local, and a merge that produces a conflict copy. Verify that it passes.
- [x] 3.5 Add golden tests for the gate (copying on a phone in light, completed on a phone in dark, failed on a tablet in light, large text). Verify with `flutter test --update-goldens` then a clean run.

## 4. Storage-location status screen (presentation)

- [x] 4.1 Update `cloud_storage_keys.dart`: add the D8 keys and semantics, `CloudStorageSemantics.fallbackReason`, and remove `localOption`, `iCloudOption`, `migrationConfirm` and `cancel`. Update `fixedValues`. Verify that the key-registry test passes and `grep -r "cloud_storage_local_option\|cloud_storage_icloud_option\|cloud_storage_migration_confirm\|cloud_storage_cancel" lib test integration_test` returns nothing.
- [x] 4.2 Rework `StorageLocationCubit` and `StorageLocationState` to use the statuses `loading`, `iCloudActive`, `localFallback(reason, canMoveNow)`, `unavailable` and `failure`, plus `moveNow()` via an injected recompose callback. Remove `choose`, `confirm` and `cancel`. Verify with rewritten bloc_test cases in `storage_location_cubit_test.dart`.
- [x] 4.3 Rework `StorageLocationScreen` into a status card (`cloud_storage_status`), `cloud_storage_move_now` shown only when `canMoveNow` is true (disabled with the reason otherwise), the existing import action, and retry on failure. Verify with the updated `storage_location_screen_test.dart`, which asserts keys and semantics for each status.
- [x] 4.4 Update the storage-screen `@Preview()` entries: iCloud active, local fallback for each of the five reasons, loading, failure and long content, on phone and tablet in light and dark. Verify that the previews render.
- [x] 4.5 Update the Tier-2 test `storage_location_component_test.dart` to use the real Cubit and use cases with a scripted platform. Cover signed-out fallback wording, move-now calling recompose when iCloud is available, and iCloud active. Verify that it passes.
- [x] 4.6 Regenerate the storage-location goldens for the status layouts and remove obsolete chooser goldens. Verify that `storage_location_golden_test.dart` passes.
- [x] 4.7 Update the Settings storage row copy and the privacy/visibility text so they state where PDFs are stored and, during fallback, why iCloud is not in use. Verify that `settings_screen_test.dart` passes with the new copy.

## 5. Composition root

- [x] 5.1 Make `CloudStorageModule` expose `decision: StorageDecision` and wire `ResolveStorageDecision`, `AdoptDeviceLibrary` and the merge-enabled `_migrate` through constructors. Verify with the updated `cloud_storage_module` unit tests.
- [x] 5.2 Add `onRecompose` and `forceLocalThisSession` parameters to `buildDocScanly`, and switch exhaustively on `StorageDecision`. `migrateToICloud` returns `CloudMigrationGateApp`, `useLocal` composes on the local store, and `useICloud` writes the marker if it is absent. Verify with `doc_scanly_test.dart` cases for each decision.
- [x] 5.3 Pass a recompose closure from `_BootstrapApp` in `lib/main.dart`, and thread it through `bootDocScanly` in `integration_test/support/app_boot.dart`. Verify that the app boots on the simulator and that `flutter analyze` is clean.
- [x] 5.4 Add `cloud_storage_use_device` and its adaptive confirmation dialog (`cloud_storage_use_device_confirm`) to `CloudLibraryUnavailableApp`. Confirming calls `AdoptDeviceLibrary` and then recompose. Verify with a Tier-1 widget test covering confirm and dismiss.
- [x] 5.5 Add a Tier-2 component test for the unavailable app plus the escape, using the real use case and preferences and a scripted platform. Verify that confirming opens the device library and that dismissing leaves authority unchanged.
- [x] 5.6 Add dartdoc to the new public APIs and an inline comment in `doc_scanly.dart` explaining why the gate precedes composition (the single-inventory constraint). Verify by reviewing the diff and running `dart doc --dry-run` without warnings for the touched libraries. (dartdoc 9.0.6 crashes with a `RangeError` in `_stripDocImports` on this repository both before and after this change, so the dry run cannot be used; the docs were reviewed in the diff instead.)

## 6. Test fixtures and end-to-end flows

- [x] 6.1 Extend `ScriptedICloudPlatform` with scripts for disabled/restricted availability, established marker with content, and a mid-migration outage (`scheduleOutage`). Quota exhaustion comes from the real file store rather than the platform edge, so it is covered in Tier 1/2 with a quota-failing store, and Tier 3 uses the scripted outage for gate failure. Verify with `scripted_icloud_platform_test.dart`.
- [x] 6.2 Update `CloudStorageRobot` to add `waitForMigrationGate`, `continueAfterMigration`, `continueOnDevice`, `retryMigration`, `moveNow`, `useDeviceWithoutICloud` and `expectStatus(reason)`, and remove `moveLibraryToICloud`/`chooseUnavailableICloud`. All steps must drive the app only through D8 keys and semantics. Verify that the flows compile.
- [x] 6.3 Rewrite `integration_test/flows/icloud_library_sync_test.dart` around these journeys:
  - fresh install goes straight to iCloud
  - a seeded device library passes through gate → completion → iCloud root (Trash preserved)
  - gate quota failure → continue on device → relaunch retries
  - signed out → device fallback with reason → sign in → move now → gate
  - an established marker with a conflicting path → a `(Conflict device)` copy is listed
  - unavailable iCloud authority → use device → confirm
  - new-device discovery
  - lazy download
  - refresh

  Verify that the flow passes on the iOS Simulator, or on Android where it is skipped with an iOS-only guard as today. (iPhone 16 Pro simulator: 7/8 pass; "new device discovers…" fails identically on the pre-change code, a pre-existing launch-reconciliation issue outside this change.)
- [x] 6.4 Check `first_launch_test.dart` and `settings_and_app_lock_test.dart` on iOS with an available scripted container, and update any step that assumed the local default. Verify that both flows pass. (first_launch passes; settings_and_app_lock's "a changed setting is still there" fails identically on the pre-change code.)

## 6a. Onboarding privacy wording

- [x] 6a.1 Make the onboarding privacy step's storage and upload statements platform-true via `OnboardingScreen.usesICloudLibrary` (passed from the composition root when iOS cloud storage exists), with the copy held in `OnboardingCopy`, keys unchanged, and iOS `@Preview()` entries. Verify with the updated `onboarding_screen_test.dart` (Android and iOS copy, device-only promises absent on iOS), the preview render test, and the conventions audit.

## 7. Documentation

- [x] 7.1 Update the README storage section: iCloud by default, automatic migration gate, device fallback reasons, the use-device escape, merge conflict naming, and that iOS Settings → iCloud → DocScanly off is the way to keep documents on the device. Verify that the README matches the implemented keys and behaviour.

## 8. Integration verification

- [x] 8.1 Run `dart format --set-exit-if-changed .` and `flutter analyze`, and check with `dart` MCP `analyze_files` that both are clean.
- [x] 8.2 Run `dart run tool/check_coverage.dart` and confirm overall coverage is ≥ 80% and `cloud_storage` business logic is ≥ 90%.
- [ ] 8.3 Run `dart run tool/verify.dart` and report the result for every stage. The change is done only when every stage passes and Tier 3 actually ran on an Android emulator/device or a usable iOS Simulator. A SKIPPED Tier 3 is not verified.
