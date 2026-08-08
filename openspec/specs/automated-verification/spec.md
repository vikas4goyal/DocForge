# automated-verification Specification

## Purpose

Define the three-tier automated-test pyramid, deterministic platform seams, stable UI keys and semantics, end-to-end journey catalogue, and single verification gate required to prove DocScanly changes across unit, component, and real-application flows.

## Requirements

### Requirement: Three-tier verification pyramid

The project SHALL classify every automated test into exactly one of three tiers, and each tier SHALL be identifiable by its location on disk without reading the test body.

- **Tier 1 — Unit**: exercises one class with no widget tree. Lives under `test/**` outside a `component/` folder. Covers entities, value objects, use cases, mappers, failures, Cubits (via `bloc_test`), repository implementations, and serialization.
- **Tier 2 — Component**: exercises one screen or widget subtree wired to its real Cubit and real use cases, with infrastructure substituted at the repository boundary. Lives under `test/features/<feature>/component/`.
- **Tier 3 — End-to-end UI**: exercises the whole composed application under `IntegrationTestWidgetsFlutterBinding`, substituting only platform-edge services. Lives under `integration_test/flows/`.

A test SHALL NOT span tiers: a Tier‑2 test MUST NOT construct the app's router or composition root, and a Tier‑3 test MUST NOT construct a Cubit, use case, or repository directly.

#### Scenario: Tier is derivable from location

- **WHEN** a reviewer or agent inspects the path of any test file in the repository
- **THEN** the tier is unambiguous from the path alone, and no file sits in a location that implies a tier it does not satisfy

#### Scenario: Component test uses the real state machine

- **WHEN** a Tier‑2 component test renders a screen
- **THEN** the screen is driven by its production Cubit and production use cases, and only the repository interfaces are substituted with fakes

#### Scenario: End-to-end test drives only the UI

- **WHEN** a Tier‑3 flow test runs
- **THEN** it interacts with the application solely through widget finders, taps, scrolls, text entry and route transitions, and it never reads or mutates a Cubit, use case or repository directly

### Requirement: End-to-end UI tests boot the real application

Tier‑3 tests SHALL launch the application through the same composition root that `main.dart` uses, substituting only services that sit at the platform edge — camera capture, OCR recognition, edge detection, biometric authentication, the share sheet and the print dialog.

Every other dependency, including the router, all Cubits, all use cases, all repositories and real on-device storage, SHALL be the production implementation.

The test entrypoint used to supply substituted dependencies SHALL NOT be reachable from a release build, and production `main.dart` SHALL NOT import it.

#### Scenario: Flow starts from a cold app launch

- **WHEN** a Tier‑3 flow test begins
- **THEN** the application is built from the composition root with a supplied dependency bundle, and the widget tree is identical in structure to the one `main.dart` produces

#### Scenario: Real persistence is exercised

- **WHEN** a flow creates or modifies a document
- **THEN** the change is written through the production repository to real device storage, and a subsequent screen in the same flow reads it back through the production path

#### Scenario: Test seam is absent from production

- **WHEN** the layering check runs over `lib/`
- **THEN** it fails if `main.dart` transitively imports the test entrypoint or any fake platform service

### Requirement: End-to-end flow catalogue

The project SHALL maintain a catalogue of user journeys covered by Tier‑3 tests, with one test file per journey. The catalogue SHALL cover at minimum:

1. **First launch** — onboarding completes and the app lands on the dashboard.
2. **Capture to document** — capture pages, enhance them, create the page table, generate the PDF, and open the result directly in Viewer.
3. **Page table creation** — build a page table, reorder and remove pages, and confirm the generated document reflects the final order in Viewer.
4. **Import** — import an existing file, confirm it appears in the library, and open it directly in Viewer without eager page preview generation.
5. **Browse and view** — open a document directly from the library in Viewer, read and jump within it, open Details from Viewer, and return to the originating surface.
6. **Search** — search the library and open a result directly in Viewer.
7. **Organise** — open Details from Viewer, rename, favourite, move to a folder, archive, and delete a document while verifying Viewer metadata reconciliation or closure.
8. **Edit** — modify a document with the editing tools and confirm the saved result opens directly in Viewer and changed.
9. **Share** — invoke share on a document and confirm the correct file and metadata reach the share boundary.
10. **Settings and lock** — change a setting and confirm it persists; enable the app lock and confirm a relaunch requires unlocking.

Each flow file SHALL state its precondition, its scripted user path, and assertions on user-visible outcomes only.

#### Scenario: Every catalogued journey has a test

- **WHEN** the flow catalogue is compared against the files in `integration_test/flows/`
- **THEN** every catalogued journey has exactly one corresponding test file, and every test file corresponds to a catalogued journey

#### Scenario: A flow asserts what the user sees

- **WHEN** a flow reaches its final step
- **THEN** it asserts on rendered widgets, route location and displayed state, not on internal objects or database rows

#### Scenario: A broken flow is reported by name

- **WHEN** a flow fails
- **THEN** the failure output names the journey and the step within it that failed

#### Scenario: Direct-view route is verified across entry points

- **WHEN** capture, import, browse, search, organise, or edit opens a document
- **THEN** the corresponding flow observes `viewer_screen` before any `document_detail_screen` and drives Details only through `viewer_document_details_button`

### Requirement: Stable widget keys and semantics for every driven element

Every screen and every control that a Tier‑3 flow interacts with SHALL expose a stable widget key of the form `Key('<feature>_<element>')` and a semantics label. These keys SHALL be catalogued in one registry that both the implementation and the tests reference.

Tier‑3 tests SHALL locate elements by key or by semantics label, and SHALL NOT locate them by user-visible text, widget type alone, or index position.

A change that renames, removes or relocates a keyed element SHALL update the registry and the affected flows in the same change.

#### Scenario: Element is reachable by key

- **WHEN** a flow needs to tap, enter text into, or assert on a control
- **THEN** that control carries a `Key('<feature>_<element>')` listed in the registry, and the flow finds it by that key

#### Scenario: Screen announces itself accessibly

- **WHEN** a screen in a catalogued flow is rendered
- **THEN** its primary controls carry semantics labels sufficient for a screen reader to describe the available actions

#### Scenario: Registry stays truthful

- **WHEN** a screen's keyed element is renamed or removed
- **THEN** the registry entry and every flow referencing it are updated in the same change, and the suite fails if a registered key is absent from the built tree

### Requirement: Deterministic substituted platform edge

Substituted platform services used by Tier‑2 and Tier‑3 tests SHALL be deterministic: given the same call sequence they SHALL return the same results. They SHALL NOT read the wall clock, generate randomness, perform network access, or depend on device state outside the test's own fixtures.

Image, document and recognition fixtures SHALL be checked into the repository and SHALL contain no real personal data.

#### Scenario: Repeated run produces the same result

- **WHEN** the same Tier‑3 flow is run twice on the same device without changing the code
- **THEN** both runs produce the same sequence of screens and the same final assertions

#### Scenario: Fake capture returns a fixture

- **WHEN** a flow triggers camera capture
- **THEN** the substituted capture service returns a checked-in fixture image, and the downstream enhancement and rendering steps operate on that image

#### Scenario: Flows do not depend on each other

- **WHEN** the flow files are executed in any order
- **THEN** each flow seeds and cleans its own state, and every flow passes regardless of which flows ran before it

### Requirement: Single verification gate

The project SHALL provide one command that runs the whole pyramid in order — formatting, static analysis, Tier‑1, Tier‑2, golden tests, then Tier‑3 — and reports a result an agent can act on without reading raw device logs.

The command SHALL exit non-zero when any stage fails, SHALL name the failing stage and, for Tier‑3, the failing flow and step, and SHALL report per-flow timing.

When no device or simulator is available, the command SHALL run every stage it can, and SHALL report Tier‑3 as skipped rather than reporting overall success.

#### Scenario: Agent verifies an implementation

- **WHEN** an agent finishes implementing a change and runs the verification command
- **THEN** it receives a per-stage pass or fail summary that identifies exactly which flow and step broke, if any

#### Scenario: Failure stops the gate

- **WHEN** any stage fails
- **THEN** the command exits non-zero and the summary names that stage

#### Scenario: No device attached

- **WHEN** the command runs with no Android device or iOS simulator available
- **THEN** stages one through five still run, and the summary marks the end-to-end stage as skipped and the overall result as incomplete rather than passed

### Requirement: Verification is required of every future change

The project's change workflow SHALL require, for every change that touches user-visible behaviour: a Tier‑1 task, a Tier‑2 component task, a Tier‑3 flow task covering each affected journey, and a final task that runs the verification gate and reports its outcome before the change is considered done.

Specifications for new user-visible behaviour SHALL name the widget keys and semantics labels the corresponding flow will use.

#### Scenario: Change plan includes all tiers

- **WHEN** a new change's task list is produced
- **THEN** it contains tasks for all three tiers and a final verification-gate task, and a change lacking them is incomplete

#### Scenario: Change is not done until the gate passes

- **WHEN** implementation of a change finishes
- **THEN** the verification gate is run and its result reported, and the change is not marked complete while any stage fails

#### Scenario: New behaviour declares its keys

- **WHEN** a spec introduces a new screen or control that a user interacts with
- **THEN** that spec names the `Key('<feature>_<element>')` and semantics label the flow will use to drive it

### Requirement: Deterministic iCloud platform edge
Tier-1, Tier-2, preview, and Tier-3 coverage SHALL substitute iCloud account, container, identity events, metadata enumeration, download progress, conflicts, and folder selection with scripted deterministic fixtures while retaining production Cubits, use cases, repositories, Isar, and real temporary files at the tier boundaries required by the verification pyramid.

#### Scenario: New-device fixture is repeatable
- **WHEN** the `icloud_library_sync` flow boots with an established marker and remote file fixture twice
- **THEN** both runs select the same authority, emit the same visible synchronization states, and index the same library without wall-clock, random, network, or ambient Apple-account input

#### Scenario: Migration fixture verifies real files
- **WHEN** the flow confirms local-to-iCloud migration
- **THEN** production migration and reconciliation operate on real test files while only the native iCloud edge is substituted

#### Scenario: Failure matrix is deterministic
- **WHEN** tests script signed-out, restricted, unavailable, insufficient-space, interrupted-copy, failed-verification, remote-only, download-failure, identity-change, and conflict responses
- **THEN** each response maps to a stable domain failure and repeatable Cubit/UI state with no hidden global state

#### Scenario: Branding and Apple configuration are checked
- **WHEN** the platform verification stage runs
- **THEN** it asserts the DocScanly display name, Android application ID/namespace and iOS bundle identifier `com.bruxkey.docscanly`, iCloud container `iCloud.com.bruxkey.docscanly`, required iCloud Documents entitlements, absence of CloudKit/Extended Share Access, and Android/iOS-only platform set

### Requirement: iCloud end-to-end journey
The Tier-3 catalogue SHALL include `integration_test/flows/icloud_library_sync_test.dart` and a cloud-storage robot that drive the full application exclusively through registered keys and semantics.

#### Scenario: Flow covers storage lifecycle
- **WHEN** the iCloud journey runs
- **THEN** it covers selection, confirmation, progress, relaunch, new-device discovery, lazy download, refresh, offline/unavailable recovery, and preservation of Trash using `cloud_storage_*`, `library_cloud_refresh`, and `document_cloud_*` elements

#### Scenario: Existing journeys remain valid
- **WHEN** the verification gate runs after implementation
- **THEN** browse/view, import, capture, search, organise/Trash, edit, share, settings/app-lock, Android storage, golden, coverage, layering, and platform stages also pass under DocScanly branding

### Requirement: Retired brand is isolated
Active application code, package imports, generated references, tests, fixtures, and current documentation SHALL use DocScanly/`doc_scanly`; DocForge/`doc_forge` SHALL remain only where required to recognize legacy persisted data and in archived historical OpenSpec changes.

#### Scenario: Brand check passes
- **WHEN** the repository brand check scans active source, platform projects, tests, fixtures, tooling, and current documentation
- **THEN** it finds no `DocForge`, `Doc Forge`, or `doc_forge` occurrence outside the explicit legacy-migration allowlist

#### Scenario: Historical migration remains testable
- **WHEN** legacy migration tests construct a prior DocForge folder, package identifier, or persisted value
- **THEN** the allowlisted old spelling remains available only to prove migration into DocScanly and is not exposed as the active product identity
