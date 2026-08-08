/// Exact-size calculation, preview preparation, and atomic Save PDF workflow.
library;

import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';

/// Removes a just-created record during commit rollback.
typedef RollbackGeneratedDocument =
    Future<Result<void>> Function(DocumentId id);

/// Cleans creation-session sources only after a verified commit.
typedef CompleteCreationSession = Future<void> Function();

/// Route-stable configuration needed by calculation, preview, and Save.
class SavePdfWorkflowRequest {
  /// Creates a workflow request.
  SavePdfWorkflowRequest({
    required this.title,
    required List<String> folders,
    required List<PageRef> sourcePages,
    required this.candidateRequest,
    this.folderId,
  }) : folders = List<String>.unmodifiable(folders),
       sourcePages = List<PageRef>.unmodifiable(sourcePages) {
    if (sourcePages.isEmpty ||
        sourcePages.length != candidateRequest.pages.length) {
      throw ArgumentError.value(
        sourcePages,
        'sourcePages',
        'must match the non-empty candidate page list',
      );
    }
  }

  /// User-selected document title.
  final String title;

  /// Public-library folder segments.
  final List<String> folders;

  /// Source page records in final order.
  final List<PageRef> sourcePages;

  /// Exact candidate inputs, including only transient secret access.
  final GeneratedPdfCandidateRequest candidateRequest;

  /// Folder record identity, when saving inside a managed folder.
  final FolderId? folderId;
}

/// One route's pointer to the candidate most recently verified by a use case.
class SavePdfCandidateCache {
  PdfCandidate? _candidate;

  /// The retained candidate metadata, when present.
  PdfCandidate? get candidate => _candidate;

  /// Records [candidate] as the only reusable route candidate.
  void replace(PdfCandidate candidate) => _candidate = candidate;

  /// Returns a candidate only when every output-affecting input matches.
  PdfCandidate? matching(PdfCandidateFingerprint fingerprint) =>
      _candidate?.fingerprint == fingerprint ? _candidate : null;

  /// Forgets transferred or discarded candidate metadata.
  void clear() => _candidate = null;

  /// Discards and forgets the route candidate during route disposal.
  Future<void> dispose(GeneratedPdfCandidateRepository repository) async {
    final retained = _candidate;
    _candidate = null;
    if (retained != null) await repository.discard(retained);
  }
}

/// Calculates exact bytes after the required slider debounce.
class CalculateSavePdfSize {
  /// Creates the use case with an injectable deterministic [debounce].
  const CalculateSavePdfSize(
    this._repository,
    this._cache, {
    this.debounce = const Duration(milliseconds: 350),
  });

  final GeneratedPdfCandidateRepository _repository;
  final SavePdfCandidateCache _cache;

  /// Delay applied only to non-commit size calculations.
  final Duration debounce;

  /// Builds and retains the exact candidate for [request].
  Future<Result<PdfCandidate>> call(
    SavePdfWorkflowRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async {
    if (!await _waitForDebounce(token, debounce)) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    final result = await _repository.buildCandidate(
      request.candidateRequest,
      token: token,
      onProgress: onProgress,
    );
    if (result case Success(:final value)) {
      _cache.replace(value);
    }
    return result;
  }
}

/// Produces a preview candidate, reusing an exact verified calculation.
class PrepareSavePdfPreview {
  /// Creates the use case.
  const PrepareSavePdfPreview(this._repository, this._cache);

  final GeneratedPdfCandidateRepository _repository;
  final SavePdfCandidateCache _cache;

  /// Returns a candidate matching [request] without a calculation debounce.
  Future<Result<PdfCandidate>> call(
    SavePdfWorkflowRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) => _matchingOrBuild(
    _repository,
    _cache,
    request,
    token: token,
    onProgress: onProgress,
  );
}

/// Immediately builds or promotes a candidate and commits one library record.
class SaveGeneratedPdf {
  /// Creates one route-scoped one-shot Save operation.
  SaveGeneratedPdf({
    required GeneratedPdfCandidateRepository repository,
    required SavePdfCandidateCache cache,
    required DocumentWriter documents,
    required RollbackGeneratedDocument rollbackDocument,
    required PublicFileStore store,
    required SecureStore secrets,
    required Clock clock,
    required IdGenerator ids,
    required Directory workingDirectory,
    required CompleteCreationSession completeSession,
  }) : this._(
         repository,
         cache,
         documents,
         rollbackDocument,
         store,
         secrets,
         clock,
         ids,
         workingDirectory,
         completeSession,
       );

  SaveGeneratedPdf._(
    this._repository,
    this._cache,
    this._documents,
    this._rollbackDocument,
    this._store,
    this._secrets,
    this._clock,
    this._ids,
    this._workingDirectory,
    this._completeSession,
  );

  final GeneratedPdfCandidateRepository _repository;
  final SavePdfCandidateCache _cache;
  final DocumentWriter _documents;
  final RollbackGeneratedDocument _rollbackDocument;
  final PublicFileStore _store;
  final SecureStore _secrets;
  final Clock _clock;
  final IdGenerator _ids;
  final Directory _workingDirectory;
  final CompleteCreationSession _completeSession;
  Document? _completed;

  /// Commits [request] without awaiting any unrelated calculation job.
  Future<Result<Document>> call(
    SavePdfWorkflowRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async {
    final completed = _completed;
    if (completed != null) {
      return Result<Document>.success(completed);
    }
    if (request.title.trim().isEmpty) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }
    final candidateResult = await _matchingOrBuild(
      _repository,
      _cache,
      request,
      token: token,
      onProgress: onProgress,
    );
    if (candidateResult case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final candidate = candidateResult.valueOrNull!;
    if (token.isCancelled) {
      await _repository.discard(candidate);
      _cache.clear();
      return const Result<Document>.failure(Failure.cancelled());
    }

    final id = DocumentId(_ids.generate());
    final promotedPath = '${_workingDirectory.path}/${id.value}.commit.pdf';
    final promoted = await _repository.promote(
      candidate,
      destinationPath: promotedPath,
      token: token,
    );
    _cache.clear();
    if (promoted case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    LibraryPath? libraryPath;
    try {
      if (token.isCancelled) {
        return const Result<Document>.failure(Failure.cancelled());
      }
      final path = await _availablePath(request.title, request.folders);
      if (path case Failed(:final failure)) {
        return Result<Document>.failure(failure);
      }
      libraryPath = path.valueOrNull!;
      final published = await _store.writeFile(libraryPath, promotedPath);
      if (published case Failed(:final failure)) {
        return Result<Document>.failure(failure);
      }
      if (token.isCancelled) {
        await _store.delete(libraryPath);
        return const Result<Document>.failure(Failure.cancelled());
      }

      final now = _clock.now().toUtc();
      final document = Document(
        id: id,
        title: request.title.trim(),
        createdAt: now,
        updatedAt: now,
        pageCount: candidate.pageCount,
        sizeInBytes: candidate.exactBytes,
        libraryPath: libraryPath,
        folderId: request.folderId,
        isProtected: candidate.isProtected,
      );
      final pages = <DocumentPage>[
        for (var index = 0; index < request.sourcePages.length; index++)
          DocumentPage(
            id: request.sourcePages[index].id,
            documentId: id,
            order: index,
            imagePath: request.sourcePages[index].imagePath,
            rotation: request.sourcePages[index].rotation,
            enhancement: request.sourcePages[index].enhancement,
          ),
      ];
      final saved = await _documents.save(document, pages);
      if (saved case Failed(:final failure)) {
        await _store.delete(libraryPath);
        return Result<Document>.failure(failure);
      }

      final password = request.candidateRequest.password;
      if (password != null) {
        final secured = await _secrets.write(
          SecureStorageKeys.pdfPassword(id.value),
          password,
        );
        if (secured case Failed(:final failure)) {
          await _rollbackDocument(id);
          await _store.delete(libraryPath);
          return Result<Document>.failure(failure);
        }
      }
      try {
        await _completeSession();
      } on Object {
        // Authoritative bytes, record, and credential are already verified.
        // Session cleanup is retried by the normal stale-session cleanup path.
      }
      _completed = document;
      return Result<Document>.success(document);
    } finally {
      final promotedFile = File(promotedPath);
      if (promotedFile.existsSync()) {
        try {
          await promotedFile.delete();
        } on FileSystemException {
          // Private commit staging cleanup is best effort after rollback.
        }
      }
    }
  }

  Future<Result<LibraryPath>> _availablePath(
    String title,
    List<String> folders,
  ) async {
    final listed = await _store.list(folders);
    if (listed case Failed(:final failure)) {
      return Result<LibraryPath>.failure(failure);
    }
    final taken = <String>{
      for (final entry in listed.valueOrNull!)
        if (!entry.isFolder) entry.name,
    };
    try {
      final desired = LibraryPath.pdfFileName(
        LibraryPath.sanitiseName(title.trim()),
      );
      return Result<LibraryPath>.success(
        LibraryPath.inFolder(folders, LibraryPath.deduplicate(desired, taken)),
      );
    } on InvalidLibraryPath catch (error) {
      return Result<LibraryPath>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: '$error',
        ),
      );
    }
  }
}

Future<Result<PdfCandidate>> _matchingOrBuild(
  GeneratedPdfCandidateRepository repository,
  SavePdfCandidateCache cache,
  SavePdfWorkflowRequest request, {
  required CancellationToken token,
  required PdfCandidateProgress onProgress,
}) async {
  final matching = cache.matching(request.candidateRequest.fingerprint);
  if (matching != null) {
    final verified = await repository.verifyCandidate(
      matching,
      password: request.candidateRequest.password,
    );
    if (verified case Success()) {
      return verified;
    }
    await repository.discard(matching);
    cache.clear();
  }
  final built = await repository.buildCandidate(
    request.candidateRequest,
    token: token,
    onProgress: onProgress,
  );
  if (built case Success(:final value)) {
    cache.replace(value);
  }
  return built;
}

Future<bool> _waitForDebounce(
  CancellationToken token,
  Duration duration,
) async {
  if (token.isCancelled) {
    return false;
  }
  if (duration == Duration.zero) {
    return true;
  }
  await Future.any<void>(<Future<void>>[
    Future<void>.delayed(duration),
    token.onCancel.first.then<void>((_) {}, onError: (_) {}),
  ]);
  return !token.isCancelled;
}
