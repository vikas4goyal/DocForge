## Why

Folder actions are not available from the active dashboard, and the existing deletion paths can recursively erase indexed documents, nested folders, and externally added files without a reliable recovery window. DocForge needs one cross-platform, explicit Trash lifecycle so deletion is discoverable, recoverable for up to 30 days, and irreversible only after a second permanent-removal decision.

## What Changes

- Add an app-managed Trash lifecycle for individual documents and complete folder subtrees, including original location, deletion time, recursive content counts, restore, permanent removal, empty-trash, and best-effort automatic expiry after 30 days.
- Replace direct dashboard deletion with “Move to Trash”; non-empty folders show a recursive preflight that counts documents, subfolders, and other files, while every successful move offers Undo.
- Preserve Archive as an indefinite organisation state distinct from Trash: archived files stay in their public folder, while trashed items disappear from active browse, search, recents, favourites, and archive views.
- Add a root-dashboard Collections section for Favourites, Archive, and Trash rather than making Trash a primary bottom-tab destination.
- Add discoverable folder action menus to dashboard rows and document trash actions to the document lifecycle UI.
- Add a Trash screen with restore, permanent removal, empty-trash, loading/empty/error states, item age/expiry messaging, accessible semantics, dark mode, phone/tablet layouts, and deterministic previews.
- Define conflict-safe restoration: restore to the original path when free and use a deterministic “(Recovered)” name when that path is occupied, without overwriting existing user data.
- Keep storage accounting truthful by including recoverable Trash bytes until permanent removal.
- Reconcile external deletions independently from app-initiated Trash; DocForge only promises recovery for deletions initiated inside DocForge.
- Update all affected unit, Cubit, repository, serialization, component, navigation, golden, and end-to-end organise-flow tests.

## Capabilities

### New Capabilities

- `recoverable-trash`: Defines Trash entries, recursive folder deletion, 30-day retention, restoration, conflict handling, permanent removal, cleanup, and Trash presentation.

### Modified Capabilities

- `document-library`: Changes document and folder deletion from immediate removal/archive-as-recovery to an explicit Trash lifecycle and adds dashboard folder actions.
- `app-shell`: Adds dashboard Collections navigation to Favourites, Archive, and Trash while retaining the existing Dashboard/Create/Settings shell.
- `public-document-storage`: Adds protected Trash storage, recursive inventory requirements, restoration, permanent removal, and reconciliation boundaries for external deletion.

## Impact

### Architecture and code

- `lib/features/document_library/domain/`: add immutable Trash models/value semantics and repository contracts; keep retention and conflict rules platform-independent.
- `lib/features/document_library/application/usecases/`: add inventory, move-to-trash, load, restore, purge, empty, and expiry-cleanup use cases; replace competing legacy folder-delete paths with one path-aware implementation.
- `lib/features/document_library/infrastructure/`: add Isar Trash persistence/mapping and platform-backed storage operations; retain public relative paths and private metadata separately.
- `lib/features/document_library/presentation/`: add `TrashCubit`/immutable `TrashState`, Trash screen/widgets/dialogs/previews, dashboard Collections, and folder/document action menus.
- `lib/core/storage/public_storage/`: extend the storage contract and iOS filesystem/Android MediaStore adapters for trash, restore, recursive inventory, and permanent removal.
- `lib/app/` and router: inject Trash use cases, add a typed `/trash` route, wire dashboard collection navigation, and invoke expiry cleanup on startup/resume.

Resulting feature structure:

```text
document_library/
├── domain/
│   ├── entities/             trash entry and inventory semantics
│   └── repositories/         trash persistence contract
├── application/usecases/     move, list, restore, purge, empty, expire
├── infrastructure/
│   ├── models/               Isar trash entity and generated mapping
│   └── repositories/         Isar trash repository
└── presentation/
    ├── cubit/                TrashCubit and TrashState
    ├── screens/              TrashScreen
    └── widgets/              trash rows, folder menus, confirmations
```

No new third-party dependency is planned. The change uses Isar, the existing public-storage abstraction, `flutter_bloc`, Freezed/json serialization conventions, and GoRouter already in the project. Android and iOS are the only supported platforms; no web or desktop code is introduced.

### Migration, security, and storage

- Add an Isar schema for trash manifests and bump generated schemas without rewriting active document identifiers.
- Existing archived documents remain archived; no automatic migration treats them as deleted.
- No SharedPreferences or secure-storage key migration is required. Passwords for protected trashed documents remain in secure storage until permanent removal and continue to protect restored documents.
- Trash payloads remain local and inaccessible through normal active-library navigation. Metadata stores original relative paths, stable identifiers, deletion/expiry timestamps, and aggregate counts; it stores no absolute device paths.
- Permanent removal deletes PDF bytes, derived caches, pages/OCR metadata, folder manifests, and password material consistently.

### Performance and future sync

- Recursive inventory and subtree moves run once per destructive operation and expose progress without rebuilding the whole dashboard.
- Trash lists are lazy and use metadata summaries instead of recursively walking payloads during every render.
- Expiry cleanup is best-effort on startup/resume, batched, idempotent, and avoids blocking the first frame; “up to 30 days” is used because iOS cannot guarantee an exact background execution time.
- Stable Trash identifiers, tombstone timestamps, original paths, and explicit restore/purge transitions leave room for future cloud-sync tombstones and conflict resolution without changing UI semantics.

### Testing and previews

- Unit: retention boundaries, recursive counts, original paths, restore collisions, idempotency, partial-failure safety, external-file handling, storage accounting, serialization, mappings, and repository behavior.
- Cubit: loading/ready/empty/failure, move/restore/purge/empty progress and messages.
- Component/widget: real Cubit/use-case Trash screen, dashboard menus/Collections, confirmations, Undo, semantics, large text, dark mode, phone/tablet, and route navigation.
- Golden/previews: Trash loading, empty, error, default, long-content, expiring, dark, and tablet states; updated dashboard states.
- Integration: organise flow creates nested content, moves it to Trash, verifies active exclusion, restores it, moves it again, permanently removes it, and validates cancellation paths exclusively through robots and stable keys.
- Verification: formatting, analysis, layering/platform checks, complete Tier 1/2 suites, goldens, coverage, and Tier 3 on an attached device through `tool/verify.dart`.

### Risks and mitigations

- Partial subtree moves could split user data: storage operations are idempotent, manifests are committed only after payload movement succeeds, and failures preserve a recoverable source or trash payload.
- Public files added outside DocForge could be missed: preflight uses recursive public-store inventory rather than only Isar documents.
- Restore destinations may collide: restoration never overwrites and chooses a deterministic recovered name.
- Android/iOS trash mechanisms differ: platform adapters implement the same domain contract and tests enforce identical observable behavior.
- External file-manager deletion may bypass DocForge Trash: UI wording limits the recovery promise to actions performed in DocForge, and reconciliation continues to clean externally missing records.

### Definition of Done

- Documents and complete folder trees can be moved to Trash, undone/restored, permanently removed, and automatically expired without silent data loss.
- Dashboard, Trash, Archive, search, storage summary, and Files/MediaStore contents remain mutually consistent across restart and resume.
- All new screens/widgets have required previews and stable keys/semantics.
- Every relevant test tier is updated and passes, overall coverage remains at least 80%, business rules remain at least 90%, and `tool/verify.dart` completes (or reports only the documented device-dependent Tier 3 skip when no device is attached).
