/// Widget previews for PDF editing.
///
/// Every preview is fed by fixtures through a Cubit frozen at a chosen state,
/// so nothing here opens a PDF or reaches the engine (`design.md` §15).
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_forge/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
import 'package:doc_forge/features/pdf_editing/presentation/screens/pdf_edit_screen.dart';
import 'package:doc_forge/features/pdf_editing/presentation/widgets/pdf_edit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A library no preview reaches.
class _PreviewLibrary implements DocumentReader, DocumentWriter {
  const _PreviewLibrary();

  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      const Result<Document>.failure(Failure.notFound());

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => const Result<List<Document>>.success([]);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async => Result<Document>.success(document);

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}

/// A Cubit frozen at [_seeded], with every action inert.
class _PreviewPdfEditCubit extends PdfEditCubit {
  _PreviewPdfEditCubit(this._seeded)
    : super(
        const DocumentId('preview'),
        _useCases(),
        PublicStoreDocumentFileResolver(InMemoryPublicFileStore()),
      );

  static PdfEditUseCases _useCases() {
    final editor = FakePdfEditor();
    const library = _PreviewLibrary();
    final context = PdfEditContext(
      documents: library,
      writer: library,
      editor: editor,
      atomic: AtomicPdfWrite(
        (path, password) => editor.pageCountOf(path, password: password),
      ),
      secrets: InMemorySecureStore(),
      store: InMemoryPublicFileStore(),
      workingDirectory: Directory('/preview/work'),
      clock: FixedClock(DateTime.utc(2026, 3, 14)),
      ids: SequentialIdGenerator(),
    );

    return PdfEditUseCases(
      rotate: RotatePage(context),
      delete: DeletePages(context),
      duplicate: DuplicatePage(context),
      extract: ExtractPages(context),
      merge: MergeDocuments(context),
      split: SplitDocument(context),
      compress: CompressDocument(context),
      watermark: WatermarkDocument(context),
      protect: ProtectDocument(context),
      removePassword: RemoveDocumentPassword(context),
      metadata: ReadPdfMetadata(context),
    );
  }

  final PdfEditState _seeded;

  @override
  PdfEditState get state => _seeded;

  @override
  Future<void> rotate() async {}

  @override
  Future<void> delete() async {}

  @override
  Future<void> duplicate() async {}

  @override
  Future<void> extract() async {}

  @override
  Future<void> compress() async {}

  @override
  Future<void> watermark(String text) async {}

  @override
  Future<void> protect(String password) async {}

  @override
  Future<void> removePassword(String currentPassword) async {}

  @override
  void toggleSelection(int page) {}
}

/// A fixture document.
Document _document({
  String title = 'Invoice 2026',
  int pageCount = 6,
  bool isProtected = false,
}) => Document(
  id: const DocumentId('preview'),
  title: title,
  // Fixed, so every preview and golden built on it is byte-stable.
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 4),
  pageCount: pageCount,
  sizeInBytes: 1_884_160,
  libraryPath: LibraryPath.parse('Invoice 2026.pdf'),
  isProtected: isProtected,
);

PdfMetadata _metadata({int pageCount = 6, bool isProtected = false}) =>
    PdfMetadata(
      title: 'Invoice 2026',
      pageCount: pageCount,
      sizeInBytes: 1_884_160,
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 4),
      isProtected: isProtected,
    );

/// A stand-in for the plugin-backed page thumbnail.
Widget _thumbnail(BuildContext context, int index) => ColoredBox(
  color: index.isEven ? const Color(0xFFE3E3E6) : const Color(0xFFD2D2D8),
);

Widget _screen(
  PdfEditState state, {
  List<Document> mergeCandidates = const [],
}) => BlocProvider<PdfEditCubit>(
  create: (_) => _PreviewPdfEditCubit(state),
  child: PdfEditScreen(
    thumbnailBuilder: _thumbnail,
    onClose: () {},
    mergeCandidates: mergeCandidates,
  ),
);

final _ready = const PdfEditState.initial().copyWith(
  status: PdfEditStatus.ready,
  document: _document(),
  metadata: _metadata(),
);

// ---------------------------------------------------------------------------
// PDF editor screen
// ---------------------------------------------------------------------------

/// The editor with nothing selected.
@Preview(
  name: 'PDF editor — default',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorDefault() => _screen(_ready);

/// The editor while the document loads.
@Preview(
  name: 'PDF editor — loading',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorLoading() => _screen(const PdfEditState.initial());

/// A single-page document, where most operations are unavailable.
@Preview(
  name: 'PDF editor — empty',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorEmpty() => _screen(
  _ready.copyWith(
    document: _document(pageCount: 1),
    metadata: _metadata(pageCount: 1),
  ),
);

/// An operation that failed.
@Preview(
  name: 'PDF editor — error',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorError() => _screen(
  _ready.copyWith(
    status: PdfEditStatus.failure,
    failure: const Failure.corruptFile(),
  ),
);

/// An operation in progress.
@Preview(
  name: 'PDF editor — working',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorWorking() => _screen(
  _ready.copyWith(
    status: PdfEditStatus.working,
    operation: PdfEditOperation.compress,
  ),
);

/// A selection across several pages.
@Preview(
  name: 'PDF editor — selected',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorSelected() => _screen(_ready.copyWith(selection: {0, 2, 4}));

/// A long document with a long title and a compression report.
@Preview(
  name: 'PDF editor — long content',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorLongContent() => _screen(
  _ready.copyWith(
    document: _document(
      title:
          'Quarterly consulting invoice for services rendered to Acme Limited',
      pageCount: 64,
    ),
    metadata: _metadata(pageCount: 64),
    compression: const CompressionOutcomeView(
      message: 'Reduced by 38% — 1.8 MB to 1.1 MB.',
      wasKept: true,
    ),
  ),
);

/// A protected document, which offers removal rather than protection.
@Preview(
  name: 'PDF editor — protected',
  group: 'PDF editing',
  theme: appPreviewTheme,
)
Widget editorProtected() => _screen(
  _ready.copyWith(
    document: _document(isProtected: true),
    metadata: _metadata(isProtected: true),
  ),
);

/// The editor on a phone, light.
@Preview(
  name: 'PDF editor — phone, light',
  group: 'PDF editing',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget editorPhoneLight() => _screen(_ready);

/// The editor on a phone, dark.
@Preview(
  name: 'PDF editor — phone, dark',
  group: 'PDF editing',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget editorPhoneDark() => _screen(_ready);

/// The editor on a tablet, light.
@Preview(
  name: 'PDF editor — tablet, light',
  group: 'PDF editing',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget editorTabletLight() => _screen(_ready);

/// The editor on a tablet, dark.
@Preview(
  name: 'PDF editor — tablet, dark',
  group: 'PDF editing',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget editorTabletDark() => _screen(_ready);

// ---------------------------------------------------------------------------
// Page tile
// ---------------------------------------------------------------------------

/// An unselected page.
@Preview(
  name: 'PdfPageTile — default',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget pageTileDefault() => PdfPageTile(
  index: 0,
  pageCount: 6,
  isSelected: false,
  thumbnailBuilder: _thumbnail,
  onTap: () {},
);

/// A selected page.
@Preview(
  name: 'PdfPageTile — selected',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget pageTileSelected() => PdfPageTile(
  index: 1,
  pageCount: 6,
  isSelected: true,
  thumbnailBuilder: _thumbnail,
  onTap: () {},
);

/// A page with no handler — the disabled state.
@Preview(
  name: 'PdfPageTile — disabled',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget pageTileDisabled() => const PdfPageTile(
  index: 2,
  pageCount: 6,
  isSelected: false,
  thumbnailBuilder: _thumbnail,
);

/// A page number long enough to need the badge to grow.
@Preview(
  name: 'PdfPageTile — long content',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget pageTileLongContent() => PdfPageTile(
  index: 998,
  pageCount: 1024,
  isSelected: true,
  thumbnailBuilder: _thumbnail,
  onTap: () {},
);

// ---------------------------------------------------------------------------
// Watermark preview
// ---------------------------------------------------------------------------

/// A typical watermark.
@Preview(
  name: 'WatermarkPreview — default',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget watermarkDefault() => const WatermarkPreview(text: 'DRAFT');

/// Nothing typed yet — the empty state, which shows a placeholder.
@Preview(
  name: 'WatermarkPreview — empty',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget watermarkEmpty() => const WatermarkPreview(text: '');

/// Text long enough to be truncated.
@Preview(
  name: 'WatermarkPreview — long content',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget watermarkLongContent() => const WatermarkPreview(
  text: 'CONFIDENTIAL — NOT FOR EXTERNAL DISTRIBUTION',
);

// ---------------------------------------------------------------------------
// Metadata view
// ---------------------------------------------------------------------------

/// Metadata for an ordinary document.
@Preview(
  name: 'PdfMetadataView — default',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget metadataDefault() => PdfMetadataView(metadata: _metadata());

/// Metadata for a protected document.
@Preview(
  name: 'PdfMetadataView — protected',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget metadataProtected() =>
    PdfMetadataView(metadata: _metadata(isProtected: true));

/// Metadata whose title has to be truncated.
@Preview(
  name: 'PdfMetadataView — long content',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget metadataLongContent() => PdfMetadataView(
  metadata: PdfMetadata(
    title:
        'Quarterly consulting invoice for services rendered to Acme Limited '
        'during the period ending the thirty-first of March',
    pageCount: 1024,
    sizeInBytes: 1_073_741_824,
    createdAt: DateTime.utc(2026, 3, 14),
    updatedAt: DateTime.utc(2026, 4),
    isProtected: true,
  ),
);

// ---------------------------------------------------------------------------
// Merge order list
// ---------------------------------------------------------------------------

/// Three documents in merge order.
@Preview(
  name: 'MergeOrderList — default',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget mergeOrderDefault() => MergeOrderList(
  titles: const ['Invoice 2026', 'Receipt', 'Statement'],
  onReorder: (_, _) {},
);

/// Nothing to merge — the empty state.
@Preview(
  name: 'MergeOrderList — empty',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget mergeOrderEmpty() =>
    MergeOrderList(titles: const [], onReorder: (_, _) {});

/// Titles long enough to truncate.
@Preview(
  name: 'MergeOrderList — long content',
  group: 'PDF editing',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget mergeOrderLongContent() => MergeOrderList(
  titles: const [
    'Quarterly consulting invoice for services rendered to Acme Limited',
    'Statement of account for the period ending the thirty-first of March',
  ],
  onReorder: (_, _) {},
);
