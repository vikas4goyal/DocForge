## 1. Apple Identity and DocScanly Branding

- [x] 1.1 Confirm the explicit Apple App ID `com.bruxkey.docscanly` and iCloud Documents container `iCloud.com.bruxkey.docscanly` exist and are assigned, with CloudKit and iCloud Extended Share Access disabled.
- [x] 1.2 Update every Runner build configuration, test bundle identifier, display name, launch surface, document-type copy, entitlements reference, and iCloud container presentation key to the DocScanly identity; regenerate/refresh signing profiles as needed.
- [x] 1.3 Change Android Gradle `applicationId` and `namespace` from `com.bruxkey.doc_forge` to `com.bruxkey.docscanly`, move/update the Kotlin `MainActivity` package path, set the manifest label to DocScanly, and update affected Android build tests.
- [x] 1.4 Rename the pub package from `doc_forge` to `doc_scanly`, update every active package import, and regenerate code; add a source check proving no obsolete package import remains.
- [x] 1.5 Rename active DocForge-named Dart files, classes, builders, integration boot helpers, keys/comments, fixture text, and tests to DocScanly equivalents; update references and run the affected Tier-1 tests.
- [x] 1.6 Update all Android/iOS user-visible copy and current non-archived documentation to DocScanly, retaining old names only in isolated legacy-migration compatibility code/tests and archived OpenSpec history.
- [x] 1.7 Add a repository brand check with the narrow legacy/archive allowlist, and extend platform checks/tests to assert Android/iOS-only support, Android application ID/namespace and iOS bundle ID `com.bruxkey.docscanly`, iCloud container `iCloud.com.bruxkey.docscanly`, required iCloud Documents entitlements, and absence of CloudKit/Extended Share Access.

## 2. Storage Roots, Marker, and Persistence

- [x] 2.1 Add documented domain values and failures for `StorageLocation`, cloud availability/content availability, migration phase, and the versioned library marker; add Tier-1 equality, validation, and failure-message tests.
- [x] 2.2 Add the Freezed/json_serializable marker DTO and mappings with no PII, run code generation, and add serialization/version-rejection tests.
- [x] 2.3 Add versioned SharedPreferences storage-location and migration-checkpoint repositories behind domain interfaces, including upgrade/default behavior; add deterministic repository tests for first install, existing local install, established marker, corruption, and write failure.
- [x] 2.4 Refactor `FilesystemPublicFileStore`/factory composition to accept an explicit root so local iOS uses its DocScanly subfolder and iCloud uses the container Documents scope directly; update filesystem and factory unit tests, including no nested cloud folder.
- [x] 2.5 Change Android MediaStore paths from `Documents/DocForge` to `Documents/DocScanly` with compatibility discovery; update all media-store channel/repository tests for active, nested, and reserved Trash paths.

## 3. Native iCloud Platform Edge

- [x] 3.1 Implement the documented Dart iCloud method/event-channel datasource and stable error-code mapping for availability, container root, marker, item metadata, downloads, coordinated operations, identity events, and scoped folder selection; add channel contract tests.
- [x] 3.2 Implement the Swift Foundation channel off the main thread using the registered ubiquity container, coordinated file access, download/status APIs, and identity-change notifications, with intent comments for platform quirks.
- [x] 3.3 Add deterministic scripted iCloud and folder-picker fakes that contain no wall-clock, randomness, network, global mutable state, or release-reachable fixture path; add repeatability and cleanup tests.
- [x] 3.4 Build `CloudContainerRepository` and `LibraryLocationRepository` implementations over the channel/preferences seams; add repository tests for signed-out, restricted, unavailable, empty marker, established marker, remote item, failed download, identity change, and conflict mappings.

## 4. Brand and Location Migration

- [x] 4.1 Extend the existing library migration to detect and copy–verify–cleanup legacy local `DocForge` active and Trash trees into `DocScanly` on Android and iOS; add restart-safe tests for success, interruption, collision, missing source, and preserved Trash expiry/original path.
- [x] 4.2 Implement inventory, streamed verification, durable checkpoints, authority switch, cleanup, and safe cancellation in `MigrateLibraryLocation`; add Tier-1 tests for local→iCloud, iCloud→local, empty library marker, insufficient space, identity loss, digest mismatch, retry, and rollback boundaries.
- [x] 4.3 Implement `LoadStorageLocation` and `ChooseStorageLocation` so existing users remain local, a valid app-owned marker auto-selects iCloud on a new device, and unavailable iCloud never silently forks to local; add use-case tests for every branch.
- [x] 4.4 Wire root resolution and migration use cases through explicit constructors in the composition root before normal library writes; add composition tests proving one authoritative store and no service locator/global mutable state.

## 5. Cloud Reconciliation and Document Access

- [x] 5.1 Extend public-entry/document contracts with stable cloud identity and content availability only where necessary, including a backward-compatible Isar migration if persisted fields are required; add mapper, Isar migration, and repository tests.
- [x] 5.2 Implement bounded/debounced `ReconcileCloudLibrary` for launch, resume, refresh, and identity events while excluding reserved Trash and preserving remote-only records; add tests for new/renamed/deleted items, folders, several-thousand-entry batching, duplicate triggers, and external deletion semantics.
- [x] 5.3 Implement `EnsureDocumentDownloaded` with observable progress and typed retryable failure; add tests for already-local, remote success, offline, cancellation, corrupt/unreadable payload, and protected PDF without a device password.
- [x] 5.4 Gate thumbnail, viewer, edit, share, print, and OCR byte readers through the injected ensure-download use case; update each affected Tier-1/component test to prove remote-only wait, progress/failure behavior, and unchanged local/Android behavior.
- [x] 5.5 Implement coordinated conflict preservation with deterministic non-overwriting names and reconciliation of both payloads; add repository/use-case tests for simultaneous same-path updates and repeated reconciliation.
- [x] 5.6 Implement explicit existing-folder import using the platform picker and normal import rules, releasing scoped access after completion; add tests proving a same-named external folder is never auto-adopted and unsupported content follows existing failures.

## 6. Storage Location and Library UI

- [x] 6.1 Add the complete `cloud_storage_*` and `document_cloud_*` key/semantics registry, update affected existing keys for DocScanly, and update every robot/flow reference in the same task; add registry presence tests.
- [x] 6.2 Implement `StorageLocationCubit` and immutable Equatable state transitions for loading, local/iCloud ready, confirmation, migrating, verifying, completed, unavailable, failure, retry, and safe cancellation with business logic only in use cases; add exhaustive `bloc_test` sequences.
- [x] 6.3 Add typed `StorageLocationRoute`, Settings entry, storage-location screen, options, confirmation, progress, unavailable/error actions, and import control with responsive accessible Material/Cupertino presentation; add navigation and Tier-1 widget tests.
- [x] 6.4 Add a Tier-2 storage-location component test under `test/features/cloud_storage/component/` using the real Cubit/use cases with repositories substituted, covering selection, migration, interruption/retry, and established-library discovery.
- [x] 6.5 Extend dashboard, document rows/detail, and relevant Cubit states for remote/downloading/available/failed status, refresh, and byte-operation progress without broad rebuilds; add Cubit and Tier-2 library component tests.
- [x] 6.6 Update Settings/About/Privacy and storage-information behavior for local versus iCloud selection and DocScanly wording; update settings Cubit/widget/component tests for truthful offline disclosure and Android absence.

## 7. Previews, Goldens, and End-to-End Journeys

- [x] 7.1 Add fixture-driven `@Preview()` entries for every new storage widget/screen covering default, loading, empty/unavailable, error, migration, long content, phone/tablet, and light/dark states; update Settings/library previews for all cloud availability states.
- [x] 7.2 Add or update golden tests for the storage-location, migration, Settings, dashboard, and document-detail screens across required phone/tablet, light/dark, large-text, loading, unavailable, error, and long-content variants.
- [x] 7.3 Add the cloud-storage integration robot and `integration_test/flows/icloud_library_sync_test.dart`, using the deterministic native edge while retaining production Cubits/use cases/repositories, Isar, and real test files; cover migration, relaunch/new-device discovery, lazy download, refresh, offline/unavailable retry, and Trash preservation.
- [x] 7.4 Update existing first-launch, browse/view, import, capture, search, organise/Trash, edit, share, settings/app-lock, and public-library Tier-3 flows and fixtures for DocScanly branding/folder paths and verify each remains independent and deterministic.

## 8. Documentation and Verification

- [x] 8.1 Add or update dartdoc for every public entity, repository, use case, Cubit/state, route, widget, key, datasource, and composition API; add intent comments for ubiquity lookup, coordinated access, marker choice, migration checkpoints, conflict naming, and no-fallback policy.
- [x] 8.2 Update user/developer documentation with Apple portal prerequisites, signing/profile regeneration, iCloud/local behavior, migration/rollback, privacy limitations, password behavior on a new device, and the fact that Isar-only metadata does not synchronize.
- [x] 8.3 Run code generation and `dart format --set-exit-if-changed .`, then fix every formatting or generated-file discrepancy.
- [x] 8.4 Run `flutter analyze`, layering checks, platform checks, Tier-1 and Tier-2 tests, golden tests, and coverage verification; fix all failures and keep overall coverage at least 80% and business-logic coverage at least 90%.
- [ ] 8.5 Run signed Debug and Release iOS device builds with the explicit App ID/profile and manually smoke-test Files visibility, same-account discovery, download, offline recovery, and migration against the real iCloud container without using production personal documents.
- [ ] 8.6 Run `tool/verify.dart` and report its per-stage result. The change is not done while any stage fails, and a run that reports Tier 3 as SKIPPED (no device attached) does not count as verified.
