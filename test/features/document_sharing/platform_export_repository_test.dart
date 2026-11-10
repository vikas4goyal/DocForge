import 'dart:io';

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_sharing/domain/document_export_result.dart';
import 'package:doc_scanly/features/document_sharing/infrastructure/repositories/platform_share_repositories.dart';
import 'package:flutter/services.dart';
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
      platform: TargetPlatform.android,
    );

    final result = await repository.export(
      sourcePath: source.path,
      suggestedName: 'Invoice.pdf',
      initialDirectory: '/storage/emulated/0/Provider',
    );

    expect(writes, 1);
    expect(String.fromCharCodes(received), 'pdf');
    expect(name, 'Invoice.pdf');
    // Normalised to the document URI Android's picker understands.
    expect(
      directory,
      'content://com.android.externalstorage.documents/document/'
      'primary%3AProvider',
    );
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

  group('starting location', () {
    SystemExportDocumentRepository recording(
      List<String?> hints, {
      TargetPlatform platform = TargetPlatform.android,
      bool exists = true,
      Exception? Function(String? hint)? fail,
      String? answer = 'Files/Invoice.pdf',
    }) => SystemExportDocumentRepository(
      platform: platform,
      directoryExists: (_) => exists,
      saveFile:
          ({
            required fileName,
            initialDirectory,
            required allowedExtensions,
            required bytes,
          }) async {
            hints.add(initialDirectory);
            final error = fail?.call(initialDirectory);
            if (error != null) throw error;
            return answer;
          },
    );

    test('iOS receives an existing folder as a file URL', () async {
      final hints = <String?>[];
      await recording(hints, platform: TargetPlatform.iOS).export(
        sourcePath: source.path,
        suggestedName: 'Invoice.pdf',
        initialDirectory: '/var/mobile/Exports',
      );

      expect(hints, ['file:///var/mobile/Exports/']);
    });

    test('no configured location means no hint', () async {
      final hints = <String?>[];
      await recording(
        hints,
      ).export(sourcePath: source.path, suggestedName: 'Invoice.pdf');

      expect(hints, [null]);
    });

    // PR #2 review: a write failure after the user picked a destination (a
    // full disk, a failed provider write) arrives as a PlatformException too.
    // Retrying reopened the picker over a real failure.
    test(
      'a failure with a starting location is reported, never retried',
      () async {
        final hints = <String?>[];
        final result =
            await recording(
              hints,
              fail: (_) => PlatformException(
                code: 'Error while saving file',
                message: 'No space left on device',
              ),
            ).export(
              sourcePath: source.path,
              suggestedName: 'Invoice.pdf',
              initialDirectory: '/storage/emulated/0/Download',
            );

        expect(hints, hasLength(1), reason: 'The picker must open only once.');
        expect(result, isA<Failed<DocumentExportResult>>());
        expect(
          result.failureOrNull.toString(),
          contains('No space left on device'),
        );
      },
    );

    test('a platform failure without a hint is not retried', () async {
      final hints = <String?>[];
      final result = await recording(
        hints,
        fail: (_) => PlatformException(code: 'provider_down'),
      ).export(sourcePath: source.path, suggestedName: 'Invoice.pdf');

      expect(hints, [null]);
      expect(result, isA<Failed<DocumentExportResult>>());
    });

    test('cancelling with a hint is still not an error', () async {
      final hints = <String?>[];
      final result = await recording(hints, answer: null).export(
        sourcePath: source.path,
        suggestedName: 'Invoice.pdf',
        initialDirectory: '/storage/emulated/0/Download',
      );

      expect(hints, hasLength(1));
      expect(result.valueOrNull, const DocumentExportResult.cancelled());
    });
  });
}
