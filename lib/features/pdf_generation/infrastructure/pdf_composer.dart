/// The [PdfComposer] implementations.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_forge/features/pdf_generation/infrastructure/pdf_composer_job.dart';

/// Composes PDFs in a background isolate.
///
/// Owns its own `Isolate.run` rather than going through `BackgroundWorker`,
/// because composition is asynchronous — `pw.Document.save` returns a future —
/// and the worker's job contract is synchronous by design.
class IsolatePdfComposer implements PdfComposer {
  /// Creates the composer.
  const IsolatePdfComposer();

  @override
  Future<Result<ComposedPdf>> compose(PdfBuildRequest request) async {
    try {
      // Only the request and the returned description cross the boundary. The
      // isolate reads each page from disk, encodes it and releases it, so a
      // fifty-page document costs one page's memory rather than fifty.
      final composed = await Isolate.run(() => composePdfJob(request));
      return Result<ComposedPdf>.success(composed);
    } on Object catch (error) {
      return Result<ComposedPdf>.failure(_failureFor(error));
    }
  }
}

/// Composes PDFs on the calling thread.
///
/// For tests and integration runs: deterministic, and free of isolate spawn
/// cost. Never used in production, where blocking the UI thread for the length
/// of a fifty-page composition is exactly what the isolate exists to prevent.
class InlinePdfComposer implements PdfComposer {
  /// Creates an inline composer.
  const InlinePdfComposer();

  @override
  Future<Result<ComposedPdf>> compose(PdfBuildRequest request) async {
    try {
      return Result<ComposedPdf>.success(await composePdfJob(request));
    } on Object catch (error) {
      return Result<ComposedPdf>.failure(_failureFor(error));
    }
  }
}

/// Maps a composition error onto the failure the user should see.
///
/// A full disk is distinguished from a corrupt page because the recoveries
/// differ: one is "free some space", the other "the page could not be read".
/// Reporting both as an unexpected error would offer a retry that cannot work.
Failure _failureFor(Object error) {
  if (error is FileSystemException) {
    // errno 28 is ENOSPC on both Android and iOS.
    if (error.osError?.errorCode == 28) {
      return Failure.storageFull(debugDetail: '$error');
    }
    return Failure.pdf(debugDetail: '$error');
  }

  if (error is FormatException) {
    return Failure.corruptFile(debugDetail: '$error');
  }

  return Failure.pdf(debugDetail: '$error');
}
