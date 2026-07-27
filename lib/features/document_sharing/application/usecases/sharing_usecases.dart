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

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_forge/features/document_sharing/domain/repositories/share_repository.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';

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
    this._job,
  );

  final DocumentReader _documents;
  final ShareRepository _share;
  final BackgroundWorker _worker;
  final ShareStagingDirectory _staging;
  final IsolateJob<SharePageRequest, String> _job;

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
  const ExportDocument(this._documents, this._picker, this._files);

  final DocumentReader _documents;
  final ExportDestinationPicker _picker;
  final DocumentFileResolver _files;

  /// Exports [documentId], asking the user where it should go.
  ///
  /// Returns the destination path, or null when the picker was cancelled — in
  /// which case nothing has been written, which the spec requires explicitly.
  ///
  /// [initialDirectory] is the configured default save location, when set.
  Future<Result<String?>> call(
    DocumentId documentId, {
    String? initialDirectory,
  }) async {
    final found = await _documents.findById(documentId);
    if (found case Failed(:final failure)) {
      return Result<String?>.failure(failure);
    }
    final document = found.valueOrNull!;

    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<String?>.failure(failure);
    }
    final source = File(resolved.valueOrNull!);

    final chosen = await _picker.chooseDestination(
      suggestedName: ShareRules.pdfFileName(document.title),
      initialDirectory: initialDirectory,
    );
    if (chosen case Failed(:final failure)) {
      return Result<String?>.failure(failure);
    }

    final destination = chosen.valueOrNull;
    if (destination == null) {
      // Cancelled. Nothing was written and nothing is said.
      return const Result<String?>.success(null);
    }

    return _copyTo(source, destination);
  }

  /// Copies [source] to [destination], leaving nothing behind on failure.
  ///
  /// Written to a temporary sibling and renamed into place, so a failure
  /// part-way — the device filling up is the case the spec names — cannot leave
  /// a truncated file where the user expects their document.
  Future<Result<String?>> _copyTo(File source, String destination) async {
    final temporary = File('$destination.partial');

    try {
      await source.copy(temporary.path);
      final written = await temporary.rename(destination);
      return Result<String?>.success(written.path);
    } on FileSystemException catch (error) {
      if (temporary.existsSync()) temporary.deleteSync();

      // errno 28 is ENOSPC on both platforms. The distinction matters because
      // "the device is full" has a different recovery from "that location is
      // not writable".
      return Result<String?>.failure(
        error.osError?.errorCode == 28
            ? Failure.storageFull(debugDetail: '$error')
            : Failure.export(debugDetail: '$error'),
      );
    } on Object catch (error) {
      if (temporary.existsSync()) temporary.deleteSync();
      return Result<String?>.failure(Failure.export(debugDetail: '$error'));
    }
  }
}
