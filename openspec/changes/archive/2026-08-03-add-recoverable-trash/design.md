## Context

The active dashboard browses a real public `DocForge` tree by relative path. It supports nested folders but exposes no folder actions. A separate legacy folder route exposes deletion by `FolderId`; that path does not represent nested public paths and can permanently purge documents. The newer `DeleteLibraryFolder` recursively deletes the public directory and index records but is not wired to the dashboard, does not retain recovery metadata, and can erase externally added content that Isar does not describe.

Document Archive is metadata-only: archived PDFs remain at their public paths indefinitely. It cannot also serve as a Trash without confusing “keep but hide” with “delete after 30 days.” iOS and Android expose different platform deletion facilities, so the domain needs one observable lifecycle implemented behind storage abstractions.

The change is Android/iOS-only, offline-first, and must preserve public relative addressing, protected-document credentials, external file reconciliation, explicit constructor injection, and the existing three-tier verification gate.

## Goals / Non-Goals

**Goals:**

- Make document and folder-tree deletion discoverable from the active dashboard.
- Preserve every app-initiated deletion for up to 30 days with restore and explicit permanent removal.
- Inventory complete folder trees recursively before confirmation, including nested folders and non-indexed files visible to DocForge.
- Keep Archive, active library, Trash, public files, Isar metadata, OCR/pages/caches, secure passwords, search, and storage totals consistent.
- Never overwrite an existing path during restore and never silently accept a partial destructive operation.
- Provide deterministic, testable behavior with stable keys, accessible semantics, previews, and all three test tiers.

**Non-Goals:**

- Recovering files deleted outside DocForge in Files or another file manager.
- Cloud synchronization, remote retention, account-level Trash, or cross-device restore.
- An exact background purge at the 30-day instant; cleanup runs best-effort on startup/resume.
- Adding Trash to the bottom tab bar or changing the Dashboard/Create/Settings shell.
- Supporting web or desktop platforms.

## Decisions

### D1. Trash is a separate aggregate lifecycle

Add a Freezed/json-serializable `TrashEntry` domain model with a stable `TrashId`, kind (`document` or `folderTree`), display name, original relative path, hidden payload relative path, UTC `deletedAt`/`expiresAt`, recursive counts, bytes, and affected document identifiers. An Isar `TrashEntryEntity` stores the manifest; no absolute paths are persisted.

The state machine is:

```text
active --move--> trashed --restore--> active
                       |
                       +--purge/expiry--> permanently removed
```

Archive remains orthogonal and is preserved while an item is trashed/restored. This replaces the earlier design assumption that Archive itself was deletion recovery.

Alternative: add only `deletedAt` to every document. Rejected because a folder tree is one user action that can also contain empty directories and non-indexed files; it needs one aggregate manifest and one restore decision.

### D2. Payloads move under one reserved hidden storage namespace

Extend `PublicFileStore` with path-aware recursive inventory and atomic-at-the-adapter move/restore operations. App-initiated Trash payloads live below a reserved internal namespace keyed by `TrashId`; normal `list`, `listRecursive`, reconciliation, and file-browser-facing queries exclude that namespace. iOS uses filesystem rename within the same volume. Android updates owned MediaStore rows' `RELATIVE_PATH` and moves the backing directory; API behavior remains behind `MediaStoreChannel`.

The manifest is written only after the payload move succeeds. Restore/purge operations are idempotent. If a process stops after payload movement but before manifest commit, startup recovery scans the reserved namespace and either completes a pending manifest or safely restores the payload; intent and recovery rules receive inline documentation.

Alternative: copy payloads into Application Support. Rejected because large folder trees would temporarily double storage, make low-space deletion fail, and turn a same-volume move into a long copy/delete transaction.

Alternative: rely on Files Recently Deleted or Android `IS_TRASHED`. Rejected as the sole abstraction because programmatic iOS behavior is not guaranteed, folder/empty-directory semantics differ, and observably identical restore/conflict behavior is required. Android may later use `IS_TRASHED` internally without changing the domain contract.

### D3. Active document records retain identity and gain trash metadata

Add nullable `trashId` and `trashedAt` fields to the Freezed `Document` model and Isar entity. Repository list/query/count/search operations exclude trashed documents by default; direct identifier lookup remains available to restore/purge use cases. Moving a folder tree updates each affected document's current hidden payload path and trash fields in the same orchestration. Restoration rewrites the active path and clears trash fields. Protected-document secure-storage entries remain until permanent purge.

This avoids cloning identifiers, pages, OCR, favourites, archive flags, or passwords. It also leaves future cloud sync a stable identity plus tombstone timestamp.

### D4. Use cases own all lifecycle rules

Add:

- `InspectTrashCandidate`: recursively inventories a document or folder path and returns counts/bytes.
- `MoveDocumentToTrash` and `MoveFolderTreeToTrash`: validate, move payloads, update affected documents/folders, and persist the manifest.
- `LoadTrash`: lazily returns manifests ordered newest first.
- `RestoreTrashEntry`: chooses the original path or deterministic `“<name> (Recovered N)”`, restores bytes, paths and metadata, and deletes the manifest.
- `PurgeTrashEntry`: permanently removes payload bytes, document/page/OCR/cache records, folder records, and secure credentials, then removes the manifest.
- `EmptyTrash`: purges entries sequentially and stops with a typed failure that preserves unprocessed entries.
- `ExpireTrash`: purges entries whose UTC expiry is not after the injected clock; it is idempotent and batched.

Cubits invoke these use cases only. No path arithmetic, retention calculation, recursive counting, or conflict selection lives in presentation.

### D5. One `TrashCubit` owns the Trash screen state

`TrashState` is immutable and Equatable with status `initial | loading | ready | empty | failure | mutating`, entries, optional failure, and optional user message. Transitions:

```text
initial -> loading -> ready | empty | failure
ready -> mutating -> ready | empty | failure
failure -> loading (retry)
```

The dashboard continues using `DashboardCubit`; it receives narrow use cases for inventory/move/rename and reloads after mutations. A Cubit is sufficient because operations are user-serial and need no event transforms.

### D6. Dashboard exposes collections and per-item menus

At the library root, add a Collections section with Favourites, Archive, and Trash rows. Trash uses key `dashboard_trash_collection` and semantics “Open Trash”; Archive/Favourites gain equivalent stable keys. Trash is a typed `/trash` route, not a bottom tab.

Folder rows replace the chevron-only trailing widget with an action menu while retaining row tap-to-open:

- `dashboard_folder_menu_<path-token>` — semantics “Actions for <folder>”
- rename — semantics “Rename folder <folder>”
- move to Trash — semantics “Move folder <folder> to Trash”

Document detail/list actions expose `document_move_to_trash_button` with semantics “Move <title> to Trash.” Successful moves show “Moved to Trash” with an Undo action that calls restore.

For non-empty folders the confirmation names recursive document, subfolder, and other-file counts and says recovery is available for up to 30 days. Empty folders still use Trash for consistent undo semantics. Permanent removal exists only inside Trash and uses visually destructive styling plus “This cannot be undone.”

### D7. Trash screen is a complete, previewable surface

Add typed route `/trash`, screen key `trash_screen`, list `trash_list`, loading/empty/error keys, retry, row, row menu, restore, permanent-delete, empty-trash, and confirmation keys. Semantics name the item and outcome rather than saying only “Delete.”

`TrashScreen` previews cover loading, empty, error, default, long names/counts, near-expiry, light/dark, phone/tablet. `TrashTile` previews cover document/folder, default, long content, and dark. Dashboard previews add root Collections and folder-menu states. Fixtures use fixed UTC timestamps and stable IDs.

### D8. Storage totals include Trash until purge

Moving to Trash does not report freed space. `totalBytes` includes active and hidden payloads and the Trash screen reports recoverable storage. Restore does not change totals. Purge/expiry reduces totals and refreshes dashboard storage.

### D9. Composition and startup cleanup stay explicit

`LibraryModule` constructs Isar repositories, platform storage adapter, use cases, and cleanup from explicit parameters. `AppScreens` receives the module and creates `TrashCubit` at the route. The root lifecycle observer invokes `ExpireTrash` on startup/resume through an injected callback and never accesses repositories directly. No service locator, static mutable state, ambient clock, or randomness is introduced; IDs and clocks remain injected.

Every new public model, repository method, use case, Cubit/state, widget, route builder, and storage method receives dartdoc. Platform namespace filtering, partial-failure recovery, and restore collision selection receive WHY-focused inline comments.

## Risks / Trade-offs

- **Partial payload move or metadata commit** → make adapter operations idempotent, commit the manifest after movement, and reconcile orphan reserved payloads on startup.
- **A folder contains an externally created file** → inventory and move the filesystem/MediaStore subtree, not only Isar document records; report “other files” explicitly.
- **Android cannot enumerate another app's owned MediaStore rows** → promise protection only for content DocForge can inventory; preserve the existing documented platform limitation.
- **Restore path already exists** → never overwrite; select a deterministic recovered suffix and update all descendant paths together.
- **App does not run at expiry** → label retention “up to 30 days” and purge at the next startup/resume; no battery-heavy polling.
- **Trash namespace leaks into active browse/reconciliation** → centralize reserved-path filtering in `PublicFileStore` implementations and add platform/reconciliation regression tests.
- **Legacy folder APIs conflict with path-aware dashboard behavior** → retire their UI wiring and route all new deletion through relative-path use cases; retain compatibility only where tests or migration still need it.
- **Large folder inventories block UI** → perform traversal asynchronously, emit mutating/progress state, and avoid walking payloads while rendering Trash lists.

## Migration Plan

1. Add nullable document trash fields and the Trash Isar collection; old records deserialize as active and require no data rewrite.
2. Add reserved-namespace filtering before any payload can be moved there.
3. Wire use cases and repositories, then dashboard/route UI.
4. On first startup with the schema, scan for orphan reserved payloads from interrupted development builds and restore them rather than deleting them.
5. Existing Archive records remain unchanged. Existing public folders remain active.
6. Rollback before release restores all Trash payloads to conflict-safe active paths, clears trash metadata/manifests, then removes the schema; after release, rollback code must retain schema readability until every supported version can migrate.

## Open Questions

None blocking. The retention duration is fixed at 30 days, restoration conflicts use deterministic recovered suffixes, Trash remains under Dashboard Collections, and external deletions remain outside the recovery guarantee.
