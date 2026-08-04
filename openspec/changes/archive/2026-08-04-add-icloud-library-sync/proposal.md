## Why

DocScanly currently keeps its iOS library only inside the device-local Documents container, so the library does not follow a user to another device through iCloud Drive. The product has also been renamed from DocForge to DocScanly, requiring the public folder, Apple identifiers, user-facing copy, and migrations to agree on the new identity without losing existing documents.

## What Changes

- Completely rename the active product/code identity from DocForge/`doc_forge` to DocScanly/`doc_scanly`: user-facing copy, public folder, Dart package/imports, source filenames, classes/builders/helpers, Android/iOS configuration, tests, fixtures, current documentation, and generated references. Retain the old spelling only in isolated legacy-migration compatibility constants/tests and archived historical OpenSpec changes.
- Use `com.bruxkey.docscanly` as both the Android application ID/namespace and the iOS bundle identifier/explicit App ID, and configure the iCloud Documents container `iCloud.com.bruxkey.docscanly`; CloudKit and iCloud Extended Share Access remain disabled.
- Add iCloud Drive as an opt-in iOS storage location, backed by the app-owned container's document scope (presented by Files as `iCloud Drive/DocScanly`), while Android continues to use `Documents/DocScanly` through MediaStore.
- Add a storage-location setting and clear availability, migration, synchronization, download, conflict, and recovery states. The app never silently falls back to a second local library when iCloud is temporarily unavailable.
- Migrate the existing local `DocForge` tree to `DocScanly`, and when the user enables iCloud, copy and verify the complete active and Trash payload tree before switching the active root or removing a source payload.
- Reconcile the iCloud directory into the device-local Isar index on startup, resume, explicit refresh, and relevant iCloud identity/container changes so a new device using the same Apple Account discovers the existing library automatically.
- Write a private, versioned library marker in the app-owned container so even an empty established library is recognized and selected automatically on a new device.
- Download an iCloud placeholder only when content is required for a thumbnail, viewer, edit, share, print, OCR, or other byte-reading operation; surface progress and recoverable failures rather than presenting a missing document.
- Offer an explicit folder-picker import for a manually created iCloud Drive folder named DocScanly; it is not treated as the app-owned container merely because its name matches.
- Update privacy messaging to disclose user-selected iCloud storage while retaining local-only handling for the Isar index, thumbnails, recognised text, working images, and secure-storage secrets.
- Extend deterministic unit, Cubit, repository, component, golden, and end-to-end coverage for migration, new-device discovery, offline/cloud-unavailable behaviour, conflicts, and branding.

## Capabilities

### New Capabilities

- `icloud-library-sync`: iOS iCloud-container access, automatic new-device discovery, lazy downloads, identity changes, conflicts, and manually selected iCloud-folder import.

### Modified Capabilities

- `public-document-storage`: Rename the public root to `DocScanly`, select the correct iOS local or iCloud root, and migrate existing local content safely.
- `document-library`: Reconcile cloud-backed entries and represent content availability without treating undownloaded files as missing.
- `app-settings`: Let an iOS user select local or iCloud storage and accurately explain storage, synchronization, and privacy behaviour.
- `app-security`: Replace the local-only guarantee with explicit user-controlled iCloud synchronization while keeping private metadata and credentials out of the public cloud container.
- `automated-verification`: Add deterministic platform-edge substitution and end-to-end coverage for iCloud selection, migration, discovery, and unavailable states.

## Impact

- **Platforms:** Android and iOS only. iCloud behavior is iOS-only; Android receives the DocScanly branding/public-folder migration but no cloud provider.
- **Apple configuration:** Register/use explicit App ID `com.bruxkey.docscanly`, iCloud container `iCloud.com.bruxkey.docscanly`, iCloud Documents entitlement, container presentation keys, and regenerated development/distribution profiles. No CloudKit or Extended Share Access entitlement is added.
- **Android configuration:** Change the Gradle `applicationId` and `namespace`, Kotlin package/path, manifest label, and release identity to `com.bruxkey.docscanly`/DocScanly. If an Android store listing already exists under another application ID, this identifier change requires a new listing rather than an in-place update.
- **Architecture:** Add `lib/features/cloud_storage/` with `presentation/{cubit,screens,widgets}`, `application/usecases`, `domain/{entities,repositories,failures}`, and `infrastructure/{datasource,models,repositories}`. Extend `lib/core/storage/public_storage/` with a root-selection/cloud-availability seam; composition remains explicit in `lib/app/`.
- **Dart identity:** Rename the pub package to `doc_scanly`, update every `package:doc_forge/` import to `package:doc_scanly/`, rename active DocForge-named public/internal symbols and files (for example `DocForgeApp`, `buildDocForge`, and `doc_forge.dart`), and regenerate references. Legacy migration vocabulary is narrowly allowlisted.
- **Cubits and states:** Add a storage-location/migration Cubit with availability, confirmation, copying, verifying, completed, and recoverable-error states; extend library state with per-entry cloud availability and reconciliation status. Business decisions remain in use cases.
- **Use cases and repositories:** Add container availability, choose-location, migrate-library, reconcile-cloud-library, ensure-local-copy, and import-external-folder use cases behind injected repository interfaces. The native iOS channel is infrastructure only.
- **Isar and preferences:** Keep Isar device-local. Add an idempotent index-rebuild/reconciliation path and persist a versioned storage-location/migration preference. Add Isar fields only if required for stable cloud identity and availability; any schema change must be backward compatible. No new secure-storage key is expected.
- **Navigation:** Add a typed storage-location route from Settings and a migration/progress surface; no string-literal routes.
- **Dependencies:** Prefer Foundation APIs through a small first-party Flutter method/event channel, adding no Dart package. If implementation proves a maintained package necessary, its permissive commercial licence and platform support must be documented before addition.
- **Performance:** Enumerate metadata off the UI path, reconcile incrementally in bounded batches, debounce lifecycle-triggered scans, lazily download bytes, and rebuild only affected list items. Avoid polling, duplicate full-tree scans, and eager downloading.
- **Security and privacy:** PDFs and the reserved Trash payload namespace may synchronize only after explicit selection; Isar, thumbnails, OCR text, working captures, and passwords remain app-private/local, with passwords only in secure storage. Logs never contain document names, paths, contents, Apple identity tokens, or credentials.
- **Previews:** Add deterministic previews for storage selection and migration widgets/screens covering default, loading, empty/unavailable, error, long content, phone/tablet, and light/dark states; update affected Settings and library previews for cloud states.
- **Testing:** Unit tests cover policies/use cases/failure mapping; Cubit tests cover complete state sequences; repository/channel tests cover container and download behavior; serialization/migration tests cover any persisted model; component and golden tests cover Settings/migration/library states; navigation tests cover typed routes; Tier-3 flows cover enable-and-migrate and new-device discovery with a deterministic fake iCloud edge. Existing browse, view, edit, share, Trash, restore, purge, and Android flows must remain green.
- **Risks and mitigations:** Partial migration is mitigated by copy-verify-switch cleanup; duplicate libraries by one persisted authoritative root; iCloud outages by explicit unavailable states and retry; external conflicts by deterministic reconciliation and non-destructive conflict naming; large libraries by incremental scans/lazy downloads; brand migration by versioned, restart-safe steps.
- **Future extensibility:** The storage-provider and reconciliation contracts can later support CloudKit metadata, another provider, or richer cross-device metadata without replacing Isar now.
- **Definition of Done:** Apple identifiers/entitlements and visible branding are coherent; existing local users migrate without loss; a same-account new device discovers the app-owned iCloud library automatically; unavailable/offline/conflict paths are recoverable; accessibility and previews are complete; formatting, analysis, layering/platform checks, all three test tiers, goldens, and coverage gates pass.
