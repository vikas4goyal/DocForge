/// The contract behind PDF composition.
library;

import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';

/// What composing a PDF produced.
class ComposedPdf {
  /// Creates a description of the written file.
  const ComposedPdf({
    required this.filePath,
    required this.sizeInBytes,
    required this.pageCount,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComposedPdf &&
          other.filePath == filePath &&
          other.sizeInBytes == sizeInBytes &&
          other.pageCount == pageCount;

  @override
  int get hashCode => Object.hash(filePath, sizeInBytes, pageCount);

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
