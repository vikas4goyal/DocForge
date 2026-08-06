/// Tests for share-sheet import, on both routes content can arrive by.
///
/// The two scenarios the spec names are genuinely different mechanisms — a
/// payload waiting at launch, and one arriving on a stream while the
/// application runs — so each is exercised separately rather than assumed to
/// behave the same.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_scanly/features/document_import/domain/import_rules.dart';
import 'package:doc_scanly/features/document_import/infrastructure/import_job.dart';
import 'package:doc_scanly/features/document_import/infrastructure/repositories/fake_import_sources.dart';
import 'package:doc_scanly/features/document_import/presentation/widgets/shared_content_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Writer implements DocumentWriter {
  final List<Document> saved = [];

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    saved.add(document);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}

void main() {
  late Directory temporary;

  setUp(() => temporary = Directory.systemTemp.createTempSync('shared_test'));
  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  String writeSource(String name) {
    final file = File('${temporary.path}/$name')..writeAsStringSync('%PDF');
    return file.path;
  }

  Future<void> pump(
    WidgetTester tester,
    FakeSharedContentSource source,
    void Function(List<String>) onContent,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SharedContentWatcher(
          takePending: TakePendingSharedContent(source),
          watchShared: WatchSharedContent(source),
          onContent: onContent,
          child: const Scaffold(body: Text('Home')),
        ),
      ),
    );
  }

  group('cold launch', () {
    testWidgets('delivers content that was waiting when the app started', (
      tester,
    ) async {
      final received = <List<String>>[];
      final source = FakeSharedContentSource(pendingPaths: ['/shared/a.pdf']);

      await pump(tester, source, received.add);
      // The pending payload is read after the first frame, so the tree it is
      // presented into has been laid out.
      await tester.pump();

      expect(received, [
        ['/shared/a.pdf'],
      ]);
    });

    testWidgets('an ordinary launch delivers nothing', (tester) async {
      // Calling back with an empty list would open an import for no content.
      final received = <List<String>>[];

      await pump(tester, FakeSharedContentSource(), received.add);
      await tester.pump();

      expect(received, isEmpty);
    });
  });

  group('while running', () {
    testWidgets('delivers content shared without restarting anything', (
      tester,
    ) async {
      final received = <List<String>>[];
      final source = FakeSharedContentSource();

      await pump(tester, source, received.add);
      await tester.pump();

      source.emit(['/shared/b.jpg']);
      await tester.pump();

      expect(received, [
        ['/shared/b.jpg'],
      ]);
      // Still the same tree; nothing was rebuilt from scratch.
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('stops listening once removed', (tester) async {
      final received = <List<String>>[];
      final source = FakeSharedContentSource();

      await pump(tester, source, received.add);
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      source.emit(['/shared/c.pdf']);
      await tester.pump();

      expect(received, isEmpty);
    });
  });

  group('importing shared content', () {
    test('several files shared at once become several documents', () async {
      final writer = _Writer();
      Directory staging() =>
          Directory('${temporary.path}/staging')..createSync(recursive: true);

      final importer = ImportFiles(
        ImportImages(
          const InlineBackgroundWorker(),
          staging,
          SequentialIdGenerator(),
          copyImportedFileJob,
        ),
        ImportPdf(
          FakePdfInspector(pageCount: 2),
          writer,
          (id) => '${temporary.path}/documents/${id.value}.pdf',
          InMemoryPublicFileStore(),
          FixedClock(DateTime.utc(2026, 3, 14)),
          SequentialIdGenerator(),
        ),
      );

      final source = FakeSharedContentSource(
        pendingPaths: [writeSource('a.pdf'), writeSource('b.pdf')],
      );

      final paths = await TakePendingSharedContent(source)();
      final events = await importer(
        paths,
        source: ImportSource.shareSheet,
      ).toList();

      expect(events.whereType<ImportedDocument>(), hasLength(2));
      expect(writer.saved, hasLength(2));
    });
  });

  group('offline', () {
    test('the feature declares no networking dependency', () {
      // Importing is a copy from one place on the device to another; there is
      // no reason for it to reach the network, and this is what keeps it that
      // way as the feature grows.
      final offenders = <String>[];

      for (final entity in Directory(
        'lib/features/document_import',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final code = entity.readAsStringSync();
        if (code.contains('package:dio') ||
            code.contains('HttpClient') ||
            code.contains('package:http/')) {
          offenders.add(entity.path);
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
