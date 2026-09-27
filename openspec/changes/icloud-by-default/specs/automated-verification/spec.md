## MODIFIED Requirements

### Requirement: Deterministic iCloud platform edge
Tier-1, Tier-2, preview, and Tier-3 coverage SHALL substitute iCloud account, container, identity events, metadata enumeration, download progress, conflicts, and folder selection with scripted deterministic fixtures. The production Cubits, use cases, repositories, Isar, and real temporary files SHALL be retained at the tier boundaries required by the verification pyramid.

#### Scenario: New-device fixture is repeatable
- **WHEN** the `icloud_library_sync` flow boots with an established marker and remote file fixture twice
- **THEN** both runs select the same authority, emit the same visible synchronization states, and index the same library without wall-clock, random, network, or ambient Apple-account input

#### Scenario: Migration fixture verifies real files
- **WHEN** the flow boots with a seeded device library and an available scripted container
- **THEN** the production automatic migration, including merge into an established library, and reconciliation operate on real test files while only the native iCloud edge is substituted

#### Scenario: Failure matrix is deterministic
- **WHEN** tests script signed-out, disabled, restricted, unavailable, insufficient-space, interrupted-copy, failed-verification, remote-only, download-failure, identity-change, and same-path-conflict responses
- **THEN** each response maps to a stable domain failure or storage decision and a repeatable Cubit/UI state with no hidden global state

#### Scenario: Branding and Apple configuration are checked
- **WHEN** the platform verification stage runs
- **THEN** it asserts the DocScanly display name, Android application ID/namespace and iOS bundle identifier `com.bruxkey.docscanly`, iCloud container `iCloud.com.bruxkey.docscanly`, required iCloud Documents entitlements, absence of CloudKit/Extended Share Access, and Android/iOS-only platform set

### Requirement: iCloud end-to-end journey
The Tier-3 catalogue SHALL include `integration_test/flows/icloud_library_sync_test.dart` and a cloud-storage robot that drive the full application exclusively through registered keys and semantics.

#### Scenario: Flow covers storage lifecycle
- **WHEN** the iCloud journey runs
- **THEN** it covers automatic first-launch iCloud selection, the automatic migration gate with progress and completion, gate failure with retry and continue-on-device, signed-out device fallback and its disclosed reason, move-now, relaunch, new-device discovery, merge with conflict naming, the use-device escape and its confirmation, lazy download, refresh, offline/unavailable recovery, and preservation of Trash, using `cloud_storage_*`, `library_cloud_refresh`, and `document_cloud_*` elements

#### Scenario: Existing journeys remain valid
- **WHEN** the verification gate runs after implementation
- **THEN** browse/view, import, capture, search, organise/Trash, edit, share, settings/app-lock, Android storage, golden, coverage, layering, and platform stages also pass under DocScanly branding, including the iOS first-launch journey with an available scripted iCloud container
