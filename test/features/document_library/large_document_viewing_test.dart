import 'dart:io';

import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../document_viewer/viewer_test_support.dart';
import 'fakes.dart';

void main() {
  test(
    'ordinary viewing and Detail create no previews for 500 pages',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'large-document-viewing-',
      );
      addTearDown(() async {
        if (directory.existsSync()) await directory.delete(recursive: true);
      });
      final document = sampleDocument.copyWith(pageCount: 500);
      final documents = FakeDocumentRepository([document]);
      final pages = FakePageRepository()..pages[document.id] = samplePages(500);

      final detail = await LoadDocumentDetail(documents)(document.id);
      final viewer = ViewerHarness();
      viewer.documents.document = document;
      final cubit = viewer.cubit();
      await cubit.load();
      await cubit.close();

      expect(detail.valueOrNull?.document.pageCount, 500);
      expect(pages.forDocumentCalls, isEmpty);
      expect(
        Directory('${directory.path}/document-pages').existsSync(),
        isFalse,
      );
      expect(viewer.renderer.opened, hasLength(1));
    },
  );
}
