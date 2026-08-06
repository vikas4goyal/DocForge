/// Use cases for sharing, printing and exporting a document.
///
/// The rule these all obey: the file of record is never handed out or moved.
/// A PDF share attaches the stored file, an image share renders *copies* into a
/// staging directory, and an export writes a *copy* to the chosen destination.
/// Nothing here mutates the document.
///
/// The password of a protected document is never read by any of these. A
/// protected PDF is protected in the bytes on disk, so sharing the file shares
/// the protection and nothing else — which is exactly what the spec requires,
/// and it is achieved by not going near secure storage rather than by
/// remembering to strip something.
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/features/document_sharing/domain/document_export_result.dart';
import 'package:doc_scanly/features/document_sharing/domain/repositories/share_repository.dart';
import 'package:doc_scanly/features/document_sharing/domain/share_content.dart';

/// Decides where content staged for sharing is written.
///
/// Injected because a use case may not perform an ambient path lookup, and
/// because a test needs the staging directory to be a temporary one it can
/// delete afterwards.
typedef ShareStagingDirectory = Directory Function();

/// Something that happened while content was being prepared.
sealed class SharePreparationEvent {
  const SharePreparationEvent();
}

/// Progress towards having everything ready.
class SharePreparationProgress extends SharePreparationEvent {
  /// Creates a progress event.
  const SharePreparationProgress(this.progress);

  /// How far preparation has got.
  final Progress progress;
}

/// Preparation finished and the content is ready to hand over.
class SharePreparationReady extends SharePreparationEvent {
  /// Creates a ready event carrying [payload].
  const SharePreparationReady(this.payload);

  /// What is ready to be shared.
  final SharePayload payload;
}

/// Preparation failed.
class SharePreparationFailed extends SharePreparationEvent {
  /// Creates a failure event.
  const SharePreparationFailed(this.failure);

  /// Why preparation could not finish.
  final Failure failure;
}

/// Shares a document's stored PDF.
///
/// Nothing is prepared: the stored file *is* what is shared, which is both the
/// fastest path and the one that cannot accidentally strip protection.
class ShareDocumentPdf {
  /// Creates the use case.
  const ShareDocumentPdf(this._documents, this._share, this._files);

  final DocumentReader _documents;
  final ShareRepository _share;
  final DocumentFileResolver _files;

  /// Shares the PDF of [documentId].
  Future<Result<void>> call(DocumentId documentId) async {
    final found = await _documents.findById(documentId);

    if (found case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    final document = found.valueOrNull!;

    // Resolved rather than read off the record: the file lives in the user's
    // own folder now, so "missing" is an ordinary outcome — they can delete it
    // from the file browser while the app is open.
    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    return _share.share(
      SharePayload(
        filePaths: [resolved.valueOrNull!],
        subject: ShareRules.subjectFor(document),
      ),
    );
  }
}

/// Renders selected pages as images and shares them.
///
/// A stream rather than a future because a long document has to report progress
/// and be cancellable, which the performance requirement states explicitly.
class SharePageImages {
  /// Creates the use case.
  ///
  /// [_job] is passed in rather than imported: the renderer lives in
  /// infrastructure, and the application layer may not depend on it
  /// (`design.md` §2). The composition root supplies the real one; a test
  /// supplies a job that fails on demand.
  const SharePageImages(
    this._documents,
    this._share,
    this._worker,
    this._staging,
    this._job, [
    this._pageAccess,
  ]);

  final DocumentReader _documents;
  final ShareRepository _share;
  final BackgroundWorker _worker;
  final ShareStagingDirectory _staging;
  final IsolateJob<SharePageRequest, String> _job;
  final DocumentPageAccessRepository? _pageAccess;

  /// Prepares and shares the pages of [documentId] identified by [pageIds].
  ///
  /// An empty [pageIds] means every page. Emits progress per page, then either
  /// [SharePreparationReady] once the share sheet has been handed the images,
  /// or [SharePreparationFailed].
  Stream<SharePreparationEvent> call(
    DocumentId documentId, {
    List<PageId> pageIds = const [],
    CancellationToken? token,
  }) async* {
    final found = await _documents.findById(documentId);
    if (found case Failed(:final failure)) {
      yield SharePreparationFailed(failure);
      return;
    }
    final document = found.valueOrNull!;

    final pageAccess = _pageAccess;
    if (pageAccess != null) {
      final handles = await pageAccess.pagesOf(document);
      if (handles case Failed(:final failure)) {
        yield SharePreparationFailed(failure);
        return;
      }
      final available = handles.valueOrNull!;
      // Stored scan rows retain rotation/enhancement metadata in the existing
      // worker path. PDF-only imports have no such rows and materialise through
      // the shared page contract instead.
      if (available.any((page) => page.source is PdfDocumentPageSource)) {
        yield* _sharePdfBackedPages(
          document,
          available,
          pageIds: pageIds,
          token: token,
          access: pageAccess,
        );
        return;
      }
    }

    final loaded = await _documents.pagesOf(documentId);
    if (loaded case Failed(:final failure)) {
      yield SharePreparationFailed(failure);
      return;
    }

    final selected = pageIds.isEmpty
        ? loaded.valueOrNull!
        : [
            for (final page in loaded.valueOrNull!)
              if (pageIds.contains(page.id)) page,
          ];

    if (selected.isEmpty) {
      yield const SharePreparationFailed(
        Failure.notFound(debugDetail: 'no pages selected'),
      );
      return;
    }

    // Sorted here rather than trusted from the caller: the selection arrives in
    // tap order, and the spec requires page order.
    final ordered = ShareRules.inPageOrder(selected);
    final directory = _staging();

    final requests = [
      for (final page in ordered)
        SharePageRequest(
          page: PageRef(
            id: page.id,
            imagePath: page.imagePath,
            rotation: page.rotation,
            enhancement: page.enhancement,
          ),
          destinationPath:
              '${directory.path}/'
              '${ShareRules.imageFileName(document.title, page.pageNumber)}',
          quality: ShareRules.imageQuality,
        ),
    ];

    final rendered = <String>[];

    await for (final event in _worker.runBatch(_job, requests, token: token)) {
      switch (event) {
        case BatchItemCompleted(:final value, :final progress):
          rendered.add(value);
          yield SharePreparationProgress(progress);
        case BatchItemFailed(:final failure):
          // Every image already written is removed. A partial set handed to the
          // share sheet would look like the document lost pages.
          _discard(rendered);
          yield SharePreparationFailed(failure);
          return;
        case BatchCancelled():
          _discard(rendered);
          yield const SharePreparationFailed(Failure.cancelled());
          return;
      }
    }

    final payload = SharePayload(
      filePaths: rendered,
      subject: ShareRules.subjectFor(document),
    );

    final result = await _share.share(payload);

    yield switch (result) {
      Success() => SharePreparationReady(payload),
      Failed(:final failure) => SharePreparationFailed(failure),
    };
  }

  Stream<SharePreparationEvent> _sharePdfBackedPages(
    Document document,
    List<DocumentPageHandle> pages, {
    required List<PageId> pageIds,
    required CancellationToken? token,
    required DocumentPageAccessRepository access,
  }) async* {
    final selected = pageIds.isEmpty
        ? pages
        : [
            for (final page in pages)
              if (pageIds.contains(page.id)) page,
          ];
    if (selected.isEmpty) {
      yield const SharePreparationFailed(
        Failure.notFound(debugDetail: 'no pages selected'),
      );
      return;
    }
    final ordered = [...selected]
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    final materialized = <MaterializedDocumentPage>[];
    try {
      for (var index = 0; index < ordered.length; index++) {
        if (token?.isCancelled ?? false) {
          yield const SharePreparationFailed(Failure.cancelled());
          return;
        }
        final rendered = await access.materialize(
          document,
          ordered[index],
          DocumentPageRenderPurpose.sharing,
        );
        if (rendered case Failed(:final failure)) {
          yield SharePreparationFailed(failure);
          return;
        }
        materialized.add(rendered.valueOrNull!);
        yield SharePreparationProgress(
          Progress(completed: index + 1, total: ordered.length),
        );
      }
      final payload = SharePayload(
        filePaths: [for (final page in materialized) page.path],
        subject: ShareRules.subjectFor(document),
      );
      final shared = await _share.share(payload);
      yield switch (shared) {
        Success() => SharePreparationReady(payload),
        Failed(:final failure) => SharePreparationFailed(failure),
      };
    } finally {
      // The share repository returns after the platform has accepted the
      // handoff, so temporary renders can now be reclaimed safely.
      for (final page in materialized) {
        await access.release(page);
      }
    }
  }

  /// Removes staged files after a failure or cancellation.
  ///
  /// Best-effort: a staging file that cannot be deleted is in the cache, which
  /// the operating system reclaims anyway, and failing the share over it would
  /// replace a recoverable situation with an error.
  void _discard(List<String> paths) {
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } on Object {
          // Deliberately ignored; see above.
        }
      }
    }
  }
}

/// Shares a document's recognised text.
class ShareExtractedText {
  /// Creates the use case.
  const ShareExtractedText(this._documents, this._text, this._share);

  final DocumentReader _documents;
  final OcrTextSource _text;
  final ShareRepository _share;

  /// Shares the recognised text of [documentId].
  ///
  /// Fails with a not-found failure when the document has no recognised text,
  /// which the UI prevents by disabling the control — this is the second line
  /// of defence rather than the first.
  Future<Result<void>> call(DocumentId documentId) async {
    final found = await _documents.findById(documentId);
    if (found case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final document = found.valueOrNull!;

    final text = await _text.textForDocument(documentId);
    if (text case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    final content = text.valueOrNull ?? '';

    if (!ShareRules.canShareText(document, content)) {
      return const Result<void>.failure(
        Failure.notFound(debugDetail: 'no recognised text'),
      );
    }

    return _share.share(
      SharePayload(text: content, subject: ShareRules.subjectFor(document)),
    );
  }
}

/// Prints a document through the system print flow.
class PrintDocument {
  /// Creates the use case.
  const PrintDocument(this._documents, this._printer, this._files);

  final DocumentReader _documents;
  final PrintRepository _printer;
  final DocumentFileResolver _files;

  /// Prints [documentId].
  ///
  /// Returns false when the user dismissed the print dialogue, which is a
  /// successful outcome with nothing to say about it.
  Future<Result<bool>> call(DocumentId documentId) async {
    final found = await _documents.findById(documentId);
    if (found case Failed(:final failure)) {
      return Result<bool>.failure(failure);
    }
    final document = found.valueOrNull!;

    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<bool>.failure(failure);
    }

    return _printer.printFile(
      resolved.valueOrNull!,
      jobName: ShareRules.sanitise(document.title),
    );
  }
}

/// Exports a document's PDF to a destination the user chooses.
class ExportDocument {
  /// Creates the use case.
  const ExportDocument(this._documents, this._exporter, this._files);

  final DocumentReader _documents;
  final ExportDocumentRepository _exporter;
  final DocumentFileResolver _files;

  /// Exports [documentId], asking the user where it should go.
  ///
  /// Returns a platform-owned completed or cancelled result. The exporter owns
  /// the provider write; this use case never treats an opaque provider value as
  /// a local path or creates an application-managed `.partial` sibling.
  ///
  /// [initialDirectory] is the configured default save location, when set.
  Future<Result<DocumentExportResult>> call(
    DocumentId documentId, {
    String? initialDirectory,
  }) async {
    final found = await _documents.findById(documentId);
    if (found case Failed(:final failure)) {
      return Result<DocumentExportResult>.failure(failure);
    }
    final document = found.valueOrNull!;

    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<DocumentExportResult>.failure(failure);
    }
    return _exporter.export(
      sourcePath: resolved.valueOrNull!,
      suggestedName: ShareRules.pdfFileName(document.title),
      initialDirectory: initialDirectory,
    );
  }
}
