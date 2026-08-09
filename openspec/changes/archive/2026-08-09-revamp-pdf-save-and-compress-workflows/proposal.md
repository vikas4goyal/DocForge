## Why

Saving a newly created PDF and compressing an existing PDF currently hide important output choices behind small or incomplete dialogs, offer coarse quality controls, and do not let the user inspect the actual result before committing it. These workflows need dedicated, responsive screens that make naming, protection, quality, expected size, preview, progress, cancellation, and output ownership explicit.

## What Changes

- Replace the creation save dialog with a typed, full-page Save PDF workflow containing the editable output name, page count, quality slider, asynchronously calculated output size, Preview, and Save actions.
- Allow quality from 30% through 100%. The percentage scales each source image's width and height relative to its original dimensions; it is not a promised percentage reduction in encoded bytes. The Settings PDF-quality value supplies the Save screen's initial selection, while the user can override it for the current document.
- Let the user override quality for an individual page in Save or Compress. The document slider remains the default; each explicit page override wins only for that page and can be reset to “Use document quality.” Preview, size calculation, and Save use the same effective per-page values.
- Move password entry into a focused confirmation dialog opened from the Save screen. After a valid matching password is accepted, the screen shows that password protection is enabled without revealing the password and offers a Remove action.
- Generate a cancellable temporary PDF for Preview and open it in a read-only PDF preview/viewer. Cancelling or leaving Preview returns to the unchanged Save screen; saving remains available without previewing.
- Replace the focused compression sheet with a full-page Compress PDF workflow containing original size, a 30–100% quality slider initially set to 80%, an asynchronously calculated resulting size and saving, Preview, and Save.
- Treat 100% compression quality as no compression. Saving at 100% first warns that the result will retain the current quality and is not expected to reduce file size.
- On compression Save, ask whether to create a collision-safe copy or overwrite the original. Overwrite uses an atomic replacement; copy leaves the source untouched. Both preserve page count and document validity.
- Run exact candidate-size calculation, preview generation, saving, and compression off the UI thread. Debounce and cancel obsolete size calculations when the slider changes, expose calculation progress, and never make Save wait for a size calculation.
- Show modal progress with a percentage and Cancel for Preview and Save. Cancellation removes temporary/partial output and returns to the originating Save or Compress screen with all choices intact. A completed save closes the workflow and navigates to or refreshes the saved document as appropriate.
- Preserve failure safety, offline behavior, dark mode, accessibility, phone/tablet responsiveness, deterministic state, previews, and all three automated-test tiers.
- Separate camera capture resolution from PDF quality. Settings offers only resolution tiers the active device/camera can actually satisfy (for example 720p, 1080p, 2K, or 4K), defaults to the active camera's highest full supported resolution, and capture/add-page uses that selection before any crop, enhancement, or PDF scaling.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pdf-generation`: Replace dialog-led saving and coarse quality presets with a dedicated configurable Save PDF screen, optional password status/removal, exact non-blocking size calculation, cancellable preview, and cancellable save.
- `pdf-editing`: Replace the current compression flow with a dedicated quality-driven screen, exact non-blocking size calculation, cancellable preview/save, 100% warning, and explicit copy-versus-overwrite choice.
- `app-settings`: Define PDF quality as the default selection for newly opened Save PDF workflows while allowing a per-document override; compression keeps its independent 80% default.
- `document-scanning`: Select camera capture resolution from the active device's reported capabilities and keep it separate from post-capture PDF quality.

## Impact

### Architecture and folders

The change remains Android/iOS-only and preserves feature-first clean architecture:

```text
lib/features/pdf_generation/
  presentation/cubit/       # Save configuration, estimate, preview, and save UI state
  presentation/screens/     # Dedicated Save PDF and temporary PDF preview screens
  presentation/widgets/     # Quality, size, password-status, and progress widgets
  application/usecases/     # Calculate candidate size, prepare preview, save/cancel output
  domain/entities/          # Document/page percentage quality and immutable save request/result values
  domain/repositories/      # Cancellable candidate generation contract
  infrastructure/           # Isolate-backed candidate PDF generation and temp cleanup
lib/features/pdf_editing/
  presentation/cubit/       # Compression configuration and independent async phases
  presentation/screens/     # Dedicated Compress PDF screen
  presentation/widgets/     # Size comparison, quality, output choice, and progress widgets
  application/usecases/     # Calculate, preview, save-copy, and atomic-overwrite operations
  domain/entities/          # Per-page compression request, destination choice, and result values
  domain/repositories/      # Cancellable compression candidate contract
  infrastructure/           # PDF page raster/downsample pipeline and atomic replacement
lib/features/app_settings/
  presentation/             # PDF default plus device-supported camera-resolution selector
  application/domain/infrastructure/ # Persisted defaults and camera capability abstraction
lib/features/document_scanning/
  presentation/application/ # Loads supported resolutions and applies the selected capture tier
  domain/infrastructure/    # Camera capability contract and plugin-backed resolution mapping
lib/core/
  cancellation/ or jobs/    # Shared job token/progress abstraction only if existing core APIs cannot serve both features
```

Features continue to communicate through injected abstractions; Cubits coordinate UI only, use cases own workflow rules, and repositories own filesystem/PDF-engine work. No service locator, singleton, global mutable state, or cross-feature import is introduced.

### Cubits, states, use cases, repositories, storage, and navigation

- The PDF-generation Cubit/State gains draft name, document quality, page-quality overrides keyed by stable page ID, password-enabled status, independently cancellable calculation/preview/save phases, progress, calculated bytes, and typed failures. Password text itself is confined to the short-lived password input boundary and is never placed in Equatable state, logs, fixtures, analytics, preferences, or Isar.
- The PDF-editing Cubit/State gains document compression quality, page-index overrides, original/calculated sizes, independent job identity/progress, preview lifecycle, and pending copy/overwrite choice. Stale calculation completions are ignored by deterministic job tokens.
- New or revised use cases validate the 30–100% range, calculate an exact candidate in temporary storage, prepare a preview candidate, save without waiting for calculation, promote/reuse a matching candidate when safe, create a collision-safe copy, atomically overwrite, and clean up on cancellation/failure.
- Repository contracts report progress and accept cancellation for candidate generation and commit. Temporary candidates are private, non-authoritative files; document records are created or updated only after a verified PDF has been committed.
- Existing Isar document fields remain sufficient; final byte size and selected generation quality continue to be recorded. If the current quality value is an enum, persistence receives a backward-compatible mapping or additive migration to integer percentage values. No page-table migration is required.
- The existing PDF-quality SharedPreferences key is retained or version-migrated to a 30–100 integer default. Existing presets map deterministically to percentages. The current image-quality preference is migrated to a camera-resolution preference selected from capabilities reported for the active device/camera; photo-library originals are not upscaled. No new secure-storage key format is required; saved passwords continue to use the existing per-document secure-storage contract.
- Typed GoRouter routes replace the save dialog and focused compression sheet with Save PDF, Compress PDF, and temporary preview destinations. Successful Save closes the originating workflow. Successful compression copy opens the new document; successful overwrite refreshes the original and closes Compress.

### Dependencies, performance, security, and future sync

- No new package is planned. The implementation reuses the installed camera plugin and its capability/preset mapping, PDF engine/composer, isolate facilities, secure storage, Isar, SharedPreferences, and typed routing.
- Slider updates are debounced; only the latest calculation may publish state. Exact size work runs in a background isolate, reports percentage progress, uses bounded page-by-page memory, and cleans superseded temporary files. The UI rebuilds only size/progress selectors. Save cancels or supersedes calculation and starts immediately; it may reuse a verified candidate only when every output-affecting input matches.
- A percentage changes raster dimensions, so encoded bytes are deliberately presented as a separately calculated result rather than inferred linearly. Each page uses its override or the document percentage. At effective 100%, Save preserves that page's input dimensions, while Compress passes that page through without downsampling/recompression; the no-compression warning applies only when every page is effectively 100%.
- Passwords remain sensitive: they are accepted through obscured fields, compared without logging, passed directly to the save/protection operation, retained only through the existing secure-storage repository after commit, and removed from transient controllers after use or cancellation. Preview temporary files for protected saves remain app-private and are deleted when preview ends.
- The design leaves future cloud sync at the document repository boundary: only fully committed documents and metadata become authoritative/syncable; calculations, previews, partial files, passwords, and job state remain local and excluded from sync.

### Testing, previews, risks, and Definition of Done

- Unit tests cover percentage validation/scaling, per-page precedence/reset, preset migration, camera capability filtering/fallback, exact-size job supersession, cancellation cleanup, candidate reuse rules, password handling boundaries, 100% behavior, copy naming, atomic overwrite, typed failures, and Cubit state sequences.
- Component tests wire each screen to real Cubits/use cases with repositories substituted only at the boundary and exercise slider changes, calculation progress, Save during calculation, password set/remove, preview cancellation, save cancellation, copy/overwrite, and completed navigation.
- Navigation tests cover typed entry/exit for Save, Compress, and Preview. Repository tests cover valid PDF/page-count preservation, byte reporting, temp cleanup, failure rollback, and atomic replacement. Serialization/migration tests cover any changed percentage preference/document metadata representation.
- Golden tests cover Save and Compress on phone/tablet, light/dark, long names, maximum supported text scale, password enabled, calculating, preview/save progress, failure, and copy/overwrite/100% dialogs.
- Tier-3 flows extend creation/save and edit/compress journeys exclusively through stable keys and semantics, including cancelling preview/save and saving while size calculation is unfinished.
- Reusable slider, size estimate, password status, progress, and output-choice widgets receive deterministic `@Preview()` coverage for default, loading, empty/not-calculated, error, and long-content states. Save and Compress screens additionally cover phone/tablet and light/dark variants without live files, services, randomness, or wall clock.
- Key risks are CPU/battery cost from repeated exact calculation, memory use for large PDFs, misleading percent/byte expectations, and destructive overwrite. They are mitigated with debounce/cancellation, isolates and bounded page processing, explicit explanatory copy plus actual calculated bytes, verified temporary output, and atomic replacement with rollback.
- Definition of Done: all specified controls, progress, cancellation, cleanup, success navigation, accessibility, responsive layouts, and offline behavior work on Android and iOS; every public API has required dartdoc; no password leaks into state or persistence outside secure storage; no orphan/partial output remains after failure or cancellation; format, analysis, layering/platform checks, unit/component tests, goldens, coverage, and available attached-device Tier-3 verification pass.
