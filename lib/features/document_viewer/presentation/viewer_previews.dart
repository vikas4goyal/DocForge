/// Widget previews for the document viewer.
///
/// Every preview is fed by fixtures through a seeded Cubit, so nothing here
/// opens a PDF, loads PDFium or touches a database (`design.md` §15). The page
/// surface is a flat placeholder for the same reason the camera preview is: a
/// real one needs a plugin-backed renderer no preview can create.
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fakes/fake_cubit.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_scanly/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_state.dart';
import 'package:doc_scanly/features/document_viewer/presentation/screens/viewer_screen.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The document every preview shows.
final _document = Document(
  id: const DocumentId('preview-document'),
  title: 'Invoice 2026',
  // Fixed, so every preview and golden built on it is byte-stable.
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 12,
  sizeInBytes: 482_310,
  libraryPath: LibraryPath.parse('Invoice 2026.pdf'),
);

/// Stands in for the page-rendering surface.
Widget _previewSurface(
  BuildContext context, {
  required String filePath,
  required String? password,
  required int page,
  required ValueChanged<int> onPageChanged,
}) => ColoredBox(
  key: ViewerKeys.pageView,
  color: const Color(0xFFE8E8E8),
  child: Center(
    child: Text(
      'Page $page',
      style: const TextStyle(color: Color(0xFF303030), fontSize: 24),
    ),
  ),
);

/// A store that holds nothing.
class _InertSecrets implements SecureStore {
  const _InertSecrets();

  @override
  Future<Result<String?>> read(String key) async =>
      const Result<String?>.success(null);

  @override
  Future<Result<void>> write(String key, String value) async =>
      const Result<void>.success(null);

  @override
  Future<Result<void>> delete(String key) async =>
      const Result<void>.success(null);
}

/// A document reader returning the fixture.
class _InertDocuments implements DocumentReader {
  const _InertDocuments();

  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      Result<Document>.success(_document);

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => Result<List<Document>>.success([_document]);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);
}

/// A [ViewerCubit] frozen at a chosen state.
class _PreviewViewerCubit extends ViewerCubit with SeededCubit<ViewerState> {
  _PreviewViewerCubit(ViewerState state)
    : super(
        const DocumentId('preview-document'),
        OpenDocumentForViewing(
          const _InertDocuments(),
          FakePdfRenderer(pageCount: 12),
          const _InertSecrets(),
          PublicStoreDocumentFileResolver(InMemoryPublicFileStore()),
        ),
        const RememberDocumentPassword(_InertSecrets()),
        const ForgetDocumentPassword(_InertSecrets()),
        _loadPreviewMetadata,
        _togglePreviewFavourite,
      ) {
    seed(state);
  }
}

Future<Result<Document>> _loadPreviewMetadata(DocumentId id) async =>
    Result<Document>.success(_document);

Future<Result<Document>> _togglePreviewFavourite(DocumentId id) async =>
    Result<Document>.success(
      _document.copyWith(isFavourite: !_document.isFavourite),
    );

Widget _viewer(ViewerState state) => BlocProvider<ViewerCubit>(
  create: (_) => _PreviewViewerCubit(state),
  child: ViewerScreen(
    surfaceBuilder: _previewSurface,
    onBack: () {},
    onShare: () {},
    onShowDetails: () async {},
    onAction: (_) {},
  ),
);

/// A document open at page one.
ViewerState _open({int page = 1, Document? document}) =>
    const ViewerState.initial().copyWith(
      status: ViewerStatus.ready,
      document: document ?? _document,
      pageCount: 12,
      page: page,
    );

// ---------------------------------------------------------------------------
// Viewer screen
// ---------------------------------------------------------------------------

/// The document open at its first page.
@Preview(name: 'Viewer — default', group: 'Viewer', theme: appPreviewTheme)
Widget viewerDefault() => _viewer(_open());

/// A document already marked as a favourite.
@Preview(name: 'Viewer — favourite', group: 'Viewer', theme: appPreviewTheme)
Widget viewerFavourite() =>
    _viewer(_open(document: _document.copyWith(isFavourite: true)));

/// Favourite persistence is currently in flight.
@Preview(
  name: 'Viewer — favourite working',
  group: 'Viewer',
  theme: appPreviewTheme,
)
Widget viewerFavouriteWorking() =>
    _viewer(_open().copyWith(isFavouriteWorking: true));

/// A favourite action failed without replacing the readable PDF.
@Preview(
  name: 'Viewer — action failure',
  group: 'Viewer',
  theme: appPreviewTheme,
)
Widget viewerActionFailure() =>
    _viewer(_open().copyWith(actionFailure: const Failure.storage()));

/// The record disappeared while Details was open.
@Preview(name: 'Viewer — unavailable', group: 'Viewer', theme: appPreviewTheme)
Widget viewerUnavailable() => _viewer(_open().copyWith(isUnavailable: true));

/// The document part-way through.
@Preview(name: 'Viewer — mid-document', group: 'Viewer', theme: appPreviewTheme)
Widget viewerMidDocument() => _viewer(_open(page: 7));

/// The document being opened.
@Preview(name: 'Viewer — loading', group: 'Viewer', theme: appPreviewTheme)
Widget viewerLoading() => _viewer(const ViewerState.initial());

/// A protected document waiting for its password.
@Preview(name: 'Viewer — locked', group: 'Viewer', theme: appPreviewTheme)
Widget viewerLocked() =>
    _viewer(const ViewerState.initial().copyWith(status: ViewerStatus.locked));

/// A protected document whose password was rejected.
@Preview(
  name: 'Viewer — password rejected',
  group: 'Viewer',
  theme: appPreviewTheme,
)
Widget viewerPasswordRejected() => _viewer(
  const ViewerState.initial().copyWith(
    status: ViewerStatus.locked,
    passwordRejected: true,
  ),
);

/// A document that could not be read.
@Preview(name: 'Viewer — error', group: 'Viewer', theme: appPreviewTheme)
Widget viewerError() => _viewer(
  const ViewerState.initial().copyWith(
    status: ViewerStatus.failure,
    failure: const Failure.corruptFile(),
  ),
);

/// A document whose file has gone.
@Preview(name: 'Viewer — missing file', group: 'Viewer', theme: appPreviewTheme)
Widget viewerMissing() => _viewer(
  const ViewerState.initial().copyWith(
    status: ViewerStatus.failure,
    failure: const Failure.notFound(),
  ),
);

/// A single-page document, where the indicator has the least to say.
@Preview(name: 'Viewer — empty', group: 'Viewer', theme: appPreviewTheme)
Widget viewerSinglePage() => _viewer(
  const ViewerState.initial().copyWith(
    status: ViewerStatus.ready,
    document: _document,
    pageCount: 1,
  ),
);

/// A document with a long title.
@Preview(name: 'Viewer — long content', group: 'Viewer', theme: appPreviewTheme)
Widget viewerLongContent() => _viewer(
  _open(
    document: _document.copyWith(
      title: List.filled(10, 'Quarterly statement').join(' '),
    ),
  ),
);

/// Viewer chrome at the maximum supported text scale.
@Preview(
  name: 'Viewer — large text',
  group: 'Viewer',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget viewerLargeText() => _viewer(_open());

/// The viewer on a phone, light.
@Preview(
  name: 'Viewer — phone, light',
  group: 'Viewer',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget viewerPhoneLight() => _viewer(_open());

/// The viewer on a phone, dark.
@Preview(
  name: 'Viewer — phone, dark',
  group: 'Viewer',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget viewerPhoneDark() => _viewer(_open());

/// The viewer on a tablet.
@Preview(
  name: 'Viewer — tablet, light',
  group: 'Viewer',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget viewerTabletLight() => _viewer(_open());

/// The viewer on a tablet, dark.
@Preview(
  name: 'Viewer — tablet, dark',
  group: 'Viewer',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget viewerTabletDark() => _viewer(_open());
