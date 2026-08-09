/// Bounded page-by-page compression candidate lifecycle.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';

/// Builds compression candidates one page at a time and retains at most one.
///
/// Native PDF operations are asynchronous, while filesystem copies and byte
/// measurement run in short isolates. Intermediate single-page files are
/// released before the next request completes, bounding working memory and
/// making cancellation cleanup deterministic.
class BoundedCompressionCandidateRepository
    implements CompressionCandidateRepository {
  /// Creates a route-scoped compression repository.
  BoundedCompressionCandidateRepository({
    required this.workingDirectory,
    required this.ids,
    required this.editor,
  });

  /// App-private directory used for candidates and page intermediates.
  final Directory workingDirectory;

  /// Generates collision-free candidate handles.
  final IdGenerator ids;

  /// Native PDF manipulation boundary.
  final PdfEditorRepository editor;

  final SingleCandidateOwner _owner = SingleCandidateOwner();

  @override
  Future<Result<PdfCandidate>> buildCandidate(
    CompressionCandidateRequest request, {
    required CancellationToken token,
    required CompressionCandidateProgress onProgress,
  }) async {
    if (token.isCancelled) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    final stem =
        '${workingDirectory.path}/compression-candidate-${ids.generate()}';
    final outputPath = '$stem.pdf';
    final intermediates = <String>[];
    onProgress(JobProgress(percent: 0));

    try {
      if (request.isAllPagesPassThrough) {
        await Isolate.run(
          () => File(request.sourcePath).copySync(outputPath).path,
        );
        onProgress(JobProgress(percent: 90));
      } else {
        final pageOutputs = <String>[];
        for (var index = 0; index < request.pageCount; index++) {
          if (token.isCancelled) {
            return const Result<PdfCandidate>.failure(Failure.cancelled());
          }
          final extracted = '$stem.page-$index.pdf';
          intermediates.add(extracted);
          final extraction = await editor.writePages(
            request.sourcePath,
            extracted,
            <int>[index],
            password: request.password,
            // All page outputs must use the same protection state before
            // merge. The completed candidate is encrypted once, below.
            preserveProtection: false,
          );
          if (extraction case Failed(:final failure)) {
            return Result<PdfCandidate>.failure(failure);
          }

          final quality = request.effectiveQualities[index];
          if (quality == 100) {
            pageOutputs.add(extracted);
          } else {
            final compressed = '$stem.page-$index.compressed.pdf';
            intermediates.add(compressed);
            final compression = await editor.compress(
              extracted,
              compressed,
              imageQuality: quality,
              // The shared percentage contract describes pixel dimensions,
              // not only an encoder hint. The concrete device adapter renders
              // this single-page intermediate at the requested scale.
              dimensionScalePercent: quality,
            );
            if (compression case Failed(:final failure)) {
              return Result<PdfCandidate>.failure(failure);
            }
            pageOutputs.add(compressed);
          }
          onProgress(
            JobProgress(
              percent: ((index + 1) * 80 / request.pageCount).floor(),
            ),
          );
        }

        if (token.isCancelled) {
          return const Result<PdfCandidate>.failure(Failure.cancelled());
        }
        final assembled = pageOutputs.length == 1
            ? await _copy(pageOutputs.single, outputPath)
            : await editor.merge(pageOutputs, outputPath);
        if (assembled case Failed(:final failure)) {
          return Result<PdfCandidate>.failure(failure);
        }
        if (request.password case final password?) {
          final protectedPath = '$stem.protected.pdf';
          intermediates.add(protectedPath);
          final protected = await editor.protect(
            outputPath,
            protectedPath,
            password: password,
          );
          if (protected case Failed(:final failure)) {
            return Result<PdfCandidate>.failure(failure);
          }
          await _deletePath(outputPath);
          await File(protectedPath).rename(outputPath);
          intermediates.remove(protectedPath);
        }
        onProgress(JobProgress(percent: 90));
      }

      if (token.isCancelled) {
        return const Result<PdfCandidate>.failure(Failure.cancelled());
      }
      final output = File(outputPath);
      if (!output.existsSync()) {
        return const Result<PdfCandidate>.failure(
          Failure.pdf(debugDetail: 'compression produced no candidate'),
        );
      }
      final candidate = PdfCandidate(
        handle: outputPath,
        exactBytes: await Isolate.run(output.lengthSync),
        pageCount: request.pageCount,
        fingerprint: request.fingerprint,
      );
      final verified = await verifyCandidate(
        candidate,
        password: request.password,
      );
      if (verified case Failed(:final failure)) {
        return Result<PdfCandidate>.failure(failure);
      }
      if (token.isCancelled) {
        return const Result<PdfCandidate>.failure(Failure.cancelled());
      }
      onProgress(JobProgress(percent: 100));
      await _owner.replace(verified.valueOrNull!, discard: _deleteCandidate);
      return verified;
    } on FileSystemException catch (error) {
      return Result<PdfCandidate>.failure(Failure.pdf(debugDetail: '$error'));
    } finally {
      for (final path in intermediates) {
        await _deletePath(path);
      }
      if (token.isCancelled || _owner.candidate?.handle != outputPath) {
        await _deletePath(outputPath);
      }
    }
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
    final count = await editor.pageCountOf(
      candidate.handle,
      password: password,
    );
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
  Future<Result<EditedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  }) async {
    if (token.isCancelled) {
      return const Result<EditedPdf>.failure(Failure.cancelled());
    }
    if (_owner.candidate != candidate) {
      return const Result<EditedPdf>.failure(
        Failure.notFound(debugDetail: 'candidate is not owned by this route'),
      );
    }
    final source = File(candidate.handle);
    if (!source.existsSync() || source.lengthSync() != candidate.exactBytes) {
      return const Result<EditedPdf>.failure(
        Failure.pdf(debugDetail: 'candidate bytes could not be verified'),
      );
    }
    final partial = '$destinationPath.partial';
    try {
      await Isolate.run(() => source.copySync(partial).path);
      if (token.isCancelled) {
        await _deletePath(partial);
        return const Result<EditedPdf>.failure(Failure.cancelled());
      }
      final destination = await File(partial).rename(destinationPath);
      _owner.takeMatching(candidate.fingerprint);
      await _deletePath(candidate.handle);
      return Result<EditedPdf>.success(
        EditedPdf(
          filePath: destination.path,
          pageCount: candidate.pageCount,
          sizeInBytes: destination.lengthSync(),
        ),
      );
    } on FileSystemException catch (error) {
      await _deletePath(partial);
      return Result<EditedPdf>.failure(Failure.pdf(debugDetail: '$error'));
    }
  }

  @override
  Future<void> discard(PdfCandidate candidate) async {
    if (_owner.candidate == candidate) {
      _owner.takeMatching(candidate.fingerprint);
    }
    await _deleteCandidate(candidate);
  }

  Future<Result<void>> _copy(String source, String destination) async {
    try {
      await Isolate.run(() => File(source).copySync(destination).path);
      return const Result<void>.success(null);
    } on FileSystemException catch (error) {
      return Result<void>.failure(Failure.pdf(debugDetail: '$error'));
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
      // Private temporary cleanup is idempotent and best effort.
    }
  }
}
