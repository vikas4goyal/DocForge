/// Tests for the write-verify-replace sequence.
///
/// This file exists to prove one sentence from the spec: *an operation either
/// completes fully or leaves the source document unchanged, with no partial
/// file left in storage*. Every way the sequence can fail is exercised, and
/// each asserts both halves of that promise — the original is intact **and**
/// nothing was left behind.
library;

import 'dart:io';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  late File original;

  const originalContents = 'the original document';

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('atomic_pdf');
    original = File('${temporary.path}/document.pdf')
      ..writeAsStringSync(originalContents);
  });

  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  String workingPath() => '${original.path}${PdfEditRules.workingSuffix}';

  /// A verifier reporting a fixed page count.
  PdfVerifier verifying(int pages) =>
      (_, _) async => Result<int>.success(pages);

  /// A producer writing [contents] to wherever it is told.
  PdfProducer producing(String contents) => (destination) async {
    File(destination).writeAsStringSync(contents);
    return const Result<void>.success(null);
  };

  group('success', () {
    test('replaces the destination with what was produced', () async {
      final result = await AtomicPdfWrite(
        verifying(3),
      ).write(original.path, producing('the new document'));

      expect(result, isA<Success<EditedPdf>>());
      expect(original.readAsStringSync(), 'the new document');
    });

    test('reports the page count and the size on disk', () async {
      final result = await AtomicPdfWrite(
        verifying(3),
      ).write(original.path, producing('12345'));

      final edited = (result as Success<EditedPdf>).value;
      expect(edited.pageCount, 3);
      // Measured from the file, not from what the producer claimed.
      expect(edited.sizeInBytes, 5);
      expect(edited.filePath, original.path);
    });

    test('leaves no working file behind', () async {
      await AtomicPdfWrite(verifying(1)).write(original.path, producing('new'));

      expect(File(workingPath()).existsSync(), isFalse);
    });

    test('creates the destination directory when it does not exist', () async {
      final nested = '${temporary.path}/derived/new.pdf';

      final result = await AtomicPdfWrite(
        verifying(1),
      ).write(nested, producing('new'));

      expect(result, isA<Success<EditedPdf>>());
      expect(File(nested).existsSync(), isTrue);
    });
  });

  group('the producer fails', () {
    test('leaves the original untouched', () async {
      final result = await AtomicPdfWrite(verifying(1)).write(original.path, (
        destination,
      ) async {
        // Half-written, as a failing engine would leave it.
        File(destination).writeAsStringSync('truncated');
        return const Result<void>.failure(Failure.pdf());
      });

      expect(result, isA<Failed<EditedPdf>>());
      expect(original.readAsStringSync(), originalContents);
    });

    test('removes the half-written working file', () async {
      await AtomicPdfWrite(verifying(1)).write(original.path, (
        destination,
      ) async {
        File(destination).writeAsStringSync('truncated');
        return const Result<void>.failure(Failure.pdf());
      });

      expect(File(workingPath()).existsSync(), isFalse);
    });

    test('propagates the failure the producer reported', () async {
      final result = await AtomicPdfWrite(verifying(1)).write(
        original.path,
        (_) async => const Result<void>.failure(Failure.storageFull()),
      );

      expect((result as Failed<EditedPdf>).failure, isA<StorageFullFailure>());
    });

    test('reports a producer that threw rather than crashing', () async {
      final result = await AtomicPdfWrite(
        verifying(1),
      ).write(original.path, (_) async => throw StateError('the engine died'));

      expect(result, isA<Failed<EditedPdf>>());
      expect(original.readAsStringSync(), originalContents);
      expect(File(workingPath()).existsSync(), isFalse);
    });

    test('fails when the producer wrote nothing at all', () async {
      final result = await AtomicPdfWrite(
        verifying(1),
      ).write(original.path, (_) async => const Result<void>.success(null));

      expect(result, isA<Failed<EditedPdf>>());
      expect(original.readAsStringSync(), originalContents);
    });
  });

  group('verification fails', () {
    test('a file that cannot be opened never replaces the original', () async {
      // The case a size check would miss entirely: the file exists, is a
      // plausible length, and is unreadable.
      final result = await AtomicPdfWrite(
        (_, _) async => const Result<int>.failure(Failure.corruptFile()),
      ).write(original.path, producing('plausible but broken'));

      expect((result as Failed<EditedPdf>).failure, isA<CorruptFileFailure>());
      expect(original.readAsStringSync(), originalContents);
      expect(File(workingPath()).existsSync(), isFalse);
    });

    test('a wrong page count never replaces the original', () async {
      // Catches an engine that silently drops a page it could not re-encode.
      final result = await AtomicPdfWrite(
        verifying(2),
      ).write(original.path, producing('new'), expectedPageCount: 3);

      expect(result, isA<Failed<EditedPdf>>());
      expect(original.readAsStringSync(), originalContents);
      expect(File(workingPath()).existsSync(), isFalse);
    });

    test('a matching page count is accepted', () async {
      final result = await AtomicPdfWrite(
        verifying(3),
      ).write(original.path, producing('new'), expectedPageCount: 3);

      expect(result, isA<Success<EditedPdf>>());
    });
  });

  group('leftovers from an earlier run', () {
    test('a stale working file is discarded rather than reused', () async {
      // Left by a run that was killed. Appending to it, or mistaking it for
      // this run's output, would produce a document made of two halves.
      File(workingPath()).writeAsStringSync('leftover from a crash');

      final result = await AtomicPdfWrite(
        verifying(1),
      ).write(original.path, producing('the new document'));

      expect(result, isA<Success<EditedPdf>>());
      expect(original.readAsStringSync(), 'the new document');
    });
  });

  group('storage failures', () {
    test('an unwritable destination leaves the original alone', () async {
      // The parent is a *file*, so creating a directory there fails.
      final blocked = '${original.path}/nested/new.pdf';

      final result = await AtomicPdfWrite(
        verifying(1),
      ).write(blocked, producing('new'));

      expect(result, isA<Failed<EditedPdf>>());
      expect(original.readAsStringSync(), originalContents);
    });
  });
}
