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
| Recognised OCR text | **Isar**, separate `OcrTextEntity` collection with a word index | Large text must not be loaded by document-list queries; a separate collection keeps list queries fast while giving search an index. |
| Page image files and generated PDFs | **Filesystem**, app-private, `<appDocuments>/documents/<documentId>/` | Binary blobs in a database bloat it, slow queries and make backup/migration harder. Isar stores only the path. |
| Theme, OCR language, PDF quality, image quality, file-naming pattern, default save location, onboarding-completed flag | **SharedPreferences**, namespaced `settings.*` / `app.*` | Small, non-sensitive scalars read at startup; no query needs. |
| App-lock enabled flag, PDF passwords | **flutter_secure_storage**, namespaced `secure.*` | Secrets. Keychain on iOS, EncryptedSharedPreferences on Android. Held in memory only for the duration of an operation and never logged. |

Every key is a documented constant in `lib/core/storage/storage_keys.dart` — never an inline string.

**Sync-readiness baked in now:** every Isar entity carries a stable UUID `id` (not an auto-increment key) plus `createdAt` and `updatedAt`. This costs nothing today and is the difference between a tractable and an intractable sync migration later.

**Isar package choice — RESOLVED (task 1.1): `isar_community` ^3.3.2.**

Verified empirically against Flutter 3.44.8 / Dart 3.12.2:

- `isar` ^3.1.0+1 resolves *on its own*, but `isar_generator` 3.1.0+1 pins `source_gen ^1.2.2` and `dart_style ^2.2.3`, which is **incompatible with `freezed` ^3.0.0** (needs `source_gen ^2.0.0` / `dart_style ^3.0.0`). Version solving fails outright. Upstream Isar is therefore unusable in this project, not merely stale.
- `isar_community` / `isar_community_flutter_libs` / `isar_community_generator` ^3.3.2 resolve cleanly alongside `freezed` ^3.0.0 and `json_serializable` ^6.8.0 (it pulls `source_gen` 4.2.4), and a combined `build_runner` run generates Isar, Freezed and json_serializable outputs together with no conflict. A collection using `@Index(type: IndexType.words)` — the index search depends on — generates and analyses correctly.

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

`SearchDocuments` queries Isar's word-indexed `OcrTextEntity` and the `title` index, merges by document id, and returns results with a match snippet and its source (title or text). Archived documents are excluded unless explicitly requested. Filters (folder, creation-date range, modified-date range) are applied as indexed query clauses, not as in-memory post-filtering, so performance holds at several thousand documents.

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
3. **Edge-detection implementation — needed for phase 3b, not blocking 3a.** Native CV binding versus a pure-Dart contour detector in `image`. Decide on measured detection quality and app-size cost against real captures.
4. **OCR language set.** Which languages ship in V1, and whether any require a downloadable model — which would need a first-use download flow and would qualify the "works entirely offline" claim for those languages specifically.
5. **Delete semantics.** The specs require deleted documents to be recoverable until permanently removed. Whether "deleted" is a distinct state or simply the archive needs confirming; if distinct, a retention policy (indefinite, or auto-purge after N days) is a product decision.
6. **Tablet layout ambition.** Whether tablets get a genuine two-pane master/detail layout or a responsive single-pane with a wider grid. The specs require only that the width be used well; the former is materially more work and more goldens.
