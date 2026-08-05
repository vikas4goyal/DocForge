## Why

Core document workflows currently give weak or misleading feedback: documents cannot be selected in bulk, editor actions can silently create or replace files, and compact phone layouts truncate titles or expose an oversized page-jump field whose purpose is unclear. Imported PDFs expose a deeper consistency defect because they have no stored page rows: the dashboard can render their first-page thumbnail directly from the PDF, while detail previews, image sharing, and OCR report missing content or remain unavailable.

## What Changes

- Add document multi-selection to the Dashboard and open-folder views, entered by long press or an explicit Select action, with Select all, Archive, and confirmed Move to Trash actions plus deterministic partial-failure reporting.
- Redesign Dashboard and open-folder browsing with a clean, Files-inspired adaptive grid: two columns on compact phones and additional columns at wider iPad/tablet breakpoints. Document tiles use a prominent bounded thumbnail followed by a maximum two-line name, modified time, and file size; folder tiles use a restrained folder treatment followed by a maximum two-line name, modified time, and recursive document count. Selection remains visible without changing tile geometry.
- Replace the visually heavy Dashboard search treatment with a rounded, platform-adaptive search field that uses native-feeling spacing, typography, focus, clear, and cancel behavior while retaining DocScanly's own colors and identity rather than reproducing Apple assets pixel-for-pixel.
- Load the real folder hierarchy for the Detail “Move to folder” action, distinguish loading/empty/error states from a genuinely empty library, exclude the current destination where appropriate, and refresh the document location after a successful move.
- Make document Detail and Viewer chrome compact and responsive: use smaller body title typography, preserve meaningful long-title visibility, move secondary viewer actions into an overflow menu when space is constrained, and replace the oversized always-visible “Go to page” field with a compact, clearly labelled page indicator that opens a bounded jump-to-page dialog.
- Replace immediate duplication with a reviewed Duplicate flow showing the source, proposed copy name, and destination folder. The user can edit the name/destination, cancel without creating anything, or confirm once; success opens the new document with an explicit confirmation instead of silently replacing the current Detail screen.
- Redesign PDF editing as explicit workflows. Split chooses a split point and confirms the two output names; merge selects and orders documents; compress explains replacement behavior; watermark and password protection review their inputs. Every operation prevents duplicate submission, shows progress, gives a concrete success result, and navigates to the affected or newly created document where appropriate.
- Make derived operations such as split, merge, and extract navigate to the created document after success instead of leaving an ambiguous editor state where repeated taps create duplicates.
- Give every stored document a uniform page-access contract. For imported PDFs, derive stable virtual page identities from document ID and page number, render thumbnails/images lazily from the authoritative PDF, and clean disposable cached renders without duplicating the source PDF in permanent storage.
- Extract embedded text from text-based PDFs using the existing PDF engine before falling back to on-device OCR for image-only pages. Share Text becomes available from actual stored/extracted content rather than only a stale document flag.
- Fix sharing/export reliability: image sharing renders from either scanned page images or imported PDF pages; export uses platform-appropriate destination semantics and never tries to copy a file onto an iOS provider path that the picker has already written or does not expose as a writable filesystem path; failures identify the failed stage and provide a useful recovery.
- Ensure imported PDFs show page previews consistently in Dashboard, Detail, Viewer, editing, sharing, and OCR without requiring a re-import.
- Add stable keys, semantics, previews, goldens, component coverage, and Android/iOS end-to-end flows for selection, editing outcomes, imported-PDF page access, OCR, share, and export.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `document-library`: Add a Files-inspired adaptive Dashboard/folder grid and rounded search; add multi-selection and bulk archive/trash behavior; make detail titles compact; load real move destinations; add a reviewed duplicate workflow; require imported-document page previews to agree with dashboard thumbnails.
- `document-viewer`: Make long titles and actions responsive and replace the ambiguous persistent page-jump field with a compact, explicit page-navigation flow.
- `pdf-editing`: Require confirmation, progress, duplicate-submission protection, success outcomes, and purposeful navigation for split, merge, compress, watermark, protect, and other derived/in-place operations.
- `document-import`: Require imported PDFs to expose stable page identities and lazily renderable page content without permanently duplicating all page images.
- `ocr`: Support embedded-text extraction and OCR fallback for imported PDFs, with truthful persisted text availability.
- `document-sharing`: Make image/text sharing and device export work for imported PDFs, use platform-correct export behavior, and present actionable stage-specific failures and completion feedback.

## Impact

### Architecture and folder structure

The change remains Android/iOS-only and preserves feature-first clean architecture:

```text
lib/
  core/contracts/                    # document-page access abstractions/value objects
  features/
    document_library/
      presentation/{cubit,screens,widgets}/ # adaptive grid/search, selection, compact detail, move/duplicate flows
      application/usecases/          # bulk outcomes, folder options, duplicate naming/destination, page detail
      domain/                         # bulk-selection/action rules
    document_viewer/
      presentation/{cubit,screens}/  # responsive chrome and page-jump dialog
    pdf_editing/
      presentation/{cubit,screens,widgets}/ # operation forms, confirmation and results
      application/usecases/          # existing operations behind explicit workflows
      domain/                         # operation input/result rules
    document_import/
      application/usecases/          # imported-PDF page capability registration
    ocr/
      application/usecases/          # embedded text first, OCR fallback
      domain/repositories/            # document text/page-source boundaries
      infrastructure/repositories/   # pdfrx text extraction and lazy page rendering
    document_sharing/
      application/usecases/          # page-source-aware image/text/export flows
      domain/repositories/            # platform export contract with clear ownership
      infrastructure/repositories/   # iOS/Android destination implementations
```

- **Cubits and States:** Dashboard and document-list state gain immutable selection sets and bulk-action progress/results. Document Detail gains explicit folder-option and duplicate-review/loading/result state instead of constructor-defaulting to an empty folder list. Viewer state coordinates only the compact page-jump UI. PDF edit state gains an explicit operation-input/review/result phase and submission guard. Share state distinguishes preparation, platform handoff, destination write, cancellation, and failure stages. Every new field is included in `props`.
- **Use cases:** add bulk archive/trash orchestration with per-document outcomes; reuse `LoadFolderOptions` through Detail composition and extend duplication to accept validated title/destination input; add a unified document-page access use case for existing image-backed pages and virtual PDF-backed pages; add embedded PDF text extraction with OCR fallback; adapt share-images/export and editor completion orchestration to return typed outcomes.
- **Repositories and infrastructure:** introduce constructor-injected page rendering/text extraction and platform export boundaries. Reuse the existing `pdfrx`/`pdfrx_engine` capability for page rendering and `loadText`; no new package is expected.
- **Isar and migration:** no destructive document migration is planned. Imported PDF page IDs are stable and derived from document ID plus page number; rendered images remain reclaimable cache artifacts. Existing documents and OCR rows remain readable. If implementation proves a persisted page-source discriminator is necessary, it requires an additive Isar migration with backfill and explicit migration tests before coding proceeds.
- **Navigation:** existing typed routes remain. Derived editor success navigates through typed document-detail/viewer callbacks. No feature introduces route-string navigation.
- **Security:** PDFs and rendered page images remain device-local or in the user-selected iCloud container; transient renders stay in private cache and are cleaned. Extracted text remains in the existing app-private Isar store. Passwords remain in secure storage and never enter Cubit state, logs, previews, or analytics.
- **Performance:** Dashboard and folder grids use lazy slivers with stable tile geometry, breakpoint-derived column counts, and bounded thumbnail requests for visible/near-visible items. Page thumbnails and share/OCR inputs render lazily and in bounded background work; large imports do not eagerly rasterize every page. Bulk actions process deterministically with visible progress and no unbounded widget rebuilds. Cached page renders are bounded/reclaimable and released after use.
- **Extensibility:** the page-access abstraction distinguishes authoritative document identity from local materialization, so future cloud-backed PDFs can download/resolve through the existing file resolver before rendering without changing presentation or business rules.

### Verification and Definition of Done

- Tier 1 covers selection rules, bulk outcomes and partial failures, folder-option loading, duplicate naming/destination/cancellation, virtual page identity, PDF text extraction, OCR fallback, editor confirmation/result state machines, duplicate-tap guards, image sharing, export cancellation/write ownership, and failure mapping.
- Tier 2 component tests wire real Cubits/use cases to repository/platform fakes for the two-column/adaptive Dashboard and folder grid, rounded search behavior, Dashboard/folder selection, compact Detail/Viewer layouts, populated/error/empty move pickers, reviewed duplication, every editing workflow, and imported-PDF sharing/OCR/preview behavior.
- Navigation tests prove derived editor results open exactly one new document and back returns predictably.
- Previews cover the Dashboard/folder grid with empty/loading/error, two-column phone, adaptive iPad/tablet, long two-line names, folder/document metadata, rounded search idle/focused/query/no-results, selection empty/partial/all/working/failure; long detail/viewer titles; page-jump validation; editing input/review/progress/success/failure; imported PDF preview/text/no-text; share/export success and stage failures, on phone/tablet, light/dark, large text, iOS/Android where behavior differs.
- Goldens cover the materially changed Dashboard/folder adaptive grid, rounded search, selection toolbar, Detail, Viewer, editor workflows, and sharing sheet on iPhone/iPad and Android phone/tablet.
- Tier 3 flows cover Dashboard search and two-column/adaptive grid browsing, multi-select archive/trash without tile reflow, moving Detail into a newly created folder, reviewed duplicate naming/destination, one-shot split/merge and in-place operation feedback, imported PDF previews, embedded-text sharing, image sharing, export success/cancellation, and actionable failures exclusively through keys and semantics.
- `dart format`, `flutter analyze`, layering/platform checks, all three test tiers, goldens, and coverage pass through `tool/verify.dart`; overall coverage remains at least 80% and business-logic coverage targets at least 90%.

Primary risks are mixed success during bulk mutation, large-PDF rendering cost, repeated editor submissions, provider-specific iOS export semantics, and stale `hasRecognisedText` metadata. Typed per-item outcomes, bounded lazy rendering, operation tokens, explicit platform ownership, and deriving text availability from the text store mitigate these risks. The change is complete only when the same imported PDF can show page previews, share images, expose embedded or recognised text, and export successfully on attached Android and iOS targets.
