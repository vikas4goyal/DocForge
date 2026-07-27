/// The seam between editing and whatever manipulates PDF bytes.
///
/// Every method takes explicit source and destination paths and never decides
/// where a file goes — that is the use case's business, and keeping it out of
/// here is what lets the atomic replace sequence live in one place rather than
/// being re-implemented per operation.
library;

import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';

/// Manipulates PDF files.
///
/// Every method **writes to its destination path and leaves the source
/// untouched**. Replacing the source is done by the caller, atomically, after
/// the result has been verified — see the atomic write sequence in
/// `infrastructure/atomic_pdf_write.dart`. Splitting the work this
/// way means "a failure leaves the document unchanged" is a property of one
/// tested sequence rather than of ten separate implementations.
abstract interface class PdfEditorRepository {
  /// Writes a copy of [sourcePath] containing only [pages], in that order.
  ///
  /// Zero-based. Used for deleting (the pages that remain), extracting (the
  /// pages chosen) and splitting (each half) — all three are the same operation
  /// with a different list, and modelling them separately would have meant
  /// three chances to get page ordering wrong.
  Future<Result<void>> writePages(
    String sourcePath,
    String destinationPath,
    List<int> pages, {
    String? password,
  });

  /// Writes a copy of [sourcePath] with [page] rotated by [degrees] clockwise.
  Future<Result<void>> rotatePage(
    String sourcePath,
    String destinationPath, {
    required int page,
    required int degrees,
    String? password,
  });

  /// Writes the concatenation of [sourcePaths], in the order given.
  Future<Result<void>> merge(List<String> sourcePaths, String destinationPath);

  /// Writes a re-encoded, smaller copy of [sourcePath].
  ///
  /// May legitimately produce a *larger* file; deciding what to do about that
  /// is the caller's job, not this one's.
  Future<Result<void>> compress(
    String sourcePath,
    String destinationPath, {
    int imageQuality = PdfEditRules.compressionImageQuality,
    String? password,
  });

  /// Writes a copy of [sourcePath] with [text] stamped on every page.
  Future<Result<void>> watermark(
    String sourcePath,
    String destinationPath, {
    required String text,
    String? password,
  });

  /// Writes an encrypted copy of [sourcePath] requiring [password] to open.
  Future<Result<void>> protect(
    String sourcePath,
    String destinationPath, {
    required String password,
  });

  /// Writes a decrypted copy of [sourcePath].
  ///
  /// Fails with an authentication failure when [currentPassword] is wrong,
  /// which the UI turns into "that password did not work" rather than an error
  /// view — the user can simply try again.
  Future<Result<void>> removePassword(
    String sourcePath,
    String destinationPath, {
    required String currentPassword,
  });

  /// Returns the page count of [filePath].
  ///
  /// The verification step of every operation: a file that cannot be opened, or
  /// that has the wrong number of pages, never replaces a real document.
  Future<Result<int>> pageCountOf(String filePath, {String? password});
}
