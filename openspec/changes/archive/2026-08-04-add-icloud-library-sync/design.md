## Context

DocScanly currently constructs a `FilesystemPublicFileStore` over the iOS application Documents directory and a `MediaStorePublicFileStore` over Android `Documents/DocForge`. Relative paths and reconciliation already prevent most features from depending on absolute device paths, but root selection is fixed at composition time and the Isar index assumes all bytes are immediately local. The iOS target still identifies as `com.bruxkey.docForge`, while Android uses `com.bruxkey.doc_forge`; neither platform yet has the final DocScanly identity, and iOS has no iCloud entitlements.

The change crosses Apple signing, native Foundation APIs, storage composition, library reconciliation, Settings, privacy copy, branding, migrations, and all three verification tiers. Isar remains a device-local index; the iCloud Documents container is the cross-device source of PDF/folder truth. Android remains offline/local and receives only the public-folder and user-facing brand migration.

## Goals / Non-Goals

**Goals:**

- Present the product as DocScanly, use `com.bruxkey.docscanly` as both Android application ID/namespace and iOS bundle/App ID, and use `iCloud.com.bruxkey.docscanly` for the iOS container.
- Let an iOS user deliberately move the library between local storage and the app-owned iCloud Documents container without data loss.
- Reopen the same app-owned library automatically on a new same-account device, including when the library is empty.
- Rebuild/reconcile the local Isar index from cloud folder contents and lazily materialize bytes for operations that require them.
- Preserve local-first usability for already-downloaded content and provide honest unavailable/downloading/conflict states.
- Keep private derived data and credentials out of iCloud.

**Non-Goals:**

- CloudKit record databases, iCloud Extended Share Access, multi-user collaboration, Windows/web/macOS/Linux, Android cloud sync, or a general-purpose file provider.
- Synchronizing Isar files, thumbnails, OCR text, favourites, archive flags, custom ordering, or passwords between devices in this version.
- Automatically adopting an arbitrary same-named folder in the user's iCloud Drive root.
- Rewriting archived OpenSpec history or removing the narrowly scoped `DocForge`/`doc_forge` constants and fixtures required to recognize and migrate already-installed data.

## Decisions

### 1. Use the app-owned iCloud Documents container, not CloudKit or an arbitrary folder

The Runner target will use explicit App ID `com.bruxkey.docscanly`, iCloud Documents container `iCloud.com.bruxkey.docscanly`, and an entitlements file referenced by every build configuration. `NSUbiquitousContainers` will expose the container document scope publicly with the display name “DocScanly”. CloudKit and `com.apple.developer.icloud-extended-share-access` remain absent.

Foundation resolves the container with `FileManager.url(forUbiquityContainerIdentifier:)` off the main thread. The active cloud library root is the returned container's `Documents` directory; Files presents this document scope as `iCloud Drive/DocScanly`, avoiding a redundant `DocScanly/DocScanly` nesting. A manually created iCloud Drive folder is reachable only through an explicit document-picker import.

Alternatives rejected: CloudKit adds a record model unnecessary for file synchronization; a security-scoped arbitrary folder requires repeated bookmark lifecycle handling and does not guarantee the same app-owned location on a new device; copying into both local and cloud roots creates two authorities.

Android Gradle `applicationId` and `namespace` will both become `com.bruxkey.docscanly`; the Kotlin `MainActivity` package and path follow that namespace, and the manifest/application label becomes DocScanly. This is an application identity change, not merely display copy. It is safe before publication; if an existing Play Store listing already uses `com.bruxkey.doc_forge`, Google Play will treat `com.bruxkey.docscanly` as a different application and rollout must use the existing ID instead or create a new listing.

The Dart package becomes `doc_scanly`; all active `package:doc_forge/` imports, DocForge-named files, classes, application builders, test boot helpers, fixture text, comments, and current documentation become DocScanly equivalents. Generated code is regenerated from renamed sources rather than edited manually. A repository brand check rejects the old names outside an explicit allowlist containing only legacy migration code/tests and `openspec/changes/archive/`. This complete rename prevents the codebase and diagnostics from continuing to expose the retired product identity.

### 2. Persist one authoritative storage location and never silently fork it

`StorageLocation` is `local` or `iCloud`; SharedPreferences stores a versioned key such as `storage.location.v1` and migration phase/checkpoint. Existing installations default to local until the user confirms migration. A fresh installation probes iCloud: if the app-owned container contains a valid `.docscanly-library.json` marker, it selects iCloud automatically; otherwise it remains local and offers iCloud in Settings. Activating iCloud creates the marker even for an empty library, allowing later devices to recognize it.

If the selected iCloud root is temporarily unavailable, the app reports unavailable and retries. It does not switch to local or create a second active tree. Existing locally cached ubiquitous items remain readable subject to Foundation availability.

The marker is a versioned Freezed/json_serializable model containing only schema version and library identifier; it contains no Apple identity, document names, or user data. There is no global mutable root: the composition root constructs an injected `LibraryRootRepository`/provider whose explicit state changes only through migration use cases.

### 3. Extend the storage contract around a resolved root

`PublicFileStore` remains the feature-neutral byte/tree contract. The filesystem implementation will accept an explicit library root (with a compatibility constructor if useful) so local iOS can use `<app Documents>/DocScanly` and cloud iOS can use `<ubiquity container>/Documents`. Android continues through MediaStore at `Documents/DocScanly`.

New `cloud_storage` structure:

```text
lib/features/cloud_storage/
  presentation/
    cubit/storage_location_cubit.dart
    cubit/storage_location_state.dart
    screens/storage_location_screen.dart
    widgets/storage_location_option.dart
    widgets/storage_migration_progress.dart
  application/usecases/
    load_storage_location.dart
    choose_storage_location.dart
    migrate_library_location.dart
    reconcile_cloud_library.dart
    ensure_document_downloaded.dart
    import_existing_cloud_folder.dart
  domain/entities/
    storage_location.dart
    cloud_availability.dart
    cloud_library_marker.dart
  domain/repositories/
    cloud_container_repository.dart
    library_location_repository.dart
  domain/failures/
    cloud_storage_failure.dart
  infrastructure/datasource/
    ios_icloud_channel.dart
    storage_location_preferences.dart
  infrastructure/models/
    cloud_library_marker_dto.dart
  infrastructure/repositories/
    platform_cloud_container_repository.dart
    preferences_library_location_repository.dart
```

Cross-feature contracts needed by the library live in `lib/core/storage/` rather than importing `cloud_storage` from `document_library`. The composition root builds channel → repositories → use cases → Cubit through explicit constructors. No service locator, singleton, static mutable state, or full Bloc is needed.

### 4. Keep business orchestration in use cases and make UI states explicit

`StorageLocationCubit` invokes use cases only. Its immutable Equatable state contains a phase enum/value plus location, availability, inventory, progress, and typed failure. Observable phases are `loading`, `readyLocal`, `readyICloud`, `confirmationRequired`, `migrating`, `verifying`, `completed`, `unavailable`, and `failure`. Transitions are load → ready/unavailable; choose → confirmation; confirm → migrating → verifying → completed → ready; retry → load or resume checkpoint; cancel before copying → previous ready state. Cancellation is disabled after the authority-switch transaction begins.

The dashboard/library state gains reconciliation status and per-entry `CloudContentAvailability` (`local`, `remote`, `downloading`, `available`, `failed`). `EnsureDocumentDownloaded` runs before any byte reader; list enumeration itself does not eagerly download payloads. Cubits never decide migration order, fallback, deletion, conflict naming, or retry policy.

### 5. Migrate with copy–verify–switch–cleanup and restart-safe checkpoints

Brand migration first renames/copies local `DocForge` to `DocScanly` on iOS and Android. Location migration inventories active and reserved Trash payloads, creates destination directories, copies each item, verifies size plus a streamed digest, records its checkpoint, then atomically persists the new authoritative location. Source deletion happens only after every payload and marker verifies. If interrupted, repeated work is idempotent and resumes from verified checkpoints.

Moving back to local uses the same algorithm. Insufficient destination space, iCloud logout, identity change, conflict, or partial copy retains the source authority and exposes retry/cancel. Rollback before the authority switch removes only verified migration-owned destination copies; after switching, rollback is another forward migration, never a blind delete.

### 6. Reconcile cloud files into local Isar without synchronizing the database

On app start, resume (debounced), explicit refresh, and iCloud identity-change notification, reconciliation enumerates relative paths and metadata asynchronously in bounded batches. Existing matching records are updated, new PDFs receive local records, external removals clean local derived metadata without creating app Trash, and the reserved Trash namespace remains excluded from active indexing. Stable platform resource identifiers are stored when available; path plus content metadata/fingerprint provides deterministic fallback.

An undownloaded ubiquitous item remains a valid record. Thumbnail/view/edit/share/print/OCR use cases invoke `EnsureDocumentDownloaded`, observe progress, and then open bytes. Passwords remain device-local; a protected PDF discovered on another device prompts for its password and may store it in that device's secure storage after user consent. Metadata not reconstructable from the files is explicitly not promised to synchronize.

Conflicting same-path payloads are never overwritten silently. The platform's coordinated file access is used, and unresolved conflicts are retained under deterministic conflict names containing device-neutral sequence information; reconciliation surfaces both items for user resolution.

### 7. Native channel is a narrow, deterministic platform edge

A first-party Flutter method/event channel exposes: availability snapshot, container document-root path, marker operations, item metadata, start download, download status, coordinated move/copy, identity-change events, and folder-picker import URLs with scoped access limited to the operation. Swift maps Foundation errors to stable codes; Dart maps them to domain failures. Channel calls perform no UI policy.

The fake platform edge takes scripted immutable fixtures for tests and previews. It does not read the network, wall clock, random values, or ambient Apple account. No new third-party dependency is planned.

### 8. Settings, routes, keys, semantics, and previews are part of the contract

Add typed `StorageLocationRoute` under Settings. `StorageLocationScreen` uses `Key('cloud_storage_screen')`; local/iCloud options use `cloud_storage_local_option` and `cloud_storage_icloud_option`; migration confirmation/progress/retry/cancel/import controls use `cloud_storage_migration_confirm`, `cloud_storage_migration_progress`, `cloud_storage_retry`, `cloud_storage_cancel`, and `cloud_storage_import_folder`. Semantics labels state the action and current status, including “Use iCloud Drive for DocScanly documents” and “Retry iCloud connection”. Dashboard cloud controls/status use `document_cloud_status_<document-id>`, `document_cloud_download_<document-id>`, and `library_cloud_refresh`.

Every new screen/widget receives fixture-driven `@Preview()` coverage for default, loading, unavailable/empty, error, migration/long content, phone/tablet, and light/dark variants. Existing Settings, dashboard, detail, and row previews add remote/downloading/failure examples. All public APIs receive truthful dartdoc; native channel quirks, coordinated access, migration checkpoints, and conflict decisions receive intent comments.

## Risks / Trade-offs

- **[iCloud container or signing misconfiguration]** → Assert entitlements in platform checks, build all configurations, and validate a signed device build using the explicit profile.
- **[Duplicate or lost files during migration]** → Copy, streamed verification, durable checkpoints, single authority switch, and deletion only after complete verification.
- **[New device sees stale/partial content]** → Marker/version validation, bounded reconciliation, explicit sync state, and retry on identity/container notifications.
- **[Large libraries consume memory, battery, or bandwidth]** → Metadata-only incremental scans, debounce, lazy downloads, streamed digests, no polling, and item-scoped UI rebuilds.
- **[Isar-only metadata differs across devices]** → Document the reconstructable subset and defer richer metadata synchronization to a future CloudKit/sidecar design.
- **[Password-protected files cannot open on a new device]** → Never sync secrets; request the password on the new device and keep the PDF visible/recoverable.
- **[Brand rename strands legacy content]** → Run a versioned restart-safe DocForge→DocScanly migration before root selection and retain compatibility detection.
- **[Files app exposes reserved Trash bytes]** → Keep the namespace excluded from DocScanly UI/reconciliation and use unobtrusive reserved naming; accept that an iCloud Documents container is user-visible by design.

## Migration Plan

1. Configure Android `applicationId`/namespace and the explicit Apple App ID as `com.bruxkey.docscanly`, register `iCloud.com.bruxkey.docscanly`, regenerate Apple profiles, and verify Debug/Profile/Release identities on both platforms.
2. Ship user-visible DocScanly branding and versioned local `DocForge`→`DocScanly` migration on Android/iOS.
3. Add the native iCloud seam, entitlements, root selection, marker, and deterministic fakes while local remains authoritative.
4. Add Settings selection and copy–verify migration, then cloud reconciliation/lazy download states.
5. Update privacy disclosure, previews, all test tiers, and platform verification.
6. Roll out with existing users remaining local until confirmation; new devices auto-adopt only a valid app-owned marker.

Rollback disables new iCloud selection but continues to recognize an already-selected cloud authority and offers verified migration back to local. It never makes a cloud library unreachable or deletes it merely because a build lacks availability.

## Open Questions

- Confirm the Apple Developer portal container is registered exactly as `iCloud.com.bruxkey.docscanly` before implementation validation.
- Decide final localized wording for the migration/privacy screens; behavior, keys, and disclosure requirements are fixed by the specs.
