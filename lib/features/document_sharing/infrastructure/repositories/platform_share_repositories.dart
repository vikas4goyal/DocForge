/// Platform-backed implementations of the sharing seams.
///
/// Each one does the smallest possible amount of work: call the plugin, map
/// what it reports onto a [Failure], and return. Everything that could be
/// decided rather than observed already happened in the domain layer, which is
/// why these classes have no tests of their own beyond their failure mapping —
/// there is no share sheet in a test VM to assert against.
library;

import 'dart:io';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_sharing/domain/repositories/share_repository.dart';
import 'package:doc_scanly/features/document_sharing/domain/share_content.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// A [ShareRepository] backed by the system share sheet.
class SystemShareRepository implements ShareRepository {
  /// Creates the repository.
  const SystemShareRepository();

  @override
  Future<Result<void>> share(SharePayload payload) async {
    if (payload.isEmpty) {
      return const Result<void>.failure(
        Failure.export(debugDetail: 'nothing to share'),
      );
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [for (final path in payload.filePaths) XFile(path)],
          text: payload.text.isEmpty ? null : payload.text,
          subject: payload.subject.isEmpty ? null : payload.subject,
        ),
      );

      // A dismissed sheet is not a failure: the user changed their mind, and
      // the spec's rule is that nothing leaves unless they chose to send it.
      return switch (result.status) {
        ShareResultStatus.unavailable => const Result<void>.failure(
          Failure.export(noReceivingApp: true),
        ),
        _ => const Result<void>.success(null),
      };
    } on Object catch (error) {
      return Result<void>.failure(Failure.export(debugDetail: '$error'));
    }
  }
}

/// A [PrintRepository] backed by the system print dialogue.
class SystemPrintRepository implements PrintRepository {
  /// Creates the repository.
  const SystemPrintRepository();

  @override
  Future<Result<bool>> printFile(
    String filePath, {
    required String jobName,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Result<bool>.failure(Failure.notFound());
      }

      // The bytes are read here rather than streamed because `printing` asks
      // for a layout callback that may be invoked more than once, for different
      // page formats, and re-reading the file each time is the slower of the
      // two wrong answers.
      final bytes = file.readAsBytesSync();
      final submitted = await Printing.layoutPdf(
        name: jobName,
        onLayout: (_) => bytes,
      );

      return Result<bool>.success(submitted);
    } on Object catch (error) {
      return Result<bool>.failure(Failure.export(debugDetail: '$error'));
    }
  }
}

/// An [ExportDestinationPicker] backed by the system file picker.
class SystemExportDestinationPicker implements ExportDestinationPicker {
  /// Creates the picker.
  const SystemExportDestinationPicker();

  @override
  Future<Result<String?>> chooseDestination({
    required String suggestedName,
    String? initialDirectory,
  }) async {
    try {
      final chosen = await FilePicker.platform.saveFile(
        fileName: suggestedName,
        initialDirectory: initialDirectory,
        type: FileType.custom,
        allowedExtensions: [suggestedName.split('.').last],
      );

      return Result<String?>.success(chosen);
    } on Object catch (error) {
      return Result<String?>.failure(Failure.export(debugDetail: '$error'));
    }
  }
}
