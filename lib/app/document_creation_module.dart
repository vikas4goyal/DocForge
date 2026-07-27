/// Constructs the OCR and PDF-generation object graph.
///
/// The two are built together because they are one pipeline in practice: a
/// document is created by composing pages *and* the text recognised from them,
/// and the seam between them is a function rather than a whole feature
/// contract.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/ocr/application/usecases/ocr_usecases.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/isar_ocr_text_store.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/mlkit_ocr_repository.dart';
import 'package:doc_forge/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_forge/features/pdf_generation/infrastructure/pdf_composer.dart';
import 'package:isar_community/isar.dart';

/// Everything OCR and PDF generation need, built once.
class DocumentCreationModule {
  /// Creates the module.
  const DocumentCreationModule({
    required this.recogniseText,
    required this.loadRecognisedText,
    required this.forgetRecognisedText,
    required this.ocrTextSource,
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

/// Builds the graph over an already-open [isar] and [documentsDirectory].
///
/// [composer] and [recogniser] default to the real implementations and are
/// injectable so an integration test can substitute an inline composer and a
/// fake recogniser without a device. [script] supplies the recognition script,
/// which settings configures.
DocumentCreationModule buildDocumentCreationModule({
  required Isar isar,
  required Directory documentsDirectory,
  required Clock clock,
  required IdGenerator ids,
  required DocumentReader documentReader,
  required DocumentWriter documentWriter,
  required NamingPattern Function() namingPattern,
  PdfComposer composer = const IsolatePdfComposer(),
  OcrRepository? recogniser,
  OcrScript Function() script = _defaultScript,
  OcrLanguagePacks languagePacks = const BundledOcrLanguagePacks(),
}) {
  final store = IsarOcrTextStore(isar);
  final ocr = recogniser ?? MlKitOcrRepository(clock);
  final recognise = RecogniseText(ocr, store);

  Future<Map<String, RecognisedText>> textFor(List<PageId> pageIds) async {
    final result = await store.findAll(pageIds);
    final texts = result.valueOrNull ?? const {};
    return {for (final entry in texts.entries) entry.key.value: entry.value};
  }

  final save = SaveDocument(
    BuildSearchablePdf(composer, textFor),
    documentWriter,
    clock,
    ids,
    (id) => '${documentsDirectory.path}/${id.value}.pdf',
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
  );

  final generateName = GenerateDocumentName(clock, documentReader);

  return DocumentCreationModule(
    recogniseText: recognise,
    loadRecognisedText: LoadRecognisedText(store),
    forgetRecognisedText: ForgetRecognisedText(store),
    ocrTextSource: OcrTextSourceImpl(store, documentReader.pagesOf),
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
