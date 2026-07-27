/// PDF rendering, backed by pdfrx.
library;

import 'dart:io';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:pdfrx/pdfrx.dart';

/// Opens PDFs with pdfrx's PDFium binding.
///
/// Opens and immediately closes: this reports what the file *is* — how many
/// pages, whether it needed a password — and nothing more. The viewer widget
/// opens its own handle and renders pages on demand, which is what keeps memory
/// bounded on a large document.
class PdfrxRenderer implements PdfRenderer {
  /// Creates the renderer.
  const PdfrxRenderer();

  @override
  Future<Result<OpenedDocument>> open(
    String filePath, {
    String? password,
  }) async {
    if (!File(filePath).existsSync()) {
      return Result<OpenedDocument>.failure(
        Failure.notFound(debugDetail: 'no file at $filePath'),
      );
    }

    PdfDocument? document;

    try {
      var passwordOffered = false;

      document = await PdfDocument.openFile(
        filePath,
        passwordProvider: () {
          // Offered exactly once. Returning it repeatedly would make pdfrx
          // retry the same wrong password forever rather than reporting that
          // the file is locked.
          if (password == null || passwordOffered) return null;
          passwordOffered = true;
          return password;
        },
      );

      return Result<OpenedDocument>.success(
        OpenedDocument(
          pageCount: document.pages.length,
          // The password was actually consumed, which is the only reliable
          // signal that the file is encrypted — pdfrx does not expose the flag
          // directly, and an unprotected file never asks.
          isProtected: passwordOffered,
        ),
      );
    } on PdfPasswordException {
      // Distinct from a corrupt file: the recovery is a password prompt, not
      // "this document cannot be opened".
      return const Result<OpenedDocument>.failure(
        Failure.auth(debugDetail: 'the document is password-protected'),
      );
    } on Object catch (error) {
      return Result<OpenedDocument>.failure(
        Failure.corruptFile(debugDetail: '$error'),
      );
    } finally {
      // Closed immediately: the handle this call opens is only used to answer
      // the two questions above, and leaving it open would hold the file's
      // native buffers for the life of the app.
      await document?.dispose();
    }
  }
}

/// A renderer that reports a fixed document without opening a file.
///
/// Ships in `lib/` rather than in `test/` because previews need it too, and a
/// preview may not reach into the test tree.
class FakePdfRenderer implements PdfRenderer {
  /// Creates a fake reporting [pageCount] pages.
  FakePdfRenderer({this.pageCount = 3, this.requiredPassword, this.failure});

  /// How many pages the document has.
  final int pageCount;

  /// The password the document needs, when it needs one.
  final String? requiredPassword;

  /// When set, every open fails with this instead.
  final Failure? failure;

  /// Every path this renderer was asked to open, in order.
  final opened = <String>[];

  @override
  Future<Result<OpenedDocument>> open(
    String filePath, {
    String? password,
  }) async {
    opened.add(filePath);

    final configured = failure;
    if (configured != null) {
      return Result<OpenedDocument>.failure(configured);
    }

    final required = requiredPassword;
    if (required != null && password != required) {
      return const Result<OpenedDocument>.failure(Failure.auth());
    }

    return Result<OpenedDocument>.success(
      OpenedDocument(pageCount: pageCount, isProtected: required != null),
    );
  }
}
