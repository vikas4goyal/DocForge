/// Tier 1 widget tests for the lazy document cover preview.
library;

import 'dart:async';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_card.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/document_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _document = Document(
  id: const DocumentId('invoice'),
  title: 'Invoice',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026, 8),
  pageCount: 2,
  sizeInBytes: 2048,
  libraryPath: LibraryPath.parse('Invoice.pdf'),
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('requests page one once and exposes a bounded loading state', (
    tester,
  ) async {
    final pending = Completer<Result<String>>();
    var calls = 0;
    var page = 0;

    Future<Result<String>> load(Document document, int pageNumber) {
      calls++;
      page = pageNumber;
      return pending.future;
    }

    await tester.pumpWidget(
      _host(DocumentThumbnail(document: _document, loadThumbnail: load)),
    );
    await tester.pump();

    expect(calls, 1);
    expect(page, 1);
    expect(
      find.byKey(LibraryKeys.documentThumbnailLoading('invoice')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _host(DocumentThumbnail(document: _document, loadThumbnail: load)),
    );
    await tester.pump();
    expect(calls, 1);

    pending.complete(const Result<String>.failure(Failure.pdf()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('an absent loader shows the stable accessible placeholder', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(DocumentThumbnail(document: _document)));

    expect(
      find.byKey(LibraryKeys.documentThumbnail('invoice')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Invoice preview'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a protected document never requests or exposes a thumbnail', (
    tester,
  ) async {
    var calls = 0;
    final protected = _document.copyWith(isProtected: true);

    await tester.pumpWidget(
      _host(
        DocumentThumbnail(
          document: protected,
          loadThumbnail: (_, _) async {
            calls++;
            return const Result<String>.success('/private/page.png');
          },
        ),
      ),
    );

    expect(calls, 0);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('DocumentCard injects thumbnail loading but remains one button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var requested = 0;

    await tester.pumpWidget(
      _host(
        DocumentCard(
          document: _document,
          onTap: () {},
          loadThumbnail: (document, pageNumber) async {
            requested++;
            return const Result<String>.failure(Failure.pdf());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requested, 1);
    expect(
      find.byKey(LibraryKeys.documentThumbnail('invoice')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Invoice.*2 pages')), findsOneWidget);
    expect(find.bySemanticsLabel('Invoice preview'), findsNothing);
    semantics.dispose();
  });

  testWidgets('cloud-backed row exposes status without changing local rows', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final remote = _document.copyWith(
      cloudResourceIdentifier: 'resource-invoice',
      contentAvailability: DocumentContentAvailability.remote,
    );

    await tester.pumpWidget(_host(DocumentCard(document: remote)));

    expect(
      find.byKey(LibraryKeys.documentCloudStatus('invoice')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Invoice.*stored in iCloud')),
      findsOneWidget,
    );

    await tester.pumpWidget(_host(DocumentCard(document: _document)));
    expect(
      find.byKey(LibraryKeys.documentCloudStatus('invoice')),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('downloading row exposes item-scoped progress and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final downloading = _document.copyWith(
      cloudResourceIdentifier: 'resource-invoice',
      contentAvailability: DocumentContentAvailability.downloading,
    );

    await tester.pumpWidget(_host(DocumentCard(document: downloading)));

    expect(
      find.byKey(LibraryKeys.documentCloudDownload('invoice')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Downloading Invoice from iCloud')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
