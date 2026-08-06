## ADDED Requirements

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
