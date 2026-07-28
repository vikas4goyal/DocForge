/// Widget previews for the PDF generation feature.
///
/// Every preview is fed by fixtures through a seeded Cubit, so nothing here
/// composes a PDF, reads an image or touches a database (`design.md` §15).
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/previews/fakes/fake_cubit.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_cubit.dart';
import 'package:doc_forge/features/pdf_generation/presentation/cubit/pdf_generation_state.dart';
import 'package:doc_forge/features/pdf_generation/presentation/screens/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Fixture pages.
List<PageRef> _pages(int count) => List.generate(
  count,
  (index) => PageRef(
    id: PageId('preview-page-$index'),
    imagePath: '/preview/$index.jpg',
  ),
);

/// A composer that produces nothing.
class _InertComposer implements PdfComposer {
  const _InertComposer();

  @override
  Future<Result<ComposedPdf>> compose(PdfBuildRequest request) async =>
      Result<ComposedPdf>.success(
        ComposedPdf(
          filePath: request.destinationPath,
          sizeInBytes: 0,
          pageCount: request.pages.length,
        ),
      );
}

/// A document reader that reports an empty library.
class _InertDocuments implements DocumentReader {
  const _InertDocuments();

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

/// A writer that stores nothing.
class _InertWriter implements DocumentWriter {
  const _InertWriter();

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async => Result<Document>.success(document);

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}

/// A [PdfGenerationCubit] frozen at a chosen state.
class _PreviewPdfCubit extends PdfGenerationCubit
    with SeededCubit<PdfGenerationState> {
  _PreviewPdfCubit(PdfGenerationState state)
    : super(
        state.pages,
        SaveDocument(
          const BuildSearchablePdf(_InertComposer(), _noText),
          const _InertWriter(),
          // Fixed, so every preview is byte-stable.
          FixedClock(DateTime.utc(2026, 3, 14, 9, 30)),
          SequentialIdGenerator(prefix: 'preview'),
          _previewDestination,
          _noDelete,
          InMemoryPublicFileStore(),
          _noProtection,
        ),
        GenerateDocumentName(
          FixedClock(DateTime(2026, 3, 14, 9, 30)),
          const _InertDocuments(),
        ),
        source: PageSource.camera,
      ) {
    seed(state);
  }
}

/// A text lookup that finds nothing.
Future<Map<String, RecognisedText>> _noText(List<PageId> ids) async => const {};

/// Names a destination without creating one.
String _previewDestination(DocumentId id) => '/preview/${id.value}.pdf';

/// A delete that removes nothing.
Future<void> _noDelete(String path) async {}

/// Protection that returns the file untouched, for previews.
Future<Result<String>> _noProtection(
  String sourcePath,
  String password,
) async => Result<String>.success(sourcePath);

Widget _screen(PdfGenerationState state) => BlocProvider<PdfGenerationCubit>(
  create: (_) => _PreviewPdfCubit(state),
  child: PdfPreviewScreen(onSaved: (_) {}, onBack: () {}),
);

/// The base state every preview varies from.
PdfGenerationState _base({int pages = 4}) => PdfGenerationState.initial(
  pages: _pages(pages),
  title: 'Scan 2026-03-14 09.30',
);

// ---------------------------------------------------------------------------
// Document preview screen
// ---------------------------------------------------------------------------

/// The screen as it opens, ready to save.
@Preview(
  name: 'PdfPreview — default',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewDefault() => _screen(_base());

/// A single-page document.
@Preview(
  name: 'PdfPreview — single page',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewSinglePage() => _screen(_base(pages: 1));

/// A long scanning session.
@Preview(
  name: 'PdfPreview — long content',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewLongContent() => _screen(_base(pages: 40));

/// A session with no pages, which cannot be saved.
@Preview(
  name: 'PdfPreview — empty',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewEmpty() => _screen(_base(pages: 0));

/// A name the user has typed over the generated one.
@Preview(
  name: 'PdfPreview — renamed',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewRenamed() =>
    _screen(_base().copyWith(enteredTitle: 'March invoices'));

/// The highest quality selected.
@Preview(
  name: 'PdfPreview — best quality',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewHighQuality() =>
    _screen(_base().copyWith(quality: PdfQuality.high));

/// The document being composed.
@Preview(
  name: 'PdfPreview — generating',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewGenerating() =>
    _screen(_base().copyWith(status: PdfGenerationStatus.generating));

/// Generation that failed.
@Preview(
  name: 'PdfPreview — error',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewError() => _screen(
  _base().copyWith(
    status: PdfGenerationStatus.failure,
    failure: const Failure.pdf(),
  ),
);

/// Generation that ran out of space.
@Preview(
  name: 'PdfPreview — storage full',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget pdfPreviewStorageFull() => _screen(
  _base().copyWith(
    status: PdfGenerationStatus.failure,
    failure: const Failure.storageFull(),
  ),
);

/// The screen on a phone, light.
@Preview(
  name: 'PdfPreview — phone, light',
  group: 'PDF generation',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget pdfPreviewPhoneLight() => _screen(_base());

/// The screen on a phone, dark.
@Preview(
  name: 'PdfPreview — phone, dark',
  group: 'PDF generation',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget pdfPreviewPhoneDark() => _screen(_base());

/// The screen on a tablet, light, where the grid gains columns.
@Preview(
  name: 'PdfPreview — tablet, light',
  group: 'PDF generation',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget pdfPreviewTabletLight() => _screen(_base(pages: 9));

/// The screen on a tablet, dark.
@Preview(
  name: 'PdfPreview — tablet, dark',
  group: 'PDF generation',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget pdfPreviewTabletDark() => _screen(_base(pages: 9));
