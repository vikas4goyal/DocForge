/// Constructs the OCR and PDF-generation object graph.
///
/// The two are built together because they are one pipeline in practice: a
/// document is created by composing pages *and* the text recognised from them,
/// and the seam between them is a function rather than a whole feature
/// contract.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_scanly/features/ocr/application/usecases/ocr_usecases.dart';
import 'package:doc_scanly/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_scanly/features/ocr/infrastructure/repositories/isar_ocr_text_store.dart';
import 'package:doc_scanly/features/ocr/infrastructure/repositories/mlkit_ocr_repository.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_scanly/features/pdf_generation/infrastructure/pdf_composer.dart';
import 'package:isar_community/isar.dart';

/// Everything OCR and PDF generation need, built once.
class DocumentCreationModule {
  /// Creates the module.
  const DocumentCreationModule({
    required this.recogniseText,
    required this.loadRecognisedText,
    required this.forgetRecognisedText,
    required this.ocrTextSource,
    this.extractDocumentText,
    required this.languagePacks,
    required this.saveDocument,
    required this.generateName,
    required this.pageBundleSink,
  });

  /// Recognises the text of a document's pages.
  final RecogniseText recogniseText;

  /// Loads what has already been recognised.
  final LoadRecognisedText loadRecognisedText;

  /// Removes a document's recognised text when it is permanently deleted.
  final ForgetRecognisedText forgetRecognisedText;

  /// Recognised text for search and sharing.
  final OcrTextSource ocrTextSource;

  /// Extracts embedded text with bounded on-device OCR fallback for imports.
  final ExtractDocumentText? extractDocumentText;

  /// Which recognition scripts this build can use.
  final OcrLanguagePacks languagePacks;

  /// Composes a PDF and creates the document record.
  final SaveDocument saveDocument;

  /// Expands the configured naming pattern.
  final GenerateDocumentName generateName;

  /// Turns captured or imported pages into a stored document.
  ///
  /// The seam scanning and import consume; neither imports `pdf-generation`.
  final PageBundleSink pageBundleSink;
}

/// The recognition script used when the caller has not configured one.
///
/// A top-level function rather than a closure, so it can be a default argument
/// value — which is what keeps every existing caller of the builder below
/// working unchanged.
OcrScript _defaultScript() => OcrScript.defaultScript;

/// Builds the graph over an already-open [isar] and [publicStore].
///
/// [composer] and [recogniser] default to the real implementations and are
/// injectable so an integration test can substitute an inline composer and a
/// fake recogniser without a device. [script] supplies the recognition script,
/// which settings configures.
DocumentCreationModule buildDocumentCreationModule({
  required Isar isar,
  required Directory workingDirectory,
  required PublicFileStore publicStore,
  required PdfProtector protectPdf,
  required Clock clock,
  required IdGenerator ids,
  required DocumentReader documentReader,
  required DocumentWriter documentWriter,
  required NamingPattern Function() namingPattern,
  required ApplyEnhancement applyEnhancement,
  DocumentPageAccessRepository? pageAccess,
  PdfComposer? composer,
  AppTelemetry telemetry = const NoopAppTelemetry(),
  OcrRepository? recogniser,
  OcrScript Function() script = _defaultScript,
  OcrLanguagePacks languagePacks = const BundledOcrLanguagePacks(),
}) {
  final store = IsarOcrTextStore(isar);
  final ocr = recogniser ?? MlKitOcrRepository(clock);
  final recognise = RecogniseText(ocr, store);
  final extract = pageAccess == null
      ? null
      : ExtractDocumentText(
          documentReader,
          documentWriter,
          pageAccess,
          ocr,
          store,
          clock,
        );

  Future<Map<String, RecognisedText>> textFor(List<PageId> pageIds) async {
    final result = await store.findAll(pageIds);
    final texts = result.valueOrNull ?? const {};
    return {for (final entry in texts.entries) entry.key.value: entry.value};
  }

  /// Renders a page's stored enhancement before it is drawn into the PDF.
  ///
  /// Without this the composer draws the capture, and the saved document does
  /// not carry the settings the user chose on the enhance screen — they were
  /// recorded against the page and then never applied to anything.
  ///
  /// Written beside the capture rather than over it, so the settings stay
  /// re-editable: a page enhanced once can be enhanced differently later from
  /// the original rather than from an already-filtered image.
  Future<String> resolvePageImage(
    PageRef page, {
    required int maxDimension,
  }) async {
    if (!EnhancementRules.requiresProcessing(page.enhancement)) {
      return page.imagePath;
    }

    final result = await applyEnhancement.single(
      sourcePath: page.imagePath,
      destinationPath: '${page.imagePath}.composed.jpg',
      settings: page.enhancement,
      // The size composition will draw at. Filtering the full capture would do
      // several times the work and then throw most of it away.
      maxDimension: maxDimension,
    );

    // A page that could not be enhanced is still drawn, unfiltered. Losing the
    // page from the document would be far worse than losing its filter.
    return result.valueOrNull ?? page.imagePath;
  }

  final save = SaveDocument(
    BuildSearchablePdf(
      composer ?? IsolatePdfComposer(telemetry: telemetry),
      textFor,
      resolveImage: resolvePageImage,
    ),
    documentWriter,
    clock,
    ids,
    // Composed into the private working directory, then published into the
    // user-visible library by the use case itself.
    (id) => '${workingDirectory.path}/${id.value}.pdf',
    // Deleting an orphan must not itself fail the save: the record is already
    // gone, and a file that could not be removed is a smaller problem than an
    // error the user cannot act on.
    (path) async {
      final file = File(path);
      if (file.existsSync()) {
        try {
          await file.delete();
        } on FileSystemException {
          // Nothing useful to do, and nothing the user could do either.
        }
      }
    },
    publicStore,
    protectPdf,
  );

  final generateName = GenerateDocumentName(clock, documentReader);

  return DocumentCreationModule(
    recogniseText: recognise,
    loadRecognisedText: LoadRecognisedText(store),
    forgetRecognisedText: ForgetRecognisedText(store),
    ocrTextSource: pageAccess == null
        ? OcrTextSourceImpl(store, documentReader.pagesOf)
        : DocumentPageOcrTextSource(
            documentReader,
            pageAccess,
            store,
            extract,
            script,
          ),
    extractDocumentText: extract,
    languagePacks: languagePacks,
    saveDocument: save,
    generateName: generateName,
    pageBundleSink: PageBundleSinkImpl(
      save,
      generateName,
      namingPattern,
      // Drained rather than merely started: composition reads the store, so it
      // has to happen after every page has been written, not alongside.
      (pages, documentId) => recognise(
        pages,
        documentId: documentId,
        script: script(),
      ).drain<void>(),
      ids,
    ),
  );
}
