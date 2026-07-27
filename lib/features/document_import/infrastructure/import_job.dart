/// Copies a selected file into app-private storage.
///
/// Runs **inside a background isolate**: no Flutter, and only paths cross the
/// boundary (`design.md` §7).
library;

import 'dart:io';

import 'package:doc_forge/features/document_import/application/usecases/import_usecases.dart';

/// Copies one selected file and returns where it landed.
///
/// A top-level function because a closure cannot be sent to an isolate.
///
/// Written to a temporary sibling and renamed into place. A rename within a
/// directory is atomic on both platforms, so an import interrupted part-way
/// leaves the temporary file — which is removed — rather than a truncated image
/// that would later decode into a half-grey page.
String copyImportedFileJob(CopyImportRequest request) {
  final source = File(request.sourcePath);

  if (!source.existsSync()) {
    throw FileSystemException('the selected file is gone', request.sourcePath);
  }

  final temporary = File('${request.destinationPath}.partial');

  try {
    temporary.parent.createSync(recursive: true);
    source.copySync(temporary.path);
    return temporary.renameSync(request.destinationPath).path;
  } on Object {
    if (temporary.existsSync()) temporary.deleteSync();
    rethrow;
  }
}
