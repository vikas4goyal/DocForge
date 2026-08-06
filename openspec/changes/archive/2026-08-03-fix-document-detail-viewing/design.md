## Context

The detail screen already contains an optional Open button, the router already owns `/documents/:id/view`, and `DerivedThumbnailCache` already fingerprints and stores rendered thumbnails. Production composition never supplies the Open callback, and `PageThumbnail` only checks the nullable persisted `thumbnailPath`. Created PDFs deliberately discard scan intermediates after saving, so that path is normally null and the retained PDF must be the preview source.

The solution crosses presentation, application, infrastructure, and composition, while preserving the rule that the authoritative PDF is addressed by `Document.libraryPath` and that presentation never imports `pdfrx`, secure storage, or public-storage plugins.

## Goals / Non-Goals

**Goals:**

- Make the existing viewer reachable from every active document detail screen.
- Derive page previews lazily and safely from the retained local PDF.
- Keep rendering memory bounded and cache output private, fingerprinted, and evictable.
- Reuse stored PDF passwords without exposing them to widgets or persistent metadata.
- Preserve callback-based, previewable presentation and constructor-injected dependencies.

**Non-Goals:**

- No new viewer, editor, PDF format, page model, Isar collection, cloud service, or route.
- No eager rendering of all pages, full-resolution page retention, manual refresh control, or network fallback.
- No web or desktop implementation.

## Decisions

### D1. A `LoadDocumentPageThumbnail` use case owns preview orchestration

The application use case receives a domain thumbnail-cache port, `DocumentFileResolver`, and `SecureStore`. For one document/page it reads the existing password key when protected, materialises the public PDF, requests a cache entry, and releases the materialised path in `finally`. `LibraryModule` exposes the use case and `buildLibraryScreens` passes a narrow callback into presentation.

Dependency direction is `presentation → application → domain/core contracts ← infrastructure`; document-library does not import document-viewer. The composition root constructs every dependency explicitly, with no locator, singleton, static mutable cache, or ambient path lookup.

Alternative: put path/password orchestration in the widget. Rejected because it couples presentation to storage and secrets. Alternative: populate `thumbnailPath` while saving. Rejected because scan intermediates are not the authoritative PDF, imported PDFs would still have no previews, and persistent cache paths become stale.

### D2. `PdfrxThumbnailRenderer` is an infrastructure adapter behind the cache port

The adapter opens a resolved file with `PdfDocument.openFile`, renders exactly one valid page at the cache width while preserving aspect ratio, encodes it as PNG bytes, disposes native/UI image resources, and closes the document in `finally`. It maps parse, password, range, and I/O exceptions to `Failure` rather than throwing into layout.

`DerivedThumbnailCache` remains responsible for fingerprinted disk hits/writes. No new dependency is added: `pdfrx` is already the mobile viewer engine. The renderer function is injectable so unit tests use deterministic bytes and never invoke a native plugin.

Alternative: embed a `PdfPageView` per tile. Rejected because it repeatedly opens documents during rebuilds, bypasses the existing fingerprinted cache, and makes resource release less explicit.

### D3. Each `PageThumbnail` has local immutable-request state

`PageThumbnail` becomes stateful only to memoise one `Future<Result<String>>` for its current page/loader. Transitions are `not requested → loading → image` or `not requested → loading → placeholder`; a changed page identity/loader creates a new request. This is ephemeral rendering state, not business state, so a Cubit/Bloc and Freezed state would add coordination and make one tile capable of failing the whole detail screen. There is no global mutable state or nondeterministic timer.

An existing `thumbnailPath` is tried immediately; a missing path invokes the loader. A progress indicator is non-interactive and the final image retains semantics `Page <n> thumbnail`. Unreadable output uses the existing placeholder and the screen remains usable.

`DocumentDetailCubit` and immutable `DocumentDetailState` remain unchanged: `initial → loading → ready/failure`, with existing working/action transitions. All lifecycle business logic remains in existing use cases; no full Bloc is introduced.

### D4. Production composition supplies both callbacks

`buildLibraryScreens` passes `onOpenViewer: () => context.push(AppRoutes.documentView(id))` and a page loader backed by `library.loadDocumentPageThumbnail`. This uses the existing GoRouter route builder rather than constructing a string or adding a route. Back returns to detail because viewer remains a child route.

The important existing control remains `Key('document_open_button')`, with visible/semantic label “Open”. Each preview retains `Key('page_thumbnail_<page-id>')` and `Page <n> thumbnail`; a deterministic loading key may be added for tests. No new screen key is needed.

### D5. Persistence, models, previews, and documentation

- Isar: `Document`, `DocumentPage`, and schemas are unchanged; derived paths are not saved.
- SharedPreferences: no value is added.
- Secure storage: only `SecureStorageKeys.pdfPassword(document.id.value)` is read; no new key or secret copy.
- File storage: authoritative PDF remains public; derived PNGs remain under private application-support storage, fingerprinted by size/modified time and removed by permanent-delete cleanup.
- Freezed/json_serializable: no new serializable model or contract is required, so no generated model is added.
- `@Preview()`: retain the populated detail preview with Open, and add fixtures/variants for derived-preview loading/fallback where deterministic async previewing is supported; existing preview harness supplies light/dark phone/tablet variants.
- Public constructors, callback typedefs, port methods, use case, and renderer receive dartdoc. Inline comments explain `finally` release/disposal and why preview failure is local.

## Risks / Trade-offs

- [A corrupt/locked PDF cannot produce a thumbnail] → return `Failure`, show the placeholder, and leave Open available for the viewer's richer recovery/password flow.
- [Horizontal list prefetch renders more than the single visible tile] → Flutter still builds a bounded viewport neighborhood; each render is thumbnail-sized and cached.
- [Concurrent requests can render the same cold entry twice] → acceptable bounded duplicate work for now; atomic in-flight de-duplication can be added behind the cache port later.
- [PNG files use more bytes than JPEG for photographic scans] → PNG encoding is directly supported without another dependency and output width is bounded; fingerprint eviction and OS-private storage limit impact.
- [A materialised Android file remains after failure] → use `finally` and treat release failure as non-fatal because the OS reclaims cache storage.

## Migration Plan

Ship as an additive mobile update. Existing documents require no data migration: their first detail visit creates derived previews from the current PDF. Rollback removes the wiring/use case/adapter; old records remain readable and private derived files are harmless reclaimable cache. Permanent deletion continues to remove the document's derived directory.

## Open Questions

None. Cloud sync can later implement/materialise behind `DocumentFileResolver`; because the cache key uses document identity/fingerprint and widgets receive only a loader, no presentation or persistence contract must change.
