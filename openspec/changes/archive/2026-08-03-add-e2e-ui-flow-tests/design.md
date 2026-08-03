## Context

The repository has 118 unit/widget test files, 19 goldens and three device-level integration tests, and a user-visible flow is broken anyway. A survey of the codebase explains why:

- **No test anywhere constructs `DocForgeApp`.** The three files in `integration_test/` drive `PublicFileStore`, `RenderPage` and the PDF composer directly. Nothing pumps the app, taps a control, or crosses a route.
- **`main.dart` has no seam.** `main()` (`lib/main.dart:89`) is a ~350-line function that wires everything inline and ends at `runApp` (`:337`). The screen set is built by a *private* `_screens(...)` (`:340`) taking 17 positional parameters. A test cannot call either.
- **The pieces are already fake-ready; the assembly is not.** `AppDependencies` (`lib/app/app_dependencies.dart:32`) is constructor-injected with a `buildFakeAppDependencies(...)` (`lib/app/composition_root.dart:66`) that is deterministic by construction — `FixedClock`, `SequentialIdGenerator`, `InlineBackgroundWorker`. `DocForgeApp` (`lib/app/app.dart:22`) reaches for nothing. `createAppRouter(...)` (`lib/app/router/app_router.dart:110`) takes its `AppScreens` as an argument and imports no feature. Most modules accept substitutes: `buildSharingModule(share:, printer:, picker:)`, `buildImportModule(gallery:, files:, shared:)`, `buildDocumentCreationModule(recogniser:)`, `buildPdfEditingModule(editor:)`, `buildScanningModule(detector:)`, and `buildLibraryModuleOver(isar:, documentsDirectory:)` which exists explicitly so an integration test can supply a temporary database.
- **Four platform edges have an interface and a shipped fake but no injection point.** `CameraScannerRepository` is hardcoded in `buildScanningModule` (`lib/app/scanning_module.dart:89`) despite `FakeScannerRepository` existing beside it; `LocalAuthAuthenticator` is `const`-constructed in `main.dart:433` and `:462` despite `FakeDeviceAuthenticator`; `PdfrxRenderer` at `main.dart:147`, `:214`, `:521` despite `FakePdfRenderer`; `buildPublicFileStore(...)` at `main.dart:104`.
- **The key convention is already strong.** Sixteen `*_keys.dart` files declare `abstract final class XKeys` of `static const Key('<feature>_<element>')`, documented as normative and sourced from the specs, including a parameterised `LibraryKeys.documentListItem(String documentId)`. Coverage is dense on `pdf_edit_screen` (18 keys), `settings_screen` (16), `dashboard_screen` (15), `crop_screen` (15). Gaps: `folder_detail_screen.dart` has zero keys and delegates to `DocumentListScreen`, so a test cannot tell folder-detail from the plain list; `AppTabScaffold` gives its tab destinations a dynamic `buttonKey` rather than constants; semantics labels are 132 inline strings across 28 files with no constants file, so they are not yet a reliable selector.
- **Two screens are pushed imperatively**, bypassing GoRouter: crop and enhance via `Navigator.push` in `lib/app/scanning_module.dart:124` and `:144`, and About/Privacy at `main.dart:394`/`:404`. A URL-driven test cannot reach them; a tap-driven test can.
- **Cold start does not land on the dashboard.** `RouteGuard.redirectFor` (`lib/app/router/route_gates.dart:44`) sends the app to `/unlock` then `/onboarding` before `/`. `FakeAppLockGate` and `FakeOnboardingGate` already ship in `lib/` for exactly this.

Constraints: Android and iOS only; flutter_bloc only; explicit constructor DI, no service locator; no new runtime dependencies; the fake platform layer must not be reachable from a release build.

## Goals / Non-Goals

**Goals**

1. Give the app one public composition seam so a test can boot the real widget tree with only the platform edge substituted.
2. Close the four injection gaps (scanner, device authenticator, PDF renderer, public file store) so the seam is actually complete.
3. Add a Tier‑3 end-to-end suite under `integration_test/flows/` that drives the app through keys and semantics only.
4. Add a Tier‑2 component tier that wires screens to their real Cubits and real use cases, which today's widget tests do not.
5. Make the whole pyramid runnable as one command whose output an agent can act on.
6. Encode the three-tier requirement in `openspec/config.yaml` so it binds every future change.

**Non-Goals**

- Rewriting the 118 existing test files. The tier boundary is enforced going forward; existing widget tests stay where they are.
- Testing OS-level surfaces the framework cannot reach — the real system share sheet, the real print dialog, the real biometric prompt. Those are asserted at the fake's boundary: the right file and metadata arrive, the right call is made.
- Adding `patrol`, `flutter_driver` or any device-automation dependency.
- Changing product behaviour, routes, the Isar schema, or any stored key.
- Testing web or desktop. Neither is a target.

## Decisions

### D1 — Extract `buildDocForge(...)` from `main()` rather than duplicating it in the test harness

`main()` and `_screens(...)` move into a public, parameterised builder in `lib/app/` that returns the configured root widget; `main.dart` shrinks to `runApp(await buildDocForge())`. Every hardcoded platform service becomes a named optional parameter defaulting to the real implementation, so production behaviour is byte-identical and a test passes only what it needs to replace.

*Alternative rejected — duplicate the wiring in `integration_test/support/`.* It is the cheaper first move and the standard one, and it is exactly why E2E suites rot: the harness drifts from `main` and then proves something the user never runs. The 17-parameter private `_screens` makes the duplication especially costly.

*Alternative rejected — a service locator or `@visibleForTesting` global overrides.* Explicitly barred by the project's DI rules, and it reintroduces the global mutable state the AI-implementation guidelines forbid.

`_screens` also gets split: 17 positional parameters is past the point where a caller can supply them correctly. It becomes a small number of per-feature screen builders assembled into `AppScreens`, which is what `createAppRouter` already expects.

### D2 — Substitute at the platform edge only, and use real Isar and real files

Tier‑3 fakes exactly seven things: camera capture, OCR recognition, edge detection, biometric authentication, share, print, and file/gallery pickers. Isar, `path_provider` directories and the public file store stay real, seeded per flow into a temporary directory via the existing `buildLibraryModuleOver(isar:, documentsDirectory:)`.

The rationale is that most reported breakage in an offline-first document app lives precisely in persistence and file handling. A suite that fakes the database proves the UI is self-consistent and nothing about whether the user's document survives.

*Alternative rejected — fake everything below presentation.* Faster and fully headless, but it is Tier 2 with extra steps, and it would not have caught the flow that is broken today.

`buildFakeAppDependencies(...)` supplies the deterministic clock, id generator and inline worker, so no flow depends on wall-clock time or on isolate scheduling order.

### D3 — Drive through keys; add a semantics-constants file to match the keys file

Flows locate elements by `Key('<feature>_<element>')` only. The sixteen existing `*_keys.dart` registries are the contract and need extending, not replacing:

- `folder_detail_screen.dart` gains its own `library_folder_detail_*` keys so a flow can distinguish it from `DocumentListScreen`.
- `AppTabScaffold` gains one `static const Key` per destination rather than the current dynamic `buttonKey`, so tab navigation is addressable.
- `AppLockObserver`, `SharedContentWatcher` and `LibraryReconciler` — the three behavioural wrappers around the whole app in `main.dart:325-334` — gain keys so a flow can assert they are mounted.
- Thinly-keyed widgets (`settings_widgets.dart`, `page_row.dart`, `folder_tile.dart`, `page_thumbnail.dart`, `enhancement_widgets.dart`, `share_widgets.dart`, `onboarding_screen.dart`) gain keys for every control a catalogued flow touches.

Semantics labels become `static const String` alongside the keys, mirroring the keys convention, so accessibility assertions have a stable target instead of 132 inline literals.

*Alternative rejected — find by text.* Text moves, and localisation would break every flow at once.

### D4 — Robots, not raw `tester` calls, in flow files

Each screen gets a robot in `integration_test/support/robots/` exposing intent-level methods (`DashboardRobot.openDocument(id)`, `ScanRobot.captureTwoPages()`), each of which waits for its screen's key, acts, and settles. Flow files read as the user journey and nothing else.

This matters more than usual here: a screen that gains a step should break one robot, not nine flows. It also makes the failure message name the step, which is required for the gate's output to be actionable.

Settling uses a bounded `pumpUntilFound(key, timeout:)` helper rather than bare `pumpAndSettle()`, because the render and PDF pipelines run real work and an unbounded settle either hangs or races.

### D5 — Crop and enhance are reached by tapping, not by URL

Because `openPageCrop` and `openPageEnhance` are imperative `Navigator.push` calls, the capture-to-document flow navigates them the way a user does. That is the correct level for Tier 3 anyway; no routing change is proposed to accommodate the tests.

### D6 — One flow file per journey, each seeding and cleaning its own state

Ten flow files, one per catalogued journey, each with its own temporary Isar and documents directory torn down afterwards. No flow depends on another, so any subset can be run to check one thing — which is what an agent iterating on a fix will actually do.

*Alternative rejected — one long test that walks the whole app.* Fewer boots and faster, but a failure anywhere blocks every later assertion, and it cannot answer "is the import flow fixed yet?".

### D7 — `tool/verify.dart` sequences the pyramid and summarises it

The gate runs, in order: `dart format --set-exit-if-changed`, `flutter analyze`, `tool/check_layering.dart`, `tool/check_platforms.dart`, Tier‑1 + Tier‑2 (`flutter test`), goldens, `tool/check_coverage.dart`, then Tier‑3 (`flutter test integration_test/flows -d <device>`). It exits non-zero on the first failure, prints a per-stage pass/fail table with per-flow timings, and — when no device is attached — marks Tier‑3 *skipped* and the overall result *incomplete*, never *passed*. Reporting a device-less run as green is the single most likely way this gate would lull an agent into shipping a broken flow.

*Alternative rejected — a shell script.* `tool/` is already Dart (`check_coverage.dart`, `check_layering.dart`, `check_platforms.dart`); staying in Dart keeps it analysable and testable, and `test/tool/` already exists.

### D8 — Enforce the seam's one-way street with the existing layering check

`tool/check_layering.dart` gains a rule: production `main.dart` must not transitively import the test entrypoint or any `Fake*` platform implementation. The fakes deliberately live in `lib/` — they already do, and the previews need them there — so a lint is the only thing standing between that convenience and shipping a fake to users.

### D9 — Tier 2 is added alongside existing widget tests, not by rewriting them

Current widget tests stub the Cubit, so screen↔Cubit↔use-case wiring is unproven. New `test/features/<feature>/component/` tests construct the real Cubit over real use cases with faked repositories, reusing the fakes already in `test/features/*/fakes.dart` and `*_test_support.dart`. The duplicated `_screens()` marker sets in `test/app/router/app_router_test.dart:11` and `creation_navigation_test.dart:17` are consolidated into one shared harness while we are there.

## Risks / Trade-offs

- **Refactoring `main()` breaks startup** → The extraction is behaviour-preserving by construction: every new parameter defaults to today's hardcoded implementation. It lands as its own task, verified by running the app before writing a single flow.
- **A flow encodes the current bug instead of catching it** → Flows are written from the feature specs' required behaviour. The journey that is broken today must be demonstrated failing before the fix, then passing.
- **Real Isar and real files make flows slow and order-dependent** → Each flow owns a temporary directory and database and tears it down; the gate reports per-flow timing so a regression in cost is visible rather than absorbed.
- **Bounded waits turn a slow device into a flake** → Timeouts are generous and per-step, and a timeout failure names the key it was waiting for, which distinguishes "slow" from "never appeared".
- **Fakes in `lib/` reach a release build** → D8's layering rule, plus `main.dart` never importing the test entrypoint.
- **The key registry drifts from the screens** → Flows fail loudly when a registered key is absent from the built tree, and `config.yaml` requires flows to be updated in the same change that moves the UI.
- **Ten flows is a lot of surface to maintain** → Robots concentrate the coupling; a screen change touches one robot.
- **The gate cannot prove the real share sheet, print dialog or biometric prompt work** → Accepted and stated in the Non-Goals. Those are asserted at the fake boundary, and remain the small residue of genuinely manual testing.

## Migration Plan

1. Extract `buildDocForge(...)`, split `_screens`, close the four injection gaps. Run the app on a device; no behaviour change.
2. Add the layering rule and the semantics constants; extend the key registries and apply the missing keys.
3. Build `integration_test/support/` — app boot helper, fixture assets, fake platform bundle, robots.
4. Add flows one at a time, starting with the journey that is broken today so the suite's first act is to reproduce it.
5. Add the Tier‑2 component tests for the screens those flows traverse.
6. Add `tool/verify.dart`; wire CI to call it.
7. Update `openspec/config.yaml`.

Rollback: every step is additive except step 1, which is a single revertible commit. Reverting the flows leaves the app exactly as it is today.

## Open Questions

- Which device and simulator pair is CI's baseline for Tier 3? The suite must be green on one of each; the specific models are an infrastructure decision, not a design one.
- Whether the OCR flow asserts on recognised text from a fixture image through the real ML Kit path on-device, or only through `FakeOcrRepository`. The fake is the default; a device-only OCR assertion could be added later as a separate flow if recognition regressions prove to be a real failure mode.
