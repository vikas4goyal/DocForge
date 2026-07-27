/// The write-verify-replace sequence every editing operation goes through.
///
/// This is the single mechanism behind the spec's strongest promise: *an
/// operation either completes fully or leaves the source document unchanged,
/// with no partial file left in storage*. It lives in one tested place rather
/// than being re-implemented per operation, because ten implementations means
/// ten chances to leave a truncated PDF where a real one used to be
/// (`design.md` §12, §29).
///
/// The sequence, in order, and why each step is where it is:
///
/// 1. **Write to a working file beside the destination.** Beside, not in a
///    temporary directory: `rename` is only atomic *within a filesystem*, and a
///    cross-device rename silently degrades to a copy-then-delete, which is
///    exactly the non-atomic behaviour being avoided.
/// 2. **Verify the working file opens and has the expected page count.** Before
///    it goes anywhere near the original. A PDF engine that fails half-way
///    through can leave a file that exists, has a plausible size, and is
///    unreadable — checking the size or the exit status would not catch it.
/// 3. **Rename the working file onto the destination.** A rename within a
///    directory is atomic on both platforms: the destination is either entirely
///    the old file or entirely the new one, never a mixture, even if the
///    process dies mid-call.
/// 4. **On any failure, delete the working file and return.** The source has
///    not been touched at any point before step 3, so there is nothing to roll
///    back — which is why there is no backup-and-restore dance here, and why
///    there is no window in which a crash loses the document.
///
/// Lives in `application/` rather than in `infrastructure/`, despite touching
/// `dart:io`. It is not an adapter onto a storage technology; it is the policy
/// that makes the spec's atomicity promise true, and the use cases depend on it
/// directly. `tool/check_layering.dart` caught the original placement, and it
/// was right to: the rule exists so a use case cannot quietly depend on an
/// implementation, and this is policy, not implementation.
library;

import 'dart:io';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';

/// Produces a PDF at the given path.
///
/// Returns a failure rather than throwing; a thrown error is caught anyway, but
/// a typed failure carries the reason the user is shown.
typedef PdfProducer = Future<Result<void>> Function(String destinationPath);

/// Reports the page count of the PDF at the given path.
typedef PdfVerifier =
    Future<Result<int>> Function(String filePath, String? password);

/// Runs an editing operation so that it either completes or changes nothing.
class AtomicPdfWrite {
  /// Creates the sequence over [_verify].
  const AtomicPdfWrite(this._verify);

  final PdfVerifier _verify;

  /// Produces a new PDF at [destinationPath], replacing anything there.
  ///
  /// [expectedPageCount], when supplied, is checked against what the produced
  /// file actually contains. A wrong count means the operation did something
  /// other than what was asked, and the result is discarded rather than kept —
  /// this is what catches an engine that silently drops a page it could not
  /// re-encode.
  /// [verifyPassword] is the password the *produced* file needs, which is not
  /// always the one the source needed. Protecting a document produces a file
  /// that now requires a password the source did not have; removing protection
  /// produces one that no longer requires the password the source did. Passing
  /// the source's password here would fail verification on exactly the two
  /// operations whose whole purpose is to change it.
  Future<Result<EditedPdf>> write(
    String destinationPath,
    PdfProducer produce, {
    int? expectedPageCount,
    String? verifyPassword,
  }) async {
    final working = File('$destinationPath${PdfEditRules.workingSuffix}');

    try {
      working.parent.createSync(recursive: true);
      // A leftover from an interrupted earlier run would otherwise be appended
      // to or mistaken for this run's output.
      if (working.existsSync()) working.deleteSync();

      final produced = await produce(working.path);
      if (produced case Failed(:final failure)) {
        _discard(working);
        return Result<EditedPdf>.failure(failure);
      }

      if (!working.existsSync()) {
        return const Result<EditedPdf>.failure(
          Failure.pdf(debugDetail: 'the operation produced no file'),
        );
      }

      final verified = await _verify(working.path, verifyPassword);
      if (verified case Failed(:final failure)) {
        _discard(working);
        return Result<EditedPdf>.failure(failure);
      }

      final pageCount = verified.valueOrNull!;

      if (expectedPageCount != null && pageCount != expectedPageCount) {
        _discard(working);
        return Result<EditedPdf>.failure(
          Failure.pdf(
            debugDetail:
                'expected $expectedPageCount pages, produced $pageCount',
          ),
        );
      }

      // The atomic step. Everything before this point was working on a file
      // nothing else refers to.
      final placed = working.renameSync(destinationPath);

      return Result<EditedPdf>.success(
        EditedPdf(
          filePath: placed.path,
          pageCount: pageCount,
          // Measured from the file rather than from what the engine reported,
          // so the figure stored on the record is what the filesystem says.
          sizeInBytes: placed.lengthSync(),
        ),
      );
    } on FileSystemException catch (error) {
      _discard(working);
      return Result<EditedPdf>.failure(_fileFailure(error));
    } on Object catch (error) {
      _discard(working);
      return Result<EditedPdf>.failure(Failure.pdf(debugDetail: '$error'));
    }
  }

  /// Removes the working file, ignoring whether it was there.
  ///
  /// Best-effort and deliberately silent: this runs on the failure path, and a
  /// second failure while cleaning up would replace the real reason with a
  /// misleading one.
  void _discard(File working) {
    try {
      if (working.existsSync()) working.deleteSync();
    } on Object {
      // See above.
    }
  }

  /// Maps a filesystem error onto the failure the user can act on.
  ///
  /// errno 28 is ENOSPC on both platforms, and the spec calls for a
  /// storage-full message with guidance to free space rather than a generic
  /// "could not save".
  Failure _fileFailure(FileSystemException error) =>
      error.osError?.errorCode == 28
      ? Failure.storageFull(debugDetail: '$error')
      : Failure.pdf(debugDetail: '$error');
}
