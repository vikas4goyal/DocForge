/// Widget previews for sharing, printing and export.
///
/// Every preview is fed by fixtures through a Cubit frozen at a chosen state,
/// so nothing here opens a share sheet, a print dialogue or a file picker
/// (`design.md` §15).
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_scanly/features/document_sharing/domain/share_content.dart';
import 'package:doc_scanly/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:doc_scanly/features/document_sharing/presentation/screens/share_options_sheet.dart';
import 'package:doc_scanly/features/document_sharing/presentation/widgets/share_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A document reader that finds nothing, because no preview asks it to.
class _PreviewReader implements DocumentReader {
  const _PreviewReader();

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
}

/// A text source with nothing in it.
class _PreviewText implements OcrTextSource {
  const _PreviewText();

  @override
  Future<Result<RecognisedText?>> textForPage(PageId pageId) async =>
      const Result<RecognisedText?>.success(null);

  @override
  Future<Result<String>> textForDocument(DocumentId documentId) async =>
      const Result<String>.success('');
}

/// Resolves preview documents to a fixed, machine-independent path.
final _files = PublicStoreDocumentFileResolver(InMemoryPublicFileStore());

/// A Cubit frozen at [_seeded].
///
/// Every action is overridden to do nothing: a preview that opened the system
/// share sheet would do so while the developer was looking at a widget.
class _PreviewShareCubit extends ShareCubit {
  _PreviewShareCubit(this._seeded)
    : super(
        const DocumentId('preview'),
        ShareDocumentPdf(const _PreviewReader(), FakeShareRepository(), _files),
        SharePageImages(
          const _PreviewReader(),
          FakeShareRepository(),
          const InlineBackgroundWorker(),
          Directory.systemTemp.createTempSync,
          _neverRendered,
        ),
        ShareExtractedText(
          const _PreviewReader(),
          const _PreviewText(),
          FakeShareRepository(),
        ),
        PrintDocument(const _PreviewReader(), FakePrintRepository(), _files),
        ExportDocument(
          const _PreviewReader(),
          FakeExportDestinationPicker(),
          _files,
        ),
      );

  final ShareState _seeded;

  @override
  ShareState get state => _seeded;

  @override
  Future<void> sharePdf() async {}

  @override
  Future<void> shareImages({List<PageId> pageIds = const []}) async {}

  @override
  Future<void> shareText() async {}

  @override
  Future<void> printDocument() async {}

  @override
  Future<void> export({String? initialDirectory}) async {}

  @override
  void cancel() {}

  @override
  void dismissError() {}
}

String _neverRendered(SharePageRequest request) =>
    throw StateError('a preview never renders a page');

Widget _sheet(ShareState state) => BlocProvider<ShareCubit>(
  create: (_) => _PreviewShareCubit(state),
  child: const ShareOptionsSheet(),
);

const _ready = ShareState.initial(
  title: 'Invoice 2026',
  pageCount: 4,
  canShareText: true,
);

// ---------------------------------------------------------------------------
// Share options sheet
// ---------------------------------------------------------------------------

/// Every option available.
@Preview(name: 'Share — default', group: 'Sharing', theme: appPreviewTheme)
Widget shareDefault() => _sheet(_ready);

/// Content being prepared, the loading state of this sheet.
@Preview(name: 'Share — loading', group: 'Sharing', theme: appPreviewTheme)
Widget shareLoading() => _sheet(
  _ready.copyWith(
    status: ShareStatus.preparing,
    format: ShareFormat.images,
    progress: const Progress(completed: 2, total: 4),
  ),
);

/// The platform provider currently owns the export write.
@Preview(name: 'Share — exporting', group: 'Sharing', theme: appPreviewTheme)
Widget shareExporting() => _sheet(
  _ready.copyWith(
    status: ShareStatus.exporting,
    action: ShareAction.export,
    format: ShareFormat.pdf,
  ),
);

/// A completed export with its destination confirmation.
@Preview(name: 'Share — export done', group: 'Sharing', theme: appPreviewTheme)
Widget shareExportDone() => _sheet(
  _ready.copyWith(
    status: ShareStatus.done,
    action: ShareAction.export,
    format: ShareFormat.pdf,
    exportedTo: 'Downloads/Invoice 2026.pdf',
  ),
);

/// A dismissed provider flow, which is explicitly not an error.
@Preview(name: 'Share — cancelled', group: 'Sharing', theme: appPreviewTheme)
Widget shareCancelled() => _sheet(
  _ready.copyWith(
    status: ShareStatus.cancelled,
    action: ShareAction.export,
    format: ShareFormat.pdf,
  ),
);

/// A document with nothing to share as text — this sheet's empty state.
@Preview(name: 'Share — empty', group: 'Sharing', theme: appPreviewTheme)
Widget shareEmpty() =>
    _sheet(const ShareState.initial(title: 'Scan 2026-03-14', pageCount: 1));

/// A share that failed.
@Preview(name: 'Share — error', group: 'Sharing', theme: appPreviewTheme)
Widget shareError() => _sheet(
  _ready.copyWith(
    status: ShareStatus.failure,
    failure: const Failure.storageFull(),
  ),
);

/// Nothing on the device could receive the share, so export is offered.
@Preview(
  name: 'Share — no receiving app',
  group: 'Sharing',
  theme: appPreviewTheme,
)
Widget shareNoReceivingApp() => _sheet(
  _ready.copyWith(
    status: ShareStatus.failure,
    failure: const Failure.export(noReceivingApp: true),
  ),
);

/// A title long enough to need truncating.
@Preview(name: 'Share — long content', group: 'Sharing', theme: appPreviewTheme)
Widget shareLongContent() => _sheet(
  const ShareState.initial(
    title:
        'Quarterly consulting invoice for services rendered to Acme Limited '
        'during the period ending the thirty-first of March',
    pageCount: 128,
    canShareText: true,
  ),
);

/// The sheet on a phone, light.
@Preview(
  name: 'Share — phone, light',
  group: 'Sharing',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget sharePhoneLight() => _sheet(_ready);

/// The sheet on a phone, dark.
@Preview(
  name: 'Share — phone, dark',
  group: 'Sharing',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget sharePhoneDark() => _sheet(_ready);

/// The sheet on a tablet, light.
@Preview(
  name: 'Share — tablet, light',
  group: 'Sharing',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget shareTabletLight() => _sheet(_ready);

/// The sheet on a tablet, dark.
@Preview(
  name: 'Share — tablet, dark',
  group: 'Sharing',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget shareTabletDark() => _sheet(_ready);

// ---------------------------------------------------------------------------
// Share option tile
// ---------------------------------------------------------------------------

/// An enabled option.
@Preview(
  name: 'ShareOptionTile — default',
  group: 'Sharing',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget optionTileDefault() => ShareOptionTile(
  label: 'Share PDF',
  icon: Icons.picture_as_pdf_outlined,
  semanticsLabel: ShareRules.optionSemanticsLabel(
    ShareAction.share,
    ShareFormat.pdf,
    title: 'Invoice 2026',
  ),
  onTap: () {},
);

/// An option whose label and subtitle both have to wrap.
@Preview(
  name: 'ShareOptionTile — long content',
  group: 'Sharing',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget optionTileLongContent() => ShareOptionTile(
  label: 'Share every page of this document as a separate image file',
  icon: Icons.image_outlined,
  semanticsLabel: ShareRules.optionSemanticsLabel(
    ShareAction.share,
    ShareFormat.images,
    title: 'Quarterly consulting invoice for Acme Limited',
    pageCount: 128,
  ),
  subtitle: 'One JPEG per page, at up to 2400 pixels on the longest edge',
  onTap: () {},
);
