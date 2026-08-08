/// Exact-size calculation, preview, and transactional compression workflow.
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
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';

/// Removes a newly created copy record when publishing cannot finish.
typedef RollbackCompressionCopy = Future<Result<void>> Function(DocumentId id);

/// Restores the source record after an overwrite commit cannot finish.
typedef RestoreCompressionMetadata =
    Future<Result<void>> Function(Document original);

/// Route-stable source and candidate inputs for compression operations.
class CompressionWorkflowRequest {
  /// Creates a request whose page records describe [source].
  CompressionWorkflowRequest({
    required this.source,
    required List<DocumentPage> sourcePages,
    required this.draft,
    required this.candidateRequest,
  }) : sourcePages = List<DocumentPage>.unmodifiable(sourcePages) {
    if (source.id.value != draft.sourceDocumentId ||
        source.pageCount != draft.pageCount ||
        source.pageCount != candidateRequest.pageCount ||
        source.sizeInBytes != draft.originalBytes ||
        draft.qualityPlan != candidateRequest.qualityPlan) {
      throw ArgumentError('source, draft, and candidate request must agree');
    }
    if (sourcePages.isNotEmpty && sourcePages.length != source.pageCount) {
      throw ArgumentError.value(
        sourcePages,
        'sourcePages',
        'must be empty or contain every source page',
      );
    }
  }

  /// The authoritative document that remains untouched until commit.
  final Document source;

  /// Optional page rows cloned when the destination is a copy.
  final List<DocumentPage> sourcePages;

  /// Non-secret user choices, including the explicit destination.
  final CompressionDraft draft;

  /// Exact candidate inputs and transient source password.
  final CompressionCandidateRequest candidateRequest;
}

/// One route's pointer to its most recently verified compression candidate.
class CompressionCandidateCache {
  PdfCandidate? _candidate;

  /// The retained candidate metadata, when present.
  PdfCandidate? get candidate => _candidate;

  /// Records [candidate] as the only reusable route candidate.
  void replace(PdfCandidate candidate) => _candidate = candidate;

  /// Returns the candidate only when every output-affecting input matches.
  PdfCandidate? matching(PdfCandidateFingerprint fingerprint) =>
      _candidate?.fingerprint == fingerprint ? _candidate : null;

  /// Forgets metadata after transfer or discard.
  void clear() => _candidate = null;

  /// Discards and forgets the route candidate during route disposal.
  Future<void> dispose(CompressionCandidateRepository repository) async {
    final retained = _candidate;
    _candidate = null;
    if (retained != null) await repository.discard(retained);
  }
}

/// Calculates exact compressed bytes after the slider debounce.
class CalculateCompressedSize {
  /// Creates the calculator with an injectable deterministic [debounce].
  const CalculateCompressedSize(
    this._repository,
    this._cache, {
    this.debounce = const Duration(milliseconds: 350),
  });

  final CompressionCandidateRepository _repository;
  final CompressionCandidateCache _cache;

  /// Delay applied only to background calculation.
  final Duration debounce;

  /// Builds and retains the exact candidate for [request].
  Future<Result<PdfCandidate>> call(
    CompressionWorkflowRequest request, {
    required CancellationToken token,
    required CompressionCandidateProgress onProgress,
  }) async {
    if (!await _waitForDebounce(token, debounce)) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    return _buildAndRetain(
      _repository,
      _cache,
      request,
      token: token,
      onProgress: onProgress,
    );
  }
}

/// Produces a preview candidate, reusing an exact verified calculation.
class PrepareCompressionPreview {
  /// Creates the preview operation.
  const PrepareCompressionPreview(this._repository, this._cache);

  final CompressionCandidateRepository _repository;
  final CompressionCandidateCache _cache;

  /// Returns a verified candidate without a calculation debounce.
  Future<Result<PdfCandidate>> call(
    CompressionWorkflowRequest request, {
    required CancellationToken token,
    required CompressionCandidateProgress onProgress,
  }) => _matchingOrBuild(
    _repository,
    _cache,
    request,
    token: token,
    onProgress: onProgress,
  );
}

/// Commits a compression candidate as a sibling copy or atomic overwrite.
class SaveCompressedPdf {
  /// Creates one route-scoped, one-shot commit operation.
  SaveCompressedPdf({
    required CompressionCandidateRepository repository,
    required CompressionCandidateCache cache,
    required DocumentWriter documents,
    required RollbackCompressionCopy rollbackCopy,
    required RestoreCompressionMetadata restoreMetadata,
    required PublicFileStore store,
    required SecureStore secrets,
    required Clock clock,
    required IdGenerator ids,
    required Directory workingDirectory,
  }) : this._(
         repository,
         cache,
         documents,
         rollbackCopy,
         restoreMetadata,
         store,
         secrets,
         clock,
         ids,
         workingDirectory,
       );

  SaveCompressedPdf._(
    this._repository,
    this._cache,
    this._documents,
    this._rollbackCopy,
    this._restoreMetadata,
    this._store,
    this._secrets,
    this._clock,
    this._ids,
    this._workingDirectory,
  );

  final CompressionCandidateRepository _repository;
  final CompressionCandidateCache _cache;
  final DocumentWriter _documents;
  final RollbackCompressionCopy _rollbackCopy;
  final RestoreCompressionMetadata _restoreMetadata;
  final PublicFileStore _store;
  final SecureStore _secrets;
  final Clock _clock;
  final IdGenerator _ids;
  final Directory _workingDirectory;
  CompressionCommitResult? _completed;

  /// Immediately builds or reuses a candidate, then commits it exactly once.
  ///
  /// A candidate that does not reduce bytes requires [allowNoBenefit]. The
  /// presentation layer uses that refusal to show the explicit review before
  /// calling again with the user's confirmation.
  Future<Result<CompressionCommitResult>> call(
    CompressionWorkflowRequest request, {
    required CancellationToken token,
    required CompressionCandidateProgress onProgress,
    bool allowNoBenefit = false,
  }) async {
    final completed = _completed;
    if (completed != null) {
      return Result<CompressionCommitResult>.success(completed);
    }
    final destination = request.draft.destination;
    if (destination == null) {
      return const Result<CompressionCommitResult>.failure(
        Failure.validation(
          issue: ValidationIssue.bulkActionNotConfirmed,
          debugDetail: 'compression destination was not selected',
        ),
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
      return Result<CompressionCommitResult>.failure(failure);
    }
    final candidate = candidateResult.valueOrNull!;
    if (!allowNoBenefit && candidate.exactBytes >= request.source.sizeInBytes) {
      return const Result<CompressionCommitResult>.failure(
        Failure.validation(
          issue: ValidationIssue.bulkActionNotConfirmed,
          debugDetail: 'compressed candidate has no byte-size benefit',
        ),
      );
    }
    if (token.isCancelled) {
      await _discard(candidate);
      return const Result<CompressionCommitResult>.failure(Failure.cancelled());
    }

    final stagedPath =
        '${_workingDirectory.path}/compression-${_ids.generate()}.commit.pdf';
    final promoted = await _repository.promote(
      candidate,
      destinationPath: stagedPath,
      token: token,
    );
    _cache.clear();
    if (promoted case Failed(:final failure)) {
      return Result<CompressionCommitResult>.failure(failure);
    }

    try {
      if (token.isCancelled) {
        return const Result<CompressionCommitResult>.failure(
          Failure.cancelled(),
        );
      }
      final result = switch (destination) {
        CompressionDestination.copy => await _commitCopy(
          request,
          candidate,
          stagedPath,
          token,
        ),
        CompressionDestination.overwrite => await _commitOverwrite(
          request,
          candidate,
          stagedPath,
          token,
        ),
      };
      if (result case Success(:final value)) {
        _completed = value;
      }
      return result;
    } finally {
      await _deleteFile(stagedPath);
    }
  }

  Future<Result<CompressionCommitResult>> _commitCopy(
    CompressionWorkflowRequest request,
    PdfCandidate candidate,
    String stagedPath,
    CancellationToken token,
  ) async {
    final pathResult = await _availableCopyPath(request.source);
    if (pathResult case Failed(:final failure)) {
      return Result<CompressionCommitResult>.failure(failure);
    }
    final path = pathResult.valueOrNull!;
    final published = await _store.writeFile(path, stagedPath);
    if (published case Failed(:final failure)) {
      return Result<CompressionCommitResult>.failure(failure);
    }
    if (token.isCancelled) {
      await _store.delete(path);
      return const Result<CompressionCommitResult>.failure(Failure.cancelled());
    }

    final id = DocumentId(_ids.generate());
    final copy = request.source.copyWith(
      id: id,
      title: path.baseName,
      createdAt: _clock.now().toUtc(),
      updatedAt: _clock.now().toUtc(),
      sizeInBytes: candidate.exactBytes,
      libraryPath: path,
    );
    final pages = <DocumentPage>[
      for (final page in request.sourcePages)
        page.copyWith(id: PageId(_ids.generate()), documentId: id),
    ];
    final saved = await _documents.save(copy, pages);
    if (saved case Failed(:final failure)) {
      await _store.delete(path);
      return Result<CompressionCommitResult>.failure(failure);
    }
    final password = request.candidateRequest.password;
    if (password != null) {
      final secured = await _secrets.write(
        SecureStorageKeys.pdfPassword(id.value),
        password,
      );
      if (secured case Failed(:final failure)) {
        await _rollbackCopy(id);
        await _store.delete(path);
        return Result<CompressionCommitResult>.failure(failure);
      }
    }
    return Result<CompressionCommitResult>.success(
      CompressionCommitResult(
        documentId: id.value,
        destination: CompressionDestination.copy,
        originalBytes: request.source.sizeInBytes,
        resultBytes: candidate.exactBytes,
      ),
    );
  }

  Future<Result<CompressionCommitResult>> _commitOverwrite(
    CompressionWorkflowRequest request,
    PdfCandidate candidate,
    String stagedPath,
    CancellationToken token,
  ) async {
    final source = request.source;
    final materialised = await _store.materialise(source.libraryPath);
    if (materialised case Failed(:final failure)) {
      return Result<CompressionCommitResult>.failure(failure);
    }
    final backupPath =
        '${_workingDirectory.path}/compression-${_ids.generate()}.backup.pdf';
    try {
      await File(materialised.valueOrNull!).copy(backupPath);
      if (token.isCancelled) {
        return const Result<CompressionCommitResult>.failure(
          Failure.cancelled(),
        );
      }
      final published = await _store.writeFile(source.libraryPath, stagedPath);
      if (published case Failed(:final failure)) {
        return Result<CompressionCommitResult>.failure(failure);
      }
      if (token.isCancelled) {
        return await _rollbackOverwrite(
          source,
          backupPath,
          const Failure.cancelled(),
        );
      }

      final readable = await _store.materialise(source.libraryPath);
      if (readable case Failed(:final failure)) {
        return await _rollbackOverwrite(source, backupPath, failure);
      }
      try {
        final publishedCandidate = candidate.copyWith(
          handle: readable.valueOrNull!,
        );
        final verified = await _repository.verifyCandidate(
          publishedCandidate,
          password: request.candidateRequest.password,
        );
        if (verified case Failed(:final failure)) {
          return await _rollbackOverwrite(source, backupPath, failure);
        }
      } finally {
        await _store.releaseMaterialised(source.libraryPath);
      }

      final updated = source.copyWith(
        updatedAt: _clock.now().toUtc(),
        sizeInBytes: candidate.exactBytes,
      );
      final saved = await _documents.updateMetadata(updated);
      if (saved case Failed(:final failure)) {
        return await _rollbackOverwrite(source, backupPath, failure);
      }
      return Result<CompressionCommitResult>.success(
        CompressionCommitResult(
          documentId: source.id.value,
          destination: CompressionDestination.overwrite,
          originalBytes: source.sizeInBytes,
          resultBytes: candidate.exactBytes,
        ),
      );
    } on FileSystemException catch (error) {
      return Result<CompressionCommitResult>.failure(
        Failure.storage(debugDetail: '$error'),
      );
    } finally {
      await _store.releaseMaterialised(source.libraryPath);
      await _deleteFile(backupPath);
    }
  }

  Future<Result<CompressionCommitResult>> _rollbackOverwrite(
    Document source,
    String backupPath,
    Failure cause,
  ) async {
    final restoredBytes = await _store.writeFile(
      source.libraryPath,
      backupPath,
    );
    final restoredRecord = await _restoreMetadata(source);
    if (restoredBytes case Failed(:final failure)) {
      return Result<CompressionCommitResult>.failure(failure);
    }
    if (restoredRecord case Failed(:final failure)) {
      return Result<CompressionCommitResult>.failure(failure);
    }
    return Result<CompressionCommitResult>.failure(cause);
  }

  Future<Result<LibraryPath>> _availableCopyPath(Document source) async {
    final listed = await _store.list(source.libraryPath.folders);
    if (listed case Failed(:final failure)) {
      return Result<LibraryPath>.failure(failure);
    }
    final taken = <String>{
      for (final entry in listed.valueOrNull!)
        if (!entry.isFolder) entry.name,
    };
    final desired = LibraryPath.pdfFileName('${source.title} (compressed)');
    return Result<LibraryPath>.success(
      LibraryPath.inFolder(
        source.libraryPath.folders,
        LibraryPath.deduplicate(desired, taken),
      ),
    );
  }

  Future<void> _discard(PdfCandidate candidate) async {
    await _repository.discard(candidate);
    _cache.clear();
  }
}

Future<Result<PdfCandidate>> _matchingOrBuild(
  CompressionCandidateRepository repository,
  CompressionCandidateCache cache,
  CompressionWorkflowRequest request, {
  required CancellationToken token,
  required CompressionCandidateProgress onProgress,
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
  return _buildAndRetain(
    repository,
    cache,
    request,
    token: token,
    onProgress: onProgress,
  );
}

Future<Result<PdfCandidate>> _buildAndRetain(
  CompressionCandidateRepository repository,
  CompressionCandidateCache cache,
  CompressionWorkflowRequest request, {
  required CancellationToken token,
  required CompressionCandidateProgress onProgress,
}) async {
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
  if (token.isCancelled) return false;
  if (duration == Duration.zero) return true;
  await Future.any<void>(<Future<void>>[
    Future<void>.delayed(duration),
    token.onCancel.first.then<void>((_) {}, onError: (_) {}),
  ]);
  return !token.isCancelled;
}

Future<void> _deleteFile(String path) async {
  try {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  } on FileSystemException {
    // Private staging cleanup is best effort after commit or rollback.
  }
}
