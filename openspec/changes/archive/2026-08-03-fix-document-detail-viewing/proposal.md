## Why

Saved PDFs currently lead to a detail screen that has neither a production-wired viewer action nor usable page previews. Users can see that a document exists but cannot reliably inspect or read it from that screen, even though the viewer and a derived-thumbnail cache already exist.

## What Changes

- Expose an **Open** action on every active document detail screen and navigate it to the existing PDF viewer route.
- Render missing page previews lazily from the retained PDF, cache only thumbnail-sized derived images, and fall back safely when rendering fails.
- Keep protected-document thumbnails behind the same secure password boundary as the viewer.
- Add regression coverage for the route wiring, lazy preview states, cache use, failure fallback, and the saved-document-to-viewer flow.
- Remain Android/iOS only; this change adds no web or desktop support.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `document-library`: Document detail gains locally derived, lazy page previews and a visible action for reading the document.
- `document-viewer`: The document-detail Open action becomes a specified entry point to the existing viewer.

## Impact

### Architecture and folder structure

The change is limited to the existing mobile feature boundaries:

```text
lib/features/document_library/
├── presentation/
│   ├── screens/document_detail_screen.dart
│   └── widgets/page_thumbnail.dart
├── application/                 # thumbnail-loading orchestration, if needed
├── domain/                      # narrow thumbnail source contract, if needed
└── infrastructure/
    └── datasource/derived_thumbnail_cache.dart
lib/app/
├── library_module.dart          # construct/expose the thumbnail source
└── screens/library_screens.dart # inject previews and viewer navigation
```

Presentation continues to receive callbacks rather than importing storage or PDF plugins. Infrastructure resolves the document's public-store file, renders one requested page, and returns a derived cache path. The application/domain additions, if required by implementation, remain narrow contracts with no UI or plugin dependency.

### Components and data

- **Cubits/States:** no new Cubit or persisted state; `DocumentDetailCubit` continues to own metadata/lifecycle loading. Per-tile preview loading is ephemeral widget state so one failed preview cannot fail the detail screen.
- **Use cases/repositories:** existing document queries are unchanged. A narrow preview source may be exposed by `LibraryModule`; it reads through existing document-file and secure-storage contracts and the existing derived cache.
- **Isar schema:** unchanged; cache paths are not authoritative data and are not migrated or persisted.
- **Navigation:** no new route. `document_detail_screen` calls the existing `/documents/:id/view` route through `AppRoutes.documentView`.
- **Dependencies:** no new package. The already-declared `pdfrx` dependency performs bounded PDF page rendering; existing `PublicFileStore`/file resolver and `SecureStore` protect platform path and password handling.
- **Migration:** no Isar migration, preference key, secure-storage key, or route migration. Existing document password keys are read but never copied into cache metadata.

### Performance and security

Previews are created only for lazily built horizontal-list children, at thumbnail width rather than full page resolution. The cache is fingerprinted by size and modification time, so edits invalidate stale pixels without decoding every page. Rendering and file materialisation are released after each request; failures show a placeholder. This bounds memory, rebuild work, battery use, and storage growth for large PDFs. PDF bytes remain in the public library store, passwords remain in secure storage, and the private derived cache contains only page images; no password or absolute path enters Isar/preferences/logs.

### Testing strategy and previews

- Unit: derived rendering/cache hit, invalidation, protected-password forwarding, file release, and failure fallback.
- Widget: loading, success, missing/corrupt preview, semantics, dark/light theme, and Open-action callback.
- Cubit/state: existing detail loading/lifecycle tests remain green; no new state surface is introduced.
- Repository/serialization/Isar: existing suites remain green because schemas and stored models do not change.
- Navigation: detail Open pushes the existing viewer route with the same `DocumentId`.
- Integration: a newly saved PDF opens from dashboard/detail into the viewer and its preview becomes available without crashing.
- Golden: update only if the visible detail baseline exists; otherwise widget assertions cover the additive content.
- `@Preview()`: the existing document-detail preview covers Open plus populated page state; add/adjust variants for preview loading/fallback and retain light/dark phone/tablet coverage where the preview harness supports them.

### Risks and mitigations

- Native PDF rendering may fail for corrupt or protected files: isolate failure to the tile and show a stable placeholder.
- Large documents could trigger eager work: generate only for list children Flutter builds and cache results.
- Public-store materialisation could leak temporary files: always release resolved paths in `finally`.
- Cached sensitive page imagery can outlive a record: keep it in private derived storage and evict it through existing permanent-delete cleanup.

### Future extensibility

The preview source is keyed by document identity and fingerprint rather than a device path. A future cloud-sync implementation can download/materialise the authoritative PDF behind the same resolver and reuse the cache without changing presentation, navigation, Isar records, or exposing cloud credentials.

### Definition of Done

- A newly created or imported PDF detail screen displays a working Open action and lazily derived page previews.
- Viewer navigation, protected documents, corrupt/missing files, cache cleanup, accessibility, phone/tablet layouts, and dark mode behave safely.
- Relevant unit, widget, navigation, integration, architecture, analysis, and formatting checks pass with no Isar/schema migration.
- Delta specs are synced and the completed OpenSpec change is validated and archived.
