/// Widget previews for the OCR feature.
///
/// Every preview is fed by fixtures through a seeded Cubit, so nothing here
/// opens a recogniser, reads a file or touches a database (`design.md` §15).
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/previews/fakes/fake_cubit.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/features/ocr/application/usecases/ocr_usecases.dart';
import 'package:doc_scanly/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_cubit.dart';
import 'package:doc_scanly/features/ocr/presentation/cubit/ocr_state.dart';
import 'package:doc_scanly/features/ocr/presentation/screens/extracted_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The document every preview shows.
const _document = DocumentId('preview-document');

/// Fixture pages.
List<PageRef> _pages(int count) => List.generate(
  count,
  (index) => PageRef(
    id: PageId('preview-page-$index'),
    imagePath: '/preview/$index.jpg',
  ),
);

/// A recognition result for [pageId] carrying [lines].
RecognisedText _text(String pageId, List<String> lines) => RecognisedText(
  pageId: PageId(pageId),
  blocks: [
    for (var index = 0; index < lines.length; index++)
      TextBlock(
        text: lines[index],
        bounds: NormalisedRect(
          left: 0.1,
          top: 0.1 + index * 0.06,
          right: 0.9,
          bottom: 0.15 + index * 0.06,
        ),
      ),
  ],
  languageTag: 'la',
  // Fixed, so every preview and golden built on it is byte-stable.
  recognisedAt: DateTime.utc(2026, 3, 14, 9, 30),
);

/// An [OcrCubit] frozen at a chosen state.
class _PreviewOcrCubit extends OcrCubit with SeededCubit<OcrState> {
  _PreviewOcrCubit(OcrState state)
    : super(
        _document,
        'Invoice 2026',
        state,
        RecogniseText(FakeOcrRepository(), InMemoryOcrTextStore()),
        LoadRecognisedText(InMemoryOcrTextStore()),
        _noClipboard,
        _noExport,
      ) {
    seed(state);
  }
}

/// A clipboard that receives nothing.
Future<void> _noClipboard(String text) async {}

/// An exporter that writes nothing.
Future<Result<void>> _noExport(String text, {required String fileName}) async =>
    const Result<void>.success(null);

Widget _view(OcrState state) => Scaffold(
  body: BlocProvider<OcrCubit>(
    create: (_) => _PreviewOcrCubit(state),
    child: const ExtractedTextView(),
  ),
);

/// The base state every preview varies from.
OcrState _base({int pages = 3}) => OcrState.initial(_pages(pages));

/// A state with text recognised on every page.
OcrState _recognised() => _base().copyWith(
  status: OcrStatus.ready,
  texts: {
    const PageId('preview-page-0'): _text('preview-page-0', [
      'INVOICE',
      'Acme Limited',
      '14 March 2026',
    ]),
    const PageId('preview-page-1'): _text('preview-page-1', [
      'Consulting services',
      'Total due: 240.00',
    ]),
    const PageId('preview-page-2'): _text('preview-page-2', [
      'Payment terms: 30 days',
    ]),
  },
);

// ---------------------------------------------------------------------------
// Extracted-text view
// ---------------------------------------------------------------------------

/// Recognised text on every page.
@Preview(name: 'ExtractedText — default', group: 'OCR', theme: appPreviewTheme)
Widget extractedTextDefault() => _view(_recognised());

/// Stored text still being loaded.
@Preview(name: 'ExtractedText — loading', group: 'OCR', theme: appPreviewTheme)
Widget extractedTextLoading() => _view(_base());

/// A document nobody has extracted text from yet.
@Preview(
  name: 'ExtractedText — not recognised',
  group: 'OCR',
  theme: appPreviewTheme,
)
Widget extractedTextNotRecognised() =>
    _view(_base().copyWith(status: OcrStatus.notRecognised));

/// A document that was read and had nothing legible on it.
@Preview(name: 'ExtractedText — empty', group: 'OCR', theme: appPreviewTheme)
Widget extractedTextEmpty() => _view(
  _base().copyWith(
    status: OcrStatus.empty,
    texts: {
      for (final page in _pages(3))
        page.id: RecognisedText.empty(
          pageId: page.id,
          languageTag: 'la',
          recognisedAt: DateTime.utc(2026, 3, 14),
        ),
    },
  ),
);

/// Recognition part-way through a long document.
@Preview(name: 'ExtractedText — running', group: 'OCR', theme: appPreviewTheme)
Widget extractedTextRunning() => _view(
  OcrState.initial(_pages(24)).copyWith(
    status: OcrStatus.running,
    progress: const Progress(completed: 9, total: 24),
  ),
);

/// Recognition that has only just started.
@Preview(
  name: 'ExtractedText — running, at the start',
  group: 'OCR',
  theme: appPreviewTheme,
)
Widget extractedTextRunningStart() => _view(
  OcrState.initial(_pages(24)).copyWith(
    status: OcrStatus.running,
    progress: const Progress(completed: 0, total: 24),
  ),
);

/// Recognition that failed.
@Preview(name: 'ExtractedText — error', group: 'OCR', theme: appPreviewTheme)
Widget extractedTextError() => _view(
  _base().copyWith(status: OcrStatus.failure, failure: const Failure.ocr()),
);

/// An export that could not be written.
@Preview(
  name: 'ExtractedText — export failed',
  group: 'OCR',
  theme: appPreviewTheme,
)
Widget extractedTextExportError() => _view(
  _recognised().copyWith(
    status: OcrStatus.failure,
    failure: const Failure.export(),
  ),
);

/// A document that produced far more text than fits on screen.
@Preview(
  name: 'ExtractedText — long content',
  group: 'OCR',
  theme: appPreviewTheme,
)
Widget extractedTextLongContent() => _view(
  _base(pages: 1).copyWith(
    status: OcrStatus.ready,
    texts: {
      const PageId('preview-page-0'): _text('preview-page-0', [
        for (var line = 0; line < 60; line++)
          'Line $line — the quick brown fox jumps over the lazy dog, twice.',
      ]),
    },
  ),
);

/// The view on a phone, light.
@Preview(
  name: 'ExtractedText — phone, light',
  group: 'OCR',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget extractedTextPhoneLight() => _view(_recognised());

/// The view on a phone, dark.
@Preview(
  name: 'ExtractedText — phone, dark',
  group: 'OCR',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget extractedTextPhoneDark() => _view(_recognised());

/// The view on a tablet, light.
@Preview(
  name: 'ExtractedText — tablet, light',
  group: 'OCR',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget extractedTextTabletLight() => _view(_recognised());

/// The view on a tablet, dark.
@Preview(
  name: 'ExtractedText — tablet, dark',
  group: 'OCR',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget extractedTextTabletDark() => _view(_recognised());
