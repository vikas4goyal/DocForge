## Why

`doc_forge` is currently an empty Flutter scaffold: `lib/main.dart` is the default counter app and no dependencies beyond `cupertino_icons` and `flutter_lints` are installed. DocForge V1 needs a complete, privacy-focused document scanning and PDF productivity application in which a new user can scan a document, get a searchable PDF, organise it, find it and share it within minutes — with no account and no internet connection.

This change establishes the entire V1 product surface and, with it, the foundations every later feature will inherit: feature-first clean architecture, flutter_bloc/Cubit state management, GoRouter typed navigation, Isar persistence, explicit constructor DI, widget previews and the mandatory testing baseline. Getting these foundations right now is far cheaper than retrofitting them once fourteen features exist.

**Scope note:** this is deliberately a large, whole-product change. It is decomposed into 14 independent capabilities and the task list is phased so each capability lands complete (implementation + tests + previews) before the next begins. If a smaller first slice is preferred, task groups 1–9 (foundation, core, onboarding, library, app shell, scanning, enhancement, OCR, PDF generation) form a shippable vertical slice on their own.

## What Changes

- **Project foundation**: adopt the dependency set, `lib/core/` shared layer, composition root, GoRouter typed route table, Material 3 light/dark theming, Isar schema and CI pipeline described in the project context. Replaces the default counter app in `lib/main.dart`.
- **First-launch onboarding**: welcome screen, privacy & offline-first introduction, just-in-time camera permission request, then Home. Returning users go straight to Home.
- **Home shell**: search bar, prominent Scan Document action, recent documents, shortcuts to All Documents / Folders / Favourites / Archive, storage summary, and a first-run empty state that invites the first scan.
- **Document scanning**: single-page, multi-page and batch capture with automatic edge detection, manual edge adjustment, perspective correction, page rotation, reordering and deletion.
- **Image enhancement**: Original, Auto Enhance, Magic Colour, Black & White, Grayscale, plus brightness, contrast, sharpen and shadow removal — with immediate preview before saving.
- **Offline OCR**: on-device text recognition producing an invisible text layer for searchable PDFs, plus copy, search and export of recognised text. No network required at any point.
- **PDF generation**: convert enhanced pages into a quality-configurable searchable PDF stored locally.
- **PDF editing**: merge, split, rotate, delete, extract, duplicate, compress, watermark, password-protect, remove password, and view metadata.
- **Document library**: document records (title, created, modified, page count, size, folder, favourite, archive) with rename, move, duplicate, favourite, archive, restore, delete and permanent removal; full folder management with per-folder document counts.
- **Search**: as-you-type search across document titles and OCR text, filterable by folder and creation/modified date.
- **Document viewer**: PDF rendering with zoom, continuous scroll, jump-to-page, share, print and entry into the editing tools.
- **Sharing & export**: share PDF, page images or extracted text; print; export to device storage.
- **Import**: from camera, photo gallery, device files and the OS share sheet.
- **Settings**: theme, OCR language, PDF quality, image quality, default file naming, default save location, biometric lock, storage information, About and Privacy Policy.
- **Security**: local-only document storage, biometric/device-credential application lock, password-protected PDFs, and a hard guarantee that no user document is uploaded anywhere.
- Cross-cutting and mandatory throughout: Material 3 with adaptive Cupertino affordances, dark mode, responsive phone/tablet layouts, screen-reader semantics, large text, high contrast, accessible touch targets, and typed error recovery for every failure path.

**Not in scope (explicitly deferred):** cloud sync (Drive/Dropbox/OneDrive/iCloud), automatic backup, AI classification/summary/rename, receipt/invoice/business-card scanners, and Office document conversion. The architecture leaves room for these; see *Future extensibility*.

**No breaking changes** — there is no existing released behaviour to break. The default counter app in `lib/main.dart` and its scaffold widget test are removed.

## Capabilities

### New Capabilities

- `onboarding`: first-launch welcome, privacy & offline introduction, just-in-time camera permission, and the first-launch-vs-returning-user decision.
- `app-shell`: Home screen composition, primary navigation, storage summary, empty states, Material 3 theming, dark mode, responsive/tablet layout and the accessibility baseline all other capabilities inherit.
- `document-scanning`: camera capture, automatic and manual edge detection, perspective correction, page rotation/reorder/delete, multi-page and batch scanning.
- `image-enhancement`: the enhancement filter set and per-page adjustments with immediate preview.
- `ocr`: offline on-device text recognition, the searchable-PDF text layer, and copy/search/export of recognised text.
- `pdf-generation`: assembling enhanced pages plus the OCR text layer into a quality-configurable PDF.
- `pdf-editing`: merge, split, rotate, delete, extract, duplicate, compress, watermark, protect/unprotect and metadata inspection.
- `document-library`: document metadata model and lifecycle operations (rename, move, duplicate, favourite, archive, restore, delete, permanently remove) plus folder management.
- `document-search`: as-you-type search over titles and OCR text with folder and date filters.
- `document-viewer`: PDF rendering, zoom, continuous scroll, jump-to-page and entry points to share/print/edit.
- `document-sharing`: share PDF, images and extracted text; print; export to device storage.
- `document-import`: import from camera, gallery, device files and the OS share sheet.
- `app-settings`: all user-configurable preferences, storage information, About and Privacy Policy.
- `app-security`: biometric/device-credential app lock, local-only storage guarantee, and secure handling of PDF passwords.

### Modified Capabilities

None. `openspec/specs/` is empty; this change introduces the first specifications.

## Impact

### Architecture impact — feature folders and layers

One feature folder per capability under `lib/features/`, each with the full four-layer structure. Shared code lives in `lib/core/`.

```
lib/
  main.dart                        # thin entry point -> composition root
  app/
    app.dart                       # MaterialApp.router, theming
    composition_root.dart          # builds data sources -> repos -> use cases -> Cubits
    router/
      app_router.dart              # GoRouter + TypedGoRoute route table
  core/
    theme/                         # Material 3 light/dark, text scaling, contrast
    widgets/                       # shared widgets (empty state, error view, loading)
    previews/                      # shared preview fixtures and wrappers
    failures/                      # base Failure hierarchy shared across features
    contracts/                     # cross-feature domain interfaces (see below)
    storage/                       # Isar instance, SharedPreferences, secure storage wrappers
    permissions/                   # permission abstraction
    isolates/                      # isolate helpers for image/OCR/PDF work
  features/
    <capability>/                  # one per capability listed above
      presentation/
        cubit/                     # Cubit + Equatable State per screen/flow
        screens/
        widgets/
      application/
        usecases/
      domain/
        entities/
        repositories/              # interfaces only
        failures/
      infrastructure/
        datasource/
        models/                    # Freezed + json_serializable DTOs, mappers
        repositories/              # implementations
```

**Dependency direction:** presentation → application → domain; infrastructure depends on domain and implements its interfaces; domain depends on nothing. No feature imports another feature. Where capabilities must cooperate — the viewer needs a document, search needs OCR text, scanning hands pages to PDF generation — they do so through domain-level interfaces declared in `lib/core/contracts/` (e.g. `DocumentReader`, `OcrTextSource`, `PageBundleSink`) and injected by the composition root. Concretely: `document-scanning` produces a `ScannedPageBundle` value object and never references `pdf-generation` types; `document-viewer` receives a `DocumentId` and resolves it through `DocumentReader`.

### Cubits, States, use cases, repositories, Isar schema, navigation

- **Cubits (new)** — one or more per capability, each owning an Equatable state: `OnboardingCubit`, `HomeCubit`, `ScanCaptureCubit`, `PageReviewCubit`, `EnhancementCubit`, `OcrCubit`, `PdfGenerationCubit`, `PdfEditCubit`, `DocumentListCubit`, `DocumentDetailCubit`, `FolderCubit`, `SearchCubit`, `ViewerCubit`, `ShareCubit`, `ImportCubit`, `SettingsCubit`, `AppLockCubit`. `SearchCubit` is the one candidate for a full Bloc (debounce on as-you-type input via an event transformer); design.md decides and justifies it.
- **States (new)** — every Cubit gets an immutable Equatable state listing all fields in `props`, covering at minimum default/loading/empty/error variants so previews and `bloc_test` sequences stay exhaustive.
- **Use cases (new)** — all business logic sits here: `CapturePage`, `DetectEdges`, `ApplyPerspectiveCorrection`, `ApplyEnhancement`, `RecogniseText`, `BuildSearchablePdf`, `MergePdfs`, `SplitPdf`, `CompressPdf`, `WatermarkPdf`, `ProtectPdf`, `RemovePdfPassword`, `ReadPdfMetadata`, `SaveDocument`, `RenameDocument`, `MoveDocument`, `DuplicateDocument`, `ArchiveDocument`, `RestoreDocument`, `DeleteDocument`, `PurgeDocument`, `CreateFolder`, `RenameFolder`, `DeleteFolder`, `SearchDocuments`, `ShareDocument`, `PrintDocument`, `ExportDocument`, `ImportFromGallery`, `ImportFromFiles`, `HandleSharedFiles`, `LoadSettings`, `UpdateSetting`, `AuthenticateAppLock`, `ComputeStorageSummary`.
- **Repository interfaces (new, domain layer)** — `DocumentRepository`, `FolderRepository`, `PageRepository`, `OcrRepository`, `PdfRepository`, `ScannerRepository`, `SettingsRepository`, `SecureStorageRepository`, `ShareRepository`, `ImportRepository`, `AppLockRepository`, `StorageInfoRepository`. Implementations live in each feature's `infrastructure/repositories/`.
- **Isar schema (new — first schema, so no migration from a prior version)** — collections `DocumentEntity`, `PageEntity`, `FolderEntity`, `OcrTextEntity`. `OcrTextEntity` carries the full-text index that powers search; page images and PDFs are stored as files on disk under app-private storage with only their paths in Isar, so the database stays small and fast.
- **Navigation (new)** — a single GoRouter table with typed routes: `/onboarding`, `/` (home), `/scan`, `/scan/review`, `/scan/enhance`, `/documents`, `/documents/:id`, `/documents/:id/edit`, `/folders`, `/folders/:id`, `/search`, `/favourites`, `/archive`, `/settings`, `/settings/about`, `/settings/privacy`, and an `/unlock` gate. No string-literal navigation anywhere in feature code.

### New dependencies (all Android/iOS compatible)

| Package | Why |
|---|---|
| `flutter_bloc`, `equatable`, `bloc_test` | Mandated state management; Equatable states; state-sequence testing. |
| `go_router`, `go_router_builder` | Mandated typed navigation. |
| `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation`, `build_runner` | Mandated immutable models and serialization; no manual JSON. |
| `isar`, `isar_flutter_libs`, `isar_generator` | Mandated primary database. See *Risks* on maintenance status. |
| `shared_preferences` | Simple preferences (theme, quality, naming). |
| `flutter_secure_storage` | PDF passwords and app-lock configuration. |
| `dio` | Not used by any V1 user flow; wired behind repository abstractions only so the future sync layer has a home. Justified solely by the "leave room for cloud sync" constraint. |
| `camera` | Capture pipeline under our own control (needed for batch capture UX). |
| `google_mlkit_text_recognition` | Fully on-device OCR on both platforms — satisfies the offline requirement. |
| `image` | Pure-Dart enhancement filters and perspective transform, runs in isolates. |
| `pdf` + `printing` | PDF composition with an invisible OCR text layer; printing and share sheets. |
| `pdfrx` | Actively maintained PDF rendering for the viewer. |
| PDF manipulation library (decision deferred to design.md) | Merge/split/compress/watermark/encrypt on *existing* PDFs. `syncfusion_flutter_pdf` covers all of it but carries licence conditions; a native-plugin or pure-Dart combination is the alternative. See *Risks*. |
| `permission_handler` | Just-in-time camera/photos/files permissions with denied-state recovery. |
| `local_auth` | Biometric / device-credential app lock. |
| `image_picker`, `file_picker`, `receive_sharing_intent` | Gallery, files and OS share-sheet import. |
| `share_plus` | Share PDF, images, text. |
| `path_provider` | App-private document storage locations. |
| `intl` | Date formatting and default file naming. |
| `mocktail`, `integration_test`, `alchemist` (or built-in golden matchers) | Mocks, integration tests, stable golden tests. |

No web or desktop packages, plugins, platform folders or build configuration are introduced.

### Migration considerations

- **Isar**: this change creates the initial schema, so there is nothing to migrate from. Every collection ships with an explicit `schemaVersion` field and a documented upgrade path from day one so V2 migrations are mechanical.
- **SharedPreferences keys**: namespaced `settings.*` (e.g. `settings.themeMode`, `settings.ocrLanguage`, `settings.pdfQuality`, `settings.imageQuality`, `settings.fileNamingPattern`, `settings.defaultSaveLocation`). Keys are declared as documented constants in one file, never inline strings.
- **Secure-storage keys**: namespaced `secure.*` (e.g. `secure.appLockEnabled`, `secure.pdfPassword.<documentId>`). Same single-source-of-truth rule.
- **File layout on disk**: `<appDocuments>/documents/<documentId>/` holds pages and the generated PDF. The layout is versioned so a future migration can relocate files without losing references.
- **Routes**: new route table; no existing deep links to preserve. Route paths are stable from V1 to keep future deep links and share-sheet targets valid.
- **Removed**: the default counter app in `lib/main.dart` and `test/widget_test.dart`.

### Performance considerations

- Image enhancement, perspective correction, OCR and PDF composition all run in **background isolates**; the UI thread never blocks on them. Long operations report progress through Cubit states and are cancellable.
- Document lists, folder contents and search results are **paginated/lazily loaded**; thumbnails are generated once, cached on disk at display resolution, and never decoded at full size for list rows.
- The viewer renders pages on demand rather than rasterising a whole PDF, so large documents open quickly and scroll smoothly.
- Rebuild cost is controlled with `BlocSelector` and `buildWhen` so only the smallest affected subtree rebuilds; list rows are `const` where possible.
- Isar queries backing search are indexed; OCR text lives in its own collection so document-list queries never load it.
- Battery: the camera is released the moment capture ends, OCR runs once per page and its result is persisted, and no background polling or network activity exists in V1.
- Targets to verify: cold start under 2s on a mid-range device, document open under 1s, smooth 60fps scrolling with 1,000+ documents.

### Security considerations

- **All documents stay on the device.** No user document, page image or OCR text leaves the app in V1 except through an explicit user-initiated share, export or print. There is no telemetry of document content.
- Documents and page images are written to **app-private storage** (`path_provider` application documents directory), not to shared/external storage where other apps could read them.
- **Sensitive data** — PDF passwords and app-lock configuration — goes to `flutter_secure_storage` (Keychain / EncryptedSharedPreferences), never to SharedPreferences or Isar. Passwords are held in memory only for the duration of the operation and are never logged.
- **App lock** uses `local_auth` with device-credential fallback, gating the app at the router level so no document content is rendered before authentication.
- Permissions are requested **just in time** and only for camera, photos and files, each with a clear rationale screen and a recovery path to system settings when denied.
- Imported files are validated before processing; a malformed or malicious PDF must fail into a typed failure, not crash the app.

### Testing strategy

Every capability ships with the full mandated set before it is considered done:

- **Unit tests** — every use case, every entity/value-object business rule, mappers, and the enhancement/perspective maths.
- **Cubit tests** (`bloc_test`) — the full emitted state sequence for every Cubit, including loading, empty, error and cancellation paths.
- **Widget tests** — every screen and reusable widget, asserted through the stable widget keys defined in design.md.
- **Repository tests** — each implementation against an in-memory/temp-directory Isar instance and fake data sources; offline behaviour asserted explicitly.
- **Serialization tests** — round-trip every Freezed/json_serializable DTO and every Isar entity mapping.
- **Navigation tests** — every typed route, including the `/unlock` gate and the onboarding-vs-home first-launch branch.
- **Integration tests** — the primary flow end to end (scan → review → enhance → OCR → PDF → save → appears in Recent → search → open → share) with camera, OCR and share plugins faked at the repository boundary; plus import, PDF-edit and app-lock flows.
- **Golden tests** — every major screen (Home, Camera Review, Enhancement, Viewer, Document List, Folder, Search, Settings) in light and dark, phone and tablet.

Coverage gates: **≥80% overall, ≥90% for business logic** (`application/` and `domain/`). CI fails below either threshold.

### Preview coverage

Every reusable widget and every screen ships `@Preview()` entries fed exclusively by fixtures from `lib/core/previews/` — no live camera, no OCR engine, no network, no real Isar instance, no randomness or wall-clock dependence. Widgets are previewed by direct construction with fixture data or by wrapping in a `BlocProvider` with a fake Cubit seeded to the target state.

- **Every reusable widget** (document card, folder tile, page thumbnail, storage summary, search result row, enhancement filter chip, empty state, error view, progress indicator, page reorder tile, metadata sheet, …): default, loading, empty, error and long-content previews.
- **Every screen** (Welcome, Privacy Intro, Permission Request, Home, Camera Capture, Page Review, Enhancement, PDF Preview, Document List, Document Detail, Folder List, Folder Detail, Search, Viewer, PDF Edit tools, Import, Settings, About, Privacy Policy, Unlock): the same five states **plus** phone, tablet, light and dark previews.

### CI

The pipeline runs `flutter pub get` → `dart format --set-exit-if-changed` → `flutter analyze` → `flutter test` → integration tests → golden tests → coverage, and fails on any formatting, analysis, test or coverage-threshold violation. Build matrix covers Android and iOS only.

### Definition of Done

1. All 14 capability specs are implemented and every requirement is observable and covered by a test.
2. The success-criteria journey passes as an automated integration test: install → scan → searchable PDF → saved locally → found from Home → organised into a folder → searched → edited → shared, with no account and airplane mode on.
3. Every Cubit has `bloc_test` coverage of its full state sequence; no business logic exists inside any Cubit.
4. Every public class, function, method, constructor and top-level constant carries dartdoc; non-obvious logic carries explanatory inline comments.
5. Every widget and screen has its required `@Preview()` entries and they render from fixtures alone.
6. `dart format`, `flutter analyze` and the full test suite pass; coverage ≥80% overall and ≥90% for business logic.
7. Golden tests exist for every major screen in light/dark and phone/tablet.
8. Accessibility verified: screen-reader labels on every important control, large text and high contrast honoured, touch targets ≥48dp.
9. Every error path in the *Error Handling* requirements shows a clear message with a recovery action.
10. Manual verification on a physical Android device and a physical iPhone; no web or desktop artefacts anywhere in the repo.

### Risks and mitigations

| Risk | Mitigation |
|---|---|
| **Scope.** Fourteen capabilities in one change risks a long unmergeable branch. | Tasks are phased by capability; each phase is independently complete (implementation + tests + previews) and mergeable. Task groups 1–9 form a shippable slice. |
| **Isar maintenance status.** Upstream Isar 3.x has been largely dormant; the community fork is the practical choice. | Confirm the exact package/version in design.md before phase 0 lands. All access is already behind `*Repository` interfaces, so swapping the engine (e.g. to Drift/sqlite with FTS5) touches only `infrastructure/`. A repository-level test suite makes that swap verifiable. |
| **PDF manipulation library licensing.** `syncfusion_flutter_pdf` covers merge/split/compress/watermark/encrypt but its community licence has revenue and registration conditions. | Decide explicitly in design.md with the licence terms written down; keep every call behind `PdfRepository` so an alternative can be substituted without touching features. |
| **Edge detection quality.** Automatic detection is the single biggest driver of perceived scan quality and is hard to get right in pure Dart. | Manual edge adjustment is a first-class requirement, not a fallback — the user can always correct detection. Evaluate the native document-scanner APIs (ML Kit Document Scanner on Android, VisionKit on iOS) behind `ScannerRepository` during phase 3. |
| **OCR accuracy and language coverage.** On-device recognition is weaker than cloud OCR, especially on non-Latin scripts. | Set expectations in the UI, make OCR language configurable, allow re-running OCR, and never block PDF creation on OCR success — a PDF without a text layer is still a valid document. |
| **Memory on large batch scans.** Holding many full-resolution page images can OOM on low-end devices. | Pages are written to disk immediately after capture and referenced by path; only thumbnails stay in memory. Enforced by a repository contract and covered by tests. |
| **Camera and permission fragmentation across devices.** | Every permission and camera failure maps to a typed failure with a recovery action; the camera is abstracted behind `ScannerRepository` so tests and previews never touch hardware. |
| **Golden-test flakiness across platforms.** | Fixed test fonts and a fixed device surface; goldens generated on a single canonical configuration in CI. |

### Future extensibility

- **Cloud sync** is the primary forward path. `dio` is wired behind repository abstractions from day one; every Isar entity carries `updatedAt` and a stable UUID `id` (not an auto-increment key) so records can be reconciled across devices; the file layout on disk is versioned and content-addressable enough to diff. Adding Drive/Dropbox/OneDrive/iCloud means adding a `RemoteDocumentDataSource` behind the existing `DocumentRepository`, plus a sync-state field — no feature code changes.
- **Automatic backup** reuses the same export pipeline already built for `document-sharing`.
- **AI classification, summaries and rename** consume the OCR text that `ocr` already persists; they become new use cases behind a `DocumentIntelligenceRepository` with no changes to storage.
- **Receipt/invoice/business-card scanners** are new features that reuse `document-scanning` and `ocr` through their existing domain contracts rather than forking the capture pipeline.
- **Office document conversion** slots in behind `PdfRepository` as an additional import path.

### Platform confirmation

This change targets **Android and iOS only**. No web, macOS, Windows or Linux platform folders, dependencies, build configuration or CI targets are introduced by any part of it, and every package selected above is verified to support both mobile platforms.
