/// Tier 2 — the compact dashboard over its real Cubit and storage boundaries.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';
import '../fakes.dart';

void main() {
  late InMemoryPublicFileStore store;
  late FakeDocumentRepository documents;
  late DashboardCubit cubit;
  late List<String> thumbnailRequests;

  Document seed(String relative, int day) {
    final path = LibraryPath.parse(relative);
    final document = Document(
      id: DocumentId(relative),
      title: path.baseName,
      createdAt: DateTime.utc(2026, 8, day),
      updatedAt: DateTime.utc(2026, 8, day),
      pageCount: 2,
      sizeInBytes: 2048,
      libraryPath: path,
    );
    store.files[relative] = 'pdf';
    for (var depth = 1; depth <= path.folders.length; depth++) {
      store.folderPaths.add(path.folders.sublist(0, depth).join('/'));
    }
    documents.documents[document.id] = document;
    return document;
  }

  Future<void> pumpDashboard(WidgetTester tester) async {
    cubit = DashboardCubit(store: store, index: documents);
    addTearDown(cubit.close);

    await pumpComponent(
      tester,
      DashboardScreen(
        loadThumbnail: (document, pageNumber) async {
          thumbnailRequests.add('${document.id.value}:$pageNumber');
          return const Result<String>.failure(Failure.pdf());
        },
        actions: DashboardActions(
          onOpenDocument: (_) {},
          onCreateFolder: (_) {},
          onImportPdf: () {},
        ),
      ),
      providers: [BlocProvider<DashboardCubit>.value(value: cubit)],
    );
    await cubit.load();
    await settleComponent(tester);
  }

  setUp(() {
    store = InMemoryPublicFileStore();
    documents = FakeDocumentRepository();
    thumbnailRequests = [];
  });

  testWidgets('root sections share one scroll and Recent stays one lane', (
    tester,
  ) async {
    for (var index = 1; index <= 7; index++) {
      seed('Document $index.pdf', index);
    }

    await pumpDashboard(tester);

    expectVisible(DashboardKeys.scrollView);
    expectNotVisible(DashboardKeys.breadcrumb);
    final recents = tester.widget<ListView>(find.byKey(DashboardKeys.recents));
    expect(recents.scrollDirection, Axis.horizontal);
    // The horizontal builder creates only the tiles near the viewport; the
    // real Cubit is the authority that proves the lane itself is capped at 5.
    expect(cubit.state.recents, hasLength(DashboardCubit.maxRecents));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'dashboard_recent_',
            ),
      ),
      findsAtLeastNWidgets(1),
    );
    expect(thumbnailRequests, isNotEmpty);
    expect(
      thumbnailRequests.every((request) => request.endsWith(':1')),
      isTrue,
    );
    expectVisible(LibraryKeys.documentThumbnail('Document 7.pdf'));
  });

  testWidgets('opening a nested folder adds the navigable breadcrumb', (
    tester,
  ) async {
    seed('Invoices/Receipt.pdf', 1);
    await pumpDashboard(tester);

    await cubit.openFolder('Invoices');
    await settleComponent(tester);

    expectVisible(DashboardKeys.breadcrumb);
    expectVisible(DashboardKeys.breadcrumbRoot);
    expect(find.text('Invoices'), findsOneWidget);
  });
}
