/// Platform-backed implementations of the sharing seams.
///
/// Each one does the smallest possible amount of work: call the plugin, map
/// what it reports onto a [Failure], and return. Everything that could be
/// decided rather than observed already happened in the domain layer, which is
/// why these classes have no tests of their own beyond their failure mapping —
/// there is no share sheet in a test VM to assert against.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_sharing/domain/document_export_result.dart';
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

/// Signature used to hand bytes to the platform document provider.
typedef SaveProviderFile =
    Future<String?> Function({
      required String fileName,
      String? initialDirectory,
      required List<String> allowedExtensions,
      required Uint8List bytes,
    });

Future<String?> _saveProviderFile({
  required String fileName,
  String? initialDirectory,
  required List<String> allowedExtensions,
  required Uint8List bytes,
}) => FilePicker.platform.saveFile(
  fileName: fileName,
  initialDirectory: initialDirectory,
  type: FileType.custom,
  allowedExtensions: allowedExtensions,
  bytes: bytes,
);

/// An [ExportDocumentRepository] backed by the system document provider.
class SystemExportDocumentRepository implements ExportDocumentRepository {
  /// Creates the platform-owned exporter.
  const SystemExportDocumentRepository({this.saveFile = _saveProviderFile});

  /// Provider handoff, replaceable only to make the platform boundary testable.
  final SaveProviderFile saveFile;

  @override
  Future<Result<DocumentExportResult>> export({
    required String sourcePath,
    required String suggestedName,
    String? initialDirectory,
  }) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return const Result<DocumentExportResult>.failure(Failure.notFound());
      }
      // Android and iOS require bytes here and perform the provider write
      // themselves. Treating the returned provider value as a writable local
      // path is what caused exports to fail and create invalid `.partial`
      // siblings beside content-provider items.
      final chosen = await saveFile(
        fileName: suggestedName,
        initialDirectory: initialDirectory,
        allowedExtensions: [suggestedName.split('.').last],
        bytes: await source.readAsBytes(),
      );

      return chosen == null
          ? const Result<DocumentExportResult>.success(
              DocumentExportResult.cancelled(),
            )
          : Result<DocumentExportResult>.success(
              DocumentExportResult.completed(destinationLabel: chosen),
            );
    } on Object catch (error) {
      return Result<DocumentExportResult>.failure(
        Failure.export(debugDetail: '$error'),
      );
    }
  }
}
