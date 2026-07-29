/// Tier 2 — the document list over its real Cubit and real use cases.
///
/// The existing widget tests for this screen stub `DocumentListCubit` and hand
/// it a state to render. That proves the screen draws a state correctly and
/// proves nothing about whether tapping "favourite" actually favourites
/// anything: the screen, the Cubit and the use case are never in the same test.
///
/// Here they are. Only the repository is substituted, so an action goes screen →
/// Cubit → use case → repository and the assertion is on what the screen shows
/// afterwards. A Cubit that emitted the wrong state, or a use case whose result
/// it mapped wrongly, fails here and nowhere else below Tier 3.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';
import '../fakes.dart';

/// A document with everything the list needs to render a row.
Document document(
  String id, {
  String title = 'Invoice',
  bool archived = false,
}) => Document(
  id: DocumentId(id),
  title: title,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026, 3),
  pageCount: 2,
  sizeInBytes: 2048,
  libraryPath: LibraryPath.parse('$title.pdf'),
  isArchived: archived,
);

void main() {
  late FakeDocumentRepository documents;

  setUp(() => documents = FakeDocumentRepository());

  /// Mounts the screen wired to a real Cubit over real use cases.
  ///
  /// Everything between the tap and the repository is production code; the
  /// repository is the only substitution, which is what makes this Tier 2 and
  /// not a widget test with extra ceremony.
  Future<void> pumpList(
    WidgetTester tester, {
    DocumentFilter filter = DocumentFilter.all,
  }) async {
    final clock = FixedClock(DateTime.utc(2026, 7, 26));

    await pumpComponent(
      tester,
      DocumentListScreen(title: 'Documents', onOpenDocument: (_) {}),
      providers: [
        BlocProvider(
          create: (_) => DocumentListCubit(
            LoadDocuments(documents),
            ToggleFavourite(documents, clock),
            ArchiveDocument(documents, clock),
            RestoreDocument(documents, clock),
            filter: filter,
          ),
        ),
      ],
    );
    await settleComponent(tester);
  }

  group('DocumentListScreen over its real state machine', () {
    testWidgets('loads what the repository holds', (tester) async {
      documents.documents[const DocumentId('a')] = document('a');
      documents.documents[const DocumentId('b')] = document(
        'b',
        title: 'Receipt',
      );

      await pumpList(tester);

      // The screen asks its Cubit to load on the first frame, the Cubit runs
      // the real query, and the rows are what came back. No state was handed in.
      expectVisible(LibraryKeys.documentListItem('a'));
      expectVisible(LibraryKeys.documentListItem('b'));
      expectNotVisible(LibraryKeys.documentListEmptyState);
    });

    testWidgets('shows the empty state when the repository holds nothing', (
      tester,
    ) async {
      await pumpList(tester);

      // Distinct from a failed load, and the distinction matters: an empty
      // library is normal and offers "scan a document", where a failure offers
      // a retry.
      expectVisible(LibraryKeys.documentListEmptyState);
      expectNotVisible(LibraryKeys.documentListErrorView);
    });

    testWidgets('shows the error view, with a retry, when the load fails', (
      tester,
    ) async {
      documents.failure = const Failure.unexpected();

      await pumpList(tester);

      expectVisible(LibraryKeys.documentListErrorView);
      expectNotVisible(LibraryKeys.documentListEmptyState);
    });

    testWidgets('a failed load recovers when the retry succeeds', (
      tester,
    ) async {
      documents.failure = const Failure.unexpected();
      await pumpList(tester);
      expectVisible(LibraryKeys.documentListErrorView);

      // The retry runs the same real use case again. A screen that showed a
      // retry control and did not actually re-query would pass a widget test
      // and strand the user here.
      documents
        ..failure = null
        ..documents[const DocumentId('a')] = document('a');

      await tester.tap(find.byKey(LibraryKeys.documentListRetryButton));
      await settleComponent(tester);

      expectVisible(LibraryKeys.documentListItem('a'));
      expectNotVisible(LibraryKeys.documentListErrorView);
    });

    testWidgets('the archive filter asks for archived documents only', (
      tester,
    ) async {
      documents.documents[const DocumentId('live')] = document('live');
      documents.documents[const DocumentId('old')] = document(
        'old',
        title: 'Old',
        archived: true,
      );

      await pumpList(tester, filter: DocumentFilter.archived);

      // The filter is carried by the Cubit into the real query. A screen that
      // rendered whatever it was handed could not tell these two apart.
      expectVisible(LibraryKeys.documentListItem('old'));
      expectNotVisible(LibraryKeys.documentListItem('live'));
    });
  });
}
