/// Constructs the import object graph.
///
/// Also the one place the viewer's PDF renderer is adapted into the inspector
/// the import feature declares. Neither feature imports the other; the
/// composition root joins them, which is what the layering rule requires
/// (`design.md` §2).
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_forge/features/document_import/domain/import_rules.dart';
import 'package:doc_forge/features/document_import/domain/repositories/import_repository.dart';
import 'package:doc_forge/features/document_import/infrastructure/import_job.dart';
import 'package:doc_forge/features/document_import/infrastructure/repositories/platform_import_sources.dart';
import 'package:doc_forge/features/document_viewer/domain/repositories/pdf_renderer.dart';

/// Adapts a [PdfRenderer] into the [ImportedPdfInspector] import declares.
///
/// The two contracts ask the same question — how many pages, and does it need a
/// password — of the same file. Rather than a second PDF library, import
/// borrows the viewer's through this adapter, which lives here because a
/// feature may not import another feature.
class RendererPdfInspector implements ImportedPdfInspector {
  /// Creates the adapter over [_renderer].
  const RendererPdfInspector(this._renderer);

  final PdfRenderer _renderer;

  @override
  Future<Result<int>> pageCountOf(String filePath, {String? password}) async {
    final opened = await _renderer.open(filePath, password: password);

    // `map` rather than a switch: the failure passes through untouched, which
    // matters because the import flow distinguishes an authentication failure
    // (prompt for a password) from a corrupt file (refuse the import).
    return opened.map((document) => document.pageCount);
  }
}

/// Everything the import feature exposes to the rest of the application.
class ImportModule {
  /// Creates the module over an already-built object graph.
  const ImportModule({
    required this.gallery,
    required this.files,
    required this.shared,
    required this.importFiles,
    required this.takePending,
    required this.watchShared,
  });

  /// The photo library picker.
  final GalleryPicker gallery;

  /// The device file browser.
  final FileBrowser files;

  /// Content handed over by other applications.
  final SharedContentSource shared;

  /// Imports a mixed selection from any source.
  final ImportFiles importFiles;

  /// Reads content shared before the application finished launching.
  final TakePendingSharedContent takePending;

  /// Watches for content shared while the application runs.
  final WatchSharedContent watchShared;
}

/// Builds the import module.
///
/// [documentsDirectory] is where an imported PDF is stored permanently and
/// [cacheDirectory] is where imported images are staged until the review step
/// turns them into a document. The split matters: a staged image that is never
/// reviewed is disposable, and a stored PDF is not.
ImportModule buildImportModule({
  required PdfRenderer renderer,
  required DocumentWriter documentWriter,
  required Directory documentsDirectory,
  required Directory cacheDirectory,
  required Clock clock,
  required IdGenerator ids,
  BackgroundWorker worker = const IsolateBackgroundWorker(),
  GalleryPicker gallery = const SystemGalleryPicker(),
  FileBrowser files = const SystemFileBrowser(),
  SharedContentSource? shared,
}) {
  Directory staging() {
    final directory = Directory(
      '${cacheDirectory.path}/${ImportRules.stagingDirectoryName}',
    );
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return directory;
  }

  final source = shared ?? SystemSharedContentSource();

  return ImportModule(
    gallery: gallery,
    files: files,
    shared: source,
    importFiles: ImportFiles(
      ImportImages(worker, staging, ids, copyImportedFileJob),
      ImportPdf(
        RendererPdfInspector(renderer),
        documentWriter,
        (id) => '${documentsDirectory.path}/${id.value}.pdf',
        clock,
        ids,
      ),
    ),
    takePending: TakePendingSharedContent(source),
    watchShared: WatchSharedContent(source),
  );
}
