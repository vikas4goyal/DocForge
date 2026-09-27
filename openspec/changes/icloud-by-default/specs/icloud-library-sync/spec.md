## ADDED Requirements

### Requirement: Automatic iCloud authority and migration
On iOS, the application SHALL make the app-owned iCloud library the single authoritative library whenever the registered container is available, without any user opt-in. The application SHALL move an existing device library to iCloud automatically at cold launch, before any document can be created, edited, or deleted. It SHALL use copy–verify–switch–cleanup migration and SHALL resume an interrupted migration without duplication or data loss.

#### Scenario: New install with iCloud available
- **WHEN** DocScanly starts for the first time with no stored location, no device documents, and an available container
- **THEN** it selects iCloud without showing a chooser or migration screen, writes a valid versioned library marker, and saves new documents to `iCloud Drive → DocScanly`

#### Scenario: Existing device library is moved automatically
- **WHEN** DocScanly cold-launches with device authority, the container is available, and the device library contains active or reserved Trash payloads
- **THEN** it shows the migration gate `cloud_storage_migration_gate`, with semantics label “Moving DocScanly documents to iCloud”, before the library, and shows `cloud_storage_migration_progress`, announcing “Library migration <n> percent”, as payloads are copied and verified
- **AND** the library, capture, import, and editing interfaces are not reachable until the gate completes or the user continues on this device

#### Scenario: Previously chosen device storage is also moved
- **WHEN** a user who explicitly selected “On this device” in an earlier version cold-launches with the container available
- **THEN** the library is moved to iCloud exactly as for any other device library

#### Scenario: Automatic migration succeeds
- **WHEN** every active and reserved Trash payload is copied and verified
- **THEN** iCloud becomes the single authoritative root and source cleanup begins only afterwards
- **AND** the gate shows `cloud_storage_migration_done` announcing “Your DocScanly documents are now in iCloud Drive”, with `cloud_storage_migration_continue` (“Continue to DocScanly”) opening the library from the iCloud root

#### Scenario: Automatic migration is interrupted
- **WHEN** the process stops during copying, verifying, switching, or cleaning
- **THEN** the next cold launch runs the gate again, resumes verified checkpoints without duplicating documents, and never leaves two authoritative libraries

#### Scenario: Automatic migration fails
- **WHEN** iCloud becomes unavailable, storage is insufficient, or verification fails during the gate
- **THEN** the device root remains authoritative, the gate shows the reason with `cloud_storage_retry` (“Retry iCloud migration”) and `cloud_storage_continue_local` (“Continue on this device for now”), and continuing opens the device library for this session only
- **AND** the next cold launch attempts the migration again

#### Scenario: Empty device library needs no gate
- **WHEN** the device authority has no active or reserved Trash payloads and the container becomes available
- **THEN** DocScanly switches to iCloud at cold launch without showing the gate

### Requirement: Device fallback while iCloud is unavailable
On iOS, when the app-owned container is unavailable and no iCloud library is authoritative, the application SHALL keep a fully functional device library, SHALL explain why iCloud is not in use, and SHALL move the library to iCloud once iCloud becomes available.

#### Scenario: User is not signed in to iCloud
- **WHEN** DocScanly starts with no Apple Account signed in, iCloud Drive turned off, DocScanly turned off in iOS iCloud settings, or iCloud restricted
- **THEN** documents are saved to `<app Documents>/DocScanly`, every library operation works offline, and no iCloud gate, error, or blocking prompt is shown

#### Scenario: Fallback reason is disclosed
- **WHEN** the user opens `cloud_storage_screen` during device fallback
- **THEN** `cloud_storage_status` announces “DocScanly documents are stored on this device” together with the reason: “Sign in to iCloud in iOS Settings”, “Turn on iCloud Drive for DocScanly in iOS Settings”, “iCloud is restricted on this device”, or “iCloud is temporarily unavailable”

#### Scenario: iCloud becomes available later
- **WHEN** the user signs in or enables iCloud Drive for DocScanly while the device library is authoritative
- **THEN** the next cold launch moves the library to iCloud through the migration gate

#### Scenario: User moves immediately
- **WHEN** the container is available, device authority is active, and the user activates `cloud_storage_move_now` with semantics label “Move documents to iCloud now”
- **THEN** DocScanly re-runs its startup composition through the migration gate without requiring an app restart

#### Scenario: Move now is disabled while iCloud is unavailable
- **WHEN** the container is unavailable
- **THEN** `cloud_storage_move_now` is absent or disabled, and its disabled state is announced with the fallback reason

### Requirement: Explicit device library when the iCloud library is unavailable
The application SHALL NOT silently replace an authoritative iCloud library that is unavailable. It SHALL offer an explicit, confirmed action to continue with a device library, SHALL leave the iCloud content untouched, and SHALL merge the device library back when iCloud returns.

#### Scenario: Selected iCloud library is unavailable at launch
- **WHEN** iCloud is authoritative and the container cannot be reached at launch
- **THEN** `cloud_storage_unavailable` (“DocScanly iCloud library unavailable”) is shown with `cloud_storage_retry` (“Retry iCloud connection”) and `cloud_storage_use_device` (“Use this device without iCloud”)

#### Scenario: User confirms device library
- **WHEN** the user activates `cloud_storage_use_device` and then `cloud_storage_use_device_confirm` (“Confirm using this device without iCloud”), after being told that iCloud documents stay in iCloud and will not be visible until iCloud returns
- **THEN** the device library becomes authoritative, the app opens on it, and no iCloud payload or marker is deleted or modified

#### Scenario: User dismisses the confirmation
- **WHEN** the user dismisses the confirmation
- **THEN** authority is unchanged and the unavailable state remains

### Requirement: Merge into an established iCloud library
When moving a device library into a container that already holds a DocScanly library, the application SHALL merge the two without overwriting or losing any payload.

#### Scenario: Identical payload already present
- **WHEN** a device payload's relative path already exists in iCloud with identical bytes
- **THEN** it is treated as verified and not duplicated

#### Scenario: Different payload at the same path
- **WHEN** a device payload's relative path already exists in iCloud with different bytes
- **THEN** the device payload is copied to `<name> (Conflict device).pdf`, or `<name> (Conflict device N).pdf` when that name is taken, in the same folder, and both payloads remain listed after reconciliation

#### Scenario: Merge keeps the established marker
- **WHEN** the container already has a valid marker
- **THEN** the merge keeps that marker and the library discovered on other devices remains the same library

## MODIFIED Requirements

### Requirement: App-owned iCloud library
On iOS, the application SHALL access only the iCloud Documents container `iCloud.com.bruxkey.docscanly` for its automatic cloud library, SHALL present that container in Files as `DocScanly`, and SHALL NOT require CloudKit or iCloud Extended Share Access.

#### Scenario: iCloud library is created
- **WHEN** the container is available and no marker exists when iCloud first becomes authoritative, whether on a new install or at the end of an automatic migration
- **THEN** the application creates its document scope and a valid versioned library marker, and Files presents it under `iCloud Drive → DocScanly`

#### Scenario: No redundant nested folder
- **WHEN** the app-owned container is opened in Files
- **THEN** the library contents appear directly within `DocScanly` rather than within `DocScanly/DocScanly`

#### Scenario: App-owned access requires no picker
- **WHEN** DocScanly reads or changes content in its registered iCloud container
- **THEN** no folder-picker or broad iCloud Drive permission prompt is shown

### Requirement: Automatic same-account discovery
The application SHALL recognize and select an established app-owned iCloud library on an iOS device signed into the same Apple Account and SHALL rebuild its local Isar index from the container without requiring the user to select the folder again.

#### Scenario: New device discovers existing library
- **WHEN** DocScanly starts with no device documents and finds a valid marker in its registered container
- **THEN** it selects iCloud without a migration gate, displays reconciliation status, and indexes the existing folders and PDFs

#### Scenario: Device with its own documents discovers existing library
- **WHEN** DocScanly starts with device documents and finds a valid marker in its registered container
- **THEN** it merges the device library into the established library through the migration gate and never creates a second iCloud library

#### Scenario: Empty established library is discovered
- **WHEN** the registered container has a valid marker but no active documents
- **THEN** DocScanly selects that iCloud library and displays its empty state rather than creating a separate local authority

#### Scenario: Different Apple Account
- **WHEN** the current iCloud identity cannot access the previously selected container
- **THEN** DocScanly displays an unavailable state with key `cloud_storage_unavailable` and semantics label “DocScanly iCloud library unavailable”, without switching roots or deleting local metadata unless the user confirms `cloud_storage_use_device_confirm`

### Requirement: Cloud storage presentation
The storage-location, migration-gate, and cloud-status interfaces SHALL support screen readers, large text, light and dark themes, phone and tablet layouts, deterministic previews, and useful offline behavior.

#### Scenario: Storage location screen is a status screen
- **WHEN** the user opens `cloud_storage_screen`
- **THEN** it shows `cloud_storage_status` describing the current authority (“DocScanly documents are stored in iCloud Drive” or the device fallback wording with its reason), offers `cloud_storage_move_now` only during device fallback, keeps `cloud_storage_import_folder`, and offers no control that moves an available iCloud library back to the device

#### Scenario: Storage location screen is accessible
- **WHEN** `cloud_storage_screen` or `cloud_storage_migration_gate` is traversed with a screen reader
- **THEN** the current authority, availability, and progress are announced, and every retry, continue, move-now, use-device, confirmation, import, and refresh control has the specified semantics label

#### Scenario: Responsive cloud states
- **WHEN** the storage screen or migration gate displays loading, fallback, unavailable, error, migration, or long-content states on a phone or tablet in light or dark mode at a supported large text scale
- **THEN** content remains readable, scrollable, and free from clipping or overflow

#### Scenario: Offline with downloaded content
- **WHEN** iCloud has no network connectivity and a selected PDF is already downloaded
- **THEN** local reading and editing continue and pending synchronization is communicated without blocking the operation

#### Scenario: Offline with remote-only content
- **WHEN** iCloud has no network connectivity and a selected PDF is remote-only
- **THEN** the application explains that download is required and offers retry without reporting the PDF as lost

#### Scenario: End-to-end cloud coverage
- **WHEN** the `icloud_library_sync` end-to-end flow runs against its deterministic platform fixture
- **THEN** it drives automatic first-launch selection, the automatic migration gate and its failure recovery, signed-out device fallback, move-now, relaunch/new-device discovery, merge with conflict preservation, the use-device escape, remote download, unavailable recovery, and library refresh exclusively through the specified keys and semantics

## REMOVED Requirements

### Requirement: Explicit storage selection and safe migration
**Reason**: iCloud is now the automatic authority whenever it is available, so users no longer choose a location or confirm a migration. The restart-safe copy–verify–switch–cleanup guarantees move to “Automatic iCloud authority and migration”.
**Migration**: `cloud_storage_local_option`, `cloud_storage_icloud_option`, and `cloud_storage_migration_confirm` are removed. Flows and robots use `cloud_storage_migration_gate`, `cloud_storage_move_now`, `cloud_storage_continue_local`, and `cloud_storage_status` instead. `cloud_storage_retry`, `cloud_storage_migration_progress`, and `cloud_storage_unavailable` keep their keys. `cloud_storage_cancel` is replaced by `cloud_storage_continue_local`, which cancels safely before the switch.
