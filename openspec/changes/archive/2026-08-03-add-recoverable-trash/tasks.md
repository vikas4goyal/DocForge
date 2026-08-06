## 1. Domain model and persistence

- [x] 1.1 Add Freezed/json-serializable `TrashEntry`, `TrashInventory`, `TrashId`, document trash fields, retention/collision rules, full dartdoc, and Tier-1 model/serialization/rule tests.
- [x] 1.2 Add the Trash repository contract, Isar entity/repository/mappers and generated schemas; test CRUD, ordering, expiry queries, migration defaults and idempotency.

## 2. Platform storage lifecycle

- [x] 2.1 Extend `PublicFileStore` with reserved-namespace filtering, recursive inventory, move-to-trash, restore, purge and orphan-recovery contracts; update in-memory and filesystem implementations with Tier-1 tests including unknown files and nested empty folders.
- [x] 2.2 Implement equivalent Android MediaStore channel/plugin operations and platform-contract tests for path updates, filtering, conflicts, idempotency and API-level fallbacks.

## 3. Application lifecycle

- [x] 3.1 Implement and unit-test `InspectTrashCandidate`, `MoveDocumentToTrash` and `MoveFolderTreeToTrash`, including rollback/partial-failure safety and preservation of archive/favourite/protection metadata.
- [x] 3.2 Implement and unit-test `LoadTrash`, `RestoreTrashEntry`, deterministic recovered-name conflicts, `PurgeTrashEntry`, `EmptyTrash` and `ExpireTrash`, including pages/OCR/cache/password cleanup and 30-day boundaries.
- [x] 3.3 Retire conflicting legacy delete wiring, update active queries/search/count/reconciliation/storage accounting to exclude reserved/trashed content while retaining Trash bytes, and run affected repository/use-case tests.

## 4. Composition, state and navigation

- [x] 4.1 Wire repositories/use cases through `LibraryModule` and explicit constructors, add the typed `/trash` route and startup/resume expiry invocation, and update router/composition tests.
- [x] 4.2 Add immutable `TrashState` and `TrashCubit`; cover every load/mutate/retry transition and message with `bloc_test`.
- [x] 4.3 Extend `DashboardCubit` coordination for rename/inventory/move-to-trash/undo and Collections counts without adding business logic; update Cubit tests.

## 5. Dashboard and destructive-action UI

- [x] 5.1 Add dashboard Collections rows for Favourites, Archive and Trash plus accessible folder action menus for Rename and Move to Trash; update stable key/semantics registries and Tier-1 widget tests.
- [x] 5.2 Add recursive move confirmation, progress/failure presentation and “Moved to Trash — Undo” behavior for folders/documents; test cancellation, counts, large text, dark mode and touch targets.
- [x] 5.3 Add/update deterministic dashboard and dialog `@Preview()` entries for default/loading/empty/error/long-content, phone/tablet and light/dark states.

## 6. Trash screen

- [x] 6.1 Build `TrashScreen` and reusable Trash rows for loading, empty, error, ready and mutating states with restore, permanent-delete and Empty Trash controls; add all registered keys, semantics and dartdoc.
- [x] 6.2 Add Tier-1 widget tests and Tier-2 component tests wiring the real `TrashCubit` and use cases over fake repository boundaries, including restore conflicts and permanent-delete failures.
- [x] 6.3 Add deterministic Trash screen/widget previews for all required states/themes/form factors and add/update major-screen golden tests.

## 7. Cross-feature regression and end-to-end coverage

- [x] 7.1 Update document list/detail, search, Archive, favourites, folder counts, storage summary and reconciliation tests for Trash exclusion/restoration and retained bytes.
- [x] 7.2 Update the organise robot and `integration_test/flows/organise_test.dart` to create nested content, move it to Trash, verify exclusion, restore, move again, permanently remove, and cover cancellation through keys/semantics only.
- [x] 7.3 Update flow-catalogue/key-registry/layering tests and confirm every new driven element is present and every touched journey remains catalogued exactly once.

## 8. Verification

- [x] 8.1 Run code generation and formatting; run `flutter analyze`, layering/platform checks, all affected Tier-1/Tier-2 tests and goldens, and resolve every failure.
- [x] 8.2 Run the full host test suite and coverage checks, keeping overall coverage at least 80% and Trash business logic at least 90%; resolve regressions.
- [x] 8.3 Run `tool/verify.dart` on an attached device and report every stage and flow result; the change remains incomplete if any stage fails or Tier 3 is skipped.
