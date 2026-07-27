/// Use cases for turning a page bundle into a stored document.
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/domain/repositories/pdf_repository.dart';

/// Produces the image a page should actually be drawn from.
///
/// A seam rather than a direct call into image enhancement: composing a PDF
/// must not depend on the enhancement feature (`design.md` §2). The composition
/// root supplies one that applies each page's stored settings; everything else
/// — previews, tests, imports that were never enhanced — uses the identity.
///
/// [maxDimension] is the size the page will be drawn at, so an implementation
/// can avoid processing pixels composition is about to discard.
typedef PageImageResolver =
    Future<String> Function(PageRef page, {required int maxDimension});

/// Draws the page exactly as it was captured.
Future<String> _unmodifiedPage(
  PageRef page, {
  required int maxDimension,
}) async => page.imagePath;

/// Reads recognised text for pages about to be composed.
///
/// A function rather than the whole `OcrTextSource` contract, because
/// composition needs exactly one thing from OCR and taking the narrower
/// dependency keeps a test from having to stand up a text source it does not
/// care about.
typedef PageTextLookup =
    Future<Map<String, RecognisedText>> Function(List<PageId> pageIds);

/// Decides where a document's PDF is written.
///
/// Injected because where a file may be written is a property of the running
/// application, and no use case may perform an ambient path lookup.
typedef PdfDestination = String Function(DocumentId id);

/// Expands the configured naming pattern for a new document.
class GenerateDocumentName {
  /// Creates the use case.
  const GenerateDocumentName(this._clock, this._documents);

  final Clock _clock;
  final DocumentReader _documents;

  /// Returns the title a document created now would be given.
  ///
  /// [suggested] wins when the source offered one — an imported file's name is
  /// more useful than a generated timestamp.
  Future<String> call(
    NamingPattern pattern, {
    String? suggested,
    String? entered,
  }) async {
    if (entered != null && entered.trim().isNotEmpty) {
      return DocumentNaming.resolve(entered, DocumentNaming.fallback);
    }

    if (suggested != null && suggested.trim().isNotEmpty) {
      return suggested.trim();
    }

    // Only the sequential pattern needs the count, and a query per keystroke
    // for the others would be pure waste.
    final count = pattern == NamingPattern.sequential
        ? await _existingCount()
        : 0;

    return DocumentNaming.expand(
      pattern,
      now: _clock.now(),
      existingCount: count,
    );
  }

  /// How many documents the library already holds.
  ///
  /// A failed count degrades to zero rather than failing the save: a document
  /// named "Scan 1" twice is a nuisance, losing a scan is not.
  Future<int> _existingCount() async {
    final result = await _documents.query();
    return result.valueOrNull?.length ?? 0;
  }
}

/// Builds a searchable PDF from a bundle of pages.
class BuildSearchablePdf {
  /// Creates the use case.
  const BuildSearchablePdf(
    this._composer,
    this._textFor, {
    this.resolveImage = _unmodifiedPage,
  });

  final PdfComposer _composer;
  final PageTextLookup _textFor;

  /// Produces the image each page is drawn from.
  ///
  /// Defaults to the capture itself, so every caller that never enhanced
  /// anything — imports, previews, tests — keeps working untouched.
  final PageImageResolver resolveImage;

  /// Composes [pages] into a PDF at [destinationPath].
  ///
  /// Attaches an invisible text layer wherever recognition has produced one.
  /// A page with no recognised text simply gets no layer: the spec states
  /// outright that a PDF must still be produced when OCR is unavailable, so a
  /// text lookup that fails degrades to an unsearchable document rather than
  /// to no document at all.
  Future<Result<ComposedPdf>> call(
    List<PageRef> pages, {
    required String destinationPath,
    PdfQuality quality = PdfQuality.defaultQuality,
    CancellationToken? token,
  }) async {
    if (token?.isCancelled ?? false) {
      return const Result<ComposedPdf>.failure(Failure.cancelled());
    }

    Map<String, RecognisedText> texts;
    try {
      texts = await _textFor([for (final page in pages) page.id]);
    } on Object {
      texts = const {};
    }

    // Checked again after the lookup: it is the last point before composition
    // begins, and composition is the expensive part.
    if (token?.isCancelled ?? false) {
      return const Result<ComposedPdf>.failure(Failure.cancelled());
    }

    // Resolved before composing, because the settings the user chose are stored
    // against the page rather than baked into the file it points at. Composing
    // straight from `imagePath` drew the unenhanced capture — the saved
    // document did not match the preview the settings were chosen from.
    //
    // Rendered at the size the page will be drawn at, not at the capture's:
    // composition caps every page at the quality setting, so filtering the full
    // capture would do several times the work and then discard most of it.
    final drawable = <PageRef>[];
    for (final page in pages) {
      if (token?.isCancelled ?? false) {
        return const Result<ComposedPdf>.failure(Failure.cancelled());
      }

      final path = await resolveImage(
        page,
        maxDimension: quality.maxDimension,
      );
      drawable.add(page.copyWith(imagePath: path));
    }

    return _composer.compose(
      PdfBuildRequest(
        pages: PdfComposition.specsFor(drawable, texts),
        destinationPath: destinationPath,
        quality: quality,
      ),
    );
  }
}

/// Creates a stored document from a bundle of captured or imported pages.
///
/// The whole point of this use case is the ordering. The PDF is composed first
/// and the record written only once the file exists, so a failure cannot leave
/// a document the user can see but not open. If the record write then fails,
/// the PDF is deleted — an orphaned file in app-private storage is invisible
/// and permanent, which is worse than none.
class SaveDocument {
  /// Creates the use case.
  const SaveDocument(
    this._build,
    this._writer,
    this._clock,
    this._ids,
    this._destinationFor,
    this._deleteFile,
  );

  final BuildSearchablePdf _build;
  final DocumentWriter _writer;
  final Clock _clock;
  final IdGenerator _ids;
  final PdfDestination _destinationFor;
  final Future<void> Function(String path) _deleteFile;

  /// Saves [bundle] as a document titled [title].
  ///
  /// [documentId] is supplied when the caller has already had to know the
  /// identity — recognition has to file its results against a document before
  /// composition reads them back, so the sink generates the id and passes it
  /// here rather than letting two places invent one.
  Future<Result<Document>> call(
    ScannedPageBundle bundle, {
    required String title,
    PdfQuality quality = PdfQuality.defaultQuality,
    FolderId? folderId,
    CancellationToken? token,
    DocumentId? documentId,
  }) async {
    if (!bundle.canCreateDocument) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.documentWouldHaveNoPages),
      );
    }

    final id = documentId ?? DocumentId(_ids.generate());
    final destination = _destinationFor(id);

    final composed = await _build(
      bundle.pages,
      destinationPath: destination,
      quality: quality,
      token: token,
    );

    return composed.flatMapAsync((pdf) async {
      // Cancelled after composition but before the record exists: the file is
      // removed so no orphan survives, and no partial record is ever created.
      if (token?.isCancelled ?? false) {
        await _deleteFile(pdf.filePath);
        return const Result<Document>.failure(Failure.cancelled());
      }

      final now = _clock.now().toUtc();

      final document = Document(
        id: id,
        title: title,
        createdAt: now,
        updatedAt: now,
        pageCount: pdf.pageCount,
        sizeInBytes: pdf.sizeInBytes,
        filePath: pdf.filePath,
        folderId: folderId,
        // Taken from what was actually composed rather than from whether
        // recognition was attempted: a run that produced no legible text
        // leaves a document with nothing to share, and offering "share
        // extracted text" for it would be an option that does nothing.
        hasRecognisedText: pdf.hasTextLayer,
      );

      final pages = [
        for (var index = 0; index < bundle.pages.length; index++)
          DocumentPage(
            id: bundle.pages[index].id,
            documentId: id,
            order: index,
            imagePath: bundle.pages[index].imagePath,
            rotation: bundle.pages[index].rotation,
            enhancement: bundle.pages[index].enhancement,
          ),
      ];

      final saved = await _writer.save(document, pages);

      if (saved case Failed()) {
        // The PDF exists but nothing references it. An orphaned file in
        // app-private storage is invisible to the user and never reclaimed, so
        // it goes with the failed record.
        await _deleteFile(pdf.filePath);
      }

      return saved;
    });
  }
}

/// Turns captured or imported pages into a stored document.
///
/// Implements the shared [PageBundleSink] contract so `document-scanning` and
/// `document-import` can create documents without importing `pdf-generation`
/// (`design.md` §2).
class PageBundleSinkImpl implements PageBundleSink {
  /// Creates the sink.
  ///
  /// [_recognise] runs text recognition over the bundle's pages *before*
  /// composition, which is what makes the resulting PDF searchable — the
  /// composer reads recognised text from the store, so text recognised after
  /// the fact would never reach the file. Injected as a function rather than
  /// taken as the OCR use case, because a feature may not import another
  /// feature (`design.md` §2).
  const PageBundleSinkImpl(
    this._save,
    this._name,
    this._patternFor,
    this._recognise,
    this._ids,
  );

  final SaveDocument _save;
  final GenerateDocumentName _name;
  final NamingPattern Function() _patternFor;
  final RecognisePages _recognise;
  final IdGenerator _ids;

  @override
  Future<Result<Document>> createDocument(
    ScannedPageBundle bundle, {
    String? title,
  }) async {
    final resolved = await _name(
      _patternFor(),
      suggested: bundle.suggestedTitle,
      entered: title,
    );

    // The identity is settled here, because recognition files its results
    // against a document and composition then reads them back by page.
    final documentId = DocumentId(_ids.generate());

    // Awaited, and its failure ignored. The spec is explicit that a PDF must
    // still be produced when recognition is unavailable, so a failed run
    // degrades to an unsearchable document rather than to no document.
    await _recognise(bundle.pages, documentId);

    return _save(bundle, title: resolved, documentId: documentId);
  }
}

/// Runs text recognition over [pages], storing whatever it finds.
///
/// Returns nothing: the caller does not act on the outcome, because a document
/// is created either way. What matters is that the recognised text is in the
/// store before composition reads it.
typedef RecognisePages =
    Future<void> Function(List<PageRef> pages, DocumentId documentId);
