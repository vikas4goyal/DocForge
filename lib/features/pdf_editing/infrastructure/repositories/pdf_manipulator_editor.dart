/// A [PdfEditorRepository] backed by `pdf_manipulator`.
///
/// Deliberately thin. Every decision — which pages, in what order, whether an
/// operation is allowed at all, whether a compression was worth keeping — was
/// made in the domain layer, and the atomic replace was done by
/// `AtomicPdfWrite`. What is left here is: open, call, map the error.
///
/// That split is not tidiness for its own sake. `pdf_manipulator` is backed by
/// a native engine that does not load in the host test VM, exactly as the
/// OpenCV edge detector does not (§22). Anything decided in this file would be
/// untestable until the app runs on a device, so nothing is decided here.
library;

import 'dart:io';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

/// Edits PDFs using the `pdf_manipulator` engine.
///
/// Holds one [Pdf] handle for its lifetime and disposes it in [dispose]: the
/// engine spins up a worker per handle, and creating one per operation would
/// pay that cost on every rotate.
class PdfManipulatorEditor implements PdfEditorRepository {
  /// Creates the repository.
  PdfManipulatorEditor();

  final _pdf = Pdf();

  @override
  Future<Result<void>> writePages(
    String sourcePath,
    String destinationPath,
    List<int> pages, {
    String? password,
  }) => _run(destinationPath, (sink) async {
    final editor = await _pdf.edit(
      FileSource(File(sourcePath)),
      password: password,
    );
    try {
      // `selectPages` keeps exactly these pages, in this order — which is why
      // deleting, extracting and splitting all come through here rather than
      // each calling a different engine method.
      await editor.selectPages(pages);
      await editor.save(sink);
    } finally {
      await editor.dispose();
    }
  });

  @override
  Future<Result<void>> rotatePage(
    String sourcePath,
    String destinationPath, {
    required int page,
    required int degrees,
    String? password,
  }) => _run(destinationPath, (sink) async {
    final editor = await _pdf.edit(
      FileSource(File(sourcePath)),
      password: password,
    );
    try {
      await editor.rotatePage(page, degrees: degrees);
      await editor.save(sink);
    } finally {
      await editor.dispose();
    }
  });

  @override
  Future<Result<void>> merge(
    List<String> sourcePaths,
    String destinationPath,
  ) => _run(destinationPath, (sink) async {
    await _pdf.merge([
      for (final path in sourcePaths) FileSource(File(path)),
    ], sink);
  });

  @override
  Future<Result<void>> compress(
    String sourcePath,
    String destinationPath, {
    int imageQuality = PdfEditRules.compressionImageQuality,
    String? password,
  }) => _run(destinationPath, (sink) async {
    await _pdf.compress(
      FileSource(File(sourcePath)),
      sink,
      imageQuality: imageQuality,
    );
  });

  @override
  Future<Result<void>> watermark(
    String sourcePath,
    String destinationPath, {
    required String text,
    String? password,
  }) => _run(destinationPath, (sink) async {
    // The default page selection is every page, which is what the spec
    // requires and what a per-page loop here would be able to get wrong.
    await _pdf.watermark(FileSource(File(sourcePath)), sink, text: text);
  });

  @override
  Future<Result<void>> protect(
    String sourcePath,
    String destinationPath, {
    required String password,
  }) => _run(destinationPath, (sink) async {
    // The same password is both owner and user password. DocForge offers one
    // password, and an owner password the user does not know would leave them
    // unable to remove the protection they added.
    await _pdf.encrypt(
      FileSource(File(sourcePath)),
      sink,
      encryption: PdfEncryptionConfig(
        ownerPassword: password,
        userPassword: password,
      ),
    );
  });

  @override
  Future<Result<void>> removePassword(
    String sourcePath,
    String destinationPath, {
    required String currentPassword,
  }) => _run(destinationPath, (sink) async {
    await _pdf.decrypt(
      FileSource(File(sourcePath)),
      sink,
      password: currentPassword,
    );
  });

  @override
  Future<Result<int>> pageCountOf(String filePath, {String? password}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Result<int>.failure(Failure.notFound());
      }

      final document = await _pdf.open(FileSource(file), password: password);
      try {
        return Result<int>.success(document.pageCount);
      } finally {
        await document.dispose();
      }
    } on Object catch (error) {
      return Result<int>.failure(_failureFor(error));
    }
  }

  /// Opens a sink at [destinationPath], runs [operation], and closes it.
  ///
  /// The sink is closed in a `finally` and the file removed on failure: a
  /// half-written destination left behind would be picked up by the verify step
  /// as a corrupt PDF, which is a confusing way to report "the engine failed".
  Future<Result<void>> _run(
    String destinationPath,
    Future<void> Function(DataSink sink) operation,
  ) async {
    final file = File(destinationPath);

    try {
      file.parent.createSync(recursive: true);
      final sink = await FileSink.create(file);

      try {
        await operation(sink);
      } finally {
        await sink.close();
      }

      return const Result<void>.success(null);
    } on Object catch (error) {
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } on Object {
          // Best-effort; the caller's working-file cleanup covers this too.
        }
      }
      return Result<void>.failure(_failureFor(error));
    }
  }

  /// Maps an engine error onto the failure the user is shown.
  ///
  /// The password case has to be distinguished: it is the one failure the UI
  /// answers with "try again" rather than an error view.
  Failure _failureFor(Object error) {
    final detail = '$error';
    final lowered = detail.toLowerCase();

    if (lowered.contains('password') || lowered.contains('encrypt')) {
      return Failure.auth(debugDetail: detail);
    }
    if (error is FileSystemException && error.osError?.errorCode == 28) {
      return Failure.storageFull(debugDetail: detail);
    }
    if (lowered.contains('corrupt') || lowered.contains('parse')) {
      return Failure.corruptFile(debugDetail: detail);
    }

    return Failure.pdf(debugDetail: detail);
  }

  /// Releases the engine handle.
  Future<void> dispose() => _pdf.dispose();
}
