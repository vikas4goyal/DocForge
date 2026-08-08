/// Constructs the PDF-generation object graph.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/contracts/page_renderer.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_scanly/features/pdf_generation/infrastructure/generated_pdf_candidate_repository.dart';
import 'package:doc_scanly/features/pdf_generation/infrastructure/pdf_composer.dart';

/// Everything PDF generation needs, built once.
class DocumentCreationModule {
  /// Creates the module.
  const DocumentCreationModule({
    required this.saveDocument,
    required this.generateName,
    required this.pageBundleSink,
    required this.candidateRepository,
  });

  /// Composes a PDF and creates the document record.
  final SaveDocument saveDocument;

  /// Expands the configured naming pattern.
  final GenerateDocumentName generateName;

  /// Turns captured or imported pages into a stored document.
  final PageBundleSink pageBundleSink;

  /// Creates one candidate repository per Save route.
  ///
  /// Route scope bounds ownership to one retained candidate and prevents two
  /// screens from cancelling or discarding one another's temporary output.
  final GeneratedPdfCandidateRepository Function() candidateRepository;
}

/// Builds the graph over [publicStore].
DocumentCreationModule buildDocumentCreationModule({
  required Directory workingDirectory,
  required PublicFileStore publicStore,
  required PdfProtector protectPdf,
  GeneratedPdfPageCounter? candidatePageCountOf,
  required Clock clock,
  required IdGenerator ids,
  required DocumentReader documentReader,
  required DocumentWriter documentWriter,
  required NamingPattern Function() namingPattern,
  ApplyEnhancement? applyEnhancement,
  PageRenderer? renderPage,
  PdfComposer? composer,
  AppTelemetry telemetry = const NoopAppTelemetry(),
}) {
  if (applyEnhancement == null && renderPage == null) {
    throw ArgumentError('applyEnhancement or renderPage must be supplied');
  }
  Future<String> resolvePageImage(
    PageRef page, {
    required int maxDimension,
  }) async {
    if (!EnhancementRules.requiresProcessing(page.enhancement)) {
      return page.imagePath;
    }

    if (renderPage case final renderer?) {
      final rendered = await renderer(
        PageRenderPlan(
          originalImagePath: page.imagePath,
          geometry: const [],
          enhancement: page.enhancement,
          scale: RenderScale.full,
        ),
      );
      return rendered.valueOrNull ?? page.imagePath;
    }

    final result = await applyEnhancement!.single(
      sourcePath: page.imagePath,
      destinationPath: '${page.imagePath}.composed.jpg',
      settings: page.enhancement,
      maxDimension: maxDimension,
    );
    return result.valueOrNull ?? page.imagePath;
  }

  final save = SaveDocument(
    BuildSearchablePdf(
      composer ?? IsolatePdfComposer(telemetry: telemetry),
      (_) async => const {},
      resolveImage: resolvePageImage,
    ),
    documentWriter,
    clock,
    ids,
    (id) => '${workingDirectory.path}/${id.value}.pdf',
    (path) async {
      final file = File(path);
      if (file.existsSync()) {
        try {
          await file.delete();
        } on FileSystemException {
          // Temporary-file cleanup is best effort.
        }
      }
    },
    publicStore,
    protectPdf,
  );

  final generateName = GenerateDocumentName(clock, documentReader);
  return DocumentCreationModule(
    saveDocument: save,
    generateName: generateName,
    pageBundleSink: PageBundleSinkImpl(save, generateName, namingPattern),
    candidateRepository: () => IsolateGeneratedPdfCandidateRepository(
      workingDirectory: workingDirectory,
      ids: ids,
      pageCountOf:
          candidatePageCountOf ??
          (path, {password}) async => const Result<int>.failure(
            Failure.pdf(debugDetail: 'candidate verification unavailable'),
          ),
      protect: protectPdf,
    ),
  );
}
