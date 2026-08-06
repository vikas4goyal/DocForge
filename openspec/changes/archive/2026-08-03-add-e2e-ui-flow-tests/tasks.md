## 1. Composition seam

- [x] 1.1 Extract a public `buildDocForge({...})` from `main()` (`lib/main.dart:89-337`) into `lib/app/`, returning the configured root widget; reduce `main.dart` to `runApp(await buildDocForge())`. Every platform service currently hardcoded becomes a named optional parameter defaulting to today's real implementation — behaviour must be byte-identical.
- [x] 1.2 Split the private `_screens(...)` (`lib/main.dart:340`, 17 positional params) into per-feature screen builders assembled into `AppScreens`; make the assembly public and callable from a test.
- [x] 1.3 Add a `ScannerRepository` parameter to `buildScanningModule` (`lib/app/scanning_module.dart:89`), defaulting to `CameraScannerRepository`.
- [x] 1.4 Route `DeviceAuthenticator` (`lib/main.dart:433,462`), `PdfRenderer` (`:147,214,521`) and the public file store (`:104`) through `buildDocForge` parameters, defaulting to `LocalAuthAuthenticator`, `PdfrxRenderer` and `buildPublicFileStore`.
- [x] 1.5 Add dartdoc to every new public API from 1.1–1.4 (what it builds, each parameter, what it defaults to and why) and inline comments where a default encodes a platform constraint.
- [ ] 1.6 Verify the refactor on a real device: launch the app, walk onboarding → dashboard → open a document, and confirm no behavioural change.
- [x] 1.7 Unit-test `buildDocForge`: it builds with all defaults, each override is honoured, and the resulting tree matches the pre-refactor structure.

## 2. Test-only seam containment

- [x] 2.1 Add a rule to `tool/check_layering.dart`: production `main.dart` must not transitively import the test entrypoint or any `Fake*` platform implementation.
- [x] 2.2 Add a test in `test/tool/` proving the new layering rule fails when a fake is imported from the production entrypoint and passes otherwise.

## 3. Widget keys and semantics registry

- [x] 3.1 Add `library_folder_detail_*` keys for `folder_detail_screen.dart` (currently zero keys) so a flow can distinguish it from `DocumentListScreen`, and apply them.
- [x] 3.2 Replace `AppTabScaffold`'s dynamic `buttonKey` (`app_tab_scaffold.dart:121`) with one `static const Key` per tab destination and apply them.
- [x] 3.3 Add keys to `AppLockObserver`, `SharedContentWatcher` and `LibraryReconciler` so a flow can assert the app-wide wrappers are mounted.
- [x] 3.4 Add keys for every control the catalogued flows touch in the thinly-keyed widgets: `settings_widgets.dart`, `page_row.dart`, `folder_tile.dart`, `page_thumbnail.dart`, `enhancement_widgets.dart`, `share_widgets.dart`, `onboarding_screen.dart`.
- [x] 3.5 Introduce `static const String` semantics labels alongside the keys in each `*_keys.dart`, replacing the inline literals on every control a flow drives.
- [x] 3.6 Add semantics labels where they are absent on driven surfaces: `folder_detail_screen.dart`, `library_dialogs.dart`, `save_name_dialog.dart`.
- [x] 3.7 Add a test asserting every key declared in a `*_keys.dart` registry is present in the built tree of its screen, so a renamed or dropped key fails loudly.
- [x] 3.8 Re-run the existing `@Preview()` entries for every screen touched in 3.1–3.6 and confirm each still renders in all its previewed states, themes and form factors.
- [x] 3.9 Re-record any golden affected by a keyed or semantics change and confirm the diff is empty of visual change.

## 4. End-to-end support harness

- [x] 4.1 Create `integration_test/support/app_boot.dart`: boots `buildDocForge` with `buildFakeAppDependencies(...)`, a per-flow temporary Isar and documents directory via `buildLibraryModuleOver(isar:, documentsDirectory:)`, and teardown.
- [x] 4.2 Create `integration_test/support/fake_platform.dart` bundling the fakes that already ship in `lib/`: `FakeScannerRepository`, `FakeOcrRepository`, `FakeDeviceAuthenticator`, `FakePdfRenderer`, `FakeShareRepository`, `FakePrintRepository`, `FakeExportDestinationPicker`, `FakeGalleryPicker`, `FakeFileBrowser`, `FakeSharedContentSource`, `FullPageEdgeDetector`.
- [x] 4.3 Add checked-in fixture assets (page images, a source PDF, an importable file) containing no real personal data, and wire them into the fakes.
- [x] 4.4 Add `pumpUntilFound(key, timeout:)` and a step-naming helper so a timeout failure reports the key it waited for and the step that was running.
- [x] 4.5 Write screen robots in `integration_test/support/robots/` exposing intent-level methods for: onboarding, unlock, dashboard, tab shell, scan/capture, crop, enhance, page table, PDF generation, document list, folder detail, document detail, viewer, PDF edit, search, share, settings.
- [x] 4.6 Add a determinism test: the harness produces identical state across two consecutive boots, and no fake reads the wall clock, generates randomness, or touches the network.
- [x] 4.7 Dartdoc the harness: what each robot drives, what each fake returns, and how a flow seeds and cleans its own state.

## 5. End-to-end flows

- [x] 5.1 Write the flow for the journey that is broken today first; demonstrate it failing before any fix, and record what it proves.
- [x] 5.2 `flows/first_launch_test.dart` — onboarding completes and the app lands on the dashboard (accounting for the `/unlock` → `/onboarding` → `/` redirect chain in `route_gates.dart:44`).
- [x] 5.3 `flows/capture_to_document_test.dart` — capture pages, enhance, create the page table, generate the PDF, open it in the viewer. Crop and enhance are reached by tapping, since they are imperative `Navigator.push` targets.
- [x] 5.4 `flows/page_table_test.dart` — build a page table, reorder and remove pages, confirm the generated document reflects the final order.
- [x] 5.5 `flows/import_test.dart` — import a file and confirm it appears in the library.
- [x] 5.6 `flows/browse_and_view_test.dart` — open a document from the library, read it in the viewer, return to the originating screen.
- [x] 5.7 `flows/search_test.dart` — search the library and open a result.
- [x] 5.8 `flows/organise_test.dart` — rename, favourite, move to a folder, archive and delete a document.
- [x] 5.9 `flows/edit_test.dart` — modify a document with the editing tools and confirm the saved result changed.
- [x] 5.10 `flows/share_test.dart` — invoke share and assert the correct file and metadata reach the fake share boundary.
- [x] 5.11 `flows/settings_and_lock_test.dart` — change a setting and confirm it persists; enable the app lock and confirm a relaunch requires unlocking.
- [x] 5.12 Run every flow file in a shuffled order and confirm each passes independently of the others.
- [ ] 5.13 Confirm the whole flow suite is green on one Android device and one iOS simulator.

## 6. Component tier

- [x] 6.1 Create the `test/features/<feature>/component/` convention and a shared harness that mounts a screen with its real Cubit over real use cases and faked repositories.
- [x] 6.2 Consolidate the duplicated `_screens()` marker sets in `test/app/router/app_router_test.dart:11` and `test/app/router/creation_navigation_test.dart:17` into that shared harness.
- [x] 6.3 Component tests for the library screens: dashboard, document list, folder detail, document detail.
- [x] 6.4 Component tests for the creation screens: capture, crop, enhance, page table, generation.
- [x] 6.5 Component tests for viewer, PDF edit, search, share and settings.
- [x] 6.6 Component test for onboarding and the app lock screen.
- [x] 6.7 Add a `bloc_test` Cubit test for any Cubit whose emitted state sequence the component tier reveals as untested.

## 7. Verification gate

- [x] 7.1 Write `tool/verify.dart` running, in order: `dart format --set-exit-if-changed`, `flutter analyze`, `check_layering`, `check_platforms`, Tier‑1 + Tier‑2, goldens, `check_coverage`, Tier‑3.
- [x] 7.2 Make it exit non-zero on the first failing stage and print a per-stage pass/fail summary naming the failing flow and step.
- [x] 7.3 Report per-flow timing in the summary.
- [x] 7.4 With no device or simulator attached, run every other stage and report Tier‑3 as *skipped* and the overall result as *incomplete* — never *passed*.
- [x] 7.5 Test `tool/verify.dart` in `test/tool/`: stage ordering, non-zero exit on failure, and the no-device summary.
- [x] 7.6 Wire CI to call `tool/verify.dart` in place of its current sequence.

## 8. Workflow enforcement

- [x] 8.1 Update the `tasks` rules in `openspec/config.yaml` to require, for every future change: a Tier‑1 unit task, a Tier‑2 component task, a Tier‑3 end-to-end flow task for each user-visible journey touched, and a final task that runs `tool/verify.dart` and reports its outcome before the change is done.
- [x] 8.2 Update the `specs` rules in `openspec/config.yaml` to require new user-visible behaviour to name the `Key('<feature>_<element>')` and semantics label its flow will drive.
- [x] 8.3 Add the three-tier definition and the flow catalogue to the project context in `openspec/config.yaml`, so an agent planning a change knows which tier proves what.

## 9. Completion

- [x] 9.1 `dart format` and `flutter analyze` clean across the repository.
- [x] 9.2 Coverage ≥80% overall and ≥90% on business logic.
- [x] 9.3 Run `tool/verify.dart` end to end on a device and confirm every stage passes.
- [x] 9.4 Confirm the flow catalogue in the spec matches the files in `integration_test/flows/` exactly, in both directions.
