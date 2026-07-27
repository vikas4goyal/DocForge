/// Constructs the sharing object graph.
///
/// Everything here is infrastructure construction, which the composition root
/// is the only place allowed to do (`design.md` §5).
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_forge/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_forge/features/document_sharing/domain/repositories/share_repository.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:doc_forge/features/document_sharing/infrastructure/repositories/platform_share_repositories.dart';
import 'package:doc_forge/features/document_sharing/infrastructure/share_page_job.dart';

/// Everything the sharing feature exposes to the rest of the application.
class SharingModule {
  /// Creates the module over an already-built object graph.
  const SharingModule({
    required this.documentReader,
    required this.ocrTextSource,
    required this.sharePdf,
    required this.shareImages,
    required this.shareText,
    required this.printDocument,
    required this.export,
  });

  /// Reads the document the sheet is about to describe.
  ///
  /// Exposed because the sheet has to be seeded with the document's title, page
  /// count and whether it has text before it is shown, and whoever opens it has
  /// no other route to that.
  final DocumentReader documentReader;

  /// Reads recognised text, for deciding whether the text option is offered.
  final OcrTextSource ocrTextSource;

  /// Shares the stored PDF.
  final ShareDocumentPdf sharePdf;

  /// Renders selected pages as images and shares them.
  final SharePageImages shareImages;

  /// Shares the recognised text.
  final ShareExtractedText shareText;

  /// Prints the document.
  final PrintDocument printDocument;

  /// Exports the document to a chosen destination.
  final ExportDocument export;
}

/// Builds the sharing module.
///
/// [cacheDirectory] is where page images are staged. The *cache* rather than
/// documents storage: a staged image is a copy the receiving application may
/// still hold a handle on after we are done, and the operating system is free
/// to reclaim it later. Nothing staged is a document of record.
SharingModule buildSharingModule({
  required DocumentReader documentReader,
  required OcrTextSource ocrTextSource,
  required DocumentFileResolver documentFiles,
  required Directory cacheDirectory,
  BackgroundWorker worker = const IsolateBackgroundWorker(),
  ShareRepository share = const SystemShareRepository(),
  PrintRepository printer = const SystemPrintRepository(),
  ExportDestinationPicker picker = const SystemExportDestinationPicker(),
}) {
  Directory staging() {
    final directory = Directory(
      '${cacheDirectory.path}/${ShareRules.stagingDirectoryName}',
    );
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return directory;
  }

  return SharingModule(
    documentReader: documentReader,
    ocrTextSource: ocrTextSource,
    sharePdf: ShareDocumentPdf(documentReader, share, documentFiles),
    shareImages: SharePageImages(
      documentReader,
      share,
      worker,
      staging,
      renderSharePageJob,
    ),
    shareText: ShareExtractedText(documentReader, ocrTextSource, share),
    printDocument: PrintDocument(documentReader, printer, documentFiles),
    export: ExportDocument(documentReader, picker, documentFiles),
  );
}
