/// PDF composition: page images plus the invisible OCR text layer.
///
/// Everything here runs **inside a background isolate**. Two consequences that
/// are easy to forget: it may not touch Flutter, and only the request and the
/// returned description cross the boundary — never a decoded image
/// (`design.md` §7).
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Composes one PDF and returns a description of what was written.
///
/// A top-level function because a closure cannot be sent to an isolate.
///
/// Writes to a temporary file beside the destination and renames it into place
/// only once the whole document exists. A rename within a directory is atomic
/// on both platforms, so a failure part-way leaves the temporary file — which
/// is removed — rather than a truncated PDF where a real one is expected.
/// Asynchronous because `pw.Document.save` is: the composer therefore owns its
/// own `Isolate.run` rather than going through `BackgroundWorker`, whose job
/// contract is synchronous by design (only paths and value objects cross the
/// boundary, and a synchronous job cannot accidentally hold a stream open
/// across it).
Future<ComposedPdf> composePdfJob(PdfBuildRequest request) async {
  final document = pw.Document();

  for (final page in request.pages) {
    _addPage(document, page, request.quality);
  }

  final temporary = File('${request.destinationPath}.partial');

  try {
    temporary.writeAsBytesSync(await document.save());
    final destination = temporary.renameSync(request.destinationPath);

    return ComposedPdf(
      filePath: destination.path,
      // True when any page carried recognised text, which is exactly when an
      // invisible layer was written above.
      hasTextLayer: request.pages.any((page) => page.textBlocks.isNotEmpty),
      // Measured from the file rather than from the byte list, so the figure
      // stored on the document record is what the filesystem actually reports.
      sizeInBytes: destination.lengthSync(),
      pageCount: request.pages.length,
    );
  } on Object {
    // No partial artefact survives a failure, which the spec requires
    // explicitly.
    if (temporary.existsSync()) temporary.deleteSync();
    rethrow;
  }
}

/// Adds one page image, and its text layer, to [document].
void _addPage(pw.Document document, PdfPageSpec page, PdfQuality quality) {
  final decoded = img.decodeImage(File(page.imagePath).readAsBytesSync());

  if (decoded == null) {
    throw FormatException(
      'the page image could not be decoded: ${page.imagePath}',
    );
  }

  // Rotation is baked into the image rather than applied as a page transform.
  // A PDF page rotation is metadata a reader may or may not honour, and the
  // text layer's coordinates would then have to be rotated to match it — two
  // chances to disagree where there can be one.
  final oriented = page.rotation == PageRotation.none
      ? decoded
      : img.copyRotate(decoded, angle: page.rotation.degrees);

  final scaled = _scaled(oriented, quality.maxDimension);
  final bytes = img.encodeJpg(scaled, quality: quality.imageQuality);

  // The page is exactly the image's aspect ratio at a fixed points-per-pixel
  // scale, so the image fills it edge to edge with no letterboxing — and the
  // normalised text boxes map onto the page by multiplication alone.
  final pageWidth = PdfPageFormat.a4.width;
  final pageHeight = pageWidth * scaled.height / scaled.width;
  final format = PdfPageFormat(pageWidth, pageHeight);

  final image = pw.MemoryImage(bytes);

  document.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Stack(
        children: [
          pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),
          ..._textLayer(page, pageWidth: pageWidth, pageHeight: pageHeight),
        ],
      ),
    ),
  );
}

/// Builds the invisible text layer for [page].
///
/// Each block is positioned over the region of the page image the text was read
/// from, which is what makes selection in a reader land on the words the user
/// is pointing at rather than somewhere near them.
///
/// The text is rendered in an invisible mode rather than in white or at zero
/// opacity: white text is visible against a dark scan and selectable text at
/// zero opacity still prints. `PdfTextRenderingMode.invisible` is the mechanism
/// PDF defines for exactly this.
List<pw.Widget> _textLayer(
  PdfPageSpec page, {
  required double pageWidth,
  required double pageHeight,
}) {
  return [
    for (final block in page.textBlocks)
      pw.Positioned(
        left: block.bounds.left * pageWidth,
        // PDF's own origin is bottom-left, but `pw.Positioned` inside a Stack
        // measures from the top, matching the normalised boxes — so no flip is
        // needed here, and adding one would put every line on the wrong half of
        // the page.
        top: block.bounds.top * pageHeight,
        child: pw.SizedBox(
          width: math.max(block.bounds.width * pageWidth, 1),
          height: math.max(block.bounds.height * pageHeight, 1),
          child: pw.Text(
            block.text,
            style: pw.TextStyle(
              // Sized to the box the text was read from, so a reader's
              // selection highlight covers the words rather than a band of
              // arbitrary height.
              fontSize: math.max(block.bounds.height * pageHeight * 0.8, 1),
              renderingMode: PdfTextRenderingMode.invisible,
            ),
          ),
        ),
      ),
  ];
}

/// Returns [source] scaled so its longest edge is at most [maxDimension].
///
/// Returns [source] unchanged when it is already small enough: upscaling a
/// low-resolution capture to hit a target adds bytes and no detail.
img.Image _scaled(img.Image source, int maxDimension) {
  final longest = math.max(source.width, source.height);
  if (longest <= maxDimension) return source;

  final scale = maxDimension / longest;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
}
