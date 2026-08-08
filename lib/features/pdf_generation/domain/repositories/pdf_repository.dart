/// The contract behind PDF composition.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';

/// What composing a PDF produced.
class ComposedPdf {
  /// Creates a description of the written file.
  const ComposedPdf({
    required this.filePath,
    required this.sizeInBytes,
    required this.pageCount,
    this.hasTextLayer = false,
  });

  /// Where the PDF was written.
  final String filePath;

  /// Its size on disk.
  ///
  /// Measured after writing rather than estimated, because it is stored on the
  /// document record and shown to the user, and an estimate that drifts from
  /// the file is worse than no figure at all.
  final int sizeInBytes;

  /// How many pages it contains.
  final int pageCount;

  /// Whether an invisible text layer was written on at least one page.
  ///
  /// Reported by the composer because the composer is what actually writes the
  /// layer; anyone else would be inferring it. It becomes the document's
  /// `hasRecognisedText`, which is what decides whether "share extracted text"
  /// is offered — so getting it from the thing that did the work is the only
  /// version that cannot drift.
  final bool hasTextLayer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComposedPdf &&
          other.hasTextLayer == hasTextLayer &&
          other.filePath == filePath &&
          other.sizeInBytes == sizeInBytes &&
          other.pageCount == pageCount;

  @override
  int get hashCode =>
      Object.hash(filePath, sizeInBytes, pageCount, hasTextLayer);

  @override
  String toString() =>
      'ComposedPdf($filePath, $sizeInBytes bytes, $pageCount pages)';
}

/// Builds PDFs from page images.
///
/// Composition only at this stage. Editing an *existing* PDF — merge, split,
/// rotate, encrypt — is a different problem with a different library behind it,
/// and lands with `pdf-editing`.
abstract interface class PdfComposer {
  /// Composes the PDF described by [request].
  ///
  /// Writes to a temporary file and moves it into place only once the whole
  /// document has been written, so a failure or a cancellation leaves no
  /// half-written PDF where a real one is expected.
  Future<Result<ComposedPdf>> compose(PdfBuildRequest request);
}

/// Reports bounded progress while a candidate is built or verified.
typedef PdfCandidateProgress = void Function(JobProgress progress);

/// Applies password protection and returns the protected temporary path.
typedef GeneratedPdfProtector =
    Future<Result<String>> Function(String sourcePath, String password);

/// Opens a PDF and returns its verified page count.
typedef GeneratedPdfPageCounter =
    Future<Result<int>> Function(String filePath, {String? password});

/// Builds and manages exact temporary candidates for generated PDFs.
///
/// Candidate handles refer only to private temporary files. A caller must
/// either transfer one with [promote] or release it with [discard].
abstract interface class GeneratedPdfCandidateRepository {
  /// Builds, protects, and verifies an exact candidate.
  Future<Result<PdfCandidate>> buildCandidate(
    GeneratedPdfCandidateRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  });

  /// Re-verifies candidate existence, byte size, page count, and protection.
  Future<Result<PdfCandidate>> verifyCandidate(
    PdfCandidate candidate, {
    String? password,
  });

  /// Atomically transfers [candidate] to [destinationPath].
  ///
  /// On success the candidate handle is consumed and must not be discarded.
  Future<Result<ComposedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  });

  /// Deletes a temporary candidate when it still exists.
  Future<void> discard(PdfCandidate candidate);
}
