## Why

The app has 118 unit/widget test files and 19 goldens, yet a user-visible flow is broken right now — because nothing in the suite launches the real app and walks a user through it. The three files under `integration_test/` drive storage, the render pipeline and the PDF composer directly; none of them pump the app widget, tap a button, or navigate a route. That leaves a gap where every piece passes in isolation and the assembled product still fails, and it pushes verification back onto manual tapping.

This change establishes an explicit three-tier verification pyramid — **unit → component → end-to-end UI** — and makes the top tier a first-class, AI-runnable gate, so an agent can prove a flow works after implementing it instead of the user testing by hand.

## What Changes

- **Name and separate the three tiers.** Today "unit", "widget" and "integration" are used loosely across overlapping folders. Each tier is defined by what it proves, where it lives, and what it may touch:
  - **Tier 1 — Unit**: one class, no widget tree. Entities, value objects, use cases, mappers, failures, Cubits (via `bloc_test`), repository implementations against fakes. Location: `test/**`. Largely present already; this change only formalises the boundary.
  - **Tier 2 — Component**: one screen or one widget subtree wired to its *real* Cubit and *real* use cases, with infrastructure faked at the repository boundary. Proves a screen and its state machine agree. Location: `test/features/<feature>/component/`. **Mostly missing today** — current widget tests stub the Cubit, so screen↔Cubit↔use-case wiring is never exercised.
  - **Tier 3 — End-to-end UI**: the whole composed app under `IntegrationTestWidgetsFlutterBinding`, started from the real composition root with only platform-edge services faked (camera, ML Kit, OpenCV, biometrics, share sheet, print). Drives the app exclusively through widget keys and semantics — taps, scrolls, text entry, route transitions. Location: `integration_test/flows/`. **Missing entirely.**
- **Add an end-to-end UI flow suite** covering the journeys a user actually performs: onboarding → dashboard; import a document → it appears in the library; capture → enhance → create pages → generate PDF → it opens in the viewer; page table creation; search and open; rename and delete; share; PDF edit and save; settings and the app lock. Each flow is one test file with a stated precondition, a scripted user path, and assertions on user-visible outcomes.
- **Add a testable composition seam.** The E2E suite must boot the real app with fakes at the platform edge only. This change introduces an explicit test entrypoint that builds the same widget tree as `main.dart` from an overridable dependency bundle — no service locator, no global mutable state, dependencies still passed through constructors.
- **Add a stable widget-key and semantics registry.** E2E tests never match on user-visible text (it moves, it localises). Every screen and control an E2E flow touches gains a `Key('<feature>_<element>')` and a semantics label, catalogued in one place so tests and implementation cannot drift apart.
- **Add a deterministic fake platform layer** for camera capture, OCR, edge detection, biometrics, share and print, plus fixture image and PDF assets, so a run is repeatable and produces the same states every time.
- **Add one runner command** that executes the pyramid in order — format, analyse, unit, component, golden, E2E — and reports *which flow* broke. This is what an AI agent invokes; it must not require the user to interpret raw device logs.
- **Update `openspec/config.yaml`** so the `tasks` rules require, for every future change: a Tier‑1 task, a Tier‑2 component task, a Tier‑3 E2E flow task for any user-visible flow touched, and a final task that runs the E2E suite and reports its result before the change is done. The `specs` rules gain a requirement to name the widget keys each new flow exposes. This is the durable part — it makes every subsequent change verified this way, not just this one.

No user-facing product behaviour changes. Android and iOS remain the only targets; nothing here introduces web or desktop support.

## Capabilities

### New Capabilities
- `automated-verification`: The project's testing contract — the three tiers and what each proves, the end-to-end UI flow catalogue and the outcomes each flow asserts, the widget-key and semantics stability guarantee that UI tests depend on, the determinism rules for faked platform edges, and the verification gate an agent runs after implementation.

### Modified Capabilities

None. No existing capability's required product behaviour changes; the widget keys and semantics labels that flows rely on are catalogued in `automated-verification` and referenced from feature specs rather than duplicated into each one.

## Impact

**Architecture.** No layer boundaries move. The only production-code changes are a test-visible composition seam in `lib/app/` and widget keys plus semantics labels on existing screens and controls.

Resulting structure:

```
lib/app/
  composition_root.dart      # unchanged responsibility; gains an overridable
                             #   dependency bundle so tests can substitute the
                             #   platform edge
  app_dependencies.dart      # explicit fields for platform-edge services
  test_entrypoint.dart       # (new) builds the same tree as main.dart from a
                             #   supplied AppDependencies — no logic of its own
lib/features/<feature>/presentation/
  screens/, widgets/         # gain Key('<feature>_<element>') + semantics only

integration_test/
  flows/                     # (new) one file per user journey, Tier 3
  support/                   # (new) app boot helper, flow robots, fake
                             #   platform services, fixture assets
  creation_flow_test.dart    # existing engine-level tests stay as they are
  pdf_engine_smoke_test.dart
  public_library_test.dart
test/features/<feature>/
  component/                 # (new) Tier 2 — screen + real Cubit + real use
                             #   cases + faked repositories
tool/
  verify.dart                # (new) runs the pyramid in order, reports failures
```

**Cubits / States / use cases / repositories / Isar schema / navigation.** None added or changed. Tier‑2 and Tier‑3 tests consume the existing ones; the fakes implement existing repository and platform interfaces. No Isar schema migration, no new preference or secure-storage keys, no route changes — the E2E suite asserts against the current typed GoRouter routes.

**Dependencies.** No new runtime dependencies. Dev-side, `integration_test` and `flutter_test` are already present; `mocktail` covers the fakes and `alchemist` the goldens. If a device-driving helper for OS-level dialogs is later judged necessary, it will be proposed separately with a licence check — this change deliberately stays on the first-party `integration_test` binding so it runs in CI without extra infrastructure.

**Migration.** None at the data layer. The migration is procedural: existing widget tests that stub Cubits stay as they are, and Tier‑2 component tests are added alongside them rather than rewriting 118 files at once.

**Performance.** Test-time only. The E2E suite boots the full app per flow, so it is the slowest tier by design. Flows are independent and each seeds its own store so they run in any order, and the runner reports per-flow timing so a slow flow is visible rather than silently dragging CI.

**Security.** The fake platform layer must never be reachable from a release build — the test entrypoint lives in a file that production `main.dart` does not import, and `tool/check_layering.dart` enforces it. Fixture assets contain no real personal data. No credentials or tokens are introduced.

**Testing strategy.** This change *is* the testing strategy. Concretely it delivers Tier‑2 component tests for every screen an E2E flow traverses, the Tier‑3 flow suite itself, goldens left untouched, and a runner that sequences all of it. Coverage stays ≥80% overall and ≥90% on business logic; the new tiers raise it rather than lower it.

**Preview coverage.** No new widgets, so no new `@Preview()` entries are required. Where a screen gains a widget key, its existing previews are re-verified to still render.

**Definition of Done.**
1. `integration_test/flows/` contains a passing test for every flow in the catalogue, each driven only through widget keys and semantics.
2. Every screen and control those flows touch has a stable `Key('<feature>_<element>')` and a semantics label, listed in the registry.
3. `test/features/<feature>/component/` covers each screen in a flow with its real Cubit and real use cases.
4. The runner executes format → analyse → unit → component → golden → E2E, exits non-zero on any failure, and names the failing flow.
5. The E2E suite is green on one Android device and one iOS simulator.
6. `openspec/config.yaml` requires the three tiers and the post-implementation E2E check on every future change.
7. `dart format`, `flutter analyze`, layering and platform checks pass; coverage ≥80%.

**Risks and mitigations.**
- *E2E tests are flaky.* Mitigated by faking every platform edge, forbidding wall-clock and randomness in fakes, driving only through keys, and using explicit settle guards with bounded timeouts rather than fixed delays.
- *Tests re-encode current bugs instead of catching them.* The flow catalogue is written from the specs' required behaviour, not from what the code does today; the flow that is broken now must fail first, then pass.
- *The suite rots as screens change.* The key registry is the single point of coupling, and `config.yaml` forces every future change to update flows in the same change that moves the UI.
- *Slow CI.* Tiers run in order and fail fast; only Tier 3 needs a device.
- *The composition seam leaks into production.* Enforced by the layering check and by production `main.dart` never importing it.

**Future extensibility.** The same seam that substitutes fake platform services will substitute a fake sync backend when cloud sync lands, so sync flows join the catalogue without restructuring. The flow catalogue also gives an AI agent a stable, machine-readable definition of what "working" means for this app.
