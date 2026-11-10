// Tier 1 — a database written before `hasRecognisedText` was removed still
// opens and reads. The fixture was produced by the previous schema (commit
// 8afbee8) with a document carrying `hasRecognisedText: true`; Isar must
// ignore the property it no longer knows rather than fail to open the library.
import 'dart:io';

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_scanly/features/document_library/infrastructure/repositories/isar_library_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  late Directory directory;

  setUpAll(() => Isar.initializeIsarCore(download: true));

  setUp(() {
    directory = Directory.systemTemp.createTempSync('legacy_isar');
    final compressed = File(
      'test/fixtures/isar/document_with_recognised_text_flag.isar.gz',
    ).readAsBytesSync();
    File(
      '${directory.path}/default.isar',
    ).writeAsBytesSync(gzip.decode(compressed));
  });

  tearDown(() => directory.deleteSync(recursive: true));

  test('a library from the previous schema opens and reads', () async {
    final isar = await Isar.open([
      DocumentEntitySchema,
      FolderEntitySchema,
      PageEntitySchema,
      TrashEntitySchema,
    ], directory: directory.path);
    addTearDown(isar.close);

    final found = await IsarDocumentRepository(
      isar,
    ).findById(const DocumentId('legacy-1'));

    final document = found.valueOrNull;
    expect(document, isNotNull);
    expect(document!.title, 'Legacy');
    expect(document.isFavourite, isTrue);
    expect(document.pageCount, 1);
  });
}
