/// Background-isolate composition for exact generated-PDF candidates.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Message sent to start candidate composition in an isolate.
class GeneratedPdfCandidateJobRequest {
  /// Creates an isolate request.
  const GeneratedPdfCandidateJobRequest({
    required this.request,
    required this.destinationPath,
    required this.events,
  });

  /// Candidate inputs.
  final GeneratedPdfCandidateRequest request;

  /// Private temporary output path.
  final String destinationPath;

  /// Port receiving control, progress, completion, and failure messages.
  final SendPort events;
}

/// Starts one cooperative, bounded-memory candidate composition job.
Future<void> runGeneratedPdfCandidateJob(
  GeneratedPdfCandidateJobRequest job,
) async {
  final controls = ReceivePort();
  job.events.send(controls.sendPort);
  var cancelled = false;
  final subscription = controls.listen((message) {
    if (message == 'cancel') {
      cancelled = true;
    }
  });
  final destination = File(job.destinationPath);

  try {
    final document = pw.Document();
    for (var index = 0; index < job.request.pages.length; index++) {
      await Future<void>.delayed(Duration.zero);
      if (cancelled) {
        job.events.send('cancelled');
        return;
      }
      _addCandidatePage(document, job.request.pages[index]);
      job.events.send(index + 1);
    }

    if (cancelled) {
      job.events.send('cancelled');
      return;
    }
    destination.writeAsBytesSync(await document.save(), flush: true);
    job.events.send('complete');
  } on Object catch (error, stackTrace) {
    job.events.send(<Object>['failure', '$error', '$stackTrace']);
  } finally {
    await subscription.cancel();
    controls.close();
    if (cancelled && destination.existsSync()) {
      destination.deleteSync();
    }
  }
}

void _addCandidatePage(pw.Document document, GeneratedPdfCandidatePage spec) {
  final decoded = img.decodeImage(File(spec.page.imagePath).readAsBytesSync());
  if (decoded == null) {
    throw FormatException(
      'the page image could not be decoded: ${spec.page.imagePath}',
    );
  }
  final oriented = spec.page.rotation == PageRotation.none
      ? decoded
      : img.copyRotate(decoded, angle: spec.page.rotation.degrees);
  final width = spec.quality.scaleDimension(oriented.width);
  final height = spec.quality.scaleDimension(oriented.height);
  final scaled = width == oriented.width && height == oriented.height
      ? oriented
      : img.copyResize(
          oriented,
          width: width,
          height: height,
          interpolation: img.Interpolation.average,
        );
  final encoded = img.encodeJpg(
    scaled,
    quality: spec.quality.value.clamp(30, 95),
  );
  final pageWidth = PdfPageFormat.a4.width;
  final pageHeight = pageWidth * scaled.height / scaled.width;
  final format = PdfPageFormat(pageWidth, pageHeight);
  final image = pw.MemoryImage(encoded);

  document.addPage(
    pw.Page(
      pageFormat: format,
      build: (_) => pw.Stack(
        children: <pw.Widget>[
          pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),
          ..._textLayer(
            spec.page,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
          ),
        ],
      ),
    ),
  );
}

List<pw.Widget> _textLayer(
  PdfPageSpec page, {
  required double pageWidth,
  required double pageHeight,
}) => <pw.Widget>[
  for (final block in page.textBlocks)
    pw.Positioned(
      left: block.bounds.left * pageWidth,
      top: block.bounds.top * pageHeight,
      child: pw.SizedBox(
        width: math.max(block.bounds.width * pageWidth, 1),
        height: math.max(block.bounds.height * pageHeight, 1),
        child: pw.Text(
          block.text,
          style: pw.TextStyle(
            fontSize: math.max(block.bounds.height * pageHeight * 0.8, 1),
            renderingMode: PdfTextRenderingMode.invisible,
          ),
        ),
      ),
    ),
];
