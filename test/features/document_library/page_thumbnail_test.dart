import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/page_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File image;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('page_thumbnail_');
    image = File('${directory.path}/page.png');
    await image.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
      ),
    );
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Widget host(PageThumbnail child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows progress then a lazily loaded image', (tester) async {
    final pending = Completer<Result<String>>();
    final page = samplePages(1).first;

    await tester.pumpWidget(
      host(PageThumbnail(page: page, loadThumbnail: () => pending.future)),
    );

    expect(
      find.byKey(LibraryKeys.pageThumbnailLoading(page.id.value)),
      findsOneWidget,
    );

    pending.complete(Result<String>.success(image.path));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed derived preview keeps a stable placeholder', (
    tester,
  ) async {
    final page = samplePages(1).first;
    await tester.pumpWidget(
      host(
        PageThumbnail(
          page: page,
          loadThumbnail: () async => const Result<String>.failure(
            Failure.pdf(debugDetail: 'cannot render'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reclaimed stored path is derived again', (tester) async {
    var calls = 0;
    final page = samplePages(
      1,
    ).first.copyWith(thumbnailPath: '${directory.path}/reclaimed.png');

    await tester.pumpWidget(
      host(
        PageThumbnail(
          page: page,
          loadThumbnail: () async {
            calls += 1;
            return Result<String>.success(image.path);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('announces the page as a thumbnail', (tester) async {
    final page = samplePages(1).first;
    await tester.pumpWidget(host(PageThumbnail(page: page)));

    expect(
      find.bySemanticsLabel(LibrarySemantics.pageThumbnail(page.pageNumber)),
      findsOneWidget,
    );
  });
}
