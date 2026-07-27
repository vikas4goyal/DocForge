/// Use cases for importing content into the library.
///
/// Two shapes, because imported content arrives in two shapes and the specs
/// treat them differently:
///
/// * **Images** become pages of a *new* document and are handed to the review
///   step, so cropping and enhancement can be applied before anything is saved.
/// * **A PDF** is already a document. It is copied into app-private storage and
///   a record is created directly, with the page count read from the file.
///
/// The rule both obey: no document record exists until its file is in place and
/// readable, and nothing partial survives a failure or a cancellation.
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_import/domain/import_rules.dart';
import 'package:doc_forge/features/document_import/domain/repositories/import_repository.dart';

/// Decides where imported content is copied to.
///
/// Injected because a use case may not perform an ambient path lookup, and
/// because a test needs a temporary directory it can delete afterwards.
typedef ImportStagingDirectory = Directory Function();

/// Decides where an imported PDF is stored permanently.
typedef ImportedPdfDestination = String Function(DocumentId id);

/// A request to copy one selected file into app-private storage.
///
/// Only paths cross the isolate boundary — never file contents (`design.md`
/// §7).
class CopyImportRequest {
  /// Creates a request to copy [sourcePath] to [destinationPath].
  const CopyImportRequest({
    required this.sourcePath,
    required this.destinationPath,
  });

  /// Where the file is now.
  final String sourcePath;

  /// Where it is to be copied.
  final String destinationPath;
}

/// Something that happened while an import ran.
sealed class ImportEvent {
  const ImportEvent();
}

/// Progress through a batch of files.
class ImportProgressed extends ImportEvent {
  /// Creates a progress event.
  const ImportProgressed(this.progress);

  /// How far the import has got.
  final Progress progress;
}

/// Images were copied and are ready for the review step.
///
/// Not yet a document: the spec requires the user to reach review, where
/// cropping and enhancement can be applied, before anything is saved.
class ImportReadyForReview extends ImportEvent {
  /// Creates a ready event carrying [bundle].
  const ImportReadyForReview(this.bundle);

  /// The pages awaiting review.
  final ScannedPageBundle bundle;
}

/// A PDF was imported and its document record created.
class ImportedDocument extends ImportEvent {
  /// Creates an imported-document event.
  const ImportedDocument(this.document);

  /// The document now in the library.
  final Document document;
}

/// The imported PDF needs a password before it can be read.
class ImportNeedsPassword extends ImportEvent {
  /// Creates a password-needed event for the file at [sourcePath].
  const ImportNeedsPassword(this.sourcePath);

  /// The file awaiting a password.
  final String sourcePath;
}

/// The import could not be completed.
class ImportFailed extends ImportEvent {
  /// Creates a failure event.
  const ImportFailed(this.failure);

  /// Why the import stopped.
  final Failure failure;
}

/// Copies selected images into staging and prepares them for review.
class ImportImages {
  /// Creates the use case.
  ///
  /// [_job] is injected rather than imported because the copier lives in
  /// infrastructure and the application layer may not depend on it
  /// (`design.md` §2).
  const ImportImages(this._worker, this._staging, this._ids, this._job);

  final BackgroundWorker _worker;
  final ImportStagingDirectory _staging;
  final IdGenerator _ids;
  final IsolateJob<CopyImportRequest, String> _job;

  /// Copies [paths] and emits a bundle ready for review.
  ///
  /// [source] records where the content came from, which the bundle carries so
  /// the finished document knows it was imported rather than scanned.
  Stream<ImportEvent> call(
    List<String> paths, {
    required ImportSource source,
    CancellationToken? token,
  }) async* {
    final candidates = ImportRules.classify(
      paths,
    ).where((candidate) => candidate.kind == ImportedFileKind.image).toList();

    if (candidates.isEmpty) {
      yield const ImportFailed(Failure.import(unsupportedType: true));
      return;
    }

    final directory = _staging();
    final requests = <CopyImportRequest>[];
    final ids = <PageId>[];

    for (final candidate in candidates) {
      final id = PageId(_ids.generate());
      ids.add(id);
      requests.add(
        CopyImportRequest(
          sourcePath: candidate.path,
          // The extension is preserved so a decoder downstream can still tell
          // what it is looking at.
          destinationPath:
              '${directory.path}/${id.value}.'
              '${ImportRules.extensionOf(candidate.path)}',
        ),
      );
    }

    final copied = <String>[];

    await for (final event in _worker.runBatch(_job, requests, token: token)) {
      switch (event) {
        case BatchItemCompleted(:final value, :final progress):
          copied.add(value);
          yield ImportProgressed(progress);
        case BatchItemFailed(:final failure):
          _discard(copied);
          yield ImportFailed(failure);
          return;
        case BatchCancelled():
          // No orphaned file survives a cancellation, which the spec requires
          // explicitly.
          _discard(copied);
          yield const ImportFailed(Failure.cancelled());
          return;
      }
    }

    yield ImportReadyForReview(
      ScannedPageBundle(
        pages: [
          for (var index = 0; index < copied.length; index++)
            PageRef(id: ids[index], imagePath: copied[index]),
        ],
        source: source.pageSource,
        // Only a single file's name is a useful title. A batch of twelve photos
        // named after the first one would be misleading.
        suggestedTitle: copied.length == 1
            ? ImportRules.suggestedTitle(candidates.first.path)
            : null,
      ),
    );
  }

  /// Removes copies made before a failure or cancellation.
  void _discard(List<String> paths) {
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } on Object {
          // Best-effort: a staging file that cannot be deleted lives in
          // app-private storage and is cleaned up on the next import, and
          // failing the import over it would be worse than leaving it.
        }
      }
    }
  }
}

/// Copies an imported PDF into storage and creates its document record.
class ImportPdf {
  /// Creates the use case.
  const ImportPdf(
    this._inspector,
    this._writer,
    this._destination,
    this._clock,
    this._ids,
  );

  final ImportedPdfInspector _inspector;
  final DocumentWriter _writer;
  final ImportedPdfDestination _destination;
  final Clock _clock;
  final IdGenerator _ids;

  /// Imports the PDF at [sourcePath].
  ///
  /// [password] is supplied on a second attempt, after the first reported that
  /// the file is protected.
  ///
  /// The order is deliberate and is the guarantee this use case exists to make:
  /// the file is copied first, read second, and the record written last. A
  /// record is never created for a file that is not there or cannot be opened,
  /// and a copy that fails inspection is deleted rather than left orphaned.
  Future<Result<Document>> call(String sourcePath, {String? password}) async {
    if (ImportRules.kindFor(sourcePath) != ImportedFileKind.pdf) {
      return const Result<Document>.failure(
        Failure.import(unsupportedType: true),
      );
    }

    final source = File(sourcePath);
    if (!source.existsSync()) {
      return const Result<Document>.failure(Failure.notFound());
    }

    final id = DocumentId(_ids.generate());
    final destination = File(_destination(id));
    final temporary = File('${destination.path}.partial');

    try {
      temporary.parent.createSync(recursive: true);
      await source.copy(temporary.path);
    } on FileSystemException catch (error) {
      if (temporary.existsSync()) temporary.deleteSync();
      return Result<Document>.failure(_fileFailure(error));
    }

    // Inspected while still under its temporary name, so a file that turns out
    // to be unreadable never occupies the name a real document would.
    final inspected = await _inspector.pageCountOf(
      temporary.path,
      password: password,
    );

    if (inspected case Failed(:final failure)) {
      if (temporary.existsSync()) temporary.deleteSync();
      return Result<Document>.failure(failure);
    }

    final File stored;
    try {
      stored = temporary.renameSync(destination.path);
    } on FileSystemException catch (error) {
      if (temporary.existsSync()) temporary.deleteSync();
      return Result<Document>.failure(_fileFailure(error));
    }

    final now = _clock.now();
    final document = Document(
      id: id,
      title: ImportRules.suggestedTitle(sourcePath) ?? 'Document',
      createdAt: now,
      updatedAt: now,
      pageCount: inspected.valueOrNull!,
      // Measured from the stored file rather than the source, so the figure on
      // the record is what the filesystem actually reports.
      sizeInBytes: stored.lengthSync(),
      filePath: stored.path,
      isProtected: password != null,
    );

    // An imported PDF has no page images, so no page records are written. The
    // viewer renders from the file itself, and OCR runs on demand.
    final saved = await _writer.save(document, const []);

    if (saved case Failed(:final failure)) {
      // The record is the thing that makes a file a document. Without one the
      // file is unreachable, so it is removed rather than left orphaned.
      if (stored.existsSync()) stored.deleteSync();
      return Result<Document>.failure(failure);
    }

    return saved;
  }

  /// Maps a filesystem error onto the failure the user can act on.
  ///
  /// errno 28 is ENOSPC on both platforms, and "the device is full" has a
  /// different recovery from "that file could not be read".
  Failure _fileFailure(FileSystemException error) =>
      error.osError?.errorCode == 28
      ? Failure.storageFull(debugDetail: '$error')
      : Failure.import(debugDetail: '$error');
}

/// Imports a mixed selection of files from any source.
///
/// The one entry point the UI uses, because a selection from the file browser
/// or the share sheet may contain both kinds and the user should not have to
/// separate them.
class ImportFiles {
  /// Creates the use case.
  const ImportFiles(this._images, this._pdf);

  final ImportImages _images;
  final ImportPdf _pdf;

  /// Imports [paths], emitting one event per outcome.
  ///
  /// PDFs are imported first and each produces a document immediately; the
  /// images that remain are gathered into a single bundle for review. That
  /// split is what makes a mixed selection behave the way each half of the spec
  /// describes, rather than forcing one rule onto both.
  Stream<ImportEvent> call(
    List<String> paths, {
    required ImportSource source,
    CancellationToken? token,
    String? password,
  }) async* {
    final candidates = ImportRules.classify(paths);

    if (!ImportRules.hasAnythingToImport(candidates)) {
      yield const ImportFailed(Failure.import(unsupportedType: true));
      return;
    }

    final pdfs = [
      for (final candidate in candidates)
        if (candidate.kind == ImportedFileKind.pdf) candidate.path,
    ];
    final images = [
      for (final candidate in candidates)
        if (candidate.kind == ImportedFileKind.image) candidate.path,
    ];

    for (final path in pdfs) {
      if (token?.isCancelled ?? false) {
        yield const ImportFailed(Failure.cancelled());
        return;
      }

      final result = await _pdf(path, password: password);

      switch (result) {
        case Success(:final value):
          yield ImportedDocument(value);
        case Failed(:final failure):
          // A protected PDF is not an error: the prompt is the normal path for
          // one, and an error view would suggest something had gone wrong.
          yield failure is AuthFailure
              ? ImportNeedsPassword(path)
              : ImportFailed(failure);
          return;
      }
    }

    if (images.isEmpty) return;

    yield* _images(images, source: source, token: token);
  }
}

/// Reads content shared to DocForge while it was closed.
class TakePendingSharedContent {
  /// Creates the use case.
  const TakePendingSharedContent(this._source);

  final SharedContentSource _source;

  /// Returns the paths waiting from a cold-launch share.
  ///
  /// An empty list when the application was opened normally, which is the
  /// common case and is not a failure.
  Future<List<String>> call() async {
    final result = await _source.pending();
    return result.valueOrNull ?? const [];
  }
}

/// Watches for content shared while DocForge is running.
class WatchSharedContent {
  /// Creates the use case.
  const WatchSharedContent(this._source);

  final SharedContentSource _source;

  /// Emits each set of paths as it arrives.
  Stream<List<String>> call() => _source.incoming;
}
