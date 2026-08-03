/// pdfrx adapter for rendering one PDF page at thumbnail resolution.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:pdfrx/pdfrx.dart';

/// Renders one page of [filePath] into PNG bytes no wider than [width].
///
/// This top-level function matches `ThumbnailRenderer`, keeping native PDFium
/// injectable and out of application/presentation tests.
Future<Result<Uint8List>> renderPdfrxThumbnail(
  String filePath, {
  required int pageNumber,
  required int width,
  String? password,
}) async {
  PdfDocument? document;
  PdfImage? rendered;
  ui.Image? image;

  try {
    document = await PdfDocument.openFile(
      filePath,
      passwordProvider: password == null ? null : () async => password,
      firstAttemptByEmptyPassword: password == null,
    );
    if (pageNumber < 1 || pageNumber > document.pages.length) {
      return Result<Uint8List>.failure(
        Failure.pdf(debugDetail: 'Page $pageNumber is out of range.'),
      );
    }

    final page = document.pages[pageNumber - 1];
    final height = width * page.height / page.width;
    rendered = await page.render(
      fullWidth: width.toDouble(),
      fullHeight: height,
    );
    if (rendered == null) {
      return const Result<Uint8List>.failure(
        Failure.pdf(debugDetail: 'PDF page rendering returned no image.'),
      );
    }

    image = await rendered.createImage(pixelSizeThreshold: width);
    final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
    if (encoded == null) {
      return const Result<Uint8List>.failure(
        Failure.pdf(debugDetail: 'PDF thumbnail encoding returned no data.'),
      );
    }
    return Result<Uint8List>.success(encoded.buffer.asUint8List());
  } on Object catch (error) {
    return Result<Uint8List>.failure(Failure.pdf(debugDetail: '$error'));
  } finally {
    // pdfrx owns native and UI image buffers; all three must be released even
    // when page validation, rendering, or PNG encoding fails.
    image?.dispose();
    rendered?.dispose();
    await document?.dispose();
  }
}
