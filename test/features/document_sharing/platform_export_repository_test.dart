import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_sharing/domain/document_export_result.dart';
import 'package:doc_scanly/features/document_sharing/infrastructure/repositories/platform_share_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  late File source;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('provider_export_test');
    source = File('${temporary.path}/source.pdf')..writeAsStringSync('pdf');
  });

  tearDown(() => temporary.deleteSync(recursive: true));

  test('hands the source bytes to the provider exactly once', () async {
    var writes = 0;
    late Uint8List received;
    late String name;
    late String? directory;
    final repository = SystemExportDocumentRepository(
      saveFile:
          ({
            required fileName,
            initialDirectory,
            required allowedExtensions,
            required bytes,
          }) async {
            writes += 1;
            received = bytes;
            name = fileName;
            directory = initialDirectory;
            expect(allowedExtensions, ['pdf']);
            return 'Provider/Invoice.pdf';
          },
    );

    final result = await repository.export(
      sourcePath: source.path,
      suggestedName: 'Invoice.pdf',
      initialDirectory: 'Provider',
    );

    expect(writes, 1);
    expect(String.fromCharCodes(received), 'pdf');
    expect(name, 'Invoice.pdf');
    expect(directory, 'Provider');
    expect(
      (result as Success<DocumentExportResult>).value,
      const DocumentExportResult.completed(
        destinationLabel: 'Provider/Invoice.pdf',
      ),
    );
    expect(File('Provider/Invoice.pdf.partial').existsSync(), isFalse);
  });

  test('delegates collision handling to the provider', () async {
    var writes = 0;
    final repository = SystemExportDocumentRepository(
      saveFile:
          ({
            required fileName,
            initialDirectory,
            required allowedExtensions,
            required bytes,
          }) async {
            writes += 1;
            return 'Provider/Invoice (1).pdf';
          },
    );

    final result = await repository.export(
      sourcePath: source.path,
      suggestedName: 'Invoice.pdf',
    );

    expect(writes, 1);
    expect(
      (result as Success<DocumentExportResult>).value,
      const DocumentExportResult.completed(
        destinationLabel: 'Provider/Invoice (1).pdf',
      ),
    );
  });

  test('maps provider cancellation to a non-error result', () async {
    final repository = SystemExportDocumentRepository(
      saveFile:
          ({
            required fileName,
            initialDirectory,
            required allowedExtensions,
            required bytes,
          }) async => null,
    );

    final result = await repository.export(
      sourcePath: source.path,
      suggestedName: 'Invoice.pdf',
    );

    expect(
      (result as Success<DocumentExportResult>).value,
      const DocumentExportResult.cancelled(),
    );
  });

  test('maps provider handoff failures without a second write', () async {
    var writes = 0;
    final repository = SystemExportDocumentRepository(
      saveFile:
          ({
            required fileName,
            initialDirectory,
            required allowedExtensions,
            required bytes,
          }) async {
            writes += 1;
            throw StateError('provider rejected write');
          },
    );

    final result = await repository.export(
      sourcePath: source.path,
      suggestedName: 'Invoice.pdf',
    );

    expect(writes, 1);
    expect(result, isA<Failed<DocumentExportResult>>());
  });

  test('does not open the provider when the source is missing', () async {
    var writes = 0;
    final repository = SystemExportDocumentRepository(
      saveFile:
          ({
            required fileName,
            initialDirectory,
            required allowedExtensions,
            required bytes,
          }) async {
            writes += 1;
            return 'unused';
          },
    );

    final result = await repository.export(
      sourcePath: '${temporary.path}/missing.pdf',
      suggestedName: 'Invoice.pdf',
    );

    expect(writes, 0);
    expect(result, isA<Failed<DocumentExportResult>>());
  });
}
