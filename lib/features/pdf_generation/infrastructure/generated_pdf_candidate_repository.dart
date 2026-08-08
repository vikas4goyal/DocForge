/// Private candidate lifecycle for newly generated PDFs.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_scanly/features/pdf_generation/infrastructure/generated_pdf_candidate_job.dart';

/// Isolate-backed repository retaining at most one verified candidate.
class IsolateGeneratedPdfCandidateRepository
    implements GeneratedPdfCandidateRepository {
  /// Creates a route-scoped candidate repository.
  IsolateGeneratedPdfCandidateRepository({
    required this.workingDirectory,
    required this.ids,
    required this.pageCountOf,
    required this.protect,
  });

  /// App-private directory in which candidates are staged.
  final Directory workingDirectory;

  /// Generates collision-free candidate handles.
  final IdGenerator ids;

  /// Opens produced files to verify their page count and password.
  final GeneratedPdfPageCounter pageCountOf;

  /// Applies password protection before a candidate is exposed.
  final GeneratedPdfProtector protect;

  final SingleCandidateOwner _owner = SingleCandidateOwner();

  @override
  Future<Result<PdfCandidate>> buildCandidate(
    GeneratedPdfCandidateRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async {
    if (token.isCancelled) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    final rawPath =
        '${workingDirectory.path}/pdf-candidate-${ids.generate()}.pdf';
    var ownedPath = rawPath;
    onProgress(JobProgress(percent: 0));

    final composed = await _compose(
      request,
      rawPath,
      token: token,
      onProgress: onProgress,
    );
    if (composed case Failed(:final failure)) {
      await _deletePath(rawPath);
      return Result<PdfCandidate>.failure(failure);
    }

    if (request.password case final password?) {
      if (token.isCancelled) {
        await _deletePath(rawPath);
        return const Result<PdfCandidate>.failure(Failure.cancelled());
      }
      final protected = await protect(rawPath, password);
      if (protected case Failed(:final failure)) {
        await _deletePath(rawPath);
        return Result<PdfCandidate>.failure(failure);
      }
      ownedPath = protected.valueOrNull!;
      if (ownedPath != rawPath) {
        await _deletePath(rawPath);
      }
    }

    final file = File(ownedPath);
    if (token.isCancelled) {
      await _deletePath(ownedPath);
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    final candidate = PdfCandidate(
      handle: ownedPath,
      exactBytes: file.existsSync() ? file.lengthSync() : 0,
      pageCount: request.pages.length,
      fingerprint: request.fingerprint,
    );
    final verified = await verifyCandidate(
      candidate,
      password: request.password,
    );
    if (verified case Failed(:final failure)) {
      await _deletePath(ownedPath);
      return Result<PdfCandidate>.failure(failure);
    }
    if (token.isCancelled) {
      await _deletePath(ownedPath);
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    onProgress(JobProgress(percent: 100));
    await _owner.replace(verified.valueOrNull!, discard: _deleteCandidate);
    return verified;
  }

  @override
  Future<Result<PdfCandidate>> verifyCandidate(
    PdfCandidate candidate, {
    String? password,
  }) async {
    final file = File(candidate.handle);
    if (!file.existsSync() || file.lengthSync() != candidate.exactBytes) {
      return const Result<PdfCandidate>.failure(
        Failure.pdf(debugDetail: 'candidate bytes could not be verified'),
      );
    }
    if (candidate.isProtected != (password != null)) {
      return const Result<PdfCandidate>.failure(
        Failure.pdf(debugDetail: 'candidate protection did not match'),
      );
    }
    final count = await pageCountOf(candidate.handle, password: password);
    if (count case Failed(:final failure)) {
      return Result<PdfCandidate>.failure(failure);
    }
    if (count.valueOrNull != candidate.pageCount) {
      return const Result<PdfCandidate>.failure(
        Failure.pdf(debugDetail: 'candidate page count did not match'),
      );
    }
    return Result<PdfCandidate>.success(candidate);
  }

  @override
  Future<Result<ComposedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  }) async {
    if (token.isCancelled) {
      return const Result<ComposedPdf>.failure(Failure.cancelled());
    }
    final retained = _owner.candidate;
    if (retained != candidate) {
      return const Result<ComposedPdf>.failure(
        Failure.notFound(debugDetail: 'candidate is not owned by this route'),
      );
    }
    final source = File(candidate.handle);
    if (!source.existsSync() || source.lengthSync() != candidate.exactBytes) {
      return const Result<ComposedPdf>.failure(
        Failure.pdf(debugDetail: 'candidate bytes could not be verified'),
      );
    }
    final partial = File('$destinationPath.partial');
    try {
      await source.copy(partial.path);
      if (token.isCancelled) {
        await _deletePath(partial.path);
        return const Result<ComposedPdf>.failure(Failure.cancelled());
      }
      final destination = await partial.rename(destinationPath);
      _owner.takeMatching(candidate.fingerprint);
      await _deletePath(candidate.handle);
      return Result<ComposedPdf>.success(
        ComposedPdf(
          filePath: destination.path,
          sizeInBytes: destination.lengthSync(),
          pageCount: candidate.pageCount,
        ),
      );
    } on FileSystemException catch (error) {
      await _deletePath(partial.path);
      return Result<ComposedPdf>.failure(Failure.pdf(debugDetail: '$error'));
    }
  }

  @override
  Future<void> discard(PdfCandidate candidate) async {
    if (_owner.candidate == candidate) {
      _owner.takeMatching(candidate.fingerprint);
    }
    await _deleteCandidate(candidate);
  }

  Future<Result<void>> _compose(
    GeneratedPdfCandidateRequest request,
    String destinationPath, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async {
    final events = ReceivePort();
    Isolate? isolate;
    SendPort? controls;
    StreamSubscription<void>? cancellation;
    try {
      isolate = await Isolate.spawn(
        runGeneratedPdfCandidateJob,
        GeneratedPdfCandidateJobRequest(
          request: request,
          destinationPath: destinationPath,
          events: events.sendPort,
        ),
      );
      cancellation = token.onCancel.listen((_) {
        controls?.send('cancel');
      });
      await for (final message in events) {
        if (message is SendPort) {
          controls = message;
          if (token.isCancelled) {
            controls.send('cancel');
          }
        } else if (message is int) {
          final percent = (message * 90 / request.pages.length).floor();
          onProgress(JobProgress(percent: percent));
        } else if (message == 'complete') {
          return const Result<void>.success(null);
        } else if (message == 'cancelled') {
          return const Result<void>.failure(Failure.cancelled());
        } else if (message is List<Object>) {
          return Result<void>.failure(
            Failure.pdf(debugDetail: message.skip(1).join('\n')),
          );
        }
      }
      return const Result<void>.failure(
        Failure.pdf(debugDetail: 'candidate isolate exited unexpectedly'),
      );
    } on Object catch (error) {
      return Result<void>.failure(Failure.pdf(debugDetail: '$error'));
    } finally {
      await cancellation?.cancel();
      events.close();
      isolate?.kill(priority: Isolate.immediate);
    }
  }

  Future<void> _deleteCandidate(PdfCandidate candidate) =>
      _deletePath(candidate.handle);

  Future<void> _deletePath(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return;
    }
    try {
      await file.delete();
    } on FileSystemException {
      // Cleanup is idempotent and best effort; no private candidate is exposed.
    }
  }
}
