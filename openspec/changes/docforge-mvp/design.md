## Context

`doc_forge` is an empty Flutter scaffold. This change builds the entire DocForge V1 product — 14 capabilities specified in `specs/` — and, in doing so, sets every architectural precedent the project will inherit.

Constraints that drive every decision below, taken from the project context:

- **Android and iOS only.** No web or desktop packages, platform folders or CI targets.
- **Offline-first.** No user flow may depend on connectivity. `dio` exists solely so a future sync layer has a home.
- **Feature-first clean architecture** with a strict dependency direction and no feature-to-feature imports.
- **flutter_bloc only.** Cubit preferred; business logic never inside a Cubit.
- **Explicit constructor DI.** No service locators, no singletons, no global mutable state.
- **Freezed + json_serializable** for models; **Equatable** for Cubit states.
- **Isar** primary database, **SharedPreferences** for simple settings, **flutter_secure_storage** for secrets.
- **Mandatory** widget previews, dartdoc, and the full test matrix with ≥80% / ≥90% coverage gates.

The hard technical problems are: keeping 14 features decoupled while they clearly cooperate; running image, OCR and PDF work without blocking the UI or exhausting memory; and choosing a PDF-manipulation library whose licence is acceptable.

## Goals / Non-Goals

**Goals:**

- A composition root that wires every dependency explicitly, so any feature can be constructed in a test or a preview with fakes.
- Feature isolation enforced structurally — cooperation only through `lib/core/contracts/` interfaces.
- All heavy work (enhancement, perspective correction, OCR, PDF composition and editing) in background isolates, cancellable, with progress surfaced as Cubit state.
- Bounded memory: full-resolution images live on disk, not in memory or in Isar.
- A storage model that a future cloud-sync layer can reconcile without touching feature code.
- Every screen and reusable widget previewable from fixtures alone.

**Non-Goals:**

- Cloud sync, backup, AI features, specialised scanners and Office conversion. Only the seams for them are built.
- A custom PDF engine. Existing libraries are used behind `PdfRepository`.
- Offline-capable OCR for every language. The on-device engine's supported set is the supported set.
- Multi-user or multi-device support of any kind in V1.

## Decisions

### 1. Layering and dependency direction

```
presentation (widgets, screens, Cubits)
      ↓  calls use cases, holds no business logic
application (use cases)
      ↓  depends on domain interfaces only
domain (entities, value objects, repository interfaces, failures)   ← depends on nothing
      ↑  implements
infrastructure (Isar/prefs/secure-storage/Dio data sources, DTOs, repository impls)
```

Enforced by convention plus a CI check: `domain/` files may not import `package:flutter`, `application/` may not import `infrastructure/`, and no file under `features/<a>/` may import `features/<b>/`. A small `dart run tool/check_layering.dart` script in CI greps the import graph and fails the build on a violation — cheap, deterministic, and it makes the rule real rather than aspirational.

**Alternative considered:** a melos multi-package workspace with compile-time enforcement. Rejected for V1 — real enforcement, but it multiplies build_runner and CI complexity across 14 features for a single-app repo. The layering check gets ~90% of the benefit at ~5% of the cost, and the folder structure is already package-shaped if we later split.

### 2. Cross-feature cooperation without coupling

Features genuinely need each other: scanning hands pages to PDF generation, the viewer needs a document, search needs OCR text. Each such seam becomes a **domain interface in `lib/core/contracts/`**, implemented by the owning feature's infrastructure and injected by the composition root into the consuming feature's use case:

| Contract | Implemented by | Consumed by |
|---|---|---|
| `DocumentReader` / `DocumentWriter` | `document-library` | viewer, sharing, import, pdf-editing, pdf-generation |
| `PageBundleSink` | `pdf-generation` | scanning, import |
| `OcrTextSource` | `ocr` | search, sharing |
| `FolderReader` | `document-library` | search, home |
| `StorageSummaryReader` | `document-library` | app-shell, settings |
| `AppLockGate` | `app-security` | router |

The value objects crossing these boundaries (`DocumentId`, `PageRef`, `ScannedPageBundle`, `RecognisedText`) live in `lib/core/contracts/models/` as Freezed types, so no feature ever names another feature's type.

**Alternative considered:** an event bus. Rejected — it hides the dependency graph, makes call sites untraceable, and is exactly the "hidden state" the AI implementation guidelines forbid.

### 3. Cubits, States and transitions

Every Cubit owns one immutable Equatable state. States are modelled as a `status` enum plus data fields rather than a sealed class hierarchy, because it keeps `copyWith` cheap and lets a Cubit retain data across a loading transition (e.g. keep the current list visible while refreshing) — a sealed hierarchy would force discarding it or duplicating fields in every variant. Every field appears in `props`.

The canonical shape:

```dart
enum LoadStatus { initial, loading, ready, empty, failure }
```

| Cubit | State | Variants / transitions |
|---|---|---|
| `OnboardingCubit` | `OnboardingState` | `step` (welcome → privacy → permission), `permissionStatus`; `complete()` writes the flag then emits `finished` |
| `HomeCubit` | `HomeState` | initial → loading → ready \| empty \| failure; holds recents, folders, storage summary |
| `ScanCaptureCubit` | `ScanCaptureState` | idle → capturing → processing → captured \| failure; `batchMode`, `pageCount`, `permission` |
| `PageReviewCubit` | `PageReviewState` | ready \| empty (all pages deleted); page list, selected index; rotate/reorder/delete emit new lists |
| `CropCubit` | `CropState` | detecting → adjusting → correcting → done \| failure; holds the quad |
| `EnhancementCubit` | `EnhancementState` | ready → previewing → applying → ready \| failure; filter, brightness, contrast, sharpen, shadowRemoval, `progress` |
| `OcrCubit` | `OcrState` | idle → running(`pagesDone`/`pagesTotal`) → ready \| empty \| failure \| cancelled |
| `PdfGenerationCubit` | `PdfGenerationState` | idle → generating(`progress`) → saved \| failure \| cancelled |
| `PdfEditCubit` | `PdfEditState` | ready → working(`operation`, `progress`) → ready \| failure |
| `DocumentListCubit` | `DocumentListState` | initial → loading → ready \| empty \| failure; `filter` (all/favourites/archive/folder), pagination cursor |
| `DocumentDetailCubit` | `DocumentDetailState` | loading → ready \| failure; document + metadata |
| `FolderCubit` | `FolderState` | loading → ready \| empty \| failure; folders with counts |
| `ViewerCubit` | `ViewerState` | loading → locked (password required) → ready \| failure; `currentPage`, `pageCount`, `zoom` |
| `ShareCubit` | `ShareState` | idle → preparing(`progress`) → ready \| failure |
| `ImportCubit` | `ImportState` | idle → picking → importing(`progress`) → done \| failure \| cancelled; `permission` |
| `SettingsCubit` | `SettingsState` | loading → ready \| failure; one field per setting |
| `AppLockCubit` | `AppLockState` | unknown → locked → authenticating → unlocked \| failure |

**`SearchBloc` is the one full Bloc, and the justification is concrete:** search must update as the user types, which requires debouncing and cancelling superseded queries. A Bloc with `bloc_concurrency`'s `restartable()` transformer plus a debounce on the `SearchQueryChanged` event expresses this declaratively and correctly — a superseded query's use-case call is cancelled rather than racing to emit a stale result. Doing the same in a Cubit means hand-rolling timers and sequence numbers inside the Cubit, which is exactly the imperative logic the state-management rules push out. Every other flow is event-free and uses a Cubit.

**No Cubit contains business logic.** Each Cubit method does exactly three things: emit a loading state, `await` a use case, emit the result state (mapping a `Failure` to a message). Enhancement maths, edge detection, PDF assembly, search ranking, naming patterns and storage accounting all live in use cases and entities. This is verifiable in review: a Cubit method body longer than emit/await/emit is a defect.

### 4. Use cases hold the business logic

One class per business operation, each a callable with a single `call()` returning `Future<Result<T, Failure>>` (a Freezed union — no exceptions across layer boundaries). The full list is in the proposal. Use cases depend only on domain repository interfaces and other use cases, never on Flutter.

Concretely, the rules that would otherwise leak into Cubits and live in the domain/application layers instead: perspective-transform and enhancement maths; the default file-naming pattern expansion; "a document must retain at least one page"; "deleting a folder must not silently lose documents"; "archived documents are excluded from recents, lists and search"; "duplicate folder names are rejected"; storage-summary accounting; and the OCR-optional rule that a PDF is still valid without a text layer.

### 5. Composition root and constructor wiring

`lib/app/composition_root.dart` builds everything once, in dependency order, and holds no mutable state after construction:

```dart
// 1. platform + storage primitives
final isar   = await Isar.open([...schemas], directory: appDir.path);
final prefs  = await SharedPreferences.getInstance();
final secure = const FlutterSecureStorage();

// 2. data sources        (infrastructure)
final documentDataSource = IsarDocumentDataSource(isar);
// 3. repositories        (infrastructure implementing domain interfaces)
final documentRepository = DocumentRepositoryImpl(documentDataSource, fileStore);
// 4. use cases           (application)
final saveDocument = SaveDocument(documentRepository);
// 5. Cubits are created per-route by BlocProvider, with use cases passed in
```

Cubits are **not** created in the composition root; the root exposes a plain `AppDependencies` value object that `BlocProvider` factories read to construct a Cubit per route. This keeps Cubit lifetimes tied to their route (disposed on pop) while dependencies stay singletons-by-construction rather than singletons-by-global.

`AppDependencies` is passed down through an `InheritedWidget` at the root of the tree. This is a deliberate and bounded exception to "no ambient state": it is immutable, constructed once, contains no behaviour of its own, and any widget or test can supply a different instance. Everything else is a constructor parameter.

**Alternatives considered:** `get_it` — forbidden by the project context and it hides the graph. Passing `AppDependencies` explicitly through every widget constructor — pure, but it threads a parameter through dozens of widgets that don't use it, for no testability gain over an overridable `InheritedWidget`.

### 6. Persistence choice per data item

| Data | Store | Rationale |
|---|---|---|
| Document record (id, title, dates, pageCount, size, folderId, isFavourite, isArchived, updatedAt) | **Isar** | Queried, sorted and filtered constantly; needs indexes on `updatedAt`, `folderId`, `isArchived`. |
| Folder record (id, name, createdAt) | **Isar** | Queried and joined for counts. |
| Page record (id, documentId, order, imagePath, rotation, enhancement settings) | **Isar** | Ordered queries per document; small rows. |
| Recognised OCR text | **Isar**, separate `OcrTextEntity` collection with a tokenised word-list index | Large text must not be loaded by document-list queries; a separate collection keeps list queries fast while giving search an index. |
| Page image files and generated PDFs | **Filesystem**, app-private, `<appDocuments>/documents/<documentId>/` | Binary blobs in a database bloat it, slow queries and make backup/migration harder. Isar stores only the path. |
| Theme, OCR language, PDF quality, image quality, file-naming pattern, default save location, onboarding-completed flag | **SharedPreferences**, namespaced `settings.*` / `app.*` | Small, non-sensitive scalars read at startup; no query needs. |
| App-lock enabled flag, PDF passwords | **flutter_secure_storage**, namespaced `secure.*` | Secrets. Keychain on iOS, EncryptedSharedPreferences on Android. Held in memory only for the duration of an operation and never logged. |

Every key is a documented constant in `lib/core/storage/storage_keys.dart` — never an inline string.

**Timestamps are UTC throughout (task 4.6).** Isar returns every `DateTime` in *local* time regardless of what was written, so a UTC value round-trips to an equal instant that is not `==`. Both the entity mappers and `SystemClock` therefore normalise to UTC, and conversion to local time happens only when formatting for display. Beyond fixing equality, this is what lets a future sync layer reconcile records written on devices in different timezones. Caught by the repository round-trip tests.

**Sync-readiness baked in now:** every Isar entity carries a stable UUID `id` (not an auto-increment key) plus `createdAt` and `updatedAt`. This costs nothing today and is the difference between a tractable and an intractable sync migration later.

**Isar package choice — RESOLVED (task 1.1): `isar_community` ^3.3.2.**

Verified empirically against Flutter 3.44.8 / Dart 3.12.2:

- `isar` ^3.1.0+1 resolves *on its own*, but `isar_generator` 3.1.0+1 pins `source_gen ^1.2.2` and `dart_style ^2.2.3`, which is **incompatible with `freezed` ^3.0.0** (needs `source_gen ^2.0.0` / `dart_style ^3.0.0`). Version solving fails outright. Upstream Isar is therefore unusable in this project, not merely stale.
- `isar_community` / `isar_community_flutter_libs` / `isar_community_generator` ^3.3.2 resolve cleanly alongside `freezed` ^3.0.0 and `json_serializable` ^6.8.0 (it pulls `source_gen` 4.2.4), and a combined `build_runner` run generates Isar, Freezed and json_serializable outputs together with no conflict. **Correction (task 4.3):** an earlier note here claimed Isar offers an `IndexType.words` full-text index. It does not — `IndexType` provides only `value`, `hash` and `hashElements`. Word search is instead implemented by tokenising the text into a `List<String>` field and indexing it with `IndexType.value`, which supports `anyStartsWith` prefix queries. `DocumentEntity.titleWords` is derived from the title on every write so the two cannot drift apart, and `OcrTextEntity` will use the same pattern. This changes the mechanism, not the design: search still runs on an index rather than an in-memory scan.

Two consequences to carry forward: `json_annotation` must be constrained `^4.12.0` (json_serializable rejects earlier versions), and the current `build_runner` has **removed** `--delete-conflicting-outputs`, so build scripts and CI must not pass it. Generated Isar code emits `experimental_member_use` warnings for `putByIndex`-family members, so generated files are excluded from analysis in `analysis_options.yaml`.

**Native builds verified (task 1.3).** `flutter build ios --debug --no-codesign` and `flutter build apk --debug` both succeed with the full plugin set, which confirms the `isar_community` native binaries link on both platforms. Three real configuration defects surfaced only at this stage and are fixed:

- **iOS deployment target raised 13.0 → 15.5** (Podfile and `project.pbxproj`), required by `google_mlkit_commons`.
- **All Android plugin subprojects pinned to `compileSdk 36`** in `android/build.gradle.kts`. `receive_sharing_intent` hardcodes `compileSdk 37`, but the SDK now installs that platform as `android-37.0`, so Gradle fails with "Failed to find target with hash string 'android-37'". The override must be registered *before* the existing `subprojects { evaluationDependsOn(":app") }` block — that call forces evaluation, after which Gradle rejects a new `afterEvaluate` with "project is already evaluated".
- **`share_plus` held at ^12.0.2 rather than ^13.** `file_picker` 8–11 requires `win32 ^5.9` while `share_plus` 13 requires `win32 ^6`, so a Windows-only transitive package makes the two mutually exclusive. `file_picker ^10` is the more important of the two for the import capability. Revisit when `file_picker` 12 leaves beta.

Still outstanding: the build warns that `file_picker`, `share_plus` and both `google_mlkit_*` plugins apply the Kotlin Gradle Plugin, which a future Flutter release will reject. Not blocking today, but it is a known upgrade cliff — tracked as a risk rather than an open question because no decision is available until those plugins migrate.

Because all access sits behind `DocumentRepository` / `FolderRepository` / `PageRepository` / `OcrRepository`, replacing the engine with Drift + SQLite FTS5 would touch only `infrastructure/` — and the repository test suite makes that swap verifiable rather than hopeful.

### 7. Heavy work: isolates, cancellation, memory

All image, OCR and PDF work goes through `lib/core/isolates/`, which wraps `Isolate.run` for one-shot jobs and a long-lived worker isolate for progress-reporting batch jobs. The contract:

- The use case owns the isolate call and exposes `Stream<Progress>` plus a `CancellationToken`.
- **Only file paths and small value objects cross the isolate boundary** — never decoded image buffers. Each isolate reads from disk, processes and writes back to disk.
- Cancellation is cooperative: the worker checks the token between pages and exits cleanly, leaving completed pages intact and removing partial output.
- Every page is written to disk immediately after capture; only display-resolution thumbnails are cached in memory (`LruCache`, bounded by count and bytes). This is what makes large batch scans survive on low-end devices, and it is enforced by the `PageRepository` contract rather than by discipline.

Preview rendering uses a downscaled copy so enhancement interaction stays at 60fps while the saved result is computed at full resolution.

### 8. Navigation: GoRouter with typed routes

One route table in `lib/app/router/app_router.dart` using `go_router_builder`'s `TypedGoRoute` annotations, generated by build_runner. No string literals in feature code.

```
/onboarding                    /documents/:id/edit
/unlock                        /folders
/                (home)        /folders/:id
/scan                          /search
/scan/review                   /favourites
/scan/enhance                  /archive
/scan/preview                  /settings
/documents                     /settings/about
/documents/:id                 /settings/privacy
```

Two redirects, both driven by injected gates rather than ambient state:

- `AppLockGate` → redirect to `/unlock` when the lock is enabled and the session is not authenticated, including on resume from background. The gate is checked *before* any route builds, so no document title or thumbnail renders behind the lock screen.
- `OnboardingGate` → redirect to `/onboarding` until the completed flag is set.

Route paths are stable from V1 so future deep links and share-sheet targets remain valid.

### 9. Models: Freezed and json_serializable

- **Domain entities and value objects** — Freezed, no JSON. `Document`, `Folder`, `Page`, `RecognisedText`, `EnhancementSettings`, `ScanSession`, `DocumentId`, `PageRef`, `StorageSummary`.
- **Failures** — a Freezed sealed union per feature, extending a shared `Failure` base in `lib/core/failures/`: `CameraFailure`, `PermissionFailure`, `OcrFailure`, `PdfFailure`, `StorageFullFailure`, `ImportFailure`, `ExportFailure`, `AuthFailure`, `NotFoundFailure`, `CorruptFileFailure`. Every user-visible error message in the specs maps to exactly one variant, and mapping a `Failure` to a message is the presentation layer's only error responsibility.
- **Infrastructure DTOs** — Freezed + json_serializable, with explicit `toDomain()` / `fromDomain()` mappers. Isar collection classes are separate from both (Isar's generator needs mutable annotated classes) and are mapped to domain entities at the repository boundary, so Isar's shape never leaks upward.
- **Cubit states** — Equatable, not Freezed, per the project context.
- No manual JSON parsing anywhere; every DTO has a serialization round-trip test.

**Two codegen decisions forced by task 2.8/2.9, both found by the round-trip tests:**

- **`explicit_to_json: true` in `build.yaml` is mandatory.** json_serializable defaults it to *false*, emitting `instance.field` rather than `instance.field.toJson()` for nested objects. `jsonEncode` papers over this by recursing, but any consumer of the map itself — an in-memory round trip, or writing a value into Isar — receives a model instance where it expects a map and fails with an opaque cast error. Every nested model was affected.
- **Typed ids (`DocumentId`, `FolderId`, `PageId`) are hand-written, not Freezed.** A Freezed wrapper around a single field serialises asymmetrically (`toJson` emits the object, `fromJson` expects a `Map`) and nests every id as `{"value": "..."}`. Hand-written value classes over a shared `EntityId` base serialise as plain strings, which round-trips symmetrically and maps directly onto an Isar indexed `String` column. Equality compares runtime type as well as value, so a `FolderId` and a `DocumentId` holding the same string are never equal.

### 10. Scanning pipeline

`ScannerRepository` abstracts capture entirely, so tests, previews and goldens never touch hardware. Implementation is staged deliberately:

1. **Phase 3a** — own camera UI on `camera`, manual crop always available, "full page" as the default quad. This satisfies every specified requirement, including the "edges not detected" scenario, and gives us our own widget keys, previews and goldens.
2. **Phase 3b** — add automatic edge detection behind an `EdgeDetector` interface. Perspective warp is applied by the same interface.

Deferring auto-detection this way means the scanning capability is shippable before the hardest computer-vision problem is solved, and the fallback path is the specified behaviour rather than a hack. The `EdgeDetector` implementation choice (a native CV binding versus a pure-Dart contour detector in `image`) is left to phase 3b, when it can be measured against real captures — see Open Questions.

The native document-scanner SDKs (ML Kit Document Scanner on Android, VisionKit on iOS) were considered as the primary path. **Rejected:** they present their own full-screen UI, which we cannot key, preview, golden-test or theme — a direct conflict with the mandatory preview and testing requirements, and with Material 3 theming and dark mode.

### 11. OCR

`google_mlkit_text_recognition` runs fully on-device on both platforms. `OcrRepository.recognise(pageImagePath, language)` returns text blocks with bounding boxes; `BuildSearchablePdf` uses those boxes to place an invisible text layer over the page image. OCR results are persisted on first run and never recomputed unless the user explicitly re-runs, which is both a performance and a battery decision. OCR failure never blocks document creation — the PDF is produced without a text layer for the affected page.

### 12. PDF composition, rendering and manipulation

Three distinct concerns, three libraries:

- **Compose** (`pdf` + `printing`) — building a new PDF from page images plus the invisible OCR text layer; `printing` also drives the system print flow.
- **Render** (`pdfrx`) — the viewer, rendering pages on demand.
- **Manipulate** (`pdf_manipulator` ^4.0.0, **MIT**) — merge, split, rotate, delete, extract, duplicate, compress, watermark, encrypt, decrypt and metadata on *existing* PDFs.

**Manipulation library decision — RESOLVED (task 1.2): `pdf_manipulator`, and Syncfusion is rejected.**

No Syncfusion licence is held, and its community licence attaches revenue, headcount and registration conditions — unacceptable for a commercial product. The requirement is a permissive, commercially usable OSS package.

Verified against the shipped package rather than its marketing: every operation the `pdf-editing` spec requires is listed **DONE** in the package's own capability roadmap, not planned — `merge`, `split`, `extractPages`, `selectPages`, `rotatePage`/`rotateAllPages`, `deletePage`/`deletePages`, `compress` (via `optimizeImages` + stream compression), `watermark`/`addWatermark`/`addStamp`, `encrypt`, `decrypt`, and the full metadata get/set surface plus `isEncrypted`, `encryptionAlgorithm` and `permissions`. Licence is MIT (OSI-approved, FSF-libre), Android and iOS both supported, 160/160 pub points. Operations run off the main thread, stream large files through bounded buffers and are cancellable — which happens to match the isolate, memory and cancellation requirements in §7 exactly.

Alternatives considered and rejected:

- **`pdf` (Apache-2.0) alone — the obvious candidate, since it is far more popular.** Rejected because it cannot read a PDF at all. Verified by reading the package source: both of the capabilities needed here are declared as *abstract extension points with no shipped implementation*.
  - `PdfDocumentParserBase` — documented as "Base class for loading an existing PDF document" — is abstract, and nothing in either `pdf` or `printing` extends it.
  - `PdfEncryption` is abstract with a single `encrypt()` method and no concrete security handler.

  Every operation in the `pdf-editing` spec begins by parsing an existing file, so without a parser none of them are possible. Implementing one, plus the standard security handler (`/O` and `/U` derivation, Algorithm 2/2.A key derivation, AES-CBC over every string and stream), is a PDF-library project in its own right — and a subtly wrong crypto implementation is security theatre rather than a bug. Download count measures how many projects *generate* PDFs, which is a different problem. `pdf` is therefore retained for composition, where it is the right tool, and is not asked to edit.
- **Rasterise-and-regenerate.** Because DocForge composes its own PDFs from page images, most edits could be done at the image level and the PDF simply rebuilt. Genuinely viable for scanned documents, and it was the fallback plan — but it destroys the text layer of any *imported* text-based PDF, inflates file size, and still leaves encryption unsolved.
- **`flutter_pdf_toolkit`** (MIT, native): far less mature (0.0.2, 4 likes) with narrower coverage.

`pdf` (Apache-2.0) is retained for **composition** — building the PDF from page images with the invisible OCR text layer, where precise text placement at a given render mode and position matters. `pdfrx` (MIT) is retained for **viewing**, since `pdf_manipulator` is explicitly not a viewer.

Consequences to manage:

- **Two native PDF engines ship** (PDFium under `pdfrx`, the Rust engine here), which costs binary size. The package supports a `keep` pubspec block that trims the engine to only the operations used — configure it before release, and re-measure. If size proves unacceptable, `pdf_manipulator` also exposes `render()`, so `pdfrx` could be dropped in favour of a hand-built viewer surface — more work, and only worth it if the numbers demand it.
- **The build hook downloads a prebuilt binary on first build**, so builds need network access and the artefact is a supply-chain input. The package vendors its Rust source, so an air-gapped or fully-reproducible build can compile from source if that ever becomes a requirement.
- **Unsigned iOS builds are no longer possible.** The native-asset engine must be code-signed into the app bundle, so `flutter build ios --no-codesign` fails with "requires a selected Development Team". Confirmed by A/B test: removing the package restores the unsigned build, and Android is unaffected. Practical impact is limited — device and store builds are signed regardless — but CI cannot use an unsigned iOS build as a smoke test. The iOS CI job therefore runs `flutter build ios --config-only` plus `pod install`, with the full signed build gated on signing secrets.
- **Single-maintainer package, recently rewritten** (the 4.x line replaced an Android-only predecessor). Bus-factor risk, mitigated by MIT licensing plus vendored source — a fork is possible — and by `PdfRepository` isolating every call site.

All three sit behind `PdfRepository`, so the manipulation library can be swapped without touching a single feature.

**Every manipulation is atomic:** write to a temporary file, verify it opens and has the expected page count, then atomically replace the original and update the record. On any failure the temporary file is deleted and the source is untouched — this is what makes the "operation failure leaves the document intact" scenarios true rather than aspirational.

### 13. Search

`SearchDocuments` queries the tokenised word-list indexes on `OcrTextEntity` and `DocumentEntity.titleWords`, merges by document id, and returns results with a match snippet and its source (title or text). Archived documents are excluded unless explicitly requested. Filters (folder, creation-date range, modified-date range) are applied as indexed query clauses, not as in-memory post-filtering, so performance holds at several thousand documents.

If the Isar decision reverses (see Open Questions), SQLite FTS5 is the replacement and `SearchDocuments` is the only use case that changes shape.

### 14. Widget keys and semantics labels

Convention: `Key('<feature>_<element>')`, declared as `const` in a per-feature `keys.dart` so tests and implementation share one source of truth and a rename is a compile error rather than a silently failing test.

The complete key set is specified in the scenarios of `specs/*/spec.md` — those are the keys automated UI tests rely on, and they are normative. Every screen root carries `<feature>_screen`; every list carries `<feature>_list`; every loading, empty and error state carries `<feature>_loading` / `_empty_state` / `_error_view` with a retry control at `_error_retry_button`.

Semantics rules applied uniformly: every interactive control has a label naming its action; icon-only buttons always have one; list rows announce their meaningful content (a document row announces title, page count, modified date and favourite state); progress indicators announce their value; and result counts are announced on change. Minimum touch target 48dp everywhere. Decorative images are explicitly excluded from the semantics tree so screen-reader users are not read noise.

### 15. Widget previews

`@Preview()` from `package:flutter/widget_previews.dart`, run with `flutter widget-preview start`.

Fixtures live in `lib/core/previews/fixtures/` — `sampleDocument`, `sampleDocuments(n)`, `sampleFolder`, `samplePage`, `sampleRecognisedText`, `longTitleDocument`, `sampleStorageSummary` — all `const` or built from constants, with **fixed timestamps and no randomness**, so previews and goldens are byte-stable.

Two feeding mechanisms, matching the project context:

1. Construct the widget directly with fixture data (preferred for leaf widgets).
2. Wrap in `BlocProvider.value` with a `FakeXCubit` seeded to the target state (for widgets bound to a Cubit). Fakes live in `lib/core/previews/fakes/` and emit fixed states — they never touch a repository, camera, OCR engine, network or Isar.

Coverage, per the project context and enumerated in the proposal: every reusable widget gets default / loading / empty / error / long-content previews; every screen gets those five **plus** phone, tablet, light and dark. Preview names follow `'<Widget> — <state>'`. A widget that cannot be previewed from fixtures alone is a design defect and must be refactored to take its data by construction.

### 16. Determinism and forbidden state

The AI implementation guidelines are enforced concretely:

- **No hidden state** — every Cubit's behaviour is a pure function of its constructor dependencies and its method arguments.
- **No static mutable state, no global mutable variables.** The `AppDependencies` `InheritedWidget` (§5) is the single ambient value, and it is immutable and overridable.
- **No wall-clock or randomness in business logic.** `Clock` and `IdGenerator` are injected interfaces; production uses `DateTime.now()` and UUID v4, tests and previews use fixed implementations. This is what makes golden tests and `bloc_test` sequences reproducible.
- **No `BuildContext` in Cubits, no Flutter imports in `domain/` or `application/`.**
- The layering check from §1 fails CI on violations of the import rules; the rest are review items with specific, checkable phrasing.

### 17. Documentation

Per the project context: dartdoc on every public class, function, method, constructor and top-level constant — third-person summary sentence, blank `///` line, then parameters, return value and possible failures, with `[Symbol]` references. Specifically: every Cubit documents the UI state it owns; every state variant documents what it means; every use case documents the business rule it enforces; every repository interface documents its contract including offline behaviour; every widget documents its purpose, required inputs, keys and semantics labels.

Inline `//` comments are required — explaining **why**, not what — at these specific places, which are where a future reader will otherwise be lost: the perspective-transform and enhancement maths; the invisible-OCR-text-layer positioning; isolate boundaries and what may cross them; the Isar schema and index choices and their migration implications; the atomic write-verify-replace sequence in `PdfRepository`; the router redirect ordering (lock gate before onboarding gate); the thumbnail cache bounds; and every deliberate trade-off recorded in this document. Docs are updated in the same change as the behaviour; stale docs are defects.

### 18. Corrections recorded during group 4

**`Failure.validation` was added to the sealed union.** The specs require a
*validation message* when a name is empty or a folder name is duplicated. Those
paths originally returned `Failure.unexpected`, which maps to "Something went
wrong. Please try again." — telling the user a correctable typing mistake was
an internal error. `Failure.validation(issue:)` carries a `ValidationIssue`, and
`FolderCubit` routes it to the text field while every other failure goes to the
screen-level error surface. The exhaustiveness test was amended: validation and
cancellation are the only two variants with no recovery action, for opposite
reasons — cancellation is what the user just chose, and a rejected name is fixed
in the field it was typed into.

**Cubit states carry a `Failure`, not a rendered message string.** The states
first held `String? message`. That made `AppErrorView` — which builds its
recovery control from the failure — unable to offer anything but a generic
retry, so a permission failure would not have offered "Open settings". The
states now hold `Failure? failure` and expose `message` as a derived getter.

**`DocumentFileStore`'s interface moved to `domain/repositories/`.** It was
declared alongside its filesystem implementation in `infrastructure/`, so
`PurgeDocument` and `DuplicateDocument` — which delete and copy a document's
files — imported infrastructure from the application layer. `check_layering.dart`
caught it. The interface is a domain contract; only `LocalDocumentFileStore`,
which knows the directory layout, is infrastructure.

**Screens load in `initState`, not in a Cubit constructor.** A Cubit that starts
work on construction cannot be built in a test or a preview without also running
it, which is what forces a preview to reach a real repository. The preview
Cubits override `load()` to do nothing for the same reason.

**Pagination asks for one row more than it needs.** `LoadDocuments` requests
`limit + 1` and discards the extra, which answers "is there more?" without a
count query over the whole library on every page.

### 19. Corrections recorded during group 5

**Metadata formatting moved to `core/formatting/`.** Home shows the same file
sizes, dates and page counts the library does, and features may not import each
other, so `LibraryFormatting` became `DisplayFormatting` in `core`. Leaving it
in the library feature would have meant Home reimplementing it and the two
disagreeing about the same 482 KB.

**Theme mode is a `ThemeModeController`, not a field.** The spec requires an
explicit theme selection in settings to apply without a restart. Settings is
several routes below the root, and a leaf screen cannot rebuild the root through
the router — so the mode is a `ValueNotifier` created in the composition root,
listened to at the root, and injected downwards. It is the one mutable object
above the router, and it is still injected rather than global.

**`LoadHomeData` fails only on the recents query.** A folder or storage read
that fails degrades to an empty folder list or a zero summary rather than
failing the whole screen: losing Home entirely over a storage figure is a worse
outcome than showing Home without one. Recents are the one section the screen
cannot be assembled without.

**The Home empty state is driven by the storage document count, not by recents.**
A library consisting entirely of archived documents has no recents but is not
empty, and telling that user to scan their first document would be wrong.

**`LibraryModule` was introduced.** `main.dart` was becoming a wiring diagram.
The module opens Isar once, builds the repositories and use cases, and exposes
use cases only — a screen that could reach a repository directly could bypass
the rules the use cases enforce. `buildLibraryModuleOver` takes an already-open
database so an integration test can supply a temporary one.

### 20. Corrections recorded during group 6

**The resampler mutated its own source image.** Bilinear sampling read four
pixels from the capture and wrote the blended result back through one of them.
`img.getPixel` returns a live view into the image's buffer, so every write
corrupted the neighbours the next samples read — damage that compounds across
the image rather than being visibly wrong at one spot. It now reads channel
values out as plain numbers and writes only to the output, with a test that
compares the source bytes before and after.

**The correction job is injected into the use case.** The pixel work is
infrastructure and the application layer may not import it, but an isolate job
must be a top-level function. `ApplyPerspectiveCorrection` therefore takes an
`IsolateJob` as a constructor argument and the composition root supplies
`correctPageJob`. This is also what lets a test substitute a failing job.

**`ScanStagingArea` was declared in domain, not infrastructure.** Captures are
written before the document exists, so they need somewhere to live; the use
cases depend on that somewhere (discarding a session clears it), which makes it
a domain contract with a filesystem implementation.

**Widget tests use the non-writing fake scanner.** `testWidgets` runs in a
fake-async zone where real file I/O never completes, so a fake that writes would
hang every `pumpAndSettle` rather than fail it. The disk-first rule is exercised
against the writing fake in `scanning_usecases_test.dart`, which runs outside
that zone. The same applies to the staging area, which the screen tests replace
with a recording stand-in.

**Releasing the camera leaves an indefinite spinner, so those tests use bounded
pumps.** `pumpAndSettle` waits for animations to finish and that one never does.

**The camera preview builder is supplied by the composition root.** A preview is
a Flutter widget tied to the plugin's controller, so it cannot sit on
`ScannerRepository` — the application layer depends on that contract and may not
import Flutter. `CameraScannerRepository` exposes `buildPreview`, the module
passes it down, and the screen takes it as a parameter, which is also what makes
the screen testable and previewable without a camera.

**The scanning flow is one route, not three.** Capture, review and crop share a
session. Three sibling routes would mean lifting that session above the router
into ambient state, and would let a deep link drop a user into a review screen
for a session that does not exist.

## Risks / Trade-offs

- **Isar's maintenance status** → Resolved to the community fork (§6); upstream is incompatible with Freezed, so this was a real blocker rather than a theoretical one. The fork is itself community-maintained, so the residual risk stands: access is entirely behind repository interfaces and covered by a repository test suite, so a swap to Drift + SQLite FTS5 touches only `infrastructure/`.
- **PDF-manipulation licensing** → Treated as a blocking open question below rather than a silent assumption; `PdfRepository` isolates the choice.
- **Automatic edge detection is hard** → Staged (§10). Manual adjustment is a first-class specified requirement, not a fallback, so the capability ships correct even if auto-detection lands late or performs modestly. A native CV binding, if chosen, adds meaningfully to app size — measured before adoption.
- **Scope: 14 capabilities in one change** → Phased tasks, each phase independently complete and mergeable; phases 0–4 form a shippable vertical slice.
- **Enum-status states can drift into illegal combinations** (`status: empty` with a non-empty list) → Each state exposes named factory constructors (`.loading()`, `.ready(items)`, `.failure(message)`) as the only construction path, and `bloc_test` asserts full sequences.
- **Memory on large batch scans** → Disk-first pages, bounded thumbnail cache, nothing but paths across isolate boundaries; enforced by the `PageRepository` contract and covered by tests.
- **ML Kit has no arm64 iOS simulator support** → `GoogleMLKit`, `MLImage`, `MLKitCommon` and `MLKitVision` ship no arm64 simulator slices, so the app cannot run on an iOS simulator on an Apple Silicon Mac — which is every current Mac, and every GitHub macOS runner. Consequences: iOS development and manual testing require a physical device, and the CI integration-test job runs on an Android emulator rather than an iOS simulator. Widget, golden and unit tests are unaffected (they run on the Dart VM). If iOS simulator support becomes essential, the fallback is to put OCR behind `OcrRepository` — which it already is — and supply a stub implementation for simulator builds.
- **Kotlin Gradle Plugin deprecation** → `file_picker`, `share_plus`, `google_mlkit_commons` and `google_mlkit_text_recognition` all apply KGP, which a future Flutter release will refuse to build. Nothing to decide until upstream migrates to Built-in Kotlin; the mitigation is that each sits behind a repository interface, so a replacement is an `infrastructure/` change. Re-check at each Flutter upgrade.
- **Golden-test flakiness across platforms and font versions** → Fixed test fonts, fixed device surfaces, fixed fixture timestamps, injected `Clock`; goldens generated on one canonical CI configuration only.
- **On-device OCR is weaker than cloud OCR, especially for non-Latin scripts** → Language is configurable, OCR is re-runnable, and no flow blocks on recognition success. Expectations are set in the UI rather than in a changelog.
- **The `AppDependencies` `InheritedWidget` is a deliberate exception to "no ambient state"** → Bounded: immutable, behaviour-free, constructed once, overridable in any test or preview. The alternative threads an unused parameter through dozens of widgets for no testability gain.
- **`bloc_concurrency` for `SearchBloc` adds a dependency for one feature** → Accepted; hand-rolled debounce and sequence-number logic inside a Cubit would be more code, less correct, and would put control flow exactly where the state-management rules forbid it.

## Migration Plan

There is no prior release, so this is a build-out rather than a migration.

- **Isar** — creates the initial schema; nothing to migrate from. Every collection carries an explicit `schemaVersion` and stable UUID ids from day one so V2 migrations are mechanical.
- **On-disk layout** — `<appDocuments>/documents/<documentId>/` is versioned by a marker file, so a future relocation can be detected and performed without losing references.
- **Preference and secure-storage keys** — namespaced and declared as constants in one file; renaming one later requires a read-old/write-new step, which the constants file makes greppable.
- **Removed in phase 0** — the default counter app in `lib/main.dart` and `test/widget_test.dart`.
- **Rollback** — each phase is an independently revertable merge. Reverting a feature phase removes its routes and Cubits but leaves the Isar schema intact; an unused collection is inert and costs nothing.
- **Deployment** — Android and iOS only. Camera, photo-library and file-access usage descriptions are added to the iOS `Info.plist` and the Android manifest in the phase that first needs each, with the just-in-time rationale required by the specs.

## Open Questions

1. ~~**PDF manipulation library.**~~ **RESOLVED (task 1.2)** — `pdf_manipulator` ^4.0.0, MIT licensed. Syncfusion is rejected outright: no licence is held and its community terms carry revenue, headcount and registration conditions. Full reasoning in §12.
2. ~~**Isar package and version.**~~ **RESOLVED (task 1.1)** — `isar_community` ^3.3.2. Upstream `isar_generator` is incompatible with `freezed` ^3.0.0; the community fork resolves and generates cleanly. Full reasoning and consequences in §6.
3. ~~**Edge-detection implementation.**~~ **RESOLVED (task 6.20)** — OpenCV via `dartcv4` ^1.1.8 (Apache-2.0). Chosen over a from-scratch pure-Dart contour detector on the grounds that the CV primitives are battle-tested upstream and writing them fresh is a large body of unproven code. Full reasoning and the testing consequence in §22.
4. ~~**OCR language set.**~~ **RESOLVED (group 8)** — Latin script ships bundled and works entirely offline; other scripts are modelled as installable language packs behind a repository, so the offline claim is unqualified for what actually ships. See §23.
5. ~~**Delete semantics.**~~ **RESOLVED** — the archive *is* the recovery state. Delete moves a document to the archive; "permanently remove" from the archive is the only irreversible action. This is what `document-library` already implements, and it satisfies "recoverable until permanently removed" without a third state.
6. ~~**Tablet layout ambition.**~~ **RESOLVED** — responsive single-pane with wider grids and larger content, driven by the existing `ResponsiveLayout`. The specs require only that the width be used well, and a true two-pane master/detail is materially more work and roughly double the goldens for no requirement.

### 21. Corrections recorded during group 7

**Shadow removal normalises against the page, not against white.** The first
implementation divided each channel by the local illumination and scaled the
result to full white. On a grey document that is correct; on anything saturated
it is not. A red logo has a low luminance background through no fault of the
lighting, so normalising it to white pushed it straight to white. Shadow
removal now divides by the local illumination *relative to a high percentile of
the whole page's illumination*, which makes the gain exactly one on an evenly
lit capture — enabling the control on a good photograph is now a no-op rather
than a brightening — and caps the gain at three stops so the deepest shadow,
which carries the least signal, is not amplified into noise.

**Sharpening adds one luminance-derived offset to all three channels.** The
first implementation ran the unsharp mask per channel against a shared
luminance blur, which treats a saturated region's colour as if it were detail:
a red pixel's distance from the page's luminance is not an edge, and amplifying
it three times pushed the colour to the extremes. The maths now returns the
offset rather than the sharpened value, and the caller adds it to each channel
equally. Structure is sharpened; hue is left exactly where it was.

**The blur is separable and shared.** Shadow removal, adaptive thresholding and
the unsharp mask all need the same blurred luminance map, and at the radius
illumination separation requires — a twentieth of the page — a naive
two-dimensional box blur is `radius²` reads per pixel, which makes a
full-resolution page take minutes. It is computed once per enhancement as two
one-dimensional passes over a running sum.

**A page that needs no work is copied, not re-encoded.** Running the pipeline
for identity settings would cost the capture a generation of JPEG loss for no
visible change, so `enhancePageJob` copies the source file when the settings
clamp to the defaults and no downscale is needed.

**The enhancement Cubit counts preview generations.** Dragging a slider starts
a render per frame and they do not finish in the order they began, so a slow
render could land after a newer one and leave the screen showing settings the
user had already passed through. Each request carries a generation number and a
superseded result is dropped rather than emitted.

**Keys belong to one widget only.** `AdjustmentSlider` initially carried its key
on both itself and its inner `Slider`, which put two widgets under one key and
made every finder for it ambiguous. The key stays on the widget the spec names.

**The filter row is a lazy horizontal list.** Five filter names do not fit on a
phone, so the row scrolls and the later chips are genuinely absent from the tree
until scrolled to. Tests scroll to a chip and call `ensureVisible` before
tapping — `scrollUntilVisible` stops as soon as the widget is in the tree, and a
lazy list builds a little beyond the viewport, so a tap at that point can land
on nothing.

### 22. Automatic edge detection

`dartcv4` ^1.1.8 (Apache-2.0, the maintained successor to the discontinued
`opencv_dart`/`opencv_core`) supplies greyscale, Gaussian blur, Canny,
`findContours` and `approxPolyDP`. Chosen over a from-scratch pure-Dart contour
detector: the primitives are battle-tested upstream, and writing them fresh
would be a large body of unproven code sitting directly on scan quality.

**Version is pinned to the 1.x line by `pdf_manipulator`.** `dartcv4` 2.x
depends on `hooks` ^1.0.0 while `pdf_manipulator` ^4.0.0 requires ^2.0.2, so
version solving fails. 1.1.8 is what resolves alongside the PDF stack.

**The native library does not load in the host test VM,** only on Android and
iOS. That is the fact that shapes the design rather than an inconvenience to
work around: if the whole detector lived in `infrastructure/`, "automatic edge
detection" would be a large block of logic no test could reach.

So the split is:

- `infrastructure/opencv_edge_detector.dart` holds *only* calls whose behaviour
  is guaranteed upstream — blur, Canny, dilate, find contours, approximate to a
  polygon. Nothing here decides anything.
- `domain/page_edge_geometry.dart` holds every *decision*, as pure functions:
  corner ordering, area and angle measurement, convexity, the plausibility
  rules, and which candidate wins. This is where a detector actually gets a
  document wrong, and it is tested exhaustively without a camera.

Three plausibility rules, each earning its place:

- **Area between 15% and 99.5% of the frame.** Below that it is a business card
  or a logo, and cropping to it silently removes most of a document the user
  believes they scanned. Above it, the contour is the frame border, which Canny
  finds reliably and which is never the document.
- **Opposite edges within 3× of each other.** This is the real test of "a
  rectangle seen at an angle". A corner-angle check alone does *not* reject a
  wedge tapering from 800px to 60px — a trapezium's interior angles stay
  moderate however extreme its taper — which the first implementation got wrong
  and a test caught.
- **Convex.** A quadrilateral that doubles back on itself is not paper from any
  angle, and is exactly what corner ordering produces from a contour that was
  never a page.

Corners are ordered by coordinate sums and differences rather than by angle
around the centroid: the two agree on a page seen at an angle and disagree on a
nearly-square one, where only the sum-and-difference rule stays correct.

Detection runs on a copy downscaled to 1024px on its longest edge, inside an
isolate. A page outline is a feature hundreds of pixels across, so the full
capture finds no more edges and takes many times longer — and the result is
normalised, so a crop found on the downscale applies unchanged to the original.

The whole thing is best-effort by contract. `EdgeDetector.detect` never fails:
an undetected or unreadable capture returns `PageQuad.full`, which is the
specified behaviour — the capture is kept, the whole frame becomes the default
crop, and the user adjusts the corners by hand. `FullPageEdgeDetector` remains,
both as that fallback and as the substitute tests and previews inject.

### 23. OCR: language packs, granularity and persistence

**Scripts, not languages.** ML Kit groups recognisers by script — one reads
every Latin-script language, another every Chinese one. `OcrScript` follows that
grouping because it is what the engine actually offers; modelling individual
languages would promise a distinction the recogniser cannot make.

**Only Latin ships, and the honest reason is that the choice is made at build
time.** ML Kit's non-Latin recognisers are separate build dependencies, not
runtime downloads, so a "first-use download" flow cannot be built over them
without also shipping and hosting the models ourselves. Rather than offer a
script and fail at the point of use, availability is a question behind
`OcrLanguagePacks`: `BundledOcrLanguagePacks` reports Latin as available and
everything else as not, and settings renders that. Adding a script later is a
build-configuration change plus one line. The consequence to be clear about: the
"works entirely offline" claim is unqualified for what ships, because what ships
is bundled.

**Text is taken at line granularity, not at ML Kit's block granularity.** A
"block" is a paragraph, and its bounding box spans several lines of differing
length. Placing invisible PDF text across that box makes selection in a reader
grab the wrong words. A line's box is a tight fit around the text it contains,
which is what the searchable-PDF requirement needs.

**Bounding boxes are normalised against the image's own dimensions, read from
the file.** ML Kit returns pixels; a caller describing the image wrongly would
put the text layer in the wrong place, and that is invisible until someone
selects text in a reader.

**Recognition is per page, persisted immediately, and never recomputed.** Each
result is stored before its event is emitted, so a page is either recognised and
durable or never started — which is what makes "cancelling keeps already
recognised pages" true, and what stops a reported-but-unstored result from being
recomputed on the next open. An empty result is stored too: a page with nothing
legible is a real answer, and retrying it every open would recognise a blank page
forever.

**A failed page does not stop the run**, unlike an enhancement batch. There, a
failure means the later pages' inputs are suspect; here one unreadable page says
nothing about the next, and the spec requires the document to stay usable
without recognised text.

**A store that cannot be read is treated as empty rather than fatal.** Worst
case every page is recognised again — slow but correct — where failing outright
would leave a usable document with no text at all.

**The row records its document.** Permanent removal has to delete a document's
recognised text after its pages are gone, so the link cannot be derived from the
page at that point and is recorded at write time.

**Correction found during this group: a tooltip is not a label.** The copy and
export controls are icon-only and carried only `tooltip:`, which Flutter turns
into a semantics *tooltip* rather than a label — so a screen reader announced
nothing actionable, in direct violation of the spec. The label now lives on the
icon's `semanticLabel`. Worth remembering for every icon-only button in the
codebase.

### 24. PDF generation

**Composition owns its own isolate.** `pw.Document.save` is asynchronous, and
`BackgroundWorker`'s job contract is synchronous by design — a synchronous job
cannot accidentally hold a stream open across the boundary. `IsolatePdfComposer`
therefore calls `Isolate.run` directly rather than going through the worker.
`InlinePdfComposer` is its test and integration counterpart.

**Written to a temporary file and renamed into place.** A rename within a
directory is atomic on both platforms, so a failure part-way leaves the
temporary file — which is deleted — rather than a truncated PDF where a real one
is expected. The spec requires no partial artefact, and this is the mechanism.

**Rotation is baked into the image, not set as page metadata.** A PDF page
rotation is metadata a reader may or may not honour, and the text layer's
coordinates would then have to be rotated to match it — two chances to disagree
where there can be one.

**The page is the image's aspect ratio at a fixed scale.** The image fills the
page edge to edge with no letterboxing, which means the normalised text boxes
map onto the page by multiplication alone. Any other page geometry would need a
letterbox offset in the text-layer maths, which is one more thing to get wrong
invisibly.

**The text layer uses `PdfTextRenderingMode.invisible`.** White text is visible
against a dark scan, and text at zero opacity still prints. Invisible rendering
is the mechanism PDF defines for exactly this.

**`SaveDocument` composes first and writes the record second.** A record written
first would leave a document the user can see but cannot open if composition
then failed. If the record write fails after the file exists, the file is
deleted: an orphan in app-private storage is invisible to the user and never
reclaimed, which is worse than none. Cancellation between the two does the same.

**Naming is a pure function of its inputs.** `DocumentNaming.expand` takes the
instant rather than reading a clock, which is what makes it testable and every
golden stable. The date is formatted by hand rather than through `intl` because
the result is a *file name*: a locale-dependent one would sort differently on
different devices and could contain a slash. Note that names use **local** time
while stored timestamps are **UTC** — a user naming a scan at half past nine
expects "09.30", and a document must not appear to move when the device travels.

**A blank name field means the default, not a nameless document.** An untitled
document is unfindable and the library forbids an empty title, so the entered
value and the generated one are kept separately and resolved at save time.

**Correction found during this group: a Cubit delivers state on a microtask.**
A widget test that emits and then pumps once sees the *previous* state — the
frame is built before the stream delivers. Two bounded pumps are needed, and
`pumpAndSettle` cannot be used where the state shows an indefinite progress bar.
The same trap applies anywhere a test seeds a Cubit directly.

### 25. Document viewer

**`PdfRenderer` reports what a file *is*, and nothing more** — page count and
whether it needed a password. Drawing pages is the viewer *widget*'s job,
because on-demand rendering with bounded memory is a property of the rendering
surface rather than of a repository call. Pulling every page through the
interface would mean holding rendered bitmaps somewhere, which is exactly what
the memory requirement forbids.

**The rendering surface is injected from the composition root**, the same
decision and the same reason as the camera preview: it is a plugin-backed widget
that cannot exist in a test or a preview, and a screen that built its own could
be neither.

**A protected document is `locked`, not `failed`.** The prompt is the normal
path for one; an error view would suggest something had gone wrong. A wrong
password is likewise not an error state — the prompt stays up and says so, which
is why `passwordRejected` is separate from `failure`.

**Nothing of a locked document is rendered** — no page, no title, no page count,
no recognised text, no share control. The state simply has no document in it
until the file opens, so there is nothing for the screen to leak.

**Passwords go to secure storage and only after they have worked.** A stored
password is tried first so a document the user protected on this device opens
without asking again; a typed one takes precedence over it, because a user
retyping a password is correcting something. A secure store that cannot be read
degrades to prompting rather than failing: being asked for a password is
recoverable, being unable to open your own document is not.

**The page count comes from the file, not from the record.** The two can
disagree after an edit, and the file is the truth about what will be rendered.

**Jumping to a page clamps rather than rejects.** A number past the end takes
the user to the last page, which is what they were reaching for. A *non-numeric*
entry does nothing at all, because silently jumping somewhere arbitrary is worse
than no visible response.

**Recognised text loads after the document is on screen.** Text is a secondary
panel, and making the first page wait for it would break the "opens promptly"
requirement for no benefit. A text lookup that fails degrades to empty: the
viewer's job is to show the document.

**Tablet width goes to a text panel, not to a bigger page.** A page scaled past
its own resolution shows no more detail, while the recognised text is genuinely
useful and has nowhere to live on a phone.

### 26. Search

**A Bloc, and the only one in the application.** Search is the single feature
whose *event stream* needs transforming: keystrokes must be debounced so a
five-letter word runs one query rather than five, and each new query must cancel
the one before it so a slow result cannot land after a newer one. `restartable()`
over a debounced stream expresses both. A Cubit has no event stream to transform
and would need that logic hand-rolled with timers and generation counters —
which is precisely the shape §3 says to prefer a Bloc for.

Filters are *not* debounced. A filter change is one deliberate action, not a
stream of them, and waiting a quarter of a second after a tap reads as lag.

**A layering violation was found and fixed here.** The first implementation read
the document collection and the OCR collection directly from one Isar instance —
`document_search` importing `document_library` and `ocr`, which the layering
check rejects. That check was right: two features' storage schemas are exactly
the coupling `core/contracts/` exists to prevent.

The fix is two contracts, each implemented by the feature that owns its
collection: `DocumentTitleIndex` (document-library) and `OcrSearchIndex` (ocr).
`IndexedSearchRepository` depends on both plus `DocumentReader`, and knows about
no database at all.

**A text match needs a document lookup.** A document whose *pages* mention a term
very often has a title that does not — "Scan 2026-03-14" whose text says Acme —
which is the entire point of searching recognised text. The first version only
kept text hits whose documents the title index had already returned, silently
dropping exactly that case. A test caught it. Documents already loaded by the
title query are reused; only the rest are fetched.

**Archived documents are excluded on both paths.** The title index filters them
in its query; the OCR index has no archive flag to filter on, so the rule is
applied where the document is known. Missing the second path would have made the
archive leak back through text search.

**Snippets are built from the original text, not the index copy.** The OCR
collection stores a lower-cased column for matching. Quoting that back to the
user renders their document in lower case and makes it look like something else,
so the hit carries the text as it was read.

**A document matching both ways is attributed to its title.** The title is what
the row shows; claiming the match came from the recognised text would send the
user looking for something already in front of them.

**A failing text index degrades to title-only results.** Finding fewer documents
is recoverable; finding none is not.

## 27. Sharing, printing and export (group 12)

**The file of record is never handed out or moved.** A PDF share attaches the
stored file itself; an image share renders *copies* into a staging directory;
an export writes a *copy* to the chosen destination. No sharing path mutates a
document.

**A protected document keeps its protection by omission, not by effort.** The
password lives in the PDF's bytes, so sharing the file shares the protection.
No sharing use case reads secure storage at all — the guarantee is achieved by
not going near the secret rather than by remembering to strip it somewhere.

**Three seams, not one.** `ShareRepository`, `PrintRepository` and
`ExportDestinationPicker` are separate interfaces because they fail differently
and are substituted independently. Two of them treat *user cancellation as a
successful result* rather than a failure: `printFile` returns `false` for a
dismissed dialogue and `chooseDestination` returns `null` for a cancelled
picker. The spec requires the app to return to the previous screen with no
change and no message, and a failure result would produce a message.

**Staging goes in the cache, not in documents storage.** A staged page image is
a copy the receiving application may still hold a handle on after we are done,
and the operating system is free to reclaim it later. Nothing staged is a
document of record.

**Page order is enforced by the feature, not trusted from the caller.** A
selection arrives in tap order; `ShareRules.inPageOrder` sorts it. Image file
names are zero-padded (`Scan_002.jpg`) because several mail clients order
attachments alphabetically, and without padding page 10 arrives before page 2.

**Enhancement is not re-run when rendering a share image.** The stored page
image is already the enhanced one, so the render job bakes in rotation and
re-encodes at 2400px — nothing more. Re-running enhancement would also mean
importing another feature, which the layering check forbids.

**The render job is injected, not imported.** `SharePageImages` takes an
`IsolateJob<SharePageRequest, String>` in its constructor because the renderer
lives in infrastructure and the application layer may not depend on it (§2).

**A partial set is never handed over and never left behind.** When a page fails
to render, or the batch is cancelled, every image already written is deleted
before the failure is emitted. Half a document handed to a share sheet looks
like the document lost pages.

**"No recognised text" is answered as both a disabled control and a message.**
The spec allows either; a disabled control with no explanation leaves the user
guessing, so the tile is disabled *and* a notice beneath it offers to run
recognition.

**Every recovery handler is supplied to the error view.** Not only `onRetry`:
a full device's recovery action is "manage storage", and supplying only the
retry handler would leave that failure with a message and no way forward — the
exact situation the "clear message and working recovery action" requirement
exists to prevent. Found by a widget test, not by reading the code.

**Offline is proved two ways.** A runtime check installs an `HttpOverrides` that
fails the test the moment anything opens an `HttpClient`, and a source check
scans the feature for `package:dio`, `HttpClient` and `package:http/`. Either
alone is defeatable: the runtime check misses a path the suite does not walk,
and the source check misses a request made through a transitive dependency.
